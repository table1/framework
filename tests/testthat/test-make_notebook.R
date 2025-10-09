test_that("normalize_notebook_name detects extensions correctly", {
  # Test .qmd extension
  result <- framework:::.normalize_notebook_name("test.qmd", "quarto")
  expect_equal(result$name, "test.qmd")
  expect_equal(result$type, "quarto")
  expect_equal(result$ext, "qmd")

  # Test .Rmd extension
  result <- framework:::.normalize_notebook_name("test.Rmd", "quarto")
  expect_equal(result$name, "test.Rmd")
  expect_equal(result$type, "rmarkdown")
  expect_equal(result$ext, "Rmd")

  # Test .R extension
  result <- framework:::.normalize_notebook_name("test.R", "quarto")
  expect_equal(result$name, "test.R")
  expect_equal(result$type, "script")
  expect_equal(result$ext, "R")

  # Test no extension defaults to quarto
  result <- framework:::.normalize_notebook_name("test", "quarto")
  expect_equal(result$name, "test.qmd")
  expect_equal(result$type, "quarto")
  expect_equal(result$ext, "qmd")

  # Test no extension with rmarkdown type
  result <- framework:::.normalize_notebook_name("test", "rmarkdown")
  expect_equal(result$name, "test.Rmd")
  expect_equal(result$type, "rmarkdown")
  expect_equal(result$ext, "Rmd")

  # Test no extension with script type
  result <- framework:::.normalize_notebook_name("test", "script")
  expect_equal(result$name, "test.R")
  expect_equal(result$type, "script")
  expect_equal(result$ext, "R")
})


test_that("make_notebook creates quarto notebooks", {
  temp_dir <- tempdir()
  old_wd <- setwd(temp_dir)
  on.exit(setwd(old_wd))

  # Create a temporary work directory
  work_dir <- file.path(temp_dir, "work")
  dir.create(work_dir, showWarnings = FALSE)

  # Create notebook
  path <- make_notebook("test-notebook", dir = work_dir)

  expect_true(file.exists(path))
  expect_equal(basename(path), "test-notebook.qmd")
  expect_true(grepl("work", path))

  # Check content
  content <- readLines(path)
  expect_true(any(grepl("title:", content)))
  expect_true(any(grepl("library\\(framework\\)", content)))
  expect_true(any(grepl("scaffold\\(\\)", content)))

  # Cleanup
  unlink(path)
})


test_that("make_notebook creates rmarkdown notebooks", {
  temp_dir <- tempdir()
  old_wd <- setwd(temp_dir)
  on.exit(setwd(old_wd))

  work_dir <- file.path(temp_dir, "work")
  dir.create(work_dir, showWarnings = FALSE)

  # Create notebook with .Rmd extension
  path <- make_notebook("test-notebook.Rmd", dir = work_dir)

  expect_true(file.exists(path))
  expect_equal(basename(path), "test-notebook.Rmd")

  # Check content
  content <- readLines(path)
  expect_true(any(grepl("title:", content)))
  expect_true(any(grepl("library\\(framework\\)", content)))
  expect_true(any(grepl("scaffold\\(\\)", content)))

  # Cleanup
  unlink(path)
})


test_that("make_notebook creates R scripts", {
  temp_dir <- tempdir()
  old_wd <- setwd(temp_dir)
  on.exit(setwd(old_wd))

  work_dir <- file.path(temp_dir, "work")
  dir.create(work_dir, showWarnings = FALSE)

  # Create script
  path <- make_notebook("test-script.R", dir = work_dir)

  expect_true(file.exists(path))
  expect_equal(basename(path), "test-script.R")

  # Check content
  content <- readLines(path)
  expect_true(any(grepl("library\\(framework\\)", content)))
  expect_true(any(grepl("scaffold\\(\\)", content)))

  # Cleanup
  unlink(path)
})


