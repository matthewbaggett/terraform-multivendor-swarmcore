data "linode_instance_type" "swarm-workers" {
  count = local.workers_linode > 0 ? 1 : 0
  id    = var.linode_worker_type
}

resource "linode_instance" "swarm-worker" {
  count = local.workers_linode
  image = data.linode_image.base_image[0].id
  label = "swarm-worker-linode-${count.index}"
  group = var.cluster_name
  tags = [
    var.cluster_name,
  "swarm-worker"]
  region = var.linode_default_region
  type   = data.linode_instance_type.swarm-workers[0].id
  authorized_keys = [
  replace(file("~/.ssh/id_rsa.pub"), "\n", "")]

  swap_size      = 1024
  stackscript_id = linode_stackscript.cloud-init[0].id
  stackscript_data = {
    userdata = base64gzip(data.template_cloudinit_config.workers[0].rendered)
  }
}