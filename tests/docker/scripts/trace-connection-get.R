#!/usr/bin/env Rscript

# Trace through connection_get() to see what happens

library(framework)

# Create test directory
test_dir <- file.path(tempdir(), "test_trace")
if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
dir.create(test_dir, recursive = TRUE)

old_wd <- getwd()
setwd(test_dir)

# Create config with pool enabled
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

cat("\n=== Calling connection_get('test_db') ===\n")

# Add debug tracing
debug_connection_get <- function(name) {
  cat("1. Reading config...\n")
  config <- read_config()
  cat("2. Getting connection config...\n")
  conn_config <- config$connections[[name]]
  cat("3. conn_config$pool =", conn_config$pool, "\n")

  use_pool <- isTRUE(conn_config$pool)
  cat("4. use_pool =", use_pool, "\n")

  if (use_pool) {
    cat("5. Checking pool package...\n")
    has_pool <- requireNamespace("pool", quietly = TRUE)
    cat("6. pool package available =", has_pool, "\n")

    if (has_pool) {
      cat("7. Calling connection_pool()...\n")
      pool <- connection_pool(
        name,
        min_size = conn_config$pool_min_size %||% 1,
        max_size = conn_config$pool_max_size %||% Inf,
        idle_timeout = conn_config$pool_idle_timeout %||% 60,
        validation_interval = conn_config$pool_validation_interval %||% 60
      )
      cat("8. Pool created, class:", paste(class(pool), collapse = ", "), "\n")
      return(pool)
    }
  }

  cat("Falling back to regular connection\n")
  return(NULL)
}

result <- debug_connection_get("test_db")

cat("\n=== Result ===\n")
cat("Class:", paste(class(result), collapse = ", "), "\n")
cat("Is Pool:", inherits(result, "Pool"), "\n")

# Clean up
setwd(old_wd)
unlink(test_dir, recursive = TRUE)
