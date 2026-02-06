#' Connect to a SQL Server database
#'
#' @param config Connection configuration from settings.yml
#' @return A SQL Server database connection via ODBC
#' @keywords internal
.connect_sqlserver <- function(config) {
  # Check if odbc is available
  .require_driver(
    "SQL Server",
    "odbc",
    "install.packages('odbc')\n# Also requires ODBC Driver 17 for SQL Server: https://learn.microsoft.com/en-us/sql/connect/odbc/"
  )

  required_fields <- c("host", "database", "user", "password")
  missing_fields <- required_fields[!required_fields %in% names(config)]

  if (length(missing_fields) > 0) {
    stop(sprintf(
      "SQL Server configuration missing required fields: %s",
      paste(missing_fields, collapse = ", ")
    ))
  }

  # Default port is 1433
  port <- if (!is.null(config$port)) {
    port_str <- trimws(as.character(config$port))
    port_val <- suppressWarnings(as.integer(port_str))

    if (is.na(port_val) || port_val < 1 || port_val > 65535) {
      stop(sprintf("Invalid port number: %s", port_str))
    }
    port_val
  } else {
    1433
  }

  # Validate host
  if (!grepl("^[a-zA-Z0-9.-]+$", config$host)) {
    stop(sprintf("Invalid host name: %s", config$host))
  }

  # Construct server string (SQL Server uses "host,port" format)
  server <- if (port == 1433) {
    config$host
  } else {
    sprintf("%s,%d", config$host, port)
  }

  # Determine ODBC driver
  driver <- if (!is.null(config$odbc_driver)) {
    config$odbc_driver
  } else {
    "ODBC Driver 17 for SQL Server"
  }

  tryCatch(
    {
      DBI::dbConnect(
        odbc::odbc(),
        driver = driver,
        server = server,
        database = config$database,
        uid = config$user,
        pwd = config$password,
        TrustServerCertificate = "yes",  # For local development
        timeout = 10
      )
    },
    error = \(e) {
      # Provide helpful error messages for common issues
      error_msg <- e$message

      if (grepl("IM002|Data source name not found", error_msg, ignore.case = TRUE)) {
        stop(sprintf(
          "ODBC driver '%s' not found.\n\nInstall SQL Server ODBC driver:\n  - macOS: brew install microsoft/mssql-release/msodbcsql17\n  - Ubuntu: https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server\n  - Windows: https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server",
          driver
        ), call. = FALSE)
      }

      stop(sprintf("Failed to connect to SQL Server database: %s", error_msg), call. = FALSE)
    }
  )
}

#' Check if a SQL Server database exists
#'
#' @param config Connection configuration from settings.yml
#' @return TRUE if database exists, FALSE otherwise
#' @keywords internal
.check_sqlserver_exists <- function(config) {
  # Connect to master database to check if target database exists
  temp_config <- config
  temp_config$database <- "master"

  .connect_sqlserver(temp_config) |>
    (\(con) {
      on.exit(DBI::dbDisconnect(con))
      tryCatch(
        {
          DBI::dbGetQuery(con, sprintf(
            "SELECT name FROM sys.databases WHERE name = %s",
            DBI::dbQuoteString(con, config$database)
          )) |>
            nrow() > 0
        },
        error = \(e) {
          message(sprintf("Error checking SQL Server database: %s", e$message))
          FALSE
        }
      )
    })()
}

#' Create a new SQL Server database
#'
#' @param config Connection configuration from settings.yml
#' @return TRUE if successful
#' @keywords internal
.create_sqlserver_db <- function(config) {
  # Connect to master database to create new database
  temp_config <- config
  temp_config$database <- "master"

  .connect_sqlserver(temp_config) |>
    (\(con) {
      on.exit(DBI::dbDisconnect(con))
      tryCatch(
        {
          # Check if database already exists
          if (.check_sqlserver_exists(config)) {
            return(TRUE)
          }

          # Create database
          # Note: SQL Server doesn't support parameterized database names in CREATE DATABASE
          db_name_clean <- gsub("[^a-zA-Z0-9_]", "", config$database)
          DBI::dbExecute(con, sprintf(
            "CREATE DATABASE [%s]",
            db_name_clean
          ))
          TRUE
        },
        error = \(e) stop(sprintf("Failed to create SQL Server database: %s", e$message))
      )
    })()
}
