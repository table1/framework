#' Get data from a database query
#'
#' Gets data from a database using a query and connection name. The connection
#' is created, used, and automatically closed. For better performance with
#' multiple queries, enable connection pooling via `pool: true` in your
#' connection configuration.
#'
#' @param query SQL query to execute
#' @param connection_name Name of the connection in config.yml
#' @param ... Additional arguments passed to DBI::dbGetQuery
#' @return A data frame with the query results
#'
#' @examples
#' \dontrun{
#' # Default: creates new connection, auto-disconnects
#' users <- query_get("SELECT * FROM users", "my_db")
#'
#' # To use pooling, configure in config.yml:
#' # connections:
#' #   my_db:
#' #     driver: postgres
#' #     pool: true
#' }
#'
#' @export
query_get <- function(query, connection_name, ...) {
  # Validate arguments
  checkmate::assert_string(query, min.chars = 1)
  checkmate::assert_string(connection_name, min.chars = 1)

  connection_get(connection_name) |>
    (\(con) {
      # Only disconnect non-pool connections
      # Pools manage their own connection lifecycle
      if (!inherits(con, "Pool")) {
        on.exit(DBI::dbDisconnect(con))
      }

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
#' Executes a query on a database without returning results. The connection
#' is created, used, and automatically closed. For better performance with
#' multiple queries, enable connection pooling via `pool: true` in your
#' connection configuration.
#'
#' @param query SQL query to execute
#' @param connection_name Name of the connection in config.yml
#' @param ... Additional arguments passed to DBI::dbExecute
#' @return Number of rows affected
#'
#' @examples
#' \dontrun{
#' # Default: creates new connection, auto-disconnects
#' rows <- query_execute("DELETE FROM cache WHERE expired = TRUE", "my_db")
#'
#' # To use pooling, configure in config.yml:
#' # connections:
#' #   my_db:
#' #     driver: postgres
#' #     pool: true
#' }
#'
#' @export
query_execute <- function(query, connection_name, ...) {
  # Validate arguments
  checkmate::assert_string(query, min.chars = 1)
  checkmate::assert_string(connection_name, min.chars = 1)

  connection_get(connection_name) |>
    (\(con) {
      # Only disconnect non-pool connections
      # Pools manage their own connection lifecycle
      if (!inherits(con, "Pool")) {
        on.exit(DBI::dbDisconnect(con))
      }

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

  # Check if deleted_at column exists in the table (cross-database)
  has_deleted_at <- .has_column(conn, table_name, "deleted_at")

  # Build query with appropriate parameter placeholder
  # PostgreSQL uses $1, most others use ?
  placeholder <- if (inherits(conn, "PqConnection")) "$1" else "?"

  query <- sprintf("SELECT * FROM %s WHERE id = %s",
                   DBI::dbQuoteIdentifier(conn, table_name),
                   placeholder)

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

