#!/bin/bash

get_container_uptime() {
  local hz sys_uptime start_ticks start_sec elapsed days hours mins out

  hz=$(getconf CLK_TCK 2>/dev/null || echo 100)
  sys_uptime=$(awk '{print $1}' /proc/uptime 2>/dev/null)
  start_ticks=$(awk '{print $22}' /proc/1/stat 2>/dev/null)

  if [ -z "$sys_uptime" ] || [ -z "$start_ticks" ]; then
    echo "unknown"
    return
  fi

  start_sec=$(awk -v t="$start_ticks" -v h="$hz" 'BEGIN{printf "%d", t/h}')
  elapsed=$(awk -v u="$sys_uptime" -v s="$start_sec" 'BEGIN{printf "%d", u-s}')

  days=$((elapsed / 86400))
  hours=$(((elapsed % 86400) / 3600))
  mins=$(((elapsed % 3600) / 60))

  out=""
  [ "$days" -gt 0 ] && out="${days}d "
  [ "$hours" -gt 0 ] && out="${out}${hours}h "
  out="${out}${mins}m"
  echo "$out"
}

bytes_to_human() {
  awk -v b="$1" 'BEGIN{
    split("B KiB MiB GiB TiB", units, " ")
    i=1
    while (b>=1024 && i<5) { b/=1024; i++ }
    printf "%.1f%s", b, units[i]
  }'
}

get_container_memory() {
  local used_bytes limit_raw limit_str

  if [ -f /sys/fs/cgroup/memory.current ]; then
    used_bytes=$(cat /sys/fs/cgroup/memory.current 2>/dev/null)
  elif [ -f /sys/fs/cgroup/memory/memory.usage_in_bytes ]; then
    used_bytes=$(cat /sys/fs/cgroup/memory/memory.usage_in_bytes 2>/dev/null)
  fi

  if [ -z "$used_bytes" ]; then
    echo "unknown"
    return
  fi

  if [ -n "$SERVER_MEMORY" ] && [ "$SERVER_MEMORY" != "0" ]; then
    limit_str="$(bytes_to_human "$((SERVER_MEMORY * 1024 * 1024))")"
  else
    if [ -f /sys/fs/cgroup/memory.max ]; then
      limit_raw=$(cat /sys/fs/cgroup/memory.max 2>/dev/null)
    elif [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
      limit_raw=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null)
    fi
    if [ "$limit_raw" = "max" ] || [ -z "$limit_raw" ] || [ "$limit_raw" -ge 9000000000000000000 ] 2>/dev/null; then
      limit_str="unlimited"
    else
      limit_str=$(bytes_to_human "$limit_raw")
    fi
  fi

  echo "$(bytes_to_human "$used_bytes") / ${limit_str}"
}

get_memory_percent() {
  local used_bytes limit_bytes

  if [ -f /sys/fs/cgroup/memory.current ]; then
    used_bytes=$(cat /sys/fs/cgroup/memory.current 2>/dev/null)
  elif [ -f /sys/fs/cgroup/memory/memory.usage_in_bytes ]; then
    used_bytes=$(cat /sys/fs/cgroup/memory/memory.usage_in_bytes 2>/dev/null)
  fi
  [ -z "$used_bytes" ] && { echo "-1"; return; }

  if [ -n "$SERVER_MEMORY" ] && [ "$SERVER_MEMORY" != "0" ]; then
    limit_bytes=$((SERVER_MEMORY * 1024 * 1024))
    awk -v u="$used_bytes" -v l="$limit_bytes" 'BEGIN{printf "%d", (u/l)*100}'
  else
    echo "-1"
  fi
}

get_server_address() {
  if [ -n "$SERVER_IP" ] && [ -n "$SERVER_PORT" ]; then
    echo "${SERVER_IP}:${SERVER_PORT}"
  elif [ -n "$SERVER_IP" ]; then
    echo "$SERVER_IP"
  else
    echo "unknown (SERVER_IP tidak di-set oleh Wings)"
  fi
}

get_container_cpu_cores() {
  local quota period

  if [ -f /sys/fs/cgroup/cpu.max ]; then
    read -r quota period < /sys/fs/cgroup/cpu.max
    if [ "$quota" = "max" ]; then
      nproc 2>/dev/null || echo "?"
      return
    fi
  elif [ -f /sys/fs/cgroup/cpu/cpu.cfs_quota_us ]; then
    quota=$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us 2>/dev/null)
    period=$(cat /sys/fs/cgroup/cpu/cpu.cfs_period_us 2>/dev/null)
    if [ "$quota" = "-1" ]; then
      nproc 2>/dev/null || echo "?"
      return
    fi
  else
    nproc 2>/dev/null || echo "?"
    return
  fi

  awk -v q="$quota" -v p="$period" 'BEGIN{printf "%.1f", q/p}'
}

get_browser_path() {
  local engine="$1" dir exe

  dir=$(find /opt/browsers -maxdepth 1 -type d -iname "${engine}-*" 2>/dev/null | head -n1)
  if [ -z "$dir" ]; then
    echo "not found"
    return
  fi

  exe=$(find "$dir" -maxdepth 3 -type f -executable \( -iname "firefox" -o -iname "MiniBrowser" -o -iname "chrome" -o -iname "pw_run.sh" \) 2>/dev/null | head -n1)

  if [ -n "$exe" ]; then
    echo "$exe"
  else
    echo "$dir"
  fi
}
