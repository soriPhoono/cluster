terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

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

provider "cloudflare" {
  api_token = var.cloudflare_global_api_token
}

provider "kubernetes" {}

data "cloudflare_zone" "zone" {
  name = var.cloudflare_domain
}

data "cloudflare_api_token_permission_groups" "all" {}

resource "cloudflare_api_token" "scoped_token" {
  name = "hello-world-tunnel-token"

  policy {
    effect = "allow"
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.account["Cloudflare Tunnel Write"]
    ]
    resources = {
      "com.cloudflare.api.account.${var.cloudflare_account_id}" = "*"
    }
  }

  policy {
    effect = "allow"
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.zone["DNS Write"]
    ]
    resources = {
      "com.cloudflare.api.account.zone.${data.cloudflare_zone.zone.id}" = "*"
    }
  }

}

resource "kubernetes_secret_v1" "cloudflare_secrets" {
  metadata {
    name      = "cloudflare-secrets"
    namespace = "hello-world"
  }

  type = "Opaque"

  data = {
    CLOUDFLARE_API_TOKEN = cloudflare_api_token.scoped_token.value
  }
}
