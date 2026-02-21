# uds-dev

Bootstrap an Ubuntu host for UDS development using Ansible (run from the `containerized-ansible` helper).

## What this playbook does (dev branch)

`playbooks/main.yaml` currently:

- installs Docker (via `geerlingguy.docker` vendored role)
- installs **k3d** from GitHub releases (**pinned** version)
- installs **UDS CLI** from GitHub releases (**pinned** version)
- optionally clones a list of repos into: `~/src/<remote-host>/<org>/<repo>`

## Structure

```bash
ansible-playbook-uds-dev/
├── ansible.cfg
├── inventory.yaml
├── run-playbook.sh
├── playbooks/
│   ├── main.yaml
│   └── tasks/
│       ├── fix-netplan-dhcp.yaml
│       ├── install-k3d.yaml
│       ├── install-uds-cli.yaml
│       └── clone-repos.yaml
└── roles/
    └── requirements.yaml
```

## Usage

### 1) Configure inventory

Edit `inventory.yaml`:

- set `ansible_host` (IP/DNS)
- set `ansible_user`

Example:

```yaml
all:
  hosts:
    uds-dev:
      ansible_host: 192.168.1.64
      ansible_user: andy
      ansible_connection: ssh
```

### 2) Run the playbook (recommended)

```bash
./run-playbook.sh
```

Pass through any extra `ansible-playbook` args:

```bash
./run-playbook.sh -vv
./run-playbook.sh --check
```

### 3) Version pins

Pins are set explicitly in `playbooks/main.yaml`:

- `k3d_version` (example: `v5.8.3`)
- `uds_cli_version` (example: `v0.28.2`)

### 4) Clone repos (repeatable)

The clone task takes `repos_to_clone` and clones into:

`/home/<ansible_user>/src/<remote-host>/<org>/<repo>`

Supported formats:

```yaml
repos_to_clone:
  - https://github.com/andygodish/package-k3d.git
  - git@github.com:andygodish/package-monitoring.git
  - repo: https://github.com/andygodish/package-base.git
    version: dev
```

Run only the clone step:

```bash
./run-playbook.sh --tags clone-repos
```

## Vendored roles

If you add dependencies to `roles/requirements.yaml`, the helper script will vendor them into `./roles/` using `ansible-galaxy`.
