test_that("make_notebook() detects correct directories", {
  # Create temp directory
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  # Test 1: notebooks/ directory exists
  dir.create("notebooks", showWarnings = FALSE)
  result <- framework:::.get_notebook_dir_from_config()
  expect_equal(result, "notebooks")
  unlink("notebooks", recursive = TRUE)

  # Test 2: work/ directory exists (legacy)
  dir.create("work", showWarnings = FALSE)
  result <- framework:::.get_notebook_dir_from_config()
  expect_equal(result, "work")
  unlink("work", recursive = TRUE)

  # Test 3: both exist - notebooks/ takes precedence
  dir.create("notebooks", showWarnings = FALSE)
  dir.create("work", showWarnings = FALSE)
  result <- framework:::.get_notebook_dir_from_config()
  expect_equal(result, "notebooks")
  unlink("notebooks", recursive = TRUE)
  unlink("work", recursive = TRUE)

  # Test 4: neither exists - defaults to current dir
  result <- framework:::.get_notebook_dir_from_config()
  expect_equal(result, ".")
})

test_that("config.yml directory settings are respected", {
  # Create temp directory with config
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit(setwd(old_wd))

  # Create config with explicit notebook_dir
  config_content <- "default:
  options:
    notebook_dir: my_notebooks
"
  writeLines(config_content, "config.yml")

  # Test notebook dir from config
  result <- framework:::.get_notebook_dir_from_config()
  expect_equal(result, "my_notebooks")

  unlink("config.yml")
})

test_that("slugify converts names correctly", {
  # Test basic slugification
  expect_equal(framework:::.slugify("My Cool Analysis"), "my-cool-analysis")

  # Test special characters
  expect_equal(framework:::.slugify("Data: Processing & Cleaning!"), "data-processing-cleaning")

  # Test consecutive hyphens
  expect_equal(framework:::.slugify("Multiple   Spaces"), "multiple-spaces")

  # Test leading/trailing hyphens
  expect_equal(framework:::.slugify("  trimmed  "), "trimmed")

  # Test already lowercase
  expect_equal(framework:::.slugify("already-slugified"), "already-slugified")

  # Test mixed case
  expect_equal(framework:::.slugify("CamelCaseText"), "camelcasetext")
})

test_that("make_notebook slugifies filenames but preserves titles", {
  # Create temp directory with minimal setup
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit({
    setwd(old_wd)
    unlink(file.path(tmp, "notebooks"), recursive = TRUE)
    unlink(file.path(tmp, "config.yml"))
    unlink(file.path(tmp, ".env"))
  })

  dir.create("notebooks", showWarnings = FALSE)

  # Create minimal config
  config_content <- "default:
  author:
    name: Test User
  directories:
    notebooks: notebooks
"
  writeLines(config_content, "config.yml")
  writeLines("", ".env")

  # Test 1: Name with spaces
  suppressMessages(make_notebook("My Cool Analysis"))
  expect_true(file.exists("notebooks/my-cool-analysis.qmd"))

  content <- readLines("notebooks/my-cool-analysis.qmd")
  title_line <- grep("^title:", content, value = TRUE)
  expect_true(grepl("My Cool Analysis", title_line))

  # Test 2: Special characters
  suppressMessages(make_notebook("Data: Processing!"))
  expect_true(file.exists("notebooks/data-processing.qmd"))

  content2 <- readLines("notebooks/data-processing.qmd")
  title_line2 <- grep("^title:", content2, value = TRUE)
  expect_true(grepl("Data: Processing!", title_line2))
})

test_that("make_notebook creates notebooks with author config reference", {
  # Create temp directory with minimal setup
  tmp <- tempdir()
  old_wd <- getwd()
  setwd(tmp)
  on.exit({
    setwd(old_wd)
    unlink(file.path(tmp, "notebooks"), recursive = TRUE)
    unlink(file.path(tmp, "config.yml"))
    unlink(file.path(tmp, ".env"))
  })

  dir.create("notebooks", showWarnings = FALSE)

  # Create config with author info
  config_content <- "default:
  author:
    name: Dr. Jane Smith
    email: jane@example.com
    affiliation: University
  directories:
    notebooks: notebooks
"
  writeLines(config_content, "config.yml")
  writeLines("", ".env")

  # Create notebook
  suppressMessages(make_notebook("Test Notebook"))

  # Check file was created
  expect_true(file.exists("notebooks/test-notebook.qmd"))

  # Check content
  content <- readLines("notebooks/test-notebook.qmd")

  # Check author line uses config reference
  author_line <- grep("^author:", content, value = TRUE)
  expect_true(grepl("config\\$author\\$name", author_line))

  # Check it doesn't have hardcoded "Your Name"
  expect_false(grepl("Your Name", author_line))

  # Check title is correct
  title_line <- grep("^title:", content, value = TRUE)
  expect_true(grepl("Test Notebook", title_line))

  # Check setup chunk exists with scaffold()
  expect_true(any(grepl("library\\(framework\\)", content)))
  expect_true(any(grepl("scaffold\\(\\)", content)))
})
