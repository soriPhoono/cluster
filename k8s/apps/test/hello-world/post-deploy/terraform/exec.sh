#!/bin/sh
set -e

# Install curl
apk add --no-cache curl

APISERVER="https://kubernetes.default.svc"
SERVICEACCOUNT="/var/run/secrets/kubernetes.io/serviceaccount"
NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)
TOKEN=$(cat ${SERVICEACCOUNT}/token)
CACERT="${SERVICEACCOUNT}/ca.crt"

echo "Checking if cloudflare-secrets already exists in hello-world..."
STATUS_CODE=$(curl --write-out "%{http_code}" --silent --output /dev/null \
  --cacert ${CACERT} \
  --header "Authorization: Bearer ${TOKEN}" \
  "${APISERVER}/api/v1/namespaces/hello-world/secrets/cloudflare-secrets")

if [ "$STATUS_CODE" -eq 200 ]; then
  echo "Secret cloudflare-secrets already exists. Skipping Terraform execution."
  exit 0
fi

echo "Secret not found (HTTP status $STATUS_CODE). Running Terraform..."

WORK_DIR="/tmp/tf"
mkdir -p "$WORK_DIR"
cp /workspace/*.tf "$WORK_DIR"/
cd "$WORK_DIR"

terraform init
terraform apply -auto-approve

