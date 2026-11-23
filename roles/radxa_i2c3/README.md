# radxa_i2c3

Enables the i2c3 controller on the 40-pin header (pins 3/5, the Raspberry Pi
I2C position) of Radxa Zero 3W / 3E running Armbian, via the
`rk3568-i2c3-m0` device tree overlay.

## Why

On Armbian vendor kernels the Zero 3 device tree routes i2c3 to the m1 pin
group, where the onboard fusb302 USB-C controller sits. Any device attached
to header pins 3/5 (PiSugar 3, sensors, RTCs) is therefore invisible on the
bus until the overlay moves i2c3 to the m0 group:

- without the overlay: `/dev/i2c-3` works, but only fusb302 (0x22) answers;
- with the overlay: pins 3/5 carry i2c3, PiSugar answers at 0x57.

Side effect: fusb302 loses its bus, so USB-C OTG role detection stops
working (power input and the USB-C 2 host port are not affected). For new
I2C devices prefer pins 27/28 (i2c4, `rk3568-i2c4-m0` overlay) which has no
such conflict.

## What it does

- Detects Radxa Zero 3 on Armbian by the `fdtfile` entry in
  `/boot/armbianEnv.txt`; silently skips other boards.
- Verifies the overlay file exists in `/boot/dtb/rockchip/overlay/`.
- Appends the overlay to the `overlays=` line (other entries are preserved).
- Reboots the device once when the line changes
  (disable with `radxa_i2c3_reboot: false`).

Run it before `pisugar` on Radxa Zero 3 hosts.

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `radxa_i2c3_overlay` | `rk3568-i2c3-m0` | overlay appended to `overlays=` |
| `radxa_i2c3_overlay_dir` | `/boot/dtb/rockchip/overlay` | directory with `.dtbo` files |
| `radxa_i2c3_env_file` | `/boot/armbianEnv.txt` | Armbian u-boot environment file |
| `radxa_i2c3_reboot` | `true` | reboot once after changing the overlays line |

## Dependencies

None.
