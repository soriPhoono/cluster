terraform {
  required_version = "1.15.8"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }

    proxmox = {
      source  = "bpg/proxmox"
      version = "0.111.1"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.12.0-alpha.5"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.2.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.2.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
}

provider "kubernetes" {
  host                   = talos_cluster_kubeconfig.guenivir-kubeconfig.kubernetes_client_configuration.host
  client_certificate     = base64decode(talos_cluster_kubeconfig.guenivir-kubeconfig.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(talos_cluster_kubeconfig.guenivir-kubeconfig.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.guenivir-kubeconfig.kubernetes_client_configuration.ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = talos_cluster_kubeconfig.guenivir-kubeconfig.kubernetes_client_configuration.host
    client_certificate     = base64decode(talos_cluster_kubeconfig.guenivir-kubeconfig.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.guenivir-kubeconfig.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.guenivir-kubeconfig.kubernetes_client_configuration.ca_certificate)
  }
}
