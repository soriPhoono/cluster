# ---------------------------------------------------------------------------
# Authentik OAuth2 Provider + Application setup for NetBird
# ---------------------------------------------------------------------------
# This job runs a script that:
#   1. Authenticates to Authentik API using the bootstrap token
#   2. Creates an OAuth2/OpenID Connect provider for NetBird
#   3. Creates an Application in Authentik
#   4. Stores the resulting client_id and client_secret in a Kubernetes Secret
# ---------------------------------------------------------------------------

locals {
  job_name    = "setup-netbird-oauth"
  secret_name = "netbird-oauth-credentials"
}

# ---------------------------------------------------------------------------
# RBAC: allow the Job's ServiceAccount to read Authentik secrets and
# create secrets in its own namespace
# ---------------------------------------------------------------------------
resource "kubernetes_service_account" "setup" {
  metadata {
    name      = "setup-netbird-oauth"
    namespace = var.netbird_namespace
  }
}

# Role to read the authentik-env secret in the authentik namespace
resource "kubernetes_role" "read_authentik_secrets" {
  metadata {
    name      = "read-authentik-secrets"
    namespace = var.authentik_namespace
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    resource_names = ["authentik-env"]
    verbs      = ["get"]
  }
}

resource "kubernetes_role_binding" "read_authentik_secrets" {
  metadata {
    name      = "read-authentik-secrets"
    namespace = var.authentik_namespace
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.setup.metadata[0].name
    namespace = var.netbird_namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.read_authentik_secrets.metadata[0].name
  }
}

