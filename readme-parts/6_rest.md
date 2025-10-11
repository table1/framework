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

Reference in config (two syntaxes supported):
```yaml
# Recommended: Clean env() syntax
security:
  data_key: env("DATA_ENCRYPTION_KEY")
connections:
  db:
    host: env("DB_HOST")
    password: env("DB_PASS", "default_password")  # With default

# Also works: Traditional !expr syntax
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
| `renv_enable()` | Enable renv for reproducibility (opt-in) |
| `renv_disable()` | Disable renv integration |
| `packages_snapshot()` | Save package versions to renv.lock |
| `packages_restore()` | Restore packages from renv.lock |

## Data Integrity & Security

- **Hash tracking** - All data files tracked with SHA-256 hashes
- **Locked data** - Flag files as read-only, errors on modification
- **Encryption** - AES encryption for sensitive data/results
- **Gitignore by default** - Private directories auto-ignored

## Reproducibility with renv

Framework includes **optional** renv integration (OFF by default):

```r
# Enable renv for this project
renv_enable()

# Your packages are now managed by renv
# Use snapshot after installing new packages
packages_snapshot()

# Disable renv if you prefer
renv_disable()
```

**Version pinning in config.yml:**
```yaml
packages:
  - dplyr              # Latest from CRAN
  - ggplot2@3.4.0     # Specific version
  - tidyverse/dplyr@main  # GitHub with ref
```

See [renv integration docs](docs/features/renv_integration.md) for details.

## Roadmap

- Excel file support
- Quarto codebook generation
