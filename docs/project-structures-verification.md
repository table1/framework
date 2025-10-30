# Framework Project Structures Verification

**Date**: 2025-10-30
**Framework Version**: 0.9
**Test Location**: `/private/tmp/fw-projects/`

This document captures the exact directory and file structure for each Framework project type after the config system rework.

---

## Project Type: `project` (Default/Analysis)

### Directory Tree
```
.
├── docs/
│   └── .gitkeep
├── functions/                       # Empty directory for user functions
├── inputs/
│   ├── public/
│   │   ├── examples/
│   │   │   └── .gitkeep
│   │   └── .gitkeep
│   └── .gitkeep
├── notebooks/
│   ├── .gitkeep
│   └── example-notebook.qmd
├── resources/
│   └── .gitkeep
├── scripts/
│   ├── .gitkeep
│   └── example-script.R
├── settings/                        # Split config files
│   ├── ai.yml
│   ├── author.yml
│   ├── connections.yml
│   ├── data.yml
│   ├── directories.yml
│   ├── git.yml
│   ├── notebook.yml
│   ├── options.yml
│   ├── packages.yml
│   └── security.yml
├── _quarto.yml
├── .editorconfig
├── .git/                            # Git repository initialized
├── .gitignore
├── .lintr
├── framework-cheatsheet.md
├── framework.db                     # SQLite database for metadata
├── README.md
├── scaffold.R
├── settings.json                    # VS Code settings
├── settings.yml                     # Main config (delegates to settings/)
└── {project-name}.Rproj
```

**Total**: 10 directories, 30 files

### Configuration Structure

**Main Config (`settings.yml`)**:
```yaml
default:
  project_type: project

  # Delegated configuration (split files)
  author: settings/author.yml
  packages: settings/packages.yml
  directories: settings/directories.yml
  options: settings/options.yml
  data: settings/data.yml
  connections: settings/connections.yml
  security: settings/security.yml
  ai: settings/ai.yml
  git: settings/git.yml
```

**Directory Configuration (`settings/directories.yml`)**:
```yaml
directories:
  # Source code
  notebooks: notebooks
  scripts: scripts
  functions: functions

  # Inputs (read-only)
  inputs_raw: inputs/private/raw
  inputs_intermediate: inputs/private/intermediate
  inputs_examples: inputs/public/examples

  # Outputs (write-only)
  outputs_tables: outputs/private/tables
  outputs_figures: outputs/private/figures
  outputs_models: outputs/private/models
  outputs_notebooks: outputs/private/notebooks
  outputs_tables_public: outputs/public/tables
  outputs_figures_public: outputs/public/figures
  outputs_models_public: outputs/public/models
  outputs_notebooks_public: outputs/public/notebooks

  # Legacy paths
  cache: outputs/private/cache
  scratch: outputs/private/scratch
```

### Test Results
✅ `scaffold()` - Loads successfully, sets seed
✅ `config("notebooks")` → `"notebooks"`
✅ `config("scripts")` → `"scripts"`
✅ `config("project_type")` → `"project"`
✅ `make_notebook("test")` → Creates `notebooks/test-analysis.qmd`

---

## Project Type: `course`

### Directory Tree
```
.
├── docs/
│   └── .gitkeep
├── functions/                       # Empty directory for course functions
├── resources/
│   └── .gitkeep
├── settings/                        # Minimal split files (not all 10)
│   ├── connections.yml
│   ├── data.yml
│   ├── git.yml
│   ├── packages.yml
│   └── security.yml
├── slides/
│   ├── .gitkeep
│   └── 01-intro.qmd                 # Example intro slide
├── _quarto.yml
├── .editorconfig
├── .git/
├── .gitignore
├── .lintr
├── framework-cheatsheet.md
├── framework.db
├── README.md
├── scaffold.R
├── settings.json
├── settings.yml                     # Flat config (NO delegation)
└── {project-name}.Rproj
```

**Total**: 6 directories, 20 files

### Configuration Structure

**Main Config (`settings.yml`)** - **FLAT (Inline)**:
```yaml
default:
  project_type: course

  # Inline author info
  author:
    name: "Test User"
    email: "instructor@university.edu"
    affiliation: "University Name"

  # Inline packages
  packages:
    - name: dplyr
      auto_attach: true
    - name: ggplot2
      auto_attach: true
    - name: quarto
      auto_attach: false
    - name: knitr
      auto_attach: false
    - name: rmarkdown
      auto_attach: false

  # Inline directories
  directories:
    slides: slides
    notebooks: notebooks
    scripts: scripts
    functions: functions
    outputs: outputs

  # Behavior
  default_notebook_format: quarto
  seed: 1234
  seed_on_scaffold: true

  # Inline data catalog
  data: {}

  # Inline connections
  connections: {}

  # Security
  security:
    data_key: !expr Sys.getenv("DATA_ENCRYPTION_KEY", "")

  # AI config
  ai:
    canonical_file: ""

  # Git hooks
  git:
    hooks:
      ai_sync: false
      data_security: false
```

**Note**: Course uses **flat config** (everything inline) vs project's **delegated config** (split files).

### Test Results
✅ `scaffold()` - Loads successfully
✅ `config("slides")` → `"slides"`
✅ `config("project_type")` → `"course"`
✅ `make_notebook("lecture-02")` → Creates `notebooks/lecture-02.qmd`
⚠️  Note: Course doesn't have a dedicated slides directory by default, uses notebooks/

