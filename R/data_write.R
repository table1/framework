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
  # Validate arguments
  checkmate::assert_data_frame(data, min.rows = 1)
  checkmate::assert_string(path, min.chars = 1)
  checkmate::assert_choice(type, c("csv", "rds"))
  checkmate::assert_choice(delimiter, c("comma", "tab", "semicolon", "space"))
  checkmate::assert_flag(locked)
  checkmate::assert_flag(encrypted)

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
  current_hash <- tryCatch(
    .calculate_file_hash(file_path),
    error = function(e) {
      stop(sprintf("Failed to calculate file hash for '%s': %s", file_path, e$message))
    }
  )

  tryCatch(
    .set_data(
      name = path,
      path = file_path,
      type = type,
      delimiter = if (type == "csv") delimiter else NA,
      locked = locked,
      encrypted = encrypted,
      hash = current_hash
    ),
    error = function(e) {
      stop(sprintf("Failed to update database record for '%s': %s", path, e$message))
    }
  )
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
#' @param path The file path
#' @param type The data type (csv, rds, etc.)
#' @param delimiter The delimiter for CSV files
#' @param locked Whether the data is locked
#' @param encrypted Whether the data is encrypted
#' @param hash The hash of the data
#' @keywords internal
.set_data <- function(name, path = NULL, type = NULL, delimiter = NULL, locked = FALSE, encrypted = FALSE, hash = NULL) {
  # Validate arguments
  checkmate::assert_string(name, min.chars = 1)
  checkmate::assert_string(path, null.ok = TRUE, na.ok = TRUE)
  checkmate::assert_string(type, null.ok = TRUE, na.ok = TRUE)
  checkmate::assert_string(delimiter, null.ok = TRUE, na.ok = TRUE)
  checkmate::assert_flag(locked)
  checkmate::assert_flag(encrypted)
  checkmate::assert_string(hash, null.ok = TRUE, na.ok = TRUE)

  # Get database connection
  con <- tryCatch(
    .get_db_connection(),
    error = function(e) {
      stop(sprintf("Failed to connect to database: %s", e$message))
    }
  )
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  now <- lubridate::now()

  # Convert booleans to integers for SQLite
  locked_int <- as.integer(locked)
  encrypted_int <- as.integer(encrypted)

  # Convert NULL values to NA for SQLite
  path_value <- if (is.null(path)) NA else path
  type_value <- if (is.null(type)) NA else type
  delimiter_value <- if (is.null(delimiter)) NA else delimiter
  hash_value <- if (is.null(hash)) NA else hash

  # Check if entry exists
  entry_exists <- tryCatch(
    DBI::dbGetQuery(
      con,
      "SELECT 1 FROM data WHERE name = ?",
      list(name)
    ),
    error = function(e) {
      stop(sprintf("Failed to check for existing data record: %s", e$message))
    }
  )

  if (nrow(entry_exists) > 0) {
    # Update existing entry
    tryCatch(
      DBI::dbExecute(
        con,
        "UPDATE data SET path = ?, type = ?, delimiter = ?, locked = ?, encrypted = ?, hash = ?, last_read_at = ?, updated_at = ? WHERE name = ?",
        list(path_value, type_value, delimiter_value, locked_int, encrypted_int, hash_value, now, now, name)
      ),
      error = function(e) {
        stop(sprintf("Failed to update data record: %s", e$message))
      }
    )
  } else {
    # Insert new entry
    tryCatch(
      DBI::dbExecute(
        con,
        "INSERT INTO data (name, path, type, delimiter, locked, encrypted, hash, last_read_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        list(name, path_value, type_value, delimiter_value, locked_int, encrypted_int, hash_value, now, now, now)
      ),
      error = function(e) {
        stop(sprintf("Failed to insert data record: %s", e$message))
      }
    )
  }

  invisible(NULL)
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
  # Validate arguments
  checkmate::assert_string(path, min.chars = 1)
  checkmate::assert_list(spec)

  parts <- strsplit(path, "\\.")[[1]]

  # Check if config.yml exists
  if (!file.exists("config.yml")) {
    stop("Configuration file 'config.yml' not found")
  }

  # Load raw config.yml to determine where `data` is defined
  raw_config <- tryCatch(
    yaml::read_yaml("config.yml", eval.expr = FALSE),
    error = function(e) {
      stop(sprintf("Failed to read config.yml: %s", e$message))
    }
  )

  # Check if default section exists
  if (is.null(raw_config$default)) {
    stop("Config file missing 'default' section")
  }

  data_source <- raw_config$default$data

  # Determine if `data` is a path or inline
  if (is.character(data_source) && length(data_source) == 1 && file.exists(data_source)) {
    # Data is in external file
    data_path <- data_source
    current <- tryCatch(
      yaml::read_yaml(data_path, eval.expr = FALSE),
      error = function(e) {
        stop(sprintf("Failed to read data file '%s': %s", data_path, e$message))
      }
    )
  } else {
    # Data is inline in config.yml
    data_path <- "config.yml"
    current <- if (is.null(data_source)) list() else data_source
  }

  # Build nested path and insert the spec
  # We need to use a recursive approach since R lists are not reference types
  if (length(parts) == 1) {
    current[[parts[1]]] <- spec
  } else {
    # Build the nested structure by evaluating from the deepest level up
    path_str <- paste0("current", paste0("[[\"", parts, "\"]]", collapse = ""))
    assign_str <- paste0(path_str, " <- spec")

    # Ensure intermediate paths exist
    for (i in seq_along(parts)[-length(parts)]) {
      intermediate_path <- paste0("current", paste0("[[\"", parts[1:i], "\"]]", collapse = ""))
      eval_str <- paste0("if (is.null(", intermediate_path, ") || !is.list(", intermediate_path, ")) { ",
                        intermediate_path, " <- list() }")
      eval(parse(text = eval_str))
    }

    # Assign the spec
    eval(parse(text = assign_str))
  }

  # Write back to the correct location
  tryCatch({
    if (data_path != "config.yml") {
      yaml::write_yaml(current, data_path)
    } else {
      raw_config$default$data <- current
      yaml::write_yaml(raw_config, "config.yml")
    }
  }, error = function(e) {
    stop(sprintf("Failed to write configuration: %s", e$message))
  })

  invisible(NULL)
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
