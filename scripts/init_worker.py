#!/usr/bin/env python3
import boto3
from botocore.exceptions import NoCredentialsError
import os
import subprocess
import time
import json
import requests

# Load system daemons
subprocess.check_call(["systemctl", "daemon-reload"])
subprocess.check_call(["systemctl", "enable", "docker.service"])
subprocess.check_call(["systemctl", "start", "docker.service"])

# Add deployer & admin to docker group to call docker without sudo.
subprocess.check_call(["usermod", "-a", "-G", "docker", "deployer"])
subprocess.check_call(["usermod", "-a", "-G", "docker", "admin"])

# Set values loaded by the template
environment    = '${environment}'
s3_access_key  = '${s3_access_key}'
s3_secret_key  = '${s3_secret_key}'
s3_endpoint    = '${s3_endpoint}'
s3_bucket      = '${s3_bucket}'
s3_region_name = '${s3_region_name}'
instance_index = int('${instance_index}')
swapsize       = int('${swapsize}')

# Connect to S3-alike:
s3 = boto3.resource('s3', endpoint_url=s3_endpoint, region_name=s3_region_name, aws_access_key_id=s3_access_key, aws_secret_access_key=s3_secret_key)
try:
    bucket = s3.Bucket(s3_bucket)
    bucket.objects.all()
except NoCredentialsError as e:
    time.sleep(5)

# Gather docker swarm credentials from S3
worker_token_object = s3.Object(s3_bucket, 'worker_token')
manager0_ip_object = s3.Object(s3_bucket, 'ip0')
worker_token_object.wait_until_exists()
manager0_ip_object.wait_until_exists()

worker_token = worker_token_object.get()['Body'].read()
manager0_ip = manager0_ip_object.get()['Body'].read()

# Connect to docker swarm
subprocess.check_call(["docker", "swarm", "join", "--token", worker_token, manager0_ip])

# Configure Swapfile
if not os.path.isfile("/swapfile"):
    subprocess.check_output(["fallocate", "-l", str(swapsize) + "G", "/swapfile"])
    os.chmod("/swapfile", 0o600)
    subprocess.check_output(["mkswap", "/swapfile"])
    f = open("/etc/fstab", "a")
    f.write("/swapfile none swap defaults 0 0\n")
    f.close()
subprocess.check_output(["swapon", "-a"])

# Configure daemon label:
daemonSettings = {
    "labels": [
        "node-purpose=worker"
    ]
}
daemon = open("/etc/docker/daemon.json", "w")
daemon.write(json.dumps(daemonSettings, sort_keys=True, indent=4))
daemon.close()

# Set the host name
subprocess.check_call(["hostnamectl", "set-hostname", "worker-%s" % (environment)])

# Restart Docker
subprocess.check_call(["systemctl", "restart", "docker.service"])
