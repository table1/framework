#' Load data using dot notation path or direct file path
#'
#' Supports CSV, TSV, RDS, Excel (.xlsx, .xls), Stata (.dta), SPSS (.sav, .zsav, .por),
#' and SAS (.sas7bdat, .xpt) file formats.
#'
#' @param path Dot notation path (e.g. "source.private.example") or direct file path
#' @param delim Optional delimiter for CSV files ("comma", "tab", "semicolon", "space")
#' @param keep_attributes Logical flag to preserve special attributes (e.g., haven labels). Default: FALSE (strips attributes)
#' @param ... Additional arguments passed to read functions (readr::read_delim, readxl::read_excel, haven::read_*, etc.)
#' @export
data_load <- function(path, delim = NULL, keep_attributes = FALSE, ...) {
  # Validate arguments
  checkmate::assert_string(path, min.chars = 1)
  checkmate::assert_choice(delim, c("comma", "tab", "semicolon", "space", ",", "\t", ";", " "), null.ok = TRUE)
  checkmate::assert_flag(keep_attributes)

  # Check if path is a direct file path
  if (file.exists(path)) {
    # Direct file path - create a minimal spec
    file_ext <- tolower(sub(".*\\.", "", path))
    spec <- list(
      path = path,
      type = switch(file_ext,
        csv = "csv",
        tsv = "tsv",
        txt = "tsv",  # Assume .txt files are tab-delimited
        dat = "tsv",  # Assume .dat files are tab-delimited
        rds = "rds",
        xlsx = "excel",
        xls = "excel",
        dta = "stata",
        sav = "spss",
        zsav = "spss",
        por = "spss_por",
        sas7bdat = "sas",
        sas7bcat = "sas",
        xpt = "sas_xpt",
        stop(sprintf("Unsupported file extension: %s", file_ext))
      ),
      encrypted = FALSE,
      locked = FALSE,
      delimiter = NULL
    )
  } else {
    # Try to get data specification from config
    spec <- tryCatch(
      data_spec_get(path),
      error = function(e) {
        stop(sprintf("Path '%s' is not a valid file and failed to get data specification: %s", path, e$message))
      }
    )

    if (is.null(spec)) {
      stop(sprintf("No data specification found for path: %s", path))
    }
  }

  # Check if file exists
  if (!file.exists(spec$path)) {
    stop(sprintf("File not found: %s", spec$path))
  }

  # Only do hash checking for config-based paths (not direct file paths)
  if (!file.exists(path)) {
    # Calculate current file hash
    current_hash <- tryCatch(
      .calculate_file_hash(spec$path),
      error = function(e) {
        stop(sprintf("Failed to calculate file hash: %s", e$message))
      }
    )

    # Get existing data record
    data_record <- tryCatch(
      .get_data_record(path),
      error = function(e) {
        warning(sprintf("Failed to get data record: %s", e$message))
        NULL
      }
    )

    # Handle hash checking
    if (is.null(data_record)) {
      # No record exists, create one with current hash
      tryCatch(
        .set_data(
          name = path,
          path = spec$path,
          type = spec$type,
          delimiter = if (!is.null(spec$delimiter)) spec$delimiter else NA,
          locked = if (!is.null(spec$locked)) spec$locked else FALSE,
          encrypted = spec$encrypted,
          hash = current_hash
        ),
        error = function(e) {
          warning(sprintf("Failed to set data record: %s", e$message))
        }
      )
    } else {
      # Check if file has changed
      if (data_record$hash != current_hash) {
        if (spec$locked) {
          stop(sprintf("Hash mismatch for locked data: %s", path))
        } else {
          warning(sprintf("File has changed since last read: %s", path))
        }
      }
      # Update hash and metadata
      tryCatch(
        .set_data(
          name = path,
          path = spec$path,
          type = spec$type,
          delimiter = if (!is.null(spec$delimiter)) spec$delimiter else NA,
          locked = if (!is.null(spec$locked)) spec$locked else FALSE,
          encrypted = as.logical(data_record$encrypted),
          hash = current_hash
        ),
        error = function(e) {
          warning(sprintf("Failed to update data record: %s", e$message))
        }
      )
    }
  }

  # Helper function to get delimiter character
  get_delimiter <- function(delimiter_name) {
    switch(delimiter_name,
      comma = ",",
      "," = ",",
      tab = "\t",
      "\t" = "\t",
      semicolon = ";",
      ";" = ";",
      space = " ",
      " " = " ",
      stop(sprintf("Unknown delimiter: %s. Must be one of: comma, tab, semicolon, space", delimiter_name))
    )
  }

  # Helper function to guess delimiter from extension
  guess_delimiter_from_ext <- function(path) {
    ext <- tolower(sub(".*\\.", "", path))
    switch(ext,
      csv = "comma",
      tsv = "tab",
      txt = "tab", # Common for tab-delimited
      dat = "tab", # Common for tab-delimited
      xlsx = NA,   # Excel files don't use delimiters
      xls = NA,    # Excel files don't use delimiters
      NULL
    )
  }

  # Determine delimiter (only for delimited file types)
  if (is.null(delim) && spec$type %in% c("csv", "tsv")) {
    # Use delimiter from spec if available, otherwise guess from extension
    if (is.null(spec$delimiter) || is.na(spec$delimiter)) {
      delim <- guess_delimiter_from_ext(spec$path)
    } else {
      delim <- spec$delimiter
    }

    if (is.null(delim)) {
      warning(sprintf("Could not determine delimiter from extension for %s, defaulting to comma", spec$path))
      delim <- "comma"
    }
  }

  # Load data based on encryption
  if (spec$encrypted) {
    config <- tryCatch(
      read_config(),
      error = function(e) {
        stop(sprintf("Failed to read config: %s", e$message))
      }
    )

    if (is.null(config$security$data_key)) {
      stop("Data encryption key not found in config")
    }

    # Read and decrypt the file
    encrypted_data <- tryCatch(
      readBin(spec$path, "raw", n = file.size(spec$path)),
      error = function(e) {
        stop(sprintf("Failed to read encrypted file: %s", e$message))
      }
    )

    decrypted_data <- tryCatch(
      .decrypt_data(encrypted_data, config$security$data_key),
      error = function(e) {
        stop(sprintf("Failed to decrypt data: %s", e$message))
      }
    )

    # Parse decrypted data based on type
    data <- tryCatch(
      switch(spec$type,
        csv = {
          # Convert raw bytes to string and parse as CSV
          readr::read_delim(rawToChar(decrypted_data), show_col_types = FALSE, delim = get_delimiter(delim), ...)
        },
        tsv = {
          # Convert raw bytes to string and parse as TSV
          readr::read_delim(rawToChar(decrypted_data), show_col_types = FALSE, delim = "\t", ...)
        },
        rds = unserialize(decrypted_data),
        stata = stop("Encrypted Stata files not supported"),
        spss = stop("Encrypted SPSS files not supported"),
        spss_por = stop("Encrypted SPSS portable files not supported"),
        sas = stop("Encrypted SAS files not supported"),
        sas_xpt = stop("Encrypted SAS transport files not supported"),
        stop(sprintf("Unsupported file type: %s", spec$type))
      ),
      error = function(e) {
        stop(sprintf("Failed to parse decrypted data: %s", e$message))
      }
    )

    # Output description if available
    if (!is.null(spec$description) && nzchar(spec$description)) {
      message(sprintf("ℹ %s", spec$description))
    }

    data
  } else {
    # Helper to check for haven package
    require_haven <- function(file_type) {
      if (!requireNamespace("haven", quietly = TRUE)) {
        stop(
          sprintf("%s files require the haven package.\n", file_type),
          "Install with: install.packages('haven')"
        )
      }
    }

    # Helper to check for readxl package
    require_readxl <- function() {
      if (!requireNamespace("readxl", quietly = TRUE)) {
        stop(
          "Excel files require the readxl package.\n",
          "Install with: install.packages('readxl')"
        )
      }
    }

    # Load data normally
    data <- tryCatch(
      switch(spec$type,
        csv = {
          readr::read_delim(spec$path, show_col_types = FALSE, delim = get_delimiter(delim), ...)
        },
        tsv = {
          readr::read_delim(spec$path, show_col_types = FALSE, delim = "\t", ...)
        },
        rds = readRDS(spec$path),
        excel = {
          require_readxl()
          readxl::read_excel(spec$path, ...)
        },
        stata = {
          require_haven("Stata")
          haven::read_dta(spec$path, ...)
        },
        spss = {
          require_haven("SPSS")
          haven::read_sav(spec$path, ...)
        },
        spss_por = {
          require_haven("SPSS portable")
          haven::read_por(spec$path, ...)
        },
        sas = {
          require_haven("SAS")
          haven::read_sas(spec$path, ...)
        },
        sas_xpt = {
          require_haven("SAS transport")
          haven::read_xpt(spec$path, ...)
        },
        stop(sprintf("Unsupported file type: %s", spec$type))
      ),
      error = function(e) {
        stop(sprintf("Failed to load data: %s", e$message))
      }
    )

    # Strip haven attributes if requested (default behavior)
    if (!keep_attributes && spec$type %in% c("stata", "spss", "spss_por", "sas", "sas_xpt")) {
      data <- haven::zap_formats(data)
      data <- haven::zap_labels(data)
      data <- haven::zap_label(data)
      data <- as.data.frame(data)
    }

    # Output description if available
    if (!is.null(spec$description) && nzchar(spec$description)) {
      message(sprintf("ℹ %s", spec$description))
    }

    data
  }
}

