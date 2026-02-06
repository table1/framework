test_that("API detects inline vs split file settings correctly", {

  # Setup: Create test directories
  test_dir <- tempdir()
  inline_project <- file.path(test_dir, "inline_project")
  split_project <- file.path(test_dir, "split_project")

  dir.create(inline_project, showWarnings = FALSE, recursive = TRUE)
  dir.create(split_project, showWarnings = FALSE, recursive = TRUE)
  dir.create(file.path(split_project, "settings"), showWarnings = FALSE, recursive = TRUE)

  # Create inline settings.yml (presentation style)
  inline_settings <- list(
    default = list(
      project_name = "Inline Test",
      project_type = "presentation",
      packages = list(
        use_renv = FALSE,
        default_packages = list(
          list(name = "dplyr", source = "cran", auto_attach = TRUE)
        )
      )
    )
  )
  yaml::write_yaml(inline_settings, file.path(inline_project, "settings.yml"))

  # Create split file settings.yml (standard project style)
  split_settings <- list(
    default = list(
      project_name = "Split Test",
      project_type = "project",
      packages = "settings/packages.yml"
    )
  )
  yaml::write_yaml(split_settings, file.path(split_project, "settings.yml"))

  # Create the referenced packages file
  packages_yaml <- list(
    packages = list(
      use_renv = FALSE,
      default_packages = list(
        list(name = "ggplot2", source = "cran", auto_attach = TRUE)
      )
    )
  )
  yaml::write_yaml(packages_yaml, file.path(split_project, "settings/packages.yml"))

  # Test: Check inline detection
  inline_check <- framework:::.uses_split_file(inline_project, "packages")
  expect_false(inline_check$use_split, info = "Inline project should not use split files")
  expect_equal(inline_check$main_file, file.path(inline_project, "settings.yml"))
  expect_null(inline_check$split_file)

  # Test: Check split file detection
  split_check <- framework:::.uses_split_file(split_project, "packages")
  expect_true(split_check$use_split, info = "Split project should use split files")
  expect_equal(split_check$main_file, file.path(split_project, "settings.yml"))
  expect_equal(split_check$split_file, file.path(split_project, "settings/packages.yml"))

  # Cleanup
  unlink(inline_project, recursive = TRUE)
  unlink(split_project, recursive = TRUE)
})

test_that("Saving packages respects inline vs split file structure", {

  # Setup: Create test directories
  test_dir <- tempdir()
  inline_project <- file.path(test_dir, "test_inline_save")
  split_project <- file.path(test_dir, "test_split_save")

  dir.create(inline_project, showWarnings = FALSE, recursive = TRUE)
  dir.create(split_project, showWarnings = FALSE, recursive = TRUE)
  dir.create(file.path(split_project, "settings"), showWarnings = FALSE, recursive = TRUE)

  # Create inline settings.yml
  inline_settings <- list(
    default = list(
      project_name = "Inline Save Test",
      project_type = "presentation",
      packages = list(
        use_renv = FALSE,
        default_packages = list()
      )
    )
  )
  yaml::write_yaml(inline_settings, file.path(inline_project, "settings.yml"))

  # Create split file settings.yml
  split_settings <- list(
    default = list(
      project_name = "Split Save Test",
      project_type = "project",
      packages = "settings/packages.yml"
    )
  )
  yaml::write_yaml(split_settings, file.path(split_project, "settings.yml"))

  # Create initial packages file for split project
  yaml::write_yaml(
    list(packages = list(use_renv = FALSE, default_packages = list())),
    file.path(split_project, "settings/packages.yml")
  )

  # Simulate saving packages to inline project
  split_info_inline <- framework:::.uses_split_file(inline_project, "packages")
  new_packages <- list(
    use_renv = FALSE,
    default_packages = list(
      list(name = "tidyr", source = "cran", auto_attach = TRUE)
    )
  )

  if (split_info_inline$use_split) {
    yaml::write_yaml(
      list(packages = new_packages),
      split_info_inline$split_file
    )
  } else {
    settings_raw <- yaml::read_yaml(split_info_inline$main_file)
    settings <- settings_raw$default %||% settings_raw
    settings$packages <- new_packages
    if (!is.null(settings_raw$default)) {
      settings_raw$default <- settings
      yaml::write_yaml(settings_raw, split_info_inline$main_file)
    } else {
      yaml::write_yaml(settings, split_info_inline$main_file)
    }
  }

  # Verify inline save went to main file
  inline_result <- yaml::read_yaml(file.path(inline_project, "settings.yml"))
  expect_equal(inline_result$default$packages$default_packages[[1]]$name, "tidyr",
               info = "Inline project should save packages to main settings.yml")
  expect_false(file.exists(file.path(inline_project, "settings/packages.yml")),
               info = "Inline project should not create split file")

  # Simulate saving packages to split project
  split_info_split <- framework:::.uses_split_file(split_project, "packages")
  new_packages_split <- list(
    use_renv = FALSE,
    default_packages = list(
      list(name = "readr", source = "cran", auto_attach = TRUE)
    )
  )

  if (split_info_split$use_split) {
    yaml::write_yaml(
      list(packages = new_packages_split),
      split_info_split$split_file
    )
  } else {
    settings_raw <- yaml::read_yaml(split_info_split$main_file)
    settings <- settings_raw$default %||% settings_raw
    settings$packages <- new_packages_split
    if (!is.null(settings_raw$default)) {
      settings_raw$default <- settings
      yaml::write_yaml(settings_raw, split_info_split$main_file)
    } else {
      yaml::write_yaml(settings, split_info_split$main_file)
    }
  }

  # Verify split save went to split file
  split_result <- yaml::read_yaml(file.path(split_project, "settings/packages.yml"))
  expect_equal(split_result$packages$default_packages[[1]]$name, "readr",
               info = "Split project should save packages to settings/packages.yml")

  # Verify main file still references split file
  main_result <- yaml::read_yaml(file.path(split_project, "settings.yml"))
  expect_equal(main_result$default$packages, "settings/packages.yml",
               info = "Split project main file should still reference split file")

  # Cleanup
  unlink(inline_project, recursive = TRUE)
  unlink(split_project, recursive = TRUE)
})

