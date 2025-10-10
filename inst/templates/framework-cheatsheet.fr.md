# Framework Package Cheatsheet

Quick reference for the most commonly used Framework functions.

---

## Getting Started

### Project Setup
```r
init()                           # Create new Framework project (interactive)
init("MyProject", type="project")  # Create project structure
init("MyProject", type="course")   # Create course structure
init("MyProject", type="presentation")  # Create presentation
scaffold()                       # Load project environment (use in notebooks)
standardize_wd()                 # Normalize working directory for notebooks
```

### Notebook & Script Creation
```r
make_notebook("1-init")          # Create notebooks/1-init.qmd
make_notebook("analysis.Rmd")    # Create RMarkdown notebook
make_notebook("slides", stub="revealjs")  # Use reveal.js stub
make_script("process-data")      # Create scripts/process-data.R
list_stubs()                     # Show available stubs
stubs_publish()                  # Publish stubs for customization
```

---

## Data Management

### Loading Data
```r
load_data("source.public.dataset")      # Load from data catalog
load_data("source.private.secure")      # Load private data
load_data_or_cache("slow.computation")  # Load or run expensive computation
```

### Saving Data
```r
save_data(df, "source.public.output")   # Save to catalog
save_data(df, "source.private.secret", encrypted=TRUE)  # Encrypted save
update_data_spec("source.public.output", spec)  # Update spec
get_data_spec("source.public.output")   # Get data specification
```

### Data Cache
```r
get_or_cache("key", expr)        # Cache expensive computation
cache_get("key")                 # Retrieve from cache
cache("key", value)              # Store in cache
cache_forget("key")              # Delete cached item
cache_flush()                    # Clear all cache
```

---

## Database Operations

### Connections
```r
get_connection("db_name")        # Get database connection
db_find(conn, "table", id)       # Find record by ID
```

### Queries
```r
results <- query_get("SELECT * FROM users", "mydb")  # Run query
affected <- query_execute("UPDATE ...", "mydb")      # Execute non-query
```

---

## Configuration

### Config Files
```r
config <- read_config()          # Read config.yml or settings/*.yml
write_config(config)             # Write config back
```

---

## Package Management (renv Integration)

### Setup
```r
renv_enable()                    # Enable renv for project
renv_disable()                   # Disable renv
renv_enabled()                   # Check if renv is enabled
```

### Package Operations
```r
packages_snapshot()              # Save package versions
packages_restore()               # Restore saved versions
packages_status()                # Check package status
packages_update()                # Update packages
```

---

## Results Management

### Saving & Loading Results
```r
result_save(obj, "my_model", type="model")           # Save result
result_save(obj, "blind", type="model", blind=TRUE)  # Save blinded
result_get("my_model")                               # Load result
result_list()                                        # List all results
```

---

## Utilities

### Scratch Space
```r
scratch_capture(df)              # Save to scratch/
scratch_capture(df, "data")      # Save as scratch/data.tsv
scratch_clean()                  # Clean scratch directory
```

### Date/Time
```r
now()                            # Current timestamp (formatted)
```

### Framework Database
```r
list_metadata()                  # List metadata entries
framework_view()                 # View framework database
use_framework_view()             # Enable auto-view on updates
restore_framework_view()         # Restore view preferences
```

---

## Advanced Features

### Initialization Control
```r
is_initialized()                 # Check if project is initialized
remove_init()                    # Remove initialization marker
```

### Output Capture
```r
capture_output(expr)             # Capture console output
```

---

## Alphabetical Function Reference

