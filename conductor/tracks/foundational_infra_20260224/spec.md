# Specification - Foundational Cluster Infrastructure

## Goal

Implement the core infrastructure services required for storage, networking, and observability using the preferred tools: Traefik, Rook-Ceph, and Grafana.

## Requirements

- **Storage**: Deploy Rook-Ceph operator and a production-ready CephCluster on Talos Linux.
- **Ingress & TLS**: Deploy Traefik with internal ACME support for automatic Let's Encrypt certificate management.
- **Monitoring**: Deploy a monitoring stack featuring Grafana and Prometheus (via Prometheus-Operator) for cluster visibility.
- **Standards**: All deployments must use Helm via Flux, include resource limits, and pin image versions.
- **Talos Integration**: Account for Talos-specific requirements for Rook (raw disks, kernel modules).

## Technical Architecture

- **Rook-Ceph**: Deployed in `rook-ceph` namespace. Configured to use raw disks on Talos nodes.
- **Traefik**: Deployed in `traefik` namespace. Configured for `IngressRoute` and ACME cert fetching.
- **Monitoring**: Deployed in `monitoring` namespace using the `kube-prometheus-stack` Helm chart.
