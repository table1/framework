# Multi-database schema introspection tests
# Tests .has_column(), .list_tables(), .list_columns() across databases

test_that(".has_column() works on SQLite", {
  skip_if_no_driver("RSQLite", "SQLite")

  db_path <- tempfile(fileext = ".db")
  conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit({
    DBI::dbDisconnect(conn)
    unlink(db_path)
  })

  # Create test table
  create_test_table(conn, "test_table", with_soft_delete = TRUE)

  # Test column exists
  expect_true(.has_column(conn, "test_table", "name"))
  expect_true(.has_column(conn, "test_table", "email"))
  expect_true(.has_column(conn, "test_table", "deleted_at"))

  # Test column doesn't exist
  expect_false(.has_column(conn, "test_table", "nonexistent"))
})

test_that(".has_column() works on PostgreSQL if available", {
  skip_if_no_driver("RPostgres", "PostgreSQL")

  config <- list(
    driver = "postgres",
    host = Sys.getenv("TEST_POSTGRES_HOST", "localhost"),
    port = 5432,
    database = "framework_test",
    user = "framework",
    password = "framework_test_pass"
  )

  conn <- tryCatch(.connect_postgres(config), error = function(e) NULL)
  if (is.null(conn)) skip("PostgreSQL not available")
  on.exit(DBI::dbDisconnect(conn))

  # Test on pre-existing users table
  expect_true(.has_column(conn, "users", "email"))
  expect_true(.has_column(conn, "users", "name"))
  expect_true(.has_column(conn, "users", "deleted_at"))
  expect_false(.has_column(conn, "users", "nonexistent"))
})

test_that(".has_column() works on MySQL if available", {
  skip_if_no_driver("RMariaDB", "MySQL")

  config <- list(
    driver = "mysql",
    host = Sys.getenv("TEST_MYSQL_HOST", "localhost"),
    port = 3306,
    database = "framework_test",
    user = "framework",
    password = "framework_test_pass"
  )

  conn <- tryCatch(.connect_mysql(config), error = function(e) NULL)
  if (is.null(conn)) skip("MySQL not available")
  on.exit(DBI::dbDisconnect(conn))

  # Test on pre-existing users table
  expect_true(.has_column(conn, "users", "email"))
  expect_true(.has_column(conn, "users", "name"))
  expect_true(.has_column(conn, "users", "deleted_at"))
  expect_false(.has_column(conn, "users", "nonexistent"))
})

test_that(".has_column() works on DuckDB if available", {
  skip_if_no_driver("duckdb", "DuckDB")

  db_path <- tempfile(fileext = ".duckdb")
  conn <- DBI::dbConnect(duckdb::duckdb(), db_path)
  on.exit({
    DBI::dbDisconnect(conn, shutdown = TRUE)
    unlink(db_path)
  })

  # Create test table
  create_test_table(conn, "test_table", with_soft_delete = TRUE)

  # Test column exists
  expect_true(.has_column(conn, "test_table", "name"))
  expect_true(.has_column(conn, "test_table", "email"))
  expect_true(.has_column(conn, "test_table", "deleted_at"))

  # Test column doesn't exist
  expect_false(.has_column(conn, "test_table", "nonexistent"))
})

test_that(".list_columns() works across databases", {
  skip_if_no_driver("RSQLite", "SQLite")

  db_path <- tempfile(fileext = ".db")
  conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit({
    DBI::dbDisconnect(conn)
    unlink(db_path)
  })

  # Create test table
  create_test_table(conn, "test_table", with_soft_delete = TRUE)

  # Get columns
  columns <- .list_columns(conn, "test_table")

  # Check expected columns exist
  expect_true("name" %in% columns)
  expect_true("email" %in% columns)
  expect_true("age" %in% columns)
  expect_true("deleted_at" %in% columns)
})

test_that(".list_tables() works across databases", {
  skip_if_no_driver("RSQLite", "SQLite")

  db_path <- tempfile(fileext = ".db")
  conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit({
    DBI::dbDisconnect(conn)
    unlink(db_path)
  })

  # Initially no tables
  tables <- .list_tables(conn)
  expect_equal(length(tables), 0)

  # Create table
  create_test_table(conn, "test_table1")
  create_test_table(conn, "test_table2")

  # Check tables exist
  tables <- .list_tables(conn)
  expect_true("test_table1" %in% tables)
  expect_true("test_table2" %in% tables)
})
