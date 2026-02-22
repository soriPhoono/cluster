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
    path = "https://factory.talos.dev/image/780d976716e800d05604b9dd8d41928a97c1ad38f36d4c8276d35984aa947865/v1.12.4/metal-amd64.iso"
  }
}

locals {
  project_id = 200
  nodes = {
    manager_1 = {
      id     = 0
      name   = "cluster-manager-1"
      memory = 4096
      disk   = 40
    }
    worker_1 = {
      id     = 1
      name   = "cluster-worker-1"
      memory = 8192
      disk   = 40
    }
  }
}

resource "proxmox_virtual_environment_vm" "cluster" {
  for_each = local.nodes

  name      = each.value.name
  node_name = "pve"
  vm_id     = local.project_id + each.value.id

  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }
  memory {
    dedicated = each.value.memory
  }

  machine = "q35"
  bios    = "ovmf"

  tpm_state {
    datastore_id = "local-lvm"
    version      = "v2.0"
  }

  efi_disk {
    datastore_id      = "local-lvm"
    file_format       = "raw"
    type              = "4m"
    pre_enrolled_keys = true
  }

  agent {
    enabled = true
  }

  network_device {
    bridge   = "vmbr0"
    firewall = true
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "virtio0"
    size         = each.value.disk
    cache        = "writethrough"
    discard      = "on"
  }

  cdrom {
    file_id = proxmox_virtual_environment_file.talos_iso.id
  }

  operating_system {
    type = "l26"
  }

  boot_order = ["virtio0", "ide2"]
}
