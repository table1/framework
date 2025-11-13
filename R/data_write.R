#' Save data using dot notation or file path
#'
#' @param data Data frame to save
#' @param path Either:
#'   - Dot notation: "intermediate.filename" resolves to inputs/intermediate/filename.{type}
#'   - Direct path: "inputs/intermediate/filename.csv" uses path as-is
#'   - Simple filename: "filename" requires force = TRUE or errors
#' @param type Type of data file ("csv" or "rds"). Auto-detected from extension if path includes one.
#' @param delimiter Delimiter for CSV files ("comma", "tab", "semicolon", "space")
#' @param locked Whether the file should be locked after saving
#' @param encrypted Whether the file should be encrypted
#' @param password Optional password for encryption. If NULL, uses ENCRYPTION_PASSWORD from environment or prompts
#' @param force If TRUE, creates missing directories. If FALSE (default), errors if directory doesn't exist.
#' @export
data_save <- function(data, path, type = NULL, delimiter = "comma", locked = TRUE, encrypted = FALSE, password = NULL, force = FALSE) {
  # Validate arguments
  checkmate::assert_data_frame(data, min.rows = 1)
  checkmate::assert_string(path, min.chars = 1)
  checkmate::assert_choice(delimiter, c("comma", "tab", "semicolon", "space"))
  checkmate::assert_flag(locked)
  checkmate::assert_flag(encrypted)
  checkmate::assert_string(password, null.ok = TRUE)
  checkmate::assert_flag(force)

  # Detect path format
  has_slash <- grepl("/", path, fixed = TRUE)
  has_extension <- grepl("\\.(csv|rds)$", path, ignore.case = TRUE)

  if (has_slash || has_extension) {
    # Direct file path mode
    file_path <- path

    # Auto-detect type from extension if not specified
    if (is.null(type)) {
      if (grepl("\\.csv$", path, ignore.case = TRUE)) {
        type <- "csv"
      } else if (grepl("\\.rds$", path, ignore.case = TRUE)) {
        type <- "rds"
      } else {
        stop("Cannot auto-detect file type from path. Please specify 'type' parameter.")
      }
    }

    # Ensure extension matches type
    expected_ext <- paste0(".", type)
    if (!grepl(paste0(expected_ext, "$"), path, ignore.case = TRUE)) {
      file_path <- paste0(path, expected_ext)
      message(sprintf("Note: Added .%s extension to path", type))
    }

    dir_path <- dirname(file_path)
    file_name <- basename(file_path)

  } else if (grepl("\\.", path)) {
    # Dot notation mode (e.g., "intermediate.filename" or legacy "test.public.sample")
    parts <- strsplit(path, ".", fixed = TRUE)[[1]]

    if (length(parts) < 2) {
      stop("Dot notation requires at least two parts (e.g., 'intermediate.filename')")
    }

    # Try to resolve first part as a directory key from config
    # Check common directory keys: raw, intermediate, final, private, public, etc.
    dir_key <- parts[1]
    possible_keys <- c(
      sprintf("directories.inputs_%s", dir_key),
      sprintf("directories.outputs_%s", dir_key),
      sprintf("directories.%s", dir_key)
    )

    resolved_dir <- NULL
    for (key in possible_keys) {
      resolved_dir <- tryCatch(config(key), error = function(e) NULL)
      if (!is.null(resolved_dir)) break
    }

    if (!is.null(resolved_dir)) {
      # New behavior: first part resolved to a configured directory
      # Example: "intermediate.filename" → inputs/intermediate/filename.rds
      dir_path <- resolved_dir
      file_base <- paste(parts[-1], collapse = "_")

      # Default type to rds if not specified
      if (is.null(type)) type <- "rds"

      file_name <- paste0(file_base, ".", type)
      file_path <- file.path(dir_path, file_name)

    } else {
      # Legacy behavior: create nested structure under data/
      # Example: "test.public.sample" → data/test/public/sample.csv
      dir_parts <- c("data", parts[-length(parts)])
      dir_path <- do.call(file.path, as.list(dir_parts))

      # Default type to csv for legacy compatibility
      if (is.null(type)) type <- "csv"

      file_name <- paste0(parts[length(parts)], ".", type)
      file_path <- file.path(dir_path, file_name)
    }

  } else {
    # Simple filename with no directory - require force
    stop(sprintf(
      "Path '%s' has no directory. Either:\n  - Use dot notation: 'intermediate.%s'\n  - Provide full path: 'inputs/intermediate/%s.%s'",
      path, path, path, type %||% "rds"
    ))
  }

  # Validate type after resolution
  checkmate::assert_choice(type, c("csv", "rds"))

  # Check if directory exists
  if (!dir.exists(dir_path)) {
    if (force) {
      dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
      message(sprintf("Created directory: %s", dir_path))
    } else {
      stop(sprintf(
        "Directory '%s' does not exist. Use force = TRUE to create it.",
        dir_path
      ))
    }
  }

  # Prepare data for saving
  if (encrypted) {
    # Get password
    pwd <- if (!is.null(password)) {
      password
    } else {
      .get_encryption_password(prompt = TRUE)
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
        content <- readBin(temp_file, "raw", n = file.info(temp_file)$size)
        unlink(temp_file)
        content
      },
      rds = serialize(data, NULL),
      stop(sprintf("Unsupported file type: %s", type))
    )

    # Encrypt the serialized data
    encrypted_data <- .encrypt_with_password(serialized_data, pwd)
    # Write encrypted data
    writeBin(encrypted_data, file_path)

    message(sprintf("Data encrypted and saved to: %s", file_path))
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

  # Create normalized name for database tracking
  # Use the original path input as the identifier
  data_name <- path

  # Calculate hash and update data record
  current_hash <- tryCatch(
    .calculate_file_hash(file_path),
    error = function(e) {
      stop(sprintf("Failed to calculate file hash for '%s': %s", file_path, e$message))
    }
  )

  tryCatch(
    .set_data(
      name = data_name,
      path = file_path,
      type = type,
      delimiter = if (type == "csv") delimiter else NA,
      locked = locked,
      encrypted = encrypted,
      hash = current_hash
    ),
    error = function(e) {
      stop(sprintf("Failed to update database record for '%s': %s", data_name, e$message))
    }
  )
  message(sprintf("\u2713 Database updated: %s", data_name))

  invisible(data)
}

