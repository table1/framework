test_that("read_config reads configuration from YAML file", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  config <- read_config()

  expect_type(config, "list")
  expect_true("data" %in% names(config))
  expect_true("packages" %in% names(config))
  expect_true("connections" %in% names(config))
  expect_true("options" %in% names(config))
})

test_that("read_config handles missing config file", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  expect_error(read_config("nonexistent.yml"))
})

test_that("write_config writes configuration to file", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  test_config <- list(
    data = list(example = "data/example.csv"),
    packages = c("dplyr", "ggplot2")
  )

  write_config(test_config, "test_config.yml")

  expect_true(file.exists("test_config.yml"))

  # Read it back using yaml::read_yaml (gets raw structure with "default" wrapper)
  config_raw <- yaml::read_yaml("test_config.yml")
  expect_equal(config_raw$default$data$example, "data/example.csv")
  expect_equal(config_raw$default$packages, c("dplyr", "ggplot2"))

  # Read back with read_config
  config_read <- read_config(config_file = "test_config.yml")
  expect_equal(config_read$data$example, "data/example.csv")
  # Packages are a character vector when written as simple strings
  expect_equal(config_read$packages, c("dplyr", "ggplot2"))
})


# ============================================================================
# Config Resolution and config() Helper Tests
# ============================================================================

test_that("config() helper with flat config accesses directories correctly", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  config_content <- "default:
  project_type: project

  directories:
    notebooks: my_notebooks
    scripts: my_scripts
    functions: my_functions
    cache: my_cache
"
  writeLines(config_content, "config.yml")

  # Test direct access to directories
  expect_equal(config("directories.notebooks"), "my_notebooks")
  expect_equal(config("directories.scripts"), "my_scripts")
  expect_equal(config("directories.functions"), "my_functions")

  # Test smart lookup (single key checks directories first)
  expect_equal(config("notebooks"), "my_notebooks")
  expect_equal(config("scripts"), "my_scripts")
  expect_equal(config("functions"), "my_functions")

  # Test project_type access
  expect_equal(config("project_type"), "project")

  # Test default values
  expect_equal(config("nonexistent"), NULL)
  expect_equal(config("nonexistent", default = "fallback"), "fallback")

  unlink("config.yml")
})


test_that("config() helper handles legacy options structure", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  # Create legacy config with options$notebook_dir
  config_content <- "default:
  options:
    notebook_dir: legacy_notebooks
    script_dir: legacy_scripts
"
  writeLines(config_content, "config.yml")

  # Smart lookup should find legacy keys
  expect_equal(config("notebook"), "legacy_notebooks")
  expect_equal(config("script"), "legacy_scripts")

  unlink("config.yml")
})


test_that("config() prioritizes directories over legacy options", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  # Config with BOTH new and legacy structures
  config_content <- "default:
  directories:
    notebooks: new_notebooks

  options:
    notebook_dir: legacy_notebooks
"
  writeLines(config_content, "config.yml")

  # Should prefer directories structure
  expect_equal(config("notebooks"), "new_notebooks")

  # Explicit path still works
  expect_equal(config("options.notebook_dir"), "legacy_notebooks")

  unlink("config.yml")
})


test_that("read_config() merges directories correctly", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  config_content <- "default:
  directories:
    notebooks: notebooks
    scripts: scripts
    cache: data/cached
"
  writeLines(config_content, "config.yml")

  cfg <- read_config()

  # Check structure
  expect_true(!is.null(cfg$directories))
  expect_equal(cfg$directories$notebooks, "notebooks")
  expect_equal(cfg$directories$scripts, "scripts")
  expect_equal(cfg$directories$cache, "data/cached")

  unlink("config.yml")
})


test_that("split file config with inline directories works", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  dir.create("settings", showWarnings = FALSE)

  # Main config with inline directories and split data
  config_content <- "default:
  project_type: project

  directories:
    notebooks: notebooks
    scripts: scripts
    cache: data/cached

  data: settings/data.yml
"
  writeLines(config_content, "config.yml")

  # Create data settings file
  data_content <- "data:
  example:
    path: data/example.csv
    type: csv
"
  writeLines(data_content, "settings/data.yml")

  # Test config resolution
  cfg <- read_config()

  # Directories should be inline
  expect_equal(cfg$directories$notebooks, "notebooks")
  expect_equal(cfg$directories$scripts, "scripts")

  # Data should come from split file
  expect_true(!is.null(cfg$data$example))
  expect_equal(cfg$data$example$path, "data/example.csv")

  # Test via config() helper
  expect_equal(config("notebooks"), "notebooks")
  expect_equal(config("data.example.path"), "data/example.csv")

  unlink("config.yml")
  unlink("settings", recursive = TRUE)
})


