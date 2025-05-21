# Framework

**Framework** is an R package that helps data analysts quickly scaffold structured, reproducible data analysis projects. Following a "convention over configuration" approach, it promotes best practices with minimal setup, while providing well-tested tools to manage the infrastructure of real-world analytical workflows.

This repository contains the source code for the Framework R package. 

The example skeleton for a Framework-based analysis project can be found at [https://github.com/table1/framework-project](https://github.com/table1/framework-project).

Framework includes functionality for:

* Project scaffolding and configuration using standardized directories and YAML-driven setup
* Declarative data cataloguing and loading for data security
* Automatic loading of packages and user-defined functions, reducing boilerplate in scripts and notebooks
* Data integrity tracking through a digest system that records and verifies transformations on data files
* Utility functions for common workflows, including caching expensive computations, flushing cached objects, and saving intermediate results
* Connection helpers for accessing remote data sources such as databases or APIs
* Automatic configuration of tooling files for popular editors and IDEs


Framework is designed to reduce friction around non-analytical tasks and make it easier for analysts to follow best practices in data science.

## Warning

This package is in active development. The APIs may change.  We will announce a version 1 with a stable API.

## Table of Contents

- [Getting Started](#getting-started)
  - [Clone the Repository](#clone-the-repository)
  - [Initialize Project](#initialize-project)
- [Project Structure](#project-structure)
  - [Default Structure](#default-structure)
  - [Minimal Structure](#minimal-structure)
- [Project Initialization](#project-initialization)
  - [scaffold()](#frameworkscaffold)
  - [scaffold.R](#scaffoldr)
- [Configuration](#configuration)
  - [Config File](#config-file)
  - [Config Functions](#config-functions)
- [Data Management](#data-management)
  - [Loading Data](#loading-data)
  - [Saving Data](#saving-data)
  - [Database Queries](#database-queries)
    - [Local SQLite](#local-sqlite)
    - [Remote PostgreSQL](#remote-postgresql)
  - [Caching](#caching)
    - [Basic Caching](#basic-caching)
    - [Getting from Cache](#getting-from-cache)
    - [Removing from Cache](#removing-from-cache)
    - [Smart Caching with Computation](#smart-caching-with-computation)
    - [Complex Caching Examples](#complex-caching-examples)
  - [Results Management](#results-management)
    - [Results Storage](#results-storage)
    - [Results Functions](#results-functions)
    - [Blinded Results](#blinded-results)
- [Framework Database](#framework-database)
  - [Database Structure](#database-structure)
  - [Data Integrity Tracking](#data-integrity-tracking)
  - [Metadata Management](#metadata-management)
- [Functions Directory](#functions-directory)
- [Tooling](#tooling)
  - [.lintr](#lintr)
  - [.styler.R](#stylerr)
  - [.editorconfig](#editorconfig)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Author](#author)

## Getting Started

### Clone the Analysis Skelton Repository
```bash
git clone https://github.com/table1/framework-project
cd framework-project
```

### Initialize Project
Open `init.R` in your R editor (RStudio, VS Code, etc.):
- Review the initialization settings
- Run `framework::init()`

The initialization script will create a new project with your chosen structure and settings.

Once the project structure is in place, the analyst can modify it however they please. `framework` is designed to stay out of your way.

## Project Structure

### Default Structure
```
project/
├── data/               # Data directory [.gitignored by default]
│   ├── source/         # Source data directory
│   │   ├── private/    # Private source data [.gitignored]
│   │   └── public/     # Public source data [not .gitignored]
│   ├── in_progress/    # Intermediate processed data [.gitignored]
│   ├── cached/         # Cached computations [.gitignored]
│   ├── scratch/        # Temporary data files [.gitignored]
│   └── final/          # Final output directory
│       ├── private/    # Private outputs [.gitignored]
│       └── public/     # Public outputs [not .gitignored]
├── work/               # Work directory: store your scripts and notebooks here
│   ├── analysis/       # Analysis scripts
│   ├── processing/     # Data processing scripts
│   ├── scratch/        # Temporary work files
│   └── tests/          # Test files
├── functions/          # Custom functions
├── documentation/      # Project documentation
├── resources/          # Project resources
├── results/            # Analysis results
│   ├── private/        # Private results [.gitignored]
│   └── public/         # Public results [not .gitignored]
├── settings/           # Configuration files
│   ├── data.yml        # Data specifications
│   ├── packages.yml    # Package dependencies
│   ├── connections.yml # Database connections
│   ├── git.yml         # Git configuration
│   └── security.yml    # Security settings
├── config.yml          # Framework configuration
├── framework.db        # Framework database (metadata, state, tracking)
├── .lintr              # R linting configuration
├── .styler.R           # R code style configuration
├── .editorconfig       # Editor configuration
└── .gitignore          # .gitignore file
```

### Minimal Structure
```
project/
├── data/               # Data files
├── functions/          # Custom functions
├── results/            # Analysis results
│   ├── private/        # Private results [.gitignored]
│   └── public/         # Public results [not .gitignored]
├── config.yml          # Framework configuration
├── framework.db        # Framework database
├── .lintr              # R linting configuration
├── .styler.R           # R code style configuration
├── .editorconfig       # Editor configuration
└── .gitignore          # .gitignore file
```

## Project Initialization

### `framework::scaffold()`

The `scaffold()` function initializes your project environment. You can place this at the top of any script or notebook you're working with. Running it more than once is generally fine.

#### Example Usage

```r
library(framework)
scaffold()

# Your functions are now available
my_function()

# Load data using dot notation
data <- load_data("source.private.my_data")
```

`scaffold()`:

- Loads the framework package if not already loaded
- Gracefully installs required packages from `config.yml`
- Loads specified libraries from `config.yml`
- Reads all `.R` files from the `functions/` directory and makes them available in your global environment
- Loads project configuration from `config.yml` and stores configuration in the `config` variable, interpolating any secrets from `.env`
- Runs the `scaffold.R` file, allowing you to run useful code you want run before you do any work.

### scaffold.R

The `scaffold.R` file in your project root is a special file that gets sourced every time you run `scaffold()`.

This is where you should put any code that needs to run at the start of every analysis session.

Example `scaffold.R`:
```r
# Set global options
options(
  digits = 3,
  scipen = 999,
  stringsAsFactors = FALSE
)
```

The `scaffold.R` file is sourced after all packages are loaded and functions are available, so you can use any of your project's functions or loaded packages in this file.

## Configuration

The framework uses a YAML-based configuration system to manage project settings and data specifications.

Note that R's `config` system expects a `default` parent node and/or overrides for it.

### Config File

The `config.yml` file is the central configuration file for your project. It uses YAML syntax and supports R expressions for dynamic values. The configuration follows R's `config` package conventions.

There are two ways to structure your configuration:

1. **Default Structure** - Uses separate YAML files in `/settings`:

```yaml
default:
  data: settings/data.yml
  packages: settings/packages.yml
  connections: settings/connections.yml
  git: settings/git.yml
  security: settings/security.yml
```

Example `settings/data.yml`:

```yaml
options:
  cache_dir: data/cached
  scratch_dir: data/scratch
data:
  source:
    private:
      example:
        path: "data/source/private/example.csv"
        type: "csv"
        delimiter: "comma"
        locked: true
```

2. **Minimal Structure** - All configuration in a single file:
```yaml
default:
  data: 
    - example: data/example.csv
  packages: 
    - dplyr
    - ggplot2
```

Whether you use the default or a minimal set up, Framework compiles your settings down into a config R `list` object that looks like something like this:

```yaml
options:
  dotenv_location: "."
  connections:
    default_connection: db
  data:
    cache_dir: data/cached
    scratch_dir: data/scratch
  packages:
    auto_install: true
    auto_update: false

connections:
  
data:

git:
  url: null
  author: null
  email: null

packages:

security:
  data_key: null
  results_key: null

```

Options are stored under `options`, structured using each component's respective name as a parent. The configuration itself is stored at the top level of the config list under its respective name.

This is designed to allow users to expect the config object to have certain data always present. For example, `config$options$data$cache_dir` will always be available, as a default or as whatever the user defines it as in their configuration settings.

### Config Functions

The framework provides several functions for managing configuration:

#### Reading and Writing Config

```r
# Read the entire config
config <- read_config()

# Write updated config
write_config(config)
```

## Package Management

The framework manages R package dependencies using the settings list in the configuration.

For example, consider the below `settings/packages.yml` file:

```yaml
# Packages that will be loaded with scaffold()
- name: dplyr
  attached: true
- name: readr
  attached: false
- name: ggplot2
  attached: true

# Packages that will be installed but not loaded
- tidyr
- tidymodels
- stringr
- forcats
- purrr
- lubridate
```

Or in a minimal setup:

```yaml
default:
  data: 
    - example: data/example.csv
  packages: 
    - dplyr
    - ggplot2
```

The package system:
- Installs all listed packages automatically
- Only loads packages marked with `attached: true` during `scaffold()`
- Packages without `attached` are installed but not loaded
- Dependencies are automatically resolved

`renv` support is coming soon.

## Data Management

The framework provides a structured way to manage data files and their metadata:

### Data Storage

- Data files are stored in the `data/` directory with a hierarchical structure:
  - `data/source/` - Raw source data
  - `data/in_progress/` - Intermediate processed data
  - `data/final/` - Final processed data
  - Each level can have `public/` and `private/` subdirectories


### Data Configuration

Data paths must be configured in either:
- `config.yml` under the `data:` key
- `settings/data.yml` (referenced in config.yml)

Example configuration:
```yaml
data:
  final:
    private:
      example:
        path: data/final/private/example.csv
        type: csv
        locked: true
        encrypted: false
        delimiter: comma
```

### Loading Data

Load data using dot notation paths:

```r
# Load data from source.private.example
data <- load_data("source.private.example")
```

The path is resolved through `config.yml`, which specifies:
- File location
- File type (CSV, RDS)
- Delimiter (for CSV files)
- Lock status

### Saving Data

Save data using dot notation paths.  Specify `csv` or `rds` as types.

```r
# Save data frame as CSV
save_data(df_post_merge, "in_progress.post_merge", type = "csv")

# Save as RDS
save_data(df, "final.public.data", type = "rds")
```

The function:
- Creates necessary directories
- Saves the data file
- Updates the data integrity digest
- Provides feedback messages

When using `save_data()`, you'll get a message showing where to add the configuration in your YAML file.  This is left up to the analyst.


### Results Management

The framework provides a system for managing analysis results:

#### Results Storage

- Results are stored in the `results/` directory with a public/private split; private results are .gitignored.
- Results can be model outputs, notebooks, or other analysis artifacts
- Results are tracked in the `results` table with:
  - `name` - Result identifier
  - `type` - Type of result (e.g. "model", "notebook")
  - `blind` - Whether the result is blinded (encrypted)
  - `comment` - Optional description
  - `hash` - File hash for integrity checking
  - `last_read_at` - Last time the result was read
  - `created_at` - When the result was first created
  - `updated_at` - When the result was last updated
- Hash verification ensures result integrity

#### Results Functions

- `save_result(name, value, type, blind = FALSE, comment = NULL)` - Save a result
- `get_result(name)` - Get a result
- `list_results()` - List all results

#### Blinded Results

- Results can be marked as "blind" during saving
- Blinded results are encrypted using the `results_key` from config
- Only users with the key can view blinded results

Example usage:
```r
# Save a model result
save_result("model1", model_output, type = "model", comment = "Initial model")

# Save a blinded result
save_result("model2", model_output, type = "model", blind = TRUE)

# Save a notebook
save_result("report.html", file = "Example-Notebook.html", type = "report", blind = FALSE, public = TRUE)


# Get a result
result <- get_result("model1")

# List all results
results <- list_results()

```

### Database Queries

#### Local SQLite

```r
# Execute a query that returns data
data <- get_query("SELECT * FROM users", "sqlite")

# Execute a command that modifies data
execute_query("INSERT INTO users (name) VALUES ('John')", "sqlite")
```

#### Remote PostgreSQL

First, configure your PostgreSQL connection in `config.yml`:

```yaml
connections:
  postgres:
    driver: "postgresql"
    host: !expr Sys.getenv("DB_HOST")
    port: !expr Sys.getenv("DB_PORT")
    database: !expr Sys.getenv("DB_DATABASE")
    schema: !expr Sys.getenv("DB_SCHEMA", "public")  # Default to public if not set
    user: !expr Sys.getenv("DB_USERNAME")
    password: !expr Sys.getenv("DB_PASSWORD")
```

Then set your environment variables in `.env`:

```env
DB_HOST=localhost
DB_PORT=5432
DB_DATABASE=my_database
DB_SCHEMA=my_schema  # Optional, defaults to public
DB_USERNAME=my_user
DB_PASSWORD=my_password
```

Now you can query the database:

```r
# Get data from a query
data <- get_query("SELECT * FROM users", "postgres")

# Execute a command
execute_query("INSERT INTO users (name) VALUES ('John')", "postgres")

# Use schema-specific queries
data <- get_query("SELECT * FROM my_schema.users", "postgres")
```

## Functions Directory

The `functions/` directory contains custom functions that are used throughout the project.

## Tooling

The framework includes several tooling files to help with development and code quality:

### .lintr

The `.lintr` file is used by the `lintr` package to enforce code style and consistency.

### .styler.R

The `.styler.R` file is used by the `styler` package to enforce code style and consistency.

### .editorconfig

The `.editorconfig` file is used by text editors to enforce code style and consistency.

## Roadmap

The following features will be implemented soon:

* More file types support:
  - Excel
  - Stata
  - SAS
* Improved helper functions for data files:
  - Automatic reports on variables documented in the data yaml files
  - Automatic validation on variables documented in the data yaml files
  - Documentation scaffolding in Quarto
  - Codebook scaffolding using data from the variables yaml and Quarto
* Improved security features
  - A private flag on data files that checks the gitignore to ensure 
  - A private flag for publishing results that checks the gitignore
* Configurable directories for cached data and results using config.yml
* Improved connections support
  * Supporting network attached storage on connections with helpers to map them
  * MySQL, SQLServer, Spark, Snowflake support
  * ODBC/JDBC support for arbitrary database drivers

## Contributing

If you're interested in contributing to the framework, make a pull request or email me below.

## License

The framework is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.

## Author

The framework was created by [Erik Westlund](https://github.com/erikwestlund).