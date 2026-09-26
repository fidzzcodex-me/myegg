#!/bin/bash

echo "[boot] entrypoint.sh started, pid $$"

CD_TRIES=0
until cd /home/container 2>/tmp/cd-error.log; do
  CD_TRIES=$((CD_TRIES + 1))
  if [ "$CD_TRIES" -ge 10 ]; then
    echo "[boot] FATAL: /home/container tidak bisa diakses setelah ${CD_TRIES}x percobaan"
    cat /tmp/cd-error.log 2>/dev/null
    exit 1
  fi
  echo "[boot] /home/container belum siap, retry ${CD_TRIES}/10..."
  sleep 1
done
echo "[boot] /home/container siap, lanjut init"

SCRIPTS_TO_LOAD="theme identity sysinfo config-check banner boot-animation live-stats log-rotate detect-runtime webhook backup web-terminal tunnel git-setup cron-runner"

for s in $SCRIPTS_TO_LOAD; do
  if [ ! -f "/scripts/${s}.sh" ]; then
    echo "[boot] FATAL: /scripts/${s}.sh tidak ditemukan di image"
    exit 1
  fi
  if ! source "/scripts/${s}.sh"; then
    echo "[boot] FATAL: gagal source /scripts/${s}.sh (kemungkinan file corrupt/CRLF)"
    exit 1
  fi
done
echo "[boot] semua script berhasil di-load"

APP_PID=""

graceful_shutdown() {
  ui_warn "Menerima sinyal stop, mematikan dengan rapi..."
  send_webhook_notification stop
  if [ "$ENABLE_AUTO_BACKUP" = "true" ] && [ "$ENABLE_BACKUP_ON_STOP" = "true" ]; then
    run_backup_once
  fi
  if [ -n "$APP_PID" ] && kill -0 "$APP_PID" 2>/dev/null; then
    kill -TERM "$APP_PID" 2>/dev/null
    wait "$APP_PID" 2>/dev/null
  fi
  exit 0
}
trap graceful_shutdown SIGTERM SIGINT

setup_identity
run_boot_animation

setup_git_repo

setup_runtime_paths
detect_and_setup_runtime

CHROME_BIN=$(find /opt/browsers -maxdepth 3 -type f -name "chrome" 2>/dev/null | head -n1)
if [ -n "$CHROME_BIN" ]; then
  export PUPPETEER_EXECUTABLE_PATH="$CHROME_BIN"
  export CHROME_PATH="$CHROME_BIN"
fi

start_web_terminal
start_cf_tunnel
start_auto_backup
send_webhook_notification start &
start_cron_runner

run_config_check
print_banner
print_runtime_status
start_live_stats_ticker
start_log_rotation

export HEADLESS_MODE="${HEADLESS_MODE:-true}"

FINAL_CMD="$STARTUP_CMD"
USE_SUPERVISOR="false"

if [ "$STATIC_HOST_MODE" = "true" ]; then
  STATIC_DIR="${STATIC_HOST_DIR:-public}"
  mkdir -p "/home/container/${STATIC_DIR}"
  FINAL_CMD="python3 -m http.server ${APP_PORT:-3000} --directory ${STATIC_DIR} --bind 0.0.0.0"
  ui_ok "static-host: serving ./${STATIC_DIR} on port ${APP_PORT:-3000}"
elif [ "$PROCESS_MANAGER" = "true" ] && [[ "$STARTUP_CMD" == node\ * ]]; then
  FINAL_CMD="pm2-runtime ${STARTUP_CMD#node }"
elif [ "$PROCESS_MANAGER" = "true" ] && [ -n "$STARTUP_CMD" ]; then
  USE_SUPERVISOR="true"
fi

if [ -z "$FINAL_CMD" ]; then
  ui_warn "No STARTUP_CMD set. Dropping into shell."
  exec /bin/bash
fi

print_access_info

ui_section "Startup Sequence"

if [ "$PROCESS_MANAGER" != "true" ]; then
  ui_row "Proc. Manager" "off"
elif [[ "$STARTUP_CMD" == node\ * ]]; then
  ui_row "Proc. Manager" "PM2 (Node)"
else
  ui_row "Proc. Manager" "Supervisor"
fi
ui_row "Chromium" "${PUPPETEER_EXECUTABLE_PATH:-not found}"
ui_row "Firefox" "$(get_browser_path firefox)"
ui_row "WebKit" "$(get_browser_path webkit)"
ui_row "Camoufox" "$([ -d /opt/camoufox-cache ] && echo "ready" || echo "not baked")"

XVFB_PREFIX=""
if [ "$HEADLESS_MODE" = "false" ]; then
  if ! command -v xvfb-run >/dev/null 2>&1; then
    ui_err "HEADLESS_MODE=false tapi binary xvfb-run tidak ditemukan"
    ui_info "PATH: ${PATH}"
    ui_info "Image belum ter-rebuild dengan paket xvfb - reinstall/rebuild server"
  else
    XVFB_PREFIX="xvfb-run -a --server-args=-screen\ 0\ 1280x1024x24\ -ac "
    ui_ok "HEADLESS_MODE=false -> Xvfb virtual display aktif"
  fi
else
  ui_info "HEADLESS_MODE=true -> jalan tanpa Xvfb"
fi

EXEC_CMD="${XVFB_PREFIX}${FINAL_CMD}"
ui_row "Exec" "$EXEC_CMD"

if [ "$USE_SUPERVISOR" = "true" ]; then
  ui_ok "Supervisor crash-recovery aktif untuk: ${FINAL_CMD}"
  cat > /tmp/supervisord.conf << SUPERVISOR_EOF
[supervisord]
nodaemon=true
logfile=/tmp/supervisord.log
pidfile=/tmp/supervisord.pid

[program:app]
command=/bin/bash -lc '${EXEC_CMD}'
directory=/home/container
autostart=true
autorestart=true
startretries=999
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
SUPERVISOR_EOF
  supervisord -c /tmp/supervisord.conf &
  APP_PID=$!
else
  /bin/bash -lc "$EXEC_CMD" &
  APP_PID=$!
fi

wait "$APP_PID"
EXIT_CODE=$?
send_webhook_notification stop
exit "$EXIT_CODE"
