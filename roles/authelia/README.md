# authelia

[Authelia](https://www.authelia.com/) in docker: single-factor authentication
portal and forward-auth endpoint for reverse proxies (pairs with the `caddy`
role via `auth: true` sites). Authelia does not support login through
external providers such as Google; for Google SSO add the `oauth2_proxy`
role and `auth: google` caddy sites.

## What it does

- Renders `configuration.yml` (file-based users, sqlite storage, filesystem
  notifier) and `users_database.yml` from
  [templates/](templates/) into `authelia_config_dir` (mounted as `/config`),
  sqlite state and notifications live in `authelia_data_dir` (mounted as
  `/data`).
- The three required secrets are never written into `configuration.yml`:
  they are deployed as root-only files in `authelia_config_dir/secrets/` and
  passed to the container via `AUTHELIA_*_FILE` environment variables
  (the upstream-recommended secrets method).
- Config, users and secret changes restart the container via the
  `Restart authelia` handler.
- Portal: `http://<host>:9091`, forward-auth endpoint for proxies: the same
  port (`/api/verify`).

Required settings in `host_vars/<hostname>.yml`:

```yaml
authelia_session_domain: example.com
authelia_access_rules:
  - domain:
      - portainer.example.com
    policy: one_factor
```

Secrets in `/etc/ansible-gitops/secrets.yml` (generate with
`openssl rand -hex 32`; see repo "Secrets"):

```yaml
authelia_jwt_secret: "..."
authelia_session_secret: "..."
authelia_storage_encryption_key: "..."
```

Users (also fine in `secrets.yml` — they contain password hashes) are a dict
of `name: {password, displayname, groups}`; generate a hash with
`docker run --rm authelia/authelia authelia crypto hash generate argon2`:

```yaml
authelia_users:
  admin:
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."
    displayname: Admin
    groups: [admins, users]
```

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `authelia_image` | `authelia/authelia:latest` | image |
| `authelia_compose_dir` | `/opt/authelia` | compose project directory |
| `authelia_container_name` | `authelia` | container name |
| `authelia_restart_policy` | `unless-stopped` | container restart policy |
| `authelia_ports` | `9091` | published ports |
| `authelia_config_dir` | `/etc/authelia` | configuration and secrets (→ `/config`) |
| `authelia_data_dir` | `/var/lib/authelia` | sqlite database and notifications (→ `/data`) |
| `authelia_session_domain` | — | cookie domain, required (e.g. `example.com`) |
| `authelia_default_policy` | `deny` | `access_control` default policy |
| `authelia_access_rules` | `[]` | `access_control` rules: `domain` (string or list) + `policy` |
| `authelia_theme` | `auto` | portal theme |
| `authelia_totp_issuer` | `Authelia` | TOTP issuer name |
| `authelia_log_level` | `info` | log level |
| `authelia_users` | `{}` | users database, see above |
| `authelia_extra_config` | `""` | raw configuration appended to `configuration.yml` |
| `authelia_jwt_secret` | — | jwt secret (secret: secrets.yml) |
| `authelia_session_secret` | — | session secret (secret: secrets.yml) |
| `authelia_storage_encryption_key` | — | storage encryption key (secret: secrets.yml) |

The role fails early when `authelia_session_domain` or any of the three
secrets is missing. Back up `authelia_data_dir` together with
`authelia_storage_encryption_key`: the key encrypts TOTP seeds and 2FA data
in the database.

## Dependencies

- `docker`
