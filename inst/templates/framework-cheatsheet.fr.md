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
make_notebook("1-init")          # Create notebooks/1-init.qmd (defaults to Quarto)
make_qmd("analysis")             # Explicit Quarto notebook
make_rmd("report")               # Explicit RMarkdown notebook
make_revealjs("slides")          # Create reveal.js presentation
make_presentation("deck")        # Alias for make_revealjs()
make_script("process-data")      # Create scripts/process-data.R
stubs_list()                     # Show available stubs
stubs_publish()                  # Publish stubs for customization
```

---

## Data Management

### Loading Data
```r
data_read("inputs_raw.dataset")           # Load from data catalog
data_read("inputs_intermediate.cleaned")  # Load intermediate data
data_info("source.public.example")        # Get data specification
```

### Saving Data
```r
data_save(df, "outputs_private.output")   # Save to catalog
data_save(df, "outputs_private.secret", encrypted=TRUE)  # Encrypted save
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

### Settings Helper (Dot Notation)
```r
settings()                          # View entire settings (pretty-printed in console)
settings("directories")             # Get all directories
settings("directories.notebooks")   # Get nested value with dot notation
settings("notebooks")               # Smart lookup (checks directories section)
settings("connections.db.host")     # Access deep nested values
settings("missing", default = "x")  # Provide fallback for missing keys
```

### Settings Files
```r
settings <- read_config()        # Read settings.yml (or settings.yml)
write_config(settings)           # Write settings back
```

### AI Assistant Support
```r
configure_ai_agents()            # Configure AI assistant support
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

## Publishing to S3

### Setup
Configure S3 connection in `config.yml`:
```yaml
connections:
  s3_public:
    driver: s3
    bucket: my-bucket
    region: us-east-1
    prefix: framework-outputs     # Optional prefix for all uploads
    default: true                 # Mark as default S3 connection
```

Add credentials to `.env`:
```bash
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
```

### Publishing Files
```r
publish("outputs/report.html")                    # Upload file to S3
publish("outputs/data.csv", dest = "data/v2.csv") # Custom destination
publish_dir("outputs/charts/")                    # Upload entire directory
```

### Publishing Notebooks
```r
publish_notebook("notebooks/analysis.qmd")        # Render & publish
# -> https://bucket.s3.region.amazonaws.com/prefix/analysis/index.html

publish_notebook("report.qmd", dest = "reports/2024/q4")  # Custom path
publish_notebook("report.qmd", self_contained = FALSE)    # With assets
```

### Publishing Data
```r
publish_data(my_df, "datasets/results.csv")       # Publish data frame
publish_data(my_df, "data.rds", format = "rds")   # As RDS
publish_data("outputs/model.rds", "models/v2.rds") # Existing file
```

### Utilities
```r
s3_test()                         # Test S3 connection
s3_test("backup_s3")              # Test specific connection
publish_list()                    # List published files
publish_list("reports/")          # List with prefix filter
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
| `configure_ai_agents()` | Configure AI assistant support |
| `data_read()` | Read data (internal) |
| `data_save()` | Save data (internal) |
| `db_find()` | Find record by ID |
| `framework_view()` | View framework database |
| `get_connection()` | Get database connection |
| `get_data_spec()` | Get data specification |
| `get_or_cache()` | Cache expensive computation |
| `init()` | Create new project |
| `is_initialized()` | Check initialization status |
| `list_metadata()` | List metadata entries |
| `stubs_list()` | List available stubs |
| `data_read()` | Load from data catalog |
| `data_info()` | Get data specification |
| `make_notebook()` | Create notebook from stub |
| `make_presentation()` | Create presentation (reveal.js) |
| `make_qmd()` | Create Quarto notebook |
| `make_revealjs()` | Create reveal.js presentation |
| `make_rmd()` | Create RMarkdown notebook |
| `make_script()` | Create script from stub |
| `now()` | Current timestamp |
| `packages_restore()` | Restore package versions |
| `packages_snapshot()` | Save package versions |
| `packages_status()` | Check package status |
| `packages_update()` | Update packages |
| `publish()` | Upload file or directory to S3 |
| `publish_data()` | Publish data frame or file to S3 |
| `publish_dir()` | Upload directory to S3 |
| `publish_list()` | List published files in S3 |
| `publish_notebook()` | Render and publish Quarto notebook to S3 |
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
| `s3_test()` | Test S3 connection |
| `data_save()` | Save to data catalog |
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

### settings.yml (Single File Approach)
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
    inputs.reference.example:
      path: inputs/reference/example.csv
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
  ├── settings.yml              # Main configuration
  ├── .env                    # Environment variables (secrets)
  ├── framework.db            # Framework metadata database
  ├── inputs/
  │   ├── raw/
  │   ├── intermediate/
  │   ├── final/
  │   └── reference/
  ├── outputs/
  │   ├── private/            # Résultats internes (tables, figures, cache)
  │   └── public/             # Livrables validés
  ├── notebooks/              # Quarto/RMarkdown notebooks
  ├── scripts/                # Scripts R
  ├── functions/              # Fonctions personnalisées
  ├── docs/                   # Documentation
  ├── stubs/                  # Modèles personnalisés (optionnel)
  └── settings/               # Fichiers de configuration (optionnel)
```

### Course Type
```
course/
  ├── settings.yml
  ├── .env
  ├── framework.db
  ├── assignments/
  ├── course_docs/
  ├── data/
  ├── readings/
  └── slides/
```

### Presentation Type
```
presentation/
  ├── settings.yml
  ├── .env
  ├── framework.db
  └── presentation.qmd
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
