# ==============================================================================
# Config System V2 - TDD Test Suite
# ==============================================================================
#
# This test suite defines the contract for Framework's custom config loader.
# Tests are written BEFORE implementation (TDD approach).
#
# Architecture:
# - Custom YAML loader (no config package dependency)
# - Environment-aware merging (default + active environment)
# - Recursive split file resolution
# - Conflict detection (main file wins)
# - !expr evaluation support
#
# ==============================================================================

# ==============================================================================
# CATEGORY 1: Environment Handling
# ==============================================================================

test_that("flat config without environment sections works", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  # Flat config (no default: wrapper)
  config_content <- "database: localhost
port: 5432
debug: true
"
  writeLines(config_content, "config.yml")

  cfg <- read_config("config.yml")

  # Should treat entire file as default environment
  expect_equal(cfg$database, "localhost")
  expect_equal(cfg$port, 5432)
  expect_true(cfg$debug)

  unlink("config.yml")
})


test_that("environment sections merge correctly (production inherits default)", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  config_content <- "default:
  database: localhost
  port: 5432
  debug: true
  timeout: 30

production:
  database: prod.example.com
  debug: false
"
  writeLines(config_content, "config.yml")

  # Test default environment
  cfg_default <- read_config("config.yml", environment = "default")
  expect_equal(cfg_default$database, "localhost")
  expect_equal(cfg_default$port, 5432)
  expect_true(cfg_default$debug)
  expect_equal(cfg_default$timeout, 30)

  # Test production environment (inherits port & timeout from default)
  cfg_prod <- read_config("config.yml", environment = "production")
  expect_equal(cfg_prod$database, "prod.example.com")
  expect_equal(cfg_prod$port, 5432)  # Inherited from default
  expect_false(cfg_prod$debug)
  expect_equal(cfg_prod$timeout, 30)  # Inherited from default

  unlink("config.yml")
})


test_that("deep nested environment inheritance works", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  config_content <- "default:
  connections:
    db:
      host: localhost
      port: 5432
      options:
        timeout: 30
        retry: 3

production:
  connections:
    db:
      host: prod.example.com
"
  writeLines(config_content, "config.yml")

  cfg <- read_config("config.yml", environment = "production")

  # Production should inherit nested structure
  expect_equal(cfg$connections$db$host, "prod.example.com")
  expect_equal(cfg$connections$db$port, 5432)  # Inherited
  expect_equal(cfg$connections$db$options$timeout, 30)  # Nested inherited
  expect_equal(cfg$connections$db$options$retry, 3)  # Nested inherited

  unlink("config.yml")
})


test_that("config with only production environment errors without default", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  # Missing default environment
  config_content <- "production:
  database: prod.example.com
"
  writeLines(config_content, "config.yml")

  expect_error(
    read_config("config.yml"),
    "no 'default' environment"
  )

  unlink("config.yml")
})


test_that("unknown environment falls back to default with warning", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  config_content <- "default:
  database: localhost

production:
  database: prod.example.com
"
  writeLines(config_content, "config.yml")

  expect_warning(
    cfg <- read_config("config.yml", environment = "staging"),
    "Environment 'staging' not found.*using 'default'"
  )

  # Should use default
  expect_equal(cfg$database, "localhost")

  unlink("config.yml")
})


test_that("R_CONFIG_ACTIVE environment variable sets active environment", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit({
    setwd(old_wd)
    Sys.unsetenv("R_CONFIG_ACTIVE")
  })

  config_content <- "default:
  database: localhost

production:
  database: prod.example.com
"
  writeLines(config_content, "config.yml")

  # Set environment variable
  Sys.setenv(R_CONFIG_ACTIVE = "production")

  # Should use production (no explicit environment arg)
  cfg <- read_config("config.yml")
  expect_equal(cfg$database, "prod.example.com")

  unlink("config.yml")
})


# ==============================================================================
# CATEGORY 2: Split File Resolution
# ==============================================================================

