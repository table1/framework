# Hybrid CLI Pattern - Implementation Guide

## Overview

The Framework CLI now uses a **hybrid pattern** that automatically routes commands based on your location:

- **Inside a project**: Uses project-local `bin/framework` (project-specific commands)
- **Outside a project**: Uses global `framework-global` (project creation, updates)
- **Single command**: Users always type `framework` - routing is automatic

This provides the best of both worlds: global project creation tools and project-specific workflows.

## Architecture

### Components

1. **Global Shim** (`~/.local/bin/framework`)
   - Main entry point users call
   - Searches upward from `$PWD` for local `bin/framework`
   - Falls back to `framework-global` if not in a project
   - Portable across macOS, Linux, WSL

2. **Global Implementation** (`~/.local/bin/framework-global`)
   - Handles project creation (`framework new`)
   - Package management (`framework version`, `framework update`)
   - Called by shim when outside projects

3. **Project-Local Launcher** (`bin/framework` in each project)
   - Project-specific commands (`scaffold`, `notebook`, `status`)
   - Safe to check into version control
   - Minimal - delegates to R package functions

### Routing Logic

```
framework [command]
    ↓
Global Shim searches upward for bin/framework
    ↓
┌─────────────┬─────────────┐
│ FOUND       │ NOT FOUND   │
│ In Project  │ Outside     │
└─────────────┴─────────────┘
      ↓              ↓
   bin/framework  framework-global
   (local commands) (global commands)
```

## Installation

### For Users

**Method 1: Shell installer (recommended)**
```bash
curl -fsSL https://raw.githubusercontent.com/table1/framework/main/inst/bin/install-cli.sh | bash
```

**Method 2: From R**
```r
framework::cli_install()
```

Both install:
- `~/.local/bin/framework` (shim)
- `~/.local/bin/framework-global` (implementation)
- `~/.frameworkrc` (configuration file, managed by Framework)
- One source line in your shell config (`~/.zshrc`, `~/.bashrc`, etc.)

### Why ~/.frameworkrc?

Framework uses a dedicated configuration file instead of directly modifying your shell config. Benefits:

- **Clean shell config** - Only one line in your `.zshrc`/`.bashrc`: `[ -f ~/.frameworkrc ] && source ~/.frameworkrc`
- **Framework-managed** - We can update PATH and other settings without touching your shell config
- **Easy uninstall** - Delete one file and one line
- **Generated configs** - Perfect for users with programmatically-generated shell configs
- **Shell-agnostic** - Same pattern works for bash, zsh, fish (with `.frameworkrc.fish`)

### For Developers

After modifying CLI scripts:

1. Reinstall package: `R CMD INSTALL .`
2. Reinstall CLI: `R -e "framework::cli_install(use_installer = FALSE)"`
3. Test both contexts:
   ```bash
   # Outside project
   cd /tmp && framework version

   # Inside project
   cd myproject && framework status
   ```

## Commands

### Global Commands (Outside Projects)

```bash
framework new [name] [type]    # Create new project
framework version              # Show Framework version
framework update               # Update from GitHub
framework self-update          # Alias for update
framework help                 # Show help
```

### Project-Local Commands (Inside Projects)

```bash
framework scaffold             # Initialize project environment
framework notebook [name]      # Create new notebook
framework status               # Show project status
framework help                 # Show project-specific help
```

## Files Modified

### Framework Package

- `inst/bin/framework-shim` - **NEW**: Global shim with upward search
- `inst/bin/framework-global` - **RENAMED** from `framework`: Global implementation
- `inst/bin/install-cli.sh` - **UPDATED**: Installs both shim and global
- `inst/bin/framework-completion.bash` - **NEW**: Bash completion
- `R/install_cli.R` - **UPDATED**: Installs hybrid pattern

### Framework-Project Template

- `bin/framework` - **NEW**: Project-local launcher

## Bash Completion

Install completion for command suggestions:

```bash
# System-wide
sudo cp ~/.local/share/R/arm64/4.4/library/framework/bin/framework-completion.bash \
  /etc/bash_completion.d/framework

# User-level
mkdir -p ~/.local/share/bash-completion/completions
cp ~/.local/share/R/arm64/4.4/library/framework/bin/framework-completion.bash \
  ~/.local/share/bash-completion/completions/framework
```

## Testing

Comprehensive test coverage:

1. ✅ Global shim finds local bin/framework when inside project
2. ✅ Global shim falls back to framework-global outside project
3. ✅ Project-local commands work (scaffold, notebook, status)
4. ✅ Global commands work (new, version, update)
5. ✅ Automatic git commit after first scaffold()
6. ✅ Portable across macOS (tested) and Linux (compatible)

## Benefits

**For Users:**
- Single `framework` command - no mental model of "which command do I use?"
- Project-aware - commands adapt to context automatically
- Consistent experience whether in or out of projects

**For Developers:**
- Easy to extend with project-specific commands
- Clean separation of global vs local concerns
- Safe to version control project-local scripts

**For the Ecosystem:**
- Follows common CLI patterns (cargo, npm, git)
- Portable across platforms
- Minimal dependencies (just bash, R)

## Implementation Notes

### Portability

The shim handles platform differences:

- **macOS**: Uses `readlink -f` (via GNU coreutils) or `realpath`
- **Linux**: Uses `readlink -f` (native)
- **WSL**: Uses `readlink -f` (native)
- **Fallback**: Manual symlink resolution if neither available

### Error Handling

- No `set -e` in shim - graceful error messages
- Clear error when neither local nor global found
- Helpful hints for installation

### Self-Update

```bash
framework update     # or framework self-update
```

Updates:
1. Framework R package from GitHub
2. CLI scripts (via symlinks to installed package)
3. All dependencies (optional)

## Future Enhancements

Potential additions (not yet implemented):

- ZSH completion script
- Fish completion script
- `framework doctor` command to verify installation
- `framework config` command for project settings
- Plugin system for custom commands

## Troubleshooting

**Command not found: framework**
```bash
# Check if installed
ls -la ~/.local/bin/framework*

# Check if in PATH
echo $PATH | grep ".local/bin"

# Add to PATH if needed
export PATH="$HOME/.local/bin:$PATH"
```

**Wrong command set (local vs global)**
```bash
# Check which framework is being used
type framework

# Debug routing
cd /tmp && bash -x ~/.local/bin/framework help
```

**Update not working**
```bash
# Manually update
R -e "devtools::install_github('table1/framework'); framework::cli_install()"
```

## Related Documentation

- `docs/cli.md` - Original CLI documentation
- `docs/features/cli_installer.md` - Installation details
- `README.md` - Quick start guide

## Credits

Implementation follows the hybrid CLI pattern described in the original request, adapted for R's ecosystem and Framework's architecture.
