#' Save data using dot notation path
#'
#' @param data Data frame to save
#' @param path Dot notation path to save data (e.g. "source.private.example")
#' @param type Type of data file ("csv" or "rds")
#' @param delimiter Delimiter for CSV files ("comma", "tab", "semicolon", "space")
#' @param locked Whether the file should be locked after saving
#' @param encrypted Whether the file should be encrypted
#' @export
data_save <- function(data, path, type = "csv", delimiter = "comma", locked = TRUE, encrypted = FALSE) {
  # Split path into components
  parts <- strsplit(path, "\\.")[[1]]

  # Create directory structure
  dir_parts <- c("data", parts[-length(parts)])
  dir_path <- do.call(file.path, as.list(dir_parts))
  dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)

  # Create file path
  file_name <- paste0(parts[length(parts)], ".", type)
  file_path <- file.path(dir_path, file_name)

  # Prepare data for saving
  if (encrypted) {
    config <- read_config()
    if (is.null(config$security$data_key)) {
      stop("Data encryption key not found in config")
    }

    # Serialize data based on type
    serialized_data <- switch(type,
      csv = {
        # Convert delimiter name to actual character
        delim <- switch(delimiter,
          comma = ",",
          tab = "\t",
          semicolon = ";",
          space = " "
        )
        # Write to temp file first
        temp_file <- tempfile(fileext = ".csv")
        readr::write_csv(data, temp_file)
        # Read raw bytes
        content <- readBin(temp_file, "raw", n = file.size(temp_file))
        unlink(temp_file)
        content
      },
      rds = serialize(data, NULL),
      stop(sprintf("Unsupported file type: %s", type))
    )

    # Encrypt the serialized data
    encrypted_data <- .encrypt_data(serialized_data, config$security$data_key)
    # Write encrypted data
    writeBin(encrypted_data, file_path)
  } else {
    # Save data normally
    switch(type,
      csv = {
        # Convert delimiter name to actual character
        delim <- switch(delimiter,
          comma = ",",
          tab = "\t",
          semicolon = ";",
          space = " "
        )
        readr::write_csv(data, file_path)
      },
      rds = saveRDS(data, file_path),
      stop(sprintf("Unsupported file type: %s", type))
    )
  }

  message(sprintf("Data saved to: %s", file_path))

  # Create example YAML for the spec
  spec_indent <- "  "
  yaml_lines <- c(
    sprintf("%s%s:", spec_indent, parts[length(parts)]),
    sprintf("%s  path: %s", spec_indent, file_path),
    sprintf("%s  type: %s", spec_indent, type),
    sprintf("%s  locked: %s", spec_indent, tolower(as.character(locked))),
    sprintf("%s  encrypted: %s", spec_indent, tolower(as.character(encrypted)))
  )

  if (type == "csv") {
    yaml_lines <- c(yaml_lines, sprintf("%s  delimiter: %s", spec_indent, delimiter))
  }

  yaml_example <- paste(yaml_lines, collapse = "\n")

  # Create path to show where to add it
  path_to_add <- paste(c("data", parts[-length(parts)]), collapse = " -> ")

  message("\nAdd this to your config.yml or settings/data.yml file under:")
  message("\n", path_to_add)
  message("\n", yaml_example, "\n")

  # Calculate hash and update data record
  current_hash <- .calculate_file_hash(file_path)
  .set_data(path, encrypted = encrypted, hash = current_hash)
  message(sprintf("Data record updated for: %s", path))

  invisible(data)
}

#' Alias for backward compatibility
#' @param data Data frame to save
#' @param path Dot notation path to save data (e.g. "source.private.example")
#' @param type Type of data file ("csv" or "rds")
#' @param delimiter Delimiter for CSV files ("comma", "tab", "semicolon", "space")
#' @param locked Whether the file should be locked after saving
#' @param encrypted Whether the file should be encrypted
#' @export
save_data <- function(data, path, type = "csv", delimiter = "comma", locked = TRUE, encrypted = FALSE) {
  data_save(data, path, type, delimiter, locked, encrypted)
}


#' Set a data value
#' @param name The data name
#' @param encrypted Whether the data is encrypted
#' @param hash The hash of the data
#' @keywords internal
.set_data <- function(name, encrypted = FALSE, hash = NULL) {
  con <- .get_db_connection()
  now <- lubridate::now()

  # Convert encrypted to integer (SQLite boolean)
  encrypted_int <- as.integer(encrypted)

  # Convert NULL hash to NA (SQLite NULL)
  hash_value <- if (is.null(hash)) NA else hash

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
      "UPDATE data SET encrypted = ?, hash = ?, last_read_at = ?, updated_at = ? WHERE name = ?",
      list(encrypted_int, hash_value, now, now, name)
    )
  } else {
    # Insert new entry
    DBI::dbExecute(
      con,
      "INSERT INTO data (name, encrypted, hash, last_read_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
      list(name, encrypted_int, hash_value, now, now, now)
    )
  }

  DBI::dbDisconnect(con)
}

#' Remove a data value
#' @param name The data name to remove
#' @keywords internal
.remove_data <- function(name) {
  con <- .get_db_connection()
  DBI::dbExecute(
    con,
    "DELETE FROM data WHERE name = ?",
    params = list(name)
  )
  DBI::dbDisconnect(con)
}


#' Update data spec in the correct YAML file
#'
#' Traverses a dot-notated key like "final.public.test" and updates or inserts
#' the given spec in the corresponding YAML file (either embedded or external).
#'
#' @param path Dot notation key (e.g., "final.public.test")
#' @param spec A named list containing the data spec
#' @export
update_data_spec <- function(path, spec) {
  parts <- strsplit(path, "\\.")[[1]]

  # Load raw config.yml to determine where `data` is defined
  raw_config <- yaml::read_yaml("config.yml", eval.expr = TRUE)
  data_source <- raw_config$default$data

  # Determine if `data` is a path or inline
  if (is.character(data_source) && file.exists(data_source)) {
    data_path <- data_source
    current <- yaml::read_yaml(data_path, eval.expr = TRUE)
  } else {
    data_path <- "config.yml"
    current <- config::get()$data
  }

  # Traverse and insert the spec
  ref <- current
  for (i in seq_along(parts)) {
    part <- parts[i]
    if (i == length(parts)) {
      ref[[part]] <- spec
    } else {
      if (is.null(ref[[part]]) || !is.list(ref[[part]])) {
        ref[[part]] <- list()
      }
      ref <- ref[[part]]
    }
  }

  # Write back to the correct location
  if (data_path != "config.yml") {
    yaml::write_yaml(current, data_path)
  } else {
    raw_config$default$data <- current
    yaml::write_yaml(raw_config, "config.yml")
  }
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
