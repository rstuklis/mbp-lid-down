#!/bin/zsh
# liddown-guard.sh — run by the root LaunchDaemon com.rstuklis.liddown every 60 s.
# Keeps `pmset disablesleep` equal to 1 on AC power and 0 on battery, because the
# setting itself is system-wide. If it has just re-enabled sleep while the lid is
# already closed, it puts the Mac to sleep immediately. A stand-down flag
# (/usr/local/etc/liddown.disabled, made by `liddown off`) forces 0 always.
FLAG=/usr/local/etc/liddown.disabled
LOG=/Library/Logs/liddown.log
src=$(pmset -g batt | sed -n "s/.*'\(.*\)'.*/\1/p")
cur=$(pmset -g | awk '/SleepDisabled/{print $2}'); cur=${cur:-0}
if [[ -e $FLAG || $src != "AC Power" ]]; then want=0; else want=1; fi
[[ $cur == $want ]] && exit 0
pmset -a disablesleep $want
print -- "$(date '+%F %T') power='$src' flag=$([[ -e $FLAG ]] && echo yes || echo no) SleepDisabled $cur -> $want" >> "$LOG"
if [[ $want == 0 ]]; then
  lid=$(ioreg -r -k AppleClamshellState -d 4 2>/dev/null | awk -F'= ' '/AppleClamshellState/{print $2; exit}')
  if [[ $lid == Yes ]]; then print -- "$(date '+%F %T') lid closed on battery: sleeping now" >> "$LOG"; pmset sleepnow; fi
fi
