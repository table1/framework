# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Documentation Standards

All development notes, debugging logs, and technical documentation should be placed in the `docs/` directory:

- **`docs/debug/`** - Bug reports, fix logs, debugging sessions
- **`docs/CLAUDE.md`** - Documentation standards and conventions for AI assistants
- **Root `CLAUDE.md`** - Project overview and getting started guide

Keep the root directory clean - move detailed notes to `docs/`.

## Project Overview

This is the **Framework** R package - a data management and project scaffolding system for reproducible data analysis workflows. Framework follows "convention over configuration" principles to help analysts quickly structure their projects with best practices.

**Framework is Quarto-first**: The package prioritizes Quarto for notebooks and documentation, with RMarkdown provided for backward compatibility.

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

### Make Targets (Makefile)
```bash
make help          # Show available targets
make build         # Build the package tarball
make install       # Install with tarball
make install-quick # Install without building tarball
make check         # Run R CMD check
make test          # Run tests
make docs          # Generate roxygen2 documentation
make clean         # Clean build artifacts
make release       # Full release workflow (clean, docs, test, check)
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

8. **Working Directory Utilities (`R/framework_util.R`)**
   - `standardize_wd()` function for normalizing working directory
   - Useful for Quarto/RMarkdown documents rendered from subdirectories
   - Auto-detects project root via config.yml, .Rproj, or common subdirectories
   - Sets both working directory and knitr's root.dir option

9. **renv Integration (`R/renv.R`, `R/packages.R`)** - NEW
   - **Optional** reproducibility via renv (OFF by default, opt-in)
   - `renv_enable()` and `renv_disable()` to toggle integration
   - Version pinning syntax in config.yml: `dplyr@1.1.0`, `user/repo@branch`
   - Package helpers: `packages_snapshot()`, `packages_restore()`, `packages_status()`, `packages_update()`
   - Educational messaging on first `scaffold()` (suppressible via `options: renv_nag: false`)
   - Smart routing: installs use renv when enabled, standard install.packages() otherwise
   - Abstracts renv complexity behind simple Framework functions

### Key Design Patterns

- **Convention over Configuration**: Standardized directory structures and naming
- **Template-Based Initialization**: `.fr` template files for project scaffolding
- **Modular Architecture**: Separate modules for each major functionality
- **Configuration-Driven**: YAML configs control behavior, package loading, and data specifications
- **Security-Conscious**: Separate public/private data handling, encryption support

### Template System

Templates use `.fr` suffix and are processed during `init()`:
- `.fr` files are processed and renamed (e.g., `project.fr.Rproj` → `{ProjectName}.Rproj`)
- `.fr.R` files have `.fr` stripped (e.g., `scaffold.fr.R` → `scaffold.R`)
- `.fr.qmd` files for Quarto notebooks (Quarto-first approach)
- `.fr.Rmd` files for RMarkdown notebooks (backward compatibility)
- `.fr.md` files for markdown templates
- `{subdir}` and `{ProjectName}` placeholders are substituted
- Template location: `inst/templates/`

### Project Structures

**Default Structure**: Full-featured with organized directories for data, work, functions, docs, results
**Minimal Structure**: Essential directories only for lightweight projects

## Configuration Files

### Key Configuration Locations
- Main config: `config.yml` (or `inst/config_skeleton.yml` as template)
- Multi-file configs: `settings/` directory (data.yml, packages.yml, connections.yml, etc.)
- Environment: `.env` file for secrets
- Framework database: `framework.db` for metadata tracking

### Default Connections
Both project structures include a pre-configured "framework" connection:
- Points to the local `framework.db` SQLite database
- Used for internal metadata tracking (data integrity, cache, results)
- Can be queried directly to inspect framework state
- Always available for testing database functionality

### Package Dependencies (from DESCRIPTION)
**Core Imports**: DBI, RSQLite, RPostgres, yaml, digest, glue, fs, readr, dotenv
**Development Suggests**: testthat, cyclocomp, usethis, styler, languageserver, devtools, sodium (encryption), httpgd (graphics device), DT (data tables)

## Development Notes

- Uses roxygen2 for documentation generation with markdown support
- Follows R package development conventions with NAMESPACE export management
- Includes comprehensive error handling and validation throughout
- Designed to be framework-agnostic - works with user's preferred R environment
- Git integration with `.gitignore` templates for data directories
- Package version: 0.1.0 (pre-release, API not yet stable)

### Function Naming Conventions

- Primary data functions use snake_case: `load_data()`, `save_data()`
- Internal implementation uses both patterns:
  - `data_load()` (internal) vs `load_data()` (exported alias)
  - This dual naming exists for backward compatibility

### Documentation Status

- No vignettes currently exist
- Documentation via:
  - README.md (user guide)
  - api.md (API reference)
  - CLAUDE.md (development context)
  - Roxygen2 man pages for all exported functions
- Consider adding vignettes for common workflows before 1.0

## Testing

### Testing Status

- `testthat` is configured (edition 3) in DESCRIPTION
- No tests currently exist in `tests/` directory
- Test templates provided in `inst/templates/`:
  - `test.fr.R` for basic functionality testing
  - `test-notebook.fr.qmd` for Quarto notebook workflow testing (primary)
  - `test-notebook.fr.Rmd` for RMarkdown notebook workflow testing (backward compatibility)
  - Both test notebooks query the framework.db SQLite database to demonstrate database functionality
- **Recommendation**: Implement comprehensive test suite before 1.0 release

## Framework Database Schema

The `framework.db` SQLite database contains:
- **data** table: Data integrity tracking (name, encrypted, hash, timestamps)
- **cache** table: Cache management (name, hash, expire_at, last_read_at, timestamps)
- **results** table: Results tracking (name, type, blind, comment, hash, timestamps)
- **metadata** table: Generic key-value storage
- Schema initialization: `inst/templates/init.sql`

## Known Considerations

- API is unstable (pre-1.0) - breaking changes expected
- No formal test suite yet
- `renv` support planned but not implemented
- Function `data_load()` exists internally but `load_data()` is the public API
- Encryption requires `sodium` package (in Suggests, not required)