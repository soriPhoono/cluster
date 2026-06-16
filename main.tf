locals {
  ghcr_auth_dockerconfigjson = jsonencode({
    auths = {
      "ghcr.io" = {
        username = "flux"
        password = var.ghcr-pat
        auth     = base64encode("flux:${var.ghcr-pat}")
      }
    }
  })
}

module "create-cluster" {
  source = "./terraform/create-dev-cluster"
}

module "flux-operator-bootstrap" {
  source = "controlplaneio-fluxcd/flux-operator-bootstrap/kubernetes"

  revision = var.bootstrap_revision

  gitops_resources = {
    instance_yaml = file("${path.root}/k8s/clusters/${var.cluster-name}/flux-system/flux-instance.yaml")
  }

  managed_resources = {
    dockerconfig_yaml = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: dockerconfig
      namespace: flux-system
    type: kubernetes.io/dockerconfigjson
    data:
      .dockerconfigjson: '${replace(local.ghcr_auth_dockerconfigjson, "'", "''")}'
    YAML
  }
}