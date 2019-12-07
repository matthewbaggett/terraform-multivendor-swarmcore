variable "cluster_name" {
  description = "Name your cluster"
  type        = string
}
variable "managers" {
  description = "How many managers do you want?"
  type        = number
  default     = 3
}
variable "workers" {
  description = "How many generic worker nodes do you want?"
  type        = number
  default     = 3
}

variable "cloud_config_extra_script" {
  description = "Additional script to run after cloud config"
  type        = string
  default     = ""
}

variable "environment_prefix" {
  default = "prod"
}

variable "default_disk_size_gb" {
  default     = 16
  type        = number
  description = "Default size of the boot disk for nodes"
}

variable "default_swap_size_gb" {
  default     = -1
  type        = number
  description = "Default size of the swap partition for nodes. -1 automatically allocates 12.5% of the volume."
}

variable "manager_docker_engine_labels" {
  default = [
  "manager"]
  type        = list(string)
  description = "Default engine labels applied to docker managers"
}

variable "worker_docker_engine_labels" {
  default = [
  "worker"]
  type        = list(string)
  description = "Default engine labels applied to generic docker workers"
}

# Provider enable flags
variable "enable_aws" {
  type    = bool
  default = false
}
variable "enable_linode" {
  type    = bool
  default = false
}
variable "enable_scaleway" {
  type    = bool
  default = false
}

# Persistent storage s3-alike bucket
variable "persistent_storage_s3_access_key" {
  type = string
}
variable "persistent_storage_s3_secret_key" {
  type = string
}
variable "persistent_storage_s3_endpoint" {
  type = string
}
variable "persistent_storage_s3_bucket" {
  type = string
}
variable "persistent_storage_s3_region" {
  type = string
}

# AWS Variables
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "aws_access_key" {
  type    = string
  default = ""
}
variable "aws_secret_key" {
  type    = string
  default = ""
}
variable "aws_manager_type" {
  type    = string
  default = "t3a.micro"
}
variable "aws_worker_type" {
  type    = string
  default = "t3a.nano"
}

# Scaleway variables
variable "scaleway_zone" {
  type    = string
  default = "fr-par-1"
}
variable "scaleway_region" {
  type    = string
  default = "fr-par"
}
variable "scaleway_access_key" {
  type    = string
  default = ""
}
variable "scaleway_secret_key" {
  type    = string
  default = ""
}
variable "scaleway_organization_id" {
  type    = string
  default = ""
}
variable "scaleway_default_region" {
  type    = string
  default = "eu-central"
}
variable "scaleway_manager_type" {
  type    = string
  default = "DEV1-S"
}
variable "scaleway_worker_type" {
  type    = string
  default = "DEV1-S"
}

# Linode variables
variable "linode_token" {
  type    = string
  default = ""
}
variable "linode_manager_type" {
  type    = string
  default = "g6-standard-1"
}
variable "linode_worker_type" {
  type    = string
  default = "g6-nanode-1"
}
variable "linode_default_region" {
  type = string
  default = "eu-central"
}

# Inherited from other project
variable "daemon_count" {
  description = "@todo refactor this out"
  default     = 0
}
variable "daemon_private_key_pems" {
  description = "These are private key PEMs to the manager nodes that will have their Docker sockets exposed.  Private key generation is not performed by this module.  If this starts with `/` then a symlink will be created instead of writing out the file."
  type        = list(string)
  default     = []
}

variable "daemon_cert_pems" {
  description = "These are cert PEMs to the manager nodes that will have their Docker sockets exposed.  These are the  `daemon_cert_request_pems` that are signed by the CA.   If this starts with `/` then a symlink will be created instead of writing out the file."
  type        = list(string)
  default     = []
}

# Locals
locals {
  divisor           = (var.enable_aws ? 1 : 0) + (var.enable_linode ? 1 : 0) + (var.enable_scaleway ? 1 : 0)
  managers_aws      = var.enable_aws ? ceil(var.managers / local.divisor) : 0
  managers_linode   = var.enable_linode ? ceil(var.managers / local.divisor) : 0
  managers_scaleway = var.enable_scaleway ? ceil(var.managers / local.divisor) : 0
  managers_total    = local.managers_aws + local.managers_scaleway + local.managers_linode
  workers_aws       = var.enable_aws ? ceil(var.workers / local.divisor) : 0
  workers_linode    = var.enable_linode ? ceil(var.workers / local.divisor) : 0
  workers_scaleway  = var.enable_scaleway ? ceil(var.workers / local.divisor) : 0
  workers_total     = local.workers_aws + local.workers_scaleway + local.workers_linode
  default_disk_size = var.default_disk_size_gb
  default_swap_size = ceil(var.default_swap_size_gb >= 0 ? var.default_swap_size_gb : (var.default_disk_size_gb / 100) * 12.5)
}