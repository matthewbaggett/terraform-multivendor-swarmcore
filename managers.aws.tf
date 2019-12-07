resource "aws_instance" "swarm-managers" {
  count         = local.managers_aws
  ami           = data.aws_ami.base_ami.id
  instance_type = var.aws_manager_type
  subnet_id     = aws_subnet.cluster[count.index % length(data.aws_availability_zones.azs.names)].id

  vpc_security_group_ids = [
    aws_security_group.swarm.id,
    aws_security_group.daemon.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2.name
  user_data_base64     = data.template_cloudinit_config.managers[count.index].rendered

  tags = {
    Name    = "swarm-master"
    Cluster = var.cluster_name
  }

  monitoring = false
  #disable_api_termination = true

  root_block_device {
    volume_size = local.default_disk_size
  }

  credit_specification {
    cpu_credits = "standard"
  }
}

resource "aws_eip" "swarm-managers" {
  count    = local.managers_aws
  instance = aws_instance.swarm-managers[count.index].id
  vpc      = true
  depends_on = [
    aws_internet_gateway.gw,
    aws_route.internet_access,
    aws_instance.swarm-managers,
  ]
  tags = {
    Name    = "swarm-master"
    Cluster = var.cluster_name
  }
}

