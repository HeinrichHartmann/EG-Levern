#!/usr/bin/env bash
# Runs a command (e.g. `tofu apply`) with Heinrich's privileged AWS identity,
# fetched from Bitwarden instead of a plaintext file on disk.
#
# Never use this for routine deploys -- it's only for IAM administration
# (applying iam.tf, etc). See infra/README.md, "Manual steps only Heinrich
# can do", and iam.tf's header comment for why hh.com must never hold these
# credentials.
#
# Usage:
#   infra/scripts/with-bw-admin.sh tofu apply
#   BW_ITEM_NAME="other item" infra/scripts/with-bw-admin.sh tofu plan
set -euo pipefail

BW_ITEM_NAME="${BW_ITEM_NAME:-aws admin IAM CLI credentials}"

if [ "$#" -eq 0 ]; then
  echo "usage: $0 <command...>" >&2
  exit 1
fi

if ! command -v bw >/dev/null 2>&1; then
  echo "error: bitwarden CLI (bw) not found" >&2
  exit 1
fi

if [ -z "${BW_SESSION:-}" ]; then
  status="$(bw status --raw | jq -r .status)"
  if [ "$status" = "unauthenticated" ]; then
    echo "error: run 'bw login' first" >&2
    exit 1
  fi
  BW_SESSION="$(bw unlock --raw)"
fi
export BW_SESSION

item="$(bw get item "$BW_ITEM_NAME")"
akid="$(jq -r '.login.username' <<<"$item")"
sak="$(jq -r '.login.password' <<<"$item")"

if [ -z "$akid" ] || [ "$akid" = "null" ] || [ -z "$sak" ] || [ "$sak" = "null" ]; then
  echo "error: item '$BW_ITEM_NAME' is missing login.username/login.password" >&2
  exit 1
fi

unset AWS_PROFILE AWS_SHARED_CREDENTIALS_FILE
AWS_ACCESS_KEY_ID="$akid" AWS_SECRET_ACCESS_KEY="$sak" "$@"
