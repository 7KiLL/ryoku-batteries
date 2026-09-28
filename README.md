# Headset

Shows wireless headset battery on the QS Bar. Click the glyph for a panel with
every detected device, a charge bar, and a refresh button.

- **Runs:** `headsetcontrol -o json -b` (every `pollSec`, default 60s, and when the panel opens).
- **Reads:** the headset over hidraw, via headsetcontrol (needs its udev rule, shipped by the package).
- **Writes:** nothing. **Network:** none. **Privileged:** none.

Requires `headsetcontrol` (AUR). Tested on Logitech G PRO X Wireless.
Supported devices: `headsetcontrol --help` / upstream README.