#' Alias for backward compatibility
#' @param path Dot notation path (e.g. "source.private.example") or direct file path
#' @param delim Optional delimiter for CSV files ("comma", "tab", "semicolon", "space")
#' @param keep_attributes Logical flag to preserve special attributes (e.g., haven labels). Default: FALSE (strips attributes)
#' @param ... Additional arguments passed to read functions
#' @export
load_data <- function(path, delim = NULL, keep_attributes = FALSE, ...) {
  data_load(path, delim, keep_attributes, ...)
}

#' List all data entries from config
#'
#' Lists all data specifications defined in the configuration, showing the
#' data key, path, type, and description (if available).
#'
#' @return A data frame with columns: name, path, type, locked, encrypted, description
#' @export
#'
#' @examples
#' \dontrun{
#' # List all data entries
#' data_list()
#'
#' # Use the alias
#' list_data()
#' }
data_list <- function() {
  config <- read_config()

  if (is.null(config$data) || length(config$data) == 0) {
    message("No data entries found in configuration")
    return(invisible(data.frame(
      name = character(),
      path = character(),
      type = character(),
      locked = logical(),
      encrypted = logical(),
      description = character(),
      stringsAsFactors = FALSE
    )))
  }

  # Recursively extract all data entries
  extract_entries <- function(obj, prefix = "") {
    entries <- list()

    for (name in names(obj)) {
      item <- obj[[name]]
      full_name <- if (nzchar(prefix)) paste(prefix, name, sep = ".") else name

      if (is.list(item) && !is.null(item$path)) {
        # This is a data entry
        entries[[full_name]] <- list(
          name = full_name,
          path = item$path,
          type = if (!is.null(item$type)) item$type else NA_character_,
          locked = if (!is.null(item$locked)) item$locked else FALSE,
          encrypted = if (!is.null(item$encrypted)) item$encrypted else FALSE,
          description = if (!is.null(item$description)) item$description else NA_character_
        )
      } else if (is.list(item) && is.null(item$path)) {
        # This is a nested structure, recurse
        nested <- extract_entries(item, full_name)
        entries <- c(entries, nested)
      }
    }

    entries
  }

  entries_list <- extract_entries(config$data)

  if (length(entries_list) == 0) {
    message("No data entries found in configuration")
    return(invisible(NULL))
  }

  # Print formatted output
  message(sprintf("\n%d data %s found:\n", length(entries_list), if (length(entries_list) == 1) "entry" else "entries"))

  for (entry in entries_list) {
    # Name with type badge
    type_badge <- sprintf("[%s]", toupper(entry$type))
    message(sprintf("• %s %s", entry$name, type_badge))

    # Path
    message(sprintf("  Path: %s", entry$path))

    # Flags (locked, encrypted)
    flags <- c()
    if (entry$locked) flags <- c(flags, "🔒 locked")
    if (entry$encrypted) flags <- c(flags, "🔐 encrypted")
    if (length(flags) > 0) {
      message(sprintf("  %s", paste(flags, collapse = ", ")))
    }

    # Description (if available)
    if (!is.na(entry$description) && nzchar(entry$description)) {
      message(sprintf("  ℹ %s", entry$description))
    }

    message("")  # Blank line between entries
  }

  invisible(NULL)
}

