# pisugar

PiSugar battery hat (PiSugar 2 / 3): packages, web UI, and the built-in
low-battery safe shutdown.

## What it does

- Detects any active I2C bus (`/dev/i2c-*`). On Raspberry Pi OS it is enabled
  automatically via raspi-config with a one-time reboot
  (disable with `pisugar_auto_reboot: false`).
- Installs the official `pisugar-server` + `pisugar-poweroff` packages
  (web UI on `http://<host>:8421`).
- Low-battery shutdown uses the mechanism built into `pisugar-server` (the
  same one the web GUI configures): the server polls the battery and when
  the level stays below `pisugar_safe_shutdown_level` for
  `pisugar_safe_shutdown_delay` seconds it runs `shutdown --poweroff 0` and
  broadcasts wall notifications during the countdown.
  `pisugar-poweroff.service` then cuts the hat output after the OS has shut
  down cleanly, so the filesystem is never left dirty.
- The role verifies `pisugar-server` runs as root — required for the built-in
  mechanism to execute the poweroff command.
- Settings are applied through the server's UDS API and persisted in
  `/etc/pisugar-server/config.json`; the role manages
  `auto_shutdown_level` / `auto_shutdown_delay` and the tap reaction keys,
  other web GUI settings are left untouched. A failed battery read is
  treated as a full battery, so a flaky I2C bus never triggers a shutdown.
- Button tap reactions (single / double / long press) are configured via
  `pisugar_tap_shells`: the built-in `pisugar-server` feature runs the given
  shell command through `/bin/sh -c` when the hat button is pressed — no
  custom units or scripts. Commands run as root (the server user); the
  command line is stored as a single line, embedded quotes are not
  preserved.
- Removes the former custom `pisugar-low-battery` timer and check script.

Note: the mechanism checks the battery level only, not the charger state. A
deeply discharged battery may still trigger shutdown right after the charger
is plugged in if the level stays below the threshold for the whole delay —
raise `pisugar_safe_shutdown_delay` if that matters.

## Radxa / Armbian notes

There is no raspi-config: enable the board's I2C overlay for the 40-pin header
yourself (uconfig on Radxa images, `overlays=` in `/boot/armbianEnv.txt` on
Armbian), reboot, and the role proceeds. On Radxa Zero 3W/3E with Armbian the
[`radxa_i2c3`](../radxa_i2c3/) role does this for header pins 3/5 — add it to
`sbc_extra_roles` before `pisugar`. If the header bus is not bus 1, point
pisugar-server at the right device in `/etc/default/pisugar-server`.

## Variables

```yaml
pisugar_model: "PiSugar 3"   # or "PiSugar 2 (4-LEDs)", "PiSugar 2 (2-LEDs)", "PiSugar 2 Pro"
pisugar_safe_shutdown_level: 15
pisugar_safe_shutdown_delay: 60
pisugar_tap_shells:
  single: "wall single tap"
  double: ""
  long: "shutdown -h now"
```

| Variable | Default | Description |
| --- | --- | --- |
| `pisugar_model` | `PiSugar 3` | hat model for package selection |
| `pisugar_safe_shutdown_level` | `15` | shutdown threshold, %; `0` disables; server clamps to 30 |
| `pisugar_safe_shutdown_delay` | `60` | seconds below the threshold before poweroff; server clamps to 120 |
| `pisugar_tap_shells` | all empty | shell command per `single` / `double` / `long` tap, empty = disabled |
| `pisugar_auto_reboot` | `true` | reboot once after enabling I2C on Raspberry Pi OS |

## Dependencies

None.
