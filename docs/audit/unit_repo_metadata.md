# Audit Notes — Repo Metadata & Packaging

Status: IN PROGRESS (Unit 01 in overall plan)

## DESCRIPTION
Findings:
- Version is `0.6.7`; align with 1.0 release plan and ensure all dependent metadata (NEWS, README) reflect the new semantic version.
- `Title`/`Description` are terse and don’t surface signature features (project scaffolding, database tooling, security). Rewrite for CRAN-style clarity and keyword coverage.
- Missing recommended fields for modern packages (`URL`, `BugReports`, possibly `Depends` vs. `Imports` rationale). Add GitHub repo/issue tracker URLs.
- `License: MIT + file LICENSE` is correct, but confirm year and copyright owner list before tagging 1.0.
- Review `Imports`/`Suggests` against actual usage (post full audit) to avoid CRAN notes; ensure heavy deps (e.g., `openssl`, `lubridate`) are strictly required.

Actions:
- Draft enhanced Title/Description copy ready for 1.0.
- Update version to `1.0.0` once freeze achieved; reflect in `package.json` and documentation.
- Add `URL` and `BugReports` fields; verify canonical repo path.

## NAMESPACE
Findings:
- Auto-generated via roxygen2; ensure re-run after API surface audit.
- Confirm exported helper aliases (`load_data`, `save_data`) remain supported or deprecate before 1.0.
- Evaluate whether internal-only helpers (`capture_output`, `make_env`, etc.) should be exposed; adjust exports as needed.

Actions:
- After function audit, open tickets for any exports slated for hiding/deprecation.

## LICENSE / LICENSE.md
Findings:
- MIT text standard; year currently `2024`. Decide on rolling year or 2019–2024 style coverage ahead of release.
- `LICENSE.md` adds plain-language summary; confirm README links to it where licensing is first mentioned.

Actions:
- Update year span if necessary; document policy for future releases.
- Verify `LICENSE.md` is still desired in package tarball (CRAN typically expects only `LICENSE`); decide whether to keep as extra doc.

## package.json
Findings:
- Version pinned at `0.1.0` (mismatch with `DESCRIPTION::Version`). Needs synchronization for tooling + release automation.
- `scripts.test` runs `testthat::test_dir('tests')`; consider using `devtools::test()` or `testthat::test_package()` for proper setup.
- `scripts.release` chains clean→docs→test→check; add build/install and optionally git tagging to support npm-driven release workflow.
- No dependencies listed (fine), but ensure Node metadata is actually used; if not, consider documenting rationale to avoid confusion.

Actions:
- Bump `version` to 1.0.0 in sync with R package once release is set.
- Decide whether to keep `package.json` (documented in README?) or migrate scripts to Makefile.
- Optionally add `engines` field to hint at required Node version if CLI generation relies on it.

## Makefile
Findings:
- `.PHONY` list omits `docs`, `release`, `install-quick`, `db-clean`. Add to avoid accidental file target conflicts.
- `help` output lacks `install-quick`, `release`, `db-clean`; add for discoverability.
- `install` target installs `*.tar.gz` after build; guard against multiple tarballs (use `$(lastword $(wildcard framework_*.tar.gz))` or similar).
- Consider adding parameterized `check-fast` (skip vignettes/tests) and `readme` targets to match current workflow.

Actions:
- Extend `help` text, `.PHONY`, and add tarball safety before release.
- Document expectation that users have Docker installed before `db-*` targets.

## build.sh
Findings:
- Nice UX messaging but heavy on emoji; confirm shell environments (e.g., CI, minimal terminals) handle UTF-8.
- Script assumes `devtools` installed; add guard or install hint.
- `R CMD INSTALL *.tar.gz` shares wildcard issue with Makefile.
- Duplicates functionality of Makefile `release`; decide on single source for build pipeline to reduce drift.

Actions:
- Add `set -u`/`set -o pipefail`, guard for required packages, ensure consistent logging.
- Replace wildcard with deterministic tarball capture and optionally add argument parsing (e.g., `--skip-tests`).

## docker-compose.test.yml
Findings:
- Uses `docker-compose` hyphen syntax; document compatibility with newer `docker compose`.
- Ports use nonstandard mappings (54329, 33069, 33070). Verify scripts/tests reference these values explicitly—if not, adjust to defaults.
- SQL Server service commented out; provide instructions for enabling on supported hardware in docs (tests README partially covers).
- Volumes declared for SQL Server even when service disabled; compose may warn—clean up conditional usage.

Actions:
- Add `x-project` extension or env var overrides for ports.
- Ensure `tests/docker/scripts` read port config from env to avoid drift.
- Decide whether to provide ARM-compatible alternative for SQL Server (e.g., Azure container) or mark as unsupported.

## Root Release Artifacts
Findings:
- `framework_0.1.0.tar.gz` checked into repo; confirm whether we want latest CRAN-style tarball committed. Ideally remove from source control.
- `.Rcheck/` directory present; should be gitignored/removed to reduce noise.

Actions:
- Add `framework_*.tar.gz` and `*.Rcheck/` to a release ignore list or clean tree before 1.0.
- If historical tarball is needed, move to `releases/` with README explaining purpose.

---

Next Steps:
- Confirm these notes cover all files in scope, then switch unit status to DONE after addressing/logging fixes.
- When ready, update `docs/audit/02_work_unit_plan.md` entry for this unit.
