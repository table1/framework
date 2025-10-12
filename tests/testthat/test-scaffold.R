test_that("scaffold() fails fast when not in a Framework project", {
  # Create a temporary empty directory
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))

  # Change to the temporary directory
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(tmp_dir)

  # scaffold() should fail with clear error message
  expect_error(
    scaffold(),
    "Could not locate a Framework project",
    fixed = TRUE
  )

  expect_error(
    scaffold(),
    "scaffold\\(\\) searches for a project by looking for",
    fixed = FALSE  # Use regex for line breaks
  )

  expect_error(
    scaffold(),
    "To create a new project, use: init()",
    fixed = TRUE
  )
})

test_that("scaffold() works when config.yml exists", {
  # Create a temporary directory with minimal config
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))

  # Change to the temporary directory
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(tmp_dir)

  # Create minimal config.yml
  writeLines(
    c(
      "default:",
      "  project_type: project",
      "  directories:",
      "    notebooks: notebooks"
    ),
    "config.yml"
  )

  # Create minimal .env file
  writeLines("", ".env")

  # scaffold() should succeed (may issue warnings about missing dirs, but shouldn't error)
  expect_no_error(scaffold())

  # Should have created the scaffolded marker
  expect_true(file.exists(".framework_scaffolded"))
})

test_that("standardize_wd() returns NULL when project not found", {
  # Create a temporary empty directory
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))

  # Change to the temporary directory
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(tmp_dir)

  # standardize_wd() should return NULL silently
  result <- standardize_wd()
  expect_null(result)
})

test_that("standardize_wd() finds and returns project root", {
  # Create a temporary directory with config.yml
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))

  # Change to the temporary directory
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(tmp_dir)

  # Create config.yml
  writeLines(
    c(
      "default:",
      "  project_type: project"
    ),
    "config.yml"
  )

  # standardize_wd() should return the project root
  result <- standardize_wd()
  expect_equal(normalizePath(result), normalizePath(tmp_dir))
})
