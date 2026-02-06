#' Connect to a MySQL or MariaDB database
#'
#' @param config Connection configuration from settings.yml
#' @return A MySQL/MariaDB database connection
#' @keywords internal
.connect_mysql <- function(config) {
  # Check if RMariaDB is available
  .require_driver("MySQL/MariaDB", "RMariaDB")

  required_fields <- c("host", "port", "database", "user", "password")
  missing_fields <- required_fields[!required_fields %in% names(config)]

  if (length(missing_fields) > 0) {
    stop(sprintf(
      "MySQL/MariaDB configuration missing required fields: %s",
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

  tryCatch(
    {
      DBI::dbConnect(
        RMariaDB::MariaDB(),
        host = config$host,
        port = port,
        dbname = config$database,
        user = config$user,
        password = config$password,
        timeout = 10
      )
    },
    error = \(e) stop(sprintf("Failed to connect to MySQL/MariaDB database: %s", e$message))
  )
}

#' Check if a MySQL/MariaDB database exists
#'
#' @param config Connection configuration from settings.yml
#' @return TRUE if database exists, FALSE otherwise
#' @keywords internal
.check_mysql_exists <- function(config) {
  # Connect to information_schema to check if target database exists
  temp_config <- config
  temp_config$database <- "information_schema"

  .connect_mysql(temp_config) |>
    (\(con) {
      on.exit(DBI::dbDisconnect(con))
      tryCatch(
        {
          DBI::dbGetQuery(con, sprintf(
            "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = %s",
            DBI::dbQuoteString(con, config$database)
          )) |>
            nrow() > 0
        },
        error = \(e) {
          message(sprintf("Error checking MySQL/MariaDB database: %s", e$message))
          FALSE
        }
      )
    })()
}

#' Create a new MySQL/MariaDB database
#'
#' @param config Connection configuration from settings.yml
#' @return TRUE if successful
#' @keywords internal
.create_mysql_db <- function(config) {
  # Connect to information_schema to create new database
  temp_config <- config
  temp_config$database <- "information_schema"

  .connect_mysql(temp_config) |>
    (\(con) {
      on.exit(DBI::dbDisconnect(con))
      tryCatch(
        {
          # Check if database already exists
          if (.check_mysql_exists(config)) {
            return(TRUE)
          }

          # Create database with UTF-8 encoding
          DBI::dbExecute(con, sprintf(
            "CREATE DATABASE %s CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci",
            DBI::dbQuoteIdentifier(con, config$database)
          ))
          TRUE
        },
        error = \(e) stop(sprintf("Failed to create MySQL/MariaDB database: %s", e$message))
      )
    })()
}
