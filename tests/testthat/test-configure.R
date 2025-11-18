test_that("configure_author updates settings file", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Non-interactive mode
  result <- configure_author(
    name = "Jane Doe",
    email = "jane@example.com",
    affiliation = "Test University",
    interactive = FALSE
  )

  # Check settings were updated
  config <- read_config()
  expect_equal(config$author$name, "Jane Doe")
  expect_equal(config$author$email, "jane@example.com")
  expect_equal(config$author$affiliation, "Test University")

  # Check return value
  expect_true(is.list(result))
})


test_that("configure_data adds data source to settings", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Non-interactive mode
  result <- configure_data(
    path = "inputs.raw.survey",
    file = "inputs/raw/survey.csv",
    type = "csv",
    locked = TRUE,
    interactive = FALSE
  )

  # Check settings were updated
  config <- read_config()
  expect_equal(config$data$inputs$raw$survey$path, "inputs/raw/survey.csv")
  expect_equal(config$data$inputs$raw$survey$type, "csv")
  expect_true(config$data$inputs$raw$survey$locked)

  # Check return value
  expect_true(is.list(result))
})


test_that("configure_data handles simple paths", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Simple path (no nesting)
  result <- configure_data(
    path = "mydata",
    file = "data/mydata.csv",
    type = "csv",
    locked = FALSE,
    interactive = FALSE
  )

  config <- read_config()
  expect_equal(config$data$mydata$path, "data/mydata.csv")
  expect_equal(config$data$mydata$type, "csv")
})


test_that("configure_connection adds SQLite connection", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # SQLite connection
  result <- configure_connection(
    name = "mydb",
    driver = "sqlite",
    database = "data/mydb.db",
    interactive = FALSE
  )

  config <- read_config()
  expect_equal(config$connections$mydb$driver, "sqlite")
  expect_equal(config$connections$mydb$database, "data/mydb.db")

  # Check return value
  expect_true(is.list(result))
})


test_that("configure_connection adds PostgreSQL connection", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # PostgreSQL connection
  result <- configure_connection(
    name = "warehouse",
    driver = "postgresql",
    host = "localhost",
    port = 5432L,
    database = "analytics",
    user = "analyst",
    password = "secret123",
    interactive = FALSE
  )

  config <- read_config()
  expect_equal(config$connections$warehouse$driver, "postgresql")
  expect_equal(config$connections$warehouse$host, "localhost")
  expect_equal(config$connections$warehouse$port, 5432)
  expect_equal(config$connections$warehouse$database, "analytics")
  expect_equal(config$connections$warehouse$user, "analyst")
  expect_equal(config$connections$warehouse$password, "secret123")
})


test_that("configure_packages adds package dependency", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Add CRAN package
  result <- configure_packages(
    package = "dplyr",
    auto_attach = TRUE,
    interactive = FALSE
  )

  config <- read_config()

  # Find dplyr in packages list
  pkg_found <- FALSE
  for (pkg in config$packages) {
    if (is.list(pkg) && pkg$name == "dplyr") {
      expect_true(pkg$auto_attach)
      pkg_found <- TRUE
      break
    }
  }
  expect_true(pkg_found, "dplyr not found in packages list")

  # Check return value
  expect_true(is.list(result))
})


test_that("configure_packages adds GitHub package with version", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Add GitHub package
  result <- configure_packages(
    package = "tidyverse/dplyr@main",
    auto_attach = FALSE,
    interactive = FALSE
  )

  config <- read_config()

  # Find package in list
  pkg_found <- FALSE
  for (pkg in config$packages) {
    if (is.list(pkg) && grepl("tidyverse/dplyr", pkg$name)) {
      expect_false(pkg$auto_attach)
      expect_match(pkg$name, "tidyverse/dplyr@main")
      pkg_found <- TRUE
      break
    }
  }
  expect_true(pkg_found, "tidyverse/dplyr@main not found in packages list")
})


