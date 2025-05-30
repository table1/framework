#' Get data from a database query
#'
#' Gets data from a database using a query and connection name.
#' @param query SQL query to execute
#' @param connection_name Name of the connection in config.yml
#' @param ... Additional arguments passed to DBI::dbGetQuery
#' @return A data frame with the query results
#' @export
get_query <- function(query, connection_name, ...) {
  get_connection(connection_name) |>
    (\(con) {
      on.exit(DBI::dbDisconnect(con))
      DBI::dbGetQuery(con, query, ...)
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
execute_query <- function(query, connection_name, ...) {
  get_connection(connection_name) |>
    (\(con) {
      on.exit(DBI::dbDisconnect(con))
      DBI::dbExecute(con, query, ...)
    })()
}

#' Find a record by ID
#'
#' Finds a single record in a table by its ID.
#' @param conn Database connection
#' @param table_name Name of the table to query
#' @param id The ID to look up
#' @param with_trashed Whether to include soft-deleted records (default: FALSE)
#' @return A data frame with the record, or empty if not found
#' @export
db_find <- function(conn, table_name, id, with_trashed = FALSE) {
  query <- paste0("SELECT * FROM ", table_name, " WHERE id = $1")

  if (!with_trashed) {
    query <- paste0(query, " AND deleted_at IS NULL")
  }

  query <- paste0(query, " LIMIT 1")

  DBI::dbGetQuery(conn, query, params = list(id))
  0
}
