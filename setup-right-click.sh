#!/usr/bin/env bash
# Make right-click on Power Monitor open the stock "Power and Battery" popup.
#
# Plasma only lets one widget open another through that widget's global
# "activate widget N" shortcut, so this:
#   - finds the stock battery widget (org.kde.plasma.battery) and its ID
#   - gives it a global shortcut if it has none (default Meta+Ctrl+Alt+Shift+B)
#   - stores the ID in every Power Monitor instance's settings
#   - with --hide-stock, also moves the stock battery icon into the tray's ^ menu
#
# plasmashell is restarted (the panel flickers briefly). A backup of the
# layout file is written next to it first.
set -euo pipefail

F=~/.config/plasma-org.kde.plasma.desktop-appletsrc
ID=io.github.mlemle128.powermonitor
SHORTCUT=${SHORTCUT:-Meta+Ctrl+Alt+Shift+B}
HIDE_STOCK=0
[ "${1:-}" = --hide-stock ] && HIDE_STOCK=1

# print "[A][B][C]..." group headers whose plugin= matches $1
groups_for() {
    awk -v plugin="$1" '
        /^\[/ { group = $0; next }
        $0 == "plugin=" plugin && group != "" { print group }
    ' "$F"
}

# "[Containments][2][Applets][7]" -> --group Containments --group 2 ...
group_args() {
    sed -E 's/^\[//; s/\]$//; s/\]\[/\n/g' <<< "$1" | while read -r g; do
        printf -- '--group\n%s\n' "$g"
    done
}

stock=$(groups_for org.kde.plasma.battery | head -n1)
[ -n "$stock" ] || { echo "no stock battery widget (org.kde.plasma.battery) found in $F" >&2; exit 1; }
stock_id=$(grep -oE '[0-9]+\]$' <<< "$stock" | tr -d ']')

mapfile -t ours < <(groups_for "$ID")
[ ${#ours[@]} -gt 0 ] || { echo "Power Monitor isn't on a panel or in the tray yet; add it first" >&2; exit 1; }

echo "stock battery widget: $stock_id"
cp "$F" "$F.bak-power-monitor"
echo "backup: $F.bak-power-monitor"

systemctl --user stop plasma-plasmashell.service

mapfile -t sg < <(group_args "$stock")
existing=$(kreadconfig6 --file "$F" "${sg[@]}" --group Shortcuts --key global)
if [ -z "$existing" ]; then
    kwriteconfig6 --file "$F" "${sg[@]}" --group Shortcuts --key global "$SHORTCUT"
    echo "gave it the global shortcut $SHORTCUT"
else
    echo "it already has the global shortcut $existing"
fi

for g in "${ours[@]}"; do
    mapfile -t og < <(group_args "$g")
    kwriteconfig6 --file "$F" "${og[@]}" --group Configuration --group General \
        --key stockBatteryWidgetId "$stock_id"
done

if [ $HIDE_STOCK = 1 ]; then
    # the tray's own config group is the stock widget's grandparent
    tray=$(sed -E 's/\[Applets\]\[[0-9]+\]$//' <<< "$stock")
    mapfile -t tg < <(group_args "$tray")
    hidden=$(kreadconfig6 --file "$F" "${tg[@]}" --group General --key hiddenItems)
    case ",$hidden," in
        *,org.kde.plasma.battery,*) ;;
        *) kwriteconfig6 --file "$F" "${tg[@]}" --group General --key hiddenItems \
               "${hidden:+$hidden,}org.kde.plasma.battery"
           echo "moved the stock battery icon into the tray's ^ menu" ;;
    esac
fi

systemctl --user start plasma-plasmashell.service
echo "done"
