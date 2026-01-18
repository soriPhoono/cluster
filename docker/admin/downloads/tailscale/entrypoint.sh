#!/bin/sh
# Read the secret file and export it as the auth key
if [ -f /run/secrets/tailscale-authkey ]; then
    TS_AUTHKEY=$(cat /run/secrets/tailscale-authkey)
    export TS_AUTHKEY
fi

# Execute the original Tailscale entrypoint
exec /usr/local/bin/containerboot "$@"