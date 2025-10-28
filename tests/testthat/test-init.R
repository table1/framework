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
  expect_true(file.exists("settings.yml"))
  expect_true(file.exists("framework.db"))
  expect_true(file.exists("TestProject.Rproj"))
  expect_true(file.exists(".gitignore"))

  # Check key directories exist
  expect_true(dir.exists("data"))
  expect_true(dir.exists("functions"))
  expect_false(dir.exists("notebooks"))
  # Presentation projects should NOT have results directory
  expect_false(dir.exists("results"))

  # Check that init.R was deleted after initialization
  expect_false(file.exists("init.R"))
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
  expect_true(file.exists("settings.yml"))
  expect_true(file.exists("framework.db"))

  # Check project structure directories
  expect_true(dir.exists("data"))
  expect_true(dir.exists("data/source"))
  raw_settings <- yaml::read_yaml("settings.yml", eval.expr = FALSE)
  expect_equal(raw_settings$default$author, "settings/author.yml")
  expect_true(file.exists("settings/author.yml"))
  expect_equal(raw_settings$default$packages, "settings/packages.yml")
  expect_true(file.exists("settings/packages.yml"))
  expect_equal(raw_settings$default$directories, "settings/directories.yml")
  expect_true(file.exists("settings/directories.yml"))
  expect_equal(raw_settings$default$options, "settings/options.yml")
  expect_true(file.exists("settings/options.yml"))
  expect_equal(raw_settings$default$data, "settings/data.yml")
  expect_true(file.exists("settings/data.yml"))
  expect_equal(raw_settings$default$connections, "settings/connections.yml")
  expect_true(file.exists("settings/connections.yml"))
  expect_equal(raw_settings$default$security, "settings/security.yml")
  expect_true(file.exists("settings/security.yml"))
  expect_equal(raw_settings$default$ai, "settings/ai.yml")
  expect_true(file.exists("settings/ai.yml"))
  expect_equal(raw_settings$default$git, "settings/git.yml")
  expect_true(file.exists("settings/git.yml"))
  expect_true(dir.exists("data/in_progress"))
  expect_true(dir.exists("data/final"))
  expect_true(dir.exists("results"))
  expect_true(dir.exists("results/public"))
  expect_true(dir.exists("results/private"))
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
  expect_true(file.exists("settings.yml"))
  expect_true(file.exists("framework.db"))

  # Check course structure directories
  expect_true(dir.exists("data"))
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
    lintr = "default"
  ))

  # Check that init.R was deleted after initialization
  expect_false(file.exists("init.R"))

  # Check that settings.yml was created (serves as initialization marker)
  expect_true(file.exists("settings.yml"))

  # Check that .env was NOT created (use make_env() instead)
  expect_false(file.exists(".env"))

  # Check project files created
  expect_true(file.exists("EmptyDirProject.Rproj"))

  # Check that .initiated was NOT created (settings.yml is the marker)
  expect_false(file.exists(".initiated"))

  # Check directory structure
  expect_true(dir.exists("data"))
  expect_true(dir.exists("functions"))
  # Presentation projects should NOT have results directory
  expect_false(dir.exists("results"))
})

test_that("make_init() recreates init.R for reference", {
  test_dir <- create_test_dir()
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    cleanup_test_dir(test_dir)
  })

  setwd(test_dir)

  # Initialize (init.R gets deleted)
  suppressMessages(init(
    project_name = "TestInit",
    type = "project",
    lintr = "default"
  ))

  # init.R should be deleted after initialization
  expect_false(file.exists("init.R"))

  # Use make_init() to recreate it
  suppressMessages(make_init("init.R"))

  # Now init.R should exist
  expect_true(file.exists("init.R"))

  # Read init.R content - should have placeholders (not filled in)
  init_content <- readLines("init.R")
  expect_true(any(grepl("\\{\\{PROJECT_NAME\\}\\}", init_content)))
  expect_true(any(grepl("\\{\\{PROJECT_TYPE\\}\\}", init_content)))
  expect_true(any(grepl("This file was generated by make_init", init_content)))
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
    type = "presentation"
  ))

  # init.R should be deleted after initialization
  expect_false(file.exists("init.R"))
  # But settings.yml should exist (initialization marker)
  expect_true(file.exists("settings.yml"))

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
    type = "presentation"
  ))

  # init.R should be deleted after initialization (even from template)
  expect_false(file.exists("init.R"))
  # settings.yml should exist
  expect_true(file.exists("settings.yml"))

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
    subdir = "subproject"
  ))

  # Check files created in subdirectory
  # init.R should be deleted after initialization
  expect_false(file.exists("subproject/init.R"))
  # settings.yml should exist (initialization marker)
  expect_true(file.exists("subproject/settings.yml"))
  # .env should NOT exist (use make_env() instead)
  expect_false(file.exists("subproject/.env"))
  # Project file should exist
  expect_true(file.exists("subproject/SubProject.Rproj"))
  # .initiated should NOT exist (settings.yml is the marker)
  expect_false(file.exists("subproject/.initiated"))
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
