test_that("project_create creates basic project structure", {
  skip_if_not_installed("yaml")
  skip_on_cran()

  # Create temp directory for test
  test_root <- tempfile("framework_test_")
  dir.create(test_root)
  on.exit(unlink(test_root, recursive = TRUE), add = TRUE)

  # Create minimal project
  result <- project_create(
    name = "test_project",
    location = test_root,
    type = "project",
    author = list(name = "Test User", email = "test@example.com", affiliation = "Test Org"),
    directories = list(
      notebooks = "notebooks",
      scripts = "scripts",
      functions = "functions"
    ),
    git = list(use_git = FALSE, hooks = list(), gitignore_content = "*.Rdata\n.Rhistory")
  )

  expect_true(result$success)
  expect_true(dir.exists(result$path))

  # Check config.yml was created
  config_path <- file.path(result$path, "config.yml")
  expect_true(file.exists(config_path))

  # Read and validate config
  config <- yaml::read_yaml(config_path)
  expect_equal(config$default$project_name, "test_project")
  expect_equal(config$default$project_type, "project")
  expect_equal(config$default$author$name, "Test User")
  expect_equal(config$default$author$email, "test@example.com")

  # Check directories were created
  expect_true(dir.exists(file.path(result$path, "notebooks")))
  expect_true(dir.exists(file.path(result$path, "scripts")))
  expect_true(dir.exists(file.path(result$path, "functions")))

  # Check .gitignore was created
  expect_true(file.exists(file.path(result$path, ".gitignore")))
  gitignore <- readLines(file.path(result$path, ".gitignore"))
  expect_true("*.Rdata" %in% gitignore)

  # Check .Rproj file was created
  expect_true(file.exists(file.path(result$path, "test_project.Rproj")))

  # Check scaffold.R was created
  expect_true(file.exists(file.path(result$path, "scaffold.R")))
})

test_that("project_create handles packages configuration", {
  skip_if_not_installed("yaml")
  skip_on_cran()

  test_root <- tempfile("framework_test_")
  dir.create(test_root)
  on.exit(unlink(test_root, recursive = TRUE), add = TRUE)

  result <- project_create(
    name = "test_packages",
    location = test_root,
    type = "project",
    packages = list(
      use_renv = FALSE,
      default_packages = list(
        list(name = "dplyr", source = "cran", auto_attach = TRUE),
        list(name = "ggplot2", source = "cran", auto_attach = TRUE)
      )
    ),
    git = list(use_git = FALSE)
  )

  expect_true(result$success)

  # Read config and check packages
  config <- yaml::read_yaml(file.path(result$path, "config.yml"))
  expect_false(config$default$packages$use_renv)
  expect_length(config$default$packages$default_packages, 2)
  expect_equal(config$default$packages$default_packages[[1]]$name, "dplyr")
  expect_true(config$default$packages$default_packages[[1]]$auto_attach)
})

test_that("project_create handles AI configuration", {
  skip_if_not_installed("yaml")
  skip_on_cran()

  test_root <- tempfile("framework_test_")
  dir.create(test_root)
  on.exit(unlink(test_root, recursive = TRUE), add = TRUE)

  result <- project_create(
    name = "test_ai",
    location = test_root,
    type = "project",
    ai = list(
      enabled = TRUE,
      assistants = c("claude", "agents"),
      canonical_content = "# Test AI Context\n\nThis is a test."
    ),
    git = list(use_git = FALSE)
  )

  expect_true(result$success)

  # Check AI files were created
  expect_true(file.exists(file.path(result$path, "CLAUDE.md")))
  expect_true(file.exists(file.path(result$path, "AGENTS.md")))

  # Check config has AI settings
  config <- yaml::read_yaml(file.path(result$path, "config.yml"))
  expect_true(config$default$ai$enabled)
  expect_equal(config$default$ai$assistants, c("claude", "agents"))
})

