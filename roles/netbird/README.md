# netbird

[NetBird](https://netbird.io/) client in docker: joins the device to an
existing NetBird network as a peer (WireGuard mesh, `network_mode: host`).

## What it does

- Deploys the client from [templates/docker-compose.yml.j2](templates/docker-compose.yml.j2)
  with host networking, `NET_ADMIN`/`SYS_ADMIN`/`SYS_RESOURCE` capabilities
  and the `/dev/net/tun` device, per the upstream docker guide.
- If `/dev/net/tun` is missing, loads the `tun` kernel module and persists it
  in `/etc/modules-load.d/netbird-tun.conf`; fails with a clear message when
  the module is unavailable on the host.
- Registers the peer with a setup key (`netbird_setup_key`) passed as the
  `NB_SETUP_KEY` environment variable. For a self-hosted NetBird set
  `netbird_management_url` in `host_vars`.
- Peer state lives in the `netbird_client` named volume: after the first
  successful registration the client reconnects on its own, and `NB_*`
  environment changes are only applied while the volume is empty — to apply
  new client settings, remove the volume (`docker volume rm
  <project>_netbird_client`) so the peer re-registers.

Check the connection on the device with
`docker exec netbird netbird status`.

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `netbird_image` | `netbirdio/netbird:latest` | image |
| `netbird_compose_dir` | `/opt/netbird` | compose project directory |
| `netbird_container_name` | `netbird` | container name |
| `netbird_restart_policy` | `unless-stopped` | container restart policy |
| `netbird_hostname` | `{{ inventory_hostname }}` | peer name in the NetBird network |
| `netbird_management_url` | — | management URL for self-hosted NetBird (empty = cloud) |
| `netbird_setup_key` | — | setup key (secret, see below) |
| `netbird_extra_env` | `{}` | extra `NB_*` environment variables |

`netbird_setup_key` is a device-local secret: create a setup key in the
NetBird dashboard and put it in `/etc/ansible-gitops/secrets.yml`
(see repo "Secrets"). The role fails early when it is not defined.

## Dependencies

- `docker`

## Removal

List the role in `remove_roles` in `/etc/ansible-gitops/roles.yml` (see root
README "Local roles"). Containers are stopped, `netbird_compose_dir` and
`/etc/modules-load.d/netbird-tun.conf` are removed; the `netbird_client`
volume with the peer state is kept.