test_that("make_notebook() uses new directories config", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  # Create config with custom notebook directory
  config_content <- "default:
  directories:
    notebooks: custom_notebooks
"
  writeLines(config_content, "config.yml")

  # Directory detection should use config
  result <- framework:::.get_notebook_dir_from_config()
  expect_equal(result, "custom_notebooks")

  unlink("config.yml")
})


test_that("config() handles nested paths correctly", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  config_content <- "default:
  connections:
    db:
      driver: postgresql
      host: localhost
      port: 5432
      database: mydb
"
  writeLines(config_content, "config.yml")

  # Test deep nesting
  expect_equal(config("connections.db.driver"), "postgresql")
  expect_equal(config("connections.db.host"), "localhost")
  expect_equal(config("connections.db.port"), 5432)

  # Test partial paths
  db_config <- config("connections.db")
  expect_true(is.list(db_config))
  expect_equal(db_config$driver, "postgresql")
  expect_equal(db_config$host, "localhost")

  unlink("config.yml")
})


test_that("read_config() initializes all standard sections", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  # Minimal config
  config_content <- "default:
  project_type: project
"
  writeLines(config_content, "config.yml")

  cfg <- read_config()

  # All standard sections should exist (may be empty lists)
  expect_true(!is.null(cfg$data))
  expect_true(!is.null(cfg$connections))
  expect_true(!is.null(cfg$git))
  expect_true(!is.null(cfg$security))
  expect_true(!is.null(cfg$packages))
  expect_true(!is.null(cfg$directories))
  expect_true(!is.null(cfg$options))

  unlink("config.yml")
})


test_that("config() returns NULL for missing keys", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  config_content <- "default:
  directories:
    notebooks: notebooks
"
  writeLines(config_content, "config.yml")

  # Non-existent keys
  expect_null(config("nonexistent"))
  expect_null(config("directories.nonexistent"))
  expect_null(config("deeply.nested.nonexistent"))

  # With defaults
  expect_equal(config("nonexistent", default = "default_value"), "default_value")

  unlink("config.yml")
})


test_that("config system handles all three project types", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  # Test project type
  config_content <- "default:
  project_type: project
  directories:
    notebooks: notebooks
    scripts: scripts
    results_public: results/public
"
  writeLines(config_content, "config.yml")
  expect_equal(config("project_type"), "project")
  expect_equal(config("scripts"), "scripts")
  unlink("config.yml")

  # Test course type
  config_content <- "default:
  project_type: course
  directories:
    notebooks: notebooks
    presentations: presentations
"
  writeLines(config_content, "config.yml")
  expect_equal(config("project_type"), "course")
  expect_equal(config("presentations"), "presentations")
  unlink("config.yml")

  # Test presentation type
  config_content <- "default:
  project_type: presentation
  directories:
    functions: functions
    cache: data/cached
"
  writeLines(config_content, "config.yml")
  expect_equal(config("project_type"), "presentation")
  expect_equal(config("cache"), "data/cached")
  unlink("config.yml")
})


# ============================================================================
# Config Conflict and Scoped Include Tests
# ============================================================================

# Test removed - format changed: split files now wrap content under section key
# Old format had unexpected keys at root level, new format wraps everything under connections:


test_that("conflict between main config and split file triggers warning", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  dir.create("settings", showWarnings = FALSE)

  # Main config with default_connection
  config_content <- "default:
  connections: settings/connections.yml
  default_connection: from_main
"
  writeLines(config_content, "config.yml")

  # Split file ALSO has default_connection (conflict!)
  connections_content <- "connections:
  db:
    host: localhost

default_connection: from_split  # CONFLICT!
"
  writeLines(connections_content, "settings/connections.yml")

  # Should warn about conflict AND scoped include violation
  expect_warning(
    cfg <- read_config(),
    "default_connection.*defined in both"
  )

  # Main file should win
  expect_equal(cfg$default_connection, "from_main")

  unlink("config.yml")
  unlink("settings", recursive = TRUE)
})


