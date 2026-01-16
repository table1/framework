# Tests for S3 publishing functions
# Note: Most S3 tests require credentials and are skipped in CI

test_that(".resolve_s3_connection finds explicit connection", {
  skip_if_not_installed("aws.s3")

  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create config with S3 connection
  config <- list(
    default = list(
      connections = list(
        my_s3 = list(
          driver = "s3",
          bucket = "test-bucket",
          region = "us-east-1",
          prefix = "test-prefix"
        )
      )
    )
  )

  yaml::write_yaml(config, "config.yml")

  # Set credentials in environment
  withr::local_envvar(
    AWS_ACCESS_KEY_ID = "test-key",
    AWS_SECRET_ACCESS_KEY = "test-secret"
  )

  result <- framework:::.resolve_s3_connection("my_s3")

  expect_equal(result$bucket, "test-bucket")
  expect_equal(result$region, "us-east-1")
  expect_equal(result$prefix, "test-prefix")
  expect_equal(result$access_key, "test-key")
  expect_equal(result$secret_key, "test-secret")
})


test_that(".resolve_s3_connection finds default connection", {
  skip_if_not_installed("aws.s3")

  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create config with default S3 connection
  config <- list(
    default = list(
      connections = list(
        s3_backup = list(
          driver = "s3",
          bucket = "backup-bucket",
          region = "us-west-2"
        ),
        s3_primary = list(
          driver = "s3",
          bucket = "primary-bucket",
          region = "us-east-1",
          default = TRUE
        )
      )
    )
  )

  yaml::write_yaml(config, "config.yml")

  withr::local_envvar(
    AWS_ACCESS_KEY_ID = "test-key",
    AWS_SECRET_ACCESS_KEY = "test-secret"
  )

  # Should find the default connection
  result <- framework:::.resolve_s3_connection(NULL)

  expect_equal(result$bucket, "primary-bucket")
  expect_equal(result$region, "us-east-1")
})


test_that(".resolve_s3_connection errors when connection not found", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  config <- list(
    default = list(
      connections = list(
        framework = list(
          driver = "sqlite",
          database = "framework.db"
        )
      )
    )
  )

  yaml::write_yaml(config, "config.yml")

  expect_error(
    framework:::.resolve_s3_connection("nonexistent"),
    "No S3 connections configured|not found"
  )
})


test_that(".resolve_s3_connection errors when credentials are missing", {
  skip_if_not_installed("aws.s3")

  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # S3 connection exists but no credentials
  config <- list(
    default = list(
      connections = list(
        storage_buckets = list(
          my_s3 = list(
            bucket = "test-bucket",
            region = "us-east-1"
          )
        )
      )
    )
  )

  yaml::write_yaml(config, "settings.yml")

  expect_error(
    framework:::.resolve_s3_connection(NULL),
    "S3 credentials not found"
  )
})


test_that(".resolve_s3_connection errors for non-S3 connection", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  config <- list(
    default = list(
      connections = list(
        framework = list(
          driver = "sqlite",
          database = "framework.db"
        )
      )
    )
  )

  yaml::write_yaml(config, "config.yml")

  expect_error(
    framework:::.resolve_s3_connection("framework"),
    "No S3 connections configured|not an S3 connection"
  )
})


test_that(".resolve_s3_connection errors when missing credentials", {
  skip_if_not_installed("aws.s3")

  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  config <- list(
    default = list(
      connections = list(
        my_s3 = list(
          driver = "s3",
          bucket = "test-bucket",
          region = "us-east-1"
        )
      )
    )
  )

  yaml::write_yaml(config, "config.yml")

  # Clear any existing credentials
  withr::local_envvar(
    AWS_ACCESS_KEY_ID = "",
    AWS_SECRET_ACCESS_KEY = ""
  )

  expect_error(
    framework:::.resolve_s3_connection("my_s3"),
    "credentials not found"
  )
})


