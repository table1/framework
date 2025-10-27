# Framework 1.0 Action Plan Prompt (for implementation model)

You are taking over implementation for the Framework R package ahead of the 1.0 release. An audit documented key issues across the codebase and supporting docs. Focus on the highest-impact fixes first while keeping changes scoped and testable.

## Priorities

1. **Config Schema Alignment**
   - Replace remaining `settings.yml` assumptions (docs, tests, code, man pages) with the new `settings.yml` + `directories.*` layout.
   - Update generators (`make_notebook`, `make_script`) and tests to honor `directories.notebooks/scripts`.
   - Refresh templates (`settings*.yml`, stubs) and documentation to match the v1.0 defaults.

2. **CLI & Installation Hardening**
   - Add fallback for `cli_install()` when symlinks fail (Windows/non-interactive). Ensure docs/man pages describe the hybrid shim/global design and platform caveats.
   - Improve project detection in `framework-global` (recognize `settings.yml`) and prevent interactive prompts when no TTY.

3. **Security & Audit Fixes**
   - Update `security_audit()` to auto-discover settings files, handle gitless repos gracefully, and normalize `.gitignore` entries. Sync tests and docs.

4. **Cleanup & Automation**
   - Remove committed build artifacts (`framework_0.1.0.tar.gz`, `framework.Rcheck/`), expand `.gitignore` if needed, and document the release workflow (Makefile/scripts).
   - Add a minimal GitHub Actions workflow (R CMD check + lint + shellcheck).

5. **Documentation Refresh**
   - Rebuild README/cheatsheet once code changes land. Ensure CLI docs, philosophy, make_notebook guide, and CLAUDE instructions reference `settings.yml`, new defaults, and 1.0 stability promises.

## Guidelines

- Work in small, reviewable commits. Update existing tests and add new coverage when behavior changes.
- Keep human-facing docs consistent with code (README, cheatsheet, docs/ articles).
- Validate `R CMD check` locally or via CI before tagging the release.

## Action Streams

### 1. Config Schema Alignment

- Sweep `R/`, `tests/testthat/`, `man/`, and `inst/templates/` for hard-coded `settings.yml` references; replace with `settings.yml` and the `directories.*` keys introduced in the audit.
- Ensure loader utilities (`config_configure()`, `config_path_*()`) accept the new schema and warn/upgrade any legacy files when feasible.
- Update scaffolds: `make_notebook()` and `make_script()` must honor `directories.notebooks` and `directories.scripts`; refresh templates and tests to assert the new paths.
- Regenerate quickstart docs, `README`, and cheatsheet snippets that demonstrate configuration defaults.
- Definition of done: all automated tests green, no lingering `settings.yml` mentions in repo-visible content, and the man pages describe `settings.yml`.

### 2. CLI & Installation Hardening

- Add a shim fallback inside `cli_install()` to handle environments that block symlink creation (Windows, locked-down CI). Document behavior in `man/cli_install.Rd` and `docs/cli.md`.
- Update `inst/bin/framework-global` to detect projects via `settings.yml` (not just `settings.yml`) and to exit non-interactively when no TTY is present.
- Expand CLI tests (`tests/testthat/test-cli.R`) to cover detection logic and installer fallbacks; include platform guards so macOS/Linux CI can still execute deterministically.
- Definition of done: CLI installer works in the audit matrix, documentation calls out platform caveats, and tests cover both symlink and shim paths.

### 3. Security & Audit Fixes

- Teach `security_audit()` to discover settings files dynamically (respecting `directories.*`) and to tolerate repos without Git metadata.
- Normalize `.gitignore` handling so reruns are idempotent; ensure results surface actionable messaging in `docs/features/cli_installer.md` or related docs.
- Update or add tests around audit edge cases (missing settings, detached HEAD, nested projects).
- Definition of done: audit runs cleanly on fresh clones, reports meaningful guidance, and test coverage guards regressions.

### 4. Cleanup & Automation

- Remove stale build artifacts (`framework_0.1.0.tar.gz`, `framework.Rcheck/`) and expand `.gitignore` so they cannot return.
- Capture release flow in `docs/release-workflow.md` referencing the Makefile/scripts used to package and smoke-test the release.
- Introduce a GitHub Actions workflow that runs linting, `R CMD check`, and shell validation; ensure it respects optional dependencies or caches as needed.
- Definition of done: repo is clean after `git clean -fdx`, CI passes on fork, and docs match the automated steps.

### 5. Documentation Refresh

- Once code changes stabilize, rebuild README, cheatsheet, and CLI docs to reflect the `settings.yml` schema and stability messaging.
- Update onboarding material (`docs/`, `man/`, `vignettes/`) to cross-link config changes and CLI behavior; prune obsolete instructions.
- Verify that the CLAUDE and AI assistant prompts mention the revised configuration terminology and recommended workflows.
- Definition of done: documentation references only current behavior, examples run smoke tests, and lints/links (e.g., pkgdown) succeed.

## Sequencing & Coordination

- Tackle Config Schema Alignment first; downstream tasks assume the new layout.
- Follow with CLI hardening and Security updates in parallel branches; both depend on the updated config terminology.
- Land Cleanup/Automation before the final documentation sweep so CI validates doc rebuild scripts.
- Before release, run the full audit checklist again to confirm no regressions slipped in.

## Reporting

- After each work stream, note progress in the audit tracker (`docs/audit/`) and flag blockers early.
- Surface any scope creep or risky refactors; keep focus on high-impact fixes required for v1.0 GA.