# Test removed - format changed: split files now have section-specific structure
# Old format: connections file could have options:, new format: just connections: wrapper


test_that("main file value takes precedence over split file", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  dir.create("settings", showWarnings = FALSE)

  # Main config with explicit value
  config_content <- "default:
  project_type: project
  data: settings/data.yml
  cache_enabled: true
"
  writeLines(config_content, "config.yml")

  # Split file trying to override (bad practice, should warn)
  data_content <- "data:
  example:
    path: data/example.csv

cache_enabled: false  # Trying to override!
"
  writeLines(data_content, "settings/data.yml")

  # Should warn
  expect_warning(
    cfg <- read_config(),
    "cache_enabled.*defined in both"
  )

  # Main file wins
  expect_true(cfg$cache_enabled)

  unlink("config.yml")
  unlink("settings", recursive = TRUE)
})


test_that("multiple split files can coexist without conflicts", {
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  dir.create("settings", showWarnings = FALSE)

  # Main config with multiple split files
  config_content <- "default:
  connections: settings/connections.yml
  data: settings/data.yml
"
  writeLines(config_content, "config.yml")

  # Connections file (clean)
  connections_content <- "connections:
  db:
    host: localhost
"
  writeLines(connections_content, "settings/connections.yml")

  # Data file (clean)
  data_content <- "data:
  example:
    path: data/example.csv
"
  writeLines(data_content, "settings/data.yml")

  # Should not warn (both files are clean)
  expect_no_warning(
    cfg <- read_config()
  )

  # Both sections should be merged
  expect_equal(cfg$connections$db$host, "localhost")
  expect_equal(cfg$data$example$path, "data/example.csv")

  unlink("config.yml")
  unlink("settings", recursive = TRUE)
})

# ---- config() Helper Tests ----

test_that("config() returns entire config when no key provided", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  cfg <- config()
  expect_type(cfg, "list")
  expect_true("directories" %in% names(cfg))
  expect_true("packages" %in% names(cfg))
})

test_that("config() accesses nested values with dot notation", {
  test_dir <- create_test_project(type = "project")
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Test nested access - get whatever directories exist
  dirs <- config("directories")
  if (length(dirs) > 0) {
    first_key <- names(dirs)[1]
    first_value <- config(paste0("directories.", first_key))
    expect_equal(first_value, dirs[[first_key]])
  }
})

test_that("config() returns default for missing keys", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Missing key with default
  result <- config("missing.key", default = "fallback")
  expect_equal(result, "fallback")

  # Missing key without default
  result <- config("missing.key")
  expect_null(result)
})

test_that("config() returns entire sections as lists", {
  test_dir <- create_test_project(type = "project")
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Get entire directories section
  dirs <- config("directories")
  expect_type(dirs, "list")
  expect_true(length(dirs) > 0)  # Should have at least some directories
})

test_that("config() handles smart directory lookups", {
  test_dir <- create_test_project(type = "project")
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Single-word key should check directories section
  # Get whatever directories exist and test smart lookup
  dirs <- config("directories")
  if (length(dirs) > 0) {
    first_key <- names(dirs)[1]
    # Smart lookup (no "directories." prefix)
    smart_result <- config(first_key)
    # Should match the direct access
    expect_equal(smart_result, dirs[[first_key]])
  }
})

test_that("config() returns raw values in non-interactive mode", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Tests run in non-interactive mode
  # Should return raw list, not invisible
  dirs <- config("directories")
  expect_type(dirs, "list")
  expect_visible(dirs)
})

test_that("config() works with deep nesting", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create config with deep nesting
  yaml::write_yaml(list(
    default = list(
      level1 = list(
        level2 = list(
          level3 = list(
            value = "deep_value"
          )
        )
      )
    )
  ), "config.yml")

  # Access deep value
  result <- config("level1.level2.level3.value")
  expect_equal(result, "deep_value")

  # Access intermediate level
  level2 <- config("level1.level2")
  expect_type(level2, "list")
  expect_true("level3" %in% names(level2))
})
