# Config System Overhaul - October 2025

## Summary

Complete overhaul of Framework's configuration system, implementing a Laravel-inspired hybrid approach that prioritizes discoverability while maintaining scalability. The new system is **production-ready** with 74 passing tests and zero failures.

## What Was Built

### 1. Laravel-Inspired Hybrid Config System

**Design Philosophy:**
- **Simple by default**: Single `settings.yml` file for most projects
- **Complex when needed**: Optional split files for domain-specific settings
- **Discoverable**: Directory paths visible immediately in main file
- **R conventions**: Follows R ecosystem pattern (like `_targets.R`, `_bookdown.yml`)

**Key Decision**: After consulting Zen (Gemini), moved directory settings from separate `settings/options.yml` into main `settings.yml` for better discoverability.

### 2. New `config()` Helper Function

Laravel-style dot-notation access with smart lookups:

```r
# Smart lookups
config("notebooks")              # → "notebooks"
config("scripts")                # → "scripts"

# Explicit nested paths
config("directories.notebooks")  # → "notebooks"
config("connections.db.host")    # → "localhost"

# With defaults
config("nonexistent", default = "fallback")  # → "fallback"
```

**Smart Resolution:**
- `config("notebooks")` checks:
  1. `directories$notebooks` (new structure)
  2. `options$notebook_dir` (legacy structure)
- Fully backward compatible

### 3. Updated Config Templates

**All Three Project Types Updated:**
- `inst/templates/config.project.fr.yml`
- `inst/templates/config.course.fr.yml`
- `inst/templates/config.presentation.fr.yml`

**New Structure:**
```yaml
default:
  project_type: project

  # --------------------------------------------------------------------------
  # Project Directories (inline for discoverability)
  # --------------------------------------------------------------------------
  directories:
    notebooks: notebooks
    scripts: scripts
    functions: functions
    inputs_raw: inputs/raw
    inputs_intermediate: inputs/intermediate
    inputs_final: inputs/final
    inputs_reference: inputs/reference
    outputs_private: outputs/private
    outputs_public: outputs/public
    outputs_docs: outputs/private/docs
    outputs_docs_public: outputs/public/docs
    outputs_final: outputs/private/final
    outputs_final_public: outputs/public/final
    cache: outputs/private/cache
    scratch: outputs/private/scratch

  # --------------------------------------------------------------------------
  # Domain-Specific Settings (optional split files)
  # --------------------------------------------------------------------------
  data: settings/data.yml           # Large data catalog
  connections: settings/connections.yml  # Database connections
  packages: settings/packages.yml
```

### 4. Enhanced `read_config()`

- Treats `directories` as top-level section (alongside data, connections, packages)
- Properly merges directories with defaults using `modifyList()`
- Handles `project_type` metadata at top level
- Backward compatible with legacy `options$notebook_dir`

### 5. Updated `make_notebook()`

Directory detection priority:
1. `config$directories$notebooks` (new structure)
2. `config$options$notebook_dir` (legacy structure)
3. `notebooks/` directory exists
4. `work/` directory exists (legacy)
5. Current directory (`.`)

### 6. Comprehensive Test Suite

**74 Config Tests Passing** covering:
- ✅ Flat config with inline directories
- ✅ Split file approach (data, connections separate)
- ✅ `config()` helper with dot-notation
- ✅ Smart lookups checking multiple locations
- ✅ Legacy backward compatibility
- ✅ Priority resolution (new over legacy)
- ✅ All three project types
- ✅ Nested path access
- ✅ Default values and NULL handling
- ✅ Integration with `make_notebook()`

### 7. Test Cleanup

Fixed all tests to use correct function names after alias removal:
- `save_result()` → `result_save()`
- `get_result()` → `result_get()`
- `list_results()` → `result_list()`
- `get_query()` → `query_get()`
- `execute_query()` → `query_execute()`
- `capture()` → `scratch_capture()`
- `clean_scratch()` → `scratch_clean()`

**Final Test Results: 302 Passing, 0 Failures** ✅

## Files Modified

### R Code
- `R/config.R` - Added `config()` helper, updated `read_config()` logic
- `R/make_notebook.R` - Updated directory detection for new structure

### Templates
- `inst/templates/config.project.fr.yml` - Inline directories, split file examples
- `inst/templates/config.course.fr.yml` - Course-specific directories
- `inst/templates/config.presentation.fr.yml` - Minimal presentation setup
- `inst/project_structure/project/settings.yml` - Updated split-file example
- `inst/project_structure/course/settings.yml` - Simplified course config (inline only)

### Tests
- `tests/testthat/test-config.R` - Added 20+ comprehensive config tests
- `tests/testthat/test-results.R` - Fixed function names
- `tests/testthat/test-queries.R` - Fixed function names
- `tests/testthat/test-scratch.R` - Fixed function names
- `tests/testthat/test-init.R` - Removed nonexistent `interactive` parameter

### Documentation
- `CLAUDE.md` - Complete config system documentation
- `docs/config_system_overhaul.md` - This document

