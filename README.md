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

## Diagnostics

```bash
systemctl status ansible-pull.timer     # timer state
systemctl list-timers ansible-pull.*    # next run
sudo systemctl start ansible-pull.service  # run right now
journalctl -u ansible-pull.service -f   # logs
```

## Roles

- `ansible_pull` — installs ansible and the systemd timer for self-updates.
- `docker` — Docker Engine + compose plugin from the official apt repository
  (Debian, Ubuntu, Raspberry Pi OS; arm64/armhf/amd64). Add users to the docker
  group via `docker_users`.
- `portainer` — Portainer CE for the local Docker environment (UI on
  `https://<host>:9443`, first admin user is created on first visit). Depends
  on `docker`.
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
roles/hermes_agent/             hermes agent in docker
roles/<other>/                  your device roles (users, packages, services)
```
