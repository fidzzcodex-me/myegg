#!/bin/bash

print_banner() {
  local cpu_cores ram_str disk_used disk_total

  cpu_cores=$(get_container_cpu_cores)
  ram_str=$(get_container_memory)
  disk_used=$(df -h /home/container 2>/dev/null | awk 'NR==2 {print $3}')
  disk_total=$(df -h /home/container 2>/dev/null | awk 'NR==2 {print $2}')

  ui_section "Console"
  ui_row "CPU" "${cpu_cores} cores"
  ui_row "RAM" "$ram_str"
  ui_row "Disk" "${disk_used} / ${disk_total}"
}

print_runtime_status() {
  local node_ver python_ver php_ver bun_ver go_ver rust_ver gcc_ver gpp_ver

  ui_section "Runtime"

  if command -v node >/dev/null 2>&1; then
    node_ver=$(node -v 2>/dev/null)
    ui_check_ver "Node.js" "true" "$node_ver"
  else
    ui_check_ver "Node.js" "false" ""
  fi

  if command -v bun >/dev/null 2>&1; then
    bun_ver=$(bun --version 2>/dev/null)
    ui_check_ver "Bun" "true" "v${bun_ver}"
  else
    ui_check_ver "Bun" "false" ""
  fi

  if command -v python3 >/dev/null 2>&1; then
    python_ver=$(python3 --version 2>/dev/null | awk '{print $2}')
    ui_check_ver "Python" "true" "v${python_ver}"
  else
    ui_check_ver "Python" "false" ""
  fi

  if command -v php >/dev/null 2>&1; then
    php_ver=$(php -v 2>/dev/null | head -n1 | awk '{print $2}')
    ui_check_ver "PHP" "true" "v${php_ver}"
  else
    ui_check_ver "PHP" "false" ""
  fi

  if command -v go >/dev/null 2>&1; then
    go_ver=$(go version 2>/dev/null | awk '{print $3}' | sed 's/^go/v/')
    ui_check_ver "Go" "true" "$go_ver"
  else
    ui_check_ver "Go" "false" ""
  fi

  if command -v rustc >/dev/null 2>&1; then
    rust_ver=$(rustc --version 2>/dev/null | awk '{print $2}')
    ui_check_ver "Rust" "true" "v${rust_ver}"
  else
    ui_check_ver "Rust" "false" ""
  fi

  if command -v gcc >/dev/null 2>&1; then
    gcc_ver=$(gcc -dumpversion 2>/dev/null)
    ui_check_ver "C" "true" "gcc ${gcc_ver}"
  else
    ui_check_ver "C" "false" ""
  fi

  if command -v g++ >/dev/null 2>&1; then
    gpp_ver=$(g++ -dumpversion 2>/dev/null)
    ui_check_ver "C++" "true" "g++ ${gpp_ver}"
  else
    ui_check_ver "C++" "false" ""
  fi
}

print_access_info() {
  local port="${APP_PORT:-3000}" addr tunnel_id

  addr=$(get_server_address)

  ui_section "Access"
  ui_ok "App       http://${SERVER_IP:-$addr}:${port}"

  if [ "$ENABLE_CF_TUNNEL" = "true" ]; then
    tunnel_id=$(grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' /tmp/cloudflared.log 2>/dev/null | head -n1)
    [ -n "$tunnel_id" ] && ui_info "Tunnel    ${tunnel_id}.cfargotunnel.com"
  fi

  if [ "$ENABLE_WEB_TERMINAL" = "true" ]; then
    ui_info "Terminal  http://${SERVER_IP:-$addr}:${WEB_TERMINAL_PORT:-7681}"
  fi

  if [ -n "$DETECTED_RUNTIME" ] && [ "$DETECTED_RUNTIME" != "Unknown" ]; then
    ui_ok "Runtime terdeteksi: ${DETECTED_RUNTIME}"
  fi
}
