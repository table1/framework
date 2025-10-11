test_that("result_save stores result and creates database record", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  test_result <- data.frame(x = 1:5, y = 6:10)

  suppressMessages(result_save("test_result", test_result, type = "analysis", public = TRUE))

  # Check file exists
  expect_true(file.exists("results/public/test_result.rds"))

  # Check database record
  conn <- DBI::dbConnect(RSQLite::SQLite(), "framework.db")
  on.exit(DBI::dbDisconnect(conn), add = TRUE)

  record <- DBI::dbGetQuery(conn, "SELECT * FROM results WHERE name = 'test_result'")
  expect_equal(nrow(record), 1)
  expect_equal(record$type, "analysis")
  expect_equal(as.logical(record$public), TRUE)
  expect_equal(as.logical(record$blind), FALSE)
})

test_that("result_save stores private results", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  test_result <- list(model = "test", accuracy = 0.95)

  suppressMessages(result_save("private_result", test_result, type = "model", public = FALSE))

  # Check file in private directory
  expect_true(file.exists("results/private/private_result.rds"))
})

test_that("result_get retrieves saved result", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  original_result <- data.frame(a = 1:3, b = 4:6)

  suppressMessages(result_save("retrieve_test", original_result, type = "data", public = TRUE))

  retrieved <- suppressMessages(result_get("retrieve_test"))

  expect_equal(retrieved, original_result)
})

test_that("result_list returns all saved results", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Save multiple results
  suppressMessages(result_save("result1", "data1", type = "type1", public = TRUE))
  suppressMessages(result_save("result2", "data2", type = "type2", public = FALSE))
  suppressMessages(result_save("result3", "data3", type = "type1", public = TRUE))

  results_list <- result_list()

  expect_s3_class(results_list, "data.frame")
  expect_true(nrow(results_list) >= 3)
  expect_true("name" %in% names(results_list))
  expect_true("type" %in% names(results_list))
  expect_true("public" %in% names(results_list))
})

test_that("result_save with comment stores metadata", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  test_data <- "test value"

  suppressMessages(result_save("commented_result", test_data, type = "test",
                                public = TRUE, comment = "This is a test comment"))

  conn <- DBI::dbConnect(RSQLite::SQLite(), "framework.db")
  on.exit(DBI::dbDisconnect(conn), add = TRUE)

  record <- DBI::dbGetQuery(conn, "SELECT * FROM results WHERE name = 'commented_result'")
  expect_equal(record$comment, "This is a test comment")
})

test_that("result_get fails for non-existent result", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  expect_error(result_get("nonexistent_result"))
})

test_that("result_save updates existing result", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Save initial result
  suppressMessages(result_save("update_test", "initial value", type = "test", public = TRUE))

  # Update it
  suppressMessages(result_save("update_test", "updated value", type = "test", public = TRUE))

  # Retrieve and verify
  retrieved <- suppressMessages(result_get("update_test"))
  expect_equal(retrieved, "updated value")

  # Check database has only one record
  conn <- DBI::dbConnect(RSQLite::SQLite(), "framework.db")
  on.exit(DBI::dbDisconnect(conn), add = TRUE)

  records <- DBI::dbGetQuery(conn, "SELECT * FROM results WHERE name = 'update_test'")
  expect_equal(nrow(records), 1)
})

test_that("list_metadata returns framework metadata", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Save some data and results to create metadata
  suppressMessages(result_save("meta_test", "value", type = "test", public = TRUE))

  metadata <- list_metadata()

  expect_s3_class(metadata, "data.frame")
})
