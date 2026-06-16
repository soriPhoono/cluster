terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.2.0"
    }
  }
}

provider "kubernetes" {
  host                   = module.create-cluster.cluster-host
  client_certificate     = module.create-cluster.cluster-client-certificate
  client_key             = module.create-cluster.cluster-client-key
  cluster_ca_certificate = module.create-cluster.cluster-ca-certificate
}

provider "helm" {
  kubernetes = {
    host                   = module.create-cluster.cluster-host
    client_certificate     = module.create-cluster.cluster-client-certificate
    client_key             = module.create-cluster.cluster-client-key
    cluster_ca_certificate = module.create-cluster.cluster-ca-certificate
  }
}