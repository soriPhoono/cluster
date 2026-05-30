variable "netbird_fqdn" {
  description = "NetBird dashboard FQDN"
  type        = string
  default     = "vpn.cryptic-coders.net"
}

variable "authentik_fqdn" {
  description = "Authentik external FQDN"
  type        = string
  default     = "auth.cryptic-coders.net"
}

variable "authentik_namespace" {
  description = "Authentik namespace"
  type        = string
  default     = "authentik"
}

variable "netbird_namespace" {
  description = "NetBird namespace"
  type        = string
  default     = "netbird"
}

variable "redirect_uris" {
  description = "OAuth2 redirect URIs for NetBird"
  type        = list(string)
  default = [
    "https://vpn.cryptic-coders.net/nb-auth",
    "https://vpn.cryptic-coders.net/nb-silent-auth",
    "https://vpn.cryptic-coders.net/api/identity-providers/callback",
  ]
}
