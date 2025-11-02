# Audit Notes — Session & Initialization Core

Status: IN PROGRESS (Unit 02)

## R/scaffold.R
- `R/scaffold.R:17-62` — Project discovery still hard-stops if neither `settings.yml` nor `settings.yml` is found, but error copy references `init()` only; refresh messaging for v1.0 (include CLI `framework new`, clarify search order).
- `R/scaffold.R:74-104` — `.load_environment()` assumes `dotenv_location` lives at root level; when using environment-scoped configs (`default:`), the key sits under `config$default`, so autodetection fails. Needs environment-aware lookup.
- `R/scaffold.R:121-173` — `.load_functions()` treats `config$options$functions_dir` as list/string, but config template stores `directories$functions`; revisit to avoid duplication and respect multiple directories defined under `directories.functions`.
- `R/scaffold.R:194-234` — Package install loop ignores version pins when `packages` entries are stored as lists with `name`/`auto_attach`; confirm `.get_package_requirements()` preserves `@version` suffix and add tests.
- `R/scaffold.R:279-314` — Function loader `source()`s into global env with `local = FALSE`; consider using package env or providing option to avoid polluting global namespace, document behavior explicitly for 1.0.
- `R/scaffold.R:318-366` — Scaffold history now writes to `framework.db`; ensure git helpers still run from `project_root` and add `withr::with_dir(project_root, …)` plus non-git guards to reduce noise.
- `R/scaffold.R:374-435` — `.check_git_status()` and `.commit_after_scaffold()` duplicate git detection logic; consolidate and ensure commands work on Windows (use `system2` consistently).

## R/init.R
- `R/init.R:11-32` — `.create_init_file()` replaces `{{PROJECT_NAME}}`, `{{PROJECT_TYPE}}`, `{{LINTR}}` but template `inst/templates/init.fr.R` still has `{{STYLER}}`; placeholder is left behind causing `init()` to receive literal braces. Add substitution + template update.
- `R/init.R:35-109` — `.create_config_file()` always writes `settings.yml`; yet `init()` and configure helpers treat `settings.yml` as canonical marker. Decide on single filename (likely `settings.yml`) and update checks.
- `R/init.R:123-170` — `.create_dev_rprofile()` hardcodes `~/code/framework`; expose env var override or detect repo location dynamically.
- `R/init.R:186-274` — `init()` validation uses `config_file <- file.path(target_dir, "settings.yml")`; this blocks re-runs when `settings.yml` exists but `settings.yml` does not. Align detection with `.has_settings_file()` to support default layout.
- `R/init.R:212-272` — Interactive messaging references `configure_connection()` etc., yet those helpers fail without `settings.yml`. Fix helper paths before marketing them in next steps block.
- `R/init.R:452-532` — Template copy loop skips `.env.fr` (intentional) but still copies `.lintr`/`.editorconfig`; verify we’re not overwriting user customizations on re-init with `force = TRUE`.
- `R/init.R:500-612` — Author/default-format updater searches for `^  author:` in YAML; fails when `settings.yml` uses environment scoping (root `default:`). Need deeper YAML edit or note requirement.
- `R/init.R:616-714` — Git initialization uses bare `system("git …")`; switch to `system2` with portable flags and guard against absence of git. Consider returning structured status for CLI feedback.
- `R/init.R:754-808` — `.configure_git_hooks()` edits `settings.yml` via regex replacements (`ai_sync`, `data_security`); update to operate on whichever settings file exists and avoid clobbering comments.

## R/configure.R
- `R/configure.R:28-39` (and throughout) — All configure_* helpers hardcode `config_path <- "settings.yml"` and error if missing. Convert to `.get_settings_file()` usage so they work with default `settings.yml`.
- `R/configure.R:122-171` — `configure_data()` builds nested lists using `eval(parse())`; risky. Replace with iterative list mutation to avoid code injection and to support keys containing hyphens/underscores safely.
- `R/configure.R:216-283` — `configure_connection()` prompts default ports for Postgres/MySQL only; extend to MariaDB/SQL Server to match supported drivers. Also enforce lowercase driver names and validate against supported set.
- `R/configure.R:254-269` — Password suggestion writes `!expr Sys.getenv()` even though docs recommend `env()` syntax. Update output to modern style and escape names with underscores automatically.
- `R/configure.R:317-385` — `configure_packages()` stores entries as `list(name = package, auto_attach = auto_attach)` but drops explicit `version` field; ensure `package` retains `@version` tokens and add validation for GitHub specs.
- `R/configure.R:401-473` — `configure_directories()` prompts to create directories but calls `dir.exists(path)` without normalizing relative to project root; use `file.path(dirname(config_path), path)` to avoid writing outside project when run from subdirectories.

## R/configure_ai.R
- `R/configure_ai.R:20-64` — `configure_ai_agents()` writes to `~/.frameworkrc` but does not create parent directory; ensure file/dir creation with proper permissions and document side effects.
- `R/configure_ai.R:115-166` — `.create_ai_instructions()` blindly copies templates even if user already customized files. Add skip/overwrite prompt or `force` flag for CLI parity.
- `R/configure_ai.R:209-254` — `_update_frameworkrc()` removes prior lines matching `FW_AI_SUPPORT` but leaves trailing blank lines; tidy file rewrite to prevent accidental whitespace growth.

## R/ide_config.R
- `R/ide_config.R:20-72` — VS Code workspace defaults include R settings but no Quarto render configuration for multi-root projects; verify if `quarto.render.previewType` should be `external` for RStudio compatibility.
- `R/ide_config.R:51-79` — `.create_vscode_settings()` overwrites existing settings.json unconditionally; consider merging or backing up existing user config (especially when running `init(force=TRUE)`).
- `R/ide_config.R:94-129` — `.create_ide_configs()` only honors `FW_IDES`; document how users opt-in and consider CLI surface to modify after init.

## R/ai_sync.R
- `R/ai_sync.R:33-64` — Uses `config()` helper; ensure `config` gracefully handles config absence (currently returns reason `config_not_found` but still logs message). Add unit tests covering split-file canonical path.
- `R/ai_sync.R:75-110` — Only looks for canonical file relative to working directory; add option to resolve relative to project root when called from scripts subdir.
- `R/ai_sync.R:117-158` — For non-canonical targets, header inserted without preserving existing front-matter (e.g., YAML). Provide guard to retain leading `---` blocks for docs.

## R/on_load.R & R/zzz.R
- Duplicate `.onAttach` definitions (`R/on_load.R:5-10` and `R/zzz.R:2-14`) — the latter overrides the former. Consolidate into single file and ensure startup messaging (CLI tip) respects `options(framework.silent_attach = TRUE)` or similar toggle.
- `R/zzz.R:5-11` — Startup message includes emoji; confirm behaves in non-UTF terminals or provide option to disable.

---

Next actions: address highlighted critical fixes (config file detection, placeholder substitution, configure_* path logic) then re-run targeted tests. Update this unit to DONE once fixes are scheduled or PRs opened.
