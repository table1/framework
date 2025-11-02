test_that("save_data creates data file and updates database", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create test data
  test_data <- data.frame(x = 1:5, y = letters[1:5])

  # Save as CSV
  suppressMessages(save_data(test_data, "test.public.sample", type = "csv"))

  # Check file was created
  expect_true(file.exists("data/test/public/sample.csv"))

  # Check database record was created
  conn <- DBI::dbConnect(RSQLite::SQLite(), "framework.db")
  on.exit(DBI::dbDisconnect(conn), add = TRUE)

  record <- DBI::dbGetQuery(conn, "SELECT * FROM data WHERE name = 'test.public.sample'")
  expect_equal(nrow(record), 1)
  expect_equal(record$type, "csv")
  expect_false(is.na(record$hash))
})

test_that("save_data creates RDS files", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  test_data <- data.frame(x = 1:5, y = letters[1:5])

  suppressMessages(save_data(test_data, "test.rds_data", type = "rds"))

  expect_true(file.exists("data/test/rds_data.rds"))
})

test_that("load_data reads saved CSV data", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create and save test data
  original_data <- data.frame(x = 1:5, y = letters[1:5])
  suppressMessages(save_data(original_data, "test.csv_load", type = "csv"))

  # Add to config
  config <- read_config()
  config$data$test <- list(
    csv_load = list(
      path = "data/test/csv_load.csv",
      type = "csv",
      delimiter = "comma",
      locked = FALSE,
      encrypted = FALSE
    )
  )
  write_config(config)

  # Load it back
  loaded_data <- suppressWarnings(load_data("test.csv_load"))

  expect_equal(nrow(loaded_data), 5)
  expect_equal(loaded_data$x, 1:5)
})

test_that("load_data reads saved RDS data", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create and save test data
  original_data <- data.frame(x = 1:5, y = letters[1:5])
  suppressMessages(save_data(original_data, "test.rds_load", type = "rds"))

  # Add to config
  config <- read_config()
  config$data$test <- list(
    rds_load = list(
      path = "data/test/rds_load.rds",
      type = "rds",
      locked = FALSE,
      encrypted = FALSE
    )
  )
  write_config(config)

  # Load it back
  loaded_data <- suppressWarnings(load_data("test.rds_load"))

  expect_equal(loaded_data, original_data)
})

test_that("load_data reads direct file paths", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create a CSV file directly
  dir.create("data/direct", recursive = TRUE)
  test_data <- data.frame(a = 1:3, b = 4:6)
  write.csv(test_data, "data/direct/file.csv", row.names = FALSE)

  # Load using direct path
  loaded <- load_data("data/direct/file.csv")

  expect_equal(nrow(loaded), 3)
  expect_true("a" %in% names(loaded))
})

test_that("load_data fails for non-existent file", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  expect_error(load_data("nonexistent.file.csv"))
})

test_that("data_spec_get retrieves data specification from config", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  config <- read_config()
  config$data$inputs <- list(
    raw = list(
      test = list(
        path = "inputs/raw/test.csv",
        type = "csv",
        delimiter = "comma"
      )
    )
  )
  write_config(config)

  spec <- data_spec_get("inputs.raw.test")

  expect_type(spec, "list")
  expect_equal(spec$path, "inputs/raw/test.csv")
  expect_equal(spec$type, "csv")
  expect_equal(spec$delimiter, "comma")
})

test_that("data_spec_update updates configuration", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Update spec
  new_spec <- list(
    path = "inputs/raw/new_test.csv",
    type = "csv",
    delimiter = "tab"
  )

  data_spec_update("inputs.raw.new_test", new_spec)

  # Read back
  spec <- data_spec_get("inputs.raw.new_test")
  expect_equal(spec$path, "inputs/raw/new_test.csv")
  expect_equal(spec$delimiter, "tab")
})

test_that("load_data reads Excel files directly", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")
  
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create an Excel file
  dir.create("data/excel", recursive = TRUE)
  test_data <- data.frame(x = 1:5, y = letters[1:5], z = 10:14)
  writexl::write_xlsx(test_data, "data/excel/test.xlsx")

  # Load using direct path
  loaded <- load_data("data/excel/test.xlsx")

  expect_equal(nrow(loaded), 5)
  expect_equal(loaded$x, 1:5)
  expect_equal(loaded$y, letters[1:5])
  expect_equal(loaded$z, 10:14)
})

test_that("load_data reads Excel files from config", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")
  
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create an Excel file
  dir.create("inputs/raw", recursive = TRUE)
  test_data <- data.frame(name = c("Alice", "Bob"), age = c(25, 30))
  writexl::write_xlsx(test_data, "inputs/raw/people.xlsx")

  # Add to config
  config <- read_config()
  config$data$inputs <- list(
     raw = list(
      people = list(
        path = "inputs/raw/people.xlsx",
        type = "excel",
        locked = FALSE,
        encrypted = FALSE
      )
    )
  )
  write_config(config)

  # Load it back
  loaded <- suppressWarnings(load_data("inputs.raw.people"))

  expect_equal(nrow(loaded), 2)
  expect_equal(loaded$name, c("Alice", "Bob"))
  expect_equal(loaded$age, c(25, 30))
})

test_that("data_spec_get detects Excel file type", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create a fake Excel file
  dir.create("data/excel", recursive = TRUE)
  file.create("data/excel/test.xlsx")

  # Get spec by direct path
  spec <- data_spec_get("data/excel/test.xlsx")

  expect_equal(spec$type, "excel")
  expect_null(spec$delimiter)
})
