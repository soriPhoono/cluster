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

variable "tailscale_oauth_client_id" {
  type      = string
  sensitive = true
}

variable "tailscale_oauth_client_secret" {
  type      = string
  sensitive = true
}

provider "proxmox" {
  endpoint  = "https://pve:8006/api2/json"
  api_token = "terraform@pve!cluster-primary=${var.proxmox_api_secret}"
  insecure  = true
}

provider "tailscale" {
  oauth_client_id     = var.tailscale_oauth_client_id
  oauth_client_secret = var.tailscale_oauth_client_secret
}

provider "talos" {
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
      id           = 0
      name         = "cluster-manager-1"
      memory       = 4096
      disk         = 40
      ip           = "192.168.1.225"
      machine_type = "controlplane"
    }
    worker_1 = {
      id           = 1
      name         = "cluster-worker-1"
      memory       = 8192
      disk         = 40
      ip           = "192.168.1.226"
      machine_type = "worker"
    }
  }
  cluster_name     = "talos-proxmox-cluster"
  cluster_endpoint = "https://192.168.1.225:6443"
}

resource "tailscale_tailnet_key" "cluster" {
  reusable      = true
  ephemeral     = false
  preauthorized = true
  tags          = ["tag:adams"]
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

resource "talos_machine_secrets" "cluster" {}

resource "talos_machine_configuration_apply" "cluster" {
  for_each = local.nodes

  client_configuration        = talos_machine_secrets.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.cluster[each.key].machine_configuration
  node                        = proxmox_virtual_environment_vm.cluster[each.key].ipv4_addresses[1][0]
}

data "talos_machine_configuration" "cluster" {
  for_each = local.nodes

  cluster_name     = local.cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_type     = each.value.machine_type
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets

  config_patches = [
    yamlencode({
      machine = {
        network = {
          hostname = each.value.name
          interfaces = [
            {
              interface = "eth0"
              dhcp      = false
              addresses = ["${each.value.ip}/24"]
              routes = [
                {
                  network = "0.0.0.0/0"
                  gateway = "192.168.1.1"
                }
              ]
            }
          ]
        }
        features = {
          tailscale = {
            enabled = true
            authKey = tailscale_tailnet_key.cluster.key
          }
        }
      }
    })
  ]
}

resource "talos_machine_bootstrap" "cluster" {
  depends_on = [
    talos_machine_configuration_apply.cluster
  ]

  client_configuration = talos_machine_secrets.cluster.client_configuration
  node                 = local.nodes.manager_1.ip
}

resource "talos_cluster_kubeconfig" "cluster" {
  depends_on = [
    talos_machine_bootstrap.cluster
  ]

  client_configuration = talos_machine_secrets.cluster.client_configuration
  node                 = local.nodes.manager_1.ip
}

resource "local_file" "talosconfig" {
  content  = talos_machine_secrets.cluster.client_configuration
  filename = "${path.module}/generated/talosconfig"
}

resource "local_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.cluster.kubeconfig_raw
  filename = "${path.module}/generated/kubeconfig"
}
