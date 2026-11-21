# common

Base packages and shell profile (aliases, default editor) for all devices.

## What it does

- Installs the packages from `common_packages` (vim, tmux, htop, ...).
- Renders `/etc/profile.d/90-common.sh` with the aliases from
  `common_shell_aliases` and `EDITOR`/`VISUAL` set to `common_editor`
  (picked up by login shells for all users).

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `common_packages` | vim, tmux, htop, curl, wget, git, jq, rsync, tree, unzip | packages to install |
| `common_shell_aliases` | `ll`, `la`, `grep` | alias name → command, rendered into the profile |
| `common_editor` | `vim` | value for `EDITOR`/`VISUAL` (empty to skip) |
| `common_profile_d_file` | `/etc/profile.d/90-common.sh` | path of the managed profile script |

## Dependencies

None.
