# Audit Notes — Security & Encryption

Status: IN PROGRESS (Unit 06)

## Password-Based Encryption (`R/encryption_core.R`, data/results helpers)
- `.get_encryption_password()` (`R/encryption_core.R:59-77`) falls back to `readline()` for prompts, which echoes the password in plaintext. Switch to a non-echoing prompt (`getPass::getPass()` or `rstudioapi::askForPassword()`) and document the dependency so secrets aren’t exposed on screen.
- ✅ File header comments now describe the scrypt-based KDF in `R/encryption_core.R`.
- No env-scoped override for per-call passwords: functions accept `password` argument but there’s no guidance on rotating env vars or using different keys per dataset. Consider adding helper (e.g., `with_encryption_password()`) or documenting best practices.

## Security Audit (`R/security_audit.R`)
- `security_audit()` accepts `config_file`, yet `.get_data_directories()` (`R/security_audit.R:120-162`) hardcodes `config_file = "settings.yml"` in every `config()` call. Projects using `settings.yml` (the default since v0.6) silently skip configured directories. Resolve by passing through the discovered settings file and leveraging `read_config()` / `settings()` helpers.
- Directory lookup keys (`data_source_private`, `data_in_progress_private`, etc.) no longer exist in the v1 config template, so the audit relies solely on fallback paths. Align the key list with the current directory schema (e.g., `directories.cache`, `directories.inputs_raw`, `directories.outputs_private`) and include newly introduced data roots.
- `.check_git_available()` only returns TRUE when both git is installed **and** the repo already has commits (`git rev-parse --git-dir`). Fresh repos with no commits (common in new projects) get an immediate “requires git repository” exit, preventing baseline audits. Detect the repo even before the first commit by checking `.git` directory directly (similar to `.is_git_repo()`).
- `security_audit()` returns `NULL` outright when git isn’t available (`R/security_audit.R:89-107`), so callers expecting a structured result crash (e.g., `audit$summary`). Return a stub result object with statuses marked “skipped” instead.
- Git interactions (`system2("git", ...)`) lack error-context logging; failures (missing git, permissions) swallow the underlying stderr. Capture stderr or bubble up a descriptive error message so users aren’t left guessing.
- `.get_data_directories()` only considers directories whose paths already exist. If a directory is configured but not yet created, it’s ignored, so security audit misses missing-but-configured secrets. Include configured paths even when absent to alert users.
- `.check_git_history()` builds the git log command using `system()` with an interpolated string. If filenames contain spaces/newlines, parsing may break. Use `system2()` with args vector and handle commit/file parsing via `git log --pretty` plus null separators (`-z`) for robustness.
- `.apply_auto_fix()` writes absolute paths into `.gitignore` when the audit is run from nested directories. Normalise to project-relative paths to avoid host-specific ignores.
- Audit results store metadata in `framework.db` via `.set_metadata()` without ensuring the DB schema exists. When users run the audit before scaffold (`framework.db` missing), `.set_metadata` fails; wrap in `if (!file.exists("framework.db")) return()` earlier or trigger `.init_db()`.

## Git Hooks (`R/git_hooks.R`)
- `hooks_install()` runs `security_audit()` during pre-commit regardless of whether `git.hooks.data_security` is enabled, but the audit currently fails for new repos (see above). Fixing audit behaviour will prevent hook false positives.
- Hook reinstall logic writes directly to `settings.yml` even when `settings.yml` is active (`.update_hook_config()` always loads YAML into `$default`). Respect the actual settings file path and environment sections.
- Generated hook script (`.generate_hook_script()`) hardcodes `git add CLAUDE.md AGENTS.md ...`; when those files don’t exist the command prints errors unless redirected. Already using `2>/dev/null || true` but consider restricting to files that exist to avoid noisy hooks.

## Documentation & Tests
- README / `readme-parts/09_security.md` still references `.gitignore` defaults that no longer exist (e.g., “Private directories auto-ignored”). Update once the audit/hook workflow is clarified so expectations match reality.
- Tests in `tests/testthat/test-security_audit.R` rely on `security_audit(check_git_history = FALSE, verbose = FALSE)` returning a structure. After fixing the gitless behaviour ensure tests cover both git repo and no-git scenarios.

---

Next actions: rework config discovery for security audit and hooks, implement non-echoing password prompts, and harden git-history scanning. Mark unit DONE once remediation tickets or PR plans exist.
