test_that("init creates minimal project structure", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  suppressMessages(init(project_name = "TestProject", project_structure = "minimal"))

  # Check key files exist
  expect_true(file.exists("config.yml"))
  expect_true(file.exists("framework.db"))
  expect_true(file.exists("TestProject.Rproj"))
  expect_true(file.exists(".gitignore"))

  # Check key directories exist
  expect_true(dir.exists("data"))
  expect_true(dir.exists("functions"))
  expect_true(dir.exists("results"))
})

test_that("init creates default project structure", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  suppressMessages(init(project_name = "TestProject", project_structure = "default"))

  # Check key files
  expect_true(file.exists("config.yml"))
  expect_true(file.exists("framework.db"))

  # Check default structure directories
  expect_true(dir.exists("data/source/private"))
  expect_true(dir.exists("data/source/public"))
  expect_true(dir.exists("data/in_progress"))
  expect_true(dir.exists("data/final/private"))
  expect_true(dir.exists("data/final/public"))
  expect_true(dir.exists("work"))
  expect_true(dir.exists("functions"))
  expect_true(dir.exists("settings"))
})

test_that("init creates framework database with correct tables", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  suppressMessages(init(project_name = "TestProject", project_structure = "minimal"))

  expect_true(check_framework_db("framework.db"))
})

test_that("is_initialized returns TRUE for initialized project", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  expect_true(is_initialized())
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

test_that("remove_init removes initialization marker", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  expect_true(is_initialized())

  remove_init()

  expect_false(is_initialized())
})

test_that("init with force=TRUE reinitializes existing project", {
  test_dir <- create_test_project()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Write a test file
  writeLines("test", "test_marker.txt")
  expect_true(file.exists("test_marker.txt"))

  # Reinitialize with force
  suppressMessages(init(project_name = "NewProject", project_structure = "minimal", force = TRUE))

  # Original file should still exist (force doesn't delete user files)
  expect_true(file.exists("test_marker.txt"))

  # But we should have new project file
  expect_true(file.exists("NewProject.Rproj"))
})

test_that("init from empty directory creates all necessary files", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Initialize from empty directory (non-interactive)
  suppressMessages(init(
    project_name = "EmptyDirProject",
    project_structure = "minimal",
    lintr = "default",
    styler = "default",
    interactive = FALSE
  ))

  # Check that init.R was created
  expect_true(file.exists("init.R"))

  # Check that config.yml was created
  expect_true(file.exists("config.yml"))

  # Check that .env was created
  expect_true(file.exists(".env"))

  # Check project files created
  expect_true(file.exists("EmptyDirProject.Rproj"))
  expect_true(file.exists(".initiated"))

  # Check directory structure
  expect_true(dir.exists("data"))
  expect_true(dir.exists("functions"))
  expect_true(dir.exists("results"))
})

test_that("init from empty directory creates correct init.R content", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Initialize
  suppressMessages(init(
    project_name = "TestInit",
    project_structure = "default",
    lintr = "default",
    styler = "default",
    interactive = FALSE
  ))

  # Read init.R content
  init_content <- readLines("init.R")

  # Check placeholders were replaced
  expect_true(any(grepl("TestInit", init_content)))
  expect_true(any(grepl("default", init_content)))
  expect_false(any(grepl("\\{\\{PROJECT_NAME\\}\\}", init_content)))
  expect_false(any(grepl("\\{\\{PROJECT_STRUCTURE\\}\\}", init_content)))
})

test_that("init detects template vs empty directory correctly", {
  # Test 1: Empty directory (no init.R)
  test_dir1 <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir1)
  })

  setwd(test_dir1)

  suppressMessages(init(
    project_name = "Empty",
    project_structure = "minimal",
    interactive = FALSE
  ))

  # Should create init.R
  expect_true(file.exists("init.R"))

  setwd(old_wd)

  # Test 2: Template directory (with init.R)
  test_dir2 <- create_test_dir()
  on.exit({
    cleanup_test_dir(test_dir2)
  }, add = TRUE)

  setwd(test_dir2)

  # Create a dummy init.R (simulating template)
  writeLines("framework::init(project_name = 'Template')", "init.R")

  suppressMessages(init(
    project_name = "Template",
    project_structure = "minimal",
    interactive = FALSE
  ))

  # Should not overwrite init.R
  init_content <- readLines("init.R")
  expect_true(any(grepl("Template", init_content)))

  setwd(old_wd)
})

test_that("init with subdir creates files in subdirectory", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Create subdir
  dir.create("subproject")

  # Initialize in subdirectory
  suppressMessages(init(
    project_name = "SubProject",
    project_structure = "minimal",
    subdir = "subproject",
    interactive = FALSE
  ))

  # Check files created in subdirectory
  expect_true(file.exists("subproject/init.R"))
  expect_true(file.exists("subproject/config.yml"))
  expect_true(file.exists("subproject/.env"))
  expect_true(file.exists("subproject/SubProject.Rproj"))
  expect_true(file.exists("subproject/.initiated"))
})
