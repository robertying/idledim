#!/bin/zsh
# Dims external display when there is no mouse/keyboard input; restores on activity.
#   after WARN_LIMIT seconds: fade to WARN_FACTOR of the current brightness
# Does not dim while an app blocks display sleep (video, calls), and does not restore over a manual brightness change.
DIR="${0:A:h}"
BIN="$DIR/brightness"
WARN_LIMIT=${WARN_LIMIT:-120}   # seconds
WARN_FACTOR=${WARN_FACTOR:-0.25}

state=0      # 0 = normal, 1 = dimmed
held=0       # 1 = user changed brightness; do not dim again until next activity
saved=0.7
expected=0   # last brightness set by this script

# fade TO SECONDS
fade() {
  expected=$(printf '%.3f' $1)
  "$BIN" "$expected" "$2"
}

blocks_sleep() {
  [[ $(pmset -g assertions | awk '$1 == "PreventUserIdleDisplaySleep" {print $2}') == 1 ]]
}

restore() {
  fade $saved 0.3
  state=0
  echo "$(date '+%F %T') restored $saved"
}

while true; do
  idle=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}')
  (( idle < WARN_LIMIT )) && held=0

  if (( state > 0 )); then
    cur=$("$BIN" 2>/dev/null)
    if [[ -n $cur ]] && (( cur - expected > 0.02 || expected - cur > 0.02 )); then
      state=0; held=1
      echo "$(date '+%F %T') brightness changed manually ($cur), not restoring"
    elif (( idle < WARN_LIMIT )) || blocks_sleep; then
      restore
    fi
  elif (( !held && idle >= WARN_LIMIT )) && ! blocks_sleep; then
    cur=$("$BIN" 2>/dev/null) && saved=$cur
    if [[ -n $cur ]]; then
      warn=$(( saved * WARN_FACTOR ))
      expected=$saved
      fade $warn 1.2
      state=1
      echo "$(date '+%F %T') dimmed to $warn (saved $saved)"
    fi
  fi

  # Poll faster while dimmed so the restore feels immediate.
  if (( state > 0 )); then sleep 0.25; else sleep 2; fi
done
