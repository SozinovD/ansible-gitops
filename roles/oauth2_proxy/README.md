# oauth2_proxy

[oauth2-proxy](https://github.com/oauth2-proxy/oauth2-proxy) in docker: login
to caddy sites with a Google account (OpenID Connect). Authelia deliberately
does not support the OIDC relying-party role, so Google SSO runs next to it —
caddy sites pick the method per site (`auth: true` for Authelia,
`auth: google` for oauth2-proxy, see the `caddy` role).

## What it does

- Deploys oauth2-proxy from [templates/docker-compose.yml.j2](templates/docker-compose.yml.j2),
  configured entirely via `OAUTH2_PROXY_*` environment variables: provider
  `google`, secure cookies, `X-Auth-Request-*` headers for upstreams.
- Restricts who may log in: either `oauth2_proxy_allowed_emails` (exact
  addresses, rendered into a root-only `authenticated-emails` file) or
  `oauth2_proxy_email_domains`. The role fails early when neither is set —
  an unrestricted oauth2-proxy would accept every Google account.
- The login/consent/callback endpoints live under `/oauth2/` on each
  protected site (proxied by the caddy role), so the service needs no
  hostname of its own; `4180` is published only for caddy's forward-auth.

Google Cloud Console setup: create an OAuth consent screen (External) and an
OAuth client ID of type *Web application* with an authorized redirect URI
`https://<site-host>/oauth2/callback` for **every** caddy site using
`auth: google`. Put the client id/secret in secrets.yml (see below).

Settings in `host_vars/<hostname>.yml`:

```yaml
oauth2_proxy_allowed_emails:
  - me@gmail.com
# or:
# oauth2_proxy_email_domains: [example.com]
# shared SSO cookie across sites (login once on any of them):
# oauth2_proxy_cookie_domains: [.example.com]
# oauth2_proxy_whitelist_domains: [.example.com]
```

Secrets in `/etc/ansible-gitops/secrets.yml` (see repo "Secrets"); generate
the cookie secret with
`python3 -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())'`:

```yaml
oauth2_proxy_client_id: "1234-abc.apps.googleusercontent.com"
oauth2_proxy_client_secret: "GOCSPX-..."
oauth2_proxy_cookie_secret: "..."
```

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `oauth2_proxy_image` | `quay.io/oauth2-proxy/oauth2-proxy:latest` | image |
| `oauth2_proxy_compose_dir` | `/opt/oauth2-proxy` | compose project directory |
| `oauth2_proxy_container_name` | `oauth2-proxy` | container name |
| `oauth2_proxy_restart_policy` | `unless-stopped` | container restart policy |
| `oauth2_proxy_ports` | `4180` | published ports (for caddy forward-auth) |
| `oauth2_proxy_config_dir` | `/etc/oauth2-proxy` | authenticated-emails file location |
| `oauth2_proxy_provider` | `google` | oauth2-proxy provider |
| `oauth2_proxy_allowed_emails` | `[]` | exact accounts allowed to log in |
| `oauth2_proxy_email_domains` | `[]` | alternative: allowed email domains |
| `oauth2_proxy_cookie_domains` | `[]` | shared SSO cookie domains, e.g. `.example.com` |
| `oauth2_proxy_whitelist_domains` | `[]` | allowed redirect domains, set together with cookie domains |
| `oauth2_proxy_scope` | `openid email profile` | OAuth scopes |
| `oauth2_proxy_extra_env` | `{}` | extra `OAUTH2_PROXY_*` environment |
| `oauth2_proxy_client_id` | — | Google OAuth client id (secret: secrets.yml) |
| `oauth2_proxy_client_secret` | — | Google OAuth client secret (secret: secrets.yml) |
| `oauth2_proxy_cookie_secret` | — | session cookie secret (secret: secrets.yml) |

Without `oauth2_proxy_cookie_domains` every site host gets its own session
cookie (login once per host); with it (plus matching
`oauth2_proxy_whitelist_domains`) one login covers all sites under the
domain. Sites must be served over HTTPS (`cookie_secure` is on). The rendered
compose file contains the provider secret, so it is deployed with mode 0640.

## Dependencies

- `docker`

## Removal

List the role in `remove_roles` in `/etc/ansible-gitops/roles.yml` (see root
README "Local roles"). Containers are stopped and `oauth2_proxy_compose_dir`
is removed; `/etc/oauth2-proxy` is kept and can be deleted manually.
