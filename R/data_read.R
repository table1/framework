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
  parts <- strsplit(path, "\\.")[[1]]

  # Get data from config$data directly (no more files check)
  current <- config$data

  # First try to find in config
  config_spec <- current
  for (part in parts) {
    if (is.null(config_spec[[part]])) {
      config_spec <- NULL
      break
    }
    config_spec <- config_spec[[part]]
  }

  # Create base spec with defaults from config$options$data
  create_spec <- function(path, existing_spec = NULL) {
    # Start with defaults from options
    spec <- list(
      path = path,
      type = if (grepl("\\.csv$", path, ignore.case = TRUE)) "csv" else "rds",
      delimiter = if (grepl("\\.csv$", path, ignore.case = TRUE)) "comma" else NULL,
      locked = FALSE,
      private = basename(dirname(path)) == "private",
      encrypted = FALSE
    )

    # Merge with any options from config$options$data
    if (!is.null(config$options$data)) {
      spec <- modifyList(spec, config$options$data)
    }

    # If we have an existing spec, merge it with our defaults
    if (!is.null(existing_spec)) {
      # Preserve any explicitly set values
      for (key in names(existing_spec)) {
        if (!is.null(existing_spec[[key]])) {
          spec[[key]] <- existing_spec[[key]]
        }
      }
    }

    spec
  }

  # If found in config, return it
  if (!is.null(config_spec)) {
    # If current is just a string, create a simple spec
    if (is.character(config_spec) && length(config_spec) == 1) {
      create_spec(config_spec)
    } else {
      # Merge with defaults, preserving any explicit settings
      create_spec(config_spec$path, config_spec)
    }
  }

  # If not in config, look for physical file
  # Convert dot notation to directory structure
  file_name <- parts[length(parts)]
  dir_parts <- parts[-length(parts)]
  search_dir <- file.path("data", paste(dir_parts, collapse = "/"))

  if (!dir.exists(search_dir)) {
    NULL
  }

  # Find all matching files
  matching_files <- list.files(
    search_dir,
    pattern = paste0("^", file_name, "\\."),
    full.names = TRUE
  )

  if (length(matching_files) == 0) {
    NULL
  }

  # If multiple files exist, prefer CSV
  if (length(matching_files) > 1) {
    csv_file <- matching_files[grepl("\\.csv$", matching_files, ignore.case = TRUE)][1]
    if (!is.na(csv_file)) {
      message(sprintf(
        "Multiple files found for %s, using CSV: %s",
        file_name,
        basename(csv_file)
      ))
      matching_files <- csv_file
    } else {
      matching_files <- sort(matching_files)
      message(sprintf(
        "Multiple files found for %s, using: %s",
        file_name,
        basename(matching_files[1])
      ))
    }
  }

  # Create spec for found file
  create_spec(matching_files[1])
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
