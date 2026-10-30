# framework 1.1.1

* Fixed (security): projects created with `new()`, `new_project()`, and the
  other `new_*()` helpers got no `.gitignore`, so the initial commit
  included `.env`, which holds database passwords and other secrets. Every
  project now gets the `.gitignore` for its type, and project creation
  asks git whether `.env` is ignored before the first commit (a later
  `!.env` line in `.gitignore` no longer slips through). If you created a
  project with 1.1.0 and put real passwords in its `.env`, untrack it
  (`git rm --cached .env`), add `.env` to `.gitignore`, and change those
  passwords, because they remain in the git history
* Fixed: `new_project()` and related helpers no longer open the setup GUI
  when no global settings exist. That needed the optional `plumber` package
  and blocked in scripts. They now create the default settings instead
* Fixed: `scaffold()` never set the random seed for new projects, which
  store `seed_on_scaffold` and `seed` under `scaffold:`. A project's own seed
  now also takes precedence over the user-wide `FW_SEED`, and
  `seed_on_scaffold: false` turns seeding off even when `FW_SEED` is set
* Fixed: `data_add()` recorded absolute paths in the data catalog, which
  broke once a project was moved or cloned. Paths inside the project are now
  stored relative to the project root
* The package's GitHub repository moved to `frameworktools/framework`
* `git_security_audit()` has a new `secrets_exposure` check that fails when
  git tracks a `.env` file

# framework 1.1.0

* `plumber` moved from Imports to Suggests. plumber pulls in `sodium`, which
  needs the system libsodium library and often fails to install on HPC
  clusters. The GUI (`gui()`, `setup()`) now asks you to install plumber when
  you launch it; nothing else needs it
* New standard `logs` directory for run logs and cluster job output. All
  project gitignore templates now ignore `**/logs/**` and `slurm-*.out`, and
  `security_audit()` treats `logs` as a private directory
* `scaffold()` git checks are now portable across platforms
* Skills-based AI context: new projects get a thin canonical `AGENTS.md` plus
  Framework skills installed in `.claude/skills/` (workflow, data, packages,
  outputs, and sensitive-data rules as separate SKILL.md files)
* `AGENTS.md` replaces `CLAUDE.md` as the default canonical AI context file;
  CLAUDE.md and .github/copilot-instructions.md are now thin pointer stubs
* New `ai_skills_update()` refreshes a project's Framework skills after
  upgrading the package
* `ai_regenerate_context()` falls back to `CLAUDE.md` for projects created
  before 1.1.0

# framework 1.0.0

* First stable release
* Zero CRAN check errors/warnings (1 acceptable note for global config object)
* Complete documentation for all exported functions
* Comprehensive test suite (300+ tests)

# framework 0.10.1

* Fixed non-ASCII characters in R source files for CRAN compatibility
* Fixed documentation for `subdir` parameter in `make_rmd()`, `make_revealjs()`, and `make_presentation()`
* Added missing package declarations to DESCRIPTION Suggests
* Improved `scratch_capture()` examples with `\dontrun{}`

# framework 0.10.0

* Initial preparation for CRAN submission
* Comprehensive data management system with declarative YAML catalogs
* SQLite, PostgreSQL, MySQL, DuckDB database connectivity
* Quarto-first notebook generation with stub templates
* S3-compatible object storage publishing
* Project scaffolding with reproducible environments
* Caching system with expiration support
* Git hooks integration for data security
* GUI for project management (via `gui()`)
