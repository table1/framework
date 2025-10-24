#!/usr/bin/env Rscript
# Test connections to all Docker databases
# Run this script to verify your Docker test infrastructure is working

# Load required packages
required_packages <- c("DBI", "RSQLite", "RPostgres", "RMariaDB", "duckdb")
missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]

if (length(missing_packages) > 0) {
  message("Installing missing packages: ", paste(missing_packages, collapse = ", "))
  install.packages(missing_packages, repos = "https://cloud.r-project.org/")
}

library(DBI)

# Color output helpers
green <- function(x) paste0("\033[32m", x, "\033[0m")
red <- function(x) paste0("\033[31m", x, "\033[0m")
yellow <- function(x) paste0("\033[33m", x, "\033[0m")

test_connection <- function(name, conn_func, query = "SELECT 1 as test") {
  cat(sprintf("Testing %s... ", name))

  result <- tryCatch({
    conn <- conn_func()
    data <- DBI::dbGetQuery(conn, query)
    DBI::dbDisconnect(conn)

    if (nrow(data) > 0) {
      cat(green("✓ OK\n"))
      TRUE
    } else {
      cat(red("✗ FAILED (empty result)\n"))
      FALSE
    }
  }, error = function(e) {
    cat(red(sprintf("✗ FAILED: %s\n", e$message)))
    FALSE
  })

  result
}

cat("\n", yellow("=== Framework Multi-Database Connection Tests ===\n\n"))

results <- list()

# Test PostgreSQL
results$postgres <- test_connection(
  "PostgreSQL",
  function() {
    dbConnect(
      RPostgres::Postgres(),
      host = "localhost",
      port = 5432,
      dbname = "framework_test",
      user = "framework",
      password = "framework_test_pass"
    )
  }
)

# Test MySQL
results$mysql <- test_connection(
  "MySQL",
  function() {
    dbConnect(
      RMariaDB::MariaDB(),
      host = "localhost",
      port = 3306,
      dbname = "framework_test",
      user = "framework",
      password = "framework_test_pass"
    )
  }
)

# Test MariaDB
results$mariadb <- test_connection(
  "MariaDB",
  function() {
    dbConnect(
      RMariaDB::MariaDB(),
      host = "localhost",
      port = 3307,
      dbname = "framework_test",
      user = "framework",
      password = "framework_test_pass"
    )
  }
)

# Test SQLite (file-based)
results$sqlite <- test_connection(
  "SQLite",
  function() {
    tmpfile <- tempfile(fileext = ".db")
    dbConnect(RSQLite::SQLite(), tmpfile)
  }
)

# Test DuckDB (file-based)
results$duckdb <- test_connection(
  "DuckDB",
  function() {
    tmpfile <- tempfile(fileext = ".duckdb")
    dbConnect(duckdb::duckdb(), tmpfile)
  }
)

# Test SQL Server (requires odbc package and ODBC driver installed)
if (requireNamespace("odbc", quietly = TRUE)) {
  results$sqlserver <- test_connection(
    "SQL Server",
    function() {
      dbConnect(
        odbc::odbc(),
        driver = "ODBC Driver 17 for SQL Server",
        server = "localhost,1433",
        database = "framework_test",
        uid = "sa",
        pwd = "Framework_Test_Pass123!",
        TrustServerCertificate = "yes"
      )
    }
  )
} else {
  cat(yellow("SQL Server... ⊘ SKIPPED (odbc package not installed)\n"))
  results$sqlserver <- NA
}

# Summary
cat("\n", yellow("=== Summary ===\n"))
passed <- sum(unlist(results[!is.na(results)]))
total <- length(results[!is.na(results)])
cat(sprintf("Passed: %d/%d\n", passed, total))

if (passed == total) {
  cat(green("\n✓ All database connections working!\n"))
  quit(status = 0)
} else {
  cat(red("\n✗ Some database connections failed\n"))
  quit(status = 1)
}
