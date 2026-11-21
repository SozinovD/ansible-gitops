# pisugar

PiSugar battery hat (PiSugar 2 / 3): packages, web UI, and a low-battery
watchdog that shuts the device down safely.

## What it does

- Detects any active I2C bus (`/dev/i2c-*`). On Raspberry Pi OS it is enabled
  automatically via raspi-config with a one-time reboot
  (disable with `pisugar_auto_reboot: false`).
- Installs the official `pisugar-server` + `pisugar-poweroff` packages
  (web UI on `http://<host>:8421`).
- Low-battery watchdog: a systemd timer checks the battery and shuts the device
  down when the level is at or below `pisugar_low_battery_level` (default 15%)
  **and** it is not charging.

## Radxa / Armbian notes

There is no raspi-config: enable the board's I2C overlay for the 40-pin header
yourself (uconfig on Radxa images, `overlays=` in `/boot/armbianEnv.txt` on
Armbian), reboot, and the role proceeds. If the header bus is not bus 1, point
pisugar-server at the right device in `/etc/default/pisugar-server`.

## Variables

```yaml
pisugar_model: "PiSugar 3"   # or "PiSugar 2 (4-LEDs)", "PiSugar 2 (2-LEDs)", "PiSugar 2 Pro"
pisugar_low_battery_level: 15
pisugar_check_interval: 1min
```

| Variable | Default | Description |
| --- | --- | --- |
| `pisugar_model` | `PiSugar 3` | hat model for package selection |
| `pisugar_low_battery_level` | `15` | shutdown threshold, % |
| `pisugar_check_interval` | `1min` | watchdog timer interval |
| `pisugar_auto_reboot` | `true` | reboot once after enabling I2C on Raspberry Pi OS |

## Dependencies

None.
