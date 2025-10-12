# CLI Dev Mode

**Date**: 2025-10-12
**Hidden Feature**: For framework developers only

## Overview

The Framework CLI has a hidden `--dev-mode` flag that allows developers to test changes to the framework package without pushing to GitHub.

## Usage

```bash
framework new myproject --dev-mode
```

This will:
1. Use the local `new-project.sh` script from `$HOME/code/framework-project`
2. Install the framework package from `$HOME/code/framework` (local dev version)
3. Skip fetching from GitHub entirely

## How It Works

### Environment Variables

When `--dev-mode` is detected:
- `FW_DEV_MODE=true` is exported
- `FW_DEV_PATH=$HOME/code/framework` is exported

These variables are passed through:
1. `framework` CLI script → `new-project.sh` → `init.R`

### Installation Flow

**Normal mode:**
```
framework new → curl GitHub new-project.sh → init.R → devtools::install_github()
```

**Dev mode:**
```
framework new --dev-mode → local new-project.sh → init.R → devtools::install(local_path)
```

### Code Locations

1. **`inst/bin/framework`** (CLI entry point)
   - Detects `--dev-mode` flag
   - Sets `FW_DEV_MODE` and `FW_DEV_PATH` env vars
   - Uses local `new-project.sh` instead of curling from GitHub

2. **`framework-project/new-project.sh`** (project installer)
   - Passes through `FW_DEV_MODE` and `FW_DEV_PATH` to init.R
   - Shows informational message when dev mode is active

3. **`framework-project/init.R`** (initialization script)
   - Checks for `FW_DEV_MODE` environment variable
   - If true, uses `devtools::install(FW_DEV_PATH)` instead of `install_github()`

## Requirements

Dev mode requires:
- `$HOME/code/framework` - Framework package source
- `$HOME/code/framework-project` - Framework project template

If these paths don't exist, dev mode will fail with a clear error.

## Why Hidden?

This feature is intentionally not documented in `framework help` because:
- It's only useful for framework developers
- It requires a specific local directory structure
- End users should use the normal GitHub installation flow

## Testing

To test dev mode:

```bash
# Make changes to framework package
cd ~/code/framework
# ... edit files ...

# Test with a new project (no need to push to GitHub!)
cd /tmp
framework new test-dev --dev-mode

# Verify it uses your local changes
cd test-dev
R -e "library(framework); packageVersion('framework')"
```

## Troubleshooting

**Error: "Dev mode requires framework-project at ~/code/framework-project"**
- Solution: Clone the framework-project repo to `~/code/framework-project`

**Error: "Dev path does not exist: ~/code/framework"**
- Solution: Ensure framework package source is at `~/code/framework`

**Package version doesn't reflect changes**
- Solution: Make sure you've incremented the version in `DESCRIPTION`
- Or: Check that changes were saved before running dev mode
