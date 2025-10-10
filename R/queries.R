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

  get_connection(connection_name) |>
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

  get_connection(connection_name) |>
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
#' Finds a single record in a table by its ID.
#' @param conn Database connection
#' @param table_name Name of the table to query
#' @param id The ID to look up
#' @param with_trashed Whether to include soft-deleted records (default: FALSE). Only applies if deleted_at column exists.
#' @return A data frame with the record, or empty if not found
#' @export
db_find <- function(conn, table_name, id, with_trashed = FALSE) {
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

