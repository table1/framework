# Framework CLI Tool

The Framework CLI provides a persistent command-line interface for quickly creating new projects, similar to Laravel's `laravel new` command.

## Installation

### Prerequisites
- R with Framework package installed
- Bash shell (Linux, macOS, or Windows WSL)

### Install the CLI

```r
# Install Framework package
devtools::install_github("table1/framework")

# Install CLI tool
framework::cli_install()
```

By default, this installs to `~/.local/bin/framework` (user installation). To install system-wide:

```r
framework::install_cli(location = "system")  # Requires sudo
```

### PATH Setup

If `~/.local/bin` is not in your PATH, the installer will:

1. **Detect your shell** (bash, zsh, fish)
2. **Offer to automatically add it** to your shell config file
3. **Provide clear instructions** for activation

The installer is smart:
- Detects if PATH is already configured (won't duplicate)
- Shows shell-specific commands (e.g., fish syntax differs from bash/zsh)
- Offers to do it for you or provides manual instructions

**If you choose automatic setup:**
```
Would you like to automatically add it to ~/.zshrc? (y/n): y

✓ Added to ~/.zshrc

To activate:
1. Restart your terminal (recommended), or
2. Run in terminal: source ~/.zshrc
```

**If you decline or it's already configured:**
Clear instructions are provided for manual setup.

## Usage

### Create Projects

```bash
# Interactive mode (prompts for all options)
framework new

# Quick project creation
framework new myproject

# Specify project type
framework new slides presentation
framework new coursework course
```

### Other Commands

```bash
# Show Framework version
framework version

# Show help
framework help
```

## How It Works

The CLI is a thin bash wrapper that:
1. Fetches the latest `new-project.sh` from the framework-project repository
2. Executes it with your specified arguments
3. The script guides you through project creation

This architecture ensures:
- **Always up-to-date**: Pulls latest template script from GitHub
- **Single source of truth**: `new-project.sh` is the only implementation
- **No duplication**: CLI doesn't reimplement logic
- **Consistency**: Same experience across all installation methods

## Alternative Installation Methods

You don't need to install the CLI to create projects. Three alternatives:

### 1. One-Time Curl Script

```bash
curl -fsSL https://raw.githubusercontent.com/table1/framework-project/main/new-project.sh | bash
```

No installation required. Same experience as the CLI.

### 2. Manual Template Clone

```bash
git clone https://github.com/table1/framework-project myproject
cd myproject
source init.R
```

Full control, can customize template before initialization.

### 3. Direct R Package Usage

```r
library(framework)
init(
  project_name = "MyProject",
  type = "project",
  use_renv = FALSE,
  attach_defaults = TRUE
)
```

Programmatic control, useful for automation.

## Updating the CLI

Update to the latest version:

```r
framework::cli_update()
```

This updates both the Framework package and CLI tool from GitHub. The CLI is a symlink to the installed package, so updating the package automatically updates the CLI.

**Output:**
```
Updating Framework package and CLI from GitHub...

✓ Framework CLI updated!
Updated: 0.1.0 → 0.1.1
```

**Advanced:**
```r
# Update to specific branch
framework::cli_update(ref = "develop")
```

Verify the update:
```bash
framework version
```

If the symlink breaks (rare), reinstall:
```r
framework::cli_install()
```

## Uninstallation

```r
# Remove user installation
framework::cli_uninstall()

# Remove system installation
framework::cli_uninstall(location = "system")
```

## Platform Support

- **Linux**: ✅ Fully supported
- **macOS**: ✅ Fully supported
- **Windows**: ⚠️ WSL only (native Windows not supported)

The CLI requires bash. Windows users should use WSL (Windows Subsystem for Linux).

## Troubleshooting

### "framework: command not found"

1. Verify installation:
   ```r
   framework::cli_install()
   ```

2. Check if installed:
   ```bash
   ls -la ~/.local/bin/framework
   ```

3. Verify PATH:
   ```bash
   echo $PATH | grep ".local/bin"
   ```

4. If not in PATH, add to `~/.bashrc`:
   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```

### CLI pulls old template version

The CLI always fetches the latest `new-project.sh` from GitHub. If you're seeing old behavior:

1. Check GitHub for latest version: https://github.com/table1/framework-project
2. Verify network connectivity
3. Try the direct curl method to bypass caching

### Permission errors (system installation)

System installation requires sudo. If you get permission errors:

```r
# Use user installation instead (recommended)
framework::install_cli(location = "user")
```

## Development

The CLI implementation consists of:

1. **`inst/bin/framework`** - Bash script wrapper (in framework package)
2. **`new-project.sh`** - Actual implementation (in framework-project repo)
3. **`R/install_cli.R`** - Installation functions

To modify the CLI behavior, edit `new-project.sh` in the framework-project repository.
To modify the CLI interface, edit `inst/bin/framework` in the framework package.
