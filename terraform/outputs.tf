output "netbird_client_id" {
  description = "OAuth2 Client ID for NetBird"
  value       = data.kubernetes_secret.netbird_oauth.data["client_id"]
  sensitive   = true
}

output "netbird_client_secret" {
  description = "OAuth2 Client Secret for NetBird"
  value       = data.kubernetes_secret.netbird_oauth.data["client_secret"]
  sensitive   = true
}

output "netbird_issuer_url" {
  description = "OpenID Connect issuer URL for NetBird"
  value       = "https://${var.authentik_fqdn}/application/o/netbird/"
}

output "netbird_oauth_secret" {
  description = "Kubernetes Secret name containing OAuth credentials"
  value       = "${data.kubernetes_secret.netbird_oauth.metadata[0].namespace}/${data.kubernetes_secret.netbird_oauth.metadata[0].name}"
}

output "google_oauth_callback_uri" {
  description = "Google OAuth callback URI — configure this in Google Cloud Console"
  value       = "https://${var.authentik_fqdn}/source/oauth/callback/google/"
}
