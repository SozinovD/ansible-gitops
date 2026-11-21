# portainer

Portainer CE for the local Docker environment, deployed as a docker compose
project.

## What it does

- Deploys Portainer CE from [templates/docker-compose.yml.j2](templates/docker-compose.yml.j2)
  into `portainer_compose_dir` and runs it with `docker compose up --pull always`.
- UI: `https://<host>:9443`, HTTP API: `9000`, Edge tunnel: `8000`.
  The first admin user is created on first visit (open the UI once).

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `portainer_image` | `portainer/portainer-ce:lts` | image |
| `portainer_compose_dir` | `/opt/portainer` | compose project directory |
| `portainer_restart_policy` | `unless-stopped` | container restart policy |
| `portainer_ports` | `9443, 9000, 8000` | published ports |
| `portainer_volumes` | docker.sock + named volume | bind mounts |

## Dependencies

- `docker`
