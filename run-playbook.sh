#!/usr/bin/env bash
set -euo pipefail

# Runs the bootstrapped playbook (playbooks/main.yaml) using the containerized-ansible image.
# Default target: macos-local (host.docker.internal)

IMAGE=${IMAGE:-"containerized-ansible:2.20.2"}
INVENTORY_HOSTS_LIMIT=${INVENTORY_HOSTS_LIMIT:-"macos-local"}
PLAYBOOK=${PLAYBOOK:-"playbooks/main.yaml"}
INVENTORY=${INVENTORY:-"inventory.yaml"}
SSH_KEY=${SSH_KEY:-"$HOME/.ssh/id_ed25519"}

if [[ ! -f "$SSH_KEY" ]]; then
  echo "ERROR: SSH key not found at $SSH_KEY" >&2
  echo "Set SSH_KEY=/path/to/key (or create one)" >&2
  exit 1
fi

mkdir -p artifacts
mkdir -p .ssh-container

# Disable reading macOS-specific ~/.ssh/config (UseKeychain, etc.)
# Avoid writing known_hosts inside the container.
ANSIBLE_SSH_ARGS=${ANSIBLE_SSH_ARGS:-"-F /dev/null -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o IdentityFile=/home/nonroot/.ssh/id_ed25519 -o IdentitiesOnly=yes"}

# Vendor roles (if roles/requirements.yaml exists)
if [[ -f "roles/requirements.yaml" ]]; then
  docker run --rm \
    --entrypoint ansible-galaxy \
    -v "$(pwd):/ansible" \
    -w /ansible \
    -e GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -o IdentityFile=/home/nonroot/.ssh/id_ed25519' \
    -v "$(pwd)/.ssh-container:/home/nonroot/.ssh" \
    -v "$SSH_KEY:/home/nonroot/.ssh/id_ed25519:ro" \
    "$IMAGE" \
    role install -r roles/requirements.yaml -p roles/
fi

exec docker run --rm -it \
  --entrypoint ansible-playbook \
  -e ANSIBLE_SSH_ARGS="$ANSIBLE_SSH_ARGS" \
  -v "$(pwd)/playbooks:/ansible/playbooks" \
  -v "$(pwd)/$INVENTORY:/ansible/inventory/inventory.yaml:ro" \
  -v "$(pwd)/ansible.cfg:/ansible/ansible.cfg:ro" \
  -v "$(pwd)/roles:/ansible/roles" \
  -v "$(pwd)/collections:/ansible/collections" \
  -v "$(pwd)/artifacts:/ansible/artifacts" \
  -v "$(pwd)/.ssh-container:/home/nonroot/.ssh" \
  -v "$SSH_KEY:/home/nonroot/.ssh/id_ed25519:ro" \
  "$IMAGE" \
  "/ansible/$PLAYBOOK" -i /ansible/inventory/inventory.yaml --limit "$INVENTORY_HOSTS_LIMIT" "$@"
