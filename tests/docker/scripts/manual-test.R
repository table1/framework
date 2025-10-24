#!/usr/bin/env Rscript
# Manual comprehensive test of multi-database support
# Run this script after starting Docker containers with: make db-up
# This is NOT part of the automated test suite - it's for manual verification

cat("\n=== Framework Multi-Database Manual Test ===\n\n")

# Load Framework
if (!require("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Load Framework from source
devtools::load_all(".")

# Test configuration with weird ports
test_configs <- list(
  postgres = list(
    driver = "postgres",
    host = "localhost",
    port = 54329,  # Weird port
    database = "framework_test",
    user = "framework",
    password = "framework_test_pass"
  ),
  mysql = list(
    driver = "mysql",
    host = "127.0.0.1",  # Force TCP connection
    port = 33069,  # Weird port
    database = "framework_test",
    user = "framework",
    password = "framework_test_pass"
  ),
  mariadb = list(
    driver = "mariadb",
    host = "127.0.0.1",  # Force TCP connection
    port = 33070,  # Weird port
    database = "framework_test",
    user = "framework",
    password = "framework_test_pass"
  ),
  sqlite = list(
    driver = "sqlite",
    database = tempfile(fileext = ".db")
  ),
  duckdb = list(
    driver = "duckdb",
    database = tempfile(fileext = ".duckdb")
  )
)

# Track results
results <- list()

# Test each database
for (db_name in names(test_configs)) {
  cat(sprintf("\n--- Testing %s ---\n", toupper(db_name)))

  config <- test_configs[[db_name]]

  tryCatch({
    # 1. Test connection
    cat("1. Connecting... ")
    conn <- switch(config$driver,
      postgres = .connect_postgres(config),
      mysql = .connect_mysql(config),
      mariadb = .connect_mysql(config),
      sqlite = .connect_sqlite(config),
      duckdb = .connect_duckdb(config)
    )
    cat("✓\n")

    # 2. Test schema introspection
    cat("2. Testing schema introspection... ")

    # Create test table
    if (inherits(conn, "SQLiteConnection")) {
      DBI::dbExecute(conn, "
        CREATE TABLE test_users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          email TEXT,
          age INTEGER,
          deleted_at TEXT
        )
      ")
    } else if (inherits(conn, "PqConnection")) {
      DBI::dbExecute(conn, "DROP TABLE IF EXISTS test_users")
      DBI::dbExecute(conn, "
        CREATE TABLE test_users (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255),
          email VARCHAR(255),
          age INTEGER,
          deleted_at TIMESTAMP
        )
      ")
    } else if (inherits(conn, "MariaDBConnection")) {
      DBI::dbExecute(conn, "DROP TABLE IF EXISTS test_users")
      DBI::dbExecute(conn, "
        CREATE TABLE test_users (
          id INT AUTO_INCREMENT PRIMARY KEY,
          name VARCHAR(255),
          email VARCHAR(255),
          age INT,
          deleted_at TIMESTAMP NULL
        )
      ")
    } else if (inherits(conn, "duckdb_connection")) {
      DBI::dbExecute(conn, "
        CREATE SEQUENCE test_users_id_seq START 1
      ")
      DBI::dbExecute(conn, "
        CREATE TABLE test_users (
          id INTEGER PRIMARY KEY DEFAULT nextval('test_users_id_seq'),
          name VARCHAR,
          email VARCHAR,
          age INTEGER,
          deleted_at TIMESTAMP
        )
      ")
    }

    # Test .has_column()
    stopifnot(.has_column(conn, "test_users", "name"))
    stopifnot(.has_column(conn, "test_users", "deleted_at"))
    stopifnot(!.has_column(conn, "test_users", "nonexistent"))
    cat("✓\n")

    # 3. Test CRUD operations
    cat("3. Testing CRUD operations... ")

    # Insert
    id1 <- connection_insert(conn, "test_users", list(
      name = "Alice",
      email = "alice@example.com",
      age = 30
    ), auto_timestamps = FALSE)

    id2 <- connection_insert(conn, "test_users", list(
      name = "Bob",
      email = "bob@example.com",
      age = 25
    ), auto_timestamps = FALSE)

    # Find by ID
    alice <- connection_find(conn, "test_users", id1)
    stopifnot(nrow(alice) == 1)
    stopifnot(alice$name == "Alice")

    # Find by column
    bob <- connection_find_by(conn, "test_users", email = "bob@example.com")
    stopifnot(nrow(bob) == 1)
    stopifnot(bob$name == "Bob")

    # Update
    connection_update(conn, "test_users", id1, list(age = 31), auto_timestamps = FALSE)
    alice_updated <- connection_find(conn, "test_users", id1)
    stopifnot(alice_updated$age == 31)

    # Soft delete
    connection_delete(conn, "test_users", id2, soft = TRUE)
    bob_deleted <- connection_find(conn, "test_users", id2)
    stopifnot(nrow(bob_deleted) == 0)  # Should not be found

    bob_with_trashed <- connection_find(conn, "test_users", id2, with_trashed = TRUE)
    stopifnot(nrow(bob_with_trashed) == 1)  # Should be found with trashed

    # Restore
    connection_restore(conn, "test_users", id2)
    bob_restored <- connection_find(conn, "test_users", id2)
    stopifnot(nrow(bob_restored) == 1)

    cat("✓\n")

    # 4. Test transactions
    cat("4. Testing transactions... ")

    # Successful transaction
    result <- connection_transaction(conn, {
      id3 <- connection_insert(conn, "test_users", list(
        name = "Charlie",
        email = "charlie@example.com",
        age = 35
      ), auto_timestamps = FALSE)
      id3
    })
    charlie <- connection_find(conn, "test_users", result)
    stopifnot(nrow(charlie) == 1)

    # Failed transaction (should rollback)
    initial_count <- DBI::dbGetQuery(conn, "SELECT COUNT(*) as n FROM test_users")$n

    tryCatch({
      connection_transaction(conn, {
        connection_insert(conn, "test_users", list(
          name = "Dave",
          email = "dave@example.com",
          age = 40
        ), auto_timestamps = FALSE)
        stop("Intentional error")
      })
    }, error = function(e) {
      # Expected to fail
    })

    final_count <- DBI::dbGetQuery(conn, "SELECT COUNT(*) as n FROM test_users")$n
    stopifnot(initial_count == final_count)  # Count should be same (rollback worked)

    cat("✓\n")

    # Clean up
    if (!inherits(conn, "SQLiteConnection") && !inherits(conn, "duckdb_connection")) {
      DBI::dbExecute(conn, "DROP TABLE test_users")
    }

    if (inherits(conn, "duckdb_connection")) {
      DBI::dbDisconnect(conn, shutdown = TRUE)
    } else {
      DBI::dbDisconnect(conn)
    }

    # Clean up temp files
    if (config$driver %in% c("sqlite", "duckdb")) {
      unlink(config$database)
    }

    results[[db_name]] <- "✓ PASSED"

  }, error = function(e) {
    cat(sprintf("✗ FAILED: %s\n", e$message))
    results[[db_name]] <- sprintf("✗ FAILED: %s", e$message)
  })
}

# Summary
cat("\n\n=== Test Summary ===\n")
for (db_name in names(results)) {
  cat(sprintf("%-12s: %s\n", toupper(db_name), results[[db_name]]))
}

# Count successes
passed <- sum(sapply(results, function(x) grepl("PASSED", x)))
total <- length(results)

cat(sprintf("\nTotal: %d/%d passed\n", passed, total))

if (passed == total) {
  cat("\n✓ ALL TESTS PASSED!\n\n")
  quit(status = 0)
} else {
  cat("\n✗ SOME TESTS FAILED\n\n")
  quit(status = 1)
}
