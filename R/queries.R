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
