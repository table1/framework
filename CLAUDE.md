# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Documentation Standards

All development notes, debugging logs, and technical documentation should be placed in the `docs/` directory:

- **`docs/debug/`** - Bug reports, fix logs, debugging sessions
- **`docs/CLAUDE.md`** - Documentation standards and conventions for AI assistants
- **Root `CLAUDE.md`** - Project overview and getting started guide

Keep the root directory clean - move detailed notes to `docs/`.

### README Editing Policy

**CRITICAL: NEVER edit `README.md` directly!**

The README uses a modular parts system located in `readme-parts/`:

- **To edit README content**: Edit the appropriate numbered part file (e.g., `2_quickstart.md`, `4_usage_notebooks.md`)
- **To rebuild README**: Run `Rscript readme-parts/build.R`
- **Parts structure**:
  - `1_header.md` - Title and description
  - `2_quickstart.md` - Installation and project types
  - `3_workflow_intro.md` - Core workflow intro
  - `4_usage_notebooks.md` - **SHARED CONTENT** - make_notebook() documentation (also used in framework-project)
  - `5_usage_data.md` - Data loading, caching, results (steps 3-6)
  - `6_rest.md` - Configuration, functions, security, etc.

**IMPORTANT**: This is the source of truth for readme-parts/. The framework-project repo gitignores readme-parts/ and only includes the built README.md.

**Pre-commit hook**: A git pre-commit hook automatically:
- Rebuilds package documentation (`devtools::document()`) when R/ files are committed
- Rebuilds README.md when readme-parts/ files are committed
- **Auto-syncs `2_quickstart.md`** to framework-project and rebuilds its README
- Hook location: `.git/hooks/pre-commit`

See `readme-parts/README.md` and `docs/readme-parts-guide.md` for complete documentation.

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

# Rebuild README from parts
Rscript readme-parts/build.R

# Install and rebuild documentation
R -e "devtools::install(quick = TRUE)"
```

### Documentation Update Checklist

**CRITICAL: When adding or modifying exported functions, ALWAYS update:**

1. **inst/templates/framework-cheatsheet.fr.md** - User-facing quick reference (gets copied to new projects)
   - Add function to appropriate section with brief comment
   - Add to alphabetical function reference table

2. **readme-parts/4_usage_notebooks.md** - If function is related to notebooks/scripts
   - Update examples in "Create Notebooks & Scripts" section
   - Keep content synchronized with framework-project template

3. **docs/*.md** - Topic-specific documentation
   - Update relevant guides (e.g., `docs/make_notebook.md`)
   - Add usage examples and edge cases

4. **README.md** - Rebuild after editing parts:
   ```bash
   Rscript readme-parts/build.R
   ```

5. **R function roxygen2 comments** - Document with examples and seealso links

**Quick verification:**
```bash
# Check if function appears in cheatsheet
grep "function_name" inst/templates/framework-cheatsheet.fr.md

# Rebuild README to catch any part file changes
Rscript readme-parts/build.R

# Regenerate R docs
R -e "devtools::document()"
```

### Code Quality
```bash
# Run linting
R -e "lintr::lint_package()"

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
   - Supports "project", "course", and "presentation" project types
   - **Auto-archives init.R**: After successful initialization, `init.R` is archived to `.init.R.done` with documentation comments
   - Archive preserves reproducibility while cleaning working directory
   - Follows Zen Consensus recommendation (Gemini + Claude Sonnet)

2. **Environment Scaffolding (`R/scaffold.R`)**
   - `scaffold()` function loads project environment
   - Handles environment variables, configuration, package installation/loading
   - Sources all `.R` files from `functions/` directory
   - Executes project-specific `scaffold.R` if present

3. **Configuration Management (`R/config.R`)** - **RECENTLY OVERHAULED**
   - **Laravel-inspired hybrid config system** with bulletproof resolution
   - **`config()` helper** with dot-notation access: `config("notebooks")`, `config("connections.db.host")`
   - **Directories inline** in main `config.yml` for discoverability (R ecosystem convention)
   - **Split files optional** for complex domain-specific settings (data catalog, connections)
   - **Smart lookups**: `config("notebooks")` checks `directories$notebooks` then `options$notebook_dir` (legacy)
   - **Backward compatible** with old `options$notebook_dir` structure
   - **Comprehensive test coverage**: 74 passing tests for flat/split/legacy resolution
   - YAML-based using `config` package with environment variable interpolation via `dotenv`

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

