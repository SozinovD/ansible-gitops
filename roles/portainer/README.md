# portainer

Portainer CE for the local Docker environment, deployed as a docker compose
project.

## What it does

- Deploys Portainer CE from [templates/docker-compose.yml.j2](templates/docker-compose.yml.j2)
  into `portainer_compose_dir` and runs it with `docker compose up --pull always`.
- UI: `https://<host>:9443`, HTTP API: `9000`, Edge tunnel: `8000`.
- Portainer locks itself ("timed out for security purposes") if the initial
  admin user is not created within 5 minutes after start. The role detects
  this (via `GET /api/users/admin/check`: 204 = admin exists, 404 = not
  initialized, 303 = timed out) and restarts the container to reset the
  lockout, so the UI is always usable.
- If `portainer_admin_password` is set (device-local secret, see repo
  "Secrets"), the role also creates the initial admin user itself via
  `POST /api/users/admin/init`; otherwise the user completes the setup form
  manually within 5 minutes after the role run. Password must be at least
  12 characters long.

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `portainer_image` | `portainer/portainer-ce:lts` | image |
| `portainer_compose_dir` | `/opt/portainer` | compose project directory |
| `portainer_restart_policy` | `unless-stopped` | container restart policy |
| `portainer_ports` | `9443, 9000, 8000` | published ports |
| `portainer_volumes` | docker.sock + named volume | bind mounts |
| `portainer_api_url` | `http://localhost:9000` | API endpoint used for admin bootstrap |
| `portainer_admin_user` | `admin` | initial admin username |
| `portainer_admin_password` | — | initial admin password (secret, min 12 chars) |

## Dependencies

- `docker`