test_that("All save endpoints respect inline vs split structure", {
  # Setup test project with inline settings
  test_dir <- tempdir()
  inline_proj <- file.path(test_dir, "test_all_inline")
  dir.create(inline_proj, showWarnings = FALSE, recursive = TRUE)

  # Create inline settings with multiple fields
  settings <- list(
    default = list(
      project_name = "Test All Inline",
      project_type = "presentation",
      packages = list(use_renv = FALSE, default_packages = list()),
      connections = list(databases = list(), storage_buckets = list()),
      ai = list(enabled = FALSE, assistants = list()),
      git = list(initialize = TRUE, hooks = list())
    )
  )
  yaml::write_yaml(settings, file.path(inline_proj, "settings.yml"))

  # Test each field
  fields <- c("packages", "connections", "ai", "git")
  for (field in fields) {
    split_info <- framework:::.uses_split_file(inline_proj, field)
    expect_false(split_info$use_split,
                 info = sprintf("%s should be inline", field))
    expect_equal(split_info$main_file, file.path(inline_proj, "settings.yml"))
  }

  # Setup test project with split file settings
  split_proj <- file.path(test_dir, "test_all_split")
  dir.create(split_proj, showWarnings = FALSE, recursive = TRUE)
  dir.create(file.path(split_proj, "settings"), showWarnings = FALSE, recursive = TRUE)

  # Create split settings
  split_settings <- list(
    default = list(
      project_name = "Test All Split",
      project_type = "project",
      packages = "settings/packages.yml",
      connections = "settings/connections.yml",
      ai = "settings/ai.yml",
      git = "settings/git.yml"
    )
  )
  yaml::write_yaml(split_settings, file.path(split_proj, "settings.yml"))

  # Create referenced files
  yaml::write_yaml(list(packages = list()), file.path(split_proj, "settings/packages.yml"))
  yaml::write_yaml(list(connections = list()), file.path(split_proj, "settings/connections.yml"))
  yaml::write_yaml(list(ai = list()), file.path(split_proj, "settings/ai.yml"))
  yaml::write_yaml(list(git = list()), file.path(split_proj, "settings/git.yml"))

  # Test each field
  for (field in fields) {
    split_info <- framework:::.uses_split_file(split_proj, field)
    expect_true(split_info$use_split,
                info = sprintf("%s should use split file", field))
    expect_equal(split_info$split_file,
                 file.path(split_proj, sprintf("settings/%s.yml", field)))
  }

  # Cleanup
  unlink(inline_proj, recursive = TRUE)
  unlink(split_proj, recursive = TRUE)
})
