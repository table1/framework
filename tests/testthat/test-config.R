test_that("read_config reads configuration from YAML file", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  config <- read_config("config.yml")

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
  # Note: YAML represents single-element character vectors as strings, not arrays
  config_raw <- yaml::read_yaml("test_config.yml")
  expect_equal(config_raw$default$data$example, "data/example.csv")
  expect_equal(config_raw$default$packages, c("dplyr", "ggplot2"))

  # Also verify it works with read_config() which handles the environment sections
  # Note: config::get() returns YAML arrays as lists, not character vectors
  config_read <- read_config(config_file = "test_config.yml")
  expect_equal(config_read$data$example, "data/example.csv")
  # Packages come back as a list from config::get()
  expect_true(is.list(config_read$packages))
  expect_equal(length(config_read$packages), 2)
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
