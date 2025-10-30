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
├── inputs/
│   ├── private/raw/        # Raw data (gitignored)
│   ├── private/intermediate/ # Processed data (gitignored)
│   └── public/examples/    # Public example data
├── outputs/
│   ├── private/tables/     # Analysis outputs (gitignored)
│   ├── private/figures/    # Visualizations (gitignored)
│   ├── private/models/     # Saved models (gitignored)
│   ├── private/notebooks/  # Rendered notebooks (gitignored)
│   ├── private/cache/      # Computation cache (gitignored)
│   └── public/             # Public outputs
├── functions/              # Custom functions
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
