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

  # Whether file is encrypted
  is_encrypted <- ifelse(is.null(spec$encrypted), FALSE, spec$encrypted)

  # Calculate current file hash
  current_hash <- .calculate_file_hash(spec$path)

  # Get existing data record
  data_record <- .get_data_record(path)

  # Handle hash checking and data loading
  if (is.null(data_record)) {
    # No record exists, create one with current hash
    .set_data(path, encrypted = is_encrypted, hash = current_hash)

    # Load unencrypted data
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
        readr::read_csv(spec$path, show_col_types = FALSE)
      },
      rds = readRDS(spec$path),
      stop(sprintf("Unsupported file type: %s", spec$type))
    )
  } else if (spec$locked) {
    # Record exists and data is locked, verify hash
    if (data_record$hash != current_hash) {
      stop(sprintf("Hash mismatch for locked data: %s", path))
    }

    # Load data based on encryption
    if (data_record$encrypted) {
      config <- read_config()
      if (is.null(config$security$data_key)) {
        stop("Data encryption key not found in config")
      }
      # Read and decrypt the file
      encrypted_data <- readBin(spec$path, "raw", n = file.size(spec$path))
      decrypted_data <- .decrypt_data(encrypted_data, config$security$data_key)

      # Parse decrypted data based on type
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
          readr::read_csv(rawToChar(decrypted_data), show_col_types = FALSE)
        },
        rds = unserialize(decrypted_data),
        stop(sprintf("Unsupported file type: %s", spec$type))
      )
    } else {
      # Load unencrypted data
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
          readr::read_csv(spec$path, show_col_types = FALSE)
        },
        rds = readRDS(spec$path),
        stop(sprintf("Unsupported file type: %s", spec$type))
      )
    }
  } else {
    # Record exists but not locked, update hash
    .set_data(path, encrypted = data_record$encrypted, hash = current_hash)

    # Load data based on encryption
    if (data_record$encrypted) {
      config <- read_config()
      if (is.null(config$security$data_key)) {
        stop("Data encryption key not found in config")
      }
      # Read and decrypt the file
      encrypted_data <- readBin(spec$path, "raw", n = file.size(spec$path))
      decrypted_data <- .decrypt_data(encrypted_data, config$security$data_key)

      # Parse decrypted data based on type
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
          readr::read_csv(rawToChar(decrypted_data), show_col_types = FALSE)
        },
        rds = unserialize(decrypted_data),
        stop(sprintf("Unsupported file type: %s", spec$type))
      )
    } else {
      # Load unencrypted data
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
          readr::read_csv(spec$path, show_col_types = FALSE)
        },
        rds = readRDS(spec$path),
        stop(sprintf("Unsupported file type: %s", spec$type))
      )
    }
  }
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

  # Check if we should start under "files"
  if ("files" %in% names(config$data)) {
    current <- config$data$files
  } else {
    current <- config$data
  }

  # First try to find in config
  config_spec <- current
  for (part in parts) {
    if (is.null(config_spec[[part]])) {
      config_spec <- NULL
      break
    }
    config_spec <- config_spec[[part]]
  }

  # If found in config, return it
  if (!is.null(config_spec)) {
    # If current is just a string, create a simple spec
    if (is.character(config_spec) && length(config_spec) == 1) {
      return(list(
        path = config_spec,
        type = if (grepl("\\.csv$", config_spec)) "csv" else "rds",
        delimiter = if (grepl("\\.csv$", config_spec)) "comma" else NULL,
        locked = FALSE,
        encrypted = FALSE
      ))
    }
    return(config_spec)
  }

  # If not in config, look for physical file
  # Convert dot notation to directory structure
  file_name <- parts[length(parts)]
  dir_parts <- parts[-length(parts)]
  search_dir <- file.path("data", paste(dir_parts, collapse = "/"))

  if (!dir.exists(search_dir)) {
    return(NULL)
  }

  # Find all matching files
  matching_files <- list.files(
    search_dir,
    pattern = paste0("^", file_name, "\\."),
    full.names = TRUE
  )

  if (length(matching_files) == 0) {
    return(NULL)
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

  file_path <- matching_files[1]
  return(list(
    path = file_path,
    type = if (grepl("\\.csv$", file_path, ignore.case = TRUE)) "csv" else "rds",
    delimiter = if (grepl("\\.csv$", file_path, ignore.case = TRUE)) "comma" else NULL,
    locked = FALSE,
    encrypted = FALSE
  ))
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
