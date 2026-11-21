# ansible_pull

Installs ansible and the systemd service + timer that keep the device in sync
with this repo via `ansible-pull` (the self-management core of sbc-tools).
This is the only role `local.yml` applies unconditionally.

## What it does

- Installs `ansible` and `git` via the system package manager.
- Installs `ansible-pull.service` / `ansible-pull.timer` from the
  [template](templates/) and enables the timer
  (every `ansible_pull_interval`, catch-up after downtime).
- Optionally installs a read-only deploy key (`ansible_pull_deploy_key`) for
  private repos.

## Variables

Defaults in [defaults/main.yml](defaults/main.yml):

| Variable | Default | Description |
| --- | --- | --- |
| `ansible_pull_repo_url` | `git@github.com:SozinovD/sbc-tools.git` | repo to pull |
| `ansible_pull_checkout` | `main` | branch to track |
| `ansible_pull_playbook` | `local.yml` | playbook to apply |
| `ansible_pull_inventory` | `"{{ ansible_hostname }},"` | inventory (the device itself) |
| `ansible_pull_workdir` | `/var/lib/ansible-pull` | checkout directory |
| `ansible_pull_interval` | `30min` | timer interval |
| `ansible_pull_on_boot_sec` | `5min` | first run after boot |
| `ansible_pull_randomized_delay` | `5min` | jitter |
| `ansible_pull_only_changed` | `false` | run the playbook only when the repo changed |
| `ansible_pull_clean` | `true` | `-C` flag for ansible-pull |
| `ansible_pull_deploy_key` | `""` | private deploy key content; empty = skip |
| `ansible_pull_key_path` | `/etc/ansible-pull/id_ed25519` | where to store it |

## Dependencies

None.
