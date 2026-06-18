#!/bin/sh
set -e

echo "Checking if cloudflare-secrets already exists in hello-world..."
if kubectl get secret -n hello-world cloudflare-secrets >/dev/null 2>&1; then
  echo "Secret cloudflare-secrets already exists. Skipping copy."
  exit 0
fi

echo "Secret not found. Copying from flux-system/cloudflare-global-secret..."

# Fetch the global token
TOKEN=$(kubectl get secret -n flux-system cloudflare-global-secret -o jsonpath='{.data.CLOUDFLARE_GLOBAL_API_TOKEN}' | base64 -d)

if [ -z "$TOKEN" ]; then
  echo "Error: CLOUDFLARE_GLOBAL_API_TOKEN is empty in flux-system/cloudflare-global-secret"
  exit 1
fi

# Create the secret in hello-world namespace
kubectl create secret generic cloudflare-secrets \
  --namespace=hello-world \
  --from-literal=CLOUDFLARE_API_TOKEN="$TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Successfully copied cloudflare-secrets to hello-world namespace."
