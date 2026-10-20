# mbp-lid-down

Keep this MacBook Pro responsive when the lid is closed.

Started 2026-10-20. Machine: MacBookPro16,1 (2019 16", i9, 64 GB, 4 TB), built-in
display only, dual-booting macOS and Fedora (t2linux). On macOS, closing the lid with
no external display puts the Mac to sleep at once, so SSH, the Sunday network audit,
the fortnightly Homebrew job and the weekly SMSF report all stall until the lid opens.

## Goal

With the lid down and the Mac on mains power:

- scheduled launchd jobs (Sunday network audit, fortnightly brew, weekly SMSF
  report) run on time,
- it still sleeps normally on battery, so it never cooks in a bag.

Decided 2026-10-20: **jobs only**. Remote Login (SSH) stays OFF; the user does not
need to reach the Mac from another device while it is closed, and an SSH listener
is one more thing on the LAN to defend.

## What macOS offers (facts, 2026-10-20)

Baseline capture: `baseline/pmset-2026-10-20.txt` and `baseline/disk-layout-2026-10-20.txt`.

Also found on 2026-10-20: Fedora is installed on `disk0s4` (2 TB Linux filesystem), and Remote Login is OFF (nothing listening on port 22) — must be turned on in System Settings > General > Sharing before lid-closed SSH can work.

| Setting | Now | Meaning |
|---|---|---|
| `womp` | 1 | Wake on LAN is on |
| `tcpkeepalive` | 1 | Keeps TCP sessions alive in sleep (Power Nap style) |
| `ttyskeepawake` | 1 | An active SSH login holds off idle sleep |
| `lidwake` | 1 | Opening the lid wakes it |
| `disablesleep` | not set | The only switch that stops lid-close sleep without an external display |

Apple's supported "clamshell mode" needs an external display plus a keyboard or
mouse. Without one, the choices are (SSH-only options dropped):

1. **`pmset disablesleep 1`**. Lid close no longer sleeps the Mac. CORRECTION
   2026-10-20: this setting is **system-wide**. macOS stores it under
   `SystemPowerSettings`, not per power source, so `pmset -c` does NOT make it
   AC-only (verified in `/Library/Preferences/com.apple.PowerManagement.plist`).
   On its own it would keep the Mac awake in a bag on battery. Hence the guard
   below. Side effects while on AC: no sleep at all, not even from the Apple menu,
   and warmer fans with the lid down, so leave it on a hard surface.
2. **`caffeinate`** per job. Already used by the brew and SMSF LaunchAgents, but it
   cannot stop lid-close sleep, only idle sleep. Not sufficient on its own.
3. **Third-party** (Amphetamine with its closed-display trick, or a plugged-in
   HDMI dummy plug to fake an external display). The dummy plug is the cheapest
   hardware route and keeps Apple's own sleep logic intact.
4. **Schedule wakes**: `pmset repeat wakeorpoweron` can bring it up for a job, but
   it goes back to sleep after, and no SSH in between.

Chosen: option 1 plus a guard. Files in this repo:

- `liddown status|on|off` — user command; `on`/`off` need `sudo` in a Terminal.
- `liddown-guard.sh` — runs as root every 60 s via the LaunchDaemon
  `com.rstuklis.liddown`; sets `disablesleep` 1 on AC, 0 on battery, and if the
  lid is already closed when it re-enables sleep, sleeps the Mac at once. A
  stand-down flag from `liddown off` forces 0. Logs to `/Library/Logs/liddown.log`.
- `install-guard.sh` — `sudo ./install-guard.sh` copies the guard to a root-owned
  path and loads the daemon; `--uninstall` reverses it.

Gap to know: unplug with the lid closed and it can stay awake for up to 60 s
before the guard sleeps it. Option 4 (scheduled wakes plus each job's own
`caffeinate`) remains the fallback if this proves too blunt.

## Fedora side

When booted into Fedora the equivalent is `HandleLidSwitch=ignore` (and
`HandleLidSwitchExternalPower=ignore`) in `/etc/systemd/logind.conf`, plus
`sudo systemctl restart systemd-logind`. Worth doing the same on both OSes so the
behaviour matches whichever one is running.

## Status

- [x] Baseline captured (power settings, disk layout)
- [x] Remote Login: decided to leave it OFF (jobs only)
- [x] Decided: `disablesleep` + guard that limits it to AC (`liddown on`)
- [x] `liddown`, `liddown-guard.sh`, LaunchDaemon plist, `install-guard.sh` written
- [x] `sudo ./liddown on` run 2026-10-20: `SleepDisabled 1` confirmed (system-wide!)
- [x] `sudo ./install-guard.sh` run 2026-10-20 ~11:35, daemon running
- [x] Verified 2026-10-20: unplugged, guard set SleepDisabled 0 within a minute (log entry); plug-in half: see below
- [x] Verified 2026-10-20 11:40: plugged in, guard set SleepDisabled back to 1 (log entry)
- [ ] Verify: plug in, close lid, wait past the next scheduled job, check its log
- [ ] Fedora logind change

Nothing in this folder has changed any system setting yet.
