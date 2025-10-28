# Framework

An R package for structured, reproducible data analysis projects with a great user experience.

**⚠️ Active Development:** APIs may change. Version 1 with a stable API coming soon.

## Quick Start

**Preview:** During setup, you'll be asked to choose:
- **Project type**: `project` (full-featured), `course` (teaching), or `presentation` (single talk)
- **Notebook format**: Quarto `.qmd` (recommended) or RMarkdown `.Rmd`
- **Git**: Whether to initialize a `git` repository
- **Package management**: Whether to use renv for package management

Not sure? Choose the defaults. You can always change these later in `settings.yml`.

### Option 1: CLI Tool (Recommended)

Install the CLI:

```bash
curl -fsSL https://raw.githubusercontent.com/table1/framework/main/inst/bin/install-cli.sh | bash
```

And get started:

```bash
# Create projects
framework new myproject
framework new slides presentation
framework new
```

See [Command Line Interface](#command-line-interface) for full details.

### Option 2: One-Time Script (No CLI Installation)

**One-liner (macOS/Linux/Windows with Git Bash):**
```bash
curl -fsSL https://raw.githubusercontent.com/table1/framework-project/main/new-project.sh | bash
```

This guides you through creating a new project without installing the CLI.

### Option 3: Manual Setup

Clone the template and customize `init.R` to your preferences:

```bash
git clone https://github.com/table1/framework-project my-project
cd my-project
```

**Open `init.R`** in your favorite editor to set your project name, type, and options, then run it:

```r
framework::init(
  project_name = "MyProject",
  type = "project",                                  # or "course" or "presentation"
  use_renv = FALSE,
  default_notebook_format = "quarto",
  author_name = "Your Name",                         # Allows auto-filling Notebook author (optional)
  author_email = "email@example.com", 
  author_affiliation = "Johns Hopkins University"  
)

# Then run your code from your IDE. Or save your changes and run:
source("init.R")
```

### Project Types

- **project** (default): Full-featured research projects with exploratory notebooks, production scripts, organized data management, and documentation
- **course**: Teaching materials with presentations, student notebooks, and example data
- **presentation**: Single talks or presentations with minimal overhead: just data, helper functions, and output

**Not sure?** Use `type = "project"`. You can always delete directories you don't need; you won't break anything.

**Example structure:**

```
project/
├── notebooks/              # Exploratory analysis
├── scripts/                # Production pipelines
├── data/
│   ├── source/private/     # Raw data (gitignored)
│   ├── source/public/      # Public raw data
│   ├── cached/             # Computation cache (gitignored)
│   └── final/private/      # Results (gitignored)
├── functions/              # Custom functions
├── results/private/        # Analysis outputs (gitignored)
├── docs/                   # Documentation
├── settings.yml              # Project configuration
├── framework.db            # Metadata/tracking database
└── .env                    # Secrets (gitignored)
```

## Why Use Framework?

Framework reduces boilerplate and enforces best practices for data analysis:

- **Project scaffolding**: Standardized directories, config-driven setup
- **Data management**: Declarative data catalog, integrity tracking, encryption (on roadmap)
- **Auto-loading**: Load the packages you use in every file with one command; no more file juggling with your `library()` calls
- **Pain-free `renv` integration**: Use `renv` for reproducible package management without having to fight `renv` or babysit it.
- **Caching**: Smart caching for expensive computations
- **Database helpers**: PostgreSQL, SQLite with credential management
- **Supported file formats**: CSV, TSV, RDS, Stata (.dta), SPSS (.sav), SAS (.xpt, .sas7bdat)

## What Gets Created

When you run `init()`, Framework creates:

- **Project structure**: Organized directories (varies by type)
- **Configuration files**: `settings.yml` and optional `settings/` files
- **Git setup**: `.gitignore` configured to protect private data
- **Tooling**: `.lintr`, `.editorconfig` for code quality
- **Database**: `framework.db` for metadata tracking
- **Environment**: `.env` template for secrets

## Command Line Interface

The Framework CLI provides a `framework` command that automatically adapts based on where you are:
- **Outside projects**: Create new projects (`framework new`)
- **Inside projects**: Project commands like `framework make:notebook`, `framework scaffold`

### Installation

**One-line install**:
```bash
curl -fsSL https://raw.githubusercontent.com/table1/framework/main/inst/bin/install-cli.sh | bash
```

Or from R:
```r
framework::cli_install()
```

This installs the `framework` command and adds it to your PATH. The installer tries to create a symlinked shim but automatically copies the scripts when symlinks are not available (common on Windows or restricted filesystems).

### Project Commands

Once inside a Framework project:

```bash
framework scaffold           # Load packages, install dependencies
framework make:notebook analysis  # Create notebooks/analysis.qmd
framework make:script process     # Create scripts/process.R
```

### Updating

```bash
framework update      # Update Framework package on your system
```

## Core Workflow

### 1. Initialize Your Session

```r
library(framework)
scaffold()  # Loads packages, functions, config, standardizes working directory
```

### 2. Load Data

Use `data_load()` to read data with automatic integrity tracking. Every read is logged in the framework database with a SHA-256 hash, so you'll be notified if source data changes.

**Configure in `settings.yml`:**

```yaml
data:
  source:
    private:
      survey:
        path: data/source/private/survey.csv
        type: csv
        locked: true  # Errors if file changes
```

**Then load with dot notation:**

```r
df <- data_load("source.private.survey")
```

**Or point directly to a file:**

You can still read files without having them in your configuration. This approach still provides data integrity tracking:

```r
df <- data_load("data/example.csv")       # Framework detects type
df <- data_load("data/stata_file.dta")    # Stata
df <- data_load("data/spss_file.sav")     # SPSS
```

### 3. Do your analysis

Do your work.

### 2.5. Enhanced Data Viewing

Framework provides `view_detail()` for rich, browser-based data exploration:

```r
# Interactive table with search, filter, sort, export
view_detail(mtcars)

# Works with any R object
view_detail(iris, title = "Iris Dataset")

# Lists get tabbed YAML + R structure views
config <- read_config()
view_detail(config)  # Perfect for exploring nested configs!

# Plots get interactive display
library(ggplot2)
p <- ggplot(mtcars, aes(mpg, hp)) + geom_point()
view_detail(p)
```

**Features:**
- **DataTables interface** for data frames (search, filter, sort, pagination)
- **Export to CSV/Excel** with one click
- **Tabbed views** for lists (YAML + R structure)
- **Works everywhere** - VS Code, RStudio, Positron, terminal
- **Respects IDE viewers** - doesn't override `View()`

**When to use:**
- `View()` (IDE native) → Quick peek at data
- `view_detail()` → Deep exploration, export, complex objects

### 2. Create Notebooks & Scripts

Framework provides commands for creating files from templates:

```r
# Create a Quarto notebook (default)
make_notebook("1-exploration")  # → notebooks/1-exploration.qmd

# Convenient aliases for explicit types
make_qmd("analysis")            # → notebooks/analysis.qmd (always Quarto)
make_rmd("report")              # → notebooks/report.Rmd (always RMarkdown)

# Create presentations
make_revealjs("slides")         # → notebooks/slides.qmd (reveal.js presentation)
make_presentation("deck")       # → notebooks/deck.qmd (alias for make_revealjs)

# Create an R script
make_script("process-data")     # → scripts/process-data.R

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

**Configure default directories in settings.yml:**

```yaml
options:
  notebook_dir: "notebooks"  # Where make_notebook() creates notebook files
  script_dir: "scripts"      # Where make_script() creates script files
```

### 3. Load Data

**Via config:**
```yaml
# settings.yml or settings/data.yml
data:
  source:
    private:
      import:
        survey:
          path: data/source/private/survey.dta
          type: stata
          locked: true
```

```r
# Load using dot notation (follows YAML structure exactly)
df <- data_load("source.private.import.survey")

# If data_load() fails, it suggests available paths:
# Error: No data specification found for path: source.private.survey
#
# Available data paths:
#   source.private.import.survey
#   source.private.import.companies
#   ...
```

**Direct path:**
```r
df <- data_load("data/my_file.csv")       # CSV
df <- data_load("data/stata_file.dta")    # Stata
df <- data_load("data/spss_file.sav")     # SPSS
```

**Important:** Dot notation paths must match your YAML structure exactly. Each level in the YAML becomes a dot-separated part of the path. Use underscores for multi-word keys (e.g., `modeling_data`, not `modeling.data`).

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
# settings.yml (using clean env() syntax)
connections:
  db:
    driver: postgresql
    host: env("DB_HOST")
    database: env("DB_NAME")
    user: env("DB_USER")
    password: env("DB_PASS")
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

Reference in config (two syntaxes supported):
```yaml
# Recommended: Clean env() syntax
security:
  data_key: env("DATA_ENCRYPTION_KEY")
connections:
  db:
    host: env("DB_HOST")
    password: env("DB_PASS", "default_password")  # With default

# Also works: Traditional !expr syntax
security:
  data_key: !expr Sys.getenv("DATA_ENCRYPTION_KEY")
```

### AI Assistant Support

Framework can create instruction files that help AI coding assistants understand your project structure:

```r
# During CLI install, you'll be asked once about AI support
framework::cli_install()

# Reconfigure AI assistant preferences anytime
framework::configure_ai_agents()

# Or via CLI
framework configure ai-agents
```

Supported assistants:
- **Claude Code** (CLAUDE.md)
- **GitHub Copilot** (.github/copilot-instructions.md)
- **AGENTS.md** (cross-platform standard)

Your preferences are stored in `~/.frameworkrc` and used as defaults for new projects.

## Key Functions

| Function | Purpose |
|----------|---------|
| `scaffold()` | Initialize session (load packages, functions, config) |
| `data_load()` | Load data from path or config |
| `data_save()` | Save data with integrity tracking |
| `view_detail()` | Enhanced browser-based data viewer with search/export |
| `query_get()` | Execute SQL query, return data |
| `query_execute()` | Execute SQL command |
| `get_or_cache()` | Lazy evaluation with caching |
| `result_save()` | Save analysis output |
| `result_get()` | Retrieve saved result |
| `scratch_capture()` | Quick debug/temp file save |
| `cli_install()` | Install Framework CLI tool |
| `cli_uninstall()` | Remove Framework CLI tool |
| `cli_update()` | Update Framework and CLI to latest version |
| `renv_enable()` | Enable renv for reproducibility (opt-in) |
| `renv_disable()` | Disable renv integration |
| `packages_snapshot()` | Save package versions to renv.lock |
| `packages_restore()` | Restore packages from renv.lock |
| `security_audit()` | Scan for data leaks and security issues |

## Data Integrity & Security

- **Hash tracking**: All data files tracked with SHA-256 hashes
- **Locked data**: Flag files as read-only, errors on modification
- **Password-based encryption**: Ansible Vault-style encryption for sensitive data/results
- **Gitignore by default**: Private directories auto-ignored
- **Security audits**: Comprehensive security scanning with `security_audit()`

### Password-Based Encryption

Framework provides Ansible Vault-style password-based encryption for sensitive data and results. Files are encrypted using scrypt key derivation and ChaCha20-Poly1305 authenticated encryption.

**Setup:**

```r
# Option 1: Set password in .env file (recommended)
# Add to your .env file:
ENCRYPTION_PASSWORD=your-secure-password

# Option 2: Set in R session
Sys.setenv(ENCRYPTION_PASSWORD = "your-secure-password")

# Option 3: Interactive prompt (if not set, you'll be prompted)
```

**Encrypting data:**

```r
# Save encrypted data
my_data <- data.frame(ssn = c("123-45-6789", "987-65-4321"))
data_save(
  my_data,
  path = "sensitive.private.data",
  encrypted = TRUE  # Will prompt for password if not in env
)

# Or provide password directly
data_save(
  my_data,
  path = "sensitive.private.data",
  encrypted = TRUE,
  password = "specific-password"
)
```

**Loading encrypted data:**

```r
# Auto-detects encryption via magic bytes, prompts for password
data <- data_load("sensitive.private.data")

# Or provide password directly
data <- data_load("sensitive.private.data", password = "specific-password")
```

**Encrypting results (blinding):**

```r
# Save blinded result
model <- lm(mpg ~ wt, data = mtcars)
result_save(
  name = "regression_model",
  value = model,
  type = "model",
  blind = TRUE  # Encrypts the result
)

# Load blinded result (auto-detects encryption)
model <- result_get("regression_model")
```

**How it works:**
- Files are prefixed with `FWENC1` magic bytes for auto-detection
- Each encrypted file uses a unique random salt (same password = different ciphertext)
- Decryption automatically detects encrypted files - no flags needed
- Wrong password = clear error message

**Security notes:**
- Requires `sodium` package: `install.packages("sodium")`
- Password strength matters - use strong, unique passwords
- Share passwords securely (not in git commits!)
- Encrypted files are safe to commit, but manage passwords separately

### Security Auditing

Framework includes `security_audit()` to detect data leaks and security issues:

```r
# Run comprehensive security audit
audit <- security_audit()

# Quick audit (skip git history)
audit <- security_audit(check_git_history = FALSE)

# Auto-fix issues (updates .gitignore)
audit <- security_audit(auto_fix = TRUE)

# Limit git history depth for faster scanning
audit <- security_audit(history_depth = 100)
```

**What it checks:**
- **Gitignore coverage**: Verifies private data directories are in `.gitignore`
- **Private data exposure**: Detects if private data files are tracked by git
- **Git history leaks**: Scans commit history for accidentally committed sensitive data
- **Orphaned files**: Finds data files outside configured directories

**Example output:**
```r
=== Security Audit Summary ===

✓ PASS: gitignore coverage (0 issues)
✓ PASS: private data exposure (0 issues)
✗ FAIL: git history (2 issues)
⚠ WARNING: orphaned files (3 issues)

=== Recommendations ===

 : CRITICAL: Private data files found in git history!
 : Consider using git-filter-repo to remove sensitive data
 : Found 3 data file(s) outside configured directories
 : Move orphaned files to appropriate data directories

✗ AUDIT FAILED: Critical security issues found
```

**Results structure:**
```r
str(audit, max.level = 2)
# List of 4
#  $ summary        : data.frame with check names, status, counts
#  $ findings       : List of 4
#   ..$ gitignore_issues      : data.frame
#   ..$ git_history_issues    : data.frame
#   ..$ orphaned_files        : data.frame
#   ..$ private_data_exposure : data.frame
#  $ recommendations: Character vector of actionable fixes
#  $ audit_metadata : List with timestamp, framework version, config
```

**Integration with CI/CD:**
```r
# In your CI pipeline or pre-commit hook
audit <- security_audit(verbose = FALSE)
if (any(audit$summary$status == "fail")) {
  stop("Security audit failed! Review findings.")
}
```

## Reproducibility with renv

Framework includes **optional** [renv](https://rstudio.github.io/renv/) integration for package version control (OFF by default, opt-in):

### Quick Start

```r
# Enable renv for this project (one-time setup)
renv_enable()

# That's it! Framework handles the rest automatically:
# ✓ Installs framework, rmarkdown, and your settings.yml packages
# ✓ Creates renv.lock with exact versions
# ✓ Updates .gitignore to exclude renv cache
```

### How It Works

**When you enable renv:**
1. Framework automatically installs essential packages:
   - `framework` (from GitHub: table1/framework)
   - `rmarkdown` (needed by Quarto for R code chunks)
   - All packages listed in `settings.yml`

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

### Package Sources in settings.yml

Control package sources (CRAN, GitHub, Bioconductor) and version pins directly in config:

```yaml
packages:
  # CRAN packages (source defaults to cran)
  - name: dplyr
    auto_attach: true

  # Pin a specific CRAN version
  - name: ggplot2
    version: 3.4.0

  # GitHub packages
  - name: tidyverse/dplyr
    source: github
    ref: main

  # Bioconductor packages
  - name: DESeq2
    source: bioc
```

Prefer the structured form above for readability, but legacy shorthand strings still work (`"ggplot2@3.4.0"`, `"tidyverse/dplyr@main"`, `"bioc::DESeq2"`).

When you run `renv_enable()` or `packages_snapshot()`, Framework installs these exact versions and records them in `renv.lock` using the right installer for each source.

Package management should come almost for free, so Framework aims to handle all the messy details of `renv` so you can focus on your work.

See [renv integration docs](docs/features/renv_integration.md) for advanced usage.

## Roadmap

- **Better database support**: Support DuckDB, MySQL, SQL Server, and other Postgres-like databases.
- **Results tracking**: Save/retrieve analysis outputs with blinding support
- **Results publishing]**: Configure an S3 bucket and publish your notebooks with ease.
