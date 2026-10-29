fake_checkout <- function() {
  dir <- withr::local_tempdir(.local_envir = parent.frame())
  dir.create(file.path(dir, ".git"))
  dir.create(file.path(dir, ".github", "workflows"), recursive = TRUE)
  writeLines("name: scaffold", file.path(dir, ".github", "workflows", "framework-scaffold.yml"))
  writeLines("# My Study", file.path(dir, "README.md"))
  dir.create(file.path(dir, ".framework"))
  dir
}

write_layers <- function(dir, layers, name = "My Study") {
  envelope <- list(
    spec_version = 1,
    name = name,
    author = list(name = "Ada Analyst", email = "ada@example.org", affiliation = ""),
    layers = layers
  )
  path <- file.path(dir, ".framework", "layers.json")
  jsonlite::write_json(envelope, path, auto_unbox = TRUE, null = "null")
  path
}

sensitive_layers <- function() {
  list(
    list(kind = "base", key = "project", version = 1, layer = list(type = "project")),
    list(kind = "facet", key = "restricted-data", version = 1, layer = list(
      security = list(sensitive = TRUE),
      directories = list(
        inputs_raw = NULL,
        inputs_private_raw = "inputs/private/raw",
        outputs_private_tables = "outputs/private/tables"
      )
    )),
    list(kind = "facet", key = "manuscript", version = 1, layer = list(
      extra_directories = list(manuscript = list(label = "Manuscript", path = "manuscript")),
      files = list(`manuscript/manuscript.qmd` = list(
        template = TRUE,
        content = "---\ntitle: \"{{project_name}}\"\nauthor: \"{{ author }}\"\n---\n{{< include _common.qmd >}}\n"
      ))
    )),
    list(kind = "facet", key = "claude-code", version = 1, layer = list(
      ai = list(enabled = TRUE, assistants = list(claude = TRUE))
    )),
    list(kind = "facet", key = "codex", version = 1, layer = list(
      ai = list(assistants = list(codex = TRUE))
    )),
    list(kind = "project", key = "my-study", layer = list())
  )
}

test_that("headless creation from a layers file builds the project in a checkout", {
  dir <- fake_checkout()
  layers_file <- write_layers(dir, sensitive_layers())

  result <- suppressMessages(project_create_from_layers(layers_file, path = dir, interactive = FALSE))
  expect_true(result$success)

  expect_true(file.exists(file.path(dir, "settings.yml")))
  expect_true(dir.exists(file.path(dir, "inputs", "private", "raw")))
  expect_false(dir.exists(file.path(dir, "inputs", "raw")))
  expect_true(dir.exists(file.path(dir, "manuscript")))

  # Template placeholders filled; Quarto shortcodes untouched
  qmd <- readLines(file.path(dir, "manuscript", "manuscript.qmd"))
  expect_true("title: \"My Study\"" %in% qmd)
  expect_true("author: \"Ada Analyst\"" %in% qmd)
  expect_true("{{< include _common.qmd >}}" %in% qmd)

  # Headless: no git init, no new workflow files, existing files left alone
  expect_identical(list.files(file.path(dir, ".git")), character())
  expect_identical(list.files(file.path(dir, ".github", "workflows")), "framework-scaffold.yml")

  # Record of how it was made
  record <- jsonlite::read_json(file.path(dir, ".framework", "spec.json"))
  expect_identical(record$name, "My Study")
  expect_true(record$security$sensitive)
  expect_false(is.null(record$source$framework_version))
})

