# Framework

A lightweight R package for structured, reproducible data analysis projects. Convention over configuration.

**⚠️ Active Development:** APIs may change. Version 1 with stable API coming soon.

## Quick Start

**Easiest way:** Clone the [framework-project template](https://github.com/table1/framework-project) (see below)

**Install package:**
```r
# Install from GitHub
devtools::install_github("table1/framework")
```

## What It Does

Framework reduces boilerplate and enforces best practices for data analysis:

- **Project scaffolding** - Standardized directories, config-driven setup
- **Data management** - Declarative data catalog, integrity tracking, encryption
- **Auto-loading** - Packages and custom functions loaded automatically
- **Caching** - Smart caching for expensive computations
- **Database helpers** - PostgreSQL, SQLite with credential management
- **Results tracking** - Save/retrieve analysis outputs with blinding support
- **Supported formats** - CSV, TSV, RDS, Stata (.dta), SPSS (.sav), SAS (.xpt, .sas7bdat)

## Framework Project Template

The fastest way to start is using the pre-configured template:

```bash
git clone https://github.com/table1/framework-project my-project
cd my-project
```

Open in RStudio/VS Code, review `init.R`, then run:
```r
framework::init()
```

This creates a complete project structure with config files, .gitignore, and tooling.

## Project Structure

```
project/
├── data/
│   ├── source/private/      # Raw data (gitignored)
│   ├── source/public/       # Public raw data
│   ├── cached/             # Computation cache (gitignored)
│   └── final/private/      # Results (gitignored)
├── work/                   # Scripts and notebooks
├── functions/              # Custom functions
├── results/private/        # Analysis outputs (gitignored)
├── config.yml             # Project configuration
├── framework.db           # Metadata/tracking database
└── .env                   # Secrets (gitignored)
```

Minimal structure also available - see template for options.

## Core Workflow

### 1. Initialize Your Session

```r
library(framework)
scaffold()  # Loads packages, functions, config
```

### 2. Load Data

**Via config:**
```yaml
# config.yml or settings/data.yml
data:
  source:
    private:
      survey:
        path: data/source/private/survey.dta
        type: stata
        locked: true
```

```r
# Load using dot notation
df <- data_load("source.private.survey")
```

**Direct path:**
```r
df <- data_load("data/my_file.csv")       # CSV
df <- data_load("data/stata_file.dta")    # Stata
df <- data_load("data/spss_file.sav")     # SPSS
```

Statistical formats (Stata/SPSS/SAS) strip metadata by default for safety. Use `keep_attributes = TRUE` to preserve labels.

### 3. Cache Expensive Operations

```r
model <- get_or_cache("model_v1", {
  expensive_model_fit(df)
}, expire_after = 1440)  # Cache for 24 hours
```

### 4. Save Results

```r
# Save data
data_save(processed_df, "final.private.clean", type = "csv")

# Save analysis output
result_save("regression_model", model, type = "model")

# Save notebook (blinded)
result_save("report", file = "report.html", type = "notebook",
            blind = TRUE, public = FALSE)
```

### 5. Query Databases

```yaml
# config.yml
connections:
  db:
    driver: postgresql
    host: !expr Sys.getenv("DB_HOST")
    database: !expr Sys.getenv("DB_NAME")
    user: !expr Sys.getenv("DB_USER")
    password: !expr Sys.getenv("DB_PASS")
```

```r
df <- query_get("SELECT * FROM users WHERE active = true", "db")
```

## Configuration

**Simple:**
```yaml
default:
  packages:
    - dplyr
    - ggplot2
  data:
    example: data/example.csv
```

**Advanced:** Split config into `settings/` files:
```yaml
default:
  data: settings/data.yml
  packages: settings/packages.yml
  connections: settings/connections.yml
  security: settings/security.yml
```

Use `.env` for secrets:
```env
DB_HOST=localhost
DB_PASS=secret
DATA_ENCRYPTION_KEY=key123
```

Reference in config:
```yaml
security:
  data_key: !expr Sys.getenv("DATA_ENCRYPTION_KEY")
```

## Key Functions

| Function | Purpose |
|----------|---------|
| `scaffold()` | Initialize session (load packages, functions, config) |
| `data_load()` | Load data from path or config |
| `data_save()` | Save data with integrity tracking |
| `query_get()` | Execute SQL query, return data |
| `query_execute()` | Execute SQL command |
| `get_or_cache()` | Lazy evaluation with caching |
| `result_save()` | Save analysis output |
| `result_get()` | Retrieve saved result |
| `scratch_capture()` | Quick debug/temp file save |

## Data Integrity & Security

- **Hash tracking** - All data files tracked with SHA-256 hashes
- **Locked data** - Flag files as read-only, errors on modification
- **Encryption** - AES encryption for sensitive data/results
- **Gitignore by default** - Private directories auto-ignored

## Roadmap

- Excel file support
- renv integration
- Quarto codebook generation
- MySQL, SQL Server, Snowflake connectors
- Enhanced validation system

## Contributing

Pull requests welcome. Email Erik Westlund for questions.

## License

MIT License - see [LICENSE](LICENSE)

## Author

Created by [Erik Westlund](https://github.com/erikwestlund)
