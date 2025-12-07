test_that("data_save registers catalog entries for dot-notation paths", {
  skip_on_cran()

  proj <- create_test_project()
  on.exit(cleanup_test_dir(proj), add = TRUE)

  withr::with_dir(proj, {
    df <- data.frame(x = 1:2, y = letters[1:2])
    expect_error(data_save(df, "inputs.intermediate.saved", locked = FALSE), NA)
    loaded <- data_read("inputs.intermediate.saved")
    expect_equal(nrow(loaded), nrow(df))
    expect_equal(names(loaded), names(df))
  })
})

test_that("parquet files are supported in data catalog", {
  skip_on_cran()
  skip_if_not_installed("arrow")

  proj <- create_test_project()
  on.exit(cleanup_test_dir(proj), add = TRUE)

  withr::with_dir(proj, {
    df <- data.frame(id = 1:3, value = letters[1:3])
    arrow::write_parquet(df, "inputs/raw/customers.parquet")

    expect_silent(data_add("inputs/raw/customers.parquet",
      name = "inputs.raw.customers",
      type = "parquet",
      locked = FALSE
    ))

    loaded <- data_read("inputs.raw.customers")
    expect_equal(df$id, loaded$id)
  })
})

test_that("cache_remember accepts string durations and fractional hours", {
  skip_on_cran()

  proj <- create_test_project()
  on.exit(cleanup_test_dir(proj), add = TRUE)

  withr::with_dir(proj, {
    expect_equal(cache_remember("string_expire", { 1 }, expire_after = "1 day"), 1)
    expect_equal(cache_remember("string_expire_alias", { 2 }, expire = "7 days"), 2)
    expect_equal(cache_remember("fractional_hours", { 3 }, expire_after = 0.1), 3)
    expect_true(is.data.frame(cache_list()))
  })
})

test_that("git_commit handles messages with spaces", {
  skip_on_cran()

  dir <- create_test_dir()
  on.exit(cleanup_test_dir(dir), add = TRUE)

  withr::with_dir(dir, {
    system2("git", "init")
    writeLines("test", "file.txt")
    git_add("file.txt")

    withr::with_envvar(c(
      GIT_AUTHOR_NAME = "Framework Tester",
      GIT_AUTHOR_EMAIL = "tester@example.com",
      GIT_COMMITTER_NAME = "Framework Tester",
      GIT_COMMITTER_EMAIL = "tester@example.com"
    ), {
      expect_error(git_commit("commit with spaces"), NA)
    })
  })
})

test_that("make_notebook supports subdir argument", {
  skip_on_cran()

  proj <- create_test_project()
  on.exit(cleanup_test_dir(proj), add = TRUE)

  withr::with_dir(proj, {
    target <- make_notebook("intro-to-r", subdir = "slides/week-01")
    expect_true(file.exists(target))
    expect_true(grepl("slides/week-01", target))
  })
})

test_that("AI context files are created even when assistants list is empty", {
  skip_on_cran()
  skip_if_not_installed("yaml")

  dir <- tempfile("framework_ai_default_")
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  result <- project_create(
    name = "ai_default",
    location = dir,
    type = "project",
    ai = list(enabled = TRUE, assistants = list()),
    git = list(use_git = FALSE)
  )

  expect_true(result$success)
  expect_true(file.exists(file.path(dir, "CLAUDE.md")))
})
