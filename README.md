# uds-dev

Ansible playbook project for uds-dev.

## Structure

```
ansible-playbook-uds-dev/
├── ansible.cfg           # Ansible configuration
├── inventory.yaml        # Inventory file
├── run-playbook.sh       # Helper to run via Docker
├── playbooks/           # Playbook files
│   └── main.yaml        # Main playbook
├── roles/               # Roles (vendored via roles/requirements.yaml)
├── collections/         # Custom collections
├── vars/                # Variable files
├── vault/               # Encrypted files
├── artifacts/           # Output artifacts fetched from targets
├── group_vars/          # Group-specific variables
└── host_vars/           # Host-specific variables
```

## Usage

### Vendored roles (optional)

If you add role dependencies to `roles/requirements.yaml`, the helper script will automatically vendor them into `./roles/` using `ansible-galaxy`.

### Run the main playbook (recommended)

Use the helper script so you don’t have to remember all the volume mounts:

```bash
./run-playbook.sh
```

Defaults:
- Image: `containerized-ansible:2.20.2` (override with `IMAGE=...`)
- Target host limit: `macos-local` (override with `INVENTORY_HOSTS_LIMIT=...`)
- SSH key: `~/.ssh/id_ed25519` (override with `SSH_KEY=...`)

Before first run (macOS host target):
1. Edit `inventory.yaml` and set `macos-local.ansible_user` to your macOS username.
2. Ensure your SSH public key is authorized for that user:
   - Add it to `~/.ssh/authorized_keys` on the Mac
   - Enable **Remote Login** (System Settings → General → Sharing → Remote Login)

Pass through any extra `ansible-playbook` args:

```bash
./run-playbook.sh -vv
./run-playbook.sh --check
```

### Run the main playbook (manual)

```bash
# Example: run from the container, connecting to targets over SSH.
# NOTE: If you want to target the *macOS host* from the container, use host.docker.internal in inventory.yaml.
mkdir -p artifacts

docker run --rm \
  --entrypoint ansible-playbook \
  -e ANSIBLE_SSH_ARGS='-F /dev/null -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o IdentityFile=/home/nonroot/.ssh/id_ed25519 -o IdentitiesOnly=yes' \
  -v $(pwd)/playbooks:/ansible/playbooks \
  -v $(pwd)/inventory.yaml:/ansible/inventory/inventory.yaml:ro \
  -v $(pwd)/ansible.cfg:/ansible/ansible.cfg:ro \
  -v $(pwd)/roles:/ansible/roles \
  -v $(pwd)/collections:/ansible/collections \
  -v $(pwd)/artifacts:/ansible/artifacts \
  -v $(pwd)/.ssh-container:/home/nonroot/.ssh \
  -v ~/.ssh/id_ed25519:/home/nonroot/.ssh/id_ed25519:ro \
  containerized-ansible:<tag> \
  /ansible/playbooks/main.yaml -i /ansible/inventory/inventory.yaml --limit macos-local
```

### Or use the alias (if configured)

```bash
ansible-playbook playbooks/main.yaml
```

## Quick Start

1. Edit `inventory.yaml` with your target hosts
2. Modify `playbooks/main.yaml` with your tasks
3. Run the playbook using the command above

## Adding Roles

```bash
cd roles/
ansible-role-init my-role
```

## Variables

- **group_vars/**: Variables for inventory groups
- **host_vars/**: Variables for specific hosts
- **vars/**: General variable files

## Vault (Encrypted Secrets)

```bash
ansible-vault create vault/secrets.yaml
ansible-vault edit vault/secrets.yaml
```

Run playbook with vault:
```bash
ansible-playbook playbooks/main.yaml --ask-vault-pass
```
