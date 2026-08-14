terraform {
  required_version = "1.15.8"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.111.1"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.12.0-alpha.5"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
}
