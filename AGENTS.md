# AGENTS.md

Guidelines for AI coding agents working in this repo.

## What this repo is

Self-managed configuration for SBC boards (Raspberry Pi, Radxa) based on
`ansible-pull`. Each device pulls this repo on a systemd timer and applies
`local.yml` to itself: inventory is `<hostname>,`, per-device variables live in
`host_vars/<hostname>.yml`. There is no control server and typically no live
device attached — changes are validated statically, real-device behavior is
verified by the user after merge.

Communication with the user: concise, in Russian.

## Ansible conventions

- Modules: always FQCN (`ansible.builtin.copy`, not `copy`).
- File modes as quoted strings (`mode: "0644"`), no comments in code.
- Role layout: `defaults/`, `tasks/`, `meta/`, plus `handlers/` and
  `templates/` when needed. Every role ships its own `README.md`
  (description, variables table, dependencies).
- Role variables are prefixed with the role name
  (`wifi_hotspot_ap_ssid`, `pisugar_model`); defaults belong in
  `defaults/main.yml`, never hardcoded in tasks.
- Compose-deploy pattern for services (see `roles/portainer`,
  `roles/hermes_agent`, `roles/wifi_hotspot`):
  1. defaults: `<role>_image`, `<role>_compose_dir`, `<role>_restart_policy`, ...;
  2. `templates/docker-compose.yml.j2` rendered into `<role>_compose_dir`;
  3. `ansible.builtin.command: docker compose --project-directory <dir> up
     --detach --pull always --remove-orphans` with
     `changed_when: (stdout ~ stderr) is search('Created|Recreated|Started')`;
  4. `meta/main.yml`: `dependencies` on `docker` where applicable.
- Secrets never live in this repo. Device-local secrets go to
  `/etc/sbc-tools/secrets.yml` (root-only 600), which `local.yml` loads via
  `include_vars` before applying roles — roles read them as ordinary vars.
  Keep `examples/secrets.yml.example` in sync when a role adds a secret var.
- Local role list (`/etc/sbc-tools/roles.yml`, optional on the device) is
  merged into `sbc_extra_roles` by a `set_fact` in `local.yml` pre_tasks:
  appended after the `host_vars` list, duplicates skipped, order preserved
  (`+` and `| difference(...)`, not `| union(...)` — union shuffles order,
  and role application order matters).

## Adding a role: checklist

1. `roles/<name>/` with defaults/tasks/meta (+ handlers/templates) following
   the conventions above; `meta/main.yml` galaxy_info: author `SozinovD`,
   license MIT, platforms Debian bookworm + Ubuntu noble.
2. `roles/<name>/README.md` with a variables table.
3. Root `README.md`: add a row to the "Roles" table and a line to
   "Repo structure".
4. Override examples (if any) → `host_vars/rpi-01.yml.example`.
5. Validate (commands below), then follow the git flow.

## Validation

Mirror of `.github/workflows/ci.yml`:

```bash
python3 -m pip install ansible-core pyyaml

# YAML parse of every file (same script as CI)
python3 - <<'PY'
import glob, yaml
files = set()
for pattern in ("*.yml", "*.yaml", "**/*.yml", "**/*.yaml"):
    files.update(glob.glob(pattern, recursive=True))
for f in sorted(files):
    if f.startswith((".git/", ".github/")):
        continue
    list(yaml.safe_load_all(open(f)))
print(f"checked {len(files)} yaml files")
PY

# Syntax-check local.yml plus every role
{
  printf -- "---\n- name: CI syntax check\n  hosts: all\n  become: true\n  roles:\n"
  for d in roles/*/; do printf "    - %s\n" "$(basename "${d}")"; done
} > /tmp/all-roles.yml
ANSIBLE_ROLES_PATH=roles ansible-playbook --syntax-check -i "localhost," -c local local.yml
ANSIBLE_ROLES_PATH=roles ansible-playbook --syntax-check -i "localhost," -c local /tmp/all-roles.yml
```

Note: with ansible-core ≥ 2.22 use `-i "localhost," -c local`;
`-i "localhost ansible_connection=local,"` fails with
"hostname contains invalid characters".

## Git and CI

- Default branch `main`. Feature branches in English kebab-case, based off a
  fresh `main`. Commit messages: imperative, one line.
- Never commit or push without explicit user approval; the user merges PRs on
  GitHub (`gh` CLI is not used). PR link after push:
  `https://github.com/SozinovD/sbc-tools/pull/new/<branch>`.
- After a merge: `git switch main && git pull`, then verify the new tag.
- Versioning is tag-driven, no manual bumps: every PR merged to `main` is
  auto-tagged `vX.Y.Z` by `.github/workflows/release.yml` (patch +1 per merge,
  computed from first-parent commit count). `ci.yml` builds a versioned zip
  artifact of the repo; config-only repo — no release artifacts.
- Expect the next tag to be the current top tag + 1 patch; flag if a merge
  did not produce it.

## Testing limitations

No live SBC hardware in the loop: no molecule tests. Functional checks are
ad-hoc playbooks in a temp dir (see `local.yml` pre_tasks for the
include_vars/set_fact merge test pattern) — prefer `-i "localhost," -c local`
local-connection runs for anything that must actually execute.
