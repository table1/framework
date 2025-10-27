# Directory Structure Dependency Analysis

**Date:** 2025-10-09
**Purpose:** Determine if Framework package has hard dependencies on specific directory structures

## Executive Summary

**Finding: Framework is MOSTLY directory-agnostic with 3 specific dependencies**

The package can work with any directory structure as long as users configure paths correctly in settings.yml. However, there are **3 hardcoded paths** that should be made configurable:

1. ✅ **Configurable (already):** `scratch_dir`, `cache_dir`
2. ❌ **Hardcoded:** `functions/` directory (scaffold.R:154)
3. ❌ **Hardcoded:** `results/public` and `results/private` (results.R:22)

## Detailed Analysis

### 1. Functions Directory (`functions/`)

**Location:** R/scaffold.R:154-162

```r
.load_functions <- function() {
  func_dir <- "functions"  # HARDCODED
  if (dir.exists(func_dir)) {
    func_files <- list.files(func_dir, pattern = "\\.R$", full.names = TRUE)
    for (file in func_files) {
      source(file, local = FALSE)
    }
  } else {
    warning(sprintf("Functions directory '%s' not found", func_dir))
  }
}
```

**Impact:**
- scaffold() always looks for `functions/` directory
- If renamed or moved, custom functions won't auto-load
- Warning issued if missing (graceful degradation)

**Recommendation:** Make configurable
```yaml
options:
  functions_dir: "functions"  # Allow customization
```

---

### 2. Results Directories (`results/public`, `results/private`)

**Location:** R/results.R:22, 125

```r
result_save <- function(..., public = FALSE) {
  results_dir <- if (public) "results/public" else "results/private"  # HARDCODED
  dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
  # ...
}

result_get <- function(name) {
  # ...
  results_dir <- if (result$public) "results/public" else "results/private"  # HARDCODED
  result_file <- file.path(results_dir, paste0(name, ".rds"))
  # ...
}
```

**Impact:**
- result_save() and result_get() always use `results/public` or `results/private`
- Cannot customize results location
- Auto-creates directories if missing (graceful)

**Recommendation:** Make configurable
```yaml
options:
  results:
    public_dir: "results/public"
    private_dir: "results/private"
```

---

### 3. Scratch & Cache Directories (ALREADY CONFIGURABLE ✅)

**Location:** inst/config_skeleton.yml:6-9

```yaml
options:
  data:
    cache_dir: data/cached
    scratch_dir: data/scratch
```

**Used by:**
- R/scratch.R:40 - `config$options$data$scratch_dir`
- R/scratch.R:186 - `config$options$data$scratch_dir`

**Status:** ✅ Already configurable, no changes needed

---

### 4. Data Directories (NO DEPENDENCIES)

**Analysis:** Searched for hardcoded references to:
- `data/source/private/`
- `data/source/public/`
- `data/output/`
- `data/cached/`

**Finding:** No hardcoded paths found in R/ code

**Why it works:**
- data_load() and data_save() use paths from settings.yml data catalog
- Users specify full paths in config: `path: data/source/private/survey.csv`
- Or use direct file paths: `data_load("any/path/file.csv")`

**Conclusion:** Data directory structure is pure convention - no dependencies

---

### 5. Other Directories (NO DEPENDENCIES)

Checked for hardcoded paths to:
- `notebooks/`, `scripts/`, `work/`, `documentation/`, `docs/`
- `presentations/`, `assets/`

**Finding:** No references found in R/ code

**Conclusion:** These directories are scaffolding convention only - Framework never references them

---

## Recommendations for Multi-Type Support

### High Priority (breaks alternative structures)

**1. Make functions/ configurable**

Add to config_skeleton.yml:
```yaml
options:
  functions_dir: "functions"
```

Update R/scaffold.R:
```r
.load_functions <- function() {
  config <- read_config()
  func_dir <- config$options$functions_dir %||% "functions"
  # ... rest unchanged
}
```

**2. Make results/ configurable**

Add to config_skeleton.yml:
```yaml
options:
  results:
    public_dir: "results/public"
    private_dir: "results/private"
```

Update R/results.R:
```r
result_save <- function(..., public = FALSE) {
  config <- read_config()
  results_dir <- if (public) {
    config$options$results$public_dir %||% "results/public"
  } else {
    config$options$results$private_dir %||% "results/private"
  }
  # ... rest unchanged
}
```

### Low Priority (nice to have)

**3. Type-specific config defaults**

Each project type can ship different config defaults:
```yaml
# config.analysis.fr.yml
options:
  functions_dir: "functions"
  results:
    public_dir: "results/public"
    private_dir: "results/private"
  data:
    cache_dir: "data/cached"
    scratch_dir: "data/scratch"

# config.course.fr.yml
options:
  functions_dir: "functions"
  data:
    cache_dir: "assets/cache"
    scratch_dir: "assets/scratch"
  # No results dirs - courses don't use result_save()

# config.presentation.fr.yml
options:
  data:
    cache_dir: "assets/cache"
    scratch_dir: "assets/scratch"
  # No functions_dir - presentations don't use functions/
  # No results dirs - presentations don't use result_save()
```

---

## Testing Plan

### Test 1: Completely custom directory structure

Create project with:
```
project/
├── my-functions/       # Not "functions/"
├── my-results/         # Not "results/"
│   ├── pub/           # Not "public"
│   └── priv/          # Not "private"
├── my-data/
│   └── temp/          # Not "scratch"
└── settings.yml
```

settings.yml:
```yaml
options:
  functions_dir: "my-functions"
  results:
    public_dir: "my-results/pub"
    private_dir: "my-results/priv"
  data:
    scratch_dir: "my-data/temp"
```

**Expected:** scaffold() loads from my-functions/, result_save() uses my-results/

### Test 2: Minimal structure (no functions/, no results/)

Create project with:
```
project/
├── notebooks/
└── settings.yml
```

**Expected:**
- scaffold() warns "Functions directory not found" but continues
- result_save() auto-creates results/private/ when needed

### Test 3: Course structure with flat directories

Create project with:
```
project/
├── presentations/
├── helpers/           # Instead of "functions/"
└── settings.yml
```

settings.yml:
```yaml
options:
  functions_dir: "helpers"
```

**Expected:** scaffold() loads .R files from helpers/

---

## Conclusion

**Framework's directory structure is 90% convention, 10% dependency**

**Hard dependencies (must fix for flexibility):**
1. `functions/` directory - fixable via config
2. `results/public` and `results/private` - fixable via config

**Soft dependencies (already configurable):**
1. `scratch_dir` - ✅ already in config
2. `cache_dir` - ✅ already in config

**Pure convention (no code dependencies):**
1. `data/` structure - users specify paths in config
2. `notebooks/`, `scripts/`, `docs/` - never referenced by code
3. `presentations/`, `assets/` - never referenced by code

**Action:** Implement recommendations #1 and #2 before multi-type rollout to ensure true flexibility.
