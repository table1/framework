# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Documentation Standards

All development notes, debugging logs, and technical documentation should be placed in the `docs/` directory:

- **`docs/debug/`** - Bug reports, fix logs, debugging sessions
- **`docs/CLAUDE.md`** - Documentation standards and conventions for AI assistants
- **Root `CLAUDE.md`** - Project overview and getting started guide

Keep the root directory clean - move detailed notes to `docs/`.

### README Editing

Edit `README.md` directly. Keep it concise and focused on user-facing documentation.

**Pre-commit hook**: A git pre-commit hook at `.git/hooks/pre-commit` automatically rebuilds package documentation (`devtools::document()`) when R/ files are committed.

## Project Overview

This is the **Framework** R package - a data management and project scaffolding system for reproducible data analysis workflows. Framework follows "convention over configuration" principles to help analysts quickly structure their projects with best practices.

**Framework is Quarto-first**: The package prioritizes Quarto for notebooks and documentation, with RMarkdown provided for backward compatibility.

## GUI Development Workflow

The Framework GUI is developed in `gui-dev/` (Vue 3 + Tailwind) and served by R via httpuv.

### Iconography

- Prefer **Font Awesome Sharp Light** variants when choosing new icons so weights match existing design language.
- Keep SVGs inline (no external requests) and scope them to the consuming component rather than global assets.
- When adding filled/sharp icons, remember to expose `svgFill`, `svgStroke`, and related props so sections that still rely on outline icons remain unaffected.

**Development Setup (Auto-Reload):**

Run these two servers in separate terminals:

**Terminal 1** - Frontend dev server (port 5173):
```bash
cd gui-dev
npm run dev
```
→ Hot reload for UI changes

**Terminal 2** - Backend R server (port 8080, auto-restarts on R file changes):
```bash
cd gui-dev
npm install  # First time only
npm run dev:server
```
→ Automatically reloads when `R/` or `inst/plumber.R` files change
→ Uses nodemon to watch files and restart R process
→ **Note**: Vite may show proxy errors immediately after restart while R server is starting up - these are normal and will resolve once the R server finishes loading (typically 2-5 seconds)

**CRITICAL: DO NOT manually restart the R server when using `npm run dev:server`!**
- The server auto-restarts on file changes via nodemon
- Manual restarts will kill the auto-reload process
- Only restart manually if NOT using the dev:server script

**Alternative - Manual R Server (Old Way):**

If you prefer manual restarts or are using tmux:

```bash
# Stop, reload package, and restart in one command (without opening browser)
/opt/homebrew/bin/tmux send-keys -t fw:8 C-c && \
sleep 1 && \
/opt/homebrew/bin/tmux send-keys -t fw:8 'devtools::load_all()' Enter && \
sleep 2 && \
/opt/homebrew/bin/tmux send-keys -t fw:8 'gui(browse = FALSE)' Enter
```

Or run directly:
```bash
cd gui-dev
Rscript start-server.R
```

**Deploying UI Changes:**

After making frontend changes, build and deploy to the R package:

```bash
cd gui-dev && npm run deploy
```

This builds the Vue app and copies assets to `inst/gui/` for distribution.

### GUI Documentation Database

**CRITICAL: When modifying the public API, you MUST regenerate docs.db!**

The GUI's documentation browser reads from `docs.db`, a SQLite database generated from roxygen2 documentation. This database must be regenerated whenever you:
- Add, remove, or rename exported functions
- Change a function from `@export` to `@keywords internal` (or vice versa)
- Modify `inst/docs-export/categories.yml` (function categories/groupings)
- Update function documentation that should appear in the GUI

**To regenerate docs.db and update all sites:**
```bash
# One-liner to regenerate and deploy docs everywhere
cd /Users/erikwestlund/code/framework && \
R -e "devtools::document(); devtools::load_all(); docs_export()" && \
cp docs.db inst/gui/docs.db && \
cp docs.db gui-dev/public/docs.db && \
cp docs.db ~/code/framework-site/storage/docs.db && \
cd ~/code/framework-site && php artisan framework:import-docs --fresh
```

Or step by step:
```bash
# 1. Generate docs.db
cd /Users/erikwestlund/code/framework
R -e "devtools::document(); devtools::load_all(); docs_export()"

# 2. Copy to GUI locations
cp docs.db inst/gui/docs.db
cp docs.db gui-dev/public/docs.db

# 3. Import into framework-site (Statamic)
cp docs.db ~/code/framework-site/storage/docs.db
cd ~/code/framework-site && php artisan framework:import-docs --fresh
```

**Category configuration**: Edit `inst/docs-export/categories.yml` to control:
- Which categories appear in the sidebar
- Which functions appear in each category
- Which functions are marked as "common" (appear at top)

