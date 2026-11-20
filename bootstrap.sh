#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-git@github.com:SozinovD/sbc-tools.git}"
BRANCH="${BRANCH:-main}"
DEPLOY_KEY="${DEPLOY_KEY:-}"
WORKDIR="$(mktemp -d)"

cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

if [ "$(id -u)" -ne 0 ]; then
  exec sudo -E "$0" "$@"
fi

apt-get update
apt-get install -y ansible git python3-apt

if [ -n "$DEPLOY_KEY" ]; then
  install -d -m 0700 /etc/ansible-pull
  install -m 0600 "$DEPLOY_KEY" /etc/ansible-pull/id_ed25519
fi

git clone --branch "$BRANCH" "$REPO_URL" "$WORKDIR"

cd "$WORKDIR"
ansible-playbook -i "$(hostname) ansible_connection=local," local.yml
