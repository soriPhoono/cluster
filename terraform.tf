terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
    tailscale = {
      source = "tailscale/tailscale"
    }
    talos = {
      source = "siderolabs/talos"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

variable "proxmox_api_secret" {
  type      = string
  sensitive = true
}

provider "proxmox" {
  endpoint  = "https://pve:8006/api2/json"
  api_token = "terraform@pve!cluster-primary=${var.proxmox_api_secret}"
  insecure  = true
}

resource "proxmox_virtual_environment_file" "talos_iso" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"
  source_file {
    path = "https://github.com/siderolabs/talos/releases/download/v1.12.4/metal-amd64.iso"
  }
}

resource "proxmox_virtual_environment_vm" "cluster_manager_1" {
  name      = "cluster-manager-1"
  node_name = "pve"

  cpu {
    cores = 4
  }
  memory {
    dedicated = 4096
  }

  machine = "q35"
  bios    = "ovmf"

  efi_disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    type         = "4m"
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "virtio0"
    size         = 40
  }

  cdrom {
    file_id = proxmox_virtual_environment_file.talos_iso.id
  }

  operating_system {
    type = "l26"
  }

  boot_order = ["virtio0", "ide2"]
}

resource "proxmox_virtual_environment_vm" "cluster_worker_1" {
  name      = "cluster-worker-1"
  node_name = "pve"

  cpu {
    cores = 4
  }
  memory {
    dedicated = 8192
  }

  machine = "q35"
  bios    = "ovmf"

  efi_disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    type         = "4m"
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "virtio0"
    size         = 100
  }

  cdrom {
    file_id = proxmox_virtual_environment_file.talos_iso.id
  }

  operating_system {
    type = "l26"
  }

  boot_order = ["virtio0", "ide2"]
}
