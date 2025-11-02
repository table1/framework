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
scaffold(quiet = FALSE)
```
## Parameters

- **`quiet`** (logical) (default: `FALSE`): Suppress startup messages and package load notifications

## Returns

Invisibly returns TRUE on success. Side effects include loading packages,
sourcing functions from functions/ directory, and setting the random seed.

## Details

scaffold() performs the following actions in order:

1. Reads settings from settings.yml (or split settings files)
2. Sets random seed if configured (for reproducibility)
3. Installs missing packages from settings$packages
4. Loads/attaches packages based on auto_attach configuration
5. Sources all .R files in the functions/ directory
6. Executes scaffold.R if present (for project-specific setup)
## Examples

```r
library(framework)
scaffold()

```

Standard usage - loads environment with status messages

```r
library(framework)
scaffold(quiet = TRUE)

```

Silent mode - suppresses all startup messages

```r
# In your scaffold.R file (project-specific setup)
message("Custom setup running...")
options(scipen = 999)  # Disable scientific notation

```

Custom project setup via scaffold.R## See Also

- [`init()`](init) - Initialize a new Framework project
- [`configure_packages()`](configure_packages) - Configure package installation and loading## Notes

- If you use renv, scaffold() will use renv for package installation
- The random seed is set from settings$seed or FW_SEED environment variable
- All .R files in functions/ are sourced in alphabetical order
