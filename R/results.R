#' Save a result
#' @param name Result name
#' @param value The result value to save (will be evaluated if it's an expression)
#' @param type Type of result (e.g. "model", "notebook")
#' @param blind Whether the result should be blinded (encrypted)
#' @param public Whether the result should be public (default: FALSE)
#' @param comment Optional description
#' @param file Optional path to a file to save (e.g. a QMD notebook)
#' @export
result_save <- function(name, value = NULL, type, blind = FALSE, public = FALSE, comment = "", file = NULL) {
  # Validate inputs
  if (!is.character(name) || length(name) != 1) {
    stop("name must be a single string")
  }
  if (!is.character(type) || length(type) != 1) {
    stop("type must be a single string")
  }
  if (!is.logical(blind) || length(blind) != 1) {
    stop("blind must be a single logical value")
  }
  if (!is.logical(public) || length(public) != 1) {
    stop("public must be a single logical value")
  }
  if (!is.null(comment) && (!is.character(comment) || length(comment) != 1)) {
    stop("comment must be a single string or NULL")
  }
  if (!is.null(file) && (!is.character(file) || length(file) != 1)) {
    stop("file must be a single string or NULL")
  }

  # Create results directory if it doesn't exist
  results_dir <- if (public) "results/public" else "results/private"
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
      # Get encryption key
      config <- read_config()
      if (is.null(config$security$results_key)) {
        stop("Results encryption key not found in config")
      }
      # Encrypt and save
      encrypted_data <- .encrypt_data(serialize(value, NULL), config$security$results_key)
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
#' @return The result value, or NULL if not found or hash mismatch
#' @export
result_get <- function(name) {
  # Get result record
  con <- .get_db_connection()
  result <- DBI::dbGetQuery(
    con,
    "SELECT type, blind, public, hash FROM results WHERE name = ? AND deleted_at IS NULL",
    list(name)
  )
  DBI::dbDisconnect(con)

  if (nrow(result) == 0) {
    return(NULL)
  }

  # Get result file
  results_dir <- if (result$public) "results/public" else "results/private"
  result_file <- file.path(results_dir, paste0(name, ".rds"))

  if (!file.exists(result_file)) {
    return(NULL)
  }

  # Verify hash
  current_hash <- .calculate_file_hash(result_file)
  if (current_hash != result$hash) {
    warning(sprintf("Hash mismatch for result '%s' - result may be corrupted", name))
    return(NULL)
  }

  # Read result
  if (result$blind) {
    # Get encryption key
    config <- read_config()
    if (is.null(config$security$results_key)) {
      stop("Results encryption key not found in config")
    }
    # Read and decrypt
    encrypted_data <- readBin(result_file, "raw", n = file.size(result_file))
    decrypted_data <- .decrypt_data(encrypted_data, config$security$results_key)
    unserialize(decrypted_data)
  } else {
    readRDS(result_file)
  }
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

#' Aliases for backward compatibility
#' @param name Result name
#' @return The result value, or NULL if not found or hash mismatch
#' @export
get_result <- function(name) {
  result_get(name)
}

#' Alias for backward compatibility
#' @return A data frame of results with their metadata
#' @export
list_results <- function() {
  result_list()
}

#' Alias for backward compatibility
#' @param name Result name
#' @param value The result value to save (will be evaluated if it's an expression)
#' @param type Type of result (e.g. "model", "notebook")
#' @param blind Whether the result should be blinded (encrypted)
#' @param public Whether the result should be public (default: FALSE)
#' @param comment Optional description
#' @param file Optional path to a file to save (e.g. a QMD notebook)
#' @export
save_result <- function(name, value = NULL, type, blind = FALSE, public = FALSE, comment = "", file = NULL) {
  result_save(name, value, type, blind, public, comment, file)
}
