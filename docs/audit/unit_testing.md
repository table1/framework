# Audit Notes — Testing Suite

Status: IN PROGRESS (Unit 10)

## Configuration & Scaffold Tests
- The majority of tests still assert on `config.yml` creation (`tests/testthat/test-init.R`, `test-scaffold.R`, `test-config*.R`, `test-make_notebook.R`). With 1.0, initialization now writes `settings.yml` + optional `settings/` split files. Update fixtures and expectations so tests reflect the new structure (and add explicit coverage for the `directories.*` schema).
- Many helper configs are written inline via `writeLines(..., "config.yml")`. Introduce helpers to write either filename based on the detection logic—otherwise the test suite will keep drifting when templates change.

## Notebook & Stub Coverage
- `test-make_notebook.R` has good coverage for extension handling but still assumes the default directory is `work/` and checks legacy `options.notebook_dir`. Add tests for the new `directories.notebooks` and `directories.scripts` fields, plus coverage for author placeholder substitution using `settings.yml`.
- No tests exercise `stubs_publish()` permutations or the `list_stubs(type=)` filter; consider adding them to prevent regressions when updating stub discovery.

## CLI & Shell Scripts
- There are zero tests around `cli_install()`, `cli_update()`, or the shell scripts in `inst/bin/`. Even a minimal smoke test (e.g., verify `system.file("bin", "framework-shim")` exists, simulate failure when symlinks unavailable) would catch packaging regressions before release. Add skip-on-Windows integration tests where feasible.
- The CLI’s `framework-global` command set (settings/data/packages subcommands) isn’t exercised; we rely solely on manual testing. Evaluate adding an integration test harness that runs key commands inside a temp project (with `Sys.which("bash")` guard).

## Security & Encryption
- Security audit tests (`test-security_audit.R`) construct `config.yml` fixtures and expect `.gitignore` edits; once the audit is refactored for `settings.yml` they’ll need to be updated. Add cases for the “no git repo” path and non-interactive CLI hook usage.
- Encryption tests (`test-encryption.R`) cover core functions, but there’s no coverage for CLI prompts or `view_detail()` encryption flows. Consider adding tests ensuring non-interactive password retrieval falls back correctly (set `ENCRYPTION_PASSWORD` env var).

## General Testing Gaps
- No tests for documentation generators (`readme-parts/build.R`) or `readme-sync` automation; lint the content or at least assert that README can rebuild without errors.
- Snapshot directories (`tests/testthat/_snaps`) exist but aren’t referenced; confirm whether snapshot-driven tests are planned or remove unused structure.
- CI/automation scripts (if added later) will need tests or at least dry runs; note the absence so we can fill gaps when developing the pipeline.

---

Next actions: refactor fixtures to use `settings.yml`, add coverage for new directory fields & author placeholders, introduce smoke tests for CLI installation, and strengthen security/encryption test scenarios. Mark unit DONE once test updates are scheduled.
