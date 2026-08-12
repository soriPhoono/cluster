

# Create proxmox VM
# Configure proxmox VM with gpu passthrough & various other package configurations + disk configurations
# Configure proxmox VMs in proxmox VM to run talos linux if possible
# If successful configure talos vms with persist-able vm configuration
# Bootstrap k8s cluster on talos VMs
# Install flux operator into new k8s cluster
# Flux operator deploys the remaining infra stack for core components
# Features of the cluster's behavior can then be divided into other repositories

data "talos_image_factory_urls" "guenivir-talos-image-registry" {
  talos_version = "v1.13.8"
  schematic_id  = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515"
  platform      = "nocloud"
}

resource "proxmox_download_file" "guenivir-talos-vm-image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve-dev"
  url          = data.talos_image_factory_urls.guenivir-talos-image-registry.urls.iso
  file_name    = "guenivir-talos-v1.3.3-nocloud.iso"
}

resource "proxmox_virtual_environment_vm" "guenivir-controlplane" {
  name        = "guenivir-controlplane"
  description = "Managed by terraform"
  tags        = ["terraform", "guenivir", "talos", "controlplane"]

  node_name = "pve-dev"
  vm_id     = 100
  migrate   = true

  agent {
    enabled = true
  }

  stop_on_destroy = true

  machine = "q35"
  bios    = "ovmf"

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores = 4
    type  = "x86-64-v2-AES" # recommended for modern CPUs
  }

  memory {
    dedicated = 8192
  }

  scsi_hardware = virtio-scsi-pci

  cdrom {
    enabled = true
    file_id = proxmox_download_file.guenivir-talos-vm-image.id
  }

  efi_disk {
    type = "4m"
  }

  disk {
    file_format = "qcow2"
    discard     = "on"
    ssd         = true
  }
}
