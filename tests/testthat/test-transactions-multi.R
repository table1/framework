# Multi-database transaction tests
# Tests connection_transaction(), connection_begin(), connection_commit(), connection_rollback()

test_that("connection_transaction() commits on success", {
  skip_if_no_driver("RSQLite", "SQLite")

  db_path <- tempfile(fileext = ".db")
  conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit({
    DBI::dbDisconnect(conn)
    unlink(db_path)
  })

  # Create table
  create_test_table(conn, "users", with_soft_delete = FALSE)

  # Execute transaction
  result <- connection_transaction(conn, {
    id1 <- connection_insert(conn, "users", list(name = "Alice", email = "alice@example.com", age = 30))
    id2 <- connection_insert(conn, "users", list(name = "Bob", email = "bob@example.com", age = 25))
    c(id1, id2)
  })

  # Verify both records inserted
  expect_length(result, 2)
  users <- DBI::dbGetQuery(conn, "SELECT * FROM users ORDER BY id")
  expect_equal(nrow(users), 2)
  expect_equal(users$name, c("Alice", "Bob"))
})

test_that("connection_transaction() rolls back on error", {
  skip_if_no_driver("RSQLite", "SQLite")

  db_path <- tempfile(fileext = ".db")
  conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit({
    DBI::dbDisconnect(conn)
    unlink(db_path)
  })

  # Create table
  create_test_table(conn, "users", with_soft_delete = FALSE)

  # Transaction that fails
  expect_error({
    connection_transaction(conn, {
      connection_insert(conn, "users", list(name = "Alice", email = "alice@example.com", age = 30))
      stop("Intentional error")
      connection_insert(conn, "users", list(name = "Bob", email = "bob@example.com", age = 25))
    })
  }, "Transaction failed and was rolled back")

  # Verify no records inserted (rollback worked)
  users <- DBI::dbGetQuery(conn, "SELECT * FROM users")
  expect_equal(nrow(users), 0)
})

test_that("connection_transaction() preserves return value", {
  skip_if_no_driver("RSQLite", "SQLite")

  db_path <- tempfile(fileext = ".db")
  conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit({
    DBI::dbDisconnect(conn)
    unlink(db_path)
  })

  # Create table
  create_test_table(conn, "users", with_soft_delete = FALSE)

  # Transaction with return value
  user_data <- connection_transaction(conn, {
    id <- connection_insert(conn, "users", list(name = "Alice", email = "alice@example.com", age = 30))
    connection_find(conn, "users", id)
  })

  expect_s3_class(user_data, "data.frame")
  expect_equal(nrow(user_data), 1)
  expect_equal(user_data$name, "Alice")
})

test_that("Manual transaction control works", {
  skip_if_no_driver("RSQLite", "SQLite")

  db_path <- tempfile(fileext = ".db")
  conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit({
    DBI::dbDisconnect(conn)
    unlink(db_path)
  })

  # Create table
  create_test_table(conn, "users", with_soft_delete = FALSE)

  # Manual transaction - commit
  connection_begin(conn)
  id <- connection_insert(conn, "users", list(name = "Alice", email = "alice@example.com", age = 30))
  connection_commit(conn)

  # Verify committed
  users <- DBI::dbGetQuery(conn, "SELECT * FROM users")
  expect_equal(nrow(users), 1)

  # Manual transaction - rollback
  connection_begin(conn)
  connection_insert(conn, "users", list(name = "Bob", email = "bob@example.com", age = 25))
  connection_rollback(conn)

  # Verify rolled back (still only 1 user)
  users <- DBI::dbGetQuery(conn, "SELECT * FROM users")
  expect_equal(nrow(users), 1)
  expect_equal(users$name, "Alice")
})

test_that("connection_with_transaction() works", {
  skip_if_no_driver("RSQLite", "SQLite")

  db_path <- tempfile(fileext = ".db")
  conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit({
    DBI::dbDisconnect(conn)
    unlink(db_path)
  })

  # Create table
  create_test_table(conn, "users", with_soft_delete = FALSE)

  # Standalone - should create transaction
  connection_with_transaction(conn, {
    connection_insert(conn, "users", list(name = "Alice", email = "alice@example.com", age = 30))
  })

  # Verify inserted
  expect_equal(nrow(DBI::dbGetQuery(conn, "SELECT * FROM users")), 1)

  # Nested - should use existing transaction
  connection_transaction(conn, {
    connection_with_transaction(conn, {
      connection_insert(conn, "users", list(name = "Bob", email = "bob@example.com", age = 25))
    })
    connection_with_transaction(conn, {
      connection_insert(conn, "users", list(name = "Charlie", email = "charlie@example.com", age = 35))
    })
  })

  # Verify both inserted in same transaction
  expect_equal(nrow(DBI::dbGetQuery(conn, "SELECT * FROM users")), 3)
})

test_that("Transactions work on PostgreSQL if available", {
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

  # Create temp table
  drop_test_table(conn, "test_transaction_users")
  create_test_table(conn, "test_transaction_users", with_soft_delete = FALSE)
  on.exit(drop_test_table(conn, "test_transaction_users"), add = TRUE)

  # Test transaction
  connection_transaction(conn, {
    connection_insert(conn, "test_transaction_users", list(name = "Alice", email = "alice@example.com", age = 30))
    connection_insert(conn, "test_transaction_users", list(name = "Bob", email = "bob@example.com", age = 25))
  })

  # Verify both inserted
  users <- DBI::dbGetQuery(conn, "SELECT * FROM test_transaction_users ORDER BY name")
  expect_equal(nrow(users), 2)
  expect_equal(users$name, c("Alice", "Bob"))
})