# Role to create secrets in the netbird namespace
resource "kubernetes_role" "manage_netbird_secrets" {
  metadata {
    name      = "manage-netbird-secrets"
    namespace = var.netbird_namespace
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_role_binding" "manage_netbird_secrets" {
  metadata {
    name      = "manage-netbird-secrets"
    namespace = var.netbird_namespace
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.setup.metadata[0].name
    namespace = var.netbird_namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.manage_netbird_secrets.metadata[0].name
  }
}

# The setup job script — inlined as a ConfigMap
resource "kubernetes_config_map" "setup_script" {
  metadata {
    name      = "${local.job_name}-script"
    namespace = var.netbird_namespace
  }

  data = {
    "setup.sh" = <<-SCRIPT
      #!/bin/sh
      set -euo pipefail

      AUTHENTIK_NS="${var.authentik_namespace}"
      NETBIRD_NS="${var.netbird_namespace}"
      NETBIRD_FQDN="${var.netbird_fqdn}"
      AUTHENTIK_FQDN="${var.authentik_fqdn}"
      SECRET_NAME="${local.secret_name}"
      REDIRECT_URI_1="${var.redirect_uris[0]}"
      REDIRECT_URI_2="${var.redirect_uris[1]}"
      REDIRECT_URI_3="${var.redirect_uris[2]}"

      echo "=== Authentik NetBird OAuth Setup ==="

      # 1. Get Authentik bootstrap credentials
      echo "Reading Authentik bootstrap token..."
      BOOTSTRAP_TOKEN=$(kubectl get secret authentik-env -n "$AUTHENTIK_NS" \
        -o jsonpath='{.data.AUTHENTIK_BOOTSTRAP_TOKEN}' | base64 -d)
      AUTHENTIK_URL="http://authentik-server.$AUTHENTIK_NS.svc.cluster.local:80"

      # Fetch default authorization and invalidation flows
      echo "Fetching default flows..."
      FLOWS=$(curl -s -H "Authorization: Bearer $BOOTSTRAP_TOKEN" \
        "$AUTHENTIK_URL/api/v3/flows/instances/")
      AUTH_FLOW=$(echo "$FLOWS" | jq -r '.results[] | select(.designation == "authorization") | .pk' 2>/dev/null | head -1)
      INVALID_FLOW=$(echo "$FLOWS" | jq -r '.results[] | select(.designation == "invalidation") | .pk' 2>/dev/null | head -1)
      echo "Authorization flow: $AUTH_FLOW"
      echo "Invalidation flow: $INVALID_FLOW"

      # Discover default certificate key pair for RS256 signing
      echo "Discovering default signing certificate..."
      DEFAULT_SIGNING_KEY=$(curl -s -H "Authorization: Bearer $BOOTSTRAP_TOKEN" \
        "$AUTHENTIK_URL/api/v3/crypto/certificatekeypairs/" \
        | jq -r '.results[] | select(.name == "authentik Self-signed Certificate") | .pk' 2>/dev/null | head -1)
      echo "Signing key: $DEFAULT_SIGNING_KEY"

      # Discover default scope mappings for OpenID email and profile
      # These provide the "name", "email", and "preferred_username" claims Dex requires
      echo "Discovering scope mappings..."
      SCOPE_MAPPINGS=$(curl -s -H "Authorization: Bearer $BOOTSTRAP_TOKEN" \
        "$AUTHENTIK_URL/api/v3/propertymappings/provider/scope/")
      EMAIL_SCOPE_MAPPING=$(echo "$SCOPE_MAPPINGS" | jq -r '.results[] | select(.name == "authentik default OAuth Mapping: OpenID '\''email'\''") | .pk' 2>/dev/null | head -1)
      PROFILE_SCOPE_MAPPING=$(echo "$SCOPE_MAPPINGS" | jq -r '.results[] | select(.name == "authentik default OAuth Mapping: OpenID '\''profile'\''") | .pk' 2>/dev/null | head -1)
      echo "Email scope mapping: $EMAIL_SCOPE_MAPPING"
      echo "Profile scope mapping: $PROFILE_SCOPE_MAPPING"

      build_provider_json() {
        jq -n \
          --arg name "netbird" \
          --arg client_type "confidential" \
          --arg auth_flow "$AUTH_FLOW" \
          --arg invalid_flow "$INVALID_FLOW" \
          --arg signing_key "$DEFAULT_SIGNING_KEY" \
          --arg email_map "$EMAIL_SCOPE_MAPPING" \
          --arg profile_map "$PROFILE_SCOPE_MAPPING" \
          --arg uri1 "$REDIRECT_URI_1" \
          --arg uri2 "$REDIRECT_URI_2" \
          --arg uri3 "$REDIRECT_URI_3" \
          '{
            name: $name,
            client_type: $client_type,
            authorization_flow: $auth_flow,
            invalidation_flow: $invalid_flow,
            redirect_uris: [{url: $uri1, matching_mode: "strict"}, {url: $uri2, matching_mode: "strict"}, {url: $uri3, matching_mode: "strict"}],
            signing_key: $signing_key,
            property_mappings: [$email_map, $profile_map],
            token_validity: 14400,
            sub_mode: "hashed_user_id"
          }'
      }

      build_app_json() {
        jq -n \
          --arg name "NetBird" \
          --arg slug "netbird" \
          --arg provider_pk "$${PROVIDER_PK}" \
          --arg url "https://$NETBIRD_FQDN" \
          '{
            name: $name,
            slug: $slug,
            provider: (try ($provider_pk | tonumber) catch 0),
            meta_launch_url: $url,
            open_in_new_tab: true
          }'
      }

      # 2. Check if provider already exists (idempotent)
      echo "Checking for existing NetBird OAuth2 provider..."
      PROVIDER_LIST=$(curl -s -H "Authorization: Bearer $BOOTSTRAP_TOKEN" \
        "$AUTHENTIK_URL/api/v3/providers/oauth2/")
      EXISTING_PROVIDER=$(echo "$PROVIDER_LIST" | jq -r '.results[] | select(.name == "netbird") | .pk' 2>/dev/null || echo "")

      CLIENT_ID=""
      CLIENT_SECRET=""

      if [ -n "$EXISTING_PROVIDER" ]; then
        echo "Provider already exists (pk=$EXISTING_PROVIDER), updating..."
        PROVIDER_PK=$EXISTING_PROVIDER
        PAYLOAD=$(build_provider_json)
        HTTP_CODE=$(curl -s -o /dev/null -w "%%{http_code}" -X PUT \
          -H "Authorization: Bearer $BOOTSTRAP_TOKEN" \
          -H "Content-Type: application/json" \
          -d "$PAYLOAD" \
          "$AUTHENTIK_URL/api/v3/providers/oauth2/$PROVIDER_PK/")
        echo "Update provider HTTP status: $HTTP_CODE"
      else
        echo "Creating new OAuth2 provider..."
        PAYLOAD=$(build_provider_json)
        PROVIDER_RESP=$(curl -s -X POST \
          -H "Authorization: Bearer $BOOTSTRAP_TOKEN" \
          -H "Content-Type: application/json" \
          -d "$PAYLOAD" \
          "$AUTHENTIK_URL/api/v3/providers/oauth2/")
        echo "Create response: $(echo "$PROVIDER_RESP" | head -c 300)"
        PROVIDER_PK=$(echo "$PROVIDER_RESP" | jq -r '.pk // .provider_id // .id' 2>/dev/null || echo "")
        CLIENT_ID=$(echo "$PROVIDER_RESP" | jq -r '.client_id' 2>/dev/null || echo "")
        CLIENT_SECRET=$(echo "$PROVIDER_RESP" | jq -r '.client_secret' 2>/dev/null || echo "")
      fi

      # If no client_secret yet (e.g. update), fetch it
      if [ -z "$CLIENT_SECRET" ] || [ "$CLIENT_SECRET" = "null" ]; then
        echo "Fetching client credentials..."
        PROVIDER_DATA=$(curl -s -H "Authorization: Bearer $BOOTSTRAP_TOKEN" \
          "$AUTHENTIK_URL/api/v3/providers/oauth2/$PROVIDER_PK/")
        CLIENT_ID=$(echo "$PROVIDER_DATA" | jq -r '.client_id')
        CLIENT_SECRET=$(echo "$PROVIDER_DATA" | jq -r '.client_secret')
      fi
      echo "Client ID: $CLIENT_ID"

      # 3. Create/update the Application
      echo "Setting up Application..."
      APP_LIST=$(curl -s -H "Authorization: Bearer $BOOTSTRAP_TOKEN" \
        "$AUTHENTIK_URL/api/v3/core/applications/")
      EXISTING_APP=$(echo "$APP_LIST" | jq -r '.results[] | select(.slug == "netbird") | .pk' 2>/dev/null || echo "")

      if [ -n "$EXISTING_APP" ]; then
        echo "Updating existing application (pk=$EXISTING_APP)..."
        PAYLOAD=$(build_app_json)
        HTTP_CODE=$(curl -s -o /dev/null -w "%%{http_code}" -X PUT \
          -H "Authorization: Bearer $BOOTSTRAP_TOKEN" \
          -H "Content-Type: application/json" \
          -d "$PAYLOAD" \
          "$AUTHENTIK_URL/api/v3/core/applications/$EXISTING_APP/")
        echo "Update app HTTP status: $HTTP_CODE"
      else
        echo "Creating new Application..."
        PAYLOAD=$(build_app_json)
        APP_RESP=$(curl -s -X POST \
          -H "Authorization: Bearer $BOOTSTRAP_TOKEN" \
          -H "Content-Type: application/json" \
          -d "$PAYLOAD" \
          "$AUTHENTIK_URL/api/v3/core/applications/")
        echo "App create: $(echo "$APP_RESP" | head -c 200)"
      fi

      # 4. Store credentials in a Kubernetes Secret
      echo "Storing OAuth credentials in Secret..."
      kubectl create secret generic "$SECRET_NAME" -n "$NETBIRD_NS" \
        --dry-run=client -o yaml \
        --from-literal=client_id="$CLIENT_ID" \
        --from-literal=client_secret="$CLIENT_SECRET" \
        | kubectl apply -f -

      echo ""
      echo "=== Done ==="
      echo "Issuer URL: https://$AUTHENTIK_FQDN/application/o/netbird/"
    SCRIPT
  }
}

# Create the setup Job
resource "kubernetes_job_v1" "setup_netbird_oauth" {
  metadata {
    name      = local.job_name
    namespace = var.netbird_namespace
  }

  spec {
    template {
      metadata {}
      spec {
        # Use an image with curl, jq, and kubectl
        container {
          name    = "setup"
          image   = "bitnami/kubectl:latest"
          command = ["/bin/bash", "/scripts/setup.sh"]

          volume_mount {
            name       = "script"
            mount_path = "/scripts"
          }
        }

        restart_policy       = "Never"
        service_account_name = kubernetes_service_account.setup.metadata[0].name

        volume {
          name = "script"
          config_map {
            name = kubernetes_config_map.setup_script.metadata[0].name
            default_mode = "0755"
          }
        }
      }
    }

    backoff_limit = 3
  }

  depends_on = [
    kubernetes_config_map.setup_script,
    kubernetes_role_binding.read_authentik_secrets,
    kubernetes_role_binding.manage_netbird_secrets,
  ]
}

# Wait for the credentials Secret to be available
data "kubernetes_secret" "netbird_oauth" {
  metadata {
    name      = local.secret_name
    namespace = var.netbird_namespace
  }

  depends_on = [kubernetes_job_v1.setup_netbird_oauth]
}

# ---------------------------------------------------------------------------
# Google OAuth Source setup for Authentik
# ---------------------------------------------------------------------------
# This job runs a script that:
#   1. Authenticates to Authentik API using the bootstrap token
#   2. Reads Google OAuth client credentials from the authentik-google-oauth Secret
#   3. Creates (or updates) a Google OAuth source in Authentik
#   4. Users can then sign in with their Google account
# ---------------------------------------------------------------------------

locals {
  google_job_name = "setup-google-oauth-source"
}

resource "kubernetes_service_account" "setup_google_oauth" {
  metadata {
    name      = local.google_job_name
    namespace = var.authentik_namespace
  }
}

# Role to read both the authentik-env and authentik-google-oauth secrets
resource "kubernetes_role" "read_google_oauth_secrets" {
  metadata {
    name      = "read-google-oauth-secrets"
    namespace = var.authentik_namespace
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    resource_names = [
      "authentik-env",
      "authentik-google-oauth",
    ]
    verbs = ["get"]
  }
}

resource "kubernetes_role_binding" "read_google_oauth_secrets" {
  metadata {
    name      = "read-google-oauth-secrets"
    namespace = var.authentik_namespace
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.setup_google_oauth.metadata[0].name
    namespace = var.authentik_namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.read_google_oauth_secrets.metadata[0].name
  }
}

resource "kubernetes_config_map" "setup_google_oauth_script" {
  metadata {
    name      = "${local.google_job_name}-script"
    namespace = var.authentik_namespace
  }

  data = {
    "setup.sh" = <<-SCRIPT
      #!/bin/sh
      set -euo pipefail

      AUTHENTIK_NS="${var.authentik_namespace}"
      AUTHENTIK_FQDN="${var.authentik_fqdn}"
      SOURCE_SLUG="google"

      echo "=== Authentik Google OAuth Source Setup ==="

      # 1. Get Authentik bootstrap token
      echo "Reading Authentik bootstrap token..."
      BOOTSTRAP_TOKEN=$(kubectl get secret authentik-env -n "$AUTHENTIK_NS" \
        -o jsonpath='{.data.AUTHENTIK_BOOTSTRAP_TOKEN}' | base64 -d)
      AUTHENTIK_URL="http://authentik-server.$AUTHENTIK_NS.svc.cluster.local:80"

      # 2. Read Google OAuth credentials from the SOPS-encrypted Secret
      echo "Reading Google OAuth credentials..."
      GOOGLE_CLIENT_ID=$(kubectl get secret authentik-google-oauth -n "$AUTHENTIK_NS" \
        -o jsonpath='{.data.google-oauth-client-id}' | base64 -d)
      GOOGLE_CLIENT_SECRET=$(kubectl get secret authentik-google-oauth -n "$AUTHENTIK_NS" \
        -o jsonpath='{.data.google-oauth-client-secret}' | base64 -d)

      if [ -z "$GOOGLE_CLIENT_ID" ] || [ "$GOOGLE_CLIENT_ID" = "placeholder-replace-with-real-client-id" ]; then
        echo "ERROR: Google OAuth credentials are not configured!"
        echo "Update k8s/apps/auth/authentik/google-oauth.sops.yaml with real credentials."
        exit 1
      fi

      echo "Google Client ID: $GOOGLE_CLIENT_ID"

      # 3. Fetch default authentication and enrollment flows
      echo "Fetching default flows..."
      FLOWS=$(curl -s -H "Authorization: Bearer $BOOTSTRAP_TOKEN" \
        "$AUTHENTIK_URL/api/v3/flows/instances/")

      AUTH_FLOW=$(echo "$FLOWS" | jq -r '.results[] | select(.slug == "default-source-authentication") | .pk' 2>/dev/null | head -1)
      ENROLL_FLOW=$(echo "$FLOWS" | jq -r '.results[] | select(.slug == "default-source-enrollment") | .pk' 2>/dev/null | head -1)

      echo "Authentication flow: $AUTH_FLOW"
      echo "Enrollment flow: $ENROLL_FLOW"

      if [ -z "$AUTH_FLOW" ] || [ -z "$ENROLL_FLOW" ]; then
        echo "WARNING: Could not find default source flows. Falling back to any authorization/enrollment flows..."
        AUTH_FLOW=$(echo "$FLOWS" | jq -r '.results[] | select(.designation == "authentication") | .pk' 2>/dev/null | head -1)
        ENROLL_FLOW=$(echo "$FLOWS" | jq -r '.results[] | select(.designation == "enrollment") | .pk' 2>/dev/null | head -1)
        echo "Fallback auth flow: $AUTH_FLOW"
        echo "Fallback enroll flow: $ENROLL_FLOW"
      fi

      build_source_json() {
        jq -n \
          --arg name "Google" \
          --arg slug "$SOURCE_SLUG" \
          --arg auth_flow "$AUTH_FLOW" \
          --arg enroll_flow "$ENROLL_FLOW" \
          --arg provider_type "google" \
          --arg client_id "$GOOGLE_CLIENT_ID" \
          --arg client_secret "$GOOGLE_CLIENT_SECRET" \
          --arg pkce "S256" \
          --arg user_matching "email_link" \
          '{
            name: $name,
            slug: $slug,
            enabled: true,
            authentication_flow: $auth_flow,
            enrollment_flow: $enroll_flow,
            provider_type: $provider_type,
            consumer_key: $client_id,
            consumer_secret: $client_secret,
            pkce: $pkce,
            user_matching_mode: $user_matching
          }'
      }

      # 4. Check if source already exists (idempotent)
      echo "Checking for existing Google OAuth source..."
      SOURCE_LIST=$(curl -s -H "Authorization: Bearer $BOOTSTRAP_TOKEN" \
        "$AUTHENTIK_URL/api/v3/sources/oauth/")
      EXISTING_SOURCE=$(echo "$SOURCE_LIST" | jq -r --arg slug "$SOURCE_SLUG" \
        '.results[] | select(.slug == $slug) | .pk' 2>/dev/null || echo "")

      if [ -n "$EXISTING_SOURCE" ]; then
        echo "Source already exists (pk=$EXISTING_SOURCE), updating..."
        SOURCE_PK=$EXISTING_SOURCE
        PAYLOAD=$(build_source_json)
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
          -H "Authorization: Bearer $BOOTSTRAP_TOKEN" \
          -H "Content-Type: application/json" \
          -d "$PAYLOAD" \
          "$AUTHENTIK_URL/api/v3/sources/oauth/$SOURCE_PK/")
        echo "Update source HTTP status: $HTTP_CODE"
      else
        echo "Creating new Google OAuth source..."
        PAYLOAD=$(build_source_json)
        SOURCE_RESP=$(curl -s -X POST \
          -H "Authorization: Bearer $BOOTSTRAP_TOKEN" \
          -H "Content-Type: application/json" \
          -d "$PAYLOAD" \
          "$AUTHENTIK_URL/api/v3/sources/oauth/")
        SOURCE_PK=$(echo "$SOURCE_RESP" | jq -r '.pk' 2>/dev/null || echo "")
        echo "Create response pk: $SOURCE_PK"
      fi

      echo ""
      echo "=== Done ==="
      echo "Google OAuth source: https://$AUTHENTIK_FQDN/source/oauth/callback/$SOURCE_SLUG/"
      echo "Users can now sign in with Google at the Authentik login page."
    SCRIPT
  }
}

# Create the setup Job
resource "kubernetes_job_v1" "setup_google_oauth" {
  metadata {
    name      = local.google_job_name
    namespace = var.authentik_namespace
  }

  spec {
    template {
      metadata {}
      spec {
        container {
          name    = "setup"
          image   = "bitnami/kubectl:latest"
          command = ["/bin/bash", "/scripts/setup.sh"]

          volume_mount {
            name       = "script"
            mount_path = "/scripts"
          }
        }

        restart_policy       = "Never"
        service_account_name = kubernetes_service_account.setup_google_oauth.metadata[0].name

        volume {
          name = "script"
          config_map {
            name = kubernetes_config_map.setup_google_oauth_script.metadata[0].name
            default_mode = "0755"
          }
        }
      }
    }

    backoff_limit = 3
  }

  depends_on = [
    kubernetes_config_map.setup_google_oauth_script,
    kubernetes_role_binding.read_google_oauth_secrets,
  ]
}
