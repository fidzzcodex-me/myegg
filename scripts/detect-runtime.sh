#!/bin/bash

setup_runtime_paths() {
  export NVM_DIR="/usr/local/nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

  if [ -n "$NODE_VERSION" ] && command -v nvm >/dev/null 2>&1; then
    if nvm ls "$NODE_VERSION" >/dev/null 2>&1; then
      nvm use "$NODE_VERSION" >/dev/null 2>&1
    else
      ui_warn "Node ${NODE_VERSION} belum ada di cache image, downloading (cuma sekali)..."
      nvm install "$NODE_VERSION" >/tmp/nvm-install.log 2>&1
      nvm use "$NODE_VERSION" >/dev/null 2>&1
    fi
  fi

  if [ -n "$PYTHON_VERSION" ] && command -v "python$PYTHON_VERSION" >/dev/null 2>&1; then
    update-alternatives --set python3 "/usr/bin/python$PYTHON_VERSION" >/dev/null 2>&1
  fi

  if [ -n "$PHP_VERSION" ] && command -v "php$PHP_VERSION" >/dev/null 2>&1; then
    update-alternatives --set php "/usr/bin/php$PHP_VERSION" >/dev/null 2>&1
  fi

  export PATH="/usr/local/go/bin:${CARGO_HOME:-/usr/local/cargo}/bin:${BUN_INSTALL:-/usr/local/bun}/bin:${PATH}"
  export GOCACHE="/home/container/.cache/go-build"
  mkdir -p "$GOCACHE" 2>/dev/null
}

resolve_package_manager() {
  case "$INSTALL_DEPS" in
    npm|pnpm|yarn|bun)
      echo "$INSTALL_DEPS"
      return
      ;;
  esac

  if [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
    echo "bun"
  elif [ -f "pnpm-lock.yaml" ]; then
    echo "pnpm"
  elif [ -f "yarn.lock" ]; then
    echo "yarn"
  else
    echo "npm"
  fi
}

detect_and_setup_runtime() {
  local cmd="$STARTUP_CMD"
  DETECTED_RUNTIME="Unknown"

  if [ "$SKIP_DEPS_INSTALL" = "true" ]; then
    ui_info "SKIP_DEPS_INSTALL=true -> lewati semua install dependency"
  fi

  case "$cmd" in
    *bun\ * | bun*)
      DETECTED_RUNTIME="Bun"
      if [ -f "package.json" ] && [ "$SKIP_DEPS_INSTALL" != "true" ]; then
        bun install
      fi
      ;;

    *node\ * | node* | *npm\ * | npm* | *npx\ * | *pnpm\ * | pnpm* | *yarn\ * | yarn*)
      DETECTED_RUNTIME="Node.js"
      if [ -f "package.json" ] && [ "$SKIP_DEPS_INSTALL" != "true" ]; then
        local lockfile current_hash="" prev_hash="" lock_hash_file=".codex-lock-hash" manager
        for lockfile in package-lock.json pnpm-lock.yaml yarn.lock bun.lockb bun.lock; do
          [ -f "$lockfile" ] && current_hash="${current_hash}$(md5sum "$lockfile" 2>/dev/null)"
        done
        [ -z "$current_hash" ] && current_hash="$(md5sum package.json 2>/dev/null)"

        [ -f "$lock_hash_file" ] && prev_hash="$(cat "$lock_hash_file" 2>/dev/null)"

        if [ -d "node_modules" ] && [ "$current_hash" = "$prev_hash" ]; then
          ui_ok "node_modules sudah lengkap dan lockfile tidak berubah, skip install"
        else
          manager=$(resolve_package_manager)
          ui_info "package manager -> ${manager}"
          case "$manager" in
            pnpm) pnpm install ;;
            yarn) yarn install ;;
            bun)  bun install ;;
            *)    [ -f "package-lock.json" ] && npm ci || npm install ;;
          esac
          echo "$current_hash" > "$lock_hash_file"
        fi
      fi
      ;;

    *python3\ * | python3* | *python\ * | python*)
      DETECTED_RUNTIME="Python"
      if [ -f "requirements.txt" ] && [ "$SKIP_DEPS_INSTALL" != "true" ]; then
        pip install --break-system-packages -r requirements.txt
      fi
      ;;

    *php\ * | php* | *artisan\ *)
      DETECTED_RUNTIME="PHP"
      if [ -f "composer.json" ] && [ "$SKIP_DEPS_INSTALL" != "true" ]; then
        composer install --no-interaction
      fi
      ;;

    *go\ run\ * | *go\ build\ * | go\ * | ./app_bin* | ./main*)
      DETECTED_RUNTIME="Go"
      if [ -f "go.mod" ] && [ "$SKIP_DEPS_INSTALL" != "true" ]; then
        go mod download
        if [ "$AUTO_BUILD" = "true" ] && [[ "$cmd" == ./* ]]; then
          go build -o app_bin .
        fi
      fi
      ;;

    *cargo\ run* | *cargo\ * | ./target/*)
      DETECTED_RUNTIME="Rust"
      if [ -f "Cargo.toml" ] && [ "$AUTO_BUILD" = "true" ] && [ "$SKIP_DEPS_INSTALL" != "true" ] && [[ "$cmd" == ./target/* ]]; then
        cargo build --release
      fi
      ;;

    *g++\ * | *gcc\ *)
      DETECTED_RUNTIME="C/C++"
      ;;
  esac

  export DETECTED_RUNTIME
}