test_that(".guess_content_type returns correct MIME types", {
  expect_equal(framework:::.guess_content_type("test.html"), "text/html")
  expect_equal(framework:::.guess_content_type("test.css"), "text/css")
  expect_equal(framework:::.guess_content_type("test.js"), "application/javascript")
  expect_equal(framework:::.guess_content_type("test.json"), "application/json")
  expect_equal(framework:::.guess_content_type("test.csv"), "text/csv")
  expect_equal(framework:::.guess_content_type("test.png"), "image/png")
  expect_equal(framework:::.guess_content_type("test.jpg"), "image/jpeg")
  expect_equal(framework:::.guess_content_type("test.pdf"), "application/pdf")
  expect_equal(framework:::.guess_content_type("test.rds"), "application/octet-stream")
  expect_equal(framework:::.guess_content_type("test.unknown"), "application/octet-stream")
})


test_that(".s3_public_url generates correct AWS URLs", {
  s3_config <- list(
    bucket = "my-bucket",
    region = "us-east-1",
    prefix = "",
    endpoint = NULL
  )

  url <- framework:::.s3_public_url("path/to/file.html", s3_config)
  expect_equal(url, "https://my-bucket.s3.us-east-1.amazonaws.com/path/to/file.html")
})


test_that(".s3_public_url handles custom endpoints", {
  s3_config <- list(
    bucket = "my-bucket",
    region = "us-east-1",
    prefix = "",
    endpoint = "https://minio.example.com"
  )

  url <- framework:::.s3_public_url("path/to/file.html", s3_config)
  expect_equal(url, "https://minio.example.com/my-bucket/path/to/file.html")
})


test_that("publish validates source exists", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create minimal config
  config <- list(
    default = list(
      connections = list(
        my_s3 = list(driver = "s3", bucket = "test", region = "us-east-1", default = TRUE)
      )
    )
  )
  yaml::write_yaml(config, "config.yml")

  expect_error(
    publish("nonexistent_file.txt"),
    "Source not found"
  )
})


test_that("publish_notebook validates file extension", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create a non-qmd file
  writeLines("test", "test.R")

  expect_error(
    publish_notebook("test.R"),
    "extension"
  )
})


test_that("publish_data handles data frames", {
  skip_if_not_installed("aws.s3")

  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create config with S3 connection
  config <- list(
    default = list(
      connections = list(
        my_s3 = list(
          driver = "s3",
          bucket = "test-bucket",
          region = "us-east-1",
          default = TRUE
        )
      )
    )
  )
  yaml::write_yaml(config, "config.yml")

  # This will fail at S3 upload (no real credentials), but we're testing
  # that data frame handling works up to that point
  withr::local_envvar(
    AWS_ACCESS_KEY_ID = "test",
    AWS_SECRET_ACCESS_KEY = "test"
  )

  df <- data.frame(x = 1:3, y = letters[1:3])

  # Should fail at S3 upload, not at data frame handling
expect_error(
    publish_data(df, "test.csv"),
    "S3|upload|403|Access Denied|Forbidden|InvalidAccessKeyId"
  )
})


# Integration tests - only run if S3_TEST_BUCKET is set
test_that("S3 integration tests", {
  skip_if(
    Sys.getenv("S3_TEST_BUCKET") == "",
    "S3_TEST_BUCKET not set - skipping integration tests"
  )

  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create config with test bucket
  config <- list(
    default = list(
      connections = list(
        test_s3 = list(
          driver = "s3",
          bucket = Sys.getenv("S3_TEST_BUCKET"),
          region = Sys.getenv("S3_TEST_REGION", "us-east-1"),
          prefix = paste0("framework-test-", format(Sys.time(), "%Y%m%d%H%M%S")),
          default = TRUE
        )
      )
    )
  )
  yaml::write_yaml(config, "config.yml")

  # Test s3_test()
  expect_true(s3_test())

  # Test publish() with a simple file
  writeLines("Hello, World!", "test.txt")
  url <- publish("test.txt")
  expect_match(url, "test\\.txt$")

  # Test publish_data() with data frame
  df <- data.frame(x = 1:3, y = letters[1:3])
  url <- publish_data(df, "test-data.csv")
  expect_match(url, "test-data\\.csv$")

  # Test publish_list()
  files <- publish_list()
  expect_s3_class(files, "data.frame")
  expect_true(nrow(files) >= 2)

  # Test publish_dir()
  dir.create("test_dir")
  writeLines("file1", "test_dir/file1.txt")
  writeLines("file2", "test_dir/file2.txt")
  urls <- publish_dir("test_dir")
  expect_length(urls, 2)
})
