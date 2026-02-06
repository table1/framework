#' Connect to a SQLite database
#'
#' @param config Connection configuration from settings.yml
#' @return A SQLite database connection
#' @keywords internal
.connect_sqlite <- function(config) {
  if (is.null(config$database)) {
    stop("SQLite configuration must include 'database' path")
  }

  # Validate database path
  db_path <- normalizePath(config$database, mustWork = FALSE)
  db_dir <- dirname(db_path)

  if (!dir.exists(db_dir)) {
    stop(sprintf("Database directory does not exist: %s", db_dir))
  }

  # Check file permissions
  if (file.exists(db_path) && file.access(db_path, 2) != 0) {
    stop(sprintf("No write permission for database: %s", db_path))
  }

  tryCatch(
    {
      DBI::dbConnect(RSQLite::SQLite(), db_path)
    },
    error = \(e) stop(sprintf("Failed to connect to SQLite database: %s", e$message))
  )
}

#' Check if a SQLite database exists
#'
#' @param config Connection configuration from settings.yml
#' @return TRUE if database exists, FALSE otherwise
#' @keywords internal
.check_sqlite_exists <- function(config) {
  if (is.null(config$database)) {
    return(FALSE)
  }

  normalizePath(config$database, mustWork = FALSE) |>
    file.exists()
}

#' Create a new SQLite database
#'
#' @param config Connection configuration from settings.yml
#' @return TRUE if successful
#' @keywords internal
.create_sqlite_db <- function(config) {
  if (is.null(config$database)) {
    stop("SQLite configuration must include 'database' path")
  }

  db_path <- normalizePath(config$database, mustWork = FALSE)
  db_dir <- dirname(db_path)

  # Create directory if it doesn't exist
  if (!dir.exists(db_dir)) {
    dir.create(db_dir, recursive = TRUE)
  }

  # Check if we can create the file
  if (file.exists(db_path) && file.access(db_path, 2) != 0) {
    stop(sprintf("No write permission for database: %s", db_path))
  }

  tryCatch(
    {
      DBI::dbConnect(RSQLite::SQLite(), db_path) |>
        (\(con) {
          DBI::dbDisconnect(con)
          TRUE
        })()
    },
    error = \(e) stop(sprintf("Failed to create SQLite database: %s", e$message))
  )
}
