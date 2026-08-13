

# Create proxmox VM
# Configure proxmox VM with gpu passthrough & various other package configurations + disk configurations
# Bootstrap k8s cluster on talos VMs
# Install flux operator into new k8s cluster
# Flux operator deploys the remaining infra stack for core components
# Features of the cluster's behavior can then be divided into other repositories

locals {
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
    for k, v in proxmox_virtual_environment_vm.guenivir-controlplane : k => [
      for ip in flatten(v.ipv4_addresses) : ip
      if startswith(ip, "192.168.") || (startswith(ip, "10.") && !startswith(ip, "100.")) || (startswith(ip, "172.") && ip != "127.0.0.1")
    ][0]
  }

  worker_ips = {
    for k, v in proxmox_virtual_environment_vm.guenivir-worker : k => [
      for ip in flatten(v.ipv4_addresses) : ip
      if startswith(ip, "192.168.") || (startswith(ip, "10.") && !startswith(ip, "100.")) || (startswith(ip, "172.") && ip != "127.0.0.1")
    ][0]
  }
}

# Get TalOS Linux ISO URL & Upgrade URL

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

# Create VMs on Proxmox

resource "proxmox_virtual_environment_vm" "guenivir-controlplane" {
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
    file_id = proxmox_download_file.guenivir-talos-vm-image.id
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

resource "proxmox_virtual_environment_vm" "guenivir-worker" {
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
    file_id = proxmox_download_file.guenivir-talos-vm-image.id
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

resource "talos_machine_secrets" "guenivir-secrets" {
  talos_version = "v1.13.8"
}

data "talos_machine_configuration" "guenivir-controlplane" {
  talos_version    = "v1.13.8"
  cluster_name     = "guenivir"
  cluster_endpoint = "https://${local.controlplane_ips["0"]}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.guenivir-secrets.machine_secrets
}

resource "talos_machine" "guenivir-controlplane" {
  for_each              = local.controlplanes
  node                  = local.controlplane_ips[each.key]
  client_configuration  = talos_machine_secrets.guenivir-secrets.client_configuration
  machine_configuration = data.talos_machine_configuration.guenivir-controlplane.machine_configuration
  image                 = data.talos_image_factory_urls.guenivir-talos-image-registry.urls.installer
  drain_on_upgrade      = false
}

resource "talos_machine_bootstrap" "guenivir-controlplane" {
  for_each             = local.controlplanes
  node                 = local.controlplane_ips[each.key]
  client_configuration = talos_machine_secrets.guenivir-secrets.client_configuration
}

resource "talos_cluster_kubeconfig" "guenivir-kubeconfig" {
  depends_on           = [talos_machine_bootstrap.guenivir-controlplane]
  client_configuration = talos_machine_secrets.guenivir-secrets.client_configuration
  node                 = local.controlplane_ips["0"]
}

data "talos_client_configuration" "guenivir" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.guenivir-secrets.client_configuration
  nodes                = [for k, v in local.controlplane_ips : v]
  endpoints            = [for k, v in local.controlplane_ips : v]
}

resource "local_sensitive_file" "talosconfig" {
  content         = data.talos_client_configuration.guenivir.talos_config
  filename        = pathexpand("~/.talos/config")
  file_permission = "0600"
}

resource "local_sensitive_file" "kubeconfig" {
  content         = talos_cluster_kubeconfig.guenivir-kubeconfig.kubeconfig_raw
  filename        = pathexpand("~/.kube/config")
  file_permission = "0600"
}

data "talos_machine_configuration" "guenivir-worker" {
  talos_version    = "v1.13.8"
  cluster_name     = "guenivir"
  cluster_endpoint = "https://${local.controlplane_ips["0"]}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.guenivir-secrets.machine_secrets
}

resource "talos_machine" "guenivir-worker" {
  for_each              = local.workers
  node                  = local.worker_ips[each.key]
  client_configuration  = talos_machine_secrets.guenivir-secrets.client_configuration
  machine_configuration = data.talos_machine_configuration.guenivir-worker.machine_configuration
  image                 = data.talos_image_factory_urls.guenivir-talos-image-registry.urls.installer
  drain_on_upgrade      = false
}

# Install FluxCD operator

module "flux-operator-bootstrap" {
  source  = "controlplaneio-fluxcd/flux-operator-bootstrap/kubernetes"
  version = "0.8.0"

  revision = var.flux_operator_bootstrap_revision

  gitops_resources = {
    instance_yaml = file("${path.root}/k8s/clusters/${var.cluster_name}/flux-instance.yaml")
  }
}
