output "endpoint" {
  value = kind_cluster.this.endpoint
}

output "client-certificate" {
  value = kind_cluster.this.client_certificate
}

output "client-key" {
  value = kind_cluster.this.client_key
}

output "cluster-ca-certificate" {
  value = kind_cluster.this.cluster_ca_certificate
}
