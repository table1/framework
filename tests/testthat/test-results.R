test_that("save_result stores result and creates database record", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  test_result <- data.frame(x = 1:5, y = 6:10)

  suppressMessages(save_result("test_result", test_result, type = "analysis", public = TRUE))

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

test_that("save_result stores private results", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  test_result <- list(model = "test", accuracy = 0.95)

  suppressMessages(save_result("private_result", test_result, type = "model", public = FALSE))

  # Check file in private directory
  expect_true(file.exists("results/private/private_result.rds"))
})

test_that("get_result retrieves saved result", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  original_result <- data.frame(a = 1:3, b = 4:6)

  suppressMessages(save_result("retrieve_test", original_result, type = "data", public = TRUE))

  retrieved <- suppressMessages(get_result("retrieve_test"))

  expect_equal(retrieved, original_result)
})

test_that("list_results returns all saved results", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Save multiple results
  suppressMessages(save_result("result1", "data1", type = "type1", public = TRUE))
  suppressMessages(save_result("result2", "data2", type = "type2", public = FALSE))
  suppressMessages(save_result("result3", "data3", type = "type1", public = TRUE))

  results_list <- list_results()

  expect_s3_class(results_list, "data.frame")
  expect_true(nrow(results_list) >= 3)
  expect_true("name" %in% names(results_list))
  expect_true("type" %in% names(results_list))
  expect_true("public" %in% names(results_list))
})

test_that("save_result with comment stores metadata", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  test_data <- "test value"

  suppressMessages(save_result("commented_result", test_data, type = "test",
                                public = TRUE, comment = "This is a test comment"))

  conn <- DBI::dbConnect(RSQLite::SQLite(), "framework.db")
  on.exit(DBI::dbDisconnect(conn), add = TRUE)

  record <- DBI::dbGetQuery(conn, "SELECT * FROM results WHERE name = 'commented_result'")
  expect_equal(record$comment, "This is a test comment")
})

test_that("get_result fails for non-existent result", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  expect_error(get_result("nonexistent_result"))
})

test_that("save_result updates existing result", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Save initial result
  suppressMessages(save_result("update_test", "initial value", type = "test", public = TRUE))

  # Update it
  suppressMessages(save_result("update_test", "updated value", type = "test", public = TRUE))

  # Retrieve and verify
  retrieved <- suppressMessages(get_result("update_test"))
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
  suppressMessages(save_result("meta_test", "value", type = "test", public = TRUE))

  metadata <- list_metadata()

  expect_s3_class(metadata, "data.frame")
})
