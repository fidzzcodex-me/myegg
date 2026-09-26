#!/bin/bash

cron_field_match() {
  local field="$1" value="$2" part base lo hi step

  IFS=',' read -ra parts <<< "$field"
  for part in "${parts[@]}"; do
    if [ "$part" = "*" ]; then
      return 0
    elif [[ "$part" == */* ]]; then
      step="${part#*/}"
      base="${part%/*}"
      case "$step" in ''|*[!0-9]*) continue ;; esac
      if [ "$base" = "*" ]; then
        [ "$((value % step))" -eq 0 ] && return 0
      elif [[ "$base" == *-* ]]; then
        lo="${base%-*}"; hi="${base#*-}"
        case "$lo$hi" in *[!0-9]*) continue ;; esac
        if [ "$value" -ge "$lo" ] && [ "$value" -le "$hi" ] && [ "$(((value - lo) % step))" -eq 0 ]; then
          return 0
        fi
      fi
    elif [[ "$part" == *-* ]]; then
      lo="${part%-*}"; hi="${part#*-}"
      case "$lo$hi" in *[!0-9]*) continue ;; esac
      [ "$value" -ge "$lo" ] && [ "$value" -le "$hi" ] && return 0
    else
      [ "$part" = "$value" ] && return 0
    fi
  done
  return 1
}

start_cron_runner() {
  [ -z "$CRON_JOBS" ] && return 0

  (
    local last_minute=""
    while true; do
      local now_min now_hour now_dom now_mon now_dow current_stamp
      now_min=$(date +%-M)
      now_hour=$(date +%-H)
      now_dom=$(date +%-d)
      now_mon=$(date +%-m)
      now_dow=$(date +%w)
      current_stamp="${now_hour}:${now_min}"

      if [ "$current_stamp" != "$last_minute" ]; then
        last_minute="$current_stamp"

        while IFS= read -r line; do
          [ -z "$line" ] && continue
          [[ "$line" == \#* ]] && continue

          local min hour dom mon dow cmd
          read -r min hour dom mon dow cmd <<< "$line"
          [ -z "$cmd" ] && continue

          if cron_field_match "$min" "$now_min" && \
             cron_field_match "$hour" "$now_hour" && \
             cron_field_match "$dom" "$now_dom" && \
             cron_field_match "$mon" "$now_mon" && \
             cron_field_match "$dow" "$now_dow"; then
            ui_info "cron -> ${cmd}"
            eval "$cmd" >> /tmp/cron-runner.log 2>&1 &
          fi
        done <<< "$CRON_JOBS"
      fi

      sleep 20
    done
  ) &
  CRON_RUNNER_PID=$!
  export CRON_RUNNER_PID
}
