#!/bin/bash

set -euo pipefail

OS=$(uname -s)

if [ "$OS" = "Darwin" ]; then
  if ! command -v brew &> /dev/null; then
    exit 1
  fi
  brew install gcc cmake git --quiet
elif [ "$OS" = "Linux" ]; then
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential cmake git > /dev/null 2>&1
else
  exit 1
fi

AC_LIBRARY_PATH="$HOME/atcoder/ac-library"
if [ ! -d "$AC_LIBRARY_PATH" ]; then
  mkdir -p "$HOME/atcoder"
  git clone https://github.com/atcoder/ac-library "$AC_LIBRARY_PATH" > /dev/null 2>&1
fi
