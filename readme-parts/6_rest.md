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
| `cli_install()` | Install Framework CLI tool |
| `cli_uninstall()` | Remove Framework CLI tool |
| `cli_update()` | Update Framework and CLI to latest version |
| `renv_enable()` | Enable renv for reproducibility (opt-in) |
| `renv_disable()` | Disable renv integration |
| `packages_snapshot()` | Save package versions to renv.lock |
| `packages_restore()` | Restore packages from renv.lock |
| `security_audit()` | Scan for data leaks and security issues |

## Data Integrity & Security

- **Hash tracking** - All data files tracked with SHA-256 hashes
- **Locked data** - Flag files as read-only, errors on modification
- **Encryption** - AES encryption for sensitive data/results
- **Gitignore by default** - Private directories auto-ignored
- **Security audits** - Comprehensive security scanning with `security_audit()`

### Security Auditing

Framework includes `security_audit()` to detect data leaks and security issues:

```r
# Run comprehensive security audit
audit <- security_audit()

# Quick audit (skip git history)
audit <- security_audit(check_git_history = FALSE)

# Auto-fix issues (updates .gitignore)
audit <- security_audit(auto_fix = TRUE)

# Limit git history depth for faster scanning
audit <- security_audit(history_depth = 100)
```

**What it checks:**
- **Gitignore coverage**: Verifies private data directories are in `.gitignore`
- **Private data exposure**: Detects if private data files are tracked by git
- **Git history leaks**: Scans commit history for accidentally committed sensitive data
- **Orphaned files**: Finds data files outside configured directories

**Example output:**
```r
=== Security Audit Summary ===

✓ PASS: gitignore coverage (0 issues)
✓ PASS: private data exposure (0 issues)
✗ FAIL: git history (2 issues)
⚠ WARNING: orphaned files (3 issues)

=== Recommendations ===

  - CRITICAL: Private data files found in git history!
  - Consider using git-filter-repo to remove sensitive data
  - Found 3 data file(s) outside configured directories
  - Move orphaned files to appropriate data directories

✗ AUDIT FAILED - Critical security issues found
```

**Results structure:**
```r
str(audit, max.level = 2)
# List of 4
#  $ summary        : data.frame with check names, status, counts
#  $ findings       : List of 4
#   ..$ gitignore_issues      : data.frame
#   ..$ git_history_issues    : data.frame
#   ..$ orphaned_files        : data.frame
#   ..$ private_data_exposure : data.frame
#  $ recommendations: Character vector of actionable fixes
#  $ audit_metadata : List with timestamp, framework version, config
```

**Integration with CI/CD:**
```r
# In your CI pipeline or pre-commit hook
audit <- security_audit(verbose = FALSE)
if (any(audit$summary$status == "fail")) {
  stop("Security audit failed! Review findings.")
}
```

## Reproducibility with renv

Framework includes **optional** [renv](https://rstudio.github.io/renv/) integration for package version control (OFF by default, opt-in):

### Quick Start

```r
# Enable renv for this project (one-time setup)
renv_enable()

# That's it! Framework handles the rest automatically:
# ✓ Installs framework, styler, rmarkdown, and your config.yml packages
# ✓ Creates renv.lock with exact versions
# ✓ Updates .gitignore to exclude renv cache
```

### How It Works

**When you enable renv:**
1. Framework automatically installs essential packages:
   - `framework` (from GitHub: table1/framework)
   - `styler` (if you enabled it during init, default: TRUE)
   - `rmarkdown` (needed by Quarto for R code chunks)
   - All packages listed in `config.yml`

2. Creates `renv.lock` - a snapshot of exact package versions

3. Other collaborators just need to run:
   ```r
   # In a fresh clone of your project:
   library(framework)
   packages_restore()  # Installs exact versions from renv.lock
   ```

**When to use renv:**
- Publishing research that needs exact reproducibility
- Collaborating with others who need identical package versions
- Long-term projects where package updates might break code
- Archiving projects with specific package dependencies

**When you might not need it:**
- Quick exploratory analysis
- Solo projects with minimal dependencies
- Projects where latest package versions are preferred

### Package Management

```r
# Check package status
packages_status()

# Install new package (automatically added to renv.lock)
install.packages("newpackage")

# Update renv.lock after changes
packages_snapshot()

# Restore from renv.lock (e.g., after git clone)
packages_restore()

# Update all packages to latest versions
packages_update()

# Disable renv if you change your mind
renv_disable()  # Keeps renv.lock for future use
```

### Version Pinning in config.yml

Control exact package versions in your config:

```yaml
packages:
  - dplyr                    # Latest from CRAN
  - ggplot2@3.4.0           # Specific CRAN version
  - tidyverse/dplyr@main    # GitHub repo with branch/tag
  - user/package@v1.2.3     # GitHub with specific tag
```

When you run `renv_enable()` or `packages_snapshot()`, Framework installs these exact versions and records them in `renv.lock`.

### Why Framework's renv is Different

Unlike vanilla renv, Framework's integration:
- **Automatically handles framework itself** (installs from GitHub)
- **No "out of sync" warnings** - styler and rmarkdown handled automatically
- **Zero configuration** - just enable and go
- **Works with config.yml** - packages defined in one place
- **Clean, quiet output** - no overwhelming install logs

See [renv integration docs](docs/features/renv_integration.md) for advanced usage.

## Roadmap

- Excel file support
- Quarto codebook generation
