#!/bin/bash

send_backup_to_telegram() {
  local file="$1" size_mb
  [ "$ENABLE_TELEGRAM_BACKUP" != "true" ] && return 0
  [ -z "$TELEGRAM_BOT_TOKEN" ] && return 0
  [ -z "$TELEGRAM_CHAT_ID" ] && return 0

  size_mb=$(( $(stat -c%s "$file" 2>/dev/null || echo 0) / 1024 / 1024 ))

  if [ "$size_mb" -gt 49 ]; then
    ui_warn "backup ${size_mb}MB melebihi limit Telegram Bot API (50MB), skip upload"
    return 1
  fi

  curl -s -o /tmp/telegram-backup.log -F "chat_id=${TELEGRAM_CHAT_ID}" \
    -F "document=@${file}" \
    -F "caption=Codex Tools backup: $(basename "$file")" \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendDocument"

  if grep -q '"ok":true' /tmp/telegram-backup.log 2>/dev/null; then
    ui_ok "backup terkirim ke Telegram: $(basename "$file")"
  else
    ui_err "gagal kirim backup ke Telegram, cek TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID"
  fi
}

run_backup_once() {
  local backup_dir="/home/container/.codex/backups" stamp target keep human_size

  mkdir -p "$backup_dir"
  stamp=$(date '+%Y%m%d-%H%M%S')
  target="${backup_dir}/backup-${stamp}.tar.gz"
  keep="${BACKUP_KEEP_COUNT:-5}"
  case "$keep" in ''|*[!0-9]*) keep=5 ;; esac

  tar --exclude="./.codex/backups" -czf "$target" -C /home/container . 2>/dev/null
  human_size=$(bytes_to_human "$(stat -c%s "$target" 2>/dev/null || echo 0)")
  ui_ok "backup dibuat: $(basename "$target") (${human_size})"

  ls -1t "$backup_dir"/backup-*.tar.gz 2>/dev/null | tail -n "+$((keep + 1))" | xargs -r rm -f

  send_backup_to_telegram "$target"
}

start_auto_backup() {
  [ "$ENABLE_AUTO_BACKUP" != "true" ] && return 0
  local interval_hours="${BACKUP_INTERVAL_HOURS:-24}"

  (
    while true; do
      sleep "$((interval_hours * 3600))"
      run_backup_once
    done
  ) &
  BACKUP_TICKER_PID=$!
  export BACKUP_TICKER_PID
}
