#' Get a database connection from config
#'
#' Gets a database connection based on the connection name in config.yml.
#' @param name Name of the connection in config.yml (e.g. "postgres")
#' @return A database connection object
#' @export
get_connection <- function(name) {
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

  tryCatch(
    switch(conn_config$driver,
      postgres = .connect_postgres(conn_config),
      postgresql = .connect_postgres(conn_config),
      sqlite = .connect_sqlite(conn_config),
      stop(sprintf("Unsupported database driver for '%s': %s", name, conn_config$driver))
    ),
    error = function(e) {
      stop(sprintf("Failed to connect to '%s': %s", name, e$message))
    }
  )
}
