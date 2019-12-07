output "enabled_aws" {
  value = var.enable_aws ? "Yes" : "No"
}
output "enabled_linode" {
  value = var.enable_linode ? "Yes" : "No"
}
output "enabled_scaleway" {
  value = var.enable_scaleway ? "Yes" : "No"
}

output "count_managers_provisioned" {
  value = local.managers_total
}

output "disk_size" {
  value = local.default_disk_size
}
output "swap_size" {
  value = local.default_swap_size
}

output "manager_ips_linode" {
  value = linode_instance.swarm-manager.*.ip_address
}
output "manager_ips_scaleway" {
  value = scaleway_instance_ip.swarm_manager_ip.*.address
}
output "manager_ips_aws" {
  value = aws_eip.swarm-managers.*.public_ip
}
output "worker_ips_linode" {
  value = linode_instance.swarm-worker.*.ip_address
}
output "worker_ips_scaleway" {
  value = scaleway_instance_ip.swarm_worker_ip.*.address
}
output "worker_ips_aws" {
  value = aws_eip.swarm-workers.*.public_ip
}

output "all_manager_ips" {
  value = concat(
    linode_instance.swarm-manager.*.ip_address,
    scaleway_instance_ip.swarm_manager_ip.*.address,
    aws_eip.swarm-managers.*.public_ip
  )
}

output "all_worker_ips" {
  value = concat(
    linode_instance.swarm-worker.*.ip_address,
    scaleway_instance_ip.swarm_worker_ip.*.address,
    aws_eip.swarm-workers.*.public_ip,
  )
}
