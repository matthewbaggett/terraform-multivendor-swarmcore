resource "scaleway_instance_security_group" "swarm-nodes" {
  count                   = local.managers_scaleway > 0 ? 1 : 0
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"
  name                    = "swarm-nodes"

  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = 2377
  }

  inbound_rule {
    action   = "accept"
    protocol = "ANY"
    port     = 7946
  }

  inbound_rule {
    action   = "accept"
    protocol = "UDP"
    port     = 4789
  }

  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = 22
  }

  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = 80
  }

  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = 443
  }

  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = 27015
  }

  inbound_rule {
    action   = "accept"
    protocol = "UDP"
    port     = "34197"
  }
}

resource "scaleway_instance_server" "swarm-manager" {
  count = local.managers_scaleway
  type  = "DEV1-S"
  image = data.scaleway_image.ubuntu[0].id
  name  = "swarm-manager-scaleway-${count.index}"

  tags = [var.cluster_name, "swarm", "manager"]

  security_group_id = scaleway_instance_security_group.swarm-nodes[0].id

  root_volume {
    # Disk size must be 20GB in scaleway
    size_in_gb            = local.default_disk_size <= 20 ? 20 : local.default_disk_size
    delete_on_termination = true
  }

  cloud_init = data.template_cloudinit_config.managers[count.index].rendered

  ip_id = scaleway_instance_ip.swarm_manager_ip[count.index].id

  placement_group_id = scaleway_instance_placement_group.swarm.id
}

resource "scaleway_instance_ip" "swarm_manager_ip" {
  count = local.managers_scaleway
}