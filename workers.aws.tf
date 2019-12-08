resource "aws_instance" "swarm-workers" {
  count                = local.workers_aws
  ami                  = data.aws_ami.base_ami.id
  instance_type        = var.aws_manager_type
  subnet_id            = aws_subnet.cluster[count.index % length(data.aws_availability_zones.azs.names)].id
  key_name             = aws_key_pair.deployer.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2.name
  user_data_base64     = data.template_cloudinit_config.workers[0].rendered
  monitoring           = false

  vpc_security_group_ids = [
    aws_security_group.swarm.id,
    aws_security_group.daemon.id,
    aws_security_group.sshaccess.id,
  ]

  tags = {
    Name    = "swarm-worker"
    Cluster = var.cluster_name
  }

  root_block_device {
    volume_size = local.default_disk_size
  }

  credit_specification {
    cpu_credits = "standard"
  }
}

resource "aws_eip" "swarm-workers" {
  count    = local.workers_aws
  instance = aws_instance.swarm-workers[0].id
  vpc      = true
  depends_on = [
    aws_internet_gateway.gw,
    aws_route.internet_access,
    aws_instance.swarm-workers,
  ]
  tags = {
    Name    = "swarm-worker"
    Cluster = var.cluster_name
  }
}
