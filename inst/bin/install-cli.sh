#!/usr/bin/env bash
# Framework CLI Installer
#
# This script installs the Framework R package and CLI tool with hybrid routing.
#
# Installs:
#   - Global shim: ~/.local/bin/framework (searches for local bin/framework)
#   - Global implementation: ~/.local/bin/framework-global (fallback handler)
#
# Usage: curl -fsSL https://raw.githubusercontent.com/table1/framework/main/inst/bin/install-cli.sh | bash

set -e

BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

BIN_DIR="$HOME/.local/bin"

printf "${BLUE}════════════════════════════════════════════════════${NC}\n"
printf "${BLUE}  Framework CLI Installation${NC}\n"
printf "${BLUE}════════════════════════════════════════════════════${NC}\n\n"

# Check if R package is installed
PACKAGE_DIR=$(Rscript --quiet --no-save -e "cat(system.file(package='framework'))" 2>/dev/null || echo "")

if [ -z "$PACKAGE_DIR" ] || [ "$PACKAGE_DIR" = "" ]; then
  printf "${YELLOW}Installing Framework R package from GitHub...${NC}\n\n"

  # Install the R package
  R --quiet --no-save <<'RCODE'
if (!requireNamespace('devtools', quietly = TRUE)) {
  install.packages('devtools', repos = 'https://cloud.r-project.org')
}
devtools::install_github('table1/framework', quiet = TRUE)
RCODE

  printf "\n${GREEN}✓ Framework package installed${NC}\n\n"

  # Re-detect package directory
  PACKAGE_DIR=$(Rscript --quiet --no-save -e "cat(system.file(package='framework'))")
else
  printf "${GREEN}Framework package already installed${NC}\n\n"
fi

# Verify source files exist
SHIM_SOURCE="$PACKAGE_DIR/bin/framework-shim"
GLOBAL_SOURCE="$PACKAGE_DIR/bin/framework-global"

if [ ! -f "$SHIM_SOURCE" ]; then
  printf "${RED}Error: Shim script not found at $SHIM_SOURCE${NC}\n"
  exit 1
fi

if [ ! -f "$GLOBAL_SOURCE" ]; then
  printf "${RED}Error: Global CLI script not found at $GLOBAL_SOURCE${NC}\n"
  exit 1
fi

# Create bin directory if it doesn't exist
mkdir -p "$BIN_DIR"

# Install framework shim (the main entry point)
SHIM_TARGET="$BIN_DIR/framework"
if [ -L "$SHIM_TARGET" ] || [ -f "$SHIM_TARGET" ]; then
  rm -f "$SHIM_TARGET"
fi
ln -s "$SHIM_SOURCE" "$SHIM_TARGET"
chmod +x "$SHIM_TARGET"

printf "${GREEN}✓ Framework shim installed to $SHIM_TARGET${NC}\n"

# Install framework-global (fallback implementation)
GLOBAL_TARGET="$BIN_DIR/framework-global"
if [ -L "$GLOBAL_TARGET" ] || [ -f "$GLOBAL_TARGET" ]; then
  rm -f "$GLOBAL_TARGET"
fi
ln -s "$GLOBAL_SOURCE" "$GLOBAL_TARGET"
chmod +x "$GLOBAL_TARGET"

printf "${GREEN}✓ Framework global installed to $GLOBAL_TARGET${NC}\n\n"

# Explain the hybrid pattern
printf "${BLUE}Hybrid CLI Pattern:${NC}\n"
printf "  • Inside projects: Uses project-local ${GREEN}bin/framework${NC}\n"
printf "  • Outside projects: Uses global ${GREEN}framework-global${NC}\n"
printf "  • Single command: ${GREEN}framework${NC} routes automatically\n\n"

# Check if already in PATH
if [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
  printf "CLI is ready to use!\n\n"
  printf "Try: ${BLUE}framework new myproject${NC}\n"
  exit 0
fi

# Not in PATH - offer to add it
printf "The CLI needs ${BLUE}~/.local/bin${NC} in your PATH.\n\n"

# Detect shell
SHELL_NAME=$(basename "$SHELL")
case "$SHELL_NAME" in
  zsh)
    SHELL_CONFIG="$HOME/.zshrc"
    ;;
  bash)
    SHELL_CONFIG="$HOME/.bashrc"
    ;;
  fish)
    SHELL_CONFIG="$HOME/.config/fish/config.fish"
    ;;
  *)
    SHELL_CONFIG="$HOME/.profile"
    ;;
esac

# Check if PATH already includes .local/bin in shell config
if [ -f "$SHELL_CONFIG" ] && grep -q "\.local/bin" "$SHELL_CONFIG"; then
  printf "${GREEN}✓ PATH already configured in ${SHELL_CONFIG}${NC}\n"
  printf "  (not active in this session)\n\n"
  printf "${YELLOW}To activate now:${NC}\n"
  printf "  ${BLUE}source ${SHELL_CONFIG}${NC}\n\n"
  printf "Or restart your terminal, then try: ${BLUE}framework new myproject${NC}\n"
  exit 0
fi

# First time setup
printf "${YELLOW}Setup PATH automatically?${NC}\n"
printf "  Framework needs ${BLUE}~/.local/bin${NC} in your PATH to work from anywhere.\n"
printf "  This will add one line to ${BLUE}${SHELL_CONFIG}${NC}\n\n"
printf "Add to PATH? [Y/n]: "

read -r response </dev/tty

case "$response" in
  [nN][oO]|[nN])
    printf "\n${YELLOW}Skipping PATH setup${NC}\n\n"
    printf "To add manually later, add to ${BLUE}${SHELL_CONFIG}${NC}:\n"
    if [ "$SHELL_NAME" = "fish" ]; then
      printf "  ${BLUE}set -gx PATH \$HOME/.local/bin \$PATH${NC}\n\n"
    else
      printf "  ${BLUE}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}\n\n"
    fi
    printf "Then restart your terminal or run: ${BLUE}source ${SHELL_CONFIG}${NC}\n"
    ;;
  *)
    # Add PATH to shell config
    if [ "$SHELL_NAME" = "fish" ]; then
      printf "\n# Added by Framework CLI installer ($(date +%Y-%m-%d))\n" >> "$SHELL_CONFIG"
      printf "set -gx PATH \$HOME/.local/bin \$PATH\n" >> "$SHELL_CONFIG"
    else
      printf "\n# Added by Framework CLI installer ($(date +%Y-%m-%d))\n" >> "$SHELL_CONFIG"
      printf 'export PATH="$HOME/.local/bin:$PATH"\n' >> "$SHELL_CONFIG"
    fi
    printf "\n${GREEN}✓ Updated ${SHELL_CONFIG}${NC}\n\n"

    printf "${YELLOW}To activate now:${NC}\n"
    printf "  ${BLUE}source ${SHELL_CONFIG}${NC}\n\n"
    printf "Or restart your terminal, then try: ${BLUE}framework new myproject${NC}\n"
    ;;
esac
