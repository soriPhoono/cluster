#!/bin/bash

# shellcheck disable=SC1091
if [[ -f .env ]]; then
	source ./.env
fi

export GITHUB_TOKEN="${GITHUB_PAT}"

export GITHUB_USER="soriphoono"

flux bootstrap github \
	--owner="${GITHUB_USER}" \
	--repository=cluster \
	--branch=main \
	--path=clusters/guenivir \
	--personal
