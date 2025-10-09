# renv Integration

Framework provides optional integration with renv for reproducible package management.

## Philosophy

**renv is OFF by default and requires explicit opt-in.**

While renv provides excellent reproducibility guarantees, it adds complexity and performance overhead (5-10s per package operation) that most data analysts don't need for exploratory work. Framework's renv integration follows these principles:

1. **Opt-in, not forced**: Users choose when they need reproducibility
2. **Educational, not prescriptive**: First scaffold shows a tip about renv, easily suppressible
3. **Simple abstractions**: Wrap renv's complex CLI behind Framework's simple functions
4. **config.yml as source of truth**: One-way sync from config to renv.lock

## Enabling renv

```r
# In your project directory
renv_enable()
```

This will:
- Initialize renv (if not already initialized)
- Create `.framework_renv_enabled` marker file
- Sync packages from `config.yml` to renv
- Update `.gitignore` with renv directories
- Create snapshot in `renv.lock`

## Disabling renv

```r
# Disable but keep renv.lock for future use
renv_disable()

# Disable and remove all renv files
renv_disable(keep_renv = FALSE)
```

## Version Pinning Syntax

Framework supports version pinning in `config.yml` whether or not renv is enabled:

```yaml
packages:
  - dplyr              # Latest from CRAN
  - ggplot2@3.4.0     # Specific CRAN version
  - tidyverse/dplyr    # GitHub repo (default branch)
  - tidyverse/dplyr@main  # GitHub repo with specific ref
```

When renv is enabled, Framework routes package installations through `renv::install()`. When disabled, it uses `install.packages()` and `remotes::install_version()` / `remotes::install_github()`.

## Helper Functions

Framework provides simple wrappers around renv's functions:

### packages_snapshot()

Save current package versions to `renv.lock`:

```r
packages_snapshot()
```

Use this after installing new packages to update the lockfile.

### packages_restore()

Restore packages from `renv.lock`:

```r
packages_restore()
```

Use this when setting up a project on a new machine or after pulling changes.

### packages_status()

Check if packages are out of sync with `renv.lock`:

```r
packages_status()
```

### packages_update()

Update packages:

```r
# Update all packages
packages_update()

# Update specific packages
packages_update(c("dplyr", "ggplot2"))
```

## Educational Messaging

On first `scaffold()` in a new project, Framework shows a one-time message:

```
ℹ Reproducibility Tip

Framework can manage your R package versions with renv for reproducibility.
This ensures your project uses consistent package versions across environments.

To enable: renv_enable()
To disable this message: Set 'options: renv_nag: false' in config.yml
Learn more: ?renv_enable
```

Suppress this message by adding to `config.yml`:

```yaml
options:
  renv_nag: false
```

The message is automatically suppressed:
- After the first scaffold (tracked via `.framework_scaffolded` marker)
- When renv is already enabled
- When `options: renv_nag: false` in config.yml

## How It Works

### Detection

Framework checks for `.framework_renv_enabled` marker file:

```r
renv_enabled()  # TRUE if marker exists, FALSE otherwise
```

### Installation Routing

When you run `scaffold()`, Framework:

1. Reads packages from `config.yml`
2. Checks if renv is enabled via `renv_enabled()`
3. Routes installation through either:
   - `renv::install()` if renv enabled
   - `install.packages()` / `remotes::install_*()` if renv disabled

### Sync Strategy

Framework uses **one-way sync** from `config.yml` → `renv.lock`:

1. You edit `packages:` list in `config.yml`
2. Run `scaffold()` or `renv_enable()` to install packages
3. Run `packages_snapshot()` to update `renv.lock`

This keeps `config.yml` as the single source of truth and avoids bidirectional sync complexity.

## Files and Markers

### .framework_renv_enabled

Marker file indicating renv is enabled for this project. Contains timestamp of when renv was enabled.

**Gitignored by default** - each developer chooses whether to use renv.

### .framework_scaffolded

Tracks scaffold history. First line contains "First scaffolded at: [timestamp]", used to suppress educational messaging after initial scaffold.

**Gitignored by default** - local state, not shared.

### renv.lock

Standard renv lockfile. **Should be committed to git** for reproducibility.

### renv/

renv's package cache. **Gitignored by default** - regenerated from renv.lock.

## Best Practices

### When to Enable renv

✅ **Enable renv when:**
- Sharing analysis with collaborators who need exact package versions
- Publishing research that must be reproducible
- Deploying to production environments
- Working with external stakeholders who may run code months/years later

❌ **Skip renv when:**
- Doing exploratory data analysis
- Working solo on internal projects
- Prioritizing speed over reproducibility
- Learning R or prototyping

### Workflow Recommendations

**Solo exploratory work:**
```r
# Just use latest packages, no renv
scaffold()
```

**Collaborative project:**
```r
# Enable renv once project is stable
renv_enable()

# After installing new packages
packages_snapshot()

# Commit renv.lock to git
```

**Setting up existing project:**
```r
# Clone repo
git clone ...

# Restore packages from renv.lock (if project uses renv)
renv_enable()
packages_restore()

# Or just use latest packages (if you prefer)
scaffold()
```

## Troubleshooting

### "renv package is required but not installed"

Install renv:

```r
install.packages("renv")
```

### Packages out of sync

Check status:

```r
packages_status()
```

Restore from lockfile:

```r
packages_restore()
```

Or update lockfile to match current state:

```r
packages_snapshot()
```

### Slow package installation

This is expected with renv - it verifies package integrity and maintains a cache. To disable:

```r
renv_disable()
```

Your packages remain installed, but future installations will use standard `install.packages()`.

## Implementation Details

### Package Specification Parsing

`.parse_package_spec()` handles:
- `"dplyr"` → `{name: "dplyr", source: "cran", version: NULL}`
- `"dplyr@1.1.0"` → `{name: "dplyr", source: "cran", version: "1.1.0"}`
- `"user/repo"` → `{name: "repo", source: "github", repo: "user/repo", ref: "HEAD"}`
- `"user/repo@branch"` → `{name: "repo", source: "github", repo: "user/repo", ref: "branch"}`

### Installation Functions

- `.install_package_renv(spec)` - Uses `renv::install()` with version/ref
- `.install_package_base(spec)` - Uses `install.packages()` or `remotes::install_*()`

### Sync Function

`.sync_packages_to_renv()`:
1. Reads `config.yml` packages list
2. Parses each package spec
3. Installs via `renv::install()` if missing or version mismatch
4. Calls `renv::snapshot()` to update renv.lock

## Architecture Decision Record

**Decision**: Opt-in renv integration (OFF by default)

**Context**: Data analysts need reproducibility sometimes, but not always. renv adds 5-10s overhead per package operation.

**Considered Alternatives**:
1. Always-on renv (rejected - too prescriptive, slows exploratory work)
2. Opt-in renv with educational messaging (CHOSEN - balances flexibility and education)
3. Manual renv setup with no Framework integration (rejected - misses opportunity to simplify)

**Rationale**:
- Aligns with industry standards (Python venv, RStudio all opt-in)
- Educational message plants reproducibility seed without forcing
- Analysts adopt when they feel the pain (collaboration, publication)
- Framework's mission: simplify workflows, not enforce them

**Multi-model Consensus**: Gemini 2.5 Pro, Deepseek R1, Claude Opus unanimously agreed (8-9/10 confidence) on opt-in approach even when given opposing stances.
