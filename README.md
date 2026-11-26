# ansible-gitops

Self-managed configuration for SBC (Raspberry Pi, Radxa) based on
`ansible-pull`: each device pulls this repo on a schedule and applies
`local.yml` to itself. No control server required.

## Supported targets

Debian-based OS on ARM64: Raspberry Pi OS, Armbian / Radxa official images
(Debian, Ubuntu).

## First run

1. Flash the OS image (rpi-imager / radxa etcher) and set the device hostname,
   e.g. `rpi-01`. The hostname is the device identity used below.
2. If the repo is private: generate a **read-only** deploy key and put the
   private part on the device:

   ```bash
   ssh-keygen -t ed25519 -f id_ed25519 -N ""   # add the .pub as a deploy key in GitHub
   REPO_URL=git@github.com:SozinovD/ansible-gitops.git DEPLOY_KEY=./id_ed25519 ./bootstrap.sh
   ```

3. If the repo is public, it is enough to do:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/SozinovD/ansible-gitops/main/bootstrap.sh | bash
   ```

   (with a private repo, first `git clone` the repo to the device and run
   `./bootstrap.sh` from there, providing SSH access to the key.)

`bootstrap.sh` will install ansible and git, run `local.yml` once, and install
the systemd timer.

## How it works

- `ansible-pull.timer` runs `ansible-pull.service` every 30 minutes
  (OnBootSec=5min, RandomizedDelaySec=5min, Persistent=true — it catches up
  after downtime).
- The service clones the repo into `/var/lib/ansible-pull` and runs
  `local.yml` against itself (inventory: `<hostname>,`).
- Device-specific settings and roles: `host_vars/<hostname>.yml`
  (see `host_vars/rpi-01.yml.example`), add roles for the device to
  `extra_roles`. A device can also add roles locally without touching the
  repo — see [Local roles](#local-roles).
- Role defaults (repo, branch, interval): `roles/ansible_pull/defaults/main.yml`,
  can be overridden in `host_vars/<hostname>.yml`.

## Secrets

Secrets (bot tokens, API keys) never live in this repo. Each device keeps them
in `/etc/ansible-gitops/secrets.yml` (root-only, `chmod 600`), which `local.yml`
loads before applying roles — variables there override role defaults, so roles
read them as ordinary Ansible vars:

```yaml
# /etc/ansible-gitops/secrets.yml
portainer_telegram_bot_token: "123456:ABC-DEF..."
portainer_telegram_api_key: "ptr_..."
portainer_telegram_allowed_chat_ids: "123456789"
```

Create the file once per device (scp or on console):

```bash
sudo install -d -m 700 /etc/ansible-gitops
sudo tee /etc/ansible-gitops/secrets.yml >/dev/null <<'EOF'
...
EOF
sudo chmod 600 /etc/ansible-gitops/secrets.yml
```

The file is outside the repo and survives ansible-pull runs untouched.
A sample with all variables the roles read from it:
[`examples/secrets.yml.example`](examples/secrets.yml.example).

## Local roles

A device can extend its role list locally, without a commit to this repo:
list extra roles in `/etc/ansible-gitops/roles.yml` (root-only, `chmod 600`).
`local.yml` loads it before applying roles and appends them to
`extra_roles` from `host_vars` (after the repo list, duplicates skipped):

```yaml
# /etc/ansible-gitops/roles.yml
extra_roles:
  - wifi_hotspot
```

Variables for locally added roles can live in the same file or in
`/etc/ansible-gitops/secrets.yml`. Both files are outside the repo and survive
ansible-pull runs untouched. A sample:
[`examples/roles.yml.example`](examples/roles.yml.example).

## Diagnostics

```bash
systemctl status ansible-pull.timer     # timer state
systemctl list-timers ansible-pull.*    # next run
sudo systemctl start ansible-pull.service  # run right now
journalctl -u ansible-pull.service -f   # logs
```

## Versioning and CI

Every push to any branch runs `.github/workflows/ci.yml`: YAML validation,
ansible syntax-check, then a versioned `ansible-gitops-<version>.zip` artifact.

Version scheme (semver):

- commits on `main` — clean `X.Y.Z`: latest `vX.Y.Z` tag plus one patch per
  commit on the first-parent chain of `main` since the tag (PR branch commits
  don't count, so each merged PR bumps the patch by exactly 1;
  `0.0.<commit count>` until the first tag);
- commits on any other branch — `<branch>-<short sha>` (branch name sanitized
  to `[a-zA-Z0-9._-]`, so non-ASCII names fall back to `branch-<sha>`).

Every PR merged into `main` and every commit pushed directly to `main` is
automatically tagged `vX.Y.Z` by `.github/workflows/release.yml` (annotated
tag on the merge/push commit; PR number and title in the message for merges,
commit subject for direct pushes). The tag equals the version the ci job
assigned to the commit, so artifact and tag always match. Push a manual tag
(e.g. `v2.0.0`) to bump major/minor — releases after it continue from there.

## Roles

| Role | Purpose |
| --- | --- |
| [`ansible_pull`](roles/ansible_pull/) | ansible + systemd timer for self-updates |
| [`common`](roles/common/) | base packages, shell aliases and editor |
| [`docker`](roles/docker/) | Docker Engine + compose plugin |
| [`authelia`](roles/authelia/) | Authelia SSO portal and forward-auth in docker |
| [`caddy`](roles/caddy/) | Caddy reverse proxy in docker |
| [`netbird`](roles/netbird/) | NetBird client (mesh VPN peer) in docker |
| [`oauth2_proxy`](roles/oauth2_proxy/) | oauth2-proxy in docker, Google SSO for caddy sites |
| [`portainer`](roles/portainer/) | Portainer CE for the local docker |
| [`portainer_telegram`](roles/portainer_telegram/) | portainer-telegram as a Portainer stack |
| [`hermes_agent`](roles/hermes_agent/) | hermes agent in docker |
| [`pisugar`](roles/pisugar/) | PiSugar battery hat, low battery shutdown |
| [`radxa_i2c3`](roles/radxa_i2c3/) | i2c3 on Zero 3 header pins 3/5 (Armbian overlay) |
| [`wifi_hotspot`](roles/wifi_hotspot/) | sbc-wifi-hotspot in docker |
| [`wifi_stability`](roles/wifi_stability/) | watchdog + AIC8800 wifi freeze mitigations |

Details, variables and dependencies are documented in each role's `README.md`.

## Repo structure

```
local.yml                       entry playbook for ansible-pull
bootstrap.sh                    initial setup
examples/                       sample /etc/ansible-gitops/secrets.yml and roles.yml
host_vars/<hostname>.yml        per-device variables and list of roles
roles/ansible_pull/             installs ansible, service, and the update timer
roles/common/                   base packages, shell aliases and editor
roles/docker/                   Docker Engine + compose plugin
roles/authelia/                 Authelia SSO portal in docker
roles/caddy/                    Caddy reverse proxy in docker
roles/netbird/                  NetBird client (mesh VPN peer) in docker
roles/oauth2_proxy/             oauth2-proxy, Google SSO for caddy sites
roles/portainer/                Portainer CE (docker backend)
roles/portainer_telegram/       portainer-telegram as a Portainer stack
roles/hermes_agent/             hermes agent in docker
roles/pisugar/                  PiSugar battery hat, low battery shutdown
roles/radxa_i2c3/               i2c3 overlay for the Zero 3 40-pin header
roles/wifi_hotspot/             sbc-wifi-hotspot in docker
roles/wifi_stability/           watchdog + AIC8800 wifi freeze mitigations
roles/<other>/                  your device roles (users, packages, services)
```
