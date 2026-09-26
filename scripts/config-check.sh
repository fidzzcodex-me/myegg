#!/bin/bash

run_config_check() {
  local warnings=()

  if [ "$ENABLE_WEB_TERMINAL" = "true" ] && [ "${WEB_TERMINAL_PASSWORD:-changeme}" = "changeme" ]; then
    warnings+=("Web Terminal aktif tapi password masih default 'changeme'")
  fi

  if [ "$ENABLE_CF_TUNNEL" = "true" ] && [ -z "$CF_TOKEN" ]; then
    warnings+=("Cloudflare Tunnel aktif tapi CF_TOKEN kosong, tunnel tidak akan jalan")
  fi

  if [ "$HEADLESS_MODE" = "false" ] && ! command -v xvfb-run >/dev/null 2>&1; then
    warnings+=("HEADLESS_MODE=false tapi xvfb-run tidak ditemukan di image")
  fi

  if [ -z "$SERVER_IP" ]; then
    warnings+=("SERVER_IP tidak tersedia dari Wings, alamat server di banner mungkin tidak akurat")
  fi

  if [ "$ENABLE_TELEGRAM_BACKUP" = "true" ] && { [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; }; then
    warnings+=("Backup to Telegram aktif tapi Bot Token/Chat ID belum lengkap")
  fi

  if [ "$STATIC_HOST_MODE" = "true" ] && [ -n "$STARTUP_CMD" ]; then
    warnings+=("Static Host Mode aktif, STARTUP_CMD diabaikan")
  fi

  if [ "$STATIC_HOST_MODE" != "true" ] && [ -z "$STARTUP_CMD" ]; then
    warnings+=("STARTUP_CMD kosong dan Static Host Mode nonaktif, server bakal drop ke shell")
  fi

  case "$NODE_VERSION" in 22|24|26|'') ;; *) warnings+=("NODE_VERSION=${NODE_VERSION} di luar versi yang di-cache image (22/24/26), bakal didownload manual saat start") ;; esac
  case "$PYTHON_VERSION" in 3.12|3.13|3.14|'') ;; *) warnings+=("PYTHON_VERSION=${PYTHON_VERSION} di luar versi yang di-bundle image (3.12/3.13/3.14)") ;; esac
  case "$PHP_VERSION" in 8.2|8.3|8.4|8.5|'') ;; *) warnings+=("PHP_VERSION=${PHP_VERSION} di luar versi yang di-bundle image (8.2-8.5)") ;; esac

  if [ "${#warnings[@]}" -eq 0 ]; then
    return 0
  fi

  ui_section "Config Warnings"
  local w
  for w in "${warnings[@]}"; do
    ui_warn "$w"
  done
}
