# docker

Docker Engine + docker compose plugin from the official Docker apt repository.

## What it does

- Adds Docker's apt repo for the detected distro
  (Debian, Ubuntu, Raspbian/Raspberry Pi OS) and architecture
  (arm64 / armhf / amd64).
- Installs `docker-ce`, `docker-ce-cli`, `containerd.io`,
  `docker-buildx-plugin`, `docker-compose-plugin`.
- Enables and starts the service.
- Adds users from `docker_users` to the `docker` group
  (they need to re-login for it to take effect).

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `docker_users` | `[]` | users to add to the `docker` group |
| `docker_apt_dist` | auto | apt distribution name |
| `docker_apt_arch` | auto | apt architecture name |

## Dependencies

None. Base for `portainer`, `hermes_agent`, `wifi_hotspot`.
