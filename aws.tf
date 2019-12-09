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
  count = var.enable_aws ? 1 : 0
  state = "available"
}

data "aws_ami" "base_ami" {
  count       = var.enable_aws ? 1 : 0
  most_recent = true
  name_regex  = var.base_ami
  owners      = ["amazon", "self"]
}

resource "aws_security_group" "swarm" {
  count       = var.enable_aws ? 1 : 0
  name        = "swarm"
  description = "Docker Swarm ports"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    description = "Docker swarm management"
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Docker container network discovery"
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Docker container network discovery"
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    self        = true
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Docker overlay network"
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    self        = true
    cidr_blocks = ["0.0.0.0/0"]
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
  count       = var.enable_aws ? 1 : 0
  name        = "docker-daemon"
  description = "Docker Daemon port"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    from_port   = 2376
    to_port     = 2376
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_security_group" "ssh-access" {
  count       = var.enable_aws ? 1 : 0
  name        = "SSH Access"
  description = "SSH port"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
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
  count              = var.enable_aws ? 1 : 0
  name               = "${var.cluster_name}-${var.environment_prefix}-ec2"
  description        = "Allows reading of infrastructure secrets"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
}

resource "aws_iam_instance_profile" "ec2" {
  count = var.enable_aws ? 1 : 0
  name  = "${var.cluster_name}-${var.environment_prefix}-ec2"
  role  = aws_iam_role.ec2[0].name
}

data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_vpc" "main" {
  count      = var.enable_aws ? 1 : 0
  cidr_block = "10.10.0.0/16"
  tags = {
    Name = "${var.cluster_name} ${var.environment_prefix} VPC"
  }
}

resource "aws_internet_gateway" "gw" {
  count  = var.enable_aws ? 1 : 0
  vpc_id = aws_vpc.main[0].id
}

resource "aws_route" "internet_access" {
  count                  = var.enable_aws ? 1 : 0
  route_table_id         = aws_vpc.main[0].main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw[0].id
}

resource "aws_subnet" "cluster" {
  depends_on              = [data.aws_availability_zones.azs[0]]
  count                   = var.enable_aws ? length(data.aws_availability_zones.azs[0].names) : 0
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(aws_vpc.main[0].cidr_block, 8, 200 + count.index, )
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.cluster_name}-${data.aws_availability_zones.azs[0].names[count.index]}"
    Cluster = var.cluster_name
  }

  availability_zone = data.aws_availability_zones.azs[0].names[count.index]
}

resource "aws_key_pair" "deployer" {
  count      = var.enable_aws ? 1 : 0
  key_name   = "${var.cluster_name}-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
