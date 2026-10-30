ada <- list(
  name = "Ada Lovelace",
  email = "ada@example.edu",
  affiliation = "Analytical Engine Lab",
  orcid = "0000-0002-1825-0097",
  url = "https://ada.example.edu",
  affiliations = list(list(name = "Analytical Engine Lab", department = "Mathematics"))
)

front_matter_author <- function(path) {
  lines <- readLines(path)
  ends <- which(lines == "---")
  yaml::yaml.load(paste(lines[(ends[1] + 1):(ends[2] - 1)], collapse = "\n"))$author
}

test_that("basic author fields keep the one-line author", {
  expect_identical(
    framework:::.author_front_matter(list(name = "Ada", email = "a@x.org", affiliation = "Lab")),
    'author: "Ada"'
  )
  expect_identical(framework:::.author_front_matter(list()), 'author: "Your Name"')
})

test_that("orcid, url, and affiliations give a Quarto author block", {
  lines <- framework:::.author_front_matter(ada)
  expect_identical(lines, c(
    "author:",
    '  - name: "Ada Lovelace"',
    '    email: "ada@example.edu"',
    '    orcid: "0000-0002-1825-0097"',
    '    url: "https://ada.example.edu"',
    "    affiliations:",
    '      - name: "Analytical Engine Lab"',
    '        department: "Mathematics"'
  ))
  parsed <- yaml::yaml.load(paste(lines, collapse = "\n"))$author[[1]]
  expect_identical(parsed$affiliations[[1]]$department, "Mathematics")
})

test_that("an orcid alone falls back to the plain affiliation string", {
  lines <- framework:::.author_front_matter(list(name = "Ada", affiliation = "Lab", orcid = "0000-0001"))
  parsed <- yaml::yaml.load(paste(lines, collapse = "\n"))$author[[1]]
  expect_identical(parsed$affiliations[[1]]$name, "Lab")
})

test_that("quotes and backslashes survive in front matter", {
  author <- list(name = 'Ada "Countess" \\ Lovelace', url = "https://x.org")
  parsed <- yaml::yaml.load(paste(framework:::.author_front_matter(author), collapse = "\n"))
  expect_identical(parsed$author[[1]]$name, author$name)
})

test_that("merging replaces affiliations as a whole list", {
  base <- list(name = "Ada", affiliations = list(list(name = "Old Lab"), list(name = "Other")))
  merged <- framework:::.author_merge(base, list(affiliations = list(list(name = "New Lab"))))
  expect_identical(merged$affiliations, list(list(name = "New Lab")))
  expect_identical(merged$name, "Ada")
  expect_identical(merged$affiliation, "New Lab")
})

test_that("normalizing drops empty and unknown affiliation fields", {
  out <- framework:::.author_normalize(list(
    name = "Ada",
    affiliations = list(list(name = "Lab", city = "", planet = "Earth"), list(department = "No name"))
  ))
  expect_identical(out$affiliations, list(list(name = "Lab")))
  expect_identical(out$affiliation, "Lab")
})

test_that("make_notebook() writes the full author block for Quarto only", {
  cleanup <- setup_isolated_config()
  on.exit(cleanup(), add = TRUE)
  dir <- withr::local_tempdir()
  withr::local_dir(dir)
  dir.create("notebooks")
  yaml::write_yaml(list(default = list(author = ada, directories = list(notebooks = "notebooks"))), "settings.yml")
  writeLines("", ".env")

  suppressMessages(make_notebook("Analysis"))
  author <- front_matter_author("notebooks/analysis.qmd")
  expect_identical(author[[1]]$name, "Ada Lovelace")
  expect_identical(author[[1]]$orcid, "0000-0002-1825-0097")
  expect_identical(author[[1]]$affiliations[[1]]$name, "Analytical Engine Lab")

  suppressMessages(make_revealjs("Talk"))
  expect_identical(front_matter_author("notebooks/talk.qmd")[[1]]$url, "https://ada.example.edu")

  suppressMessages(make_notebook("Old style", type = "rmarkdown"))
  expect_identical(front_matter_author("notebooks/old-style.Rmd"), "Ada Lovelace")
})

test_that("make_notebook() keeps the one-line author with only basic fields", {
  cleanup <- setup_isolated_config()
  on.exit(cleanup(), add = TRUE)
  dir <- withr::local_tempdir()
  withr::local_dir(dir)
  dir.create("notebooks")
  yaml::write_yaml(list(default = list(
    author = list(name = "Ada", email = "a@x.org", affiliation = "Lab"),
    directories = list(notebooks = "notebooks")
  )), "settings.yml")
  writeLines("", ".env")

  suppressMessages(make_notebook("Plain"))
  expect_identical(grep("^author:", readLines("notebooks/plain.qmd"), value = TRUE), 'author: "Ada"')
})

test_that("global author details fill in, without the package placeholders", {
  cleanup <- setup_isolated_config()
  on.exit(cleanup(), add = TRUE)
  yaml::write_yaml(
    list(author = list(name = "Your Name", email = "your.email@example.com", orcid = "0000-0002-1825-0097")),
    file.path(Sys.getenv("FW_CONFIG_HOME"), "settings.yml")
  )
  resolved <- framework:::.author_resolve(list(name = "Ada"))
  expect_identical(resolved$name, "Ada")
  expect_identical(resolved$email, "")
  expect_identical(resolved$orcid, "0000-0002-1825-0097")
})

test_that("rich authors pass the spec and layers schemas", {
  skip_if_not_installed("jsonvalidate")
  schema <- function(name) {
    path <- system.file("schema", name, package = "framework")
    if (!nzchar(path)) path <- testthat::test_path("..", "..", "inst", "schema", name)
    jsonvalidate::json_schema$new(path, engine = "ajv")
  }

  spec <- spec_resolve(list(list(type = "project")), name = "Rich", author = ada)
  expect_identical(spec$author$affiliations[[1]]$department, "Mathematics")
  attr(spec, "conflicts") <- NULL
  expect_true(schema("spec.v1.json")$validate(jsonlite::toJSON(spec, auto_unbox = TRUE, null = "null")))

  envelope <- list(spec_version = 1, name = "Rich", author = ada, layers = list())
  expect_true(schema("layers.v1.json")$validate(jsonlite::toJSON(envelope, auto_unbox = TRUE, null = "null")))

  bad <- envelope
  bad$author$affiliations <- list(list(department = "No name"))
  expect_false(schema("layers.v1.json")$validate(jsonlite::toJSON(bad, auto_unbox = TRUE, null = "null")))
})

test_that("presentation projects and settings keep the author details", {
  cleanup <- setup_isolated_config()
  on.exit(cleanup(), add = TRUE)
  parent <- withr::local_tempdir()
  spec <- spec_resolve(list(list(type = "presentation", git = list(use_git = FALSE))), name = "Talk", author = ada)
  location <- file.path(parent, "talk")
  suppressMessages(project_create(spec, location))

  expect_identical(front_matter_author(file.path(location, "presentation.qmd"))[[1]]$orcid, ada$orcid)
  settings <- yaml::read_yaml(file.path(location, "settings.yml"))
  expect_identical(settings$default$author$affiliations[[1]]$department, "Mathematics")
})
