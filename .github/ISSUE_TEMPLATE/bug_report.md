______________________________________________________________________

## name: Bug report about: Create a report to help us improve title: '[BUG] ' labels: bug assignees: ''

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:

1. Trigger event '...'
1. Stack / service affected '....'
1. See error '...'

**Expected behavior**
A clear and concise description of what you expected to happen.

**Logs**
If applicable, add logs to help explain your problem.

```bash
# Kubernetes pod logs
kubectl logs -n <namespace> <pod-name>

# Flux reconciliation status
flux get all -A

# Talos node logs
talosctl logs -n <node-ip> kubelet
```

**Environment Context (please complete the following information):**

- Talos version (`talosctl version`):
- Kubernetes version (`kubectl version`):
- Flux version (`flux version`):
- Cluster / Node affected:
- Namespace / Service name:

**Additional context**
Add any other context about the problem here.
