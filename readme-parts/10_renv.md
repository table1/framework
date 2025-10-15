## Reproducibility with renv

Framework includes **optional** [renv](https://rstudio.github.io/renv/) integration for package version control (OFF by default, opt-in):

### Quick Start

```r
# Enable renv for this project (one-time setup)
renv_enable()

# That's it! Framework handles the rest automatically:
# ✓ Installs framework, rmarkdown, and your config.yml packages
# ✓ Creates renv.lock with exact versions
# ✓ Updates .gitignore to exclude renv cache
```

### How It Works

**When you enable renv:**
1. Framework automatically installs essential packages:
   - `framework` (from GitHub: table1/framework)
   - `rmarkdown` (needed by Quarto for R code chunks)
   - All packages listed in `config.yml`

2. Creates `renv.lock` - a snapshot of exact package versions

3. Other collaborators just need to run:
   ```r
   # In a fresh clone of your project:
   library(framework)
   packages_restore()  # Installs exact versions from renv.lock
   ```

**When to use renv:**
- Publishing research that needs exact reproducibility
- Collaborating with others who need identical package versions
- Long-term projects where package updates might break code
- Archiving projects with specific package dependencies

**When you might not need it:**
- Quick exploratory analysis
- Solo projects with minimal dependencies
- Projects where latest package versions are preferred

### Package Management

```r
# Check package status
packages_status()

# Install new package (automatically added to renv.lock)
install.packages("newpackage")

# Update renv.lock after changes
packages_snapshot()

# Restore from renv.lock (e.g., after git clone)
packages_restore()

# Update all packages to latest versions
packages_update()

# Disable renv if you change your mind
renv_disable()  # Keeps renv.lock for future use
```

### Version Pinning in config.yml

Control exact package versions in your config:

```yaml
packages:
  - dplyr                    # Latest from CRAN
  - ggplot2@3.4.0           # Specific CRAN version
  - tidyverse/dplyr@main    # GitHub repo with branch/tag
  - user/package@v1.2.3     # GitHub with specific tag
```

When you run `renv_enable()` or `packages_snapshot()`, Framework installs these exact versions and records them in `renv.lock`.

Package management should come almost for free, so Framework aims to handle all the messy details of `renv` so you can focus on your work.

See [renv integration docs](docs/features/renv_integration.md) for advanced usage.
