#!/bin/bash

start_log_rotation() {
  local max_bytes=$((5 * 1024 * 1024)) interval=3600

  (
    while true; do
      sleep "$interval"
      for f in /tmp/*.log; do
        [ -f "$f" ] || continue
        local size
        size=$(stat -c%s "$f" 2>/dev/null || echo 0)
        if [ "$size" -gt "$max_bytes" ]; then
          tail -c "$max_bytes" "$f" > "${f}.tmp" && mv "${f}.tmp" "$f"
        fi
      done
    done
  ) &
  LOG_ROTATOR_PID=$!
  export LOG_ROTATOR_PID
}
