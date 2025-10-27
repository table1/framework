# Audit Notes — CLI & Tooling Scripts

Status: IN PROGRESS (Unit 07)

## CLI Installer & Shim (`R/install_cli.R`, `inst/bin/install-cli.sh`, `inst/bin/framework*`)
- `R/install_cli.R:109-118` calls `file.symlink()` and then immediately `Sys.chmod()` without verifying the symlink succeeded. On Windows (where symlinks require elevation) or on filesystems that disallow symlinks, the calls silently fail yet the function still prints “CLI installed”, leaving users with a broken setup. Capture the return value and fall back to copying the script when symlinks aren’t available.
- `R/install_cli.R` has no Windows branch at all—installing via symlink doesn’t work on default Windows R sessions. Provide an alternate path (e.g., write wrapper `.bat` files or copy the scripts) and document support expectations.
- The fallback path in `cli_install()` uses `readline()` to prompt for PATH updates (`R/install_cli.R:141-158`). In non-interactive sessions this emits “readline called in non-interactive mode” warnings and returns an empty string, accidentally choosing the default branch. Guard prompts with `interactive()` and offer a non-interactive flag.
- Project detection in the shell CLI (`inst/bin/framework-global:34-44`) only checks for `framework.db` or `bin/framework`. Freshly created projects contain neither until `scaffold()` runs, so in-project commands like `framework make:notebook` immediately error. Extend detection to recognise `config.yml` / `settings.yml` or other canonical markers.
- The interactive “settings check-in” prompts within `framework-global` (`inst/bin/framework-global:77-183`) rely on `read` from STDIN. When the CLI is invoked inside scripts/pipelines (no TTY), these reads block. Use `/dev/tty` (as done in `install-cli.sh`) or skip prompts when `! -t 0`.

## Notebook & Script Generators (`R/make_notebook.R`, `R/make_script.R`, `R/stubs.R`)
- `R/make_script.R:33-50` still reads `config$options$script_dir`; the 1.0 directory layout moved to `config$directories$scripts`. As a result, scripts always fall back to `scripts/` even when users customised directories. Update to use the new schema (with legacy fallback).
- Author placeholder replacement in `make_notebook()` (`R/make_notebook.R:153-162`) only swaps literal `!expr config$author$name`. Current default stubs use backtick inline R (`\`r config$author$name\``), so the substitution never fires and notebooks keep the placeholder. Expand replacements to cover compact inline expressions (name/email/affiliation).
- User stub discovery warns “Skipped (exists)” for every file when `stubs_publish()` is rerun (`R/stubs.R:63-115`). Consider summarising duplicates after the loop to reduce noisy output, though not critical for functionality.

## Console Helper (`R/console.R`)
- `capture_output()` wraps `eval(expr)` without forcing promise evaluation. Users must call `capture_output(quote(expr))` manually, otherwise the expression evaluates in the caller’s environment before the sinks are established. Provide a documented example or internally wrap `substitute(expr)` so the helper behaves as expected.

---

Next actions: make CLI installation resilient across platforms (symlink fallback + interactive guards), broaden project detection in `framework-global`, and modernise script generation to honour 1.0 directory settings. Update status once remediation tasks are queued.
