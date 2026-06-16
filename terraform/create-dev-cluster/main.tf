resource "k3d_cluster" "this" {
  name = "k3d-guenivir"

  servers = 1
  agents  = 2

  image = "rancher/k3s:v1.20.4-k3s1"

  kubeconfig {
    switch_current_context    = true
    update_default_kubeconfig = true
  }

  k3s {
    extra_args = [{
      arg = "--disable=traefik"
    }]
  }
}