## Configuration System

### Overview

Framework uses a **Laravel-inspired hybrid configuration system** that prioritizes discoverability while allowing scalability. The system supports both flat files (everything in one `config.yml`) and split files (domain-specific settings in `settings/*.yml`).

**Design Philosophy:**
- **Simple by default**: Most users work with a single `config.yml` file
- **Complex when needed**: Split files for data catalogs, connections, etc.
- **Discoverable**: Directory paths visible immediately in main file
- **R conventions**: Follows R ecosystem pattern of single primary config (like `_targets.R`, `_bookdown.yml`)

### Config Structure

**Flat File Approach** (Recommended for most projects):
```yaml
default:
  project_type: project

  # Core directories (inline for discoverability)
  directories:
    notebooks: notebooks
    scripts: scripts
    functions: functions
    results_public: results/public
    results_private: results/private
    cache: data/cached
    scratch: data/scratch

  # Packages
  packages:
    - dplyr
    - ggplot2

  # Simple data catalog
  data:
    example:
      path: data/example.csv
      type: csv
```

**Split File Approach** (For complex projects):
```yaml
default:
  project_type: project

  # Directories stay inline (most commonly changed)
  directories:
    notebooks: notebooks
    scripts: scripts
    functions: functions
    cache: data/cached

  # Complex settings reference split files
  data: settings/data.yml           # Large data catalog
  packages: settings/packages.yml   # Package specifications
  connections: settings/connections.yml  # Database connections
  git: settings/git.yml
  security: settings/security.yml
```

### The config() Helper

**Laravel-style dot-notation access:**

```r
# Smart lookups (checks multiple locations)
config("notebooks")              # → "notebooks" (from directories$notebooks)
config("scripts")                # → "scripts"
config("cache")                  # → "data/cached"

# Explicit nested paths
config("directories.notebooks")  # → "notebooks"
config("connections.db.host")    # → "localhost"
config("data.example.path")      # → "data/example.csv"

# With default values
config("nonexistent", default = "fallback")  # → "fallback"

# Returns NULL for missing keys
config("missing.key")            # → NULL
```

**Smart Directory Resolution:**
- `config("notebooks")` automatically checks:
  1. `directories$notebooks` (new structure)
  2. `options$notebook_dir` (legacy structure)
- Prioritizes new structure when both exist
- Fully backward compatible

### Config Precedence and Conflict Resolution

**Core Rule: Main file ALWAYS wins** ✅

When the same key exists in both `config.yml` and a split file (e.g., `settings/connections.yml`), Framework follows a strict precedence rule based on Zen Consensus (Gemini + Claude):

**Precedence Order:**
1. **Main config.yml** - Takes absolute precedence
2. **Split files** - Only used when key is not in main config
3. **Package defaults** - Used when key is missing entirely

**Scoped Include Rules:**

Split files should ONLY contain keys for their designated section plus `options:`:

**Valid split file structure** (settings/connections.yml):
```yaml
connections:           # ✅ Expected - matches the section name
  db:
    host: localhost
    port: 5432

options:               # ✅ Expected - connection-specific options
  default_connection: db
```

**Invalid split file structure** (settings/connections.yml):
```yaml
connections:
  db:
    host: localhost

default_connection: db  # ❌ Unexpected - top-level key in split file
cache_enabled: true     # ❌ Unexpected - unrelated key
```

**Conflict Detection:**

Framework emits **warnings** for two scenarios:

1. **Scoped include violation** - Split file contains unexpected keys:
   ```
   Warning: Split file 'settings/connections.yml' contains unexpected keys:
   default_connection, cache_enabled. Only 'connections' and 'options' keys
   should be present in this file. Unexpected keys will be ignored.
   ```

2. **Main file conflict** - Both files define the same key:
   ```
   Warning: Key 'default_connection' defined in both config.yml and
   'settings/connections.yml'. Using value from config.yml (main file
   takes precedence).
   ```

**Why This Matters:**

- **Predictable behavior**: Main config is single source of truth
- **Prevents silent conflicts**: Database connections, critical settings won't be accidentally overridden
- **Encourages good practices**: Split files for organization, not override
- **Discoverable**: Warnings guide users to fix misconfigurations

**Example - Conflict Scenario:**

```yaml
# config.yml
default:
  connections: settings/connections.yml
  default_connection: primary_db  # ← Main file value
```

