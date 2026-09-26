#!/bin/bash

boot_step() {
  local label="$1"
  printf "  %s...%s %s\r" "$C_MUTED" "$C_RESET" "$label"
  sleep 0.08
  printf "  %sOK %s %s%s%s\n" "$C_OK" "$C_RESET" "$C_TEXT" "$label" "$C_RESET"
}

run_boot_animation() {
  clear 2>/dev/null
  printf "%s%scodex-tools%s %sruntime v14%s\n" "$C_BOLD" "$C_ACCENT" "$C_RESET" "$C_MUTED" "$C_RESET"
  echo ""
  boot_step "Registering console identity"
  boot_step "Mounting workspace"
  boot_step "Detecting runtime"
  boot_step "Starting background services"
  boot_step "Finalizing system"
  echo ""
}
