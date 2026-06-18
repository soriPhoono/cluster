module "create-cluster" {
  source = var.debug_mode ? "./terraform/create-dev-cluster" : "./terraform/create-prod-cluster"
}

module "flux-operator-bootstrap" {
  source = "controlplaneio-fluxcd/flux-operator-bootstrap/kubernetes"

  revision = 1

  gitops_resources = {
    instance_yaml = file("${path.root}/k8s/clusters/${var.debug_mode ? "staging" : var.cluster_name}/flux-system/flux-instance.yaml")
  }

  depends_on = [module.create-cluster]
}

resource "kubernetes_secret_v1" "cloudflare_global_secret" {
  metadata {
    name      = "cloudflare-global-secret"
    namespace = "flux-system"
  }

  data = {
    CLOUDFLARE_GLOBAL_API_TOKEN = var.cloudflare_global_api_token
  }

  depends_on = [module.flux-operator-bootstrap]
}

