---
title: Load Data from Catalog
category: Data Management
tags: data, loading, catalog, encryption, integrity
---

# Load Data from Catalog

Load datasets defined in your data catalog (settings/data.yml). Supports
CSV and RDS formats with automatic integrity verification, encryption,
and caching.


## Usage

```r
data_load(name, verify_hash = TRUE, cache = TRUE)
```
## Parameters

- **`name`** (character) *(required)*: Name of the dataset as defined in settings/data.yml (supports dot-notation like "source.private.my_data")
- **`verify_hash`** (logical) (default: `TRUE`): Verify file integrity against stored hash from framework.db
- **`cache`** (logical) (default: `TRUE`): Cache the loaded data in memory for faster subsequent access

## Returns

The loaded dataset as a data.frame or tibble. Encrypted files are automatically
decrypted if sodium package is available.

## Details

data_load() uses your data catalog to load datasets with the following features:

**Catalog-based loading:**
- Define datasets once in settings/data.yml
- Specify path, type (csv/rds), encryption status
- Use dot-notation for nested organization

**Integrity verification:**
- Computes file hash and compares to stored value
- Warns if file has changed since last registration
- Updates hash in framework.db on load

**Encryption support:**
- Automatically decrypts .enc files using sodium
- Requires encryption key in .env file
- Transparent to user (just works)

**Performance:**
- In-memory caching for repeated access
- Smart cache invalidation on file changes
## Examples

```r
# Load a simple dataset
df <- data_load("example")

```

Load dataset named "example" from catalog

```r
# Load with dot-notation (nested in catalog)
private_data <- data_load("source.private.patient_data")

```

Load from nested catalog path

```r
# Skip hash verification (faster, less safe)
df <- data_load("example", verify_hash = FALSE)

```

Skip integrity check for performance

```r
# Force fresh load (bypass cache)
df <- data_load("example", cache = FALSE)

```

Disable caching to force reload from disk## See Also

- [`data_save()`](data_save) - Save data to catalog with integrity tracking
- [`data_list()`](data_list) - List all datasets in catalog
- [`configure_data()`](configure_data) - Configure data catalog interactively## Notes

- Encrypted files require sodium package and KEY in .env
- Hash verification uses digest package (MD5 by default)
- Catalog location defaults to settings/data.yml
- Use data_list() to see all available datasets
