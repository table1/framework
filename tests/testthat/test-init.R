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
