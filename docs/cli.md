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
framework::install_cli()
```

By default, this installs to `~/.local/bin/framework` (user installation). To install system-wide:

```r
framework::install_cli(location = "system")  # Requires sudo
```

### Add to PATH (if needed)

If `~/.local/bin` is not in your PATH, add this to `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then restart your shell or run `source ~/.bashrc`.

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

## Uninstallation

```r
# Remove user installation
framework::uninstall_cli()

# Remove system installation
framework::uninstall_cli(location = "system")
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
   framework::install_cli()
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
