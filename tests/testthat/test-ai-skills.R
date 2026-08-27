test_that(".ai_skills_for_type returns correct skills per project type", {
  base <- c("framework-workflow", "framework-data", "framework-packages", "framework-outputs")

  expect_equal(.ai_skills_for_type("project"), base)
  expect_equal(.ai_skills_for_type("course"), base)
  expect_equal(.ai_skills_for_type("presentation"), base)
  expect_equal(
    .ai_skills_for_type("project_sensitive"),
    c(base, "framework-sensitive-data")
  )
})


test_that(".ai_install_skills installs skill files", {
  skip_on_cran()

  test_dir <- file.path(tempdir(), "test-skills-install")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(test_dir, recursive = TRUE))

  installed <- suppressMessages(.ai_install_skills(test_dir, "project"))

  expect_true("framework-workflow" %in% installed)
  expect_false("framework-sensitive-data" %in% installed)

  for (skill in installed) {
    skill_file <- file.path(test_dir, ".claude", "skills", skill, "SKILL.md")
    expect_true(file.exists(skill_file))

    content <- readLines(skill_file, warn = FALSE)
    expect_equal(content[1], "---")
    expect_true(any(grepl(paste0("^name: ", skill, "$"), content)))
    expect_true(any(grepl("^description: ", content)))
  }
})


test_that(".ai_install_skills includes sensitive-data skill for sensitive projects", {
  skip_on_cran()

  test_dir <- file.path(tempdir(), "test-skills-sensitive")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(test_dir, recursive = TRUE))

  installed <- suppressMessages(.ai_install_skills(test_dir, "project_sensitive"))

  expect_true("framework-sensitive-data" %in% installed)
  expect_true(file.exists(
    file.path(test_dir, ".claude", "skills", "framework-sensitive-data", "SKILL.md")
  ))
})


test_that("ai_skills_update refreshes skills using project settings", {
  skip_on_cran()

  test_dir <- file.path(tempdir(), "test-skills-update")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(test_dir, recursive = TRUE))

  writeLines(c(
    "default:",
    "  project_type: project"
  ), file.path(test_dir, "settings.yml"))

  installed <- suppressMessages(ai_skills_update(test_dir))
  expect_true(length(installed) >= 4)

  # Tamper with a skill, then update should restore package content
  skill_file <- file.path(test_dir, ".claude", "skills", "framework-data", "SKILL.md")
  writeLines("stale content", skill_file)
  suppressMessages(ai_skills_update(test_dir))
  content <- readLines(skill_file, warn = FALSE)
  expect_true(any(grepl("data_read", content)))
})


test_that(".generate_skills_section lists skills with paths", {
  section <- .generate_skills_section("project_sensitive")

  expect_true(grepl("framework-workflow", section))
  expect_true(grepl("framework-sensitive-data", section))
  expect_true(grepl(".claude/skills/framework-data/SKILL.md", section, fixed = TRUE))
})
