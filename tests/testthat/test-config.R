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
