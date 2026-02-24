#!/usr/bin/env bash
set -e

# This script sets up a local Talos cluster for testing, 
# ensuring any existing stale state is cleaned up first.

CLUSTER_NAME="talos-default"
STATE_DIR="${HOME}/.talos/clusters/${CLUSTER_NAME}"

echo "Stopping and removing existing Talos containers..."
docker ps -a --filter "name=${CLUSTER_NAME}" -q | xargs -r docker rm -f

echo "Removing Talos network if it exists..."
docker network rm "${CLUSTER_NAME}" 2>/dev/null || true

echo "Cleaning up state directory: ${STATE_DIR}"
sudo rm -rf "${STATE_DIR}"

echo "Creating new Talos cluster using Docker..."
sudo -E talosctl cluster create docker --workers 0

echo "Cluster created successfully."
