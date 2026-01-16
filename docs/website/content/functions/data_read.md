---
title: Read Data from Catalog or File
category: Data Management
tags: data, loading, catalog, csv, rds, excel, stata, spss
---

# Read Data from Catalog or File

Read datasets defined in your data catalog (settings.yml) or directly from file paths.
Supports CSV, TSV, RDS, Excel, Stata, SPSS, SAS, and Parquet formats.


## Usage

```r
data_read(path, delim = NULL, keep_attributes = FALSE, ...)
```

## Parameters

- **`path`** (character) *(required)*: Dot notation path to data catalog entry (e.g., "inputs.raw.sales") OR direct file path (e.g., "data/myfile.csv")
- **`delim`** (character) (default: `NULL`): Optional delimiter for CSV files ("comma", "tab", "semicolon", "space")
- **`keep_attributes`** (logical) (default: `FALSE`): Preserve special attributes from statistical software (e.g., haven labels). Set to TRUE to keep Stata/SPSS/SAS metadata.
- **`...`**: Additional arguments passed to underlying read functions (readr, readxl, haven, etc.)

## Returns

The loaded dataset as a data.frame or tibble.

## Details

data_read() provides two modes of operation:

**Catalog-based loading (dot notation):**
- Define datasets once in settings.yml under the `data:` section
- Access using dot notation: `data_read("inputs.raw.sales")`
- Supports encryption, integrity verification, and locking

**Direct file path loading:**
- Bypass the catalog by providing a file path directly
- Format detected automatically from file extension
- Example: `data_read("path/to/file.csv")`

**Supported formats:**
- CSV, TSV, TXT, DAT (delimited text)
- RDS (R data files)
- Excel (.xlsx, .xls)
- Stata (.dta)
- SPSS (.sav, .zsav, .por)
- SAS (.sas7bdat, .xpt)
- Parquet

## Examples

```r
# Load from data catalog using dot notation
df <- data_read("inputs.raw.sales")
```

Load dataset named "sales" from inputs/raw section of catalog

```r
# Load with nested catalog path
private_data <- data_read("source.private.patient_data")
```

Load from nested catalog path

```r
# Load directly from file path (bypass catalog)
df <- data_read("inputs/raw/mydata.csv")
df <- data_read("outputs/results.rds")
df <- data_read("data/survey.dta")  # Stata file
```

Load directly from file path - format detected from extension

```r
# Keep haven attributes from Stata/SPSS/SAS files
df <- data_read("data/survey.dta", keep_attributes = TRUE)
```

Preserve value labels and other metadata from statistical software

## See Also

- [`data_save()`](data_save) - Save data to catalog with integrity tracking
- [`data_list()`](data_list) - List all datasets in catalog
- [`data_add()`](data_add) - Add a new dataset to the catalog
- [`data_info()`](data_info) - Get data specification from catalog

## Notes

- When loading from catalog, encrypted files are automatically decrypted (requires sodium package)
- Statistical software formats (Stata, SPSS, SAS) strip metadata by default for consistency; use `keep_attributes = TRUE` to preserve
- Direct file paths take precedence over catalog lookups if the file exists