test_that("split file reference loads and merges correctly", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  dir.create("settings", showWarnings = FALSE)

  # Main config
  config_content <- "default:
  project_type: project
  connections: settings/connections.yml
"
  writeLines(config_content, "config.yml")

  # Split file
  connections_content <- "default:
  connections:
    db:
      host: localhost
      port: 5432
"
  writeLines(connections_content, "settings/connections.yml")

  cfg <- read_config("config.yml")

  expect_equal(cfg$project_type, "project")
  expect_equal(cfg$connections$db$host, "localhost")
  expect_equal(cfg$connections$db$port, 5432)

  unlink("config.yml")
  unlink("settings", recursive = TRUE)
})


test_that("split file with flat structure (no environment sections) works", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  dir.create("settings", showWarnings = FALSE)

  # Main config
  config_content <- "default:
  data: settings/data.yml
"
  writeLines(config_content, "config.yml")

  # Split file (flat, no default:)
  data_content <- "data:
  example:
    path: data/example.csv
    type: csv
"
  writeLines(data_content, "settings/data.yml")

  cfg <- read_config("config.yml")

  expect_equal(cfg$data$example$path, "data/example.csv")
  expect_equal(cfg$data$example$type, "csv")

  unlink("config.yml")
  unlink("settings", recursive = TRUE)
})


test_that("split file with environment sections merges correctly", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  dir.create("settings", showWarnings = FALSE)

  # Main config
  config_content <- "default:
  connections: settings/connections.yml
  api_key: default-key

production:
  api_key: prod-key
"
  writeLines(config_content, "config.yml")

  # Split file with environments
  connections_content <- "default:
  connections:
    db:
      host: localhost

production:
  connections:
    db:
      host: prod-db.example.com
"
  writeLines(connections_content, "settings/connections.yml")

  # Test production environment
  cfg <- read_config("config.yml", environment = "production")

  expect_equal(cfg$api_key, "prod-key")
  expect_equal(cfg$connections$db$host, "prod-db.example.com")

  unlink("config.yml")
  unlink("settings", recursive = TRUE)
})


test_that("missing split file errors with clear message", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  config_content <- "default:
  connections: settings/missing.yml
"
  writeLines(config_content, "config.yml")

  expect_error(
    read_config("config.yml"),
    "settings/missing.yml.*not found"
  )

  unlink("config.yml")
})


test_that("split file with invalid YAML errors clearly", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  dir.create("settings", showWarnings = FALSE)

  config_content <- "default:
  connections: settings/bad.yml
"
  writeLines(config_content, "config.yml")

  # Invalid YAML
  bad_content <- "connections:
  db:
    host: [unclosed
"
  writeLines(bad_content, "settings/bad.yml")

  expect_error(
    read_config("config.yml"),
    "Failed to parse.*settings/bad.yml"
  )

  unlink("config.yml")
  unlink("settings", recursive = TRUE)
})


test_that("circular split file reference errors gracefully", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  dir.create("settings", showWarnings = FALSE)

  # Main references A
  config_content <- "default:
  data: settings/a.yml
"
  writeLines(config_content, "config.yml")

  # A references B
  a_content <- "default:
  connections: settings/b.yml
"
  writeLines(a_content, "settings/a.yml")

  # B references A (circular!)
  b_content <- "default:
  data: settings/a.yml
"
  writeLines(b_content, "settings/b.yml")

  expect_error(
    read_config("config.yml"),
    "Circular reference"
  )

  unlink("config.yml")
  unlink("settings", recursive = TRUE)
})


test_that("nested split file references work (A -> B -> C)", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  dir.create("settings", showWarnings = FALSE)

  # Main references A
  config_content <- "default:
  level: main
  config_a: settings/a.yml
"
  writeLines(config_content, "config.yml")

  # A references B
  a_content <- "default:
  level_a: from_a
  config_b: settings/b.yml
"
  writeLines(a_content, "settings/a.yml")

  # B has data
  b_content <- "default:
  level_b: from_b
  data:
    example: value
"
  writeLines(b_content, "settings/b.yml")

  cfg <- read_config("config.yml")

  expect_equal(cfg$level, "main")
  expect_equal(cfg$level_a, "from_a")
  expect_equal(cfg$level_b, "from_b")
  expect_equal(cfg$data$example, "value")

  unlink("config.yml")
  unlink("settings", recursive = TRUE)
})


