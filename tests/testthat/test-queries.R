test_that("get_connection returns SQLite connection for framework db", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  conn <- get_connection("framework")

  expect_s4_class(conn, "SQLiteConnection")

  DBI::dbDisconnect(conn)
})

test_that("get_query executes SELECT query", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Query framework database
  result <- get_query("SELECT name, type FROM sqlite_master WHERE type='table'", "framework")

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 0)
  expect_true("name" %in% names(result))
  expect_true("type" %in% names(result))
})

test_that("execute_query runs INSERT/UPDATE commands", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create a test table
  execute_query("CREATE TABLE test_table (id INTEGER, name TEXT)", "framework")

  # Insert data
  rows <- execute_query("INSERT INTO test_table (id, name) VALUES (1, 'test')", "framework")

  expect_equal(rows, 1)

  # Verify data was inserted
  result <- get_query("SELECT * FROM test_table", "framework")
  expect_equal(nrow(result), 1)
  expect_equal(result$name, "test")

  # Clean up
  execute_query("DROP TABLE test_table", "framework")
})

test_that("get_query handles empty result sets", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create and query empty table
  execute_query("CREATE TABLE empty_table (id INTEGER)", "framework")

  result <- get_query("SELECT * FROM empty_table", "framework")

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)

  # Clean up
  execute_query("DROP TABLE empty_table", "framework")
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
  conn <- get_connection("framework")
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

  conn <- get_connection("framework")
  on.exit(DBI::dbDisconnect(conn), add = TRUE)

  DBI::dbExecute(conn, "CREATE TABLE test_missing (id INTEGER PRIMARY KEY, value TEXT)")

  result <- db_find(conn, "test_missing", 999)

  expect_equal(nrow(result), 0)

  # Clean up
  DBI::dbExecute(conn, "DROP TABLE test_missing")
})

test_that("get_connection fails for non-existent connection", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  expect_error(get_connection("nonexistent_connection"))
})