#' Alias for backward compatibility
#' @param data Data frame to save
#' @param path Either dot notation, direct path, or simple filename
#' @param type Type of data file ("csv" or "rds"). Auto-detected from extension if path includes one.
#' @param delimiter Delimiter for CSV files ("comma", "tab", "semicolon", "space")
#' @param locked Whether the file should be locked after saving
#' @param encrypted Whether the file should be encrypted
#' @param password Optional password for encryption
#' @param force If TRUE, creates missing directories. If FALSE (default), errors if directory doesn't exist.
#' @export
save_data <- function(data, path, type = NULL, delimiter = "comma", locked = TRUE, encrypted = FALSE, password = NULL, force = FALSE) {
  data_save(data, path, type, delimiter, locked, encrypted, password, force)
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
#' the given spec in the corresponding YAML file (either embedded in settings.yml
#' or in an external settings/data.yml file). Automatically handles nested paths
#' and creates intermediate structures as needed.
#'
#' @param path Dot notation key (e.g., "final.public.test") indicating where
#'   to place the spec in the configuration hierarchy
#' @param spec A named list containing the data spec fields (path, type,
#'   delimiter, locked, encrypted, etc.)
#'
#' @return Invisibly returns NULL. Function is called for its side effect of
#'   updating the YAML configuration file.
#'
#' @examples
#' \dontrun{
#' # Update a spec in the config
#' data_spec_update("final.public.test", list(
#'   path = "data/public/test.csv",
#'   type = "csv",
#'   delimiter = "comma",
#'   locked = TRUE
#' ))
#' }
#'
#' @export
data_spec_update <- function(path, spec) {
  # Validate arguments
  checkmate::assert_string(path, min.chars = 1)
  checkmate::assert_list(spec)

  parts <- strsplit(path, "\\.")[[1]]

  # Discover settings file
  config_path <- .get_settings_file()
  if (is.null(config_path)) {
    stop("Configuration file 'settings.yml' (or legacy config.yml) not found")
  }

  # Load raw config to determine where `data` is defined
  raw_config <- tryCatch(
    yaml::read_yaml(config_path, eval.expr = FALSE),
    error = function(e) {
      stop(sprintf("Failed to read %s: %s", config_path, e$message))
    }
  )

  # Support both environment-scoped and flat configs
  has_envs <- !is.null(raw_config$default) && is.list(raw_config$default)
  env_key <- if (has_envs) "default" else NULL
  env_config <- if (has_envs) raw_config$default else raw_config

  data_source <- env_config$data

  # Determine if `data` is a path or inline
  is_external <- is.character(data_source) && length(data_source) == 1
  if (is_external) {
    data_path <- data_source
    current <- if (file.exists(data_path)) {
      tryCatch({
        external_content <- yaml::read_yaml(data_path, eval.expr = FALSE)
        # External data files have a 'data' wrapper, extract it
        if (!is.null(external_content$data)) {
          external_content$data
        } else {
          external_content
        }
      },
      error = function(e) {
        stop(sprintf("Failed to read data file '%s': %s", data_path, e$message))
      })
    } else {
      list()
    }
  } else {
    data_path <- config_path
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
    if (is_external) {
      dir.create(dirname(data_path), recursive = TRUE, showWarnings = FALSE)
      # Wrap in 'data' key when writing to external file
      yaml::write_yaml(list(data = current), data_path)
    } else {
      env_config$data <- current
      if (!is.null(env_key)) {
        raw_config[[env_key]] <- env_config
      } else {
        raw_config <- env_config
      }
      yaml::write_yaml(raw_config, config_path)
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
