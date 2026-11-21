# wifi_stability

Mitigates silent system freezes caused by AIC8800 wifi/bluetooth combo
chips (Radxa Zero 3, some Armbian boards): the SDIO driver deadlocks the
kernel under load with no logs, requiring a manual power cycle.

Measures:

- arms the systemd hardware watchdog (`RuntimeWatchdogSec`) so a frozen
  kernel reboots automatically instead of hanging until power cycle;
- disables wpa_supplicant P2P (adds `p2p_disabled=1` via a drop-in on the
  netplan-generated `netplan-wpa-<iface>.service`);
- masks `bluetooth.service` (shared combo chip, its timeouts precede wifi
  hangs).

Netplan-managed networking only; on NetworkManager hosts the wpa part is
skipped.

## Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `wifi_stability_interface` | `wlan0` | wifi interface |
| `wifi_stability_watchdog_sec` | `30` | `RuntimeWatchdogSec` |
| `wifi_stability_reboot_watchdog_sec` | `5min` | `RebootWatchdogSec` |
| `wifi_stability_mask_bluetooth` | `true` | stop and mask `bluetooth.service` |
| `wifi_stability_disable_p2p` | `true` | disable wpa_supplicant P2P |
