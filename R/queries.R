#' Get data from a database query
#'
#' Gets data from a database using a query and connection name.
#' @param query SQL query to execute
#' @param connection_name Name of the connection in config.yml
#' @param ... Additional arguments passed to DBI::dbGetQuery
#' @return A data frame with the query results
#' @export
query_get <- function(query, connection_name, ...) {
  # Validate arguments
  checkmate::assert_string(query, min.chars = 1)
  checkmate::assert_string(connection_name, min.chars = 1)

  connection_get(connection_name) |>
    (\(con) {
      on.exit(DBI::dbDisconnect(con))
      tryCatch(
        DBI::dbGetQuery(con, query, ...),
        error = function(e) {
          stop(sprintf("Failed to execute query on connection '%s': %s", connection_name, e$message))
        }
      )
    })()
}

#' Execute a database query
#'
#' Executes a query on a database without returning results.
#' @param query SQL query to execute
#' @param connection_name Name of the connection in config.yml
#' @param ... Additional arguments passed to DBI::dbExecute
#' @return Number of rows affected
#' @export
query_execute <- function(query, connection_name, ...) {
  # Validate arguments
  checkmate::assert_string(query, min.chars = 1)
  checkmate::assert_string(connection_name, min.chars = 1)

  connection_get(connection_name) |>
    (\(con) {
      on.exit(DBI::dbDisconnect(con))
      tryCatch(
        DBI::dbExecute(con, query, ...),
        error = function(e) {
          stop(sprintf("Failed to execute query on connection '%s': %s", connection_name, e$message))
        }
      )
    })()
}

#' Find a record by ID
#'
#' Finds a single record in a table by its ID. Supports soft-delete patterns
#' where records have a deleted_at column.
#'
#' @param conn Database connection
#' @param table_name Name of the table to query
#' @param id The ID to look up (integer or string)
#' @param with_trashed Whether to include soft-deleted records (default: FALSE).
#'   Only applies if deleted_at column exists in the table.
#'
#' @return A data frame with the record, or empty data frame if not found
#'
#' @examples
#' \dontrun{
#' conn <- connection_get("postgres")
#' user <- connection_find(conn, "users", 42)
#' DBI::dbDisconnect(conn)
#' }
#'
#' @export
connection_find <- function(conn, table_name, id, with_trashed = FALSE) {
  # Validate arguments
  checkmate::assert_class(conn, "DBIConnection")
  checkmate::assert_string(table_name, min.chars = 1)
  checkmate::assert(
    checkmate::check_integerish(id, len = 1),
    checkmate::check_string(id)
  )
  checkmate::assert_flag(with_trashed)

  # Check if deleted_at column exists in the table
  has_deleted_at <- tryCatch({
    table_info <- DBI::dbGetQuery(conn, sprintf("PRAGMA table_info(%s)", table_name))
    "deleted_at" %in% table_info$name
  }, error = function(e) {
    # If we can't check (e.g., not SQLite), assume it doesn't exist
    FALSE
  })

  # Build query
  query <- sprintf("SELECT * FROM %s WHERE id = ?", table_name)

  if (!with_trashed && has_deleted_at) {
    query <- paste0(query, " AND deleted_at IS NULL")
  }

  query <- paste0(query, " LIMIT 1")

  # Execute query
  tryCatch(
    DBI::dbGetQuery(conn, query, params = list(id)),
    error = function(e) {
      stop(sprintf("Failed to query table '%s': %s", table_name, e$message))
    }
  )
}


#' @title (Deprecated) Use connection_find() instead
#' @description `r lifecycle::badge("deprecated")`
#'
#' `db_find()` was renamed to `connection_find()` to follow the package's
#' noun_verb naming convention for better discoverability and consistency.
#'
#' @inheritParams connection_find
#' @return A data frame with the record
#' @export
db_find <- function(conn, table_name, id, with_trashed = FALSE) {
  .Deprecated("connection_find", package = "framework",
              msg = "db_find() is deprecated. Use connection_find() instead.")
  connection_find(conn, table_name, id, with_trashed)
}