### Removed
- `inst/templates/settings/options.fr.yml` - No longer needed
- `inst/project_structure/*/settings/options.yml` - No longer needed

## Design Rationale

### Why Directories in Main Config?

Based on consultation with Zen (Gemini 2.5 Pro), the decision was made to keep directories inline rather than in a separate file:

**Pros:**
1. **Discoverability**: Users see all configurable paths immediately
2. **R Conventions**: Aligns with R ecosystem (single primary config file)
3. **Zero Indirection**: Most common config task requires no file navigation
4. **Simplicity First**: 90% of users never need split files

**Cons (Addressed):**
1. ~~"Config file gets cluttered"~~ → Mitigated with clear section headers and comments
2. ~~"Not following Laravel exactly"~~ → Laravel pattern adapted for R data analyst audience

### What Goes in Split Files?

**Keep in main `settings.yml`:**
- Directory paths (most commonly changed)
- Project metadata
- Basic options

**Move to split files when:**
- Data catalog grows large (50+ entries)
- Multiple database connections with complex config
- Security settings with many environment variables
- Project becomes complex enough to warrant organization

## Backward Compatibility

**Legacy Structure Still Supported:**
```yaml
default:
  options:
    notebook_dir: work
    script_dir: scripts
```

**New Structure Preferred:**
```yaml
default:
  directories:
    notebooks: notebooks
    scripts: scripts
```

**Priority:** New structure takes precedence when both exist.

## Testing Strategy

### Test Coverage

1. **Flat Config Tests**
   - Inline directories
   - Direct access via `config()`
   - Project metadata

2. **Split File Tests**
   - Directories inline, data in split file
   - Graceful merging
   - Both access patterns work

3. **Legacy Compatibility Tests**
   - Old `options$notebook_dir` structure
   - Smart lookup fallback
   - Priority when both exist

4. **Integration Tests**
   - `make_notebook()` directory detection
   - All project types
   - Nested path access

5. **Edge Cases**
   - NULL handling
   - Default values
   - Missing keys
   - Empty configs

### Test Results

```
══ Results ═════════════════════════════════════════════════════════════════════
[ FAIL 0 | WARN 12 | SKIP 1 | PASS 302 ]
```

## Usage Examples

### Basic Usage

```r
# Load config
cfg <- read_config()

# Access directories (multiple ways)
config("notebooks")                  # Smart lookup
config("directories.notebooks")      # Explicit path
cfg$directories$notebooks            # Direct access

# Access nested settings
config("connections.db.host")
config("data.example.path")

# With defaults
config("missing", default = "fallback")
```

### Project Initialization

```r
# Create new project with inline directories
init(
  project_name = "MyProject",
  type = "project"
)

# Creates settings.yml with:
# - Inline directories section
# - Optional references to split files
# - Comprehensive inline comments
```

### Migration from Legacy

If you have an existing project with:
```yaml
options:
  notebook_dir: work
```

**No action needed!** The system automatically:
1. Checks new `directories$notebooks` first
2. Falls back to `options$notebook_dir`
3. Your code continues working

**To migrate** (optional):
```yaml
# Old structure
options:
  notebook_dir: work
  script_dir: scripts

# New structure
directories:
  notebooks: notebooks  # Changed name
  scripts: scripts
```

## Future Considerations

### Potential Enhancements

1. **`config_trace()` debugging helper**
   - Show value resolution chain
   - Indicate which file/section provided value
   - Help debug complex split-file setups

2. **Config validation**
   - Schema validation for config structure
   - Type checking for directory paths
   - Warn about deprecated options

3. **Config migration tool**
   - Automatically convert legacy to new structure
   - `config_migrate()` function
   - Preview changes before applying

4. **Environment-specific configs**
   - Already supported via `config` package
   - Document patterns for dev/prod/test
   - Examples in templates

### Not Planned

- ❌ Automatic config file generation from R objects
- ❌ GUI config editor
- ❌ Runtime config modification (configs are read-only)

## Lessons Learned

1. **Discoverability > Organization**
   - Users need to see options immediately
   - Split files are for complexity management, not default organization

2. **R Conventions Matter**
   - R users expect single primary config file
   - Laravel patterns need adaptation for R audience

3. **Backward Compatibility is Critical**
   - Legacy structure must keep working
   - Smart lookups enable gradual migration
   - Tests ensure nothing breaks

4. **Comprehensive Testing is Worth It**
   - 74 tests caught issues during development
   - Confidence in refactoring
   - Documentation through test names

## Conclusion

The config system overhaul successfully delivers:
- ✅ **Discoverability**: Paths visible in main file
- ✅ **Scalability**: Split files when needed
- ✅ **Simplicity**: Single file for most projects
- ✅ **Compatibility**: Legacy structure still works
- ✅ **Reliability**: 74 passing tests, 0 failures
- ✅ **Documentation**: Comprehensive docs in CLAUDE.md

The system is **production-ready** and follows R ecosystem conventions while providing Laravel-inspired flexibility for complex projects.
