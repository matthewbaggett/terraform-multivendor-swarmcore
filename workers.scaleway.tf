resource "scaleway_instance_server" "swarm-worker" {
  count = local.workers_scaleway
  type  = var.scaleway_worker_type
  image = data.scaleway_image.ubuntu[0].id
  name  = "swarm-worker-scaleway-${count.index}"

  tags = [
    var.cluster_name,
    "swarm",
  "worker"]

  security_group_id = scaleway_instance_security_group.swarm-nodes[0].id

  root_volume {
    # Disk size must be 20GB in scaleway
    size_in_gb            = local.default_disk_size <= 20 ? 20 : local.default_disk_size
    delete_on_termination = true
  }

  cloud_init = data.template_cloudinit_config.workers[0].rendered

  ip_id = scaleway_instance_ip.swarm_worker_ip[count.index].id

  placement_group_id = scaleway_instance_placement_group.swarm.id
}

resource "scaleway_instance_ip" "swarm_worker_ip" {
  count = local.workers_scaleway
}