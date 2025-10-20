# Framework Philosophy

This document outlines the core design principles and workflow philosophy behind Framework.

## Table of Contents

- [Core Principles](#core-principles)
- [Package Management Philosophy](#package-management-philosophy)
- [Convention Over Configuration](#convention-over-configuration)
- [Reproducibility First](#reproducibility-first)

## Core Principles

Framework is built around several key principles:

1. **Convention over Configuration** - Sensible defaults, minimal setup
2. **Reproducibility by Design** - Every project decision considers reproducibility
3. **Progressive Disclosure** - Simple by default, powerful when needed
4. **Explicit over Implicit** - Make dependencies and data flows obvious

## Package Management Philosophy

### The "Attach Common, Namespace Specific" Workflow

Framework promotes a deliberate approach to package management that balances convenience with clarity:

**Never use `library()` calls in analysis scripts or notebooks.**

Instead, Framework uses a two-tier system:

#### Auto-Attached Packages (Available without prefix)

These packages are loaded automatically by `scaffold()` and are available throughout your project:

```r
# Works immediately after scaffold()
data %>%
  filter(x > 10) %>%
  select(y) %>%
  ggplot(aes(x, y)) + geom_point()
```

**Default auto-attached packages:**
- `dplyr` - Data manipulation
- `tidyr` - Data tidying
- `ggplot2` - Visualization

**Project-specific heavy users** should also be attached:
```yaml
# config.yml for a spatial analysis project
packages:
  - name: dplyr
    attached: true
  - name: ggplot2
    attached: true
  - name: sf              # Heavy spatial use
    attached: true
  - name: terra           # Raster operations
    attached: true
```

#### Namespaced Packages (Use `package::function()`)

Specialized or occasionally-used packages should be called with explicit namespacing:

```r
# Read specialized formats
excel_data <- readxl::read_excel("data/source/file.xlsx")
stata_data <- haven::read_stata("data/source/file.dta")

# Parse dates
dates <- lubridate::ymd("2024-01-15")

# Specialized operations
spatial_join <- sf::st_join(points, polygons)
```

These packages are still **declared in config.yml** and **installed by Framework**, but not attached to the namespace.

### Why This Approach?

**Benefits:**

✅ **Single source of truth** - All dependencies tracked in `config.yml`
✅ **No scattered library() calls** - Clean, consistent scripts
✅ **Clear provenance** - Obvious where functions come from
✅ **Fewer namespace conflicts** - Only core packages in namespace
✅ **Better code review** - Dependencies explicit in function calls
✅ **Pedagogically sound** - Teaches awareness of package sources

**Comparison to traditional approach:**

```r
# ❌ Traditional: Scattered library() calls
library(dplyr)
library(ggplot2)
library(readxl)
library(haven)
library(lubridate)
library(sf)
# ... 20 more lines later ...
data <- read_excel("file.xlsx")  # Where did this come from?

# ✅ Framework: Clear and explicit
# (dplyr, ggplot2 auto-attached via scaffold())
data <- readxl::read_excel("file.xlsx")  # Obvious source
```

### Decision Guide: When to Attach vs. Namespace?

**Attach a package when:**
- Used in >50% of your scripts
- Core to your project's workflow
- Part of your "daily driver" toolkit
- Low risk of namespace conflicts

**Namespace a package when:**
- Specialized or domain-specific use
- One-off or occasional need
- High risk of namespace conflicts (e.g., `MASS::select()` vs `dplyr::select()`)
- Used for only 1-2 functions

**Examples by project type:**

```yaml
# Standard data analysis project
packages:
  - name: dplyr
    attached: true
  - name: ggplot2
    attached: true
  - name: tidyr
    attached: true
  - name: readxl
    attached: false    # Use readxl::read_excel()
  - name: haven
    attached: false    # Use haven::read_stata()

# Spatial analysis project
packages:
  - name: dplyr
    attached: true
  - name: ggplot2
    attached: true
  - name: sf
    attached: true     # Heavy use justifies attachment
  - name: terra
    attached: true
  - name: rgdal
    attached: false    # Occasional use

# Time series project
packages:
  - name: dplyr
    attached: true
  - name: ggplot2
    attached: true
  - name: tsibble
    attached: true
  - name: forecast
    attached: true
  - name: zoo
    attached: false
```

### Common Patterns

#### Pattern 1: Namespaced Functions (Standard)

```r
# Best for occasional use
excel_data <- readxl::read_excel("data.xlsx")
stata_data <- haven::read_stata("data.dta")
dates <- lubridate::ymd("2024-01-15")
```

#### Pattern 2: Shorthand for Heavy Namespace Use

If you find yourself typing the same namespace repeatedly in one script:

```r
# Create shorthand at top of notebook (optional)
read_excel <- readxl::read_excel
read_stata <- haven::read_stata
ymd <- lubridate::ymd

# Then use throughout
data1 <- read_excel("file1.xlsx")
data2 <- read_excel("file2.xlsx")
data3 <- read_excel("file3.xlsx")
```

**Note:** This is a pragmatic compromise. Only do this if you're calling the same function many times in a single script.

#### Pattern 3: Temporary Attachment (Use Sparingly)

For interactive exploration, you might temporarily attach a package:

```r
# During interactive exploration only
library(sf)  # Temporarily attach for console work

# Before committing notebook, convert to:
sf::st_read(...)
sf::st_transform(...)
# Or add to config.yml with attached: true
```

### Reproducibility Script Generation

For collaborators not using Framework, consider generating standalone scripts:

```r
# Generate standalone R script from Framework notebook
# (adds library() calls at top based on namespaced functions)
make_standalone <- function(notebook, output) {
  # TODO: Future feature
  # Scans for package::function() patterns
  # Generates library() statements
  # Creates self-contained script
}
```

### Integration with renv

Framework's package philosophy works alongside renv:

- **`attached: true/false`** controls **namespace** (what's visible without prefix)
- **`renv`** controls **versions** (what versions are installed)
- Both are needed for full reproducibility

```yaml
# config.yml
packages:
  - name: dplyr
    attached: true
    version: "1.1.0"  # Pinned version (when renv enabled)

  - name: readxl
    attached: false   # Namespace only, but version still tracked
    version: "1.4.2"
```

## Convention Over Configuration

Framework embraces "convention over configuration" to reduce cognitive load:

### Standardized Directory Structure

```
project/
├── data/
│   ├── source/      # Raw, immutable data
│   ├── in_progress/ # Intermediate transformations
│   ├── final/       # Analysis-ready datasets
│   ├── cached/      # Computed results (gitignored)
│   └── scratch/     # Temporary files (gitignored)
├── notebooks/       # Quarto/RMarkdown analysis
├── scripts/         # Standalone R scripts
├── functions/       # Reusable project functions
├── results/         # Outputs, figures, tables
└── config.yml       # Single source of configuration
```

**Benefits:**
- Everyone knows where to find things
- Tools can make safe assumptions
- Documentation transfers across projects
- Onboarding is faster

### Configuration Hierarchy

Framework uses a three-tier configuration system:

1. **Package defaults** - Sensible starting points built into Framework
2. **Project config.yml** - Project-specific overrides
3. **Environment variables (.env)** - Secrets and credentials (gitignored)

```yaml
# config.yml - Project configuration
default:
  directories:
    notebooks: notebooks
    scripts: scripts
    cache: data/cached

  packages:
    - name: dplyr
      attached: true
```

```bash
# .env - Secrets (never committed)
DB_PASSWORD=secret123
API_KEY=sk-...
```

### Template System

New projects start from type-specific templates:

- **project** - Full-featured data analysis
- **course** - Teaching materials with lectures/assignments
- **presentation** - Single presentation focus

Each template provides pre-configured structure, README, and config.yml.

## Reproducibility First

Every Framework design decision considers reproducibility:

### Declarative Data Management

Data files are declared in config.yml with integrity tracking:

```yaml
data:
  demographics:
    path: data/source/demographics.csv
    type: csv
    locked: true  # Integrity checking via digest
    description: "Population demographics from 2020 census"

  outcomes:
    path: data/source/private/patient_outcomes.csv
    type: csv
    encrypted: true  # Encrypted at rest
    locked: true
```

**Benefits:**
- Data catalog serves as documentation
- Integrity verification via SHA-256 digests
- Public/private data segregation
- Encrypted storage for sensitive data

### Immutable Source Data

Framework enforces immutability:

```r
# ✓ GOOD: Load, transform, save to new location
source_data <- data_load("source.raw_data")
clean_data <- source_data %>% clean_transform()
data_save(clean_data, "final.clean_data")

# ✗ BAD: Framework prevents overwriting source data
data_save(clean_data, "source.raw_data")  # Error: locked
```

### Environment Isolation

Each project is self-contained:

- **Own package library** (via renv when enabled)
- **Own data directory** (no global data dependencies)
- **Own functions/** (no reliance on workspace functions)
- **Own config** (explicit, not inherited)

### Audit Trail

Framework tracks provenance:

```r
# Data provenance
data_load("demographics")  # Logs load time, hash verification

# Results tracking
result_save(model, "final_model",
  comment = "Logistic regression with age + gender covariates")

# Cache with expiration
cache("expensive_calculation", {
  slow_computation(data)
}, expire_after = 24)  # Hours
```

Query project history:

```r
# View all saved results
result_list()

# View data integrity status
data_list()

# Check cache status
cache_get("expensive_calculation")
```

### Computational Environment Documentation

Framework captures environment details:

```r
# Summarize current environment
env_summary()
# Shows: R version, platform, loaded packages, memory usage

# Reset environment between analyses
env_reset(keep = c("config"))
```

---

## Further Reading

- [Configuration Guide](../readme-parts/6_rest.md) - Deep dive into config.yml
- [Data Management](../readme-parts/5_usage_data.md) - Data loading and caching
- [Package Management](../README.md#packages) - renv integration and version pinning
- [Security](../README.md#security) - Handling sensitive data

---

**Philosophy in Practice:**

The best way to understand Framework's philosophy is to create a project and experience the workflow:

```r
library(framework)

# Create new project
init(project_name = "MyAnalysis", type = "project")

# Start new R session in project directory
scaffold()  # Loads environment, attaches core packages

# Start analyzing with confidence
data <- readxl::read_excel("data/source/raw.xlsx")
clean_data <- data %>% filter(!is.na(outcome))
data_save(clean_data, "final.clean")
```

Every Framework feature is designed to make this workflow smooth, explicit, and reproducible.