#' Alias for backward compatibility
#' @export
list_data <- function() {
  data_list()
}

#' Load data with caching
#' @param path Dot notation path to load data (e.g. "source.private.example")
#' @param expire_after Optional expiration time in hours (default: from config$options$data$cache_default_expire)
#' @param refresh Optional boolean or function that returns boolean to force refresh
#' @return The loaded data, either from cache or file
#' @export
load_data_or_cache <- function(path, expire_after = NULL, refresh = FALSE) {
  # Validate arguments
  checkmate::assert_string(path)
  checkmate::assert_number(expire_after, lower = 0, null.ok = TRUE)
  checkmate::assert(
    checkmate::check_flag(refresh),
    checkmate::check_function(refresh)
  )

  cache_key <- sprintf("data.%s", path)
  cache_fetch(cache_key,
    {
      message(sprintf("Loading data from file: %s (cached as %s)", path, cache_key))
      load_data(path)
    },
    expire_after = expire_after,
    refresh = refresh
  )
}

#' Get a data value
#' @param name The data name
#' @return The data metadata (encrypted flag and hash), or NULL if not found
#' @keywords internal
.get_data_record <- function(name) {
  con <- .get_db_connection()
  result <- DBI::dbGetQuery(
    con,
    "SELECT encrypted, hash FROM data WHERE name = ?",
    list(name)
  )
  DBI::dbDisconnect(con)

  if (nrow(result) == 0) {
    return(NULL)
  }

  result
}