test_that("skills and stubs follow the selected assistants", {
  dir <- fake_checkout()
  suppressMessages(project_create_from_layers(write_layers(dir, sensitive_layers()), path = dir))

  expect_true(file.exists(file.path(dir, ".claude", "skills", "framework-workflow", "SKILL.md")))
  expect_true(file.exists(file.path(dir, ".agents", "skills", "framework-workflow", "SKILL.md")))
  expect_true(file.exists(file.path(dir, ".claude", "skills", "framework-sensitive-data", "SKILL.md")))
  expect_identical(readLines(file.path(dir, "CLAUDE.md")), "@AGENTS.md")
  expect_false(file.exists(file.path(dir, ".github", "copilot-instructions.md")))

  agents <- readLines(file.path(dir, "AGENTS.md"))
  expect_true("# My Study" %in% agents)
  expect_true(any(grepl("framework::scaffold()", agents, fixed = TRUE)))
  expect_true(any(grepl("`inputs/private/`", agents, fixed = TRUE)))
  expect_true("## Project Notes" %in% agents)
})

test_that("sensitive projects get Claude Code deny rules and a fail-closed sandbox", {
  dir <- fake_checkout()
  suppressMessages(project_create_from_layers(write_layers(dir, sensitive_layers()), path = dir))

  settings <- jsonlite::read_json(file.path(dir, ".claude", "settings.json"), simplifyVector = TRUE)
  expect_setequal(settings$permissions$deny, c(
    "Read(/inputs/private/**)", "Edit(/inputs/private/**)",
    "Read(/outputs/private/**)", "Edit(/outputs/private/**)",
    "Read(/.env)"
  ))
  expect_true(settings$sandbox$enabled)
  expect_true(settings$sandbox$failIfUnavailable)
  expect_setequal(settings$sandbox$filesystem$denyRead, c("./inputs/private", "./outputs/private", "./.env"))

  gitignore <- readLines(file.path(dir, ".gitignore"))
  expect_true(any(grepl("Sensitive", gitignore, ignore.case = TRUE)))
})

test_that("non-sensitive projects get no deny rules", {
  dir <- fake_checkout()
  layers <- list(list(kind = "facet", key = "claude-code", layer = list(ai = list(enabled = TRUE, assistants = list(claude = TRUE)))))
  suppressMessages(project_create_from_layers(write_layers(dir, layers), path = dir))
  expect_false(file.exists(file.path(dir, ".claude", "settings.json")))
})

test_that("with no assistants, skills go to .agents/skills only", {
  dir <- fake_checkout()
  layers <- list(list(layer = list(ai = list(enabled = TRUE, assistants = list(claude = FALSE)))))
  suppressMessages(project_create_from_layers(write_layers(dir, layers), path = dir))
  expect_true(dir.exists(file.path(dir, ".agents", "skills", "framework-workflow")))
  expect_false(dir.exists(file.path(dir, ".claude")))
  expect_false(file.exists(file.path(dir, "CLAUDE.md")))
})

test_that("headless creation refuses a checkout with other content", {
  dir <- fake_checkout()
  writeLines("x <- 1", file.path(dir, "analysis.R"))
  expect_error(
    project_create_from_layers(write_layers(dir, list()), path = dir),
    "already contains analysis.R"
  )
})

test_that("headless creation refuses to write workflow files", {
  dir <- fake_checkout()
  layers <- list(list(layer = list(files = list(`.github/workflows/ci.yml` = list(content = "on: push")))))
  expect_error(
    project_create_from_layers(write_layers(dir, layers), path = dir),
    "cannot write workflow files"
  )
})

test_that("an invalid layers file stops with a readable message", {
  dir <- fake_checkout()
  layers <- list(list(layer = list(directories = list(raw = "../outside"))))
  expect_error(
    project_create_from_layers(write_layers(dir, layers), path = dir),
    "must be relative"
  )
})

test_that("project_create() accepts a resolved spec", {
  parent <- withr::local_tempdir()
  spec <- spec_resolve(list(list(git = list(use_git = FALSE))), name = "From spec")
  location <- file.path(parent, "from-spec")
  result <- suppressMessages(project_create(spec, location))
  expect_true(result$success)
  expect_true(file.exists(file.path(location, "settings.yml")))
  expect_true(file.exists(file.path(location, ".framework", "spec.json")))
  expect_error(suppressMessages(project_create(spec, location)), "already exists")
})
