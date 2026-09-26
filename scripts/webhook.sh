#!/bin/bash

send_webhook_notification() {
  local event="${1:-start}" ip time payload
  [ -z "$WEBHOOK_URL" ] && return 0

  ip=$(hostname -I 2>/dev/null | awk '{print $1}')
  time=$(date '+%Y-%m-%d %H:%M:%S')

  if [ -n "$WEBHOOK_PAYLOAD" ]; then
    payload="$WEBHOOK_PAYLOAD"
    payload="${payload//\{event\}/$event}"
    payload="${payload//\{server\}/${HOSTNAME:-server}}"
    payload="${payload//\{ip\}/$ip}"
    payload="${payload//\{time\}/$time}"
  else
    payload=$(cat <<JSON
{"content": "Server ${HOSTNAME:-container} ${event} at ${time} (${ip})"}
JSON
)
  fi

  curl -s --max-time 5 -X POST -H "Content-Type: application/json" -d "$payload" "$WEBHOOK_URL" >/dev/null 2>&1
}
