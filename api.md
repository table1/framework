# Framework API Documentation

This document provides comprehensive API documentation for all exported functions in the Framework R package.

## Table of Contents

- [Project Management](#project-management)
- [Configuration](#configuration)
- [Data Management](#data-management)
- [Caching System](#caching-system)
- [Database Operations](#database-operations)
- [Results Management](#results-management)
- [Scratch System](#scratch-system)
- [Framework Views](#framework-views)
- [Utilities](#utilities)

---

## Project Management

### `init()`
Initializes a new Framework project with standardized directory structure and configuration files.

**Parameters:**
- `project_name` (character, optional): Name of the project (used for .Rproj file)
- `project_structure` (character, default: "default"): Project structure to use ("default" or "minimal")
- `lintr` (character, default: "default"): Lintr style configuration
- `styler` (character, default: "default"): Styler style configuration
- `subdir` (character, optional): Subdirectory to initialize project in
- `force` (logical, default: FALSE): Reinitialize even if project already exists

**Returns:** NULL (creates project structure and files)

**Example:**
```r
init("My Analysis Project", project_structure = "default")
```

### `scaffold()`
Loads and initializes the project environment for the current session.

**Parameters:**
- `config_file` (character, default: "config.yml"): Path to configuration file

**Actions:**
- Loads environment variables from .env file
- Loads configuration from config.yml
- Installs required packages
- Loads specified libraries
- Sources all .R files from functions/ directory
- Executes scaffold.R if present

**Example:**
```r
scaffold()
```

### `is_initialized()`
Checks if the current directory (or specified subdirectory) is initialized as a Framework project.

**Parameters:**
- `subdir` (character, optional): Subdirectory to check

**Returns:** Logical indicating if project is initialized

### `remove_init()`
Removes the initialization marker from the current directory (or specified subdirectory).

**Parameters:**
- `subdir` (character, optional): Subdirectory to remove initialization from

**Returns:** Logical indicating if removal was successful

---

## Configuration

### `read_config()`
Reads and processes the project configuration from YAML files.

**Parameters:**
- `config_file` (character, default: "config.yml"): Path to main configuration file

**Returns:** List containing processed configuration with all sections and options

**Features:**
- Evaluates R expressions in YAML (!expr syntax)
- Handles environment variable interpolation (env() function)
- Merges skeleton config with user config
- Validates and initializes all standard sections

**Example:**
```r
config <- read_config()
```

### `write_config()`
Writes configuration data to a YAML file.

**Parameters:**
- `config` (list): Configuration object to write
- `config_file` (character, default: "config.yml"): Path to write configuration file

**Returns:** NULL

---

## Data Management

### `load_data()`
Loads data from configured data specifications or direct file paths using dot notation.

**Parameters:**
- `path` (character): Dot notation path (e.g., "source.private.example") or direct file path
- `delim` (character, optional): Delimiter for CSV files ("comma", "tab", "semicolon", "space")
- `...`: Additional arguments passed to readr::read_delim

**Returns:** Loaded data as data frame or other R object

**Features:**
- Supports both dot notation paths and direct file paths
- Automatic file type detection (CSV, TSV, RDS)
- Data integrity verification via hash checking
- Encryption support for sensitive data
- Comprehensive error handling

**Examples:**
```r
# Load using dot notation
data <- load_data("source.private.my_data")

# Load direct file with custom delimiter
data <- load_data("data/file.csv", delim = "tab", na = c("", "NA"))
```

### `save_data()`
Saves data using dot notation path with automatic directory creation and integrity tracking.

**Parameters:**
- `data` (data frame): Data to save
- `path` (character): Dot notation path (e.g., "in_progress.processed_data")
- `type` (character, default: "csv"): File type ("csv" or "rds")
- `delimiter` (character, default: "comma"): Delimiter for CSV files
- `locked` (logical, default: TRUE): Whether file should be locked after saving
- `encrypted` (logical, default: FALSE): Whether file should be encrypted

**Returns:** NULL (saves file and updates framework database)

**Features:**
- Automatic directory structure creation
- Data integrity hash calculation and storage
- Encryption support using configured security keys
- Locking mechanism to prevent accidental modifications
- Informative messages for configuration updates

**Examples:**
```r
# Save as CSV
save_data(processed_data, "in_progress.cleaned_data", type = "csv")

# Save encrypted data
save_data(sensitive_data, "final.private.results", type = "rds", encrypted = TRUE)
```

### `load_data_or_cache()`
Loads data with intelligent caching - returns cached version if available and current, otherwise loads and caches.

**Parameters:**
- `path` (character): Dot notation path or file path
- `cache_name` (character): Name for cache entry
- `force_refresh` (logical, default: FALSE): Force reload even if cache exists

**Returns:** Loaded data (from cache or file)

### `get_data_spec()`
Retrieves data specification from configuration for a given dot notation path.

**Parameters:**
- `path` (character): Dot notation path

**Returns:** List containing data specification (path, type, delimiter, locked, encrypted, etc.)

### `update_data_spec()`
Updates or creates a data specification in the configuration.

**Parameters:**
- `path` (character): Dot notation path
- `spec` (list): Data specification details

**Returns:** NULL

---

## Caching System

### `cache()`
Stores a value in the cache with optional expiration.

**Parameters:**
- `name` (character): Cache name/key
- `value`: Value to cache (any R object)
- `file` (character, optional): Custom file path for cache storage
- `expire_after` (numeric, optional): Expiration time in hours

**Returns:** NULL

**Features:**
- Stores values as RDS files
- Hash verification for integrity
- Configurable default expiration
- Metadata tracking in framework database

### `cache_get()`
Retrieves a value from the cache if available and not expired.

**Parameters:**
- `name` (character): Cache name/key
- `file` (character, optional): Custom file path for cache storage
- `expire_after` (numeric, optional): Expiration time in hours

**Returns:** Cached value or NULL if not found/expired

### `cache_forget()`
Removes a specific entry from the cache.

**Parameters:**
- `name` (character): Cache name/key to remove
- `file` (character, optional): Custom file path for cache storage

**Returns:** NULL

### `cache_flush()`
Clears all cached values.

**Parameters:** None

**Returns:** NULL

### `get_or_cache()`
Gets a value, caching the result if not found. Ideal for expensive computations.

**Parameters:**
- `name` (character): Cache name/key
- `expr`: Expression to evaluate and cache if needed
- `file` (character, optional): Custom file path for cache storage
- `expire_after` (numeric, optional): Expiration time in hours
- `refresh` (logical/function, default: FALSE): Force refresh or function to determine refresh need

**Returns:** Result of expression (from cache or computation)

**Examples:**
```r
# Cache expensive computation
result <- get_or_cache("expensive_calc", {
  # Your expensive computation here
  Sys.sleep(5)
  runif(1000)
}, expire_after = 1440)  # 24 hours

# Smart refresh based on source file changes
result <- get_or_cache("data_processing", {
  process_data()
}, refresh = function() {
  file.mtime("source/data.csv") > get_last_update_time()
})
```

---

## Database Operations

### `get_connection()`
Gets a database connection based on configuration.

**Parameters:**
- `connection_name` (character): Name of connection defined in config.yml

**Returns:** Database connection object

**Features:**
- Supports SQLite and PostgreSQL
- Automatic connection management
- Configuration-driven parameters

### `get_query()`
Executes a SELECT query and returns results as a data frame.

**Parameters:**
- `query` (character): SQL SELECT query to execute
- `connection_name` (character): Name of connection in config.yml
- `...`: Additional arguments passed to DBI::dbGetQuery

**Returns:** Data frame with query results

**Example:**
```r
users <- get_query("SELECT * FROM users WHERE active = TRUE", "postgres")
```

### `execute_query()`
Executes a SQL command that doesn't return results (INSERT, UPDATE, DELETE, etc.).

**Parameters:**
- `query` (character): SQL command to execute
- `connection_name` (character): Name of connection in config.yml
- `...`: Additional arguments passed to DBI::dbExecute

**Returns:** Number of rows affected

**Example:**
```r
rows_affected <- execute_query("INSERT INTO users (name) VALUES ('John')", "postgres")
```

### `db_find()`
Finds a single record in a database table by ID.

**Parameters:**
- `conn`: Database connection object
- `table_name` (character): Name of table to query
- `id`: ID value to look up
- `with_trashed` (logical, default: FALSE): Include soft-deleted records

**Returns:** Data frame with the record or empty data frame if not found

---

## Results Management

### `save_result()`
Saves analysis results with metadata tracking and optional encryption.

**Parameters:**
- `name` (character): Result name/identifier
- `value`: Result value to save (optional if using file parameter)
- `type` (character): Type of result (e.g., "model", "notebook", "report")
- `blind` (logical, default: FALSE): Whether result should be encrypted
- `public` (logical, default: FALSE): Whether result should be public (vs private)
- `comment` (character, default: ""): Optional description
- `file` (character, optional): Path to external file to save (e.g., HTML report)

**Returns:** NULL

**Features:**
- Separate public/private result directories
- Encryption for sensitive results
- Hash verification for integrity
- Metadata tracking in framework database
- Support for both R objects and external files

**Examples:**
```r
# Save model output
save_result("model_v1", model_object, type = "model", comment = "Initial model")

# Save encrypted results
save_result("sensitive_results", results_data, type = "analysis", blind = TRUE)

# Save external report
save_result("monthly_report", type = "report", file = "report.html", public = TRUE)
```

### `get_result()`
Retrieves a saved result.

**Parameters:**
- `name` (character): Result name/identifier

**Returns:** The saved result object

### `list_results()`
Lists all saved results with metadata.

**Parameters:** None

**Returns:** Data frame with results metadata (name, type, created_at, updated_at, etc.)

### `list_metadata()`
Lists framework database metadata (data specifications, cache entries, etc.).

**Parameters:** None

**Returns:** Data frame with metadata information

---

## Scratch System

### `capture()`
Saves R objects to the scratch directory for debugging, sharing, or temporary storage.

**Parameters:**
- `x`: R object to save
- `name` (character, optional): Custom filename (without extension)
- `to` (character, optional): Output format ("text", "rds", "csv", "tsv")
- `location` (character, optional): Directory path (uses config scratch_dir if NULL)
- `n` (numeric, default: Inf): Number of rows to capture for data frames

**Returns:** Input object `x` invisibly

**Features:**
- Intelligent format detection based on object type
- Automatic filename generation from object names
- Row limiting for large data frames
- Pipe-friendly operation
- Multiple output formats

**Examples:**
```r
# Auto-detect format and name
capture(my_data)

# Custom name and format
capture(large_dataset, "sample", to = "csv", n = 100)

# Pipe operation
my_data |> capture("processed_data")

# Save as RDS
capture(complex_object, to = "rds")
```

### `capture_output()`
Captures R output (messages, warnings, errors, printed output) to a file.

**Parameters:**
- `expr`: R expression to evaluate and capture output from
- `file` (character): File path to save output to
- `append` (logical, default: FALSE): Whether to append to existing file

**Returns:** Result of evaluated expression

### `clean_scratch()`
Cleans up the scratch directory by removing old or all files.

**Parameters:**
- `older_than` (character, optional): Remove files older than this time period
- `all` (logical, default: FALSE): Remove all files regardless of age

**Returns:** NULL

---

## Framework Views

Framework Views provide a custom R environment for organized data analysis.

### `framework_view()`
Creates or modifies a framework view environment.

**Parameters:**
- `name` (character): View name
- `data` (list, optional): Named list of data objects to add to view
- `packages` (character, optional): Packages to load in view
- `functions` (character, optional): Function files to source in view

**Returns:** Framework view environment

### `use_framework_view()`
Activates a framework view as the current working environment.

**Parameters:**
- `view`: Framework view environment or name

**Returns:** NULL

### `restore_framework_view()`
Restores the previous environment after using a framework view.

**Parameters:** None

**Returns:** NULL

---

## Utilities

### `now()`
Returns current timestamp as character string in ISO format.

**Parameters:** None

**Returns:** Character string with current timestamp

### `db_find()`
Find records by ID in database tables (see Database Operations section).

### `framework_view()`, `use_framework_view()`, `restore_framework_view()`
Framework view management functions (see Framework Views section).

---

## Configuration Structure

The Framework uses a hierarchical YAML configuration structure:

### Main Sections

- **options**: Global settings (cache directories, expiration times, etc.)
- **data**: Data specifications with paths, types, and metadata
- **connections**: Database connection configurations
- **packages**: Package dependencies and loading preferences
- **security**: Encryption keys and security settings
- **git**: Git configuration settings

### Example Configuration Structure

```yaml
default:
  options:
    cache_dir: data/cached
    scratch_dir: data/scratch
    cache_default_expire: 1440  # hours

  data:
    source:
      private:
        sensitive_data:
          path: data/source/private/sensitive.csv
          type: csv
          locked: true
          encrypted: true

  connections:
    postgres:
      driver: postgresql
      host: !expr Sys.getenv("DB_HOST")
      # ... other connection params

  packages:
    - name: dplyr
      attached: true
    - name: ggplot2
      attached: true
    - tidyr  # installed but not loaded

  security:
    data_key: !expr Sys.getenv("DATA_KEY")
    results_key: !expr Sys.getenv("RESULTS_KEY")
```

---

## Error Handling

All Framework functions include comprehensive error handling:

- **File operations**: Clear messages for missing files, permission issues
- **Data parsing**: Informative errors for malformed data
- **Database operations**: Connection and query error handling
- **Configuration**: Validation and helpful error messages
- **Encryption**: Clear messages for missing keys or encryption failures

Functions use `stop()` for critical errors and `warning()` for recoverable issues, with messages designed to help users quickly identify and resolve problems.