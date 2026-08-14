locals {
  controlplanes = {
    for i in range(var.control_plane_count) : tostring(i) => {
      cpu    = 8
      memory = 4096
    }
  }

  workers = {
    for i in range(var.worker_count) : tostring(i) => {
      cpu    = 16
      memory = 8192
    }
  }
}

# Get TalOS Linux ISO URL & Upgrade URL

data "talos_image_factory_urls" "guenivir_talos_image_registry" {
  talos_version = var.talos_version
  schematic_id  = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515"
  platform      = "nocloud"
}

resource "proxmox_download_file" "guenivir_talos_vm_image" {
  depends_on   = [data.talos_image_factory_urls.guenivir_talos_image_registry]
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve-dev"
  url          = data.talos_image_factory_urls.guenivir_talos_image_registry.urls.iso
  file_name    = "guenivir_talos_${var.talos_version}_nocloud.iso"
}

# Create VMs on Proxmox

resource "proxmox_virtual_environment_vm" "guenivir_controlplane" {
  depends_on  = [proxmox_download_file.guenivir_talos_vm_image]
  for_each    = local.controlplanes
  name        = "guenivir-controlplane-${tonumber(each.key) + 1}"
  description = "Managed by terraform - Guenivir controlplane"
  tags        = ["terraform", "guenivir", "talos", "controlplane"]

  node_name  = "pve-dev"
  vm_id      = 100 + tonumber(each.key)
  migrate    = true
  boot_order = ["scsi0", "ide3"]

  agent {
    enabled = true
    timeout = "15m"
  }

  stop_on_destroy = true

  machine       = "q35"
  bios          = "ovmf"
  scsi_hardware = "virtio-scsi-pci"

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores = each.value.cpu
    type  = "x86-64-v2-AES"
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
  name        = "guenivir-worker-${tonumber(each.key) + 1}"
  description = "Managed by terraform - Guenivir worker"
  tags        = ["terraform", "guenivir", "talos", "worker"]

  node_name  = "pve-dev"
  vm_id      = 200 + tonumber(each.key)
  migrate    = true
  boot_order = ["scsi0", "ide3"]

  agent {
    enabled = true
    timeout = "15m"
  }

  stop_on_destroy = true

  machine       = "q35"
  bios          = "ovmf"
  scsi_hardware = "virtio-scsi-pci"

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores = each.value.cpu
    type  = "x86-64-v2-AES"
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
