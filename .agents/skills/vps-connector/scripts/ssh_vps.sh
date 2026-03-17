#!/usr/bin/env bash

# Check if bw is installed
if ! command -v bw >/dev/null 2>&1; then
    echo "Error: Bitwarden CLI (bw) is not installed."
    exit 1
fi

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is not installed."
    exit 1
fi

# Check if bw is unlocked
if ! bw status 2>/dev/null | grep -q '"status":"unlocked"'; then
  echo "Error: Bitwarden is locked. Please unlock it first."
  exit 1
fi

# Extract key
# Note: Using the specific item ID for 'Personal Key'
PRIVATE_KEY=$(bw get item af26cdbb-d79c-4e28-b00c-b407013c425a 2>/dev/null | jq -r '.sshKey.privateKey')

if [ -z "$PRIVATE_KEY" ] || [ "$PRIVATE_KEY" == "null" ]; then
    echo "Error: Failed to retrieve the private key from Bitwarden."
    exit 1
fi

# Start a temporary ssh-agent
eval "$(ssh-agent -s)" > /dev/null

# Add the key to the agent
echo "$PRIVATE_KEY" | ssh-add - > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to add SSH key to the agent."
    kill $SSH_AGENT_PID > /dev/null 2>&1
    exit 1
fi

# Execute the provided SSH command
ssh "$@"
EXIT_CODE=$?

# Clean up the agent
kill $SSH_AGENT_PID > /dev/null 2>&1

exit $EXIT_CODE
