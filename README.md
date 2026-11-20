# sbc-tools

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
   DEPLOY_KEY=./id_ed25519 ./bootstrap.sh
   ```

3. If the repo is public, it is enough to do:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/SozinovD/sbc-tools/main/bootstrap.sh | bash
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
  `sbc_extra_roles`.
- Role defaults (repo, branch, interval): `roles/ansible_pull/defaults/main.yml`,
  can be overridden in `host_vars/<hostname>.yml`.

## Secrets

Secrets (bot tokens, API keys) never live in this repo. Each device keeps them
in `/etc/sbc-tools/secrets.yml` (root-only, `chmod 600`), which `local.yml`
loads before applying roles — variables there override role defaults, so roles
read them as ordinary Ansible vars:

```yaml
# /etc/sbc-tools/secrets.yml
portainer_telegram_bot_token: "123456:ABC-DEF..."
portainer_telegram_api_key: "ptr_..."
portainer_telegram_allowed_chat_ids: "123456789"
```

Create the file once per device (scp or on console):

```bash
sudo install -d -m 700 /etc/sbc-tools
sudo tee /etc/sbc-tools/secrets.yml >/dev/null <<'EOF'
...
EOF
sudo chmod 600 /etc/sbc-tools/secrets.yml
```

The file is outside the repo and survives ansible-pull runs untouched.

## Diagnostics

```bash
systemctl status ansible-pull.timer     # timer state
systemctl list-timers ansible-pull.*    # next run
sudo systemctl start ansible-pull.service  # run right now
journalctl -u ansible-pull.service -f   # logs
```

## Versioning and CI

Every push to any branch runs `.github/workflows/ci.yml`: YAML validation,
ansible syntax-check, then a versioned `sbc-tools-<version>.zip` artifact.

Version scheme (semver):

- commits on `main` — clean `X.Y.Z`: latest `vX.Y.Z` tag plus one patch per
  commit since the tag (`0.0.<commit count>` until the first tag);
- commits on any other branch — `<branch>-<short sha>` (branch name sanitized
  to `[a-zA-Z0-9._-]`, so non-ASCII names fall back to `branch-<sha>`).

Every PR merged into `main` is automatically tagged `vX.Y.Z` by
`.github/workflows/release.yml` (annotated tag on the merge commit, PR number
and title in the message). The tag equals the version the ci job assigned to
the merge commit, so artifact and tag always match. Push a manual tag
(e.g. `v2.0.0`) to bump major/minor — releases after it continue from there.

## Roles

- `ansible_pull` — installs ansible and the systemd timer for self-updates.
- `docker` — Docker Engine + compose plugin from the official apt repository
  (Debian, Ubuntu, Raspberry Pi OS; arm64/armhf/amd64). Add users to the docker
  group via `docker_users`.
- `portainer` — Portainer CE for the local Docker environment (UI on
  `https://<host>:9443`, HTTP API on 9000, Edge tunnel on 8000; first admin
  user is created on first visit). Depends on `docker`.
- `portainer_telegram` — deploys
  [portainer-telegram](https://github.com/SozinovD/portainer-telegram) as a
  Portainer stack via the Portainer API (idempotent: creates or updates on
  content change). Requires an initialized Portainer (admin account created)
  and an API key (My Account → API Tokens). Secrets go to
  `/etc/sbc-tools/secrets.yml` on the device (see [Secrets](#secrets)):

  ```yaml
  portainer_telegram_bot_token: "123456:ABC-DEF..."
  portainer_telegram_api_key: "ptr_..."
  portainer_telegram_allowed_chat_ids: "123456789"   # strongly recommended
  ```

  Optional: `portainer_telegram_image`, `portainer_telegram_stack_name`,
  `portainer_telegram_portainer_url` (default `http://host.docker.internal:9000`),
  `portainer_telegram_portainer_endpoint_id`, `portainer_telegram_extra_env` —
  these can live in `host_vars/<hostname>.yml`.
  Depends on `portainer`.
- `hermes_agent` — hermes agent container managed via docker compose. Set the
  image and runtime settings in `host_vars/<hostname>.yml`:

  ```yaml
  hermes_agent_image: ghcr.io/sozinovd/hermes-agent:latest
  hermes_agent_ports:
    - "8080:8080"
  hermes_agent_volumes:
    - /opt/hermes-agent/data:/data
  hermes_agent_env:
    HERMES_LOG_LEVEL: info
  ```

  Depends on `docker`.

## Repo structure

```
local.yml                       entry playbook for ansible-pull
bootstrap.sh                    initial setup
host_vars/<hostname>.yml        per-device variables and list of roles
roles/ansible_pull/             installs ansible, service, and the update timer
roles/docker/                   Docker Engine + compose plugin
roles/portainer/                Portainer CE (docker backend)
roles/portainer_telegram/       portainer-telegram as a Portainer stack
roles/hermes_agent/             hermes agent in docker
roles/<other>/                  your device roles (users, packages, services)
```
