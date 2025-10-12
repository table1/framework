## Quick Start

**Three ways to start:** CLI tool (persistent), one-time script (no installation), or clone the template directly.

### Option 1: CLI Tool

**One-time setup:**

Start R, then:
```r
# Install Framework and the CLI
devtools::install_github("table1/framework")
framework::install_cli()
```

**Then create projects anywhere:**
```bash
framework new myproject
framework new slides presentation
framework new                      # Interactive mode
```

The CLI fetches and runs the latest template script from GitHub, so you're always creating projects with the current version.

### Option 2: One-Time Script (No CLI Installation)

**One-liner (macOS/Linux/Windows with Git Bash):**
```bash
curl -fsSL https://raw.githubusercontent.com/table1/framework-project/main/new-project.sh | bash
```

This guides you through creating a new project without installing the CLI.

### Option 3: Template From Git

**Step-by-step:**

1. Clone the template (edit `my-project` to your desired name):
```bash
git clone https://github.com/table1/framework-project my-project
```

2. Navigate into the project:
```bash
cd my-project
```

3. Start R and run setup:
```bash
R
```
Then in R:
```r
source("init.R")
```

### Option 4: Direct R Package Usage

```r
# Install package
devtools::install_github("table1/framework")

# Initialize in current directory
framework::init(
  project_name = "MyProject",
  type = "project",        # or "course" or "presentation"
  use_renv = FALSE,        # Set TRUE to enable renv
  attach_defaults = TRUE   # Auto-attach dplyr, tidyr, ggplot2
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
