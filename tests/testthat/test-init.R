test_that("init creates presentation project structure", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  suppressMessages(init(project_name = "TestProject", type = "presentation"))

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

test_that("init creates project structure", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  suppressMessages(init(project_name = "TestProject", type = "project"))

  # Check key files
  expect_true(file.exists("config.yml"))
  expect_true(file.exists("framework.db"))

  # Check project structure directories
  expect_true(dir.exists("data/source/private"))
  expect_true(dir.exists("data/source/public"))
  expect_true(dir.exists("data/in_progress"))
  expect_true(dir.exists("data/final/private"))
  expect_true(dir.exists("data/final/public"))
  expect_true(dir.exists("notebooks"))
  expect_true(dir.exists("scripts"))
  expect_true(dir.exists("functions"))
  expect_true(dir.exists("settings"))
  expect_true(dir.exists("docs"))
})

test_that("init creates course project structure", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  suppressMessages(init(project_name = "TestProject", type = "course"))

  # Check key files
  expect_true(file.exists("config.yml"))
  expect_true(file.exists("framework.db"))

  # Check course structure directories
  expect_true(dir.exists("data/cached"))
  expect_true(dir.exists("presentations"))
  expect_true(dir.exists("notebooks"))
  expect_true(dir.exists("functions"))
  expect_true(dir.exists("docs"))

  # Course type should NOT have results directory
  expect_false(dir.exists("results"))

  # Should not have public/private data splits
  expect_false(dir.exists("data/source/private"))
})

test_that("init creates framework database with correct tables", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  suppressMessages(init(project_name = "TestProject", type = "presentation"))

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
  suppressMessages(init(project_name = "NewProject", type = "presentation", force = TRUE))

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
    type = "presentation",
    lintr = "default",
    styler = "default"  ))

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
    type = "project",
    lintr = "default",
    styler = "default"  ))

  # Read init.R content
  init_content <- readLines("init.R")

  # Check placeholders were replaced
  expect_true(any(grepl("TestInit", init_content)))
  expect_true(any(grepl("project", init_content)))
  expect_false(any(grepl("\\{\\{PROJECT_NAME\\}\\}", init_content)))
  expect_false(any(grepl("\\{\\{PROJECT_TYPE\\}\\}", init_content)))
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
    type = "presentation"  ))

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
    type = "presentation"  ))

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
    type = "presentation",
    subdir = "subproject"  ))

  # Check files created in subdirectory
  expect_true(file.exists("subproject/init.R"))
  expect_true(file.exists("subproject/config.yml"))
  expect_true(file.exists("subproject/.env"))
  expect_true(file.exists("subproject/SubProject.Rproj"))
  expect_true(file.exists("subproject/.initiated"))
})

test_that("deprecated project_structure parameter still works", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Test backward compatibility with deprecated parameter
  expect_warning(
    suppressMessages(init(project_name = "TestProject", project_structure = "default")),
    "Parameter 'project_structure' is deprecated"
  )

  # Should map to project type
  expect_true(dir.exists("notebooks"))
  expect_true(dir.exists("scripts"))

  # Clean up for next test
  setwd(old_wd)
  cleanup_test_dir(test_dir)

  test_dir2 <- create_test_dir()
  setwd(test_dir2)
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir2)
  }, add = TRUE)

  # Test minimal -> presentation mapping
  expect_warning(
    suppressMessages(init(project_name = "TestProject", project_structure = "minimal")),
    "Parameter 'project_structure' is deprecated"
  )

  # Should map to presentation type
  expect_true(dir.exists("data"))
  expect_true(dir.exists("functions"))
})

test_that("deprecated 'analysis' type shows warning and maps to 'project'", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Test that analysis type triggers deprecation warning
  expect_warning(
    suppressMessages(init(project_name = "TestProject", type = "analysis")),
    "Type 'analysis' is deprecated"
  )

  # Should create project structure (same as type = "project")
  expect_true(dir.exists("notebooks"))
  expect_true(dir.exists("scripts"))
  expect_true(dir.exists("data/source/private"))
})
