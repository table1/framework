## Quick Start

**Preview:** During setup, you'll be asked to choose:
- **Project type** - `project` (full-featured), `course` (teaching), or `presentation` (single talk)
- **Notebook format** - Quarto `.qmd` (recommended) or RMarkdown `.Rmd`
- **Package management** - Whether to renv for reproducibility or standard R packages

Not sure? The defaults work great. You can always change these later in `config.yml`.

### Option 1: CLI Tool (Recommended)

**One-command install:**

```bash
curl -fsSL https://raw.githubusercontent.com/table1/framework/main/inst/bin/install-cli.sh | bash
```

This installs both the Framework R package and the CLI tool, and sets up your PATH.

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
  type = "project",        # or "course" or "presentation"
  use_renv = FALSE,
  default_notebook_format = "quarto",
  author_name = "Your Name",  # Optional
  author_email = "email@example.com",  # Optional
  author_affiliation = "Johns Hopkins University"  # Optional
)

# Then run your code from your IDE. Or save your changes and run:
source("init.R")
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
│   ├── cached/             # Computation cache (gitignored)
│   └── final/private/      # Results (gitignored)
├── functions/              # Custom functions
├── results/private/        # Analysis outputs (gitignored)
├── docs/                   # Documentation
├── config.yml              # Project configuration
├── framework.db            # Metadata/tracking database
└── .env                    # Secrets (gitignored)
```
