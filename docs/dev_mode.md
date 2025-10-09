# Development Mode

Framework includes a special development mode for package developers working on the framework itself.

## Quick Start

When creating a new test project, enable dev mode:

```r
init(.dev_mode = TRUE)
```

This creates a special `.Rprofile` that automatically loads framework from your development directory (`$HOME/code/framework`) instead of the installed package.

## How It Works

The generated `.Rprofile`:

1. **Overrides `library()`** - Intercepts calls to `library("framework")`
2. **Loads from dev directory** - Uses `devtools::load_all()` to load from `~/code/framework`
3. **Falls back gracefully** - If dev directory doesn't exist, loads from installed package
4. **Preserves other packages** - All other `library()` calls work normally

## Usage

### Creating a Dev Project

```r
# In R console
library(framework)
init(.dev_mode = TRUE)

# Creates .Rprofile that loads from ~/code/framework
```

### Testing Changes

1. Make changes to framework source in `~/code/framework`
2. In your test project, start a new R session
3. Call `library(framework)` - automatically loads your changes
4. Test your changes immediately

```r
# In test project
library(framework)
# → Framework loaded from development directory: /Users/you/code/framework

scaffold()
# Your changes are now active!
```

## What Gets Created

The `.Rprofile` contains:

```r
# Store original library function
original_library <- base::library

# Override library function
library <- function(package, ...) {
  if (!character.only) {
    package <- as.character(substitute(package))
  }

  if (package == "framework") {
    dev_path <- "$HOME/code/framework"
    if (dir.exists(dev_path)) {
      env <- devtools::load_all(dev_path, export_all = FALSE, quiet = TRUE)
      message("Framework loaded from development directory: ", dev_path)
      return(invisible(env))
    }
    # ... fallback logic
  }

  # Other packages use original library
  original_library(package, character.only = TRUE, ...)
}
```

## Requirements

- **devtools** package must be installed
- Framework source must be at `$HOME/code/framework`

If either is missing, framework falls back to loading the installed package.

## Workflow Example

```bash
# Terminal - make changes to framework
cd ~/code/framework
# Edit R/make_notebook.R, add new feature

# Terminal - create test project
cd /tmp
R

# R Console
library(framework)
init(.dev_mode = TRUE)
# → Creates test project with dev .Rprofile

# Restart R session (or start new one)
library(framework)
# → Framework loaded from development directory: ~/code/framework

# Test your changes
make_notebook("test")  # Uses your modified code!
```

## When to Use Dev Mode

✅ **Use dev mode when:**
- Developing framework itself
- Testing new features before release
- Debugging framework issues
- Contributing to framework

❌ **Don't use dev mode when:**
- Using framework for actual analysis work
- In production environments
- Sharing projects with collaborators
- You want stable, released versions

## Disabling Dev Mode

Simply delete or rename the `.Rprofile`:

```bash
# Disable dev mode
rm .Rprofile

# Or rename to keep as backup
mv .Rprofile .Rprofile.bak
```

Then restart R - framework will load normally from installed package.

## Tips

1. **Quick iteration** - No need to reinstall framework after each change
2. **Clean state** - `devtools::load_all()` gives you a fresh package environment
3. **Multiple test projects** - Create separate test projects for different features
4. **Git branches** - Switch framework branches, reload in test project
5. **Documentation** - Changes to roxygen comments are immediately available

## Troubleshooting

### "devtools package required"

Install devtools:
```r
install.packages("devtools")
```

### "Framework not found"

Check that framework source exists at `~/code/framework`:
```bash
ls ~/code/framework/DESCRIPTION
```

If it's in a different location, edit `.Rprofile` and update the `dev_path` variable.

### Changes not appearing

Make sure to restart your R session after making changes to framework source.

### Other packages affected

The `.Rprofile` only intercepts `library("framework")`. All other packages load normally through the standard library function.
