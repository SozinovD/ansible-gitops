# hermes_agent

hermes agent container managed via docker compose.

## What it does

- Deploys the agent from [templates/docker-compose.yml.j2](templates/docker-compose.yml.j2)
  into `hermes_agent_compose_dir` and runs it with `docker compose up --pull always`.

## Variables

Set image and runtime settings in `host_vars/<hostname>.yml`:

```yaml
hermes_agent_image: ghcr.io/sozinovd/hermes-agent:latest
hermes_agent_ports:
  - "8080:8080"
hermes_agent_volumes:
  - /opt/hermes-agent/data:/data
hermes_agent_env:
  HERMES_LOG_LEVEL: info
```

| Variable | Default | Description |
| --- | --- | --- |
| `hermes_agent_image` | `ghcr.io/sozinovd/hermes-agent:latest` | image |
| `hermes_agent_compose_dir` | `/opt/hermes-agent` | compose project directory |
| `hermes_agent_container_name` | `hermes-agent` | container name |
| `hermes_agent_restart_policy` | `unless-stopped` | container restart policy |
| `hermes_agent_ports` | `[]` | published ports |
| `hermes_agent_volumes` | `[]` | bind mounts |
| `hermes_agent_env` | `{}` | environment variables |

## Removal

List the role in `remove_roles` in `/etc/ansible-gitops/roles.yml` (see root
README "Local roles"). Containers are stopped and `hermes_agent_compose_dir`
is removed; bind-mounted data (e.g. `/opt/hermes-agent/data`) is kept and can
be deleted manually.

## Dependencies

- `docker`
