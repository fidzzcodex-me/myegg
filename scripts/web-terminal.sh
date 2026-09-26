#!/bin/bash

start_web_terminal() {
  [ "$ENABLE_WEB_TERMINAL" != "true" ] && return 0
  local port="${WEB_TERMINAL_PORT:-7681}" user="${WEB_TERMINAL_USER:-admin}" pass="${WEB_TERMINAL_PASSWORD:-changeme}"

  if [ "$pass" = "changeme" ]; then
    ui_warn "WEB_TERMINAL_PASSWORD masih default 'changeme', ganti sebelum expose ke publik"
  fi

  ttyd -p "$port" -c "${user}:${pass}" -W bash >/tmp/ttyd.log 2>&1 &
  WEB_TERMINAL_PID=$!
  export WEB_TERMINAL_PID
}
