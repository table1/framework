test_that("make_notebook() detects correct directories", {
  # Create temp directory
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  # Test 1: notebooks/ directory exists
  dir.create("notebooks", showWarnings = FALSE)
  result <- framework:::.get_notebook_dir_from_config()
  expect_equal(result, "notebooks")
  unlink("notebooks", recursive = TRUE)

  # Test 2: work/ directory exists (legacy)
  dir.create("work", showWarnings = FALSE)
  result <- framework:::.get_notebook_dir_from_config()
  expect_equal(result, "work")
  unlink("work", recursive = TRUE)

  # Test 3: both exist - notebooks/ takes precedence
  dir.create("notebooks", showWarnings = FALSE)
  dir.create("work", showWarnings = FALSE)
  result <- framework:::.get_notebook_dir_from_config()
  expect_equal(result, "notebooks")
  unlink("notebooks", recursive = TRUE)
  unlink("work", recursive = TRUE)

  # Test 4: neither exists - defaults to current dir
  result <- framework:::.get_notebook_dir_from_config()
  expect_equal(result, ".")
})

test_that("config.yml directory settings are respected", {
  # Create temp directory with config
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  # Create config with explicit notebook_dir
  config_content <- "default:
  options:
    notebook_dir: my_notebooks
"
  writeLines(config_content, "config.yml")

  # Test notebook dir from config
  result <- framework:::.get_notebook_dir_from_config()
  expect_equal(result, "my_notebooks")

  unlink("config.yml")
})
