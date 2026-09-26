#!/bin/bash

C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_ACCENT=$'\033[38;2;97;175;239m'
C_OK=$'\033[38;2;152;195;121m'
C_WARN=$'\033[38;2;229;192;123m'
C_ERR=$'\033[38;2;224;108;117m'
C_MUTED=$'\033[38;2;120;126;140m'
C_TEXT=$'\033[38;2;220;223;228m'

LABEL_WIDTH=13
VALUE_MAX=38

_ui_truncate() {
  local str="$1" max="$2" len=${#1}
  if [ "$len" -le "$max" ]; then
    printf '%s' "$str"
  else
    printf '%s…' "${str:0:$((max - 1))}"
  fi
}

_ui_pad() {
  local str="$1" width="$2" pad=$((${2} - ${#1}))
  [ "$pad" -lt 0 ] && pad=0
  printf '%s%*s' "$str" "$pad" ""
}

ui_section() {
  local title="$1" rule
  rule=$(printf '─%.0s' $(seq 1 ${#title}))
  echo ""
  printf "%s%s%s%s\n" "$C_BOLD" "$C_ACCENT" "$title" "$C_RESET"
  printf "%s%s%s\n" "$C_MUTED" "$rule" "$C_RESET"
}

ui_row() {
  local label value
  label=$(_ui_pad "$(_ui_truncate "$1" "$LABEL_WIDTH")" "$LABEL_WIDTH")
  value=$(_ui_truncate "$2" "$VALUE_MAX")
  printf "  %s%s%s %s%s%s\n" "$C_MUTED" "$label" "$C_RESET" "$C_TEXT" "$value" "$C_RESET"
}

ui_ok() {
  printf "  %s%-4s%s %s\n" "$C_OK" "OK" "$C_RESET" "$1"
}

ui_warn() {
  printf "  %s%-4s%s %s\n" "$C_WARN" "WARN" "$C_RESET" "$1"
}

ui_err() {
  printf "  %s%-4s%s %s\n" "$C_ERR" "ERR" "$C_RESET" "$1"
}

ui_info() {
  printf "  %s%-4s%s %s\n" "$C_MUTED" "INFO" "$C_RESET" "$1"
}

ui_check_ver() {
  local name="$1" ok="$2" ver="$3" label
  label=$(_ui_pad "$(_ui_truncate "$name" 11)" 11)
  if [ "$ok" = "true" ]; then
    printf "  %s%s%s %sOK%s   %s%s%s\n" "$C_TEXT" "$label" "$C_RESET" "$C_OK" "$C_RESET" "$C_MUTED" "$ver" "$C_RESET"
  else
    printf "  %s%s%s %s—%s    %snot installed%s\n" "$C_MUTED" "$label" "$C_RESET" "$C_MUTED" "$C_RESET" "$C_MUTED" "$C_RESET"
  fi
}
