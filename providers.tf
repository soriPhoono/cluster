terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.111.1"
    }
  }
}

variable "debug_mode" {
  type        = bool
  description = "Whether or not to run this pipeline in debug mode or in production mode"
}

variable "tailnet_fqdn" {
  type        = string
  description = "The magic DNS prefix for your tailnet"
}

variable "proxmox_api_url" {
  type        = string
  description = "The api url endpoint to use to connect via API key over https"
  default     = null
}

variable "proxmox_api_token" {
  type        = string
  description = "The api token of the SA on proxmox to create the cluster and provision it's VMs and other resources"
  sensitive   = true
}

locals {
  proxmox_api_url = coalesce(var.proxmox_api_url, "https://pve-dev.${var.tailnet_fqdn}")
}

provider "proxmox" {
  endpoint  = local.proxmox_api_url
  api_token = var.proxmox_api_token
}

resource "proxmox_virtual_environment_vm" "test" {
  name        = "terraform-provider-test"
  description = "Managed by Terraform"
  tags        = ["terraform", "talos"]

  node_name = "guenivir-controlplane"
  vm_id     = 100

  bios = "ovmf"

  agent {
    enabled = true
  }

  stop_on_destroy = true

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES" # recommended for modern CPUs
  }

  memory {
    dedicated = 8192
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_virtual_environment_download_file.latest_ubuntu_22_jammy_qcow2_img.id
    interface    = "scsi0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      keys = [trimspace()]
    }
  }

}

resource "proxmox_virtual_environment_download_file" "latest_ubuntu_22_jammy_qcow2_img" {
  content_type = "import"
  datastore_id = "local"
  node_name    = "pve"
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  # need to rename the file to *.qcow2 to indicate the actual file format for import
  file_name = "jammy-server-cloudimg-amd64.qcow2"
}
