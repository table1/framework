# Explore Framework Site Audit

Audit of the "Explore Framework" tabbed section on the Framework marketing site against the actual R package implementation.

**Audit Date:** 2025-12-03
**Site File:** `framework-site/resources/views/home.antlers.html`
**Package Version:** 0.1.0 (pre-release)

---

## Summary

| Tab | Status | Issues |
|-----|--------|--------|
| Project Setup | ✅ FIXED | Updated to show `settings.yml` as config file |
| Project Types | ✅ FIXED | Added `reference/` directories to match `settings-catalog.yml` |
| Data Catalog | ✅ FIXED | Updated config label to `settings.yml (data section)` |
| Data Integrity | ✅ FIXED | Updated config label to `settings.yml (data section)` |
| Notebooks | ✅ FIXED | Changed template path to `stubs/` with `stubs_publish()` |
| Packages | OK | Correctly shows `settings.yml` |
| Databases | OK | Functions and `env()` syntax verified |
| Easy Renv | ✅ FIXED | Changed to `packages_snapshot()` and `packages_restore()` |
| Publishing | OK | `publish_notebook()` exists and verified |
| Caching | ✅ FIXED | Changed to `cache_get()` and `cache_forget()` |
| AI Agents | ✅ FIXED | Changed to `settings.yml` with `ai:` and `git:` sections |
| Security | OK | `git_security_audit()` exists and verified |

**All issues have been resolved as of 2025-12-03.**

---

## Tab 1: Project Setup (scaffold)

### Site Claims
- `library(framework)` + `scaffold()` loads packages from `settings/packages.yml`
- Automatically sources files in `functions/`
- `data_read("inputs.raw.survey")` reads from data catalog in `settings/data.yml`

### Verification

| Claim | Status | Notes |
|-------|--------|-------|
| `scaffold()` function | ✅ EXISTS | Exported in NAMESPACE |
| `data_read()` function | ✅ EXISTS | Exported in NAMESPACE |
| Sources `functions/` dir | ✅ CORRECT | Verified in scaffold.R |
| Packages from `settings/packages.yml` | ⚠️ PARTIAL | Packages can be inline in `settings.yml` OR in split `settings/packages.yml` |

### Recommended Fix
- Change "settings/packages.yml" to "settings.yml" or clarify that split files are optional

---

## Tab 2: Project Types

### Site Claims
Shows 4 project types with directory structures:
1. **Project** - inputs/, notebooks/, scripts/, functions/, settings.yml
2. **Project Sensitive** - inputs/private/, inputs/public/, etc.
3. **Course** - data/, slides/, assignments/, course_docs/, readings/
4. **Presentation** - presentation.qmd, settings.yml

### Verification

| Project Type | Status | Notes |
|--------------|--------|-------|
| project | ⚠️ PARTIAL | Actual defaults include more dirs; site shows simplified view |
| project_sensitive | ⚠️ PARTIAL | Site doesn't show all input subdirectories |
| course | ✅ MOSTLY CORRECT | Minor differences in optional dirs |
| presentation | ✅ CORRECT | Minimal structure matches |

### Discrepancies in `settings-catalog.yml`

**Project type actual defaults:**
- `inputs_raw`, `inputs_intermediate`, `inputs_final`, `inputs_reference` (not just `inputs/raw`, `intermediate`, `final`)
- `outputs_tables`, `outputs_figures`, `outputs_models`, `outputs_reports` (site shows `outputs/tables/figures/models/reports/`)
- `cache` and `scratch` are marked `enabled_by_default: false`

**Site shows:**
```
my-project/
├── inputs/
│   ├── raw/
│   ├── intermediate/
│   └── final/
├── notebooks/
├── scripts/
├── functions/
└── settings.yml
```

**Actual default (enabled_by_default: true):**
```
my-project/
├── inputs/
│   ├── raw/
│   ├── intermediate/
│   └── final/
│   └── reference/    # ← Missing from site
├── notebooks/
├── scripts/
├── functions/
└── settings.yml
```