**Verification**: After regenerating, check the categories are correct:
```bash
sqlite3 inst/gui/docs.db "SELECT name FROM categories ORDER BY position"
```

**CRITICAL: ALWAYS regenerate docs.db when:**
- Adding, removing, or renaming exported functions
- Changing `@export` to `@keywords internal` (or vice versa)
- Modifying roxygen2 documentation (titles, descriptions, parameters)
- Editing `inst/docs-export/categories.yml`

The GUI reads documentation from docs.db, NOT from the .Rd files directly. If you forget to regenerate, the GUI will show stale documentation.

## Configuration System

### Global Configuration (All YAML)

Framework now uses **all-YAML configuration** for consistency across global and project settings.

**Global Config Location**: `~/.config/framework/`
- `config.yml` - User defaults (author, preferences, default packages, etc.)
- `projects.yml` - Project registry
- `settings-catalog.yml` - Templates/schema (copied from package on first run)

**Auto-initialization**: If no global config exists, Framework automatically creates it from `inst/settings/global-settings-default.yml` on first run (GUI launch or `framework::init_global_config()`).

**Why YAML everywhere**:
- Consistency - one parser, one format, fewer edge cases
- Comments supported - crucial for user-editable config files
- Same structure for global defaults and project settings
- No conversion logic needed between formats

**Legacy migration**: Old `~/.frameworkrc.json` files are automatically migrated to the new YAML format on first read.

## Configuration Philosophy

**CRITICAL: When adding new configurable settings, ALWAYS follow this pattern:**

1. **Add to global defaults** (`inst/settings/global-settings-default.yml`):
   - Add `FW_*` environment variable with sensible default
   - Document in comments what the setting controls
   - Example: `FW_SEED="20241016"  # Random seed for reproducibility`

2. **Add to project templates** (all three `config.yml` files):
   - `inst/project_structure/project/config.yml`
   - `inst/project_structure/course/config.yml`
   - `inst/project_structure/presentation/config.yml`
   - Include inline comments explaining the setting
   - Reference global fallback in comments

3. **Implement resolution logic** (in relevant R function):
   - Check project config first: `config$setting_name`
   - Fall back to global: `Sys.getenv("FW_SETTING_NAME", "")`
   - Provide sensible default if neither exists
   - Example: `.set_random_seed()` in `R/scaffold.R`

4. **Document the hierarchy** (in this CLAUDE.md):
   - Add to "Configuration Locations & Hierarchy" section
   - Include resolution order example
   - Explain when each tier is used

This pattern ensures consistency and predictability across Framework.

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

### Documentation Update Checklist

**CRITICAL: When adding or modifying exported functions, ALWAYS update:**

1. **inst/templates/framework-cheatsheet.md** - User-facing quick reference (gets copied to new projects)
   - Add function to appropriate section with brief comment
   - Add to alphabetical function reference table

2. **README.md** - Update the relevant section directly
   - Keep examples current and concise

