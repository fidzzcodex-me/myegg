#!/bin/bash

setup_identity() {
  export USER="root"
  export HOME="/home/container"
  export TERM="xterm-256color"

  local prompt='\[\033[1m\033[38;2;97;175;239m\]codex\[\033[0m\]\[\033[38;2;120;126;140m\]:\[\033[0m\]\[\033[38;2;220;223;228m\]\w\[\033[0m\]\[\033[38;2;120;126;140m\]\$\[\033[0m\] '

  export PS1="$prompt"
  export CODEX_PS1="$prompt"
}
