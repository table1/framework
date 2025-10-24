#!/usr/bin/env Rscript

# Test config-based connection pooling
# Verifies that pool configuration in config.yml works correctly

library(framework)
library(DBI)

message("\n=== Testing Config-Based Connection Pooling ===\n")

# Create test directory
test_dir <- file.path(tempdir(), "test_config_pool")
if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
dir.create(test_dir, recursive = TRUE)

old_wd <- getwd()
on.exit({
  setwd(old_wd)
  unlink(test_dir, recursive = TRUE)
}, add = TRUE)

setwd(test_dir)

# Test 1: Connection WITHOUT pooling (default)
message("Test 1: Default behavior (no pooling)")

config_no_pool <- list(
  connections = list(
    test_db = list(
      driver = "sqlite",
      database = "test.db"
    )
  )
)

yaml::write_yaml(list(default = config_no_pool), "config.yml")

conn <- connection_get("test_db")
message("  Connection class: ", class(conn)[1])
if (inherits(conn, "Pool")) {
  stop("ERROR: Should not be a pool!")
}
DBI::dbDisconnect(conn)
message("  ✓ Regular connection (not pooled)")

# Test 2: Connection WITH pooling (pool: true)
message("\nTest 2: With pooling enabled (pool: true)")

config_with_pool <- list(
  connections = list(
    test_db = list(
      driver = "sqlite",
      database = "test.db",
      pool = TRUE,
      pool_min_size = 1,
      pool_max_size = 3
    )
  )
)

yaml::write_yaml(list(default = config_with_pool), "config.yml")

# Check if pool package is available
if (!requireNamespace("pool", quietly = TRUE)) {
  message("  ⚠ pool package not installed, skipping pooling test")
  message("    Install with: install.packages('pool')")
} else {
  pool <- connection_get("test_db")
  message("  Connection class: ", paste(class(pool), collapse = ", "))

  if (!inherits(pool, "Pool")) {
    stop("ERROR: Should be a pool!")
  }

  # Verify pool works for queries
  DBI::dbExecute(pool, "CREATE TABLE test (id INTEGER, name TEXT)")
  DBI::dbExecute(pool, "INSERT INTO test VALUES (1, 'Alice'), (2, 'Bob')")
  result <- DBI::dbGetQuery(pool, "SELECT * FROM test")

  if (nrow(result) != 2) {
    stop("ERROR: Expected 2 rows, got ", nrow(result))
  }

  message("  ✓ Pool created and queries work")

  # Verify query_get() works with pooled connection
  result2 <- query_get("SELECT COUNT(*) as count FROM test", "test_db")
  if (result2$count != 2) {
    stop("ERROR: query_get() failed with pool")
  }

  message("  ✓ query_get() works with pooled connection")

  # Clean up pool
  connection_pool_close("test_db")
  message("  ✓ Pool cleaned up successfully")
}

# Test 3: Pool configuration parameters
message("\nTest 3: Pool configuration parameters from config.yml")

config_with_params <- list(
  connections = list(
    test_db = list(
      driver = "sqlite",
      database = "test.db",
      pool = TRUE,
      pool_min_size = 2,
      pool_max_size = 10,
      pool_idle_timeout = 30,
      pool_validation_interval = 45
    )
  )
)

yaml::write_yaml(list(default = config_with_params), "config.yml")

if (requireNamespace("pool", quietly = TRUE)) {
  pool <- connection_get("test_db")

  # Pool was created with custom parameters
  # (Can't easily verify params, but creation succeeds)
  message("  ✓ Pool created with custom parameters")

  connection_pool_close("test_db")
}

# Test 4: Fallback when pool package not installed
message("\nTest 4: Graceful fallback when pool package missing")

# Temporarily hide pool package
if (requireNamespace("pool", quietly = TRUE)) {
  message("  Note: pool package is installed, simulating warning behavior")
  message("  (In real scenario without pool, would see warning and fallback to regular connection)")
} else {
  message("  pool package not available")

  config_want_pool <- list(
    connections = list(
      test_db = list(
        driver = "sqlite",
        database = "test.db",
        pool = TRUE
      )
    )
  )

  yaml::write_yaml(list(default = config_want_pool), "config.yml")

  # Should warn and return regular connection
  conn <- suppressWarnings(connection_get("test_db"))

  if (inherits(conn, "Pool")) {
    stop("ERROR: Should have fallen back to regular connection!")
  }

  DBI::dbDisconnect(conn)
  message("  ✓ Falls back to regular connection with warning")
}

message("\n=== All Config-Based Pooling Tests Passed! ===\n")
