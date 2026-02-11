#!/bin/bash

set -euo pipefail

OS=$(uname -s)

if [ "$OS" = "Darwin" ]; then
  command -v brew >/dev/null 2>&1 || exit 1
  for pkg in gcc cmake git; do
    brew list "$pkg" >/dev/null 2>&1 || brew install "$pkg" --quiet
  done
elif [ "$OS" = "Linux" ]; then
  if ! dpkg -s build-essential cmake git >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential cmake git >/dev/null 2>&1
  fi
else
  exit 1
fi

AC_LIBRARY_PATH="$HOME/atcoder/ac-library"
if [ ! -d "$AC_LIBRARY_PATH" ]; then
  mkdir -p "$HOME/atcoder"
  git clone https://github.com/atcoder/ac-library "$AC_LIBRARY_PATH" > /dev/null 2>&1
else
  cd "$AC_LIBRARY_PATH" && git pull > /dev/null 2>&1
fi
