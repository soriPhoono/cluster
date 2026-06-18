resource "kind_cluster" "this" {
  name           = "kind-guenivir"
  wait_for_ready = true

  node_image = "kindest/node:v1.32.0"

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    dynamic "node" {
      for_each = concat(
        [for i in range(var.servers_count) : { role = "control-plane" }],
        [for i in range(var.workers_count) : { role = "worker" }]
      )
      content {
        role = node.value.role
      }
    }
  }
}

