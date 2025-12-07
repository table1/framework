# Docs Audit (2025-02-15) — Resolved Items

- `data_save()` now registers dot-notation paths in the data catalog automatically so `data_read()` works without manual edits.
- Parquet is supported for `data_add()`/`data_read()` (via arrow); doc examples now match behavior.
- `cache_remember()` accepts string durations (e.g., `"7 days"`) and fractional hours without warnings; `expire` is an accepted alias.
- New projects always create an AI context file (default CLAUDE.md) even when assistants aren’t specified, so `ai_regenerate_context()` works out of the box.
- `git_commit()` handles multi-word messages safely by using a temp message file.
- `make_notebook()` (and aliases) support `subdir`, matching course/teaching examples.
- Git hook config accepts both `check_sensitive_dirs` and `warn_unignored_sensitive`.
- Initial git commit is skipped gracefully when git identity is missing, with guidance instead of a hard failure.
- Docs refreshed: installer uses `table1/framework`; setup file name is `~/.config/framework/settings.yml`; publishing docs show supported `connections.storage_buckets` (legacy `s3:` also works); git docs aligned to `check_sensitive_dirs`.
