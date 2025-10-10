# Framework

A lightweight R package for structured, reproducible data analysis projects focusing on convention over configuration.

**⚠️ Active Development:** APIs may change. Version 1 with a stable API coming soon.

## Quick Start

### Option 1: Use the Template (Recommended)

```bash
git clone https://github.com/table1/framework-project my-project
cd my-project
```

Edit `init.R` with your settings, then run:
```r
devtools::install_github("table1/framework")
source("init.R")
```

**Most common setup:**
```r
framework::init(
  project_name = "MyProject",
  type = "project",  # Creates notebooks/, scripts/, data/, results/
  use_renv = FALSE   # Set TRUE to enable renv for reproducibility
)
```

### Option 2: Start from Scratch

```r
# Install package
devtools::install_github("table1/framework")

# Initialize in current directory
framework::init(
  project_name = "MyProject",
  type = "project",       # or "course" or "presentation"
  use_renv = FALSE,       # Set TRUE to enable renv
  interactive = FALSE
)
```

### Project Types

- **project** (default): Full-featured with `notebooks/`, `scripts/`, `data/` (public/private splits), `results/`, `functions/`, `docs/`
- **course**: For teaching with `presentations/`, `notebooks/`, `data/`, `functions/`, `docs/`
- **presentation**: Minimal for single talks with `data/`, `functions/`, `results/`

**Not sure?** Use `type = "project"` - it's the most flexible.

## What It Does

Framework reduces boilerplate and enforces best practices for data analysis:

- **Project scaffolding** - Standardized directories, config-driven setup
- **Data management** - Declarative data catalog, integrity tracking, encryption
- **Auto-loading** - Packages and custom functions loaded automatically
- **Optional renv integration** - Reproducible package management (opt-in)
- **Caching** - Smart caching for expensive computations
- **Database helpers** - PostgreSQL, SQLite with credential management
- **Results tracking** - Save/retrieve analysis outputs with blinding support
- **Supported formats** - CSV, TSV, RDS, Stata (.dta), SPSS (.sav), SAS (.xpt, .sas7bdat)

## What Gets Created

When you run `init()`, Framework creates:

- **Project structure** - Organized directories (varies by type)
- **Configuration files** - `config.yml` and optional `settings/` files
- **Git setup** - `.gitignore` configured to protect private data
- **Tooling** - `.lintr`, `.styler.R`, `.editorconfig` for code quality
- **Database** - `framework.db` for metadata tracking
- **Environment** - `.env` template for secrets

### Example: Project Type Structure

```
project/
├── notebooks/              # Exploratory analysis
├── scripts/                # Production pipelines
├── data/
│   ├── source/private/     # Raw data (gitignored)
│   ├── source/public/      # Public raw data
│   ├── cached/            # Computation cache (gitignored)
│   └── final/private/     # Results (gitignored)
├── functions/             # Custom functions
├── results/private/       # Analysis outputs (gitignored)
├── docs/                  # Documentation
├── config.yml            # Project configuration
├── framework.db          # Metadata/tracking database
└── .env                  # Secrets (gitignored)
```

## Core Workflow

### 1. Initialize Your Session

```r
library(framework)
scaffold()  # Loads packages, functions, config, standardizes working directory
```

### 2. Create Notebooks & Scripts

Framework provides artisan-style commands for creating files from templates:

```r
# Create a Quarto notebook (default)
make_notebook("1-exploration")  # → notebooks/1-exploration.qmd

# Create an RMarkdown notebook
make_notebook("analysis.Rmd")   # → notebooks/analysis.Rmd

# Create an R script (two ways)
make_notebook("process-data.R") # → scripts/process-data.R
make_script("process-data")     # → scripts/process-data.R (convenience wrapper)

# Create a reveal.js presentation
make_notebook("results-presentation", stub = "revealjs")

# List available stubs
list_stubs()
```

**Built-in stubs:**
- `default` - Full-featured notebook with TOC and sections
- `minimal` - Bare-bones notebook with essential setup only
- `revealjs` - Quarto presentation using reveal.js (Quarto only)

**Custom stubs:** Create a `stubs/` directory in your project:
```
stubs/
  notebook-analysis.qmd     # Custom notebook template
  notebook-default.qmd      # Override default notebook
  script-etl.R              # Custom script template
  script-default.R          # Override default script
```

