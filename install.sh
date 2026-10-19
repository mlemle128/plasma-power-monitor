#!/usr/bin/env bash
# install batt to ~/.local/bin and the Power Monitor widget for the current user
set -euo pipefail
cd "$(dirname "$0")"

ID=io.github.mlemle128.powermonitor

install -Dm755 batt ~/.local/bin/batt
echo "installed ~/.local/bin/batt"

if kpackagetool6 -t Plasma/Applet --list | grep -qx "$ID"; then
    kpackagetool6 -t Plasma/Applet --upgrade "plasmoid/$ID"
else
    kpackagetool6 -t Plasma/Applet --install "plasmoid/$ID"
fi

cat <<'MSG'

Next:
  1. Right-click the system tray ^ > Configure System Tray > Entries,
     set "Power Monitor" to "Always shown" (and optionally the stock
     "Power and Battery" to "Shown when relevant" / "Always hidden").
  2. Run ./setup-right-click.sh so right-click opens the stock battery popup.
MSG
