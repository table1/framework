# Framework Package Cheatsheet

Quick reference for the most commonly used Framework functions.

---

## Getting Started

### Project Setup
```r
init()                           # Create new Framework project (interactive)
init("MyProject")                # Create with specific name
init("MyProject", minimal=TRUE)  # Create minimal structure
scaffold()                       # Load project environment (use in notebooks)
standardize_wd()                 # Normalize working directory for notebooks
```

### Notebook Creation
```r
make_notebook("1-init")          # Create work/1-init.qmd
make_notebook("analysis.Rmd")    # Create RMarkdown notebook
make_notebook("report", stub="minimal")  # Use minimal stub
list_stubs()                     # Show available notebook stubs
```

---

## Data Management

### Loading Data
```r
load_data("source.public.dataset")      # Load from data catalog
load_data("source.private.secure", encrypted=TRUE)
load_data_or_cache("slow.computation")  # Load or run expensive computation
```

### Saving Data
```r
save_data(df, "source.public.output")   # Save to catalog
save_data(df, "source.private.secret", encrypted=TRUE)
update_data_spec(df, "source.public.output")  # Update spec without saving
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
db_find("table_name")            # Find table in any connection
```

### Queries
```r
query <- get_query("query_name")          # Load query from queries/
results <- execute_query("query_name")    # Execute query
results <- query_execute("conn", query)   # Execute on connection
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

### Saving Results
```r
save_result(obj, "result_name")              # Save result
save_result(obj, "blind_result", blind=TRUE) # Save blinded result
result_save(obj, "result_name", comment="Analysis output")
```

### Loading Results
```r
get_result("result_name")        # Load result
result_get("result_name")        # Alias for get_result
list_results()                   # List all results
result_list()                    # Alias for list_results
```

---

## Utilities

### Scratch Space
```r
capture("var_name", expr)        # Capture to scratch space
scratch_capture("var_name", expr)  # Alias
scratch_clean()                  # Clean scratch space
clean_scratch()                  # Alias
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
| `capture()` | Capture to scratch space |
| `capture_output()` | Capture console output |
| `clean_scratch()` | Clean scratch space |
| `data_load()` | Load data (internal) |
| `data_save()` | Save data (internal) |
| `db_find()` | Find table in database |
| `execute_query()` | Execute named query |
| `framework_view()` | View framework database |
| `get_connection()` | Get database connection |
| `get_data_spec()` | Get data specification |
| `get_or_cache()` | Cache expensive computation |
| `get_query()` | Load query from file |
| `get_result()` | Load result |
| `init()` | Create new project |
| `is_initialized()` | Check initialization status |
| `list_metadata()` | List metadata entries |
| `list_results()` | List all results |
| `list_stubs()` | List notebook stubs |
| `load_data()` | Load from data catalog |
| `load_data_or_cache()` | Load or compute |
| `make_notebook()` | Create notebook from stub |
| `now()` | Current timestamp |
| `packages_restore()` | Restore package versions |
| `packages_snapshot()` | Save package versions |
| `packages_status()` | Check package status |
| `packages_update()` | Update packages |
| `query_execute()` | Execute query on connection |
| `query_get()` | Load query (alias) |
| `read_config()` | Read configuration |
| `remove_init()` | Remove init marker |
| `renv_disable()` | Disable renv |
| `renv_enable()` | Enable renv |
| `renv_enabled()` | Check renv status |
| `restore_framework_view()` | Restore view preferences |
| `result_get()` | Load result (alias) |
| `result_list()` | List results (alias) |
| `result_save()` | Save result (alternate) |
| `save_data()` | Save to data catalog |
| `save_result()` | Save result |
| `scaffold()` | Load project environment |
| `scratch_capture()` | Capture to scratch (alias) |
| `scratch_clean()` | Clean scratch (alias) |
| `standardize_wd()` | Normalize working directory |
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
      file: data/public/raw.csv
      format: csv
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

### Default Project Structure
```
project/
  ├── config.yml              # Main configuration
  ├── .env                    # Environment variables (secrets)
  ├── framework.db            # Framework metadata database
  ├── data/                   # Data files
  │   ├── public/            #   Public data
  │   └── private/           #   Private data (gitignored)
  ├── work/                   # Notebooks and analysis
  ├── functions/              # Custom R functions
  ├── queries/                # SQL query files
  ├── results/                # Analysis results
  ├── docs/                   # Documentation
  ├── stubs/                  # Custom notebook stubs
  └── scratch/                # Temporary workspace
```

### Minimal Project Structure
```
project/
  ├── config.yml
  ├── .env
  ├── framework.db
  ├── data/
  ├── work/
  └── functions/
```

---

## Quick Tips

1. **Quarto First**: Framework defaults to `.qmd` (Quarto) notebooks. Use `.Rmd` for RMarkdown.

2. **Data Paths**: Use dot notation for data catalog: `"category.subcategory.name"`

3. **Custom Stubs**: Create `stubs/notebook-{name}.qmd` to override defaults

4. **Encryption**: Requires `sodium` package. Use `encrypted=TRUE` parameter.

5. **renv**: Optional and opt-in. Enable with `renv_enable()` for reproducibility.

6. **Working Directory**: Call `standardize_wd()` in notebooks to normalize paths

7. **Database**: Framework creates `framework.db` for internal metadata tracking

8. **Functions Directory**: All `.R` files in `functions/` are auto-sourced by `scaffold()`

9. **Queries**: Store SQL in `queries/` directory, load with `get_query()`

10. **Results**: Saved results are tracked in framework.db with integrity hashes
