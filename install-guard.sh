#!/bin/zsh
# install-guard.sh — run with sudo from this folder. Copies the guard to a
# root-owned path (so a user process cannot edit what root runs) and loads the
# LaunchDaemon. Re-run after editing liddown-guard.sh. `--uninstall` removes it.
set -e
cd "$(dirname "$0")"
[[ $EUID -eq 0 ]] || { echo "run: sudo ./install-guard.sh"; exit 1; }
if [[ $1 == --uninstall ]]; then
  launchctl bootout system/com.rstuklis.liddown 2>/dev/null || true
  rm -f /Library/LaunchDaemons/com.rstuklis.liddown.plist /usr/local/libexec/liddown-guard.sh
  pmset -a disablesleep 0; echo "guard removed, sleep back to normal"; exit 0
fi
install -d -o root -g wheel -m 755 /usr/local/libexec
# /usr/local/etc belongs to Homebrew and is owned by the user. Create it only if it
# is missing and never re-own it: `install -d` on an existing directory resets its
# owner and mode, which broke every `brew upgrade` from 20 Oct 2026 until fixed.
[[ -d /usr/local/etc ]] || install -d -m 755 /usr/local/etc
install -o root -g wheel -m 755 liddown-guard.sh /usr/local/libexec/liddown-guard.sh
install -o root -g wheel -m 644 com.rstuklis.liddown.plist /Library/LaunchDaemons/com.rstuklis.liddown.plist
launchctl bootout system/com.rstuklis.liddown 2>/dev/null || true
launchctl bootstrap system /Library/LaunchDaemons/com.rstuklis.liddown.plist
launchctl print system/com.rstuklis.liddown | grep -E "state|last exit"
echo "guard installed; it runs now and every 60 s. Log: /Library/Logs/liddown.log"
