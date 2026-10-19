#!/usr/bin/env bash
# install batt to ~/.local/bin and the Power Monitor widget for the current user,
# then put it in the system tray (setup.sh). --no-setup skips the tray part.
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

if [ "${1:-}" != --no-setup ]; then
    echo
    ./setup.sh
fi
