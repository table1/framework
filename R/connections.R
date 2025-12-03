#' Get a database connection
#'
#' Gets a database connection based on the connection name in config.yml.
#' For most use cases, prefer `db_query()` or `db_execute()` which handle
#' connection lifecycle automatically.
#'
#' @param name Character. Name of the connection in config.yml (e.g., "postgres")
#' @return A database connection object (DBIConnection)
#'
#' @examples
#' \dontrun{
#' # Preferred: use db_query() which auto-disconnects
#' users <- db_query("SELECT * FROM users", "postgres")
#'
#' # Manual connection management (remember to disconnect!)
#' conn <- db_connect("postgres")
#' DBI::dbListTables(conn)
#' DBI::dbDisconnect(conn)
#' }
#'
#' @export
db_connect <- function(name) {
  # Validate arguments
  checkmate::assert_string(name, min.chars = 1)

  config <- tryCatch(
    config_read(),
    error = function(e) {
      stop(sprintf("Failed to read configuration: %s", e$message))
    }
  )

  if (is.null(config$connections[[name]])) {
    stop(sprintf("No connection configuration found for '%s'", name))
  }

  conn_config <- config$connections[[name]]

  # Validate driver
  if (is.null(conn_config$driver)) {
    stop(sprintf("No driver specified for connection '%s'", name))
  }

  # Return connection
  tryCatch(
    switch(conn_config$driver,
      postgres = .connect_postgres(conn_config),
      postgresql = .connect_postgres(conn_config),
      mysql = .connect_mysql(conn_config),
      mariadb = .connect_mysql(conn_config),
      sqlserver = .connect_sqlserver(conn_config),
      mssql = .connect_sqlserver(conn_config),
      duckdb = .connect_duckdb(conn_config),
      sqlite = .connect_sqlite(conn_config),
      stop(sprintf("Unsupported database driver for '%s': %s", name, conn_config$driver))
    ),
    error = function(e) {
      stop(sprintf("Failed to connect to '%s': %s", name, e$message))
    }
  )
}




#' List all database connections from configuration
#'
#' Lists all database connections defined in the configuration, showing the
#' connection name, driver, host, and database name (if applicable).
#'
#' @return Invisibly returns NULL after printing connection list
#' @export
#'
#' @examples
#' \dontrun{
#' # List all connections
#' db_list()
#' }
db_list <- function() {
  config <- config_read()

  if (is.null(config$connections) || length(config$connections) == 0) {
    message("No database connections found in configuration")
    return(invisible(NULL))
  }

  # Print formatted output
  message(sprintf("\n%d %s found:\n",
                  length(config$connections),
                  if (length(config$connections) == 1) "connection" else "connections"))

  for (name in names(config$connections)) {
    conn <- config$connections[[name]]

    # Connection name with driver badge
    driver <- if (!is.null(conn$driver)) toupper(conn$driver) else "UNKNOWN"
    message(sprintf("• %s [%s]", name, driver))

    # Host (if available)
    if (!is.null(conn$host)) {
      port_info <- if (!is.null(conn$port)) sprintf(":%s", conn$port) else ""
      message(sprintf("  Host: %s%s", conn$host, port_info))
    }

    # Database (if available)
    if (!is.null(conn$database) || !is.null(conn$dbname)) {
      db <- conn$database %||% conn$dbname
      message(sprintf("  Database: %s", db))
    }

    # File path (for file-based databases like SQLite, DuckDB)
    if (!is.null(conn$path)) {
      message(sprintf("  Path: %s", conn$path))
    }

    # Pool info (if enabled)
    if (isTRUE(conn$pool)) {
      message("  Connection pooling: enabled")
    }

    message("")  # Blank line between connections
  }

  invisible(NULL)
}

