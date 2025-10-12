# scaffold() Guard Improvement

**Date**: 2025-10-12
**Issue**: scaffold() displayed confusing cascading errors when called outside a Framework project

## Problem

When `scaffold()` was called from a directory without a Framework project (no `config.yml`), users saw:

```
Warning message:
In standardize_wd() :
  Could not determine project root directory. Current directory: /Users/erikwestlund/code
Consider specifying project_root explicitly.

Error in read_config() : Config file not found: config.yml
```

This was confusing because:
1. Warning + error = unclear failure mode
2. Didn't explain what scaffold() actually looks for
3. Misleading about where scaffold() can be called from

## Solution

Added **fail-fast guard** at the start of `scaffold()` after `standardize_wd()`:

```r
scaffold <- function(config_file = "config.yml") {
  # Standardize working directory first (for notebooks in subdirectories)
  project_root <- standardize_wd()

  # Fail fast if not in a Framework project
  if (is.null(project_root) || !file.exists("config.yml")) {
    stop(
      "Could not locate a Framework project.\n",
      "scaffold() searches for a project by looking for:\n",
      "  - config.yml in current or parent directories\n",
      "  - .Rproj file with config.yml nearby\n",
      "  - Common subdirectories (notebooks/, scripts/, etc.)\n",
      "Current directory: ", getwd(), "\n",
      "To create a new project, use: init()"
    )
  }

  # ... rest of scaffold logic
}
```

Also updated `standardize_wd()` to return `NULL` silently instead of warning, since the calling function now handles the error.

## Benefits

1. **Clear, immediate error** - no confusing cascade
2. **Educational message** - explains what scaffold() looks for
3. **Actionable guidance** - tells user how to fix (use `init()`)
4. **Accurate description** - clarifies that scaffold() works from subdirectories and parent dirs

## Testing

Added comprehensive tests in `tests/testthat/test-scaffold.R`:

- ✅ scaffold() fails fast with clear error outside project
- ✅ scaffold() works when config.yml exists
- ✅ scaffold() works from subdirectories (notebooks/, scripts/)
- ✅ standardize_wd() returns NULL when project not found
- ✅ standardize_wd() finds and returns project root

**Test Status**: 7 passing tests

## Files Changed

- `R/scaffold.R` - Added fail-fast guard
- `R/framework_util.R` - Made standardize_wd() silent on failure
- `tests/testthat/test-scaffold.R` - New test suite

## Example Output

**Before:**
```
Warning message:
In standardize_wd() :
  Could not determine project root directory. Current directory: /Users/erikwestlund/code
Consider specifying project_root explicitly.
Error in read_config() : Config file not found: config.yml
```

**After:**
```
Error in scaffold() : Could not locate a Framework project.
scaffold() searches for a project by looking for:
  - config.yml in current or parent directories
  - .Rproj file with config.yml nearby
  - Common subdirectories (notebooks/, scripts/, etc.)
Current directory: /Users/erikwestlund/code
To create a new project, use: init()
```
