# idledim

Dims your external display when you stop using the Mac, and fades it back when you return.

- After 2 minutes without mouse or keyboard input, the display fades to 25% of its current brightness.
- On any activity it fades back to where it was (0.3s).
- It does not dim while an app is holding the display awake (video, calls).
- If you change the brightness yourself while dimmed, it leaves your setting alone.

It only touches external displays; the built-in panel is left to macOS.

## Requirements

- macOS with the Xcode Command Line Tools (`xcode-select --install`), for `swiftc`
- An external display that macOS can control the brightness of (the same displays that respond to the brightness keys)

## Install

```sh
git clone https://github.com/robertying/idledim.git && cd idledim
./install.sh
```

This compiles the `brightness` helper, writes a LaunchAgent to `~/Library/LaunchAgents/`, and starts it. It runs at every login. Logs go to `/tmp/idledim.log`.

## Configure

Settings are environment variables in the `EnvironmentVariables` block that `install.sh` writes to the plist (edit `install.sh` and rerun it, or edit the plist and reload):

| Variable | Default | Meaning |
|---|---|---|
| `WARN_LIMIT` | `120` | Seconds idle before dimming |
| `WARN_FACTOR` | `0.25` | Dimmed brightness as a fraction of current brightness |

The fade durations are in `idledim.sh` (`fade $warn 1.2` to dim, `fade $saved 0.3` to restore).

To apply a change to an installed copy:

```sh
./install.sh
```

## Uninstall

```sh
launchctl bootout gui/$(id -u)/io.ruiying.idledim && rm ~/Library/LaunchAgents/io.ruiying.idledim.plist
```

If the display is dimmed at that moment it stays dimmed; set it back with `./brightness 1` or the brightness keys.

## The `brightness` tool

`brightness.swift` is a small standalone CLI:

```sh
./brightness          # print current brightness (0.0-1.0) of the first external display
./brightness 0.3      # set all external displays to 0.3
./brightness 0.3 1.5  # fade to 0.3 over 1.5 seconds
```

## Caveats

- It uses `DisplayServicesSetBrightness` from Apple's private `DisplayServices` framework. It is not a public API and could change or break in a future macOS release.
- Tested on one setup (macOS on Apple Silicon, one external display). Other monitors, docks and adapters may not report or accept brightness changes. If `./brightness` prints "no external display" or "set failed", idledim cannot control that display.
- Idle time comes from `ioreg` (`HIDIdleTime`) and the video/call check from `pmset -g assertions`, polled every 2s (every 0.25s while dimmed).
- If idledim is killed or crashes while dimmed, the display stays dimmed until you change it.
- This is not the screen saver or display sleep. Set those in System Settings as usual; idledim just adds an earlier, gentler step.

## License

MIT
