data "linode_image" "base_image" {
  count = local.managers_linode > 0 ? 1 : 0
  id    = "linode/ubuntu18.04"
}

data "linode_instance_type" "swarm-masters" {
  count = local.managers_linode > 0 ? 1 : 0
  id    = var.linode_manager_type
}

resource "linode_stackscript" "cloud-init" {
  count       = local.managers_linode > 0 ? 1 : 0
  description = "Cloud Init compatability startup script"
  images      = [data.linode_image.base_image[0].id]
  label       = "cloudinit"
  script      = file("${path.module}/scripts/linode.cloud-init.stackscript.sh")
}

resource "linode_instance" "swarm-manager" {
  count           = local.managers_linode
  image           = data.linode_image.base_image[0].id
  label           = "swarm-manager-linode-${count.index}"
  group           = var.cluster_name
  tags            = [var.cluster_name, "swarm-master"]
  region          = var.linode_default_region
  type            = data.linode_instance_type.swarm-masters[0].id
  authorized_keys = [replace(file("~/.ssh/id_rsa.pub"), "\n", "")]

  swap_size      = 1024
  stackscript_id = linode_stackscript.cloud-init[0].id
  stackscript_data = {
    userdata = data.template_cloudinit_config.managers[count.index].rendered
  }
}