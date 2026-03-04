# Docker Swarm Migration TODO

The project is currently transitioning from a Kubernetes (Talos Linux) structure to a Docker Swarm deployment running on LXC (Linux Containers) on Proxmox, optimizing for lower resource overhead.

This TODO outlines the steps necessary to establish a production-quality Swarm cluster and migrate the existing GitOps/K8s setup.

## 1. LXC & Host Virtualization Setup (Proxmox)

- [ ] **Provision LXC Containers**: Create LXC containers on Proxmox to serve as Docker Swarm Manager and Worker nodes.
- [ ] **Configure LXC Permissions**: Ensure Docker nested virtualization is supported.
  - Enable `nesting=1` and `keyctl=1` in the LXC options.
  - Decide between privileged vs unprivileged containers (unprivileged is more secure but may require subuid/subgid mapping for certain volume mounts).
- [ ] **Node Networking**: Configure static IPs for all LXC nodes to ensure stable Swarm communication.

## 2. Docker Swarm Initialization

- [ ] **Install Docker Engine**: Install Docker on all LXC nodes (can use Nix/flake configurations or standard apt installs).
- [ ] **Initialize Swarm**: Run `docker swarm init` on the primary manager node.
- [ ] **Join Nodes**: Add the remaining manager and worker nodes using the respective `docker swarm join-token` commands.
- [ ] **Label Nodes**: Apply node labels for workload scheduling (e.g., `docker node update --label-add storage=ssd <node-name>`).

## 3. Network Infrastructure & Security

- [ ] **Overlay Networks**: Create the core overlay networks required by your stacks.
  - `docker network create -d overlay --attachable traefik-public`
  - `docker network create -d overlay socket-proxy`
- [ ] **Docker Socket Proxy**: Deploy the `socket-proxy` stack to securely expose the Docker API to Traefik, isolating the raw `docker.sock` from the public ingress.
- [ ] **Tailscale Integration**: Reconfigure the Tailscale setup (previously an operator in K8s). This can be run as a service in Swarm or installed directly on the LXC hosts/Proxmox node for secure administrative access.

## 4. Storage & Secrets Management

- [ ] **Shared Storage Strategy**: Docker Swarm requires volumes to be available on all nodes if a container restarts elsewhere.
  - Setup a shared filesystem (e.g., NFS, CephFS, Gluster, or CIFS) mapped to the LXC nodes.
  - Ensure stack definitions point to these shared mounts or utilize a Docker volume plugin.
- [ ] **Migrate Secrets**: Convert existing `sops`/`agenix` Kubernetes Secret objects into Docker Swarm Secrets (`docker secret create my_secret file.txt`).
- [ ] **Update Compose Files**: Modify `.env` handling and secret references in your `stacks/` compose files to use Swarm external secrets (e.g., `/run/secrets/...`).

## 5. Ingress & Core Services Deployment

- [ ] **Traefik Deployment**: Deploy the `stacks/traefik/docker-compose.yml` stack.
  - Verify Cloudflare DNS challenge credentials are working.
  - Ensure Traefik can fetch certificates for the configured `DOMAIN_NAME`.
- [ ] **Verify Ingress**: Test the Traefik dashboard using the securely routed `proxy.admin.ts...` hostname.

## 6. Application Migration (K8s to Swarm)

- [ ] **Translate Workloads**: Convert existing Kubernetes manifests (`k8s/apps/`) into Docker Compose stack files (`stacks/<app-name>/docker-compose.yml`).
- [ ] **Translate Ingress Rules**: Convert K8s Ingress objects to Traefik Swarm labels (e.g., `traefik.http.routers.myapp.rule=Host('myapp.example.com')`).
- [ ] **Database & Stateful Workloads**: Migrate core databases (Postgres, Redis/Dragonfly). Ensure they are pinned to specific nodes if relying on local storage, or use the shared storage layer carefully to avoid corruption.
- [ ] **GitLab / Gitea**: Deploy the version control system as a Swarm stack to complete the "Black Box" bootstrap goal.

## 7. Observability Stack

- [ ] **Prometheus & Grafana**: Deploy a lightweight observability stack using Docker Compose.
- [ ] **Log Collection**: Set up Promtail or configure the Docker logging driver (e.g., `loki` driver plugin) to ship container logs to a central Loki instance.

## 8. CI/CD & GitOps Modernization

- [ ] **Replace Flux**: Since `flux` is native to Kubernetes, select a Swarm-compatible GitOps tool or workflow.
  - **Option A**: Use Portainer's built-in GitOps features to pull compose files from the repository and deploy automatically.
  - **Option B**: Write a GitHub Actions (or GitLab CI) workflow using the existing `actions.nix` shell to automatically connect to the Swarm manager and run `docker stack deploy`.
- [ ] **Cleanup**: Once the Swarm environment is stable and apps are migrated, remove the legacy `k8s/`, `talos/`, and related Kubernetes-specific code to trim the repository.
