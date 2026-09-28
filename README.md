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

## Custom readers (the contract)

Any executable can add devices: put its absolute path in **Custom reader scripts**
(QS Bar Settings > Community > Batteries; several paths comma-separated). It is
run with no arguments and no shell every poll, and must print:

```json
{"devices": [{"device": "Rainy75", "product": "Rainy 75 Keyboard", "kind": "keyboard",
              "battery": {"status": "BATTERY_CHARGING", "level": 62},
              "errors": {"battery": "only when level is -1"}}]}
```

- `battery.level`: 0-100, or -1 when unknown. Everything else is optional.
- `battery.status`: `BATTERY_CHARGING` | `BATTERY_AVAILABLE` | `BATTERY_UNAVAILABLE`.
- `kind`: `headset` / `mouse` pick an icon; anything else gets a battery icon.
- Invalid JSON or a crash shows up in the panel as an error row for that script.
- Same shape as `headsetcontrol -o json`, so its output is a valid reader.

**Custom readers run as you, unsandboxed, like the plugin itself. Only list scripts you trust.**

Built-in readers live in `service/Main.qml`; `bin/wlmouse-battery --test` is the self-test.
