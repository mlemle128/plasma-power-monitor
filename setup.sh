#!/usr/bin/env bash
# Put Power Monitor in the system tray and wire up its right-click.
#
#   - Power Monitor: added to the tray, "Always shown"
#   - stock Power and Battery: kept enabled but "Shown only in popup" (the ^ menu)
#   - stock battery gets a global shortcut if it has none (default
#     Meta+Ctrl+Alt+Shift+B). Plasma only lets one widget open another's popup
#     through that widget's "activate widget N" shortcut, so right-click needs it.
#   - the stock battery's widget ID is stored in Power Monitor's settings
#
# Safe to re-run. plasmashell is restarted twice (the panel flickers), and the
# layout file is backed up first.
set -euo pipefail

F=~/.config/plasma-org.kde.plasma.desktop-appletsrc
ID=io.github.mlemle128.powermonitor
STOCK=org.kde.plasma.battery
SHORTCUT=${SHORTCUT:-Meta+Ctrl+Alt+Shift+B}

die() { echo "$*" >&2; exit 1; }

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

# every plugin= line, for checking nothing else went missing
all_plugins() { grep -E '^plugin=' "$F" | sort; }

# add / remove one entry in a comma-separated tray list (extraItems etc.)
list_add() {
    local v
    v=$(kreadconfig6 --file "$F" "${tray_args[@]}" --group General --key "$1")
    case ",$v," in
        *,"$2",*) ;;
        *) kwriteconfig6 --file "$F" "${tray_args[@]}" --group General --key "$1" "${v:+$v,}$2" ;;
    esac
}
list_del() {
    local v n
    v=$(kreadconfig6 --file "$F" "${tray_args[@]}" --group General --key "$1")
    n=$(tr ',' '\n' <<< "$v" | { grep -vx "$2" || true; } | paste -sd,)
    [ "$n" = "$v" ] || kwriteconfig6 --file "$F" "${tray_args[@]}" --group General --key "$1" "$n"
}

# stopping plasmashell also makes it write out any pending config
restart_plasma() {
    systemctl --user stop plasma-plasmashell.service
    "$@"
    systemctl --user start plasma-plasmashell.service
}

[ -f "$F" ] || die "no Plasma layout file at $F"
tray=$(groups_for org.kde.plasma.systemtray | head -n1)
[ -n "$tray" ] || die "no system tray found on any panel"
mapfile -t tray_args < <(group_args "$tray")

cp "$F" "$F.bak-power-monitor"
echo "backup: $F.bak-power-monitor"
before=$(all_plugins)

# 1. tray entries. plasmashell creates the widgets from these on start.
tray_entries() {
    list_add extraItems "$ID"
    list_add knownItems "$ID"
    list_del hiddenItems "$ID"
    list_add shownItems "$ID"

    list_add extraItems "$STOCK"
    list_add knownItems "$STOCK"
    list_del shownItems "$STOCK"
    list_add hiddenItems "$STOCK"
}
restart_plasma tray_entries
echo "tray: Power Monitor always shown, Power and Battery only in the ^ popup"

# give plasmashell time to create both widgets, then stop it so it saves them
sleep 10
systemctl --user stop plasma-plasmashell.service

stock=$(groups_for "$STOCK" | head -n1)
mapfile -t ours < <(groups_for "$ID")
if [ -z "$stock" ] || [ ${#ours[@]} -eq 0 ]; then
    systemctl --user start plasma-plasmashell.service
    die "plasmashell didn't create the widgets; check the tray, then re-run ./setup.sh"
fi
stock_id=$(grep -oE '[0-9]+\]$' <<< "$stock" | tr -d ']')

# 2. shortcut on the stock battery + its ID in Power Monitor's settings
mapfile -t stock_args < <(group_args "$stock")
existing=$(kreadconfig6 --file "$F" "${stock_args[@]}" --group Shortcuts --key global)
if [ -z "$existing" ]; then
    kwriteconfig6 --file "$F" "${stock_args[@]}" --group Shortcuts --key global "$SHORTCUT"
    echo "shortcut: gave Power and Battery $SHORTCUT"
else
    echo "shortcut: Power and Battery already has $existing"
fi
for g in "${ours[@]}"; do
    mapfile -t our_args < <(group_args "$g")
    kwriteconfig6 --file "$F" "${our_args[@]}" --group Configuration --group General \
        --key stockBatteryWidgetId "$stock_id"
done
echo "right-click: opens Power and Battery (widget $stock_id)"
systemctl --user start plasma-plasmashell.service

# plasma has been seen to reuse another tray item's slot when adding one;
# make sure everything that was there before still is
missing=$(comm -23 <(echo "$before") <(all_plugins) | sed 's/^plugin=//')
if [ -n "$missing" ]; then
    echo
    echo "WARNING: these widgets disappeared from the layout:" >&2
    echo "$missing" | sed 's/^/  /' >&2
    echo "Re-enable them in the tray's Entries settings, or restore $F.bak-power-monitor" >&2
    exit 1
fi
echo "done"
