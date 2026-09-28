# Batteries

Wireless headset and WLMouse battery on the QS Bar: one icon + % per device.
Click for a panel with every device, a charge bar, status, and a refresh icon.

- **Runs:** `bin/batteries` every `pollSec` (default 60s) and when the panel opens.
  It runs every reader script (15s timeout each) and merges their devices.
- **Built-in readers** (`bin/readers/`): `headsetcontrol` (headsets, if installed) and
  `wlmouse` (WLMouse 36a7:a870/a871 over /dev/hidraw; needs a uaccess udev rule for
  vendor 36a7; sends ONE read-only GET-battery feature report, opcode 0x83, the same
  query the WL MOUSE HUB web driver polls; never writes settings).
- **Writes:** only `$XDG_STATE_HOME/ryoku/plugins/headset/bar.json` (which devices the
  bar shows; the panel checkboxes). **Network:** none. **Privileged:** none.

## Custom readers (the contract)

Any executable dropped in **`~/.config/ryoku/batteries.d/`** is a reader: no
settings, no paths to type. It is run with no arguments and no shell every poll,
and must print:

```json
{"devices": [{"device": "Rainy75", "product": "Rainy 75 Keyboard", "kind": "keyboard",
              "battery": {"status": "BATTERY_CHARGING", "level": 62},
              "errors": {"battery": "only when level is -1"}}]}
```

- `battery.level`: 0-100, or -1 when unknown. Everything else is optional.
- `battery.status`: `BATTERY_CHARGING` | `BATTERY_AVAILABLE` | `BATTERY_UNAVAILABLE`.
- `kind`: `headset` / `mouse` pick an icon; anything else gets a battery icon.
- Invalid JSON, a crash, or >15s shows up in the panel as an error row for that script.
- Not executable (`chmod -x`) or a dotfile = disabled.
- Same shape as `headsetcontrol -o json`, so its output is a valid reader.

**Custom readers run as you, unsandboxed, like the plugin itself. Only list scripts you trust.**

Self-tests: `bin/batteries --test`, `bin/readers/wlmouse --test`.