---

## Project Type: `presentation`

### Directory Tree
```
.
├── functions/                       # Empty directory for helper functions
├── resources/
│   └── images/
│       └── .gitkeep
├── _quarto.yml
├── .editorconfig
├── .git/
├── .gitignore
├── .lintr
├── framework-cheatsheet.md
├── framework.db
├── presentation.qmd                 # Main presentation file
├── README.md
├── scaffold.R
├── settings.json
├── settings.yml                     # Flat config
└── {project-name}.Rproj
```

**Total**: 4 directories, 13 files

### Configuration Structure

**Main Config (`settings.yml`)** - **FLAT (Inline)**:
```yaml
default:
  project_type: presentation

  # Inline author
  author:
    name: "Test User"
    email: "your.email@example.com"
    affiliation: "Your Institution"

  # Minimal packages
  packages:
    - name: ggplot2
      auto_attach: true
    - name: dplyr
      auto_attach: true

  # Minimal directories
  directories:
    presentation: "."
    functions: functions
    outputs: outputs

  # Behavior
  default_notebook_format: quarto
  seed: 1234
  seed_on_scaffold: true

  # Inline data
  data: {}

  # Framework connection
  connections:
    framework:
      driver: "sqlite"
      database: "framework.db"

  # AI config
  ai:
    canonical_file: ""

  # Git hooks
  git:
    hooks:
      ai_sync: false
      data_security: false
```

### Test Results
✅ `scaffold()` - Loads successfully
✅ `config("project_type")` → `"presentation"`
✅ `config("notebooks")` → `NULL` (no notebooks directory)
✅ Database tables created: `cache, connections, data, meta, results, sqlite_sequence`

---

## Key Differences Summary

| Feature | Project | Course | Presentation |
|---------|---------|--------|--------------|
| **Config Style** | Delegated (split files) | Flat (inline) | Flat (inline) |
| **Settings Files** | 10 split YAML files | 5 minimal split files | 0 split files |
| **Directories** | 10 (inputs/outputs separated) | 6 (slides focus) | 4 (minimal) |
| **Main File** | None | None | `presentation.qmd` |
| **Example Content** | `example-notebook.qmd`, `example-script.R` | `01-intro.qmd` | None |
| **Total Files** | 30 | 20 | 13 |
| **Focus** | Data analysis pipeline | Teaching materials | Single presentation |

---

## Configuration Architecture Patterns

### Pattern 1: Delegated Config (Project Type)
- **Main config** delegates to `settings/*.yml`
- **10 split files**: author, packages, directories, options, data, connections, security, ai, git, notebook
- **Best for**: Complex projects with many settings
- **Access**: `config("notebooks")` resolves via `settings/directories.yml`

### Pattern 2: Flat Config (Course + Presentation)
- **Everything inline** in `settings.yml`
- **Optional split files**: Only for complex catalogs (data.yml, connections.yml)
- **Best for**: Simpler projects, teaching, presentations
- **Access**: `config("slides")` reads directly from inline YAML

### Config Resolution Order
1. **Main `settings.yml`** - Always checked first
2. **Split file** (if key delegates to one) - `settings/{section}.yml`
3. **Package defaults** - Built-in fallbacks

**Precedence Rule**: Main config ALWAYS wins over split files.

---

## Verified Functionality

### All Project Types
✅ Git repository initialized with initial commit
✅ `framework.db` SQLite database created
✅ VS Code settings (`settings.json`) included
✅ `.gitignore` configured for data directories
✅ `.lintr` R code linting config
✅ `.editorconfig` for editor consistency
✅ `scaffold.R` entrypoint present
✅ Framework cheatsheet included

### Config System
✅ `config()` helper with dot-notation access
✅ Smart lookups (checks multiple locations)
✅ Split file resolution
✅ Flat config resolution
✅ Environment variable interpolation (`!expr Sys.getenv()`)

### Core Functions
✅ `scaffold()` - Loads environment, sets seed
✅ `make_notebook()` - Creates notebooks in correct directories
✅ `config("key")` - Retrieves settings correctly
✅ Database operations - Tables created properly

---

## Notes

1. **Directory Creation**: Physical directories only created when needed (e.g., notebooks/ created by `make_notebook()` if missing)

2. **Split Files**: Project type creates 10 split files upfront, course/presentation create 0-5 minimal ones

3. **Backward Compatibility**: Legacy `options$notebook_dir` style still supported, but new structure prioritized

4. **Config Warnings**: System warns if:
   - Split file contains unexpected top-level keys
   - Same key defined in both main and split file

5. **Git Integration**: All projects initialize git with clean initial commit

6. **Database Schema**: SQLite `framework.db` includes 6 tables: `cache`, `connections`, `data`, `meta`, `results`, `sqlite_sequence`

---

## Verification Command

To reproduce this structure:
```bash
cd /private/tmp && mkdir fw-projects && cd fw-projects

# Project
mkdir project && cd project
Rscript -e 'library(framework); init("test-project", type = "project", author_name = "Test User")'

# Course
cd .. && mkdir course && cd course
Rscript -e 'library(framework); init("test-course", type = "course", author_name = "Test User")'

# Presentation
cd .. && mkdir presentation && cd presentation
Rscript -e 'library(framework); init("test-presentation", type = "presentation", author_name = "Test User")'
```

---

**Status**: ✅ All three project types verified working with new config system
