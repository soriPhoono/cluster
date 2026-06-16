output "cluster-host" {
  depends_on  = [k3d_cluster.this]
  description = "Hostname to access the cluster"
  value       = k3d_cluster.this.kubeconfig[0].host
}

output "cluster-client-certificate" {
  depends_on  = [k3d_cluster.this]
  description = "Client certificate to access the cluster"
  value       = k3d_cluster.this.kubeconfig[0].client_certificate
  sensitive   = true
}

output "cluster-client-key" {
  depends_on  = [k3d_cluster.this]
  description = "Client key to access the cluster"
  value       = k3d_cluster.this.kubeconfig[0].client_key
  sensitive   = true
}

output "cluster-ca-certificate" {
  depends_on  = [k3d_cluster.this]
  description = "CA certificate to access the cluster"
  value       = k3d_cluster.this.kubeconfig[0].certificate_authority_data
  sensitive   = true
}