# Multi-database connection tests
# Tests connection_get() and driver-specific connection functions

test_that("SQLite connections work", {
  skip_if_no_driver("RSQLite", "SQLite")

  # Create temp database
  db_path <- tempfile(fileext = ".db")

  # Create connection config
  config <- list(
    driver = "sqlite",
    database = db_path
  )

  # Test connection
  conn <- .connect_sqlite(config)
  expect_s4_class(conn, "SQLiteConnection")

  # Test basic query
  result <- DBI::dbGetQuery(conn, "SELECT 1 as test")
  expect_equal(result$test, 1)

  DBI::dbDisconnect(conn)
  unlink(db_path)
})

test_that("PostgreSQL connections work if available", {
  skip_if_no_driver("RPostgres", "PostgreSQL")

  config <- list(
    driver = "postgres",
    host = Sys.getenv("TEST_POSTGRES_HOST", "localhost"),
    port = 5432,
    database = "framework_test",
    user = "framework",
    password = "framework_test_pass"
  )

  conn <- tryCatch(
    .connect_postgres(config),
    error = function(e) NULL
  )

  if (is.null(conn)) {
    skip("PostgreSQL server not available (Docker not running?)")
  }

  expect_s4_class(conn, "PqConnection")

  # Test basic query
  result <- DBI::dbGetQuery(conn, "SELECT 1 as test")
  expect_equal(result$test, 1)

  # Test that users table exists
  tables <- DBI::dbListTables(conn)
  expect_true("users" %in% tables)

  DBI::dbDisconnect(conn)
})

test_that("MySQL connections work if available", {
  skip_if_no_driver("RMariaDB", "MySQL")

  config <- list(
    driver = "mysql",
    host = Sys.getenv("TEST_MYSQL_HOST", "localhost"),
    port = 3306,
    database = "framework_test",
    user = "framework",
    password = "framework_test_pass"
  )

  conn <- tryCatch(
    .connect_mysql(config),
    error = function(e) NULL
  )

  if (is.null(conn)) {
    skip("MySQL server not available (Docker not running?)")
  }

  expect_s4_class(conn, "MariaDBConnection")

  # Test basic query
  result <- DBI::dbGetQuery(conn, "SELECT 1 as test")
  expect_equal(result$test, 1)

  # Test that users table exists
  tables <- DBI::dbListTables(conn)
  expect_true("users" %in% tables)

  DBI::dbDisconnect(conn)
})

test_that("DuckDB connections work if available", {
  skip_if_no_driver("duckdb", "DuckDB")

  db_path <- tempfile(fileext = ".duckdb")

  config <- list(
    driver = "duckdb",
    database = db_path
  )

  conn <- .connect_duckdb(config)
  expect_s4_class(conn, "duckdb_connection")

  # Test basic query
  result <- DBI::dbGetQuery(conn, "SELECT 1 as test")
  expect_equal(result$test, 1)

  DBI::dbDisconnect(conn, shutdown = TRUE)
  unlink(db_path)
})

test_that("Driver validation catches missing packages", {
  # Test with a driver that doesn't exist
  expect_error(
    .require_driver("FakeDB", "NonExistentPackage"),
    "FakeDB connections require the NonExistentPackage package"
  )
})

test_that("Get driver info returns correct information", {
  # PostgreSQL
  info <- .get_driver_info("postgres")
  expect_equal(info$package, "RPostgres")
  expect_equal(info$name, "PostgreSQL")

  # MySQL
  info <- .get_driver_info("mysql")
  expect_equal(info$package, "RMariaDB")
  expect_equal(info$name, "MySQL")

  # DuckDB
  info <- .get_driver_info("duckdb")
  expect_equal(info$package, "duckdb")
  expect_equal(info$name, "DuckDB")

  # Unknown driver
  expect_error(
    .get_driver_info("unknown"),
    "Unknown database driver"
  )
})

test_that("Connection aliases work", {
  # Test that postgresql resolves to postgres
  info <- .get_driver_info("postgresql")
  expect_equal(info$package, "RPostgres")

  # Test that mariadb resolves to mysql driver
  info <- .get_driver_info("mariadb")
  expect_equal(info$package, "RMariaDB")

  # Test that mssql resolves to sqlserver
  info <- .get_driver_info("mssql")
  expect_equal(info$package, "odbc")
})
