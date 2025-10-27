# Audit Notes — Templates & Project Scaffolds

Status: IN PROGRESS (Unit 08)

## Core Settings Templates (`inst/templates/settings*.fr.yml`)
- `inst/templates/settings.fr.yml` still uses the legacy `options.functions_dir` / `options.results.public_dir` schema. The 1.0 config now stores directories under `default.directories.*`; shipping the old structure causes new projects to miss default paths (and makes features like `make_script()` fall back to `scripts/`). Update base template to mirror `settings.project.fr.yml` or refactor to a single source of truth.
- All three project-specific templates (`settings.project.fr.yml`, `settings.course.fr.yml`, `settings.presentation.fr.yml`) reference split files as `settings/...` but the CLI offers a `FW_CONFIG_DIR` override (e.g., `config/`). Consider templating that path or documenting the env var to avoid mismatches when users choose non-default config dirs.

## Init & Scaffold Templates (`inst/templates/init.fr.R`, `scaffold.fr.R`)
- `init.fr.R` calls `framework::init(..., styler = "{{STYLER}}")`; the exported `init()` signature does **not** accept a `styler` parameter, so generated `init.R` files throw “unused argument (styler=…)” as soon as users run them. Remove the placeholder or map to a supported argument.
- `scaffold.fr.R` ships as an empty file with only a comment. That’s fine, but project README still advertises `scaffold.R` as an “Initialization script” (see below). Either flesh out a basic example (e.g., loading custom packages) or adjust docs so expectations match reality.

## Project Skeletons (`inst/project_structure/**`)
- Project README (`inst/project_structure/project/README.md`) instructs users to “Edit `config.yml`”, yet the generated project actually places configuration in `settings.yml` alongside a `settings/` directory. Update the guidance (and similar references in course/presentation variants) to avoid confusion.
- The CLI’s global script detects projects by checking for `framework.db` or `bin/framework`. Fresh scaffolds include neither (they only contain `settings.yml`). Add a lightweight marker (e.g., `bin/framework` wrapper) or align `framework-global` project detection with the files we actually ship.
- `_quarto.yml.fr` lives beside `_rendered/` but the `.gitignore` template still ignores `_rendered/` wholesale. Confirm that freeze / render defaults match the recommended workflow (e.g., storing rendered notebooks under `_rendered/`).

## .gitignore Template (`inst/templates/.gitignore.fr`)
- The template ignores entire private directories (`data/source/private/**`) and then tries to re-include `.gitkeep` via `!data/*/.gitkeep`. Because the directory-level ignore is more specific, the negation never fires—`.gitkeep` files under `data/source/private/` stay untracked, leaving empty directories missing from git. Consider using anchored patterns or `.gitkeep` placement inside `.gitignore` explicitly.
- Cache ignores use `data/cached*` / `data/cached/**`; the `*` variant accidentally ignores files like `data/cached_backup.csv` outside the cache folder. Tighten patterns to `data/cached/` and `data/cached/**`.

## Notebook / Script Stubs (`inst/stubs/**`, `R/make_notebook.R`)
- Default Quarto stub (`notebook-default.qmd`) hardcodes `author: "Your Name"` and swaps `{filename}`, `{date}` placeholders, but the `make_notebook()` replacement only handles literal `!expr config$author$name`. RMarkdown stubs rely on backtick inline R (`` `r config$author$name` ``), so the replacement never triggers—generated notebooks expose raw template code. Teach the generator to handle inline expressions or switch the default stub to plain placeholders.
- Script generator (`R/make_script.R`) still looks at `config$options$script_dir` for custom paths. The new settings template uses `directories.scripts`, so scripts default to `scripts/` even when the config says otherwise. Update `.get_notebook_dir_from_config()` / `make_script()` to prioritise `directories`.

## Miscellaneous
- `framework-cheatsheet.fr.md` and README fragments still mention `config.yml` in several places. Sweep the docs to ensure references match the actual files (settings vs config, presence of `settings/` split files).
- Resources (`resources/`) and results seed directories are empty, which is fine, but consider adding `README.md` placeholders or `.gitkeep` so the purpose of each folder is clear when published.

---

Next actions: modernise the default settings template, remove the stale `styler` argument from `init.fr.R`, fix `.gitignore` negation patterns, and align documentation (README/cheatsheet/CLI detection) with the settings-based project structure. Mark unit DONE when remediation plans are in place.
