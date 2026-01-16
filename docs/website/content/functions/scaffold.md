---
title: Load Project Environment
category: Core Functions
tags: setup, environment, core, workflow
---

# Load Project Environment

Loads your project environment by reading settings, installing/loading packages,
sourcing custom functions, and setting up your workspace. This is the first
function you run after library(framework).


## Usage

```r
scaffold(config_file = NULL)
```

## Parameters

- **`config_file`** (character) (default: `NULL`): Path to configuration file. If NULL, automatically discovers settings.yml or config.yml in the project.

## Returns

Invisibly returns NULL. The main effects are side effects: loading packages,
sourcing functions, and creating the `config` object in the global environment.

## Details

scaffold() performs the following actions in order:

1. **Standardizes working directory** - Finds and sets the project root, even when called from notebooks in subdirectories
2. **Loads environment variables** - Reads secrets from `.env` file
3. **Loads configuration** - Parses settings.yml for project settings
4. **Creates config object** - Makes `config` available in global environment for accessing settings via `config("key")`
5. **Sets random seed** - For reproducibility (if `seed_on_scaffold: true` and `seed` is configured)
6. **Sets ggplot2 theme** - For consistent styling (if `set_theme_on_scaffold: true` and `ggplot_theme` is configured)
7. **Installs missing packages** - Any missing packages from the `packages` list
8. **Loads/attaches packages** - Based on `auto_attach` configuration
9. **Sources functions** - Loads all `.R` files from `functions/` directory
10. **Executes scaffold.R** - Runs project-specific setup script if present in project root

After `scaffold()` completes, you have access to:
- All packages listed in settings.yml
- All functions from your `functions/` directory
- The `config` object for accessing settings via `config("key")`
- Database connections configured in your project

## The config Object

After scaffolding, a `config` object is created in your global environment. Use it to access settings with dot-notation:

```r
config("directories.notebooks")  # Get notebooks directory
config("seed")                   # Get random seed value
config("connections.db.host")    # Get nested connection settings
config("missing", default = "fallback")  # Use default for missing keys
```

## Examples

```r
library(framework)
scaffold()
```

Standard usage - loads environment with status messages

```r
library(framework)
scaffold()

# Access configuration after scaffolding
config("directories.notebooks")
config("packages")
```

Using the config object after scaffolding

```r
# In your scaffold.R file (project-specific setup)
message("Custom setup running...")
options(scipen = 999)  # Disable scientific notation
```

Custom project setup via scaffold.R

## See Also

- [`new_project()`](new_project) - Create a new Framework project
- [`standardize_wd()`](standardize_wd) - Just the working directory standardization
- [`settings()`](settings) - Access configuration values after scaffolding

## Notes

- If you use renv, scaffold() will use renv for package installation
- The random seed is set from settings$seed or FW_SEED environment variable
- All .R files in functions/ are sourced in alphabetical order
- The `config` object is locked in the global environment to prevent accidental modification
- Framework creates a `framework.db` SQLite database for tracking data integrity and caching
