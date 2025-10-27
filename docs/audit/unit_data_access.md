# Audit Notes — Data Access & Integrity

Status: IN PROGRESS (Unit 04)

## Cache System (`R/cache_*`)
- `R/cache_read.R:48` & `R/cache_write.R:20` assume `config$options$data$cache_default_expire`, but the v1 templates moved cache settings under `directories` / `settings.yml`. Reads now return `NULL`, so expirations never apply. Replace with `config("cache_default_expire")` or new settings path.
- `R/cache_delete.R:14` and `cache_flush()` read `config$options$data$cache_dir`; likewise stale with new config layout—should honor `config("cache")` or `config$directories$cache`.
- `.get_cache()` ignores the `expire_after` argument entirely; overrides should adjust the expiry check instead of being discarded.
- Cache refresh removal only deletes RDS file; metadata row remains if database connection fails (when `.get_db_connection()` returns NULL). Add defensive handling to avoid orphaned rows.
- All cache helpers expect `framework.db` tables to exist; if user calls `cache_fetch()` before `scaffold()` (or framework.db missing), new SQLite file gets created with no schema and queries fail. Call `.init_db()`/`.ensure_framework_db()` on connect.

## Data Loading & Specs (`R/data_read.R`)
- `data_load()` calculates hashes for direct-path loads too (when spec fetched) but never records `private` flag; consider storing additional metadata (size, modified time) for audit views.
- Hashing via `.calculate_file_hash()` reads entire file into memory; large datasets will spike RAM. Switch to streaming hash (chunked `openssl::sha256`) or warn for >100MB.
- Locked datasets (`spec$locked = TRUE`) halt on hash mismatch without recovery guidance. Provide remediation instructions (refresh hash) or allow override.
- `data_spec_get()` returns NULL for unconfigured dot paths without suggesting nearest match until later; consider integrating fuzzy search sooner.
- `data_spec_get()` treats relative paths as relative to `getwd()` rather than project root; after `standardize_wd()` this is usually OK, but if invoked before scaffold it may resolve incorrectly. Use project root detection or config to anchor.
- `data_spec_update()` (`R/data_write.R:139`) hard-requires `config.yml` and `default` section; fails entirely for `settings.yml`-only projects and in split configuration setups. Must auto-detect active config + environment.
- `data_spec_update()` uses `eval(parse())` to mutate nested lists, risking code injection and brittle behavior with hyphenated keys. Refactor with iterative list assignment.

## Data Saving (`R/data_write.R`)
- CSV writer always calls `readr::write_csv()` regardless of delimiter selection. For tabs/semicolons, must use `readr::write_delim()` with the resolved delimiter; current code silently writes commas even when `delimiter = "tab"`. Critical bug.
- Directory resolution is hardcoded to `data/...` by splitting dot notation; ignores `directories` overrides in config (e.g., custom source paths). Should inspect configured `directories` for correct base path.
- When encrypting CSVs, serialization uses `write_csv()` to temp file (same delimiter issue) before encrypting.
- Added YAML snippet always references `config.yml`; needs update for `settings/data.yml` flow and to note environment scopes.
- Default `locked = TRUE` may be surprising for iterative workflows; consider documenting expectation or defaulting to `FALSE`.

## Data Catalog Tracking (`R/data_write.R` & `R/data_read.R`)
- `.set_data()` / `.get_data_record()` interact with SQLite but don’t ensure schema exists (same issue as cache). Calling before scaffold results in SQL errors.
- `.remove_data()` never called; consider exposing cleanup helper or prune unused record entries during deletes.

## Results System (`R/results*.R`)
- `result_save()` pulls directories from `config$options$results$public_dir/private_dir`, but new settings place paths under `directories.results_public` / `results_private`. Currently falls back to hardcoded defaults, ignoring user overrides.
- Saving a file via `result_save(name, file=...)` copies with original extension, but `result_get()` always looks for `name.rds`; retrieving non-R objects fails outright. Need a path metadata column and retrieval fallback.
- Result encryption relies on `.is_encrypted_file()` magic bytes; ensure saved encrypted files include the prefix (verify via tests).
- Supporting scripts `results_read.R`, `results_write.R`, `results_delete.R` are empty placeholders; either implement utilities (list/read/delete) or remove to avoid confusion.
- No pruning of deleted results files; `result_list()` doesn’t surface missing disk artifacts or stale hashes.

## Scratch Helpers (`R/scratch.R`)
- `scratch_capture()` relies on `config$options$data$scratch_dir`, conflicting with modern `directories.scratch`. Needs `config("scratch")` fallback.
- Writing YAML via `yaml::as.yaml()` requires `yaml` package, but it’s only in Suggests; ensure helpful error if missing.
- Vector capture converts via `as.character()` but doesn’t guard against `NA` values; consider explicit handling to avoid `"NA"` string confusion in logs.

## Framework DB (`R/framework_db.R`)
- `.get_db_connection()` blindly connects; when `framework.db` missing, a blank database is created without schema, causing inserts to fail. Call `.init_db()` or check for required tables before returning the connection.
- Template building (`.create_template_db()`) splits SQL simply on semicolons—breaks if statements contain semicolons inside triggers or views. Consider using `DBI::dbExecute` on raw script or more robust parser.

---

Next actions: prioritize fixes for delimiter handling, modern config path usage (cache/data/results/scratch), framework DB initialization guard, and result retrieval for file artifacts. Update status after issues are queued or patches planned.
