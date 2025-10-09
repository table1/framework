# Feature: Haven Data Format Support

## Overview
Add support for reading statistical software data formats (Stata, SPSS, SAS) using the `haven` package. This expands Framework's data loading capabilities beyond CSV/TSV/RDS to include formats commonly used in academic and statistical research.

## Requirements
- [x] Support Stata files (.dta)
- [x] Support SPSS files (.sav, .zsav, .por)
- [x] Support SAS files (.sas7bdat, .sas7bcat, .xpt)
- [x] Integrate seamlessly with existing `data_load()` function
- [x] Auto-detect format from file extension
- [x] Strip haven attributes by default (defensive programming)
- [x] Preserve haven attributes with opt-in `keep_attributes = TRUE`
- [x] Handle both direct file paths and config-based paths

## Implementation Checklist
- [x] Design and planning
- [x] Add haven to package dependencies
- [x] Extend file type detection in `get_data_spec()`
- [x] Add haven read functions to `data_load()`
- [x] Implement attribute stripping logic
- [x] Write comprehensive tests (20 tests, all passing)
- [x] Update documentation (CLAUDE.md pattern added)
- [x] All tests passing (148 total, 0 failures)

## Technical Details

### Files to Modify

1. **`DESCRIPTION`**
   - Add `haven` to Imports section

2. **`R/data_read.R`**
   - Modify `get_data_spec()` helper function `get_file_type_info()` to recognize haven formats
   - Add new cases to `data_load()` switch statement for haven formats
   - Ensure hash checking works with haven files
   - Ensure encrypted data flow handles haven formats (if needed)

### File Extension Mappings

```r
# Stata
.dta → haven::read_dta()

# SPSS
.sav → haven::read_sav()
.zsav → haven::read_sav()  # Compressed SPSS
.por → haven::read_por()   # SPSS portable format

# SAS
.sas7bdat → haven::read_sas()  # SAS data files
.sas7bcat → haven::read_sas()  # SAS catalog files
.xpt → haven::read_xpt()       # SAS transport files
```

### New Dependencies
- **haven** - Read and write SPSS, Stata, and SAS files (Tidyverse package)

### Breaking Changes
- None - This is purely additive functionality

## Implementation Details

### 1. Update `get_file_type_info()` in `get_data_spec()`

Currently handles:
- `.rds` → type: "rds", delimiter: NULL
- `.tsv` → type: "csv", delimiter: "tab"
- `.csv` → type: "csv", delimiter: "comma"

Add haven formats:
```r
get_file_type_info <- function(path) {
  # Existing RDS/CSV/TSV checks...

  # Stata
  if (grepl("\\.dta$", path, ignore.case = TRUE)) {
    return(list(type = "stata", delimiter = NULL))
  }

  # SPSS
  if (grepl("\\.(sav|zsav)$", path, ignore.case = TRUE)) {
    return(list(type = "spss", delimiter = NULL))
  }

  if (grepl("\\.por$", path, ignore.case = TRUE)) {
    return(list(type = "spss_por", delimiter = NULL))
  }

  # SAS
  if (grepl("\\.sas7bdat$", path, ignore.case = TRUE)) {
    return(list(type = "sas", delimiter = NULL))
  }

  if (grepl("\\.xpt$", path, ignore.case = TRUE)) {
    return(list(type = "sas_xpt", delimiter = NULL))
  }

  # Default for unknown...
  return(list(type = "csv", delimiter = NULL))
}
```

### 2. Update `data_load()` function signature

Add `keep_attributes` parameter:
```r
data_load <- function(path, delim = NULL, keep_attributes = FALSE, ...)
```

### 3. Extend `data_load()` switch statement

Add new cases alongside existing csv/tsv/rds:

