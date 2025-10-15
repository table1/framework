#!/usr/bin/env bash
# Bash completion for Framework CLI
#
# Installation:
#   # For bash
#   sudo cp framework-completion.bash /etc/bash_completion.d/framework
#
#   # Or for user-level installation
#   mkdir -p ~/.local/share/bash-completion/completions
#   cp framework-completion.bash ~/.local/share/bash-completion/completions/framework
#
# Usage:
#   After installation, restart your shell or run: source ~/.bashrc

_framework_completion() {
  local cur prev words cword
  _init_completion || return

  # Get current word being completed
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  # Check if we're in a Framework project (has config.yml)
  local in_project=false
  if [ -f "config.yml" ] || [ -f "../config.yml" ] || [ -f "../../config.yml" ]; then
    in_project=true
  fi

  # First argument - show appropriate commands
  if [ "$COMP_CWORD" -eq 1 ]; then
    if [ "$in_project" = true ]; then
      # Inside project - show project-local commands
      COMPREPLY=( $(compgen -W "scaffold notebook nb status help" -- "$cur") )
    else
      # Outside project - show global commands
      COMPREPLY=( $(compgen -W "new version update self-update help" -- "$cur") )
    fi
    return 0
  fi

  # Second argument
  if [ "$COMP_CWORD" -eq 2 ]; then
    case "$prev" in
      new)
        # Project name - no completion
        return 0
        ;;
      notebook|nb)
        # Notebook name - no completion
        return 0
        ;;
      *)
        return 0
        ;;
    esac
  fi

  # Third argument
  if [ "$COMP_CWORD" -eq 3 ]; then
    case "${COMP_WORDS[1]}" in
      new)
        # Project type
        COMPREPLY=( $(compgen -W "project course presentation" -- "$cur") )
        return 0
        ;;
      notebook|nb)
        # Notebook format
        COMPREPLY=( $(compgen -W "quarto rmarkdown" -- "$cur") )
        return 0
        ;;
      *)
        return 0
        ;;
    esac
  fi

  return 0
}

# Register completion function
complete -F _framework_completion framework
