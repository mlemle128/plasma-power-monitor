# plasma-power-monitor

Per-battery charging info for dual-battery laptops (ThinkPad T480 and
friends) on Linux, as a terminal command and a KDE Plasma 6 tray widget.

The stock Plasma battery applet shows one combined percentage. When you
have an internal and a rear battery, that hides the useful bits: which
one is charging, how fast, and whether one has silently stopped
reporting.

![Power Monitor in the system tray](docs/tray.png)

## `batt`

```
$ batt
AC: plugged in    22:10:38

BAT   STATUS          CHG          ENERGY    POWER    VOLT  HEALTH  CYCLE  THRESH ETA
BAT0  Not charging    64%  15.39/23.94Wh    0.00W  11.46V    100%      3  96-100 waiting turn
BAT1  Charging        23%  16.58/71.04Wh   28.52W  11.22V    100%      5  96-100 1h54m to 100%

Total battery power: 28.52W
```

| Command | |
|---|---|
| `batt` | table once |
| `batt -w [s]` | live view, refresh every `s` seconds (default 5) |
| `batt --panel` | one line: `INT: 64% · EXT: ▲ 23% · 28.5W` |
| `batt --raw` | one line per battery: `name status capacity energy_now energy_full power_now` (µWh/µW) |

The ETA column explains "Not charging": ThinkPads charge one battery at
a time (`waiting turn`), and charge thresholds stop a battery from
starting until it drops below the start threshold (`waits until <40%`).

Reads everything from `/sys/class/power_supply`; no root needed.

## Power Monitor widget

A tray icon showing the combined charge, plus a readout popup:

| Click | Does |
|---|---|
| Left | show / hide the `INT · EXT · W` readout above the icon. It stays up until you click again, and is remembered across logins |
| Middle | switch the popup to the full `batt` table |
| Right | open the stock *Power and Battery* popup (power profiles, brightness, sleep inhibit) |
| Double right | the normal widget menu (Configure…, Remove) |

Settings (double right-click → *Configure Power Monitor…*): refresh
interval, battery labels, arrows / watts on or off, the stock battery
widget ID, and the path to `batt`.

### Install

Needs Plasma 6, `kpackagetool6`, `qdbus6`.

```
git clone https://github.com/mlemle128/plasma-power-monitor
cd plasma-power-monitor
./install.sh
```

That installs `batt` and the widget, then runs `setup.sh`, which sets up
the tray with no clicking:

- **Power Monitor** is added to the tray and set to *Always shown*.
- The stock **Power and Battery** stays enabled but is set to *Shown only
  in popup*, so it lives in the ^ menu.
- Power and Battery gets the global shortcut `Meta+Ctrl+Alt+Shift+B`
  if it has none (override with `SHORTCUT=...`), and its widget ID is
  stored in Power Monitor's settings so right-click can open it.

Why the shortcut: Plasma has no way for one widget to open another's
popup except through that widget's global *activate widget N* shortcut.

`setup.sh` restarts plasmashell (the panel flickers a couple of times),
backs up `~/.config/plasma-org.kde.plasma.desktop-appletsrc` first, and
afterwards checks no other tray item went missing. It's safe to re-run,
and you need to after removing Power Monitor from the tray and adding it
back, since that resets its settings. Use `./install.sh --no-setup` to
install without touching the tray.

Until setup has run, right-click shows a menu with just *Configure
Power Monitor…*.

### Notes

- The tray sorts icons alphabetically by name within a category, which
  is why the widget is called *Power Monitor*: it lands right after
  *Networks*, next to the ^.
- `BAT0` is labelled INT and any other battery EXT; both labels are
  configurable.
- Tested on a ThinkPad T480 (internal + rear battery), Arch Linux,
  Plasma 6.7.

## License

MIT
