#!/bin/bash

start_live_stats_ticker() {
  local interval="${LIVE_STATS_INTERVAL:-30}"
  [ "$interval" = "0" ] && return 0

  (
    while true; do
      sleep "$interval"
      local uptime_str ram_str disk_used disk_total mem_pct line
      uptime_str=$(get_container_uptime)
      ram_str=$(get_container_memory)
      disk_used=$(df -h /home/container 2>/dev/null | awk 'NR==2 {print $3}')
      disk_total=$(df -h /home/container 2>/dev/null | awk 'NR==2 {print $2}')
      mem_pct=$(get_memory_percent)

      line="uptime=${uptime_str} ram=${ram_str} disk=${disk_used}/${disk_total}"
      if [ "$mem_pct" -ge 90 ] 2>/dev/null; then
        printf "  %s%s%s %s%s%s\n" "$C_MUTED" "live" "$C_RESET" "$C_WARN" "${line} (RAM ${mem_pct}%)" "$C_RESET"
      else
        printf "  %s%s%s %s%s%s\n" "$C_MUTED" "live" "$C_RESET" "$C_MUTED" "$line" "$C_RESET"
      fi
    done
  ) &
  LIVE_STATS_PID=$!
  export LIVE_STATS_PID
}
