provider "aws" {
  version    = "~> 2.30"
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

variable "base_ami" {
  default = "ubuntu-bionic-18.04-amd64-server-*"
  type    = string
}

data "aws_region" "current" {}

data "aws_availability_zones" "azs" {
  state = "available"
}

data "aws_ami" "base_ami" {
  most_recent = true
  name_regex  = var.base_ami
  owners = [
    "amazon",
  "self"]
}

resource "aws_security_group" "swarm" {
  name        = "swarm"
  description = "Docker Swarm ports"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Docker swarm management"
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    self        = true
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  ingress {
    description = "Docker container network discovery"
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    self        = true
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  ingress {
    description = "Docker container network discovery"
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    self        = true
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  ingress {
    description = "Docker overlay network"
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    self        = true
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  tags = {
    Name    = "swarm-master"
    Cluster = var.cluster_name
  }

  timeouts {
    create = "2m"
    delete = "2m"
  }
}

resource "aws_security_group" "daemon" {
  name        = "docker-daemon"
  description = "Docker Daemon port"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 2376
    to_port   = 2376
    protocol  = "tcp"
    self      = true
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  tags = {
    Name    = "swarm-master"
    Cluster = var.cluster_name
  }

  timeouts {
    create = "2m"
    delete = "2m"
  }
}

resource "aws_security_group" "sshaccess" {
  name        = "SSH Access"
  description = "SSH port"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
    "0.0.0.0/0"]
    self = true
  }

  tags = {
    Name    = "swarm-master"
    Cluster = var.cluster_name
  }

  timeouts {
    create = "2m"
    delete = "2m"
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.cluster_name}-${var.environment_prefix}-ec2"
  description        = "Allows reading of infrastructure secrets"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.cluster_name}-${var.environment_prefix}-ec2"
  role = aws_iam_role.ec2.name
}

data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = [
    "sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
      "ec2.amazonaws.com"]
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.10.0.0/16"
  tags = {
    Name = "${var.cluster_name} ${var.environment_prefix} VPC"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_subnet" "cluster" {
  depends_on = [
    data.aws_availability_zones.azs
  ]
  count                   = length(data.aws_availability_zones.azs.names)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 200 + count.index, )
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.cluster_name}-${data.aws_availability_zones.azs.names[count.index]}"
    Cluster = var.cluster_name
  }

  availability_zone = data.aws_availability_zones.azs.names[count.index]
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.cluster_name}-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