Stub templates support placeholders:
- `{filename}` - File name without extension
- `{date}` - Current date (YYYY-MM-DD)

**Configure default directories in config.yml:**
```yaml
options:
  notebook_dir: "notebooks"  # Where make_notebook() creates notebook files
  script_dir: "scripts"      # Where make_script() creates script files
```

### 3. Load Data

**Via config:**
```yaml
# config.yml or settings/data.yml
data:
  source:
    private:
      survey:
        path: data/source/private/survey.dta
        type: stata
        locked: true
```

```r
# Load using dot notation
df <- data_load("source.private.survey")
```

**Direct path:**
```r
df <- data_load("data/my_file.csv")       # CSV
df <- data_load("data/stata_file.dta")    # Stata
df <- data_load("data/spss_file.sav")     # SPSS
```

Statistical formats (Stata/SPSS/SAS) strip metadata by default for safety. Use `keep_attributes = TRUE` to preserve labels.

### 4. Cache Expensive Operations

```r
model <- get_or_cache("model_v1", {
  expensive_model_fit(df)
}, expire_after = 1440)  # Cache for 24 hours
```

### 5. Save Results

```r
# Save data
data_save(processed_df, "final.private.clean", type = "csv")

# Save analysis output
result_save("regression_model", model, type = "model")

# Save notebook (blinded)
result_save("report", file = "report.html", type = "notebook",
            blind = TRUE, public = FALSE)
```

### 6. Query Databases

```yaml
# config.yml
connections:
  db:
    driver: postgresql
    host: !expr Sys.getenv("DB_HOST")
    database: !expr Sys.getenv("DB_NAME")
    user: !expr Sys.getenv("DB_USER")
    password: !expr Sys.getenv("DB_PASS")
```

```r
df <- query_get("SELECT * FROM users WHERE active = true", "db")
```


## Configuration

**Simple:**
```yaml
default:
  packages:
    - dplyr
    - ggplot2
  data:
    example: data/example.csv
```

**Advanced:** Split config into `settings/` files:
```yaml
default:
  data: settings/data.yml
  packages: settings/packages.yml
  connections: settings/connections.yml
  security: settings/security.yml
```

Use `.env` for secrets:
```env
DB_HOST=localhost
DB_PASS=secret
DATA_ENCRYPTION_KEY=key123
```

Reference in config:
```yaml
security:
  data_key: !expr Sys.getenv("DATA_ENCRYPTION_KEY")
```

## Key Functions

| Function | Purpose |
|----------|---------|
| `scaffold()` | Initialize session (load packages, functions, config) |
| `data_load()` | Load data from path or config |
| `data_save()` | Save data with integrity tracking |
| `query_get()` | Execute SQL query, return data |
| `query_execute()` | Execute SQL command |
| `get_or_cache()` | Lazy evaluation with caching |
| `result_save()` | Save analysis output |
| `result_get()` | Retrieve saved result |
| `scratch_capture()` | Quick debug/temp file save |
| `renv_enable()` | Enable renv for reproducibility (opt-in) |
| `renv_disable()` | Disable renv integration |
| `packages_snapshot()` | Save package versions to renv.lock |
| `packages_restore()` | Restore packages from renv.lock |

## Data Integrity & Security

- **Hash tracking** - All data files tracked with SHA-256 hashes
- **Locked data** - Flag files as read-only, errors on modification
- **Encryption** - AES encryption for sensitive data/results
- **Gitignore by default** - Private directories auto-ignored

## Reproducibility with renv

Framework includes **optional** renv integration (OFF by default):

```r
# Enable renv for this project
renv_enable()

# Your packages are now managed by renv
# Use snapshot after installing new packages
packages_snapshot()

# Disable renv if you prefer
renv_disable()
```

**Version pinning in config.yml:**
```yaml
packages:
  - dplyr              # Latest from CRAN
  - ggplot2@3.4.0     # Specific version
  - tidyverse/dplyr@main  # GitHub with ref
```

See [renv integration docs](docs/features/renv_integration.md) for details.

## Roadmap

- Excel file support
- Quarto codebook generation
