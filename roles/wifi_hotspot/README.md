# wifi_hotspot

[sbc-wifi-hotspot](https://github.com/SozinovD/sbc-wifi-hotspot) in docker:
connects to known Wi-Fi networks and, when none are around (or there is no
internet), raises an access point with a captive portal to pick a network and
enter the password.

## What it does

- Deploys the service from [templates/docker-compose.yml.j2](templates/docker-compose.yml.j2)
  with `network_mode: host` and `NET_ADMIN`/`NET_RAW` capabilities.
- If NetworkManager is present, excludes `wifi_hotspot_interface` from its
  control via a drop-in in `/etc/NetworkManager/conf.d/` and restarts it before
  starting the container.
- Known networks are stored in `wifi_hotspot_data_dir`
  (bind-mounted to `/data` in the container).

## Variables

Settings in `host_vars/<hostname>.yml`:

```yaml
wifi_hotspot_interface: mlan0     # wlan0 by default, mlan0 on Radxa Zero 3W
wifi_hotspot_ap_ssid: SBC-Hotspot
wifi_hotspot_ap_passphrase: change-me   # or put it in /etc/sbc-tools/secrets.yml
wifi_hotspot_env:                # any other service variables
  AP_CHANNEL: "6"
  MONITOR_INTERVAL: "30"
```

| Variable | Default | Description |
| --- | --- | --- |
| `wifi_hotspot_image` | `ghcr.io/sozinovd/sbc-wifi-hotspot:latest` | image |
| `wifi_hotspot_compose_dir` | `/opt/sbc-wifi-hotspot` | compose project directory |
| `wifi_hotspot_container_name` | `sbc-wifi-hotspot` | container name |
| `wifi_hotspot_restart_policy` | `unless-stopped` | container restart policy |
| `wifi_hotspot_interface` | `wlan0` | managed wireless interface |
| `wifi_hotspot_ap_ssid` | `SBC-Hotspot` | hotspot SSID |
| `wifi_hotspot_ap_passphrase` | `sbc-hotspot` | hotspot password (device-local: secrets.yml) |
| `wifi_hotspot_data_dir` | `/var/lib/sbc-wifi-hotspot` | persistent state (known networks) |
| `wifi_hotspot_env` | `{}` | extra service environment |

## Dependencies

- `docker`
