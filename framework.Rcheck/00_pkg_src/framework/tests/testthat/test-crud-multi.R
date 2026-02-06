# Multi-database CRUD operation tests
# Tests connection_find_by(), connection_insert(), connection_update(), connection_delete()

# Helper aliases for internal functions used in tests
connection_find_by <- framework:::connection_find_by
connection_insert <- framework:::connection_insert
connection_update <- framework:::connection_update
connection_delete <- framework:::connection_delete
connection_restore <- framework:::connection_restore
connection_find <- framework:::connection_find

test_that("connection_find_by() works across databases", {
  skip_if_no_driver("RSQLite", "SQLite")

  db_path <- tempfile(fileext = ".db")
  conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit({
    DBI::dbDisconnect(conn)
    unlink(db_path)
  })

  # Create and populate table
  create_test_table(conn, "users", with_soft_delete = TRUE)
  DBI::dbExecute(conn, "INSERT INTO users (name, email, age) VALUES ('Alice', 'alice@example.com', 30)")
  DBI::dbExecute(conn, "INSERT INTO users (name, email, age) VALUES ('Bob', 'bob@example.com', 25)")
  DBI::dbExecute(conn, "INSERT INTO users (name, email, age) VALUES ('Charlie', 'charlie@example.com', 35)")

  # Soft-delete Charlie
  DBI::dbExecute(conn, "UPDATE users SET deleted_at = datetime('now') WHERE name = 'Charlie'")

  # Find by email
  result <- connection_find_by(conn, "users", email = "alice@example.com")
  expect_equal(nrow(result), 1)
  expect_equal(result$name, "Alice")

  # Find by multiple conditions
  result <- connection_find_by(conn, "users", name = "Bob", age = 25)
  expect_equal(nrow(result), 1)
  expect_equal(result$email, "bob@example.com")

  # Soft-deleted user not returned by default
  result <- connection_find_by(conn, "users", name = "Charlie")
  expect_equal(nrow(result), 0)

  # Soft-deleted user returned with with_trashed = TRUE
  result <- connection_find_by(conn, "users", name = "Charlie", with_trashed = TRUE)
  expect_equal(nrow(result), 1)
  expect_equal(result$email, "charlie@example.com")
})

test_that("connection_insert() works across databases", {
  skip_if_no_driver("RSQLite", "SQLite")

  db_path <- tempfile(fileext = ".db")
  conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit({
    DBI::dbDisconnect(conn)
    unlink(db_path)
  })

  # Create table
  create_test_table(conn, "users", with_soft_delete = FALSE)

  # Insert record
  id <- connection_insert(conn, "users", list(
    name = "Alice",
    email = "alice@example.com",
    age = 30
  ))

  expect_true(is.numeric(id))
  expect_true(id > 0)

  # Verify inserted
  result <- DBI::dbGetQuery(conn, "SELECT * FROM users WHERE id = ?", params = list(id))
  expect_equal(nrow(result), 1)
  expect_equal(result$name, "Alice")
  expect_equal(result$email, "alice@example.com")
  expect_equal(result$age, 30)
})

test_that("connection_insert() auto-handles timestamps", {
  skip_if_no_driver("RSQLite", "SQLite")

  db_path <- tempfile(fileext = ".db")
  conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit({
    DBI::dbDisconnect(conn)
    unlink(db_path)
  })

  # Create table with timestamps
  create_test_table(conn, "users", with_soft_delete = TRUE)

  # Insert without providing timestamps
  id <- connection_insert(conn, "users", list(
    name = "Alice",
    email = "alice@example.com",
    age = 30
  ), auto_timestamps = TRUE)

  # Verify timestamps were set
  result <- DBI::dbGetQuery(conn, "SELECT * FROM users WHERE id = ?", params = list(id))
  expect_false(is.na(result$created_at))
  expect_false(is.na(result$updated_at))
})

test_that("connection_update() works across databases", {
  skip_if_no_driver("RSQLite", "SQLite")

  db_path <- tempfile(fileext = ".db")
  conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit({
    DBI::dbDisconnect(conn)
    unlink(db_path)
  })

  # Create and populate table
  create_test_table(conn, "users", with_soft_delete = FALSE)
  id <- connection_insert(conn, "users", list(name = "Alice", email = "alice@example.com", age = 30))

  # Update record
  rows <- connection_update(conn, "users", id, list(age = 31, name = "Alice Updated"))
  expect_equal(rows, 1)

  # Verify update
  result <- DBI::dbGetQuery(conn, "SELECT * FROM users WHERE id = ?", params = list(id))
  expect_equal(result$name, "Alice Updated")
  expect_equal(result$age, 31)
})

test_that("connection_delete() soft-deletes when column exists", {
  skip_if_no_driver("RSQLite", "SQLite")

  db_path <- tempfile(fileext = ".db")
  conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit({
    DBI::dbDisconnect(conn)
    unlink(db_path)
  })

  # Create table with soft-delete support
  create_test_table(conn, "users", with_soft_delete = TRUE)
  id <- connection_insert(conn, "users", list(name = "Alice", email = "alice@example.com", age = 30))

  # Soft-delete
  rows <- connection_delete(conn, "users", id, soft = TRUE)
  expect_equal(rows, 1)

  # Record still exists but is soft-deleted
  result <- DBI::dbGetQuery(conn, "SELECT * FROM users WHERE id = ?", params = list(id))
  expect_equal(nrow(result), 1)
  expect_false(is.na(result$deleted_at))

  # connection_find() doesn't return soft-deleted by default
  result <- connection_find(conn, "users", id)
  expect_equal(nrow(result), 0)

  # But returns with with_trashed = TRUE
  result <- connection_find(conn, "users", id, with_trashed = TRUE)
  expect_equal(nrow(result), 1)
})

test_that("connection_delete() hard-deletes when soft = FALSE", {
  skip_if_no_driver("RSQLite", "SQLite")

  db_path <- tempfile(fileext = ".db")
  conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit({
    DBI::dbDisconnect(conn)
    unlink(db_path)
  })

  # Create table with soft-delete support
  create_test_table(conn, "users", with_soft_delete = TRUE)
  id <- connection_insert(conn, "users", list(name = "Alice", email = "alice@example.com", age = 30))

  # Hard-delete
  rows <- connection_delete(conn, "users", id, soft = FALSE)
  expect_equal(rows, 1)

  # Record permanently deleted
  result <- DBI::dbGetQuery(conn, "SELECT * FROM users WHERE id = ?", params = list(id))
  expect_equal(nrow(result), 0)
})

test_that("connection_restore() restores soft-deleted records", {
  skip_if_no_driver("RSQLite", "SQLite")

  db_path <- tempfile(fileext = ".db")
  conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit({
    DBI::dbDisconnect(conn)
    unlink(db_path)
  })

  # Create table with soft-delete support
  create_test_table(conn, "users", with_soft_delete = TRUE)
  id <- connection_insert(conn, "users", list(name = "Alice", email = "alice@example.com", age = 30))

  # Soft-delete
  connection_delete(conn, "users", id, soft = TRUE)
  expect_equal(nrow(connection_find(conn, "users", id)), 0)

  # Restore
  rows <- connection_restore(conn, "users", id)
  expect_equal(rows, 1)

  # Now accessible
  result <- connection_find(conn, "users", id)
  expect_equal(nrow(result), 1)
  expect_true(is.na(result$deleted_at))
})
