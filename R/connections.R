#' Get a database connection from config
#'
#' Gets a database connection based on the connection name in config.yml.
#' If the connection is configured with `pool: true`, returns a connection pool
#' instead of a single connection. Pools are automatically managed and reused.
#'
#' @param name Character. Name of the connection in config.yml (e.g., "postgres")
#' @return A database connection object (DBIConnection) or pool object
#'
#' @examples
#' \dontrun{
#' # Regular connection (pool: false or not specified)
#' conn <- connection_get("postgres")
#' DBI::dbListTables(conn)
#' DBI::dbDisconnect(conn)  # Must disconnect
#'
#' # Pooled connection (pool: true in config.yml)
#' conn <- connection_get("postgres")
#' DBI::dbListTables(conn)
#' # No need to disconnect - pool handles it
#' }
#'
#' @export
connection_get <- function(name) {
  # Validate arguments
  checkmate::assert_string(name, min.chars = 1)

  config <- tryCatch(
    read_config(),
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

  # Check if pooling is enabled for this connection
  use_pool <- isTRUE(conn_config$pool)

  if (use_pool) {
    # Check if pool package is available
    if (!requireNamespace("pool", quietly = TRUE)) {
      warning(
        sprintf("Connection '%s' configured with pool: true, but 'pool' package not installed.\n", name),
        "Falling back to regular connection.\n",
        "Install with: install.packages('pool')",
        call. = FALSE
      )
      use_pool <- FALSE
    }
  }

  if (use_pool) {
    # Return connection pool
    connection_pool(
      name,
      min_size = conn_config$pool_min_size %||% 1,
      max_size = conn_config$pool_max_size %||% Inf,
      idle_timeout = conn_config$pool_idle_timeout %||% 60,
      validation_interval = conn_config$pool_validation_interval %||% 60
    )
  } else {
    # Return regular connection
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
}


#' @title (Deprecated) Use connection_get() instead
#' @description `r lifecycle::badge("deprecated")`
#'
#' `get_connection()` was renamed to `connection_get()` to follow the package's
#' noun_verb naming convention for better discoverability and consistency.
#'
#' @inheritParams connection_get
#' @return A database connection object
#' @export
get_connection <- function(name) {
  .Deprecated("connection_get", package = "framework",
              msg = "get_connection() is deprecated. Use connection_get() instead.")
  connection_get(name)
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
#' connections_list()
#' }
connections_list <- function() {
  config <- read_config()

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
