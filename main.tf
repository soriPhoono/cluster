

# Create proxmox VM
# Configure proxmox VM with gpu passthrough & various other package configurations + disk configurations
# Bootstrap k8s cluster on talos VMs
# Install flux operator into new k8s cluster
# Flux operator deploys the remaining infra stack for core components
# Features of the cluster's behavior can then be divided into other repositories

locals {
  talos_version = "v1.13.8"

  controlplanes = {
    0 = {
      cpu    = 4
      memory = 4096
    }
  }
  workers = {
    0 = {
      cpu    = 8
      memory = 8192
    }
  }

  controlplane_ips = {
    for k, v in proxmox_virtual_environment_vm.guenivir_controlplane : k => [
      for ip in flatten(v.ipv4_addresses) : ip
      if startswith(ip, "192.168.") || (startswith(ip, "10.") && !startswith(ip, "100.")) || (startswith(ip, "172.") && ip != "127.0.0.1")
    ][0]
  }

  worker_ips = {
    for k, v in proxmox_virtual_environment_vm.guenivir_worker : k => [
      for ip in flatten(v.ipv4_addresses) : ip
      if startswith(ip, "192.168.") || (startswith(ip, "10.") && !startswith(ip, "100.")) || (startswith(ip, "172.") && ip != "127.0.0.1")
    ][0]
  }
}

# Get TalOS Linux ISO URL & Upgrade URL

data "talos_image_factory_urls" "guenivir_talos_image_registry" {
  talos_version = local.talos_version
  schematic_id  = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515"
  platform      = "nocloud"
}

resource "proxmox_download_file" "guenivir_talos_vm_image" {
  depends_on   = [data.talos_image_factory_urls.guenivir_talos_image_registry]
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve-dev"
  url          = data.talos_image_factory_urls.guenivir_talos_image_registry.urls.iso
  file_name    = "guenivir_talos_${local.talos_version}_nocloud.iso"
}

# Create VMs on Proxmox

resource "proxmox_virtual_environment_vm" "guenivir_controlplane" {
  depends_on  = [proxmox_download_file.guenivir_talos_vm_image]
  for_each    = local.controlplanes
  name        = "guenivir-controlplane-${each.key + 1}"
  description = "Managed by terraform - Guenivir controlplane"
  tags        = ["terraform", "guenivir", "talos", "controlplane"]

  node_name = "pve-dev"
  vm_id     = 100 + each.key
  migrate   = true

  agent {
    enabled = true
  }

  stop_on_destroy = true

  machine = "q35"
  bios    = "ovmf"
  # scsi_hardware = "virtio-scsi-pci"

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores = each.value.cpu
    type  = "x86-64-v2-AES" # recommended for modern CPUs
  }

  memory {
    dedicated = each.value.memory
  }

  tpm_state {}

  cdrom {
    file_id = proxmox_download_file.guenivir_talos_vm_image.id
  }

  efi_disk {
    type = "4m"
  }

  disk {
    interface   = "scsi0"
    file_format = "raw"
    discard     = "on"
    ssd         = true
  }

  network_device {}

  operating_system {
    type = "l26"
  }
}

resource "proxmox_virtual_environment_vm" "guenivir_worker" {
  depends_on  = [proxmox_download_file.guenivir_talos_vm_image]
  for_each    = local.workers
  name        = "guenivir-worker-${each.key + 1}"
  description = "Managed by terraform - Guenivir worker"
  tags        = ["terraform", "guenivir", "talos", "worker"]

  node_name = "pve-dev"
  vm_id     = 200 + each.key
  migrate   = true

  agent {
    enabled = true
  }

  stop_on_destroy = true

  machine = "q35"
  bios    = "ovmf"
  # scsi_hardware = "virtio-scsi-pci"

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores = each.value.cpu
    type  = "x86-64-v2-AES" # recommended for modern CPUs
  }

  memory {
    dedicated = each.value.memory
  }

  tpm_state {}

  cdrom {
    file_id = proxmox_download_file.guenivir_talos_vm_image.id
  }

  efi_disk {
    type = "4m"
  }

  disk {
    interface   = "scsi0"
    file_format = "raw"
    discard     = "on"
    ssd         = true
  }

  network_device {}

  operating_system {
    type = "l26"
  }
}

