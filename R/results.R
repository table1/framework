#' Save a result
#' @param name Result name
#' @param value The result value to save (will be evaluated if it's an expression)
#' @param type Type of result (e.g. "model", "notebook")
#' @param blind Whether the result should be blinded (encrypted)
#' @param public Whether the result should be public (default: FALSE)
#' @param comment Optional description
#' @param file Optional path to a file to save (e.g. a QMD notebook)
#' @param password Optional password for encryption. If NULL and blind=TRUE, uses ENCRYPTION_PASSWORD from environment or prompts
#' @export
result_save <- function(name, value = NULL, type, blind = FALSE, public = FALSE, comment = "", file = NULL, password = NULL) {
  # Validate inputs
  checkmate::assert_string(name)
  checkmate::assert_string(type)
  checkmate::assert_flag(blind)
  checkmate::assert_flag(public)
  checkmate::assert_string(comment, null.ok = TRUE)
  checkmate::assert_string(password, null.ok = TRUE)
  if (!is.null(file)) {
    checkmate::assert_file_exists(file)
  }

  # Get results directory from config
  config <- read_config()
  results_dir <- if (public) {
    config$options$results$public_dir %||% "results/public"
  } else {
    config$options$results$private_dir %||% "results/private"
  }
  dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

  if (!is.null(file)) {
    # Verify file exists
    if (!file.exists(file)) {
      stop(sprintf("File not found: %s", file))
    }

    # Get file extension and create destination path
    ext <- tools::file_ext(file)
    result_file <- file.path(results_dir, paste0(name, if (ext != "") paste0(".", ext) else ""))

    # Copy the file
    file.copy(file, result_file, overwrite = TRUE)
    message(sprintf("Saved file '%s' to %s", basename(file), result_file))
  } else {
    # Save R object to RDS file
    result_file <- file.path(results_dir, paste0(name, ".rds"))

    if (blind) {
      # Get password (from parameter, environment, or prompt)
      pwd <- if (!is.null(password)) {
        password
      } else {
        .get_encryption_password(prompt = TRUE)
      }

      # Serialize and encrypt
      serialized_data <- serialize(value, NULL)
      encrypted_data <- .encrypt_with_password(serialized_data, pwd)
      writeBin(encrypted_data, result_file)
      message(sprintf("Saved encrypted R object to %s", result_file))
    } else {
      saveRDS(value, result_file)
      message(sprintf("Saved R object to %s", result_file))
    }
  }

  # Calculate hash
  hash <- .calculate_file_hash(result_file)

  # Update database record
  con <- .get_db_connection()
  now <- lubridate::now()

  # Check if entry exists
  entry_exists <- DBI::dbGetQuery(
    con,
    "SELECT 1 FROM results WHERE name = ?",
    list(name)
  )

  if (nrow(entry_exists) > 0) {
    # Update existing entrys
    DBI::dbExecute(
      con,
      "UPDATE results SET type = ?, blind = ?, public = ?, comment = ?, hash = ?, last_read_at = ?, updated_at = ? WHERE name = ?",
      list(type, as.integer(blind), as.integer(public), comment, hash, now, now, name)
    )
  } else {
    # Insert new entry
    DBI::dbExecute(
      con,
      "INSERT INTO results (name, type, blind, public, comment, hash, last_read_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
      list(name, type, as.integer(blind), as.integer(public), comment, hash, now, now, now)
    )
  }

  DBI::dbDisconnect(con)
  invisible(NULL)
}

#' Get a result
#' @param name Result name
#' @param password Optional password for decryption. If NULL, uses ENCRYPTION_PASSWORD from environment or prompts
#' @return The result value, or NULL if not found or hash mismatch
#' @export
result_get <- function(name, password = NULL) {
  # Validate arguments
  checkmate::assert_string(name, min.chars = 1)
  checkmate::assert_string(password, null.ok = TRUE)

  # Get result record
  con <- tryCatch(
    .get_db_connection(),
    error = function(e) {
      stop(sprintf("Failed to connect to database: %s", e$message))
    }
  )
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  result <- tryCatch(
    DBI::dbGetQuery(
      con,
      "SELECT type, blind, public, hash FROM results WHERE name = ? AND deleted_at IS NULL",
      list(name)
    ),
    error = function(e) {
      stop(sprintf("Failed to query results: %s", e$message))
    }
  )

  if (nrow(result) == 0) {
    stop(sprintf("Result '%s' not found", name))
  }

  # Get result file from config
  config <- read_config()
  results_dir <- if (result$public) {
    config$options$results$public_dir %||% "results/public"
  } else {
    config$options$results$private_dir %||% "results/private"
  }
  result_file <- file.path(results_dir, paste0(name, ".rds"))

  if (!file.exists(result_file)) {
    stop(sprintf("Result file not found: %s", result_file))
  }

  # Verify hash
  current_hash <- tryCatch(
    .calculate_file_hash(result_file),
    error = function(e) {
      stop(sprintf("Failed to calculate hash for result '%s': %s", name, e$message))
    }
  )

  if (current_hash != result$hash) {
    stop(sprintf("Hash mismatch for result '%s' - file may be corrupted (expected: %s, got: %s)",
                 name, result$hash, current_hash))
  }

  # Auto-detect encryption and read result
  is_encrypted <- .is_encrypted_file(result_file)

  tryCatch({
    if (is_encrypted) {
      # Get password (from parameter, environment, or prompt)
      pwd <- if (!is.null(password)) {
        password
      } else {
        .get_encryption_password(prompt = TRUE)
      }

      # Read and decrypt
      encrypted_data <- readBin(result_file, "raw", n = file.info(result_file)$size)
      decrypted_data <- .decrypt_with_password(encrypted_data, pwd)
      unserialize(decrypted_data)
    } else {
      readRDS(result_file)
    }
  }, error = function(e) {
    stop(sprintf("Failed to read result '%s': %s", name, e$message))
  })
}

#' List all results
#' @return A data frame of results with their metadata
#' @export
result_list <- function() {
  con <- .get_db_connection()
  results <- DBI::dbGetQuery(
    con,
    "SELECT name, type, blind, public, comment, last_read_at, created_at, updated_at FROM results WHERE deleted_at IS NULL ORDER BY name"
  )
  DBI::dbDisconnect(con)

  # Convert timestamps to POSIXct
  results$last_read_at <- lubridate::as_datetime(results$last_read_at)
  results$created_at <- lubridate::as_datetime(results$created_at)
  results$updated_at <- lubridate::as_datetime(results$updated_at)

  results
}

