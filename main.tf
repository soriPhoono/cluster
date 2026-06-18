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
