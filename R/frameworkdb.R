#' Create the template SQLite database
#' @keywords internal
.create_template_db <- function() {
  # Create new database
  con <- DBI::dbConnect(RSQLite::SQLite(), "inst/templates/framework.fr.db")
  

  # Create data table
  DBI::dbExecute(con, "
    CREATE TABLE data (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE,
      encrypted BOOLEAN,
      hash TEXT,
      last_read_at DATETIME,
      created_at DATETIME,
      updated_at DATETIME,
      deleted_at DATETIME
    )
  ")

  # Create cache table
  DBI::dbExecute(con, "
    CREATE TABLE cache (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE,
      result TEXT,
      hash TEXT,
      last_read_at DATETIME,
      created_at DATETIME,
      updated_at DATETIME,
      deleted_at DATETIME
    )
  ")

  # Create meta table
  DBI::dbExecute(con, "
    CREATE TABLE meta (
      key TEXT PRIMARY KEY,
      value TEXT,
      created_at DATETIME,
      updated_at DATETIME
    )
  ")

  # Create results table
  DBI::dbExecute(con, "
    CREATE TABLE results (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE,
      type TEXT,
      public BOOLEAN,
      blind BOOLEAN,
      comment TEXT,
      hash TEXT,
      last_read_at DATETIME,
      created_at DATETIME,
      updated_at DATETIME,
      deleted_at DATETIME
    )
  ")

  DBI::dbDisconnect(con)
}

#' Initialize the framework database
#' @keywords internal
.init_db <- function() {
  db_path <- "framework.db"
  if (!file.exists(db_path)) {
    # Copy template database
    file.copy("inst/templates/framework.fr.db", db_path)
  }
}

#' Get a connection to the framework database
#' @keywords internal
.get_db_connection <- function() {
  DBI::dbConnect(RSQLite::SQLite(), "framework.db")
}

#' Set a metadata value
#' @param key The metadata key
#' @param value The metadata value
#' @keywords internal
.set_metadata <- function(key, value) {
  con <- .get_db_connection()
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

  DBI::dbDisconnect(con)
}

#' Get a metadata value
#' @param key The metadata key
#' @return The metadata value, or NULL if not found
#' @keywords internal
.get_metadata <- function(key) {
  con <- .get_db_connection()
  result <- DBI::dbGetQuery(
    con,
    "SELECT value FROM meta WHERE key = ?",
    list(key)
  )
  DBI::dbDisconnect(con)

  if (nrow(result) == 0) {
    return(NULL)
  }
  result$value
}

#' List all metadata keys
#' @return A character vector of metadata keys
#' @export
list_metadata <- function() {
  con <- .get_db_connection()
  result <- DBI::dbGetQuery(con, "SELECT key FROM meta")
  DBI::dbDisconnect(con)
  result$key
}

#' Remove a metadata value
#' @param key The metadata key to remove
#' @keywords internal
.remove_metadata <- function(key) {
  con <- .get_db_connection()
  DBI::dbExecute(con, "DELETE FROM meta WHERE key = ?", list(key))
  DBI::dbDisconnect(con)
}
