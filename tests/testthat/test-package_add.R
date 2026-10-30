local_package_project <- function(settings, split = NULL, env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  withr::local_dir(dir, .local_envir = env)
  yaml::write_yaml(settings, "settings.yml")
  if (!is.null(split)) {
    dir.create("settings")
    yaml::write_yaml(split, "settings/packages.yml")
  }
  dir
}

test_that("package_add() appends to a split packages file", {
  local_package_project(
    list(default = list(project_type = "project", packages = "settings/packages.yml")),
    split = list(packages = list(use_renv = FALSE, default_packages = list(
      list(name = "dplyr", source = "cran", auto_attach = TRUE)
    )))
  )
  suppressMessages(package_add("janitor", install = FALSE))
  suppressMessages(package_add("tidyverse/ggplot2@main", auto_attach = TRUE, install = FALSE))

  pkgs <- yaml::read_yaml("settings/packages.yml")$packages
  expect_false(pkgs$use_renv)
  expect_identical(vapply(pkgs$default_packages, `[[`, "", "name"), c("dplyr", "janitor", "ggplot2"))
  gh <- pkgs$default_packages[[3]]
  expect_identical(gh$source, "github")
  expect_identical(gh$repo, "tidyverse/ggplot2")
  expect_identical(gh$ref, "main")
  expect_true(gh$auto_attach)

  # scaffold() reads the new entries back
  specs <- lapply(framework:::.get_package_list_from_config(settings_read()), framework:::.normalize_package_spec)
  expect_identical(vapply(specs, `[[`, "", "name"), c("dplyr", "janitor", "ggplot2"))
})

test_that("package_add() replaces an existing entry to pin or toggle auto-attach", {
  local_package_project(list(default = list(packages = list(default_packages = list(
    list(name = "dplyr", source = "cran", auto_attach = FALSE)
  )))))
  expect_message(package_add("dplyr@1.1.0", auto_attach = TRUE, install = FALSE), "Updated dplyr")

  pkgs <- yaml::read_yaml("settings.yml")$default$packages$default_packages
  expect_length(pkgs, 1)
  expect_identical(pkgs[[1]]$version, "1.1.0")
  expect_true(pkgs[[1]]$auto_attach)
})

test_that("package_add() handles the older flat list and no packages at all", {
  local_package_project(list(default = list(packages = list("dplyr"))))
  suppressMessages(package_add("janitor", install = FALSE))
  pkgs <- yaml::read_yaml("settings.yml")$default$packages
  expect_identical(pkgs[[1]], "dplyr")
  expect_identical(pkgs[[2]]$name, "janitor")

  local_package_project(list(default = list(project_type = "project")))
  suppressMessages(package_add("janitor", install = FALSE))
  pkgs <- yaml::read_yaml("settings.yml")$default$packages
  expect_identical(pkgs$default_packages[[1]]$name, "janitor")
})

test_that("package_add() needs a project", {
  # The settings lookup walks up the tree, and other tests can leave a
  # settings.yml in the shared temp directory
  testthat::local_mocked_bindings(.get_settings_file = function(...) NULL)
  expect_error(package_add("janitor", install = FALSE), "No settings.yml found")
})

test_that("package_add() installs only when asked", {
  local_package_project(list(default = list(packages = list(default_packages = list()))))
  installed <- NULL
  testthat::local_mocked_bindings(.install_package = function(pkg_spec) installed <<- pkg_spec)
  suppressMessages(package_add("janitor", install = FALSE))
  expect_null(installed)
  suppressMessages(package_add("forcats"))
  expect_identical(installed$name, "forcats")
})

test_that("skills, AI context, and the cheatsheet only call exported functions", {
  ns <- asNamespace("framework")
  exports <- getNamespaceExports(ns)
  root <- system.file(package = "framework")
  templates <- if (dir.exists(file.path(root, "inst"))) file.path(root, "inst", "templates") else file.path(root, "templates")
  files <- c(
    list.files(file.path(templates, "skills"), pattern = "SKILL\\.md$", recursive = TRUE, full.names = TRUE),
    list.files(templates, pattern = "^(ai-context\\..*|framework-cheatsheet)\\.md$", full.names = TRUE)
  )
  expect_gt(length(files), 5)

  reference <- framework:::.generate_function_reference()
  text <- c(unlist(lapply(files, readLines, warn = FALSE)), strsplit(reference, "\n")[[1]])
  # Inline code and code blocks only: calls written as name( with no namespace
  code <- unlist(regmatches(text, gregexpr("(?<![A-Za-z0-9_.:$])[a-z][a-z0-9_]*(?=\\()", text, perl = TRUE)))
  other <- c("dplyr", "ggplot2", "tidyr", "readr", "stringr", "lubridate", "glue", "here", "readxl")
  known <- function(f) {
    f %in% exports || exists(f, envir = baseenv()) ||
      any(vapply(c("utils", "stats", "graphics", "grDevices", "methods", "tools"), function(p) exists(f, envir = asNamespace(p)), logical(1))) ||
      any(vapply(other, function(p) requireNamespace(p, quietly = TRUE) && exists(f, envir = asNamespace(p)), logical(1)))
  }
  placeholders <- c("fit_complex_model", "train_expensive_model", "expensive_computation", "run_analysis")
  unknown <- setdiff(unique(code[!vapply(code, known, logical(1))]), placeholders)
  expect_identical(unknown, character(0))
})
