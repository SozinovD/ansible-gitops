# caddy

[Caddy](https://caddy.dev/) reverse proxy in docker: automatic HTTPS (ACME,
HTTP/3), sites described declaratively in `caddy_sites`.

## What it does

- Renders [templates/Caddyfile.j2](templates/Caddyfile.j2) from `caddy_sites`
  into `caddy_compose_dir/Caddyfile` and deploys the container from
  [templates/docker-compose.yml.j2](templates/docker-compose.yml.j2)
  with published `80`/`443`/`443/udp` ports; certificates live in the
  `caddy_data` named volume.
- `host.docker.internal` resolves to the docker host (via `host-gateway`),
  so upstreams can point at services published by the host, e.g.
  `host.docker.internal:9443` for portainer.
- Each site is `{host, to, auth, tls}`: `host` and the `reverse_proxy`
  upstream `to` are required; `auth: true` puts the site behind Authelia
  forward-auth (see the `authelia` role); `auth: google` puts it behind
  oauth2-proxy forward-auth with Google login (see the `oauth2_proxy` role);
  `tls` renders a `tls` directive, e.g. `internal` for LAN-only names
  (self-signed).
- Caddyfile changes restart the container via the `Restart caddy` handler;
  certificate emails go into the global options block when `caddy_email` is
  set.

Settings in `host_vars/<hostname>.yml`:

```yaml
caddy_email: admin@example.com
caddy_sites:
  - host: portainer.example.com
    to: host.docker.internal:9443
    auth: true
  - host: app.example.com
    to: host.docker.internal:8080
    auth: google
  - host: home.example.com
    to: host.docker.internal:8080
    tls: internal
```

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `caddy_image` | `caddy:2` | image |
| `caddy_compose_dir` | `/opt/caddy` | compose project directory (Caddyfile lives here) |
| `caddy_container_name` | `caddy` | container name |
| `caddy_restart_policy` | `unless-stopped` | container restart policy |
| `caddy_ports` | `80, 443, 443/udp` | published ports |
| `caddy_email` | — | ACME account email |
| `caddy_sites` | `[]` | sites: `host`, `to`, optional `auth` (`true`/`google`), `tls` |
| `caddy_authelia_addr` | `host.docker.internal:9091` | authelia forward-auth address |
| `caddy_oauth2_proxy_addr` | `host.docker.internal:4180` | oauth2-proxy forward-auth address |
| `caddy_extra_config` | `""` | raw Caddyfile directives appended at the end |

When `auth: true` is used, the `authelia` role must run on the same device
and publish `9091` (its default) so the forward-auth endpoint is reachable
via `caddy_authelia_addr`. Likewise `auth: google` requires the
`oauth2_proxy` role publishing `4180`, with the site's
`https://<host>/oauth2/callback` registered in the Google OAuth client.

## Dependencies

- `docker`
