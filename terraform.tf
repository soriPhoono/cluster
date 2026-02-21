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
    path = "https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/v1.12.4/metal-amd64.iso"
  }
}

locals {
  nodes = {
    manager_1 = {
      name   = "cluster-manager-1"
      memory = 4096
      disk   = 40
    }
    worker_1 = {
      name   = "cluster-worker-1"
      memory = 8192
      disk   = 100
    }
  }
}

resource "proxmox_virtual_environment_vm" "cluster" {
  for_each = local.nodes

  name      = each.value.name
  node_name = "pve"

  cpu {
    cores = 4
  }
  memory {
    dedicated = each.value.memory
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
    size         = each.value.disk
  }

  cdrom {
    file_id = proxmox_virtual_environment_file.talos_iso.id
  }

  operating_system {
    type = "l26"
  }

  boot_order = ["virtio0", "ide2"]
}

moved {
  from = proxmox_virtual_environment_vm.cluster_manager_1
  to   = proxmox_virtual_environment_vm.cluster["manager_1"]
}

moved {
  from = proxmox_virtual_environment_vm.cluster_worker_1
  to   = proxmox_virtual_environment_vm.cluster["worker_1"]
}