#' Calculate hash of a file
#' @param file_path Path to the file
#' @return The hash of the file as a character string
#' @keywords internal
.calculate_file_hash <- function(file_path) {
  # Read file content
  content <- readBin(file_path, "raw", n = file.size(file_path))
  # Calculate hash and convert to character
  as.character(openssl::sha256(content))
}

#' Get data specification from config
#'
#' Gets the data specification for a given dot notation path from config.yml.
#' Supports dot notation (e.g., "source.private.example"), relative paths, and
#' absolute paths. Auto-detects file type from extension and applies intelligent
#' defaults for common formats.
#'
#' @param path Dot notation path (e.g. "source.private.example"), relative path,
#'   or absolute path to a data file
#'
#' @return A list with data specification including:
#'   \itemize{
#'     \item \code{path} - Full file path
#'     \item \code{type} - File type (csv, rds, stata, spss, sas, etc.)
#'     \item \code{delimiter} - Delimiter for CSV files (comma, tab, etc.)
#'     \item \code{locked} - Whether file is locked for integrity checking
#'     \item \code{private} - Whether file is in private data directory
#'     \item \code{encrypted} - Whether file is encrypted
#'     \item \code{description} - Optional description of the dataset (displayed when loading)
#'   }
#'
#' @examples
#' \dontrun{
#' # Get spec from dot notation
#' spec <- data_spec_get("source.private.my_data")
#'
#' # Get spec from file path
#' spec <- data_spec_get("data/public/example.csv")
#' }
#'
#' @export
data_spec_get <- function(path) {
  # Validate arguments
  checkmate::assert_string(path, min.chars = 1)

  config <- read_config()

  # Get file type info
  get_file_type_info <- function(path) {
    # For RDS files, we can be explicit
    if (grepl("\\.rds$", path, ignore.case = TRUE)) {
      return(list(type = "rds", delimiter = NULL))
    }

    # For TSV files
    if (grepl("\\.tsv$", path, ignore.case = TRUE)) {
      return(list(type = "csv", delimiter = "tab"))
    }

    # For CSV files
    if (grepl("\\.csv$", path, ignore.case = TRUE)) {
      return(list(type = "csv", delimiter = "comma"))
    }

    # Excel files
    if (grepl("\\.(xlsx|xls)$", path, ignore.case = TRUE)) {
      return(list(type = "excel", delimiter = NULL))
    }

    # Stata files
    if (grepl("\\.dta$", path, ignore.case = TRUE)) {
      return(list(type = "stata", delimiter = NULL))
    }

    # SPSS files
    if (grepl("\\.(sav|zsav)$", path, ignore.case = TRUE)) {
      return(list(type = "spss", delimiter = NULL))
    }

    if (grepl("\\.por$", path, ignore.case = TRUE)) {
      return(list(type = "spss_por", delimiter = NULL))
    }

    # SAS files
    if (grepl("\\.(sas7bdat|sas7bcat)$", path, ignore.case = TRUE)) {
      return(list(type = "sas", delimiter = NULL))
    }

    if (grepl("\\.xpt$", path, ignore.case = TRUE)) {
      return(list(type = "sas_xpt", delimiter = NULL))
    }

    # For everything else, let readr figure it out
    return(list(type = "csv", delimiter = NULL))
  }

  # Create base spec with defaults
  create_base_spec <- function(path) {
    type_info <- get_file_type_info(path)
    list(
      path = path,
      type = type_info$type,
      delimiter = type_info$delimiter,
      locked = FALSE,
      private = basename(dirname(path)) == "private",
      encrypted = FALSE
    )
  }

  # Create spec with optional existing spec
  create_spec <- function(path, existing_spec = NULL) {
    spec <- create_base_spec(path)
    if (!is.null(existing_spec)) {
      for (key in names(existing_spec)) {
        if (!is.null(existing_spec[[key]])) {
          spec[[key]] <- existing_spec[[key]]
        }
      }
    }
    spec
  }

  # Handle dot notation lookup
  get_dot_notation_spec <- function(parts, config) {
    current <- config$data
    config_spec <- current
    for (part in parts) {
      if (is.null(config_spec[[part]])) {
        return(NULL)
      }
      config_spec <- config_spec[[part]]
    }

    if (is.character(config_spec) && length(config_spec) == 1) {
      create_spec(config_spec)
    } else {
      create_spec(config_spec$path, config_spec)
    }
  }

  # Get spec based on path type
  get_spec_by_path_type <- function(path, config) {
    if (grepl("^/", path)) {
      # Handle absolute paths directly
      create_spec(path)
    } else if (grepl("[/\\\\]", path)) {
      # Handle relative paths by normalizing them against the working directory
      full_path <- normalizePath(file.path(getwd(), path), mustWork = FALSE)
      create_spec(full_path)
    } else {
      get_dot_notation_spec(strsplit(path, "\\.")[[1]], config)
    }
  }

  get_spec_by_path_type(path, config)
}

#' Update data with hash in the data table
#' @param name The data name
#' @param hash The hash to store
#' @keywords internal
.update_data_with_hash <- function(name, hash) {
  con <- .get_db_connection()
  now <- lubridate::now()

  # Check if entry exists
  entry_exists <- DBI::dbGetQuery(
    con,
    "SELECT 1 FROM data WHERE name = ?",
    list(name)
  )

  if (nrow(entry_exists) > 0) {
    # Update existing entry
    DBI::dbExecute(
      con,
      "UPDATE data SET hash = ?, last_read_at = ?, updated_at = ? WHERE name = ?",
      list(hash, now, now, name)
    )
  } else {
    # Insert new entry
    DBI::dbExecute(
      con,
      "INSERT INTO data (name, hash, last_read_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
      list(name, hash, now, now, now)
    )
  }

  DBI::dbDisconnect(con)
}