test_that("project_create handles scaffold configuration", {
  skip_if_not_installed("yaml")
  skip_on_cran()

  test_root <- tempfile("framework_test_")
  dir.create(test_root)
  on.exit(unlink(test_root, recursive = TRUE), add = TRUE)

  result <- project_create(
    name = "test_scaffold",
    location = test_root,
    type = "project",
    scaffold = list(
      seed_on_scaffold = TRUE,
      seed = "20241109",
      set_theme_on_scaffold = TRUE,
      ggplot_theme = "theme_bw"
    ),
    git = list(use_git = FALSE)
  )

  expect_true(result$success)

  # Check scaffold.R contains seed
  scaffold <- readLines(file.path(result$path, "scaffold.R"))
  expect_true(any(grepl("set.seed\\(20241109\\)", scaffold)))
  expect_true(any(grepl("theme_bw", scaffold)))

  # Check config
  config <- yaml::read_yaml(file.path(result$path, "config.yml"))
  expect_true(config$default$scaffold$seed_on_scaffold)
  expect_equal(config$default$scaffold$seed, "20241109")
  expect_equal(config$default$scaffold$ggplot_theme, "theme_bw")
})

test_that("project_create handles extra directories", {
  skip_if_not_installed("yaml")
  skip_on_cran()

  test_root <- tempfile("framework_test_")
  dir.create(test_root)
  on.exit(unlink(test_root, recursive = TRUE), add = TRUE)

  result <- project_create(
    name = "test_extra_dirs",
    location = test_root,
    type = "project",
    directories = list(notebooks = "notebooks"),
    extra_directories = list(
      list(key = "custom_data", label = "Custom Data", path = "data/custom", type = "input"),
      list(key = "reports", label = "Reports", path = "outputs/reports", type = "output_public")
    ),
    git = list(use_git = FALSE)
  )

  expect_true(result$success)

  # Check extra directories were created
  expect_true(dir.exists(file.path(result$path, "data/custom")))
  expect_true(dir.exists(file.path(result$path, "outputs/reports")))

  # Check config has extra_directories
  config <- yaml::read_yaml(file.path(result$path, "config.yml"))
  expect_length(config$default$extra_directories, 2)
  expect_equal(config$default$extra_directories[[1]]$key, "custom_data")
})

test_that("project_create fails if directory already exists", {
  skip_on_cran()

  test_root <- tempfile("framework_test_")
  dir.create(test_root)
  on.exit(unlink(test_root, recursive = TRUE), add = TRUE)

  # Create first project
  result1 <- project_create(
    name = "duplicate_test",
    location = test_root,
    type = "project",
    git = list(use_git = FALSE)
  )

  expect_true(result1$success)

  # Try to create second project with same name
  expect_error(
    project_create(
      name = "duplicate_test",
      location = test_root,
      type = "project",
      git = list(use_git = FALSE)
    ),
    "already exists"
  )
})

test_that("project_create validates required parameters", {
  expect_error(project_create(name = "", location = "~/test"), "at least 1 characters")
  expect_error(project_create(name = "test", location = ""), "at least 1 characters")
  expect_error(project_create(name = "test", location = "~/test", type = "invalid"), "Must be element of set")
})

test_that("project_create handles different project types", {
  skip_if_not_installed("yaml")
  skip_on_cran()

  test_root <- tempfile("framework_test_")
  dir.create(test_root)
  on.exit(unlink(test_root, recursive = TRUE), add = TRUE)

  # Test each project type
  for (type in c("project", "project_sensitive", "course", "presentation")) {
    result <- project_create(
      name = paste0("test_", type),
      location = test_root,
      type = type,
      git = list(use_git = FALSE)
    )

    expect_true(result$success, info = paste("Failed for type:", type))

    config <- yaml::read_yaml(file.path(result$path, "config.yml"))
    expect_equal(config$default$project_type, type, info = paste("Wrong type in config for:", type))
  }
})
