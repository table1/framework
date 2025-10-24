#!/usr/bin/env Rscript
# Test connection pooling functionality
# Run this after starting Docker databases with: make db-up

cat("\n=== Testing Connection Pooling ===\n\n")

# Load Framework
if (!require("devtools", quietly = TRUE)) {
  install.packages("devtools")
}
devtools::load_all(".")

# Check if pool package is available
if (!requireNamespace("pool", quietly = TRUE)) {
  cat("Installing pool package...\n")
  install.packages("pool")
}

library(pool)

# Test configuration
test_configs <- list(
  postgres = list(
    driver = "postgres",
    host = "localhost",
    port = 54329,
    database = "framework_test",
    user = "framework",
    password = "framework_test_pass"
  ),
  mysql = list(
    driver = "mysql",
    host = "127.0.0.1",
    port = 33069,
    database = "framework_test",
    user = "framework",
    password = "framework_test_pass"
  ),
  sqlite = list(
    driver = "sqlite",
    database = tempfile(fileext = ".db")
  )
)

# Write temporary config
config_content <- list(
  default = list(
    connections = test_configs
  )
)

config_file <- "config.yml"
yaml::write_yaml(config_content, config_file)

results <- list()

for (db_name in names(test_configs)) {
  cat(sprintf("\n--- Testing %s ---\n", toupper(db_name)))

  tryCatch({
    # Test 1: Create pool
    cat("1. Creating connection pool... ")
    pool_obj <- connection_pool(db_name, min_size = 1, max_size = 3)
    cat("✓\n")

    # Test 2: Verify pool is valid
    cat("2. Verifying pool validity... ")
    stopifnot(pool::dbIsValid(pool_obj))
    cat("✓\n")

    # Test 3: Use pool for query
    cat("3. Testing pool query... ")

    # Create a test table
    if (db_name == "sqlite") {
      DBI::dbExecute(pool_obj, "CREATE TABLE test_pool (id INTEGER PRIMARY KEY, name TEXT)")
    } else if (db_name == "postgres") {
      DBI::dbExecute(pool_obj, "DROP TABLE IF EXISTS test_pool")
      DBI::dbExecute(pool_obj, "CREATE TABLE test_pool (id SERIAL PRIMARY KEY, name VARCHAR(255))")
    } else if (db_name == "mysql") {
      DBI::dbExecute(pool_obj, "DROP TABLE IF EXISTS test_pool")
      DBI::dbExecute(pool_obj, "CREATE TABLE test_pool (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255))")
    }

    # Insert data
    DBI::dbExecute(pool_obj, "INSERT INTO test_pool (name) VALUES ('Alice')")
    DBI::dbExecute(pool_obj, "INSERT INTO test_pool (name) VALUES ('Bob')")

    # Query data
    result <- DBI::dbGetQuery(pool_obj, "SELECT * FROM test_pool")
    stopifnot(nrow(result) == 2)
    stopifnot("Alice" %in% result$name)
    stopifnot("Bob" %in% result$name)
    cat("✓\n")

    # Test 4: Test connection_with_pool
    cat("4. Testing connection_with_pool... ")
    result2 <- connection_with_pool(db_name, {
      DBI::dbGetQuery(pool, "SELECT COUNT(*) as n FROM test_pool")
    })
    stopifnot(result2$n == 2)
    cat("✓\n")

    # Test 5: Test pool reuse (get existing pool)
    cat("5. Testing pool reuse... ")
    pool_obj2 <- connection_pool(db_name)
    # Should be the same pool object
    result3 <- DBI::dbGetQuery(pool_obj2, "SELECT COUNT(*) as n FROM test_pool")
    stopifnot(result3$n == 2)
    cat("✓\n")

    # Test 6: List pools
    cat("6. Testing pool listing... ")
    pool_list <- connection_pool_list()
    stopifnot(db_name %in% pool_list$name)
    stopifnot(pool_list$valid[pool_list$name == db_name])
    cat("✓\n")

    # Test 7: Multiple concurrent operations (connection reuse)
    cat("7. Testing concurrent operations... ")
    for (i in 1:5) {
      result <- DBI::dbGetQuery(pool_obj, "SELECT * FROM test_pool LIMIT 1")
      stopifnot(nrow(result) == 1)
    }
    cat("✓\n")

    # Clean up
    if (!db_name == "sqlite") {
      DBI::dbExecute(pool_obj, "DROP TABLE test_pool")
    }

    results[[db_name]] <- "✓ PASSED"

  }, error = function(e) {
    cat(sprintf("✗ FAILED: %s\n", e$message))
    results[[db_name]] <- sprintf("✗ FAILED: %s", e$message)
  })
}

# Clean up all pools
cat("\n--- Cleanup ---\n")
cat("Closing all pools... ")
closed <- connection_pool_close_all(quiet = TRUE)
cat(sprintf("✓ (%d pools closed)\n", closed))

# Verify pools are closed
pool_list <- connection_pool_list()
stopifnot(nrow(pool_list) == 0)

# Clean up temp files
if (file.exists(config_file)) {
  unlink(config_file)
}
if (!is.null(test_configs$sqlite$database) && file.exists(test_configs$sqlite$database)) {
  unlink(test_configs$sqlite$database)
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
  cat("\n✓ ALL POOLING TESTS PASSED!\n\n")
  quit(status = 0)
} else {
  cat("\n✗ SOME TESTS FAILED\n\n")
  quit(status = 1)
}
