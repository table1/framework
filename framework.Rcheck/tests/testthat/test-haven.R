test_that("can load Stata files directly", {
  skip_if_not_installed("haven")
  fixture_path <- test_path("fixtures/test.dta")
  skip_if_not(file.exists(fixture_path), "Fixture file not found")

  df <- data_read(fixture_path)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 5)
  expect_equal(ncol(df), 4)
  expect_true("id" %in% names(df))
  expect_true("name" %in% names(df))
  expect_true("score" %in% names(df))
})

test_that("can load SPSS files directly", {
  skip_if_not_installed("haven")
  fixture_path <- test_path("fixtures/test.sav")
  skip_if_not(file.exists(fixture_path), "Fixture file not found")

  df <- data_read(fixture_path)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 5)
  expect_equal(ncol(df), 4)
})

test_that("can load SAS transport files directly", {
  skip_if_not_installed("haven")
  fixture_path <- test_path("fixtures/test.xpt")
  skip_if_not(file.exists(fixture_path), "Fixture file not found")

  df <- data_read(fixture_path)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 5)
  expect_equal(ncol(df), 4)
})

test_that("strips haven attributes by default", {
  skip_if_not_installed("haven")
  fixture_path <- test_path("fixtures/test.dta")
  skip_if_not(file.exists(fixture_path), "Fixture file not found")

  df <- data_read(fixture_path)
  # Check that haven attributes are removed
  expect_null(attr(df$score, "label"))
  expect_null(attr(df$score, "format.stata"))
  # Should be plain data.frame, not haven_tibble
  expect_s3_class(df, "data.frame")
  expect_false(inherits(df, "tbl_df"))
})

test_that("preserves haven attributes when keep_attributes = TRUE", {
  skip_if_not_installed("haven")
  fixture_path <- test_path("fixtures/test.dta")
  skip_if_not(file.exists(fixture_path), "Fixture file not found")

  df <- data_read(fixture_path, keep_attributes = TRUE)
  # Should have haven attributes
  expect_true(inherits(df, "tbl_df"))  # haven returns tibbles
  # May have labels or formats (depending on how they were saved)
})

test_that("can load haven files using data_read", {
  skip_if_not_installed("haven")
  fixture_path <- test_path("fixtures/test.dta")
  skip_if_not(file.exists(fixture_path), "Fixture file not found")

  df <- data_read(fixture_path)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 5)
})

test_that("errors on encrypted Stata files", {
  # We don't actually have an encrypted file, but test the logic path
  # This would require mocking, so we'll skip for now
  skip("Encrypted haven files not yet testable")
})

test_that("handles non-existent haven files gracefully", {
  skip_if_not_installed("haven")

  expect_error(
    data_read(test_path("fixtures/nonexistent.dta"))
    # File doesn't exist so it will try to look it up in config, which also doesn't exist
    # Either way, should error
  )
})

test_that("detects Stata format from extension via direct file load", {
  skip_if_not_installed("haven")
  fixture_path <- test_path("fixtures/test.dta")
  skip_if_not(file.exists(fixture_path), "Fixture file not found")

  # Test format detection through the direct file path logic
  df <- data_read(fixture_path)
  expect_s3_class(df, "data.frame")
  # If it loaded successfully, format was detected correctly
})

test_that("detects SPSS format from extension via direct file load", {
  skip_if_not_installed("haven")
  fixture_path <- test_path("fixtures/test.sav")
  skip_if_not(file.exists(fixture_path), "Fixture file not found")

  df <- data_read(fixture_path)
  expect_s3_class(df, "data.frame")
  # If it loaded successfully, format was detected correctly
})

test_that("detects SAS format from extension via direct file load", {
  skip_if_not_installed("haven")
  fixture_path <- test_path("fixtures/test.xpt")
  skip_if_not(file.exists(fixture_path), "Fixture file not found")

  df <- data_read(fixture_path)
  expect_s3_class(df, "data.frame")
  # If it loaded successfully, format was detected correctly
})

test_that("validates keep_attributes parameter", {
  skip_if_not_installed("haven")
  fixture_path <- test_path("fixtures/test.dta")
  skip_if_not(file.exists(fixture_path), "Fixture file not found")

  expect_error(
    data_read(fixture_path, keep_attributes = "yes"),
    "Assertion on 'keep_attributes' failed"
  )

  expect_error(
    data_read(fixture_path, keep_attributes = NULL),
    "Assertion on 'keep_attributes' failed"
  )
})

test_that("passthrough parameters work with haven functions", {
  skip_if_not_installed("haven")
  fixture_path <- test_path("fixtures/test.dta")
  skip_if_not(file.exists(fixture_path), "Fixture file not found")

  # haven::read_dta has encoding parameter
  df <- data_read(fixture_path, encoding = "UTF-8")
  expect_s3_class(df, "data.frame")
})

test_that("data values are correct after loading", {
  skip_if_not_installed("haven")
  fixture_path <- test_path("fixtures/test.dta")
  skip_if_not(file.exists(fixture_path), "Fixture file not found")

  df <- data_read(fixture_path)
  expect_equal(df$id, 1:5)
  expect_equal(df$name, c("Alice", "Bob", "Charlie", "Diana", "Eve"))
  expect_equal(df$score, c(85.5, 92.0, 78.5, 95.0, 88.0))
  # Haven may convert logical to numeric (1/0), both are valid
  expect_true(all(df$pass == 1) || all(df$pass == TRUE))
})

test_that("hash tracking works with haven files", {
  skip_if_not_installed("haven")
  fixture_path <- test_path("fixtures/test.dta")
  skip_if_not(file.exists(fixture_path), "Fixture file not found")

  # This tests the integration with the data tracking system
  df <- data_read(fixture_path)
  expect_s3_class(df, "data.frame")
  # The hash should be calculated and stored in the database
  # (actual hash verification tested in test-data.R)
})
