# Batteries

Wireless headset and WLMouse battery on the QS Bar: one icon + % per device.
Click for a panel with every device, a charge bar, status, and a refresh icon.

- **Runs:** `headsetcontrol -o json -b` and `bin/wlmouse-battery` every `pollSec`
  (default 60s) and when the panel opens. Each source can be toggled off.
- **Reads:** headsets via headsetcontrol (hidraw, udev rule shipped by the package);
  WLMouse (USB 36a7:a870 receiver / a871 wired) via /dev/hidraw, which needs a
  uaccess udev rule for vendor 36a7. The mouse script sends ONE read-only feature
  report (GET battery, opcode 0x83) — the same query the WL MOUSE HUB web driver
  polls. It never writes settings.
- **Writes:** nothing. **Network:** none. **Privileged:** none.

Adding a device type: write a script in `bin/` that prints headsetcontrol-shaped
JSON (`{"devices":[{device, product, kind, battery:{status, level}}]}`), add a
`Process` for it in `service/Main.qml`, and list it in `manifest.json` `files`.
Self-test: `bin/wlmouse-battery --test`.
