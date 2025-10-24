#' Check if a database driver package is available
#'
#' Internal helper to check if a required database driver package is installed.
#' Throws an informative error if the package is missing.
#'
#' @param driver_name Character. Human-readable name of the database (e.g., "PostgreSQL", "MySQL")
#' @param package_name Character. Name of the R package required (e.g., "RPostgres", "RMariaDB")
#' @param install_command Character. Optional custom install command. Defaults to install.packages()
#'
#' @return NULL (invisible). Throws error if package not available.
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' .require_driver("PostgreSQL", "RPostgres")
#' .require_driver("MySQL", "RMariaDB")
#' }
.require_driver <- function(driver_name, package_name, install_command = NULL) {
  # Validate arguments
  checkmate::assert_string(driver_name, min.chars = 1)
  checkmate::assert_string(package_name, min.chars = 1)
  checkmate::assert_string(install_command, null.ok = TRUE)

  if (!requireNamespace(package_name, quietly = TRUE)) {
    # Default install command
    if (is.null(install_command)) {
      install_command <- sprintf("install.packages('%s')", package_name)
    }

    stop(sprintf(
      "%s connections require the %s package.\n\nInstall with: %s",
      driver_name,
      package_name,
      install_command
    ), call. = FALSE)
  }

  invisible(NULL)
}

#' Get driver information for a given database type
#'
#' Internal helper to map database driver names to their R packages and
#' human-readable names.
#'
#' @param driver Character. Database driver name (e.g., "postgres", "mysql", "sqlite")
#'
#' @return Named list with `package`, `name`, and optionally `install_command`
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' .get_driver_info("postgres")
#' .get_driver_info("mysql")
#' }
.get_driver_info <- function(driver) {
  checkmate::assert_string(driver, min.chars = 1)

  driver_map <- list(
    postgres = list(
      package = "RPostgres",
      name = "PostgreSQL"
    ),
    postgresql = list(
      package = "RPostgres",
      name = "PostgreSQL"
    ),
    mysql = list(
      package = "RMariaDB",
      name = "MySQL"
    ),
    mariadb = list(
      package = "RMariaDB",
      name = "MariaDB"
    ),
    sqlserver = list(
      package = "odbc",
      name = "SQL Server",
      install_command = "install.packages('odbc')\n# Also requires ODBC driver: https://learn.microsoft.com/en-us/sql/connect/odbc/"
    ),
    mssql = list(
      package = "odbc",
      name = "SQL Server",
      install_command = "install.packages('odbc')\n# Also requires ODBC driver: https://learn.microsoft.com/en-us/sql/connect/odbc/"
    ),
    duckdb = list(
      package = "duckdb",
      name = "DuckDB"
    ),
    sqlite = list(
      package = "RSQLite",
      name = "SQLite"
    )
  )

  info <- driver_map[[tolower(driver)]]

  if (is.null(info)) {
    stop(sprintf("Unknown database driver: %s", driver), call. = FALSE)
  }

  info
}

#' Validate driver availability before connection
#'
#' Internal helper that combines driver info lookup and availability check.
#' Used by connection functions to ensure required packages are installed.
#'
#' @param driver Character. Database driver name
#'
#' @return NULL (invisible). Throws error if driver package not available.
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' .validate_driver("postgres")
#' .validate_driver("mysql")
#' }
.validate_driver <- function(driver) {
  checkmate::assert_string(driver, min.chars = 1)

  info <- .get_driver_info(driver)

  # Skip check for RSQLite (always in Imports)
  if (info$package == "RSQLite") {
    return(invisible(NULL))
  }

  .require_driver(
    driver_name = info$name,
    package_name = info$package,
    install_command = info$install_command
  )

  invisible(NULL)
}
