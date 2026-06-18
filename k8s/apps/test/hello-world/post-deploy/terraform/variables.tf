variable "cloudflare_global_api_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_account_id" {
  type    = string
  default = "b6e9a277e1c46db22032d0e2c04fb6ae"
}

variable "cloudflare_domain" {
  type    = string
  default = "cryptic-coders.net"
}