3. **docs/*.md** - Topic-specific documentation
   - Update relevant guides (e.g., `docs/make_notebook.md`)
   - Add usage examples and edge cases

4. **R function roxygen2 comments** - Document with examples and seealso links

**Quick verification:**
```bash
# Check if function appears in cheatsheet
grep "function_name" inst/templates/framework-cheatsheet.md

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
   - **Sets random seed** for reproducibility (project config → global fallback → skip)
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

10. **Quarto Configuration Generation (`R/quarto_generate.R`)** - NEW
   - **Write once, user owns it**: `_quarto.yml` files generated on project creation, never auto-regenerated
   - **Hierarchical configuration**: Project root + directory-specific configs (inherits from root)
   - **Format-specific defaults**: HTML for notebooks/docs, revealjs for slides/presentations
   - **Global defaults**: Settings from `~/.config/framework/settings.yml` → `defaults.quarto`
   - **Manual regeneration**: Optional "Regenerate Quarto Configs" in GUI (warns about overwriting)
   - **Auto-generated header**: Files include comment noting they're auto-generated and safe to edit
   - **Project type awareness**: Generates configs for render directories based on project type:
     - **project**: notebooks, docs render directories
     - **project_sensitive**: notebooks, docs render directories
     - **course**: slides, assignments, course_docs, modules render directories
     - **presentation**: root directory (single presentation.qmd)

### Key Design Patterns

- **Convention over Configuration**: Standardized directory structures and naming
- **Template-Based Initialization**: `.fr` template files for project scaffolding
- **Modular Architecture**: Separate modules for each major functionality
- **Configuration-Driven**: YAML configs control behavior, package loading, and data specifications
- **Security-Conscious**: Separate public/private data handling, encryption support

### Template System

Templates are stored in `inst/templates/` and copied to new projects:
- `project.Rproj` → renamed to `{ProjectName}.Rproj`
- `scaffold.R` → copied as-is
- `settings.*.yml` → copied as `settings.yml` based on project type
- AI context templates (`ai-context.*.md`) → used to generate AI instructions
- `{subdir}` and `{ProjectName}` placeholders are substituted in file content

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
    inputs_raw: inputs/raw
    inputs_intermediate: inputs/intermediate
    inputs_final: inputs/final
    inputs_reference: inputs/reference
    outputs_private: outputs/private
    outputs_public: outputs/public
    outputs_docs: outputs/private/docs
    outputs_docs_public: outputs/public/docs
    cache: outputs/private/cache
    scratch: outputs/private/scratch

  # Packages
  packages:
    - dplyr
    - ggplot2

  # Simple data catalog
  data:
    inputs.raw.example:
      path: inputs/raw/example.csv
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
    cache: outputs/private/cache

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
config("cache")                  # → "outputs/private/cache"

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

### Configuration Locations & Hierarchy

Framework uses a **three-tier configuration hierarchy** for maximum flexibility:

**1. Project-Level Config** (`config.yml`) - Highest Priority
- Created during `init()` in each project
- Project-specific settings (seed, packages, directories, data catalog, etc.)
- Overrides global defaults

**2. Global User Config** (`~/.frameworkrc`) - Fallback Defaults
- User-wide preferences applied to ALL new projects
- Settings include:
  - `FW_SEED`: Default random seed (YYYYMMDD format recommended)
  - `FW_AUTHOR_NAME`, `FW_AUTHOR_EMAIL`, `FW_AUTHOR_AFFILIATION`: Author info
  - `FW_DEFAULT_FORMAT`: Default notebook format (quarto or rmarkdown)
  - `FW_IDES`: IDE preferences (vscode, rstudio, both, none)
  - `FW_AI_SUPPORT`, `FW_AI_ASSISTANTS`: AI assistant configuration
- Updated via `framework::setup()` or by editing `~/.frameworkrc` directly

**3. Package Defaults** - Last Resort
- Built into Framework package
- Used only when neither project nor global config specifies a value

**Resolution Order Examples:**

```r
# Random seed resolution (in scaffold())
1. Check config$seed in project config.yml
2. Fall back to Sys.getenv("FW_SEED") from ~/.frameworkrc
3. Skip seeding if neither is set

# Author information resolution (in init())
1. Check explicit parameters: init(author_name = "...")
2. Fall back to Sys.getenv("FW_AUTHOR_NAME") from ~/.frameworkrc
3. Use placeholder "Your Name" from package defaults
```

**File Locations:**
- **Project config**: `./config.yml` (created by `init()`)
- **Global config**: `~/.frameworkrc` (managed by `setup()`)
- **Split files**: `./settings/` directory (optional, for complex projects)
- **Environment secrets**: `.env` file (gitignored)
- **Metadata tracking**: `framework.db` (SQLite database)

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

**CRITICAL: Namespaced functions are ALWAYS primary, non-namespaced are aliases for backward compatibility.**

Framework uses a consistent naming pattern where namespaced functions (with prefixes like `data_`, `result_`, `cache_`) are the primary API:

**Primary (Namespaced)**:
- `data_read()`, `data_save()`, `data_list()`
- `result_save()`, `result_get()`, `result_list()`
- `cache_fetch()`, `cache_get()`, `cache_flush()`
- `query_get()`, `query_execute()`
- `scratch_capture()`, `scratch_clean()`

**Aliases (Backward Compatibility)**:
- `data_load()` → `data_read()` (legacy name)
- `load_data()` → `data_read()`
- `read_data()` → `data_read()`
- `save_data()` → `data_save()`
- `list_data()` → `data_list()`

**When creating new functions:**
1. Always define the namespaced version first as the primary function
2. Add backward compatibility alias afterward if needed
3. Document the alias relationship in roxygen comments
4. Export both functions

### Documentation Status

- No vignettes currently exist
- Documentation via:
  - README.md (user guide)
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
  - `test.R` for basic functionality testing
  - Test notebooks query the framework.db SQLite database to demonstrate database functionality

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
- **Canonical function naming**: Use `data_read()` as primary (not `data_load()` or `load_data()`)
  - `data_load()`, `load_data()`, `read_data()` are backward-compatible aliases
  - Use `result_save()`, `result_get()`, `result_list()` (not `save_result`, `get_result`, `list_results`)
  - Use `query_get()`, `query_execute()` (not `get_query`, `execute_query`)
  - Use `scratch_capture()`, `scratch_clean()` (not `capture`, `clean_scratch`)
- Encryption requires `sodium` package (in Suggests, not required)
