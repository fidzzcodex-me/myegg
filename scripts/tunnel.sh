#!/bin/bash

start_cf_tunnel() {
  [ "$ENABLE_CF_TUNNEL" != "true" ] && return 0
  if [ -z "$CF_TOKEN" ]; then
    ui_warn "ENABLE_CF_TUNNEL=true tapi CF_TOKEN kosong, tunnel tidak dijalankan"
    return 0
  fi
  cloudflared tunnel run --token "$CF_TOKEN" >/tmp/cloudflared.log 2>&1 &
  CF_TUNNEL_PID=$!
  export CF_TUNNEL_PID
}