### Recommended Fix
- Update directory trees to match `settings-catalog.yml` `enabled_by_default: true` directories
- Note: `inputs_reference` is enabled by default but missing from site
- The "All Options" view should include `docs/`, `outputs/tables/`, `outputs/figures/`, etc.

---

## Tab 3: Data Catalog

### Site Claims
- Config in `settings/data.yml`
- `data_read("inputs.raw.survey")` - read by catalog name
- `data_list()` - list available data
- `data_save("inputs.final.analysis_ready", df)` - save to catalog

### Verification

| Function | Status | Notes |
|----------|--------|-------|
| `data_read()` | ✅ EXISTS | Exported in NAMESPACE |
| `data_list()` | ✅ EXISTS | Exported in NAMESPACE |
| `data_save()` | ✅ EXISTS | Exported in NAMESPACE |
| Dot notation | ✅ CORRECT | `inputs.raw.survey` works |
| `locked` option | ✅ EXISTS | Verified in data_read.R |

### Status: OK

---

## Tab 4: Data Integrity

### Site Claims
- Hashes stored in `framework.db`
- `locked: true` in config aborts if file changed
- `data_read(..., locked = TRUE)` inline lock

### Verification

| Feature | Status | Notes |
|---------|--------|-------|
| Hash tracking | ✅ EXISTS | Implemented in data_read.R |
| `locked` config option | ✅ EXISTS | Verified |
| `locked` parameter | ✅ EXISTS | `data_read(..., locked = TRUE)` works |
| framework.db | ✅ EXISTS | SQLite database for tracking |

### Status: OK

---

## Tab 5: Notebooks

### Site Claims
- Config in `settings/quarto.yml` with `html:`, `render_dirs:`
- `make_notebook("analysis")` creates from template
- `make_script("etl")` creates script
- Global templates in `~/.config/framework/templates/`

### Verification

| Claim | Status | Notes |
|-------|--------|-------|
| `make_notebook()` | ✅ EXISTS | Exported in NAMESPACE |
| `make_script()` | ✅ EXISTS | Exported in NAMESPACE |
| `settings/quarto.yml` | ❌ WRONG | Quarto config is in main `settings.yml` under `quarto:` key, not split file |
| `~/.config/framework/templates/` | ❌ WRONG | Templates are in project-local `stubs/` directory |

### Actual Template System
- Templates ("stubs") are in `stubs/` directory at project root
- Or fall back to package's `inst/stubs/`
- Use `stubs_publish()` to copy stubs to project for customization
- Use `stubs_list()` to see available stubs
- Use `stubs_path()` to get stubs directory

### Recommended Fixes
1. Change `settings/quarto.yml` to show config is in main `settings.yml` under `quarto:` key
2. Change `~/.config/framework/templates/` to `stubs/` directory
3. Mention `stubs_publish()` for customizing templates

---

## Tab 6: Packages

### Site Claims
- Config in `settings.yml` with `packages:` array
- Each package has `name:` and `auto_attach:`
- `scaffold()` installs and loads

### Verification

| Claim | Status | Notes |
|-------|--------|-------|
| Package config format | ⚠️ PARTIAL | Format is correct but label shows `settings.yml` while tab intro says `settings/packages.yml` |
| `auto_attach` option | ✅ CORRECT | Verified in settings-catalog.yml |
| `scaffold()` handles packages | ✅ CORRECT | Verified in scaffold.R |
| `gui()` for package management | ✅ EXISTS | Exported in NAMESPACE |

### Recommended Fix
- Be consistent: either `settings.yml` (inline) or `settings/packages.yml` (split file)
- The example shows `settings.yml` which is correct for inline config

---

## Tab 7: Databases

### Site Claims
- Config in `settings/connections.yml`
- `env("DB_HOST")` syntax for environment variables
- `db_query()`, `db_execute()`, `db_connect()`
- Supports SQLite, PostgreSQL, MySQL, MariaDB, SQL Server, DuckDB