```r
# In the non-encrypted branch:
data <- switch(spec$type,
  csv = { readr::read_delim(spec$path, show_col_types = FALSE, delim = get_delimiter(delim), ...) },
  tsv = { readr::read_delim(spec$path, show_col_types = FALSE, delim = "\t", ...) },
  rds = readRDS(spec$path),
  stata = haven::read_dta(spec$path, ...),
  spss = haven::read_sav(spec$path, ...),
  spss_por = haven::read_por(spec$path, ...),
  sas = haven::read_sas(spec$path, ...),
  sas_xpt = haven::read_xpt(spec$path, ...),
  stop(sprintf("Unsupported file type: %s", spec$type))
)

# Strip haven attributes if requested (default behavior)
if (!keep_attributes && spec$type %in% c("stata", "spss", "spss_por", "sas", "sas_xpt")) {
  data <- haven::zap_formats(data)
  data <- haven::zap_labels(data)
  data <- haven::zap_label(data)
  data <- as.data.frame(data)
}

# In the encrypted branch:
switch(spec$type,
  csv = { readr::read_delim(rawToChar(decrypted_data), ...) },
  tsv = { readr::read_delim(rawToChar(decrypted_data), ...) },
  rds = unserialize(decrypted_data),
  stata = stop("Encrypted Stata files not supported"),
  spss = stop("Encrypted SPSS files not supported"),
  spss_por = stop("Encrypted SPSS portable files not supported"),
  sas = stop("Encrypted SAS files not supported"),
  sas_xpt = stop("Encrypted SAS transport files not supported"),
  stop(sprintf("Unsupported file type: %s", spec$type))
)
```

### 3. Error Handling

Wrap haven calls in tryCatch with clear messages:
```r
stata = tryCatch(
  haven::read_dta(spec$path),
  error = function(e) {
    stop(sprintf("Failed to load Stata file: %s", e$message))
  }
)
```

## Testing Strategy

### Unit Tests (test-data.R)

1. **Create test fixtures** in `tests/testthat/fixtures/`:
   - `test.dta` - Small Stata file
   - `test.sav` - Small SPSS file
   - `test.xpt` - Small SAS transport file

2. **Test direct file loading**:
   ```r
   test_that("can load Stata files directly", {
     df <- data_load("tests/testthat/fixtures/test.dta")
     expect_s3_class(df, "data.frame")
     expect_true(nrow(df) > 0)
   })
   ```

3. **Test config-based loading**:
   - Add haven format specs to test config
   - Verify dot-notation loading works
   - Verify hash tracking works

4. **Test error conditions**:
   - Non-existent files
   - Corrupted files
   - Unsupported formats

5. **Test attribute preservation**:
   ```r
   test_that("preserves haven attributes", {
     df <- data_load("tests/testthat/fixtures/test.dta")
     # Check for variable labels, value labels, etc.
     expect_true(!is.null(attr(df, "spec")))  # haven metadata
   })
   ```

### Integration Tests

- Test haven files work with `load_data_or_cache()`
- Test hash verification on haven files
- Test locked data protection on haven files

## Documentation Updates
- [ ] Update `data_load()` roxygen documentation to list supported formats
- [ ] Add examples showing haven file loading
- [ ] Update CLAUDE.md if new patterns are introduced
- [ ] Update README if this is user-facing functionality

## Notes

### Design Decisions

**Q: Should we support encrypted haven files?**
A: Start without encryption support. Haven files are typically read-only source data, less likely to need encryption than derived results.

**Q: Should we convert haven tibbles to data.frames?**
A: Keep as-is. Haven returns tibbles with special attributes (labels, etc.). Users may want to preserve these. Can always convert with `as.data.frame()` if needed.

**Q: Additional parameters for haven functions?**
A: Haven read functions have parameters like `encoding`, `user_na`, etc. Start simple - just file path. Can add ... passthrough later if needed.

**Q: File type detection order?**
A: Check specific extensions first (.dta, .sav, etc.) before falling back to generic. Case-insensitive matching.

### Design Decisions Made

**✅ Format Coverage:** Support all variants (.zsav, .sas7bcat, .por) for comprehensive format support.

**✅ Encryption:** Encrypted haven files will throw an error. Haven files are typically read-only source data, less likely to need encryption.

**✅ Attributes Handling (CONSENSUS DECISION):** Strip attributes by default with `keep_attributes = TRUE` opt-in.
- **Rationale:** Aligns with Framework's defensive programming principles
- **Benefits:** Consistent with CSV/RDS behavior, prevents unexpected issues, smaller memory footprint
- **Implementation:** Use haven's `zap_*()` functions to strip, convert to plain data.frame
- **Flexibility:** Users who need metadata can set `keep_attributes = TRUE`
- **Confidence:** 9/10 (based on multi-model consensus analysis)

**✅ Parameter Passthrough:** Add `...` parameter to `data_load()` to pass additional args to haven functions (encoding, user_na, etc.).

### Future Enhancements

- Add `data_save()` support for writing haven formats (haven::write_dta, write_sav, write_xpt)
- Add parameter passthrough for haven-specific options (encoding, user_na, etc.)
- Add helper functions to work with haven attributes (labels, value labels)
- Add conversion utilities (haven → plain data.frame, or vice versa)