test_that("configure_packages updates existing package", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Add package first time
  configure_packages(
    package = "ggplot2",
    auto_attach = TRUE,
    interactive = FALSE
  )

  # Update it
  result <- configure_packages(
    package = "ggplot2@3.4.0",
    auto_attach = FALSE,
    interactive = FALSE
  )

  config <- read_config()

  # Should only have one ggplot2 entry
  ggplot_count <- 0
  for (pkg in config$packages) {
    if (is.list(pkg) && grepl("ggplot2", pkg$name)) {
      ggplot_count <- ggplot_count + 1
      expect_false(pkg$auto_attach)
      expect_match(pkg$name, "ggplot2@3.4.0")
    }
  }
  expect_equal(ggplot_count, 1)
})


test_that("configure_directories sets directory path", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Set notebooks directory
  result <- configure_directories(
    directory = "notebooks",
    path = "analysis",
    interactive = FALSE
  )

  config <- read_config()
  expect_equal(config$directories$notebooks, "analysis")

  # Check return value
  expect_true(is.list(result))
})


test_that("configure_directories creates new directory entry", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Set custom directory
  result <- configure_directories(
    directory = "custom_dir",
    path = "my_custom_path",
    interactive = FALSE
  )

  config <- read_config()
  expect_equal(config$directories$custom_dir, "my_custom_path")
})


test_that("configure functions require settings file", {
  test_dir <- tempfile()
  dir.create(test_dir, recursive = TRUE)
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    unlink(test_dir, recursive = TRUE)
  })

  setwd(test_dir)

  # All configure functions should fail without settings file
  expect_error(
    configure_author(name = "Test", interactive = FALSE),
    "settings.yml or config.yml not found"
  )

  expect_error(
    configure_data(path = "test", file = "test.csv", type = "csv", interactive = FALSE),
    "settings.yml or config.yml not found"
  )

  expect_error(
    configure_connection(name = "db", driver = "sqlite", database = "test.db", interactive = FALSE),
    "settings.yml or config.yml not found"
  )

  expect_error(
    configure_packages(package = "dplyr", interactive = FALSE),
    "settings.yml or config.yml not found"
  )

  expect_error(
    configure_directories(directory = "notebooks", path = "analysis", interactive = FALSE),
    "settings.yml or config.yml not found"
  )
})


# Tests for .path_to_tilde() helper function
test_that(".path_to_tilde handles NULL and empty paths", {
  # NULL returns NULL
  expect_null(framework:::.path_to_tilde(NULL))

  # Empty string returns empty string
  expect_equal(framework:::.path_to_tilde(""), "")
})


test_that(".path_to_tilde handles paths already with tilde", {
  # Already tilde notation returns unchanged
  expect_equal(framework:::.path_to_tilde("~/code"), "~/code")
  expect_equal(framework:::.path_to_tilde("~/Documents/project"), "~/Documents/project")
  expect_equal(framework:::.path_to_tilde("~"), "~")
})


test_that(".path_to_tilde converts home directory paths to tilde", {
  # Get actual home directory for reliable testing
  home <- path.expand("~")

  # Path under home directory should convert to tilde
  test_path <- file.path(home, "code")
  result <- framework:::.path_to_tilde(test_path)
  expect_match(result, "^~/code$")

  # Nested path under home
  test_path2 <- file.path(home, "Documents", "projects", "my-app")
  result2 <- framework:::.path_to_tilde(test_path2)
  expect_match(result2, "^~/Documents/projects/my-app$")

  # Home directory itself returns just tilde
  result_home <- framework:::.path_to_tilde(home)
  expect_equal(result_home, "~")
})


test_that(".path_to_tilde leaves non-home paths unchanged", {
  # Paths outside home directory should return unchanged
  expect_equal(framework:::.path_to_tilde("/usr/local/bin"), "/usr/local/bin")
  expect_equal(framework:::.path_to_tilde("/tmp/test"), "/tmp/test")
  expect_equal(framework:::.path_to_tilde("/opt/software"), "/opt/software")
})


test_that(".path_to_tilde handles paths with trailing slashes", {
  home <- path.expand("~")

  # Path with trailing slash
  test_path <- paste0(file.path(home, "code"), "/")
  result <- framework:::.path_to_tilde(test_path)
  expect_match(result, "^~/code$")
})
