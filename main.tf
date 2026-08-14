

# Create proxmox VM
# Configure proxmox VM with gpu passthrough & various other package configurations + disk configurations
# Bootstrap k8s cluster on talos VMs
# Install flux operator into new k8s cluster
# Flux operator deploys the remaining infra stack for core components
# Features of the cluster's behavior can then be divided into other repositories

# Create cluster

module "create_cluster" {
  source = "./tf/create-demo-cluster"

  proxmox_api_url   = var.proxmox_api_url
  proxmox_api_token = var.proxmox_api_token
  talos_version     = var.talos_version
}

# Talos machine installation

resource "talos_machine_secrets" "guenivir_secrets" {
  talos_version = var.talos_version
}

data "talos_machine_configuration" "guenivir_controlplane" {
  depends_on       = [talos_machine_secrets.guenivir_secrets]
  talos_version    = var.talos_version
  cluster_name     = "guenivir"
  cluster_endpoint = module.create_cluster.endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.guenivir_secrets.machine_secrets
}

resource "talos_machine_configuration_apply" "guenivir_controlplane" {
  depends_on                  = [data.talos_machine_configuration.guenivir_controlplane]
  for_each                    = module.create_cluster.control_plane_ips
  node                        = each.value
  machine_configuration_input = data.talos_machine_configuration.guenivir_controlplane.machine_configuration
  client_configuration        = talos_machine_secrets.guenivir_secrets.client_configuration

  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk  = "/dev/sdd"
          image = "ghcr.io/siderolabs/installer:v1.12.6"
        }
      }
    })
  ]
}

data "talos_machine_configuration" "guenivir_worker" {
  depends_on       = [talos_machine_secrets.guenivir_secrets]
  talos_version    = var.talos_version
  cluster_name     = "guenivir"
  cluster_endpoint = module.create_cluster.endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.guenivir_secrets.machine_secrets
}

resource "talos_machine_configuration_apply" "guenivir_worker" {
  depends_on                  = [data.talos_machine_configuration.guenivir_worker]
  for_each                    = module.create_cluster.worker_ips
  node                        = each.value
  machine_configuration_input = data.talos_machine_configuration.guenivir_worker.machine_configuration
  client_configuration        = talos_machine_secrets.guenivir_secrets.client_configuration

  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk  = "/dev/sdd"
          image = "ghcr.io/siderolabs/installer:v1.12.6"
        }
      }
    })
  ]
}

resource "talos_machine_bootstrap" "guenivir_controlplane" {
  depends_on           = [talos_machine_configuration_apply.guenivir_controlplane]
  for_each             = module.create_cluster.control_plane_ips
  node                 = each.value
  client_configuration = talos_machine_secrets.guenivir_secrets.client_configuration
}

# Wait for talos to finish installing and come up ready

data "talos_cluster_health" "guenivir_health" {
  depends_on           = [talos_machine_bootstrap.guenivir_controlplane]
  client_configuration = talos_machine_secrets.guenivir_secrets.client_configuration
  control_plane_nodes  = [for k, v in module.create_cluster.control_plane_ips : v]
  worker_nodes         = [for k, v in module.create_cluster.worker_ips : v]
  endpoints            = [for k, v in module.create_cluster.control_plane_ips : v]

  timeouts = {
    read = "10m"
  }
}

# Extract information from testing cluster to host

data "talos_client_configuration" "guenivir" {
  depends_on           = [talos_machine_bootstrap.guenivir_controlplane, data.talos_cluster_health.guenivir_health]
  cluster_name         = "guenivir"
  nodes                = [for k, v in module.create_cluster.control_plane_ips : v]
  endpoints            = [for k, v in module.create_cluster.control_plane_ips : v]
  client_configuration = talos_machine_secrets.guenivir_secrets.client_configuration
}

resource "local_sensitive_file" "talosconfig" {
  depends_on      = [data.talos_client_configuration.guenivir]
  content         = data.talos_client_configuration.guenivir.talos_config
  filename        = pathexpand("~/.talos/config")
  file_permission = "0600"
}

resource "talos_cluster_kubeconfig" "guenivir-kubeconfig" {
  depends_on           = [talos_machine_bootstrap.guenivir_controlplane, data.talos_cluster_health.guenivir_health]
  client_configuration = talos_machine_secrets.guenivir_secrets.client_configuration
  node                 = module.create_cluster.control_plane_ips["0"]
}

resource "local_sensitive_file" "kubeconfig" {
  depends_on      = [talos_cluster_kubeconfig.guenivir-kubeconfig]
  content         = talos_cluster_kubeconfig.guenivir-kubeconfig.kubeconfig_raw
  filename        = pathexpand("~/.kube/config")
  file_permission = "0600"
}

# Install flux operator into kubernetes
