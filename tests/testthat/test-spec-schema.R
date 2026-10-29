schema_path <- function(name) {
  path <- system.file("schema", name, package = "framework")
  if (!nzchar(path)) path <- testthat::test_path("..", "..", "inst", "schema", name)
  path
}

schema_validator <- function(name) {
  testthat::skip_if_not_installed("jsonvalidate")
  jsonvalidate::json_schema$new(schema_path(name), engine = "ajv")
}

as_json <- function(x) jsonlite::toJSON(x, auto_unbox = TRUE, null = "null")

minimal_spec <- function() {
  list(
    spec_version = 1,
    name = "Test project",
    type = "project",
    author = list(name = "A", email = "a@example.com", affiliation = ""),
    directories = list(notebooks = "notebooks", logs = "logs"),
    extra_directories = list(),
    render_dirs = list(notebooks = "outputs/notebooks"),
    packages = list(
      use_renv = FALSE,
      default_packages = list(list(name = "dplyr", source = "cran", auto_attach = TRUE))
    ),
    git = list(use_git = TRUE, hooks = list(ai_sync = FALSE), gitignore_content = ""),
    ai = list(enabled = TRUE, assistants = list("claude"), agents_md = "stub"),
    scaffold = list(
      seed_on_scaffold = FALSE, seed = "", set_theme_on_scaffold = TRUE,
      ggplot_theme = "theme_minimal"
    ),
    connections = list(
      default_database = "framework",
      databases = list(framework = list(driver = "sqlite", database = "framework.db")),
      storage_buckets = setNames(list(), character())
    ),
    security = list(sensitive = FALSE),
    env = setNames(list(), character()),
    data_hooks = setNames(list(), character()),
    files = setNames(list(), character()),
    skills = list(`framework-workflow` = list(package = TRUE))
  )
}

test_that("committed schemas match data-raw/spec_schema.R", {
  generator <- testthat::test_path("..", "..", "data-raw", "spec_schema.R")
  skip_if_not(file.exists(generator), "generator only exists in the source tree")

  out_dir <- withr::local_tempdir()
  withr::with_envvar(c(FW_SCHEMA_OUT = out_dir), {
    withr::with_dir(testthat::test_path("..", ".."), {
      suppressMessages(source("data-raw/spec_schema.R", local = new.env()))
    })
  })

  for (name in c("spec.v1.json", "layer.v1.json")) {
    expect_identical(
      readLines(file.path(out_dir, name)),
      readLines(schema_path(name)),
      info = paste(name, "is stale; run Rscript data-raw/spec_schema.R")
    )
  }
})

test_that("a complete spec validates against the resolved schema", {
  v <- schema_validator("spec.v1.json")
  expect_true(v$validate(as_json(minimal_spec())))
})

test_that("the resolved schema rejects incomplete or malformed specs", {
  v <- schema_validator("spec.v1.json")

  missing_type <- minimal_spec()
  missing_type$type <- NULL
  expect_false(v$validate(as_json(missing_type)))

  unknown_key <- minimal_spec()
  unknown_key$surprise <- TRUE
  expect_false(v$validate(as_json(unknown_key)))

  null_dir <- minimal_spec()
  null_dir$directories$logs <- NA
  expect_false(v$validate(as_json(null_dir)))

  bad_assistant <- minimal_spec()
  bad_assistant$ai$assistants <- list("clippy")
  expect_false(v$validate(as_json(bad_assistant)))
})

test_that("a partial layer validates, and null entries are allowed", {
  v <- schema_validator("layer.v1.json")

  layer <- list(
    directories = list(inputs_raw = NULL, inputs_private_raw = "inputs/private/raw"),
    security = list(sensitive = TRUE),
    skills = list(`framework-sensitive-data` = list(package = TRUE), old = NULL)
  )
  json <- jsonlite::toJSON(layer, auto_unbox = TRUE, null = "null")
  expect_true(v$validate(json))
})

test_that("the layer schema rejects unsafe paths and malformed entries", {
  v <- schema_validator("layer.v1.json")

  expect_false(v$validate(as_json(list(files = list(`../escape.R` = list(content = "x"))))))
  expect_false(v$validate(as_json(list(files = list(`/etc/passwd` = list(content = "x"))))))
  expect_false(v$validate(as_json(list(directories = list(raw = "../outside")))))
  expect_false(v$validate(as_json(list(skills = list(`Bad Name` = list(package = TRUE))))))
  expect_false(v$validate(as_json(list(skills = list(ok = list(package = TRUE, content = "x"))))))
  expect_false(v$validate(as_json(list(packages = list(default_packages = list(list(name = "dplyr")))))))
  expect_false(v$validate(as_json(list(env = list(`BAD-NAME` = "")))))
  expect_false(v$validate(as_json(list(data_hooks = list(inputs_raw = "fetch_raw")))))
})
