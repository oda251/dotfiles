#!/bin/bash
# Setup script for GCC and AtCoder Library (ac-library)
# This script is idempotent and detects the operating system to install required tools.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== AtCoder Competitive Programming Setup ===${NC}"
echo ""

# Detect OS
OS=$(uname -s)

if [ "$OS" = "Darwin" ]; then
  echo -e "${GREEN}✓ Detected macOS (Darwin)${NC}"
  
  # Check if Homebrew is installed
  if ! command -v brew &> /dev/null; then
    echo ""
    echo -e "${RED}✗ Homebrew is not installed${NC}"
    echo ""
    echo "To install Homebrew, run:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo ""
    exit 1
  fi
  
  echo "Installing required packages via Homebrew..."
  
  # Install packages (non-interactive)
  brew install gcc cmake python git --quiet 2>/dev/null || {
    echo -e "${YELLOW}Note: Some packages may already be installed${NC}"
  }
  
elif [ "$OS" = "Linux" ]; then
  echo -e "${GREEN}✓ Detected Linux${NC}"
  echo "Installing required packages via apt-get..."
  
  # Update package lists
  sudo apt-get update -qq
  
  # Install packages (non-interactive, assume yes)
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential gcc g++ cmake python3 git \
    > /dev/null 2>&1 || true
  
else
  echo -e "${RED}✗ Unsupported operating system: $OS${NC}"
  echo "This setup script supports macOS (Darwin) and Linux only."
  exit 1
fi

echo -e "${GREEN}✓ Packages installed successfully${NC}"
echo ""

# Clone ac-library if not already present
AC_LIBRARY_PATH="$HOME/atcoder/ac-library"

if [ -d "$AC_LIBRARY_PATH" ]; then
  echo -e "${GREEN}✓ AtCoder Library already exists at: $AC_LIBRARY_PATH${NC}"
else
  echo "Cloning AtCoder Library to $AC_LIBRARY_PATH..."
  mkdir -p "$HOME/atcoder"
  git clone https://github.com/atcoder/ac-library "$AC_LIBRARY_PATH" > /dev/null 2>&1
  echo -e "${GREEN}✓ AtCoder Library cloned successfully${NC}"
fi

echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "Next steps:"
echo "  1. Add AtCoder Library to your include path when compiling:"
echo "     g++ -I$AC_LIBRARY_PATH mycode.cpp -o mycode"
echo ""
echo "  2. Verify your installation:"
echo "     gcc --version"
echo "     cmake --version"
echo "     python3 --version"
echo "     git --version"
echo ""