```yaml
# settings/connections.yml
connections:
  primary_db:
    host: localhost
  backup_db:
    host: backup.example.com

default_connection: backup_db  # ← Split file tries to override (IGNORED!)
```

**Result:**
- `config("default_connection")` returns `"primary_db"` (from main config)
- Warning emitted about conflict
- Split file's `default_connection` is ignored

**Best Practice:**

Keep top-level configuration keys in `config.yml`:
```yaml
# config.yml - Single source of truth for top-level keys
default:
  directories: { notebooks: notebooks, scripts: scripts }
  connections: settings/connections.yml
  default_connection: primary_db    # ← Keep here
  cache_enabled: true               # ← Keep here
  project_type: project             # ← Keep here
```

### Configuration Locations
- **Main config**: `config.yml` (created by `init()`)
- **Split files**: `settings/` directory (optional, for complex projects)
- **Environment variables**: `.env` file for secrets (gitignored)
- **Framework database**: `framework.db` for metadata tracking
- **Package defaults**: Built into Framework, auto-fill missing values

### Default Connections
Both project structures include a pre-configured "framework" connection:
- Points to the local `framework.db` SQLite database
- Used for internal metadata tracking (data integrity, cache, results)
- Can be queried directly to inspect framework state
- Always available for testing database functionality

### Package Dependencies (from DESCRIPTION)
**Core Imports**: DBI, RSQLite, RPostgres, yaml, digest, glue, fs, readr, dotenv
**Development Suggests**: testthat, cyclocomp, usethis, languageserver, devtools, sodium (encryption), httpgd (graphics device), DT (data tables)

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

**Current Status: 302 Passing Tests, 0 Failures** ✅

- `testthat` is configured (edition 3) in DESCRIPTION
- **Comprehensive test suite** in `tests/testthat/`:
  - `test-config.R` - 20+ tests for config resolution (flat, split, legacy, smart lookups)
  - `test-make_notebook.R` - Directory detection and notebook creation
  - `test-data.R` - Data loading, saving, cataloging
  - `test-cache.R` - Caching system
  - `test-results.R` - Results management
  - `test-queries.R` - Database queries
  - `test-scratch.R` - Scratch file management
  - `test-init.R` - Project initialization
  - `test-renv.R` - renv integration
  - And more...
- Test templates provided in `inst/templates/`:
  - `test.fr.R` for basic functionality testing
  - `test-notebook.fr.qmd` for Quarto notebook workflow testing (primary)
  - `test-notebook.fr.Rmd` for RMarkdown notebook workflow testing (backward compatibility)
  - Both test notebooks query the framework.db SQLite database to demonstrate database functionality

### Config System Testing

**Bulletproof resolution** with 20+ dedicated tests covering:
- ✅ Flat config with inline directories
- ✅ Split file approach (data, connections in separate files)
- ✅ `config()` helper with dot-notation access
- ✅ Smart lookups checking multiple locations
- ✅ Legacy backward compatibility (`options$notebook_dir`)
- ✅ Priority resolution (new structure over legacy)
- ✅ All three project types (project, course, presentation)
- ✅ Nested path access (`connections.db.host`)
- ✅ Default values and NULL handling
- ✅ Integration with `make_notebook()` directory detection

## Framework Database Schema

The `framework.db` SQLite database contains:
- **data** table: Data integrity tracking (name, encrypted, hash, timestamps)
- **cache** table: Cache management (name, hash, expire_at, last_read_at, timestamps)
- **results** table: Results tracking (name, type, blind, comment, hash, timestamps)
- **metadata** table: Generic key-value storage
- Schema initialization: `inst/templates/init.sql`

## Known Considerations

- API is unstable (pre-1.0) - breaking changes expected
- **Config system is production-ready** with comprehensive test coverage (74 tests passing)
- `renv` support is **implemented and tested** (opt-in, disabled by default)
- **Alias cleanup completed**: Removed 8 backward-compatibility aliases, kept only `load_data()`/`save_data()`
  - Use `result_save()`, `result_get()`, `result_list()` (not `save_result`, `get_result`, `list_results`)
  - Use `query_get()`, `query_execute()` (not `get_query`, `execute_query`)
  - Use `scratch_capture()`, `scratch_clean()` (not `capture`, `clean_scratch`)
- Encryption requires `sodium` package (in Suggests, not required)