test_that("make_notebook respects overwrite parameter", {
  temp_dir <- tempdir()
  old_wd <- setwd(temp_dir)
  on.exit(setwd(old_wd))

  work_dir <- file.path(temp_dir, "work")
  dir.create(work_dir, showWarnings = FALSE)

  # Create initial notebook
  path <- make_notebook("test-overwrite", dir = work_dir)
  expect_true(file.exists(path))

  # Try to create again without overwrite - should error
  expect_error(
    make_notebook("test-overwrite", dir = work_dir, overwrite = FALSE),
    "File already exists"
  )

  # Create with overwrite = TRUE - should succeed
  path2 <- make_notebook("test-overwrite", dir = work_dir, overwrite = TRUE)
  expect_true(file.exists(path2))
  expect_equal(path, path2)

  # Cleanup
  unlink(path)
})


test_that("make_notebook uses custom stubs when available", {
  temp_dir <- tempdir()
  old_wd <- setwd(temp_dir)
  on.exit(setwd(old_wd))

  work_dir <- file.path(temp_dir, "work")
  stubs_dir <- file.path(temp_dir, "stubs")
  dir.create(work_dir, showWarnings = FALSE)
  dir.create(stubs_dir, showWarnings = FALSE)

  # Create custom stub
  custom_stub <- file.path(stubs_dir, "notebook-custom.qmd")
  writeLines(c(
    "---",
    "title: Custom Stub",
    "---",
    "",
    "This is a custom stub template."
  ), custom_stub)

  # Create notebook with custom stub
  path <- make_notebook("test-custom", stub = "custom", dir = work_dir)

  expect_true(file.exists(path))
  content <- readLines(path)
  expect_true(any(grepl("Custom Stub", content)))
  expect_true(any(grepl("custom stub template", content)))

  # Cleanup
  unlink(path)
  unlink(custom_stub)
})


test_that("list_stubs shows available stubs", {
  stubs <- list_stubs()

  expect_true(is.data.frame(stubs))
  expect_true(all(c("name", "type", "source") %in% names(stubs)))

  # Should have at least default and minimal stubs
  expect_true("default" %in% stubs$name)
  expect_true("minimal" %in% stubs$name)

  # Should have both quarto and rmarkdown types for default
  default_stubs <- stubs[stubs$name == "default", ]
  expect_true("quarto" %in% default_stubs$type)
  expect_true("rmarkdown" %in% default_stubs$type)
})


test_that("list_stubs filters by type", {
  quarto_stubs <- list_stubs(type = "quarto")
  expect_true(all(quarto_stubs$type == "quarto"))

  rmarkdown_stubs <- list_stubs(type = "rmarkdown")
  expect_true(all(rmarkdown_stubs$type == "rmarkdown"))

  script_stubs <- list_stubs(type = "script")
  expect_true(all(script_stubs$type == "script"))
})


test_that("make_notebook placeholder substitution works", {
  temp_dir <- tempdir()
  old_wd <- setwd(temp_dir)
  on.exit(setwd(old_wd))

  work_dir <- file.path(temp_dir, "work")
  dir.create(work_dir, showWarnings = FALSE)

  # Create notebook
  path <- make_notebook("placeholder-test", dir = work_dir)

  # Check placeholders were replaced
  content <- paste(readLines(path), collapse = "\n")
  expect_true(grepl("placeholder-test", content))  # {filename} replaced
  expect_true(grepl(as.character(Sys.Date()), content))  # {date} replaced
  expect_false(grepl("\\{filename\\}", content))  # No unreplaced placeholders
  expect_false(grepl("\\{date\\}", content))

  # Cleanup
  unlink(path)
})


test_that("make_notebook creates directory if it doesn't exist", {
  temp_dir <- tempdir()
  old_wd <- setwd(temp_dir)
  on.exit(setwd(old_wd))

  new_dir <- file.path(temp_dir, "new_notebooks_dir")

  # Ensure directory doesn't exist
  if (dir.exists(new_dir)) {
    unlink(new_dir, recursive = TRUE)
  }

  # Create notebook in non-existent directory
  path <- make_notebook("test-new-dir", dir = new_dir)

  expect_true(dir.exists(new_dir))
  expect_true(file.exists(path))

  # Cleanup
  unlink(new_dir, recursive = TRUE)
})
