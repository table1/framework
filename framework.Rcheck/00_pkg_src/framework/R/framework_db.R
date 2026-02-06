#' Create the template SQLite database
#' @keywords internal
.create_template_db <- function(delete_existing = FALSE) {
  db_path <- "inst/templates/framework.db"

  # Validate we're in package root
  if (!file.exists("inst/templates")) {
    stop("This function must be run from the package root directory")
  }

  if (delete_existing && file.exists(db_path)) {
    tryCatch(
      file.remove(db_path),
      error = function(e) {
        stop(sprintf("Failed to remove existing database: %s", e$message))
      }
    )
  }

  # Read SQL from init.sql for consistency
  sql_file <- "inst/templates/init.sql"
  if (!file.exists(sql_file)) {
    stop(sprintf("SQL initialization file not found: %s", sql_file))
  }

  sql_content <- tryCatch(
    readLines(sql_file, warn = FALSE),
    error = function(e) {
      stop(sprintf("Failed to read SQL file '%s': %s", sql_file, e$message))
    }
  )

  # Create new database
  con <- tryCatch(
    DBI::dbConnect(RSQLite::SQLite(), db_path),
    error = function(e) {
      stop(sprintf("Failed to create database connection: %s", e$message))
    }
  )
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  # Execute the SQL content
  # Split by semicolons and execute each statement
  sql_statements <- paste(sql_content, collapse = "\n")
  sql_statements <- strsplit(sql_statements, ";")[[1]]

  for (stmt in sql_statements) {
    stmt <- trimws(stmt)
    if (nchar(stmt) > 0) {
      tryCatch(
        DBI::dbExecute(con, stmt),
        error = function(e) {
          stop(sprintf("Failed to execute SQL statement: %s\nError: %s", stmt, e$message))
        }
      )
    }
  }

  message(sprintf("Template database created successfully: %s", db_path))
  invisible(NULL)
}

#' Initialize the framework database
#' @keywords internal
.init_db <- function() {
  # Use project root to find framework.db (consistent with .ensure_framework_db)
  project_root <- tryCatch(.find_project_root(getwd()), error = function(e) NULL)
  db_path <- if (!is.null(project_root)) {
    file.path(project_root, "framework.db")
  } else {
    "framework.db"
  }

  if (!file.exists(db_path)) {
    # Copy template database
    template_db <- system.file("templates", "framework.db", package = "framework")
    if (nzchar(template_db) && file.exists(template_db)) {
      file.copy(template_db, db_path)
    }
  }
}

#' Get a connection to the framework database
#' @param project_root Optional project root used to resolve the database path.
#' @keywords internal
.get_db_connection <- function(project_root = NULL) {
  if (is.null(project_root)) {
    # Use project root to find framework.db (consistent with .ensure_framework_db)
    project_root <- tryCatch(.find_project_root(getwd()), error = function(e) NULL)
  }
  db_path <- if (!is.null(project_root)) {
    file.path(project_root, "framework.db")
  } else {
    "framework.db"
  }

  DBI::dbConnect(RSQLite::SQLite(), db_path)
}

#' Set a metadata value
#' @param key The metadata key
#' @param value The metadata value
#' @param project_root Optional project root for database resolution
#' @keywords internal
.set_metadata <- function(key, value, project_root = NULL) {
  con <- .get_db_connection(project_root)
  on.exit(DBI::dbDisconnect(con))
  now <- lubridate::now()

  # Check if key exists
  key_exists <- DBI::dbGetQuery(con, "SELECT 1 FROM meta WHERE key = ?", list(key))

  if (nrow(key_exists) > 0) {
    # Update existing value
    DBI::dbExecute(
      con,
      "UPDATE meta SET value = ?, updated_at = ? WHERE key = ?",
      list(value, now, key)
    )
  } else {
    # Insert new value
    DBI::dbExecute(
      con,
      "INSERT INTO meta (key, value, created_at, updated_at) VALUES (?, ?, ?, ?)",
      list(key, value, now, now)
    )
  }
}

#' Get a metadata value
#' @param key The metadata key
#' @param project_root Optional project root for database resolution
#' @return The metadata value, or NULL if not found
#' @keywords internal
.get_metadata <- function(key, project_root = NULL) {
  con <- .get_db_connection(project_root)
  on.exit(DBI::dbDisconnect(con))
  result <- DBI::dbGetQuery(
    con,
    "SELECT value FROM meta WHERE key = ?",
    list(key)
  )

  if (nrow(result) == 0) {
    return(NULL)
  }
  result$value
}

#' List all metadata
#' @return A data frame of metadata with keys, values, and timestamps
#' @keywords internal
list_metadata <- function() {
  con <- tryCatch(
    .get_db_connection(),
    error = function(e) {
      stop(sprintf("Failed to connect to database: %s", e$message))
    }
  )
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  result <- tryCatch(
    DBI::dbGetQuery(con, "SELECT key, value, created_at, updated_at FROM meta"),
    error = function(e) {
      stop(sprintf("Failed to query metadata: %s", e$message))
    }
  )

  # Convert timestamps to POSIXct
  if (nrow(result) > 0) {
    result$created_at <- lubridate::as_datetime(result$created_at)
    result$updated_at <- lubridate::as_datetime(result$updated_at)
  }

  result
}

#' Remove a metadata value
#' @param key The metadata key to remove
#' @param project_root Optional project root for database resolution
#' @keywords internal
.remove_metadata <- function(key, project_root = NULL) {
  con <- .get_db_connection(project_root)
  on.exit(DBI::dbDisconnect(con))
  DBI::dbExecute(con, "DELETE FROM meta WHERE key = ?", list(key))
}