# ==============================================================================
# CATEGORY 3: Conflict Detection
# ==============================================================================

test_that("main file wins conflict with split file (top-level key)", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  dir.create("settings", showWarnings = FALSE)

  # Main config defines default_connection
  config_content <- "default:
  connections: settings/connections.yml
  default_connection: from_main
"
  writeLines(config_content, "config.yml")

  # Split file also defines default_connection (conflict!)
  connections_content <- "default:
  connections:
    db:
      host: localhost
  default_connection: from_split
"
  writeLines(connections_content, "settings/connections.yml")

  expect_warning(
    cfg <- read_config("config.yml"),
    "default_connection.*defined in both.*main config"
  )

  # Main file should win
  expect_equal(cfg$default_connection, "from_main")

  unlink("config.yml")
  unlink("settings", recursive = TRUE)
})


test_that("multiple split files with conflicting keys (first wins)", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  dir.create("settings", showWarnings = FALSE)

  # Main references two split files
  config_content <- "default:
  connections: settings/connections.yml
  data: settings/data.yml
"
  writeLines(config_content, "config.yml")

  # Both define cache_enabled
  connections_content <- "default:
  cache_enabled: true
"
  writeLines(connections_content, "settings/connections.yml")

  data_content <- "default:
  cache_enabled: false
"
  writeLines(data_content, "settings/data.yml")

  expect_warning(
    cfg <- read_config("config.yml"),
    "cache_enabled.*already defined"
  )

  # First split file (connections) should win
  expect_true(cfg$cache_enabled)

  unlink("config.yml")
  unlink("settings", recursive = TRUE)
})


# ==============================================================================
# CATEGORY 4: !expr Evaluation
# ==============================================================================

test_that("!expr evaluates environment variables", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit({
    setwd(old_wd)
    Sys.unsetenv("TEST_DB_HOST")
  })

  Sys.setenv(TEST_DB_HOST = "test.example.com")

  config_content <- "default:
  database_host: !expr Sys.getenv('TEST_DB_HOST')
"
  writeLines(config_content, "config.yml")

  cfg <- read_config("config.yml")

  expect_equal(cfg$database_host, "test.example.com")

  unlink("config.yml")
})


test_that("!expr with default value works", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit({
    setwd(old_wd)
    Sys.unsetenv("MISSING_VAR")
  })

  config_content <- "default:
  database_host: !expr Sys.getenv('MISSING_VAR', 'localhost')
"
  writeLines(config_content, "config.yml")

  cfg <- read_config("config.yml")

  expect_equal(cfg$database_host, "localhost")

  unlink("config.yml")
})


test_that("!expr works in split files", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit({
    setwd(old_wd)
    Sys.unsetenv("SPLIT_VAR")
  })

  Sys.setenv(SPLIT_VAR = "from_env")

  dir.create("settings", showWarnings = FALSE)

  config_content <- "default:
  connections: settings/connections.yml
"
  writeLines(config_content, "config.yml")

  connections_content <- "default:
  connections:
    db:
      host: !expr Sys.getenv('SPLIT_VAR')
"
  writeLines(connections_content, "settings/connections.yml")

  cfg <- read_config("config.yml")

  expect_equal(cfg$connections$db$host, "from_env")

  unlink("config.yml")
  unlink("settings", recursive = TRUE)
})


test_that("!expr with invalid expression errors clearly", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  config_content <- "default:
  bad_expr: !expr this_function_does_not_exist()
"
  writeLines(config_content, "config.yml")

  expect_error(
    read_config("config.yml"),
    "Failed to evaluate expression"
  )

  unlink("config.yml")
})


