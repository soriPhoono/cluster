---
name: vps-connector
description: Automates SSH connections to VPS nodes using the Personal Key stored in Bitwarden. Use this skill when asked to execute commands on or interact with the user's VPS instances.
---

# VPS Connector Skill

This skill provides a secure way for the agent to connect to the user's VPS instances using the private SSH key stored in the Bitwarden CLI (`bw`). 

Because the key must be kept secure, this skill uses a wrapper script (`scripts/ssh_vps.sh`) that starts a temporary `ssh-agent`, loads the key from Bitwarden into the agent, executes the requested SSH command, and then cleans up the agent.

## Usage Instructions

When asked to connect to or run commands on a VPS (like `vps-manager`), **do not** use the standard `ssh` command. Instead, use the provided `ssh_vps.sh` script.

### Prerequisites
Before running the script, verify that Bitwarden CLI (`bw`) is unlocked by running:
`bw status`
If the status is not unlocked, ask the user to unlock it before proceeding.

### Executing Commands

Run the wrapper script exactly as you would run `ssh`:

```bash
bash <path-to-skill>/scripts/ssh_vps.sh [user@]hostname [command]
```

**Example: Check uptime on vps-manager**
```bash
bash <path-to-skill>/scripts/ssh_vps.sh vps-manager uptime
```

**Example: Copy a file from vps-manager (using standard ssh wrapped via the script)**
```bash
# To copy files, you may need to use the script with standard ssh commands or pipes
bash <path-to-skill>/scripts/ssh_vps.sh vps-manager 'cat /remote/path/file.txt' > /local/path/file.txt
```

### Important Notes

1. The user has added aliases/entries for the VPS nodes (like `vps-manager`) in their `~/.ssh/config`, so you can use the short hostname directly.
2. The script handles the `ssh-agent` lifecycle automatically. Do not manually start an agent or run `ssh-add`.
3. If the script fails, check the `bw status` first.
