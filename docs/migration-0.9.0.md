# Migration Guide: Framework 0.9.0

## Overview

Framework 0.9.0 introduces a new inputs/outputs directory structure that provides clearer semantics for data workflow and better aligns with reproducible research principles.

## What Changed

### Directory Structure

**Old Structure (< 0.9.0):**
```
data/
├── source/private/         # Raw data
├── source/public/          # Public raw data
├── in_progress/            # Intermediate data
├── final/                  # Results
├── cached/                 # Cache
└── scratch/                # Temporary files

results/
├── private/                # Private outputs
└── public/                 # Public outputs
```

**New Structure (>= 0.9.0):**
```
inputs/
├── private/raw/            # Raw data (read-only in code)
├── private/intermediate/   # Processed data
└── public/examples/        # Public example data

outputs/
├── private/tables/         # Analysis outputs
├── private/figures/        # Visualizations
├── private/models/         # Saved models
├── private/notebooks/      # Rendered notebooks
├── private/cache/          # Computation cache
├── private/scratch/        # Temporary files
└── public/                 # Public outputs
```

### Configuration Changes

**Data catalog paths have changed:**

**Old (settings/data.yml):**
```yaml
data:
  cache_dir: data/cached
  scratch_dir: data/scratch
  source:
    private:
      survey:
        path: data/source/private/survey.csv
```

**New (settings/data.yml):**
```yaml
data:
  cache_dir: outputs/private/cache
  scratch_dir: outputs/private/scratch
  inputs:
    raw:
      survey:
        path: inputs/private/raw/survey.csv
```

**Dot notation has changed:**
```r
# Old
df <- data_load("source.private.survey")

# New
df <- data_load("inputs.raw.survey")
```

## Migration Steps

### For Existing Projects

**Option 1: No Migration Required (Recommended)**

Framework is designed to work with ANY directory structure through configuration. Your existing projects will continue to work without changes:

1. Keep your current `data/` and `results/` directories
2. Your `settings.yml` and `settings/data.yml` already point to the correct paths
3. No code changes needed

**Option 2: Adopt New Structure**

If you want to adopt the new structure:

1. **Create new directories:**
   ```bash
   mkdir -p inputs/private/{raw,intermediate}
   mkdir -p inputs/public/examples
   mkdir -p outputs/private/{tables,figures,models,notebooks,cache,scratch}
   mkdir -p outputs/public
   ```

2. **Move your data (optional):**
   ```bash
   # Example: Move raw data
   mv data/source/private/* inputs/private/raw/

   # Example: Move results
   mv results/private/* outputs/private/tables/
   ```

3. **Update settings/directories.yml:**
   ```yaml
   directories:
     # Update these paths
     inputs_raw: inputs/private/raw
     outputs_tables: outputs/private/tables
     outputs_figures: outputs/private/figures
     # ... etc
   ```

4. **Update settings/data.yml:**
   - Change `source:` → `inputs:` and `raw:` nesting
   - Update file paths
   - Update dot notation in your code

5. **Update _quarto.yml (if using Quarto):**
   ```yaml
   project:
     output-dir: outputs/private/notebooks  # Was: _rendered
   ```

### For New Projects

New projects created with Framework >= 0.9.0 automatically use the new structure. No action needed.

## Breaking Changes

**None for existing projects!**

The changes are:
- **Template defaults** - New projects get the new structure
- **Documentation examples** - Updated to show new structure
- **Bug fix** - `data_spec_update()` now correctly handles external data files

Your existing projects will continue to work because Framework respects your configuration files.

## Benefits of New Structure

1. **Clear semantics**: `inputs/` vs `outputs/` makes data workflow explicit
2. **Read-only inputs**: Encourages treating source data as immutable
3. **Organized outputs**: Separate directories for different artifact types
4. **Better .gitignore**: All `outputs/` gitignored by default
5. **Industry standard**: Aligns with common data science project structures

## Questions?

- Check the updated [README](../README.md) for examples
- View the [cheatsheet](../inst/templates/framework-cheatsheet.fr.md) for directory reference
- File an issue at https://github.com/erikwestlund/framework/issues
