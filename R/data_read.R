#' Load data using dot notation path
#'
#' @param path Dot notation path to load data (e.g. "source.private.example")
#' @export
load_data <- function(path) {
  # Get data specification from config
  spec <- get_data_spec(path)
  if (is.null(spec)) {
    stop(sprintf("No data specification found for path: %s", path))
  }

  # Check if file exists
  if (!file.exists(spec$path)) {
    stop(sprintf("File not found: %s", spec$path))
  }

  # Calculate current file hash
  current_hash <- .calculate_file_hash(spec$path)

  # Get existing data record
  data_record <- .get_data_record(path)

  # Handle hash checking
  if (is.null(data_record)) {
    # No record exists, create one with current hash
    .set_data(path, encrypted = spec$encrypted, hash = current_hash)
  } else {
    # Check if file has changed
    if (data_record$hash != current_hash) {
      if (spec$locked) {
        stop(sprintf("Hash mismatch for locked data: %s", path))
      } else {
        warning(sprintf("File has changed since last read: %s", path))
      }
    }
    # Update hash
    .set_data(path, encrypted = data_record$encrypted, hash = current_hash)
  }

  # Load data based on encryption
  if (spec$encrypted) {
    config <- read_config()
    if (is.null(config$security$data_key)) {
      stop("Data encryption key not found in config")
    }
    # Read and decrypt the file
    encrypted_data <- readBin(spec$path, "raw", n = file.size(spec$path))
    data <- .decrypt_data(encrypted_data, config$security$data_key)
  } else {
    data <- readBin(spec$path, "raw", n = file.size(spec$path))
  }

  # Parse data based on type
  switch(spec$type,
    csv = {
      # Convert delimiter name to actual character
      delim <- switch(spec$delimiter,
        comma = ",",
        "," = ",",
        tab = "\t",
        "\t" = "\t",
        semicolon = ";",
        ";" = ";",
        space = " ",
        " " = " "
      )
      readr::read_csv(rawToChar(data), show_col_types = FALSE)
    },
    rds = unserialize(data),
    stop(sprintf("Unsupported file type: %s", spec$type))
  )
}

#' Load data with caching
#' @param path Dot notation path to load data (e.g. "source.private.example")
#' @param expire_after Optional expiration time in hours (default: from config$options$data$cache_default_expire)
#' @param refresh Optional boolean or function that returns boolean to force refresh
#' @return The loaded data, either from cache or file
#' @export
load_data_or_cache <- function(path, expire_after = NULL, refresh = FALSE) {
  if (!is.character(path) || length(path) != 1) {
    stop("Path must be a single string")
  }

  cache_key <- sprintf("data.%s", path)
  get_or_cache(cache_key,
    {
      message(sprintf("Loading data from file: %s (cached as %s)", path, cache_key))
      load_data(path)
    },
    expire_after = expire_after,
    refresh = refresh
  )
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
#' Gets the data specification for a given dot notation path
#' @param path Dot notation path (e.g. "source.private.example")
#' @return The data specification as a list
#' @export
get_data_spec <- function(path) {
  config <- read_config()

  # Get file type info
  get_file_type_info <- function(path) {
    is_csv <- grepl("\\.csv$", path, ignore.case = TRUE)
    list(
      type = if (is_csv) "csv" else "rds",
      delimiter = if (is_csv) "comma" else NULL
    )
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
    if (grepl("[/\\\\]", path)) {
      create_spec(file.path(getwd(), path))
    } else {
      get_dot_notation_spec(strsplit(path, "\\.")[[1]], config)
    }
  }

  get_spec_by_path_type(path, config)
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
