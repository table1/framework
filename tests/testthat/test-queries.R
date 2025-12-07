# Helper alias for internal function used in tests
db_find <- framework:::connection_find

test_that("db_connect returns SQLite connection for framework database", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  conn <- db_connect("framework")

  expect_s4_class(conn, "SQLiteConnection")

  DBI::dbDisconnect(conn)
})

test_that("db_query executes SELECT query on connection", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Query framework database
  result <- db_query("SELECT name, type FROM sqlite_master WHERE type='table'", "framework")

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 0)
  expect_true("name" %in% names(result))
  expect_true("type" %in% names(result))
})

test_that("db_execute runs INSERT/UPDATE commands on connection", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create a test table
  db_execute("CREATE TABLE test_table (id INTEGER, name TEXT)", "framework")

  # Insert data
  rows <- db_execute("INSERT INTO test_table (id, name) VALUES (1, 'test')", "framework")

  expect_equal(rows, 1)

  # Verify data was inserted
  result <- db_query("SELECT * FROM test_table", "framework")
  expect_equal(nrow(result), 1)
  expect_equal(result$name, "test")

  # Clean up
  db_execute("DROP TABLE test_table", "framework")
})

test_that("db_query handles empty result sets correctly", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create and query empty table
  db_execute("CREATE TABLE empty_table (id INTEGER)", "framework")

  result <- db_query("SELECT * FROM empty_table", "framework")

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)

  # Clean up
  db_execute("DROP TABLE empty_table", "framework")
})

test_that("db_find retrieves record by ID", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create test table and insert data
  conn <- db_connect("framework")
  on.exit(DBI::dbDisconnect(conn), add = TRUE)

  DBI::dbExecute(conn, "CREATE TABLE test_find (id INTEGER PRIMARY KEY, value TEXT)")
  DBI::dbExecute(conn, "INSERT INTO test_find (id, value) VALUES (1, 'first')")
  DBI::dbExecute(conn, "INSERT INTO test_find (id, value) VALUES (2, 'second')")

  # Find record
  result <- db_find(conn, "test_find", 2)

  expect_equal(nrow(result), 1)
  expect_equal(result$id, 2)
  expect_equal(result$value, "second")

  # Clean up
  DBI::dbExecute(conn, "DROP TABLE test_find")
})

test_that("db_find returns empty data frame for non-existent ID", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  conn <- db_connect("framework")
  on.exit(DBI::dbDisconnect(conn), add = TRUE)

  DBI::dbExecute(conn, "CREATE TABLE test_missing (id INTEGER PRIMARY KEY, value TEXT)")

  result <- db_find(conn, "test_missing", 999)

  expect_equal(nrow(result), 0)

  # Clean up
  DBI::dbExecute(conn, "DROP TABLE test_missing")
})

test_that("db_connect fails for non-existent connection name", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  expect_error(db_connect("nonexistent_connection"))
})
