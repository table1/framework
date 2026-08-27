---
name: framework-packages
description: Use when adding, installing, or managing R packages in this Framework project - package_add() is required instead of install.packages(), and auto-attached packages must not be re-loaded with library().
---

# Framework Package Management

Packages are declared in settings.yml and installed/attached by `scaffold()`.

## Adding Packages

**ALWAYS use Framework's package management:**

```r
# Add a CRAN package (installed on next scaffold)
package_add("janitor")

# Add and auto-attach (loaded automatically by scaffold)
package_add("forcats", auto_attach = TRUE)

# Add from GitHub
package_add("tidyverse/dplyr@main")

# Pin a version
package_add("dplyr@1.1.0")
```

**DO NOT** use `install.packages()` directly — it bypasses Framework's tracking
and the package won't be recorded in settings.yml for reproducibility.

## Auto-Attached vs Installed-Only

- **Auto-attached** packages (marked `auto_attach: true` in settings.yml) are loaded
  by `scaffold()`. **Never call `library()` for them** — see AGENTS.md for the current list.
- **Installed-only** packages are available but not loaded; call `library()` when needed.

## renv Integration (Optional)

If the project has renv enabled, Framework routes installs through renv automatically.
Snapshot/restore helpers:

```r
packages_snapshot()   # Record current versions
packages_restore()    # Restore recorded versions
packages_status()     # Check for drift
```
