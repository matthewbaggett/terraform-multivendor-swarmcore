provider "template" {
  version = "~> 2.1"
}

data "template_file" "init_daemon" {
  count    = local.managers_total
  template = file("${path.module}/scripts/init_daemon.py")

  vars = {
    daemon_count   = var.daemon_count
    instance_index = count.index
    private_key = count.index < var.daemon_count ? concat(var.daemon_private_key_pems, [
    ""])[count.index] : ""
    cert = count.index < var.daemon_count ? concat(var.daemon_cert_pems, [
    ""])[count.index] : ""
    ca_cert = ""
  }
}

data "template_file" "init_manager" {
  count    = local.managers_total
  template = file("${path.module}/scripts/init_manager.py")

  vars = {
    environment    = var.environment_prefix
    s3_access_key  = var.persistent_storage_s3_access_key
    s3_secret_key  = var.persistent_storage_s3_secret_key
    s3_endpoint    = var.persistent_storage_s3_endpoint
    s3_bucket      = var.persistent_storage_s3_bucket
    s3_region_name = var.persistent_storage_s3_region
    instance_index = count.index
    swapsize       = local.default_swap_size
  }
}

data "template_cloudinit_config" "managers" {
  count         = local.managers_total
  gzip          = "true"
  base64_encode = "true"

  part {
    content = file("${path.module}/scripts/common.cloud-config")
  }

  part {
    filename     = "extra.cloud-config"
    content      = file("${path.module}/scripts/users.cloud-config")
    content_type = "text/cloud-config"
  }

  part {
    filename     = "init_daemon.py"
    content      = data.template_file.init_daemon[count.index].rendered
    content_type = "text/x-shellscript"
  }

  part {
    filename     = "init_manager.py"
    content      = data.template_file.init_manager[count.index].rendered
    content_type = "text/x-shellscript"
  }

  part {
    filename     = "extra.sh"
    content      = var.cloud_config_extra_script
    content_type = "text/x-shellscript"
  }
}

data "template_file" "init_worker" {
  count    = local.workers_total
  template = file("${path.module}/scripts/init_worker.py")

  vars = {
    environment    = var.environment_prefix
    s3_access_key  = var.persistent_storage_s3_access_key
    s3_secret_key  = var.persistent_storage_s3_secret_key
    s3_endpoint    = var.persistent_storage_s3_endpoint
    s3_bucket      = var.persistent_storage_s3_bucket
    s3_region_name = var.persistent_storage_s3_region
    instance_index = count.index
    swapsize       = local.default_swap_size
  }
}

data "template_cloudinit_config" "workers" {
  count         = local.workers_total > 0 ? 1 : 0
  gzip          = "true"
  base64_encode = "true"

  part {
    content = file("${path.module}/scripts/common.cloud-config")
  }

  part {
    filename     = "extra.cloud-config"
    content      = file("${path.module}/scripts/users.cloud-config")
    content_type = "text/cloud-config"
  }

  part {
    filename     = "init_worker.py"
    content      = data.template_file.init_worker[count.index].rendered
    content_type = "text/x-shellscript"
  }

  part {
    filename     = "extra.sh"
    content      = var.cloud_config_extra_script
    content_type = "text/x-shellscript"
  }
}