test_that("env() syntax evaluates environment variables", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit({
    setwd(old_wd)
    Sys.unsetenv("TEST_ENV_VAR")
  })

  Sys.setenv(TEST_ENV_VAR = "value_from_env")

  config_content <- "default:
  database_host: env(\"TEST_ENV_VAR\")
"
  writeLines(config_content, "config.yml")

  cfg <- read_config("config.yml")

  expect_equal(cfg$database_host, "value_from_env")

  unlink("config.yml")
})


test_that("env() syntax with default value works", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit({
    setwd(old_wd)
    Sys.unsetenv("MISSING_ENV_VAR")
  })

  config_content <- "default:
  database_host: env(\"MISSING_ENV_VAR\", \"localhost\")
"
  writeLines(config_content, "config.yml")

  cfg <- read_config("config.yml")

  expect_equal(cfg$database_host, "localhost")

  unlink("config.yml")
})


test_that("env() syntax works in split files", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit({
    setwd(old_wd)
    Sys.unsetenv("SPLIT_ENV_VAR")
  })

  Sys.setenv(SPLIT_ENV_VAR = "from_split_env")

  dir.create("settings", showWarnings = FALSE)

  config_content <- "default:
  connections: settings/connections.yml
"
  writeLines(config_content, "config.yml")

  connections_content <- "default:
  connections:
    db:
      host: env(\"SPLIT_ENV_VAR\")
"
  writeLines(connections_content, "settings/connections.yml")

  cfg <- read_config("config.yml")

  expect_equal(cfg$connections$db$host, "from_split_env")

  unlink("config.yml")
  unlink("settings", recursive = TRUE)
})


# ==============================================================================
# CATEGORY 5: Type Handling
# ==============================================================================

test_that("NULL values handled correctly", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  config_content <- "default:
  optional_value: null
  required_value: present
"
  writeLines(config_content, "config.yml")

  cfg <- read_config("config.yml")

  expect_null(cfg$optional_value)
  expect_equal(cfg$required_value, "present")

  unlink("config.yml")
})


test_that("empty sections don't error", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  config_content <- "default:
  connections:
  data:
"
  writeLines(config_content, "config.yml")

  cfg <- read_config("config.yml")

  expect_true(is.null(cfg$connections) || (is.list(cfg$connections) && length(cfg$connections) == 0))
  expect_true(is.null(cfg$data) || (is.list(cfg$data) && length(cfg$data) == 0))

  unlink("config.yml")
})


test_that("arrays replace not merge in environment inheritance", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  config_content <- "default:
  packages:
    - dplyr
    - ggplot2
    - tidyr

production:
  packages:
    - dplyr
"
  writeLines(config_content, "config.yml")

  cfg <- read_config("config.yml", environment = "production")

  # Production should REPLACE array, not merge
  expect_equal(length(cfg$packages), 1)
  expect_equal(cfg$packages[[1]], "dplyr")

  unlink("config.yml")
})


# ==============================================================================
# CATEGORY 6: Error Handling
# ==============================================================================

test_that("missing config file errors clearly", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  expect_error(
    read_config("nonexistent.yml"),
    "not found|does not exist"
  )
})


test_that("invalid YAML in main config errors clearly", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  bad_content <- "default:
  key: [unclosed
"
  writeLines(bad_content, "config.yml")

  expect_error(
    read_config("config.yml"),
    "Failed to parse"
  )

  unlink("config.yml")
})


# ==============================================================================
# CATEGORY 7: Backward Compatibility
# ==============================================================================

test_that("existing config.yml files still work", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  # Current Framework config structure
  config_content <- "default:
  project_type: project

  directories:
    notebooks: notebooks
    scripts: scripts

  packages:
    - dplyr
    - ggplot2
"
  writeLines(config_content, "config.yml")

  cfg <- read_config("config.yml")

  expect_equal(cfg$project_type, "project")
  expect_equal(cfg$directories$notebooks, "notebooks")
  expect_equal(length(cfg$packages), 2)

  unlink("config.yml")
})
