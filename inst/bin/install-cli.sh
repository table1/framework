#!/usr/bin/env bash
# Framework CLI Installer
#
# This script installs the Framework R package and CLI tool in one command.
# Usage: curl -fsSL https://raw.githubusercontent.com/table1/framework/main/inst/bin/install-cli.sh | bash

set -e

BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

BIN_DIR="$HOME/.local/bin"
CLI_NAME="framework"

printf "${BLUE}════════════════════════════════════════════════════${NC}\n"
printf "${BLUE}  Framework Installation${NC}\n"
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

CLI_SOURCE="$PACKAGE_DIR/bin/framework"

if [ ! -f "$CLI_SOURCE" ]; then
  printf "${RED}Error: CLI script not found at $CLI_SOURCE${NC}\n"
  exit 1
fi

# Create bin directory if it doesn't exist
mkdir -p "$BIN_DIR"

# Create symlink
TARGET="$BIN_DIR/$CLI_NAME"
if [ -L "$TARGET" ] || [ -f "$TARGET" ]; then
  rm -f "$TARGET"
fi

ln -s "$CLI_SOURCE" "$TARGET"
chmod +x "$TARGET"

printf "${GREEN}✓ CLI installed to $TARGET${NC}\n\n"

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
    EXPORT_LINE='export PATH="$HOME/.local/bin:$PATH"'
    ;;
  bash)
    SHELL_CONFIG="$HOME/.bashrc"
    EXPORT_LINE='export PATH="$HOME/.local/bin:$PATH"'
    ;;
  fish)
    SHELL_CONFIG="$HOME/.config/fish/config.fish"
    EXPORT_LINE='set -gx PATH $HOME/.local/bin $PATH'
    ;;
  *)
    SHELL_CONFIG="$HOME/.profile"
    EXPORT_LINE='export PATH="$HOME/.local/bin:$PATH"'
    ;;
esac

# Check if already in config (exact match for .local/bin)
if [ -f "$SHELL_CONFIG" ] && grep -qE '\.local/bin|/\.local/bin|\$HOME/\.local/bin' "$SHELL_CONFIG"; then
  printf "${YELLOW}Note:${NC} ~/.local/bin is already in ${SHELL_CONFIG}\n"
  printf "but is not active in this session.\n\n"
  printf "To activate:\n"
  printf "  1. Restart your terminal, or\n"
  printf "  2. Run: ${BLUE}source ${SHELL_CONFIG}${NC}\n\n"
  printf "Then try: ${BLUE}framework new myproject${NC}\n"
  exit 0
fi

# Offer to add
printf "Add to ${SHELL_CONFIG}? [y/N]: "
read -r response </dev/tty

case "$response" in
  [yY][eE][sS]|[yY])
    printf "\n# Added by Framework CLI installer\n%s\n" "$EXPORT_LINE" >> "$SHELL_CONFIG"
    printf "\n${GREEN}✓ Added to ${SHELL_CONFIG}${NC}\n\n"
    printf "To activate:\n"
    printf "  1. Restart your terminal (recommended), or\n"
    printf "  2. Run: ${BLUE}source ${SHELL_CONFIG}${NC}\n\n"
    printf "Then try: ${BLUE}framework new myproject${NC}\n"
    ;;
  *)
    printf "\nTo add manually, add this line to ${SHELL_CONFIG}:\n"
    printf "  ${BLUE}%s${NC}\n\n" "$EXPORT_LINE"
    printf "Then restart your terminal or run: ${BLUE}source ${SHELL_CONFIG}${NC}\n"
    ;;
esac
