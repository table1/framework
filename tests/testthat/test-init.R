# Tests for project initialization helpers
# Note: init() was deprecated and removed - use new_project() instead

test_that(".is_initialized returns FALSE for non-initialized directory", {
  # Skip this test - .is_initialized walks up the directory tree and may find

  # config files from the framework package or other parent directories.
  # This makes it unreliable in test environments.
  skip("Test isolation issue - .is_initialized() searches parent directories")

  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  expect_false(framework:::.is_initialized())
})

test_that(".is_initialized returns TRUE when settings.yml exists", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create a minimal settings.yml
  writeLines("default:\n  project_type: project", "settings.yml")

  expect_true(framework:::.is_initialized())
})
