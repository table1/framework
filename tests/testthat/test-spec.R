spec_to_json <- function(spec) {
  attr(spec, "conflicts") <- NULL
  jsonlite::toJSON(spec, auto_unbox = TRUE, null = "null")
}

test_that("package defaults alone resolve to a valid spec for every type", {
  for (type in c("project", "project_sensitive", "course", "presentation", "bare")) {
    spec <- spec_resolve(list(list(type = type)), name = "Defaults")
    expect_identical(spec_check(spec), character(), info = type)
    expect_identical(spec$type, type)
    expect_identical(spec$name, "Defaults")
  }
})

test_that("resolved specs validate against spec.v1.json", {
  skip_if_not_installed("jsonvalidate")
  path <- system.file("schema", "spec.v1.json", package = "framework")
  if (!nzchar(path)) path <- testthat::test_path("..", "..", "inst", "schema", "spec.v1.json")
  v <- jsonvalidate::json_schema$new(path, engine = "ajv")

  for (type in c("project", "project_sensitive", "course", "presentation", "bare")) {
    spec <- spec_resolve(list(list(type = type)), name = "Schema check")
    expect_true(v$validate(spec_to_json(spec)), info = type)
  }
})

test_that("later layers win and null removes a map entry", {
  spec <- spec_resolve(
    list(
      list(directories = list(notebooks = "nb", inputs_raw = NULL)),
      list(directories = list(notebooks = "analysis"))
    ),
    name = "Merge"
  )
  expect_identical(spec$directories$notebooks, "analysis")
  expect_false("inputs_raw" %in% names(spec$directories))
  expect_identical(spec$directories$scripts, "scripts")
})

test_that("assistants merge by name, and false removes one", {
  spec <- spec_resolve(
    list(
      list(ai = list(assistants = list(codex = TRUE))),
      list(ai = list(assistants = list(claude = FALSE)))
    ),
    name = "Assistants"
  )
  expect_identical(names(spec$ai$assistants), "codex")
})

test_that("atomic entries are replaced whole, not merged field by field", {
  spec <- spec_resolve(
    list(
      list(files = list(`a.R` = list(content = "one", template = TRUE))),
      list(files = list(`a.R` = list(content = "two")))
    ),
    name = "Files"
  )
  expect_identical(spec$files$`a.R`, list(content = "two"))
})

test_that("packages can be added and removed by name", {
  spec <- spec_resolve(
    list(list(packages = list(default_packages = list(
      targets = list(source = "cran", auto_attach = FALSE),
      dplyr = NULL
    )))),
    name = "Packages"
  )
  expect_true("targets" %in% names(spec$packages$default_packages))
  expect_false("dplyr" %in% names(spec$packages$default_packages))
  expect_true("ggplot2" %in% names(spec$packages$default_packages))
})

test_that("gitignore text is appended with a label, after the right template", {
  spec <- spec_resolve(
    list(list(kind = "facet", key = "python", version = 1,
              layer = list(git = list(gitignore_content = ".venv/")))),
    name = "Gitignore"
  )
  gi <- spec$git$gitignore_content
  expect_match(gi, "Framework Research Project", fixed = TRUE)
  expect_match(gi, "# --- from facet python v1 ---\n.venv/", fixed = TRUE)
})

test_that("security.sensitive picks the sensitive gitignore on any type", {
  spec <- spec_resolve(list(list(security = list(sensitive = TRUE))), name = "Sensitive")
  expect_true(spec$security$sensitive)
  expect_identical(spec$type, "project")
  template <- readLines(system.file("templates", "gitignore-sensitive", package = "framework"), n = 3)
  expect_true(startsWith(spec$git$gitignore_content, paste(template, collapse = "\n")))
})

test_that("the last layer that sets type wins and drives the defaults", {
  spec <- spec_resolve(list(list(type = "course"), list(type = "presentation")), name = "Type")
  expect_identical(spec$type, "presentation")
  expect_true("presentation_source" %in% names(spec$directories))
})

test_that("name and author arguments override the layers", {
  spec <- spec_resolve(
    list(list(name = "From layer", author = list(name = "Layer", email = "l@x.org", affiliation = "L"))),
    name = "From argument",
    author = list(name = "Arg")
  )
  expect_identical(spec$name, "From argument")
  expect_identical(spec$author$name, "Arg")
  expect_identical(spec$author$email, "l@x.org")
})

test_that("conflicts list keys set by more than one layer", {
  spec <- spec_resolve(
    list(
      list(kind = "facet", key = "a", layer = list(directories = list(slides = "slides"))),
      list(kind = "facet", key = "b", layer = list(directories = list(slides = "talks")))
    ),
    name = "Conflicts"
  )
  conflicts <- attr(spec, "conflicts")
  expect_identical(conflicts$path, "directories/slides")
  expect_identical(conflicts$layers, "facet a, facet b")
})

test_that("unsafe paths and bad skills make resolution fail", {
  expect_error(
    spec_resolve(list(list(files = list(`../escape.R` = list(content = "x")))), name = "Bad"),
    "must be relative"
  )
  expect_error(
    spec_resolve(list(list(directories = list(raw = "/etc"))), name = "Bad"),
    "must be relative"
  )
  expect_error(
    spec_resolve(list(list(skills = list(`my-skill` = list(content = "---\nname: other\n---\nbody")))), name = "Bad"),
    "frontmatter name is 'other'"
  )
  expect_error(
    spec_resolve(list(list(skills = list(`not-shipped` = list(package = TRUE)))), name = "Bad"),
    "not shipped"
  )
})

test_that("check = FALSE returns an invalid spec without stopping", {
  spec <- spec_resolve(list(list(directories = list(raw = "/etc"))), name = "Unchecked", check = FALSE)
  expect_match(spec_check(spec), "must be relative", all = FALSE)
})

test_that("JSON nulls and empty objects from a layers file are handled", {
  json <- '{"directories": {"inputs_raw": null}, "files": [], "skills": {}}'
  layer <- jsonlite::fromJSON(json, simplifyVector = FALSE)
  spec <- spec_resolve(list(layer), name = "JSON")
  expect_false("inputs_raw" %in% names(spec$directories))
  expect_identical(length(spec$files), 0L)
  expect_true("framework-workflow" %in% names(spec$skills))
})

test_that("layers using list shapes for keyed sections are rejected", {
  expect_error(
    spec_resolve(list(list(kind = "facet", key = "codex", layer = list(ai = list(assistants = list("codex"))))), name = "Old"),
    "Layer 'facet codex': ai.assistants must be an object keyed by name"
  )
  expect_error(
    spec_resolve(list(list(extra_directories = list(list(key = "slides", path = "slides")))), name = "Old"),
    "extra_directories must be an object keyed by name"
  )
})
