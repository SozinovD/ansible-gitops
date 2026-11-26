# common

Base packages, shell profile (aliases, default editor) and fail2ban for all
devices.

## What it does

- Installs the packages from `common_packages` (vim, tmux, htop, ...).
- Renders `/etc/profile.d/90-common.sh` with the aliases from
  `common_shell_aliases` and `EDITOR`/`VISUAL` set to `common_editor`
  (picked up by login shells for all users).
- Installs fail2ban, renders `common_fail2ban_jail_local_file` from the
  `common_fail2ban_*` variables, validates the config with
  `fail2ban-client -t` and enables the service. Set
  `common_fail2ban_enabled: false` to stop and disable it.

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `common_packages` | vim, tmux, htop, curl, wget, git, jq, rsync, tree, unzip | packages to install |
| `common_shell_aliases` | `ll`, `la`, `grep` | alias name → command, rendered into the profile |
| `common_editor` | `vim` | value for `EDITOR`/`VISUAL` (empty to skip) |
| `common_profile_d_file` | `/etc/profile.d/90-common.sh` | path of the managed profile script |
| `common_fail2ban_enabled` | `true` | manage fail2ban (false = stop and disable) |
| `common_fail2ban_jail_local_file` | `/etc/fail2ban/jail.local` | path of the rendered jail config |
| `common_fail2ban_bantime` | `1h` | initial ban duration |
| `common_fail2ban_bantime_increment` | `true` | grow the ban for repeat offenders (capped by maxtime) |
| `common_fail2ban_bantime_maxtime` | `1w` | upper bound of the incremental ban |
| `common_fail2ban_findtime` | `10m` | window for counting failures |
| `common_fail2ban_maxretry` | `3` | failures before a ban |
| `common_fail2ban_ignoreip` | loopback + RFC1918 ranges | IPs never banned (base list) |
| `common_fail2ban_extra_ignoreip` | `[]` | extra IPs/subnets merged into ignoreip — device-local secrets, see below |
| `common_fail2ban_jails` | `sshd: {backend: systemd}` | jail name → jail.local options (`enabled` key optional, default true) |

`common_fail2ban_extra_ignoreip` is meant to be set per device in
`/etc/ansible-gitops/secrets.yml` (VPN subnet, the git server the repo is
pulled from, ...) — it is merged with `common_fail2ban_ignoreip` and
duplicates are dropped.

## Dependencies

None.
