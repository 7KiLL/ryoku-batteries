# Batteries

Peripheral batteries on the QS Bar: one icon + % per device. Click for a panel
with every device, a charge bar, and checkboxes for which devices the bar shows.

Works out of the box with **UPower** (Bluetooth headphones, Logitech HID++ mice
and keyboards, gamepads, ...) and **headsetcontrol** (Logitech/SteelSeries/
Corsair/HyperX headsets). Anything else: point it at your own command.

## Settings

QS Bar Settings > Community > Batteries (global):

| Setting | Default |
| --- | --- |
| Show percentage | on |
| Hide devices that are off | off |
| Low battery warning (%) | 15 |
| Poll interval (seconds) | 60 |
| Readers config (JSON) | `~/.config/ryoku-batteries/readers.json` |

Per-reader options live in that JSON file. Click the pencil in the panel to
create it from a template (only if it doesn't exist) and open it in your editor.
No file = the built-ins (`upower`, `headsetcontrol`). Saving it applies at once.

## readers.json

```json
{
  "$schema": "file:///home/you/.local/share/ryoku/plugins/batteries/schema/readers.schema.json",
  "version": 1,
  "readers": [
    { "id": "upower",         "builtin": "upower" },
    { "id": "headsetcontrol", "builtin": "headsetcontrol" },
    { "id": "kbd", "cmd": ["~/.config/ryoku-batteries/readers/rainy75"],
      "label": "Rainy 75", "kind": "keyboard", "interval": 300, "timeout": 5 }
  ]
}
```

The `$schema` line gives completion and validation in VS Code, Neovim (jsonls),
Zed and Helix. Per reader:

| Field | Meaning |
| --- | --- |
| `id` | unique name (also keys bar visibility, so renaming resets it) |
| `builtin` | `upower` or `headsetcontrol` — exactly one of `builtin` / `cmd` |
| `cmd` | argv of your own reader, run **without a shell**; leading `~` expanded |
| `enabled` | `false` skips it (default `true`) |
| `interval` | seconds between runs, `0` = every poll (default) |
| `timeout` | seconds before it's killed and shown as an error (default 10) |
| `label` | display name (when the reader reports one device) |
| `kind` | `mouse` `headset` `keyboard` `gamepad` `phone` `tablet` picks the icon |
| `icon` | any Nerd Font glyph, overrides the kind's icon |

A broken config, an unknown builtin, a crashing or slow reader: each shows up
in the panel as an error row saying why, instead of silently disappearing.

## Writing a reader

Any executable that prints, on stdout, headsetcontrol's JSON shape:

```json
{"api_version": "1",
 "devices": [{"product": "Rainy 75", "kind": "keyboard",
              "battery": {"status": "BATTERY_CHARGING", "level": 62},
              "errors": {"battery": "only when level is -1"}}]}
```

- `battery.level`: 0-100, or -1 when unknown. Everything else is optional.
- `battery.status`: `BATTERY_CHARGING` | `BATTERY_AVAILABLE` | `BATTERY_UNAVAILABLE`.
- `headsetcontrol -o json -b` output is itself a valid reader.

## What it runs, reads and writes

- **Runs:** `bin/batteries` every poll and when the panel opens; it runs the
  enabled readers in parallel: the built-ins (`bin/readers/upower` calls
  `upower -e`/`-i`; `bin/readers/headsetcontrol` calls `headsetcontrol -o json -b`)
  and **any `cmd` you list in readers.json, as you, unsandboxed. Only list
  commands you trust.** The pencil runs `xdg-open` on the config file.
- **Reads:** readers.json (path from the setting).
- **Writes:** `$XDG_STATE_HOME/ryoku/plugins/batteries/` (`bar.json`: bar
  visibility; `cache.json`: last results for `interval`). Creates readers.json
  from the template **only** when you click the pencil and the file is missing;
  never modifies an existing one.
- **Network:** none. **Privileged:** none.

Self-tests: `bin/batteries --test`, `bin/readers/upower --test`.
