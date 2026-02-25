#!/usr/bin/env bash
set -e

# This script sets up a local Talos cluster for testing,
# ensuring any existing stale state is cleaned up first.

CLUSTER_NAME="talos-default"
STATE_DIR="${HOME}/.talos/clusters/${CLUSTER_NAME}"

if ! talosctl cluster destroy; then
  echo "[INFO]: Stopping and removing existing Talos containers..."
  docker ps -a --filter "name=${CLUSTER_NAME}" -q | xargs -r docker rm -f

  echo "[INFO]: Removing Talos network if it exists..."
  docker network rm "${CLUSTER_NAME}" 2>/dev/null || true

  echo "[INFO]: Cleaning up state directory: ${STATE_DIR}"
  sudo rm -rf "${STATE_DIR}"
fi

echo "[INFO]: Creating new Talos cluster using Docker..."
# Ensure OVMF_DIR is set (expected from devshell)
if [ -z "$OVMF_DIR" ]; then
  echo "[WARN]: OVMF_DIR is not set. Cluster creation might fail if UEFI is required."
fi

sudo -E talosctl cluster create docker

echo "[INFO]: Extracting kubeconfig..."
talosctl kubeconfig ./kubeconfig --force --merge=false
KUBECONFIG="$(pwd)/kubeconfig"
export KUBECONFIG

echo "[INFO]: Installing FluxCD components..."
kubectl apply -f k8s/core/flux-system/gotk-components.yaml

echo "[INFO]: Waiting for FluxCD to be ready..."
kubectl wait --for=condition=available --timeout=5m -n flux-system deployment/source-controller

echo "[INFO]: Applying FluxCD sync configuration..."
kubectl apply -f k8s/core/flux-system/gotk-sync.yaml
kubectl apply -f k8s/core/flux-system/helm-repositories.yaml

echo "[SUCCESS]: Cluster setup and Flux synchronization complete."