# Talos machine installation

resource "talos_machine_secrets" "guenivir_secrets" {
  talos_version = local.talos_version
}

data "talos_machine_configuration" "guenivir_controlplane" {
  depends_on       = [talos_machine_secrets.guenivir_secrets]
  talos_version    = "v1.13.8"
  cluster_name     = "guenivir"
  cluster_endpoint = "https://${local.controlplane_ips["0"]}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.guenivir_secrets.machine_secrets
}

resource "talos_machine_configuration_apply" "guenivir_controlplane" {
  for_each                    = local.controlplane_ips
  depends_on                  = [data.talos_machine_configuration.guenivir_controlplane]
  node                        = each.value
  machine_configuration_input = data.talos_machine_configuration.guenivir_controlplane.machine_configuration
  client_configuration        = talos_machine_secrets.guenivir_secrets.client_configuration
}

data "talos_machine_configuration" "guenivir_worker" {
  depends_on       = [talos_machine_secrets.guenivir_secrets]
  talos_version    = "v1.13.8"
  cluster_name     = "guenivir"
  cluster_endpoint = "https://${local.controlplane_ips["0"]}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.guenivir_secrets.machine_secrets
}

resource "talos_machine_configuration_apply" "guenivir_worker" {
  for_each                    = local.worker_ips
  depends_on                  = [data.talos_machine_configuration.guenivir_worker]
  node                        = each.value
  machine_configuration_input = data.talos_machine_configuration.guenivir_worker.machine_configuration
  client_configuration        = talos_machine_secrets.guenivir_secrets.client_configuration
}

resource "talos_machine_bootstrap" "guenivir_controlplane" {
  depends_on = [
    talos_machine_configuration_apply.guenivir_controlplane
  ]
  for_each             = local.controlplanes
  node                 = local.controlplane_ips[each.key]
  client_configuration = talos_machine_secrets.guenivir_secrets.client_configuration
}

# resource "talos_machine_bootstrap" "guenivir_worker" {
#   depends_on = [
#     talos_machine_configuration_apply.guenivir_worker
#   ]
#   for_each             = local.workers
#   node                 = local.worker_ips[each.key]
#   client_configuration = talos_machine_secrets.guenivir_secrets.client_configuration
# }

data "talos_cluster_health" "guenivir_health" {
  depends_on = [
    talos_machine_bootstrap.guenivir_controlplane
    # , talos_machine_bootstrap.guenivir_worker
  ]
  client_configuration = talos_machine_secrets.guenivir_secrets.client_configuration
  control_plane_nodes  = [for k, v in local.controlplane_ips : v]
  worker_nodes         = [for k, v in local.worker_ips : v]
  endpoints            = [for k, v in local.controlplane_ips : v]
}

data "talos_client_configuration" "guenivir" {
  depends_on = [
    talos_machine_bootstrap.guenivir_controlplane,
    data.talos_cluster_health.guenivir_health
  ]
  cluster_name         = var.cluster_name
  nodes                = [for k, v in local.controlplane_ips : v]
  endpoints            = [for k, v in local.controlplane_ips : v]
  client_configuration = talos_machine_secrets.guenivir_secrets.client_configuration
}

resource "local_sensitive_file" "talosconfig" {
  depends_on      = [data.talos_client_configuration.guenivir]
  content         = data.talos_client_configuration.guenivir.talos_config
  filename        = pathexpand("~/.talos/config")
  file_permission = "0600"
}

resource "talos_cluster_kubeconfig" "guenivir-kubeconfig" {
  depends_on           = [talos_machine_bootstrap.guenivir_controlplane]
  client_configuration = talos_machine_secrets.guenivir_secrets.client_configuration
  node                 = local.controlplane_ips["0"]
}

resource "local_sensitive_file" "kubeconfig" {
  content         = talos_cluster_kubeconfig.guenivir-kubeconfig.kubeconfig_raw
  filename        = pathexpand("~/.kube/config")
  file_permission = "0600"
}
