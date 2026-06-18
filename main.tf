locals {
  ghcr_auth_dockerconfigjson = jsonencode({
    auths = {
      "ghcr.io" = {
        username = "flux"
        password = var.ghcr_pat
        auth     = base64encode("flux:${var.ghcr_pat}")
      }
    }
  })
}

module "create-cluster" {
  source = var.debug_mode ? "./terraform/create-dev-cluster" : "./terraform/create-prod-cluster"
}

module "flux-operator-bootstrap" {
  source = "controlplaneio-fluxcd/flux-operator-bootstrap/kubernetes"

  revision = 1

  gitops_resources = {
    instance_yaml = file("${path.root}/k8s/clusters/${var.debug_mode ? "staging" : var.cluster_name}/flux-system/flux-instance.yaml")
  }

  managed_resources = {
    dockerconfig_yaml = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: flux-dockerconfig
      namespace: flux-system
    type: kubernetes.io/dockerconfigjson
    data:
      .dockerconfigjson: '${replace(local.ghcr_auth_dockerconfigjson, "'", "''")}'
    YAML
  }
}