### Verification

| Claim | Status | Notes |
|-------|--------|-------|
| `settings/connections.yml` | ✅ CORRECT | Split file is supported |
| `env()` syntax | ✅ EXISTS | Implemented in config.R:386-396 |
| `db_query()` | ✅ EXISTS | Exported in NAMESPACE |
| `db_execute()` | ✅ EXISTS | Exported in NAMESPACE |
| `db_connect()` | ✅ EXISTS | Exported in NAMESPACE |
| Database drivers | ✅ CORRECT | All listed drivers supported via DBI |

### Status: OK

---

## Tab 8: Easy Renv

### Site Claims
- Config in `settings/packages.yml` with `version:` pinning
- `renv_enable()` to enable
- `scaffold()` installs pinned versions
- `renv_snapshot()` and `renv_restore()`

### Verification

| Claim | Status | Notes |
|-------|--------|-------|
| `renv_enable()` | ✅ EXISTS | Exported in NAMESPACE |
| `renv_disable()` | ✅ EXISTS | Exported in NAMESPACE |
| `renv_snapshot()` | ⚠️ EXISTS but... | Exists but `packages_snapshot()` is the preferred public wrapper |
| `renv_restore()` | ❌ NOT EXPORTED | Use `packages_restore()` instead |
| Version pinning | ✅ CORRECT | Verified in settings-catalog.yml |

### Actual Exported Functions
- `renv_enable()`, `renv_disable()`, `renv_enabled()` - renv management
- `packages_snapshot()`, `packages_restore()`, `packages_status()`, `packages_update()` - package management

### Recommended Fixes
1. Change `renv_snapshot()` to `packages_snapshot()`
2. Change `renv_restore()` to `packages_restore()`

---

## Tab 9: Publishing

### Site Claims
- S3 config in `settings/connections.yml` under `s3:` key
- `publish_notebook("analysis.qmd")`
- `publish_notebook(..., connection = "public_docs")`
- Supports AWS S3, Cloudflare R2, MinIO, DigitalOcean Spaces

### Verification

| Claim | Status | Notes |
|-------|--------|-------|
| `publish_notebook()` | ✅ EXISTS | Exported in NAMESPACE |
| S3 config format | ✅ CORRECT | Verified in settings-catalog.yml |
| `connection` parameter | ✅ EXISTS | Verified in connections_s3.R |
| S3-compatible storage | ✅ CORRECT | Uses aws.s3 package |

### Status: OK

---

## Tab 10: Caching

### Site Claims
- `cache_remember("key", { expr }, expire = "1 hour")`
- `cache_list()` - check what's cached
- `cache_read("key")` - read without recomputing
- `cache_delete("key")` - clear specific cache
- `cache_flush()` - clear all caches

### Verification

| Function | Status | Notes |
|----------|--------|-------|
| `cache_remember()` | ✅ EXISTS | Exported in NAMESPACE |
| `cache_list()` | ❌ NOT EXPORTED | Does not exist |
| `cache_read()` | ❌ NOT EXPORTED | Does not exist |
| `cache_delete()` | ❌ NOT EXPORTED | Does not exist |
| `cache_flush()` | ✅ EXISTS | Exported in NAMESPACE |
| `cache_get()` | ✅ EXISTS | Exported (alternative to cache_read) |
| `cache_forget()` | ✅ EXISTS | Exported (alternative to cache_delete) |
| `cache()` | ✅ EXISTS | Exported (for writing) |

### Actual Exported Cache Functions
- `cache_remember(name, expr, ...)` - Fetch from cache or compute
- `cache_get(name, ...)` - Read from cache (returns NULL if missing)
- `cache(name, value, ...)` - Write to cache
- `cache_forget(name, ...)` - Delete specific cache entry
- `cache_flush()` - Clear all cache entries

