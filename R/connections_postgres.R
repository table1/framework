#' Connect to a PostgreSQL database
#'
#' @param config Connection configuration from config.yml
#' @return A PostgreSQL database connection
#' @keywords internal
.connect_postgres <- function(config) {
  # Check if RPostgres is available
  if (!requireNamespace("RPostgres", quietly = TRUE)) {
    stop(
      "PostgreSQL connections require the RPostgres package.\n",
      "Install with: install.packages('RPostgres')"
    )
  }

  required_fields <- c("host", "port", "database", "user", "password")
  missing_fields <- required_fields[!required_fields %in% names(config)]

  if (length(missing_fields) > 0) {
    stop(sprintf(
      "PostgreSQL configuration missing required fields: %s",
      paste(missing_fields, collapse = ", ")
    ))
  }

  # Clean and convert port to numeric
  port_str <- trimws(as.character(config$port))
  port <- suppressWarnings(as.integer(port_str))

  if (is.na(port) || port < 1 || port > 65535) {
    stop(sprintf("Invalid port number: %s", port_str))
  }

  # Validate host
  if (!grepl("^[a-zA-Z0-9.-]+$", config$host)) {
    stop(sprintf("Invalid host name: %s", config$host))
  }

  # Set default schema if not specified
  schema <- if (!is.null(config$schema)) config$schema else "public"

  tryCatch(
    {
      con <- DBI::dbConnect(
        RPostgres::Postgres(),
        host = config$host,
        port = port,
        dbname = config$database,
        user = config$user,
        password = config$password,
        connect_timeout = 10
      )

      # Set search path to specified schema
      DBI::dbExecute(con, sprintf("SET search_path TO %s", DBI::dbQuoteIdentifier(con, schema)))
      con
    },
    error = \(e) stop(sprintf("Failed to connect to PostgreSQL database: %s", e$message))
  )
}

#' Check if a PostgreSQL database exists
#'
#' @param config Connection configuration from config.yml
#' @return TRUE if database exists, FALSE otherwise
#' @keywords internal
.check_postgres_exists <- function(config) {
  # Connect to postgres database to check if target database exists
  temp_config <- config
  temp_config$database <- "postgres"

  .connect_postgres(temp_config) |>
    (\(con) {
      on.exit(DBI::dbDisconnect(con))
      tryCatch(
        {
          DBI::dbGetQuery(con, sprintf(
            "SELECT 1 FROM pg_database WHERE datname = %s",
            DBI::dbQuoteString(con, config$database)
          )) |>
            nrow() > 0
        },
        error = \(e) {
          message(sprintf("Error checking PostgreSQL database: %s", e$message))
          FALSE
        }
      )
    })()
}

#' Create a new PostgreSQL database
#'
#' @param config Connection configuration from config.yml
#' @return TRUE if successful
#' @keywords internal
.create_postgres_db <- function(config) {
  # Connect to postgres database to create new database
  temp_config <- config
  temp_config$database <- "postgres"

  .connect_postgres(temp_config) |>
    (\(con) {
      on.exit(DBI::dbDisconnect(con))
      tryCatch(
        {
          # Check if database already exists
          if (.check_postgres_exists(config)) {
            return(TRUE)
          }

          # Create database
          DBI::dbExecute(con, sprintf(
            "CREATE DATABASE %s",
            DBI::dbQuoteIdentifier(con, config$database)
          ))
          TRUE
        },
        error = \(e) stop(sprintf("Failed to create PostgreSQL database: %s", e$message))
      )
    })()
}
