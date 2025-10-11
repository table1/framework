test_that("scratch_capture saves data frame to scratch", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  test_data <- data.frame(x = 1:5, y = letters[1:5])

  suppressMessages(scratch_capture(test_data, "test_scratch_capture"))

  # Check that file was created (default is TSV for data frames)
  scratch_dir <- read_config()$options$data$scratch_dir
  expect_true(file.exists(file.path(scratch_dir, "test_scratch_capture.rds")) ||
              file.exists(file.path(scratch_dir, "test_scratch_capture.csv")) ||
              file.exists(file.path(scratch_dir, "test_scratch_capture.tsv")))
})

test_that("scratch_capture with to='csv' saves as CSV", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  test_data <- data.frame(a = 1:3, b = 4:6)

  suppressMessages(scratch_capture(test_data, "csv_test", to = "csv"))

  scratch_dir <- read_config()$options$data$scratch_dir
  expect_true(file.exists(file.path(scratch_dir, "csv_test.csv")))
})

test_that("scratch_capture with to='rds' saves as RDS", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  test_list <- list(a = 1:5, b = "test")

  suppressMessages(scratch_capture(test_list, "rds_test", to = "rds"))

  scratch_dir <- read_config()$options$data$scratch_dir
  expect_true(file.exists(file.path(scratch_dir, "rds_test.rds")))
})

test_that("scratch_capture with to='text' saves as text", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  test_vector <- c("line1", "line2", "line3")

  suppressMessages(scratch_capture(test_vector, "text_test", to = "text"))

  scratch_dir <- read_config()$options$data$scratch_dir
  expect_true(file.exists(file.path(scratch_dir, "text_test.txt")))
})

test_that("scratch_capture with n limits rows", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  large_data <- data.frame(x = 1:100, y = 101:200)

  suppressMessages(scratch_capture(large_data, "limited_test", to = "csv", n = 10))

  scratch_dir <- read_config()$options$data$scratch_dir
  scratch_captured_file <- file.path(scratch_dir, "limited_test.csv")

  expect_true(file.exists(scratch_captured_file))

  # Read back and check row count
  scratch_captured_data <- read.csv(scratch_captured_file)
  expect_equal(nrow(scratch_captured_data), 10)
})

test_that("scratch_capture returns input invisibly for piping", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  test_data <- data.frame(x = 1:5)

  result <- suppressMessages(test_data |> scratch_capture("pipe_test"))

  expect_equal(result, test_data)
})

test_that("scratch_clean removes scratch files", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create some scratch files
  suppressMessages(scratch_capture(data.frame(x = 1), "file1"))
  suppressMessages(scratch_capture(data.frame(x = 2), "file2"))

  scratch_dir <- read_config()$options$data$scratch_dir

  # Verify files exist
  files_before <- list.files(scratch_dir)
  expect_true(length(files_before) >= 2)

  # Clean scratch
  suppressMessages(scratch_clean())

  # Verify files are gone
  files_after <- list.files(scratch_dir)
  expect_equal(length(files_after), 0)
})

test_that("now returns ISO timestamp", {
  timestamp <- now()

  expect_type(timestamp, "character")
  expect_true(nchar(timestamp) > 0)

  # Should be parseable as datetime
  expect_no_error(as.POSIXct(timestamp))
})

test_that("scratch_capture works without explicit name", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  my_test_data <- data.frame(x = 1:3)

  # Capture should auto-generate name from variable
  result <- suppressMessages(scratch_capture(my_test_data))

  scratch_dir <- read_config()$options$data$scratch_dir
  files <- list.files(scratch_dir)

  # Should have created some file
  expect_true(length(files) > 0)
})