### Recommended Fixes
1. Change `cache_list()` to... (no direct equivalent, could show `list.files(config("cache"))`)
2. Change `cache_read()` to `cache_get()`
3. Change `cache_delete()` to `cache_forget()`

---

## Tab 11: AI Agents

### Site Claims
- Config in `settings/ai.yml` with `context:`, `canonical:`, `sync_to:`
- `git_hooks_install()` to install hooks
- Syncs CLAUDE.md to AGENTS.md, COPILOT.md on commit

### Verification

| Claim | Status | Notes |
|-------|--------|-------|
| `git_hooks_install()` | ✅ EXISTS | Exported in NAMESPACE |
| `settings/ai.yml` | ❌ WRONG | AI config is in main `settings.yml` under `ai:` key |
| Sync functionality | ✅ EXISTS | Implemented via git hooks |

### Actual AI Config Location
AI settings are in main `settings.yml`:
```yaml
ai:
  canonical_file: "CLAUDE.md"  # Options: AGENTS.md, CLAUDE.md, .github/copilot-instructions.md
```

Or via split file reference in project_create.R but not a standalone `settings/ai.yml`.

### Recommended Fixes
1. Change config example to show it's in main `settings.yml` under `ai:` key, not `settings/ai.yml`
2. Show actual config format:
   ```yaml
   ai:
     canonical_file: "CLAUDE.md"
   ```

---

## Tab 12: Security

### Site Claims
- Auto-generated `.gitignore` with private directories
- `git_security_audit()` checks for exposure

### Verification

| Claim | Status | Notes |
|-------|--------|-------|
| `git_security_audit()` | ✅ EXISTS | Exported in NAMESPACE |
| Gitignore templates | ✅ EXISTS | `gitignore-project`, `gitignore-sensitive`, etc. in inst/templates/ |
| Private directory exclusion | ✅ CORRECT | Verified in gitignore templates |

### Status: OK

---

## Action Items

### Critical (Incorrect Information)
1. **Caching tab**: Replace `cache_list()`, `cache_read()`, `cache_delete()` with actual functions
2. **Notebooks tab**: Change template path from `~/.config/framework/templates/` to `stubs/`
3. **AI tab**: Change `settings/ai.yml` to show config is in main `settings.yml`
4. **Easy Renv tab**: Use `packages_snapshot()`/`packages_restore()` instead of `renv_*` functions

### Minor (Clarification Needed)
5. **Project Setup**: Clarify packages can be inline in `settings.yml` or split to `settings/packages.yml`
6. **Packages tab**: Be consistent about `settings.yml` vs `settings/packages.yml`
7. **Notebooks tab**: Change `settings/quarto.yml` to show quarto config is in main `settings.yml`
8. **Project Types**: Update directory trees to match actual defaults from `settings-catalog.yml`

---

## Reference: Actual Exported Functions

From NAMESPACE file:

```
# Cache
cache, cache_flush, cache_forget, cache_get, cache_remember

# Data
data_add, data_list, data_read, data_read_or_cache, data_save, data_spec_get, data_spec_update

# Database
db_connect, db_drivers_install, db_drivers_status, db_execute, db_list, db_query, db_transaction, db_with

# Git
git_add, git_commit, git_diff, git_hooks_disable, git_hooks_enable, git_hooks_install,
git_hooks_list, git_hooks_uninstall, git_log, git_pull, git_push, git_security_audit, git_status

# Notebooks/Scripts
make_notebook, make_presentation, make_qmd, make_revealjs, make_rmd, make_script

# Packages
packages_install, packages_list, packages_restore, packages_snapshot, packages_status, packages_update

# Publishing
publish, publish_data, publish_dir, publish_list, publish_notebook

# Renv
renv_disable, renv_enable, renv_enabled

# Stubs/Templates
stubs_list, stubs_path, stubs_publish

# Other
ai_generate_context, ai_regenerate_context, ai_sync_context
configure_global
gui
scaffold, setup, status
settings, settings_read, settings_write
```
