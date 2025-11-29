# Tests for init() deprecation
# Note: init() is deprecated - use project_create() instead

test_that("init() shows deprecation warning", {
  # init() should emit a deprecation warning and return invisibly

  expect_warning(
    init(project_name = "TestProject", type = "project"),
    "deprecated"
  )
})

test_that("init() returns NULL invisibly", {
  result <- suppressWarnings(init(project_name = "Test", type = "project"))
  expect_null(result)
})

test_that("is_initialized returns FALSE for non-initialized directory", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  expect_false(is_initialized())
})

test_that("is_initialized returns TRUE when settings.yml exists", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create a minimal settings.yml
  writeLines("default:\n  project_type: project", "settings.yml")

  expect_true(is_initialized())
})
