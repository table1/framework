# Catalog names, data_save() folders, file types, and private paths, matched
# with framework-py

local_data_project <- function(env = parent.frame()) {
  dir <- create_test_project()
  withr::defer(cleanup_test_dir(dir), envir = env)
  withr::local_dir(dir, .local_envir = env)
  dir
}

test_that("data_info() finds nested, mixed, and flat catalog keys", {
  local_data_project()
  writeLines("a,b\n1,2", "inputs/raw/survey.csv")
  writeLines("a,b\n1,2", "inputs/raw/visits.csv")
  writeLines("a,b\n1,2", "inputs/raw/labs.csv")
  cfg <- yaml::read_yaml("settings.yml")
  cfg$default$data <- list(
    inputs = list(
      raw = list(survey = list(path = "inputs/raw/survey.csv", type = "csv")),
      raw.visits = list(path = "inputs/raw/visits.csv", type = "csv")
    ),
    inputs.raw.labs = "inputs/raw/labs.csv"
  )
  yaml::write_yaml(cfg, "settings.yml")

  expect_match(data_info("inputs.raw.survey")$path, "inputs/raw/survey.csv$")
  expect_match(data_info("inputs.raw.visits")$path, "inputs/raw/visits.csv$")
  expect_match(data_info("inputs.raw.labs")$path, "inputs/raw/labs.csv$")
  expect_null(data_info("inputs.raw.missing"))
  expect_equal(nrow(suppressMessages(data_read("inputs.raw.visits"))), 1)

  # data_add() updates a mixed entry where it is
  suppressMessages(data_add("inputs/raw/visits.csv", name = "inputs.raw.visits", type = "csv", locked = FALSE))
  data <- yaml::read_yaml("settings.yml")$default$data
  expect_identical(data$inputs$raw.visits$path, "inputs/raw/visits.csv")
  expect_null(data$inputs$raw$visits)
})

test_that("data_save() uses the longest directory key the name starts with", {
  local_data_project()
  cfg <- yaml::read_yaml("settings.yml")
  cfg$default$directories$inputs_private_raw <- "inputs/private/raw"
  yaml::write_yaml(cfg, "settings.yml")
  df <- data.frame(x = 1:2)

  suppressMessages(data_save(df, "inputs.private.raw.ids", force = TRUE))
  expect_true(file.exists("inputs/private/raw/ids.rds"))
  suppressMessages(data_save(df, "outputs.private.results"))
  expect_true(file.exists("outputs/private/results.rds"))
  suppressMessages(data_save(df, "inputs.raw.wave.one"))
  expect_true(file.exists("inputs/raw/wave_one.rds"))
  expect_error(data_save(df, "nowhere.at.all"), "Unknown directory")
})

test_that("files under any private folder are private", {
  root <- "/proj"
  expect_true(framework:::.data_path_is_private("/proj/inputs/private/raw/x.csv", root))
  expect_true(framework:::.data_path_is_private("/proj/private/x.csv", root))
  expect_false(framework:::.data_path_is_private("/proj/inputs/raw/x.csv", root))
  # Outside the project only the file's folder counts (macOS temp paths
  # start with /private)
  expect_false(framework:::.data_path_is_private("/private/var/tmp/x.csv", root))
  expect_true(framework:::.data_path_is_private("/elsewhere/private/x.csv", root))
})

test_that("data_add() records SPSS portable and SAS transport files by type", {
  local_data_project()
  file.create("inputs/raw/old.por", "inputs/raw/old.xpt")
  suppressMessages(data_add("inputs/raw/old.por", name = "inputs.raw.por", locked = FALSE))
  suppressMessages(data_add("inputs/raw/old.xpt", name = "inputs.raw.xpt", locked = FALSE))
  data <- yaml::read_yaml("settings.yml")$default$data
  expect_identical(data$inputs$raw$por$type, "spss_por")
  expect_identical(data$inputs$raw$xpt$type, "sas_xpt")
})

test_that("scaffold reads source_all_functions from scaffold:", {
  dir <- withr::local_tempdir()
  withr::local_dir(dir)
  dir.create(file.path(dir, "functions"))
  writeLines("fw_test_sourced_fn <- function() 1", file.path(dir, "functions", "f.R"))
  withr::defer(if (exists("fw_test_sourced_fn", envir = globalenv())) {
    rm("fw_test_sourced_fn", envir = globalenv())
  })

  yaml::write_yaml(list(default = list(scaffold = list(source_all_functions = FALSE))),
                   file.path(dir, "settings.yml"))
  suppressMessages(framework:::.load_functions(project_root = dir))
  expect_false(exists("fw_test_sourced_fn", envir = globalenv()))

  yaml::write_yaml(list(default = list(scaffold = list(source_all_functions = TRUE))),
                   file.path(dir, "settings.yml"))
  suppressMessages(framework:::.load_functions(project_root = dir))
  expect_true(exists("fw_test_sourced_fn", envir = globalenv()))
})
