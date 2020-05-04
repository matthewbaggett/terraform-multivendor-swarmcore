resource "scaleway_instance_security_group" "swarm-nodes" {
  count                   = local.managers_scaleway > 0 ? 1 : 0
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"
  name                    = "swarm-nodes"

  dynamic "inbound_rule" {
    for_each = local.tcp_ports
    content {
      action   = "accept"
      protocol = "TCP"
      port     = inbound_rule.value
    }
  }

  dynamic "inbound_rule" {
    for_each = local.udp_ports
    content {
      action   = "accept"
      protocol = "UDP"
      port     = inbound_rule.value
    }
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