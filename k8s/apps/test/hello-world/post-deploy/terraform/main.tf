data "cloudflare_zone" "zone" {
  name = var.cloudflare_domain
}

locals {
  permission_groups = {
    "Cloudflare Tunnel Write" = "c07321b023e944ff818fec44d8203567"
    "DNS Write"               = "4755a26eedb94da69e1066d98aa820be"
    "Zone Read"               = "c8fed203ed3043cba015a93ad1616f1f"
  }
}

resource "cloudflare_api_token" "scoped_token" {
  name = "hello-world-tunnel-token"

  policy {
    effect = "allow"
    permission_groups = [
      local.permission_groups["Cloudflare Tunnel Write"]
    ]
    resources = {
      "com.cloudflare.api.account.${var.cloudflare_account_id}" = "*"
    }
  }

  policy {
    effect = "allow"
    permission_groups = [
      local.permission_groups["DNS Write"],
      local.permission_groups["Zone Read"]
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
