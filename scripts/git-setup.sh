#!/bin/bash

setup_git_repo() {
  git config --global --add safe.directory /home/container >/dev/null 2>&1

  [ "$USER_UPLOAD" = "true" ] && return 0
  [ -z "$GIT_ADDRESS" ] && return 0

  local repo_url="$GIT_ADDRESS" branch_flag=""
  if [ -n "$USERNAME" ] && [ -n "$ACCESS_TOKEN" ]; then
    repo_url=$(echo "$GIT_ADDRESS" | sed "s#https://#https://${USERNAME}:${ACCESS_TOKEN}@#")
  fi

  if [ ! -d ".git" ]; then
    ui_info "git clone ${GIT_ADDRESS}"
    [ -n "$BRANCH" ] && branch_flag="-b $BRANCH"
    git clone --depth 1 $branch_flag "$repo_url" temp_clone 2>&1 | grep -v "$ACCESS_TOKEN"
    if [ -d "temp_clone" ]; then
      shopt -s dotglob
      mv temp_clone/* . 2>/dev/null
      rm -rf temp_clone
      shopt -u dotglob
      git config --global --add safe.directory /home/container >/dev/null 2>&1
    fi
  elif [ "$AUTO_UPDATE" = "true" ]; then
    ui_info "git pull"
    git pull 2>&1 | grep -v "$ACCESS_TOKEN"
  fi
}
