#!/usr/bin/env Rscript

# Debug config pooling issue

library(framework)

# Create test directory
test_dir <- file.path(tempdir(), "test_debug_pool")
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

# Read config back
cat("\n=== Config file contents ===\n")
cat(readLines("config.yml"), sep = "\n")

cat("\n=== Reading config with read_config() ===\n")
config <- read_config()
print(str(config$connections$test_db))

cat("\n=== Check pool value ===\n")
cat("pool value:", config$connections$test_db$pool, "\n")
cat("isTRUE(pool):", isTRUE(config$connections$test_db$pool), "\n")

cat("\n=== Check pool package ===\n")
cat("pool package available:", requireNamespace("pool", quietly = TRUE), "\n")

# Clean up
setwd(old_wd)
unlink(test_dir, recursive = TRUE)
