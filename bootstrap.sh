#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/SozinovD/ansible-gitops.git}"
BRANCH="${BRANCH:-main}"
DEPLOY_KEY="${DEPLOY_KEY:-}"
WORKDIR="$(mktemp -d)"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
fi

cleanup() {
  $SUDO rm -rf "$WORKDIR"
}
trap cleanup EXIT

$SUDO apt-get update
$SUDO apt-get install -y ansible git python3-apt

if [ -n "$DEPLOY_KEY" ]; then
  $SUDO install -d -m 0700 /etc/ansible-pull
  $SUDO install -m 0600 "$DEPLOY_KEY" /etc/ansible-pull/id_ed25519
  $SUDO GIT_SSH_COMMAND="ssh -i /etc/ansible-pull/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new" \
    git clone --branch "$BRANCH" "$REPO_URL" "$WORKDIR"
else
  git clone --branch "$BRANCH" "$REPO_URL" "$WORKDIR"
fi

cd "$WORKDIR"
$SUDO ansible-playbook -i "$(hostname)," -c local local.yml
