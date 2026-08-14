locals {
  controlplane_ips = {
    for k, v in proxmox_virtual_environment_vm.guenivir_controlplane : k => coalescelist(
      [for ip in flatten(v.ipv4_addresses) : ip if startswith(ip, "100.")],
      [for ip in flatten(v.ipv4_addresses) : ip if startswith(ip, "192.168.")],
      [""]
    )[0]
  }

  worker_ips = {
    for k, v in proxmox_virtual_environment_vm.guenivir_worker : k => coalescelist(
      [for ip in flatten(v.ipv4_addresses) : ip if startswith(ip, "100.")],
      [for ip in flatten(v.ipv4_addresses) : ip if startswith(ip, "192.168.")],
      [""]
    )[0]
  }
}

output "endpoint" {
  description = "The kubectl endpoint for the kubernetes api"
  value       = "https://${local.controlplane_ips["0"]}:6443"
}

output "control_plane_ips" {
  value = local.controlplane_ips
}

output "worker_ips" {
  value = local.worker_ips
}
