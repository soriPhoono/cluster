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
  host                   = module.create-cluster.endpoint
  client_certificate     = module.create-cluster.client-certificate
  client_key             = module.create-cluster.client-key
  cluster_ca_certificate = module.create-cluster.cluster-ca-certificate
}

provider "helm" {
  kubernetes = {
    host                   = module.create-cluster.endpoint
    client_certificate     = module.create-cluster.client-certificate
    client_key             = module.create-cluster.client-key
    cluster_ca_certificate = module.create-cluster.cluster-ca-certificate
  }
}
