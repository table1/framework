# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **Framework** R package - a data management and project scaffolding system for reproducible data analysis workflows. Framework follows "convention over configuration" principles to help analysts quickly structure their projects with best practices.

## Package Development Commands

### Building and Testing
```bash
# Build the package
R CMD build .

# Check the package (comprehensive testing)
R CMD check framework_0.1.0.tar.gz

# Install the package locally
R CMD INSTALL .

# Load and test in R session
R -e "library(framework); packageVersion('framework')"
```

### Documentation
```bash
# Generate documentation from roxygen2 comments
R -e "devtools::document()"

# Install and rebuild documentation
R -e "devtools::install(quick = TRUE)"
```

### Code Quality
```bash
# Run linting
R -e "lintr::lint_package()"

# Run styler for code formatting
R -e "styler::style_pkg()"

# Check code complexity
R -e "cyclocomp::cyclocomp_package()"
```

## Architecture Overview

### Core Components

1. **Project Initialization (`R/init.R`)**
   - `init()` function creates new projects with standardized structure
   - Uses templates from `inst/templates/` and structures from `inst/project_structure/`
   - Supports both "default" and "minimal" project structures

2. **Environment Scaffolding (`R/scaffold.R`)**
   - `scaffold()` function loads project environment
   - Handles environment variables, configuration, package installation/loading
   - Sources all `.R` files from `functions/` directory
   - Executes project-specific `scaffold.R` if present

3. **Configuration Management (`R/config.R`)**
   - YAML-based configuration system using `config` package
   - Supports both single-file (`config.yml`) and multi-file (`settings/*.yml`) approaches
   - Environment variable interpolation via `dotenv`

4. **Data Management (`R/data_*.R`)**
   - `data_read.R`, `data_write.R`, `data_encrypt.R`
   - Declarative data cataloguing with integrity tracking
   - Support for CSV, RDS formats with encryption capabilities
   - Dot-notation data paths (e.g., `source.private.my_data`)

5. **Database Layer (`R/connections_*.R`, `R/queries.R`)**
   - SQLite and PostgreSQL support
   - Connection management through configuration
   - Query execution helpers (`get_query()`, `execute_query()`)

6. **Caching System (`R/cache_*.R`)**
   - File-based caching with expiration support
   - Hash verification for integrity
   - Smart caching with `get_or_cache()` for expensive computations

7. **Framework Database (`R/framework_db.R`)**
   - SQLite-based metadata tracking
   - Data integrity verification via digests
   - Results and cache management

### Key Design Patterns

- **Convention over Configuration**: Standardized directory structures and naming
- **Template-Based Initialization**: `.fr` template files for project scaffolding
- **Modular Architecture**: Separate modules for each major functionality
- **Configuration-Driven**: YAML configs control behavior, package loading, and data specifications
- **Security-Conscious**: Separate public/private data handling, encryption support

### Template System

Templates use `.fr` suffix and are processed during `init()`:
- `project.fr.Rproj` → `{ProjectName}.Rproj`
- `.lintr.default.fr` → `.lintr`
- `.styler.default.fr.R` → `.styler.R`
- `{subdir}` placeholder substitution in YAML files

### Project Structures

**Default Structure**: Full-featured with organized directories for data, work, functions, docs, results
**Minimal Structure**: Essential directories only for lightweight projects

## Configuration Files

### Key Configuration Locations
- Main config: `config.yml` (or `inst/config_skeleton.yml` as template)
- Multi-file configs: `settings/` directory (data.yml, packages.yml, connections.yml, etc.)
- Environment: `.env` file for secrets
- Framework database: `framework.db` for metadata tracking

### Package Dependencies (from DESCRIPTION)
**Core Imports**: DBI, RSQLite, RPostgres, yaml, digest, glue, fs, readr, dotenv
**Development Suggests**: testthat, cyclocomp, usethis, styler, languageserver, devtools

## Development Notes

- Uses roxygen2 for documentation generation with markdown support
- Follows R package development conventions with NAMESPACE export management
- Includes comprehensive error handling and validation throughout
- Designed to be framework-agnostic - works with user's preferred R environment
- Git integration with `.gitignore` templates for data directories

## Testing

The package includes test templates in `inst/templates/`:
- `test.fr.R` for basic functionality testing
- `test-notebook.fr.Rmd` for notebook workflow testing
- Test framework integration via `testthat` (mentioned in Suggests)