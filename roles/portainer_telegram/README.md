# portainer_telegram

Deploys [portainer-telegram](https://github.com/SozinovD/portainer-telegram)
as a Portainer stack via the Portainer HTTP API (idempotent: creates or updates
the stack when the definition changes).

## Requirements

- Initialized Portainer: the admin account must already exist (open the UI
  once after applying the `portainer` role).
- A Portainer API key: My Account → API Tokens. Put it in
  `/etc/ansible-gitops/secrets.yml` on the device, not in this repo:

```yaml
portainer_telegram_bot_token: "123456:ABC-DEF..."
portainer_telegram_api_key: "ptr_..."
portainer_telegram_allowed_chat_ids: "123456789"   # strongly recommended
```

## Variables

Non-secret settings live in `host_vars/<hostname>.yml`:

| Variable | Default | Description |
| --- | --- | --- |
| `portainer_telegram_image` | `ghcr.io/sozinovd/portainer-telegram:latest` | image |
| `portainer_telegram_stack_name` | `portainer-telegram` | stack name in Portainer |
| `portainer_telegram_portainer_url` | `http://host.docker.internal:9000` | Portainer API URL as seen from the container |
| `portainer_telegram_portainer_endpoint_id` | `""` | endpoint id (empty = first endpoint) |
| `portainer_telegram_extra_env` | `{}` | extra stack environment |

## Dependencies

- `portainer`

## Removal

List the role in `remove_roles` in `/etc/ansible-gitops/roles.yml` (see root
README "Local roles"). The stack is deleted from Portainer via its API; if
Portainer is unreachable, the removal is skipped without failing the run.
