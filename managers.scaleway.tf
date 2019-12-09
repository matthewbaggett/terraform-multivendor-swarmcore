resource "scaleway_instance_security_group" "swarm-managers" {
  count                   = local.managers_scaleway > 0 ? 1 : 0
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  inbound_rule {
    action = "accept"
    port   = 2376
  }

  inbound_rule {
    action = "accept"
    port   = 2377
  }

  inbound_rule {
    action = "accept"
    port   = 7946
  }

  inbound_rule {
    action = "accept"
    port   = 4789
  }

  inbound_rule {
    action = "accept"
    port   = "22"
  }

  inbound_rule {
    action = "accept"
    port   = "80"
  }

  inbound_rule {
    action = "accept"
    port   = "443"
  }
}

resource "scaleway_instance_server" "swarm-manager" {
  count = local.managers_scaleway
  type  = "DEV1-S"
  image = data.scaleway_image.ubuntu[0].id
  name  = "swarm-manager-scaleway-${count.index}"

  tags = [var.cluster_name, "swarm", "manager"]

  security_group_id = scaleway_instance_security_group.swarm-managers[0].id

  root_volume {
    # Disk size must be 20GB in scaleway
    size_in_gb            = local.default_disk_size <= 20 ? 20 : local.default_disk_size
    delete_on_termination = true
  }

  cloud_init = data.template_cloudinit_config.managers[count.index].rendered
}

resource "scaleway_instance_ip" "swarm_manager_ip" {
  count     = local.managers_scaleway
  server_id = scaleway_instance_server.swarm-manager[count.index].id
}