| Function | Purpose |
|----------|---------|
| `cache()` | Store value in cache |
| `cache_flush()` | Clear all cache |
| `cache_forget()` | Delete cached item |
| `cache_get()` | Retrieve from cache |
| `capture_output()` | Capture console output |
| `data_load()` | Load data (internal) |
| `data_save()` | Save data (internal) |
| `db_find()` | Find record by ID |
| `framework_view()` | View framework database |
| `get_connection()` | Get database connection |
| `get_data_spec()` | Get data specification |
| `get_or_cache()` | Cache expensive computation |
| `init()` | Create new project |
| `is_initialized()` | Check initialization status |
| `list_metadata()` | List metadata entries |
| `list_stubs()` | List available stubs |
| `load_data()` | Load from data catalog |
| `load_data_or_cache()` | Load or compute |
| `make_notebook()` | Create notebook from stub |
| `make_script()` | Create script from stub |
| `now()` | Current timestamp |
| `packages_restore()` | Restore package versions |
| `packages_snapshot()` | Save package versions |
| `packages_status()` | Check package status |
| `packages_update()` | Update packages |
| `query_execute()` | Execute query on connection |
| `query_get()` | Get query results |
| `read_config()` | Read configuration |
| `remove_init()` | Remove init marker |
| `renv_disable()` | Disable renv |
| `renv_enable()` | Enable renv |
| `renv_enabled()` | Check renv status |
| `restore_framework_view()` | Restore view preferences |
| `result_get()` | Load result |
| `result_list()` | List all results |
| `result_save()` | Save result |
| `save_data()` | Save to data catalog |
| `scaffold()` | Load project environment |
| `scratch_capture()` | Save to scratch space |
| `scratch_clean()` | Clean scratch directory |
| `standardize_wd()` | Normalize working directory |
| `stubs_path()` | Get stubs directory path |
| `stubs_publish()` | Publish stubs for customization |
| `update_data_spec()` | Update data specification |
| `use_framework_view()` | Enable auto-view |
| `write_config()` | Write configuration |

---

## Configuration File Examples

### config.yml (Single File Approach)
```yaml
default:
  project_name: "MyProject"

  packages:
    - dplyr
    - ggplot2
    - tidyr

  connections:
    framework:
      type: sqlite
      database: framework.db

  data:
    source.public.raw:
      path: data/public/raw.csv
      type: csv
```

### settings/ Directory (Multi-File Approach)
```
settings/
  packages.yml
  connections.yml
  data.yml
```

### Stub Template Example (stubs/notebook-analysis.qmd)
```yaml
---
title: "{filename}"
date: "{date}"
format: html
---

```{{r}}
library(framework)
scaffold()
standardize_wd()

# Your analysis code
```
```

---

## Directory Structure

### Project Type (Default)
```
project/
  ├── config.yml              # Main configuration
  ├── .env                    # Environment variables (secrets)
  ├── framework.db            # Framework metadata database
  ├── data/                   # Data files
  │   ├── source/            #   Source data
  │   │   ├── public/        #     Public data
  │   │   └── private/       #     Private data (gitignored)
  │   └── results/           #   Result data
  ├── notebooks/              # Quarto/RMarkdown notebooks
  ├── scripts/                # R scripts
  ├── functions/              # Custom R functions
  ├── docs/                   # Documentation
  ├── resources/              # Static resources
  ├── results/                # Analysis output
  │   ├── public/            #   Shareable results
  │   └── private/           #   Private results
  ├── stubs/                  # Custom templates (optional)
  └── settings/               # Config files (optional)
```

### Course Type
```
course/
  ├── config.yml
  ├── .env
  ├── framework.db
  ├── data/
  ├── notebooks/              # Lesson notebooks
  ├── presentations/          # Slide decks
  ├── functions/
  ├── docs/
  ├── resources/
  └── settings/
```

### Presentation Type
```
presentation/
  ├── config.yml
  ├── .env
  ├── framework.db
  ├── presentation.qmd        # Main presentation file
  ├── build.R                 # Build script
  ├── data/
  ├── functions/
  └── results/
```

---

## Quick Tips

1. **Quarto First**: Framework defaults to `.qmd` (Quarto) notebooks. Use `.Rmd` for RMarkdown.

2. **Data Paths**: Use dot notation for data catalog: `"category.subcategory.name"`

3. **Custom Stubs**: Run `stubs_publish()` then edit `stubs/` directory

4. **Encryption**: Requires `sodium` package. Use `encrypted=TRUE` parameter.

5. **renv**: Optional and opt-in. Enable with `renv_enable()` for reproducibility.

6. **Working Directory**: Call `standardize_wd()` in notebooks to normalize paths

7. **Database**: Framework creates `framework.db` for internal metadata tracking

8. **Functions Directory**: All `.R` files in `functions/` are auto-sourced by `scaffold()`

9. **Noun-Prefix Pattern**: Functions are grouped by noun (`query_*`, `result_*`, `scratch_*`, `stubs_*`)

10. **Project Types**: Choose `project`, `course`, or `presentation` based on your needs
