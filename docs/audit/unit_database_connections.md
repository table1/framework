# Audit Notes — Database Connections & CRUD

Status: IN PROGRESS (Unit 05)

## Connection Discovery & Configuration
- `R/connections.R:20-52` (`connection_get`) assumes connection metadata lives under `config$connections[[name]]`, but helper utilities like `connection_check()` still read raw `config.yml` via `config::get(file = "config.yml")` (`R/drivers.R:114`). Projects using `settings.yml` (the v1 default) or environment-scoped configs will fail that health check. Align all helpers to `read_config()` with auto-discovery.
- `R/drivers.R:114-206` hardcodes required fields per driver (host, database, user, password). Config templates often rely on `env()` defaults; when passwords resolve to empty string this validation still passes, but the connection functions later enforce the same fields, meaning SQLite/DuckDB configs without `password` hit unnecessary errors. Relax or document per-driver optional fields.
- Empty stub `R/connections_cifs.R` ships with the package yet nothing references it. Decide whether CIFS/Samba support is being added; otherwise remove to avoid confusion.

## Pooling & Lifecycle Management
- `connection_with()` (`R/connection_helpers.R:27-57`) always calls `DBI::dbDisconnect(conn)` on exit. When pooling is enabled (`connection_get()` returns a `pool::Pool`), this triggers `dbDisconnect()` on the pool object instead of returning the borrowed connection, potentially shutting down the pool or raising an error. Detect pool objects (`inherits(conn, "Pool")`) and skip disconnect.
- `connection_pool()` (`R/connection_pool.R:1-160`) caches pools in `.framework_pools` stored in `.GlobalEnv`. That leaks into user-global state, conflicts across tests, and survives package unload. Prefer a package-private environment (e.g., `framework_env$pool_cache`) with cleanup on package unload.
- Default `max_size = Inf` and other counts are passed straight to `pool::dbPool()`. The pool API expects finite integers; feeding `Inf` results in warnings or failures. Clamp values or translate to `NULL`.
- `connection_pool_sqlserver()` (`R/connection_pool.R:168-198`) and `connections_sqlserver.R:8-73` set `TrustServerCertificate = "yes"` whenever the config key exists, even if `FALSE`. Ensure the option respects actual boolean values.
- `connection_pool_list()` (`R/connection_pool.R:236-286`) reads `pool_obj@counters$taken` directly—an internal slot from the pool package. This is fragile and may break with package upgrades. Use exported introspection helpers or return basic metadata only.
- No hook currently closes pools on package detach or session exit; add `.onUnload`/`.onDetach` cleanup (`connection_pool_close_all()`).

## CRUD Helpers & Query Abstractions
- `.get_placeholders()` (`R/crud.R:5-16`) only handles PostgreSQL vs “others”. SQL Server ODBC prefers `?` but some drivers expect `@p1`; confirm compatibility or add driver-specific mapping.
- `connection_insert()` (`R/crud.R:54-117`) converts values to a data frame via `as.data.frame(values, stringsAsFactors = FALSE)`. Lists containing vector columns (>1 length) become multiple rows, silently inserting more records than intended. Validate scalar inputs or recycle explicitly.
- `connection_insert()` returns Boolean for PostgreSQL because no `RETURNING` clause is used. Document limitation or add optional `returning` support so callers can retrieve inserted IDs consistently.
- `connection_update()`/`connection_delete()` build dynamic SQL with placeholders but don’t quote table names when passed `schema.table`. Using `DBI::dbQuoteIdentifier(conn, table_name)` helps but requires schema support; verify multi-schema semantics for Postgres/SQL Server.
- `connection_find_by()` merges user parameters via `DBI::dbGetQuery(conn, query, params = unname(conditions))`. Because `unname()` on a list still yields a list, order is preserved, but warn that vectorized arguments (length >1) aren’t supported.
- Soft-delete helpers rely solely on the presence of `deleted_at`. Consider allowing configurable soft-delete column name in settings.

## Transaction Utilities
- `connection_transaction()` (`R/transactions.R:37-97`) and `connection_with_transaction()` rely on `force(code)` but don’t wrap evaluation in `substitute()`/`eval`. While promises defer execution, the connection isn’t injected into the evaluation frame, so inner code must reference external `conn`. That matches examples, but document this or refactor to evaluate in a constructed environment providing `conn`.
- `connection_transaction()` warns about nested transactions but still calls `DBI::dbBegin()` without checking driver capabilities. For drivers lacking nested transaction support, this may error; consider `DBI::dbWithTransaction()` for more portable behaviour.

## Driver Implementations
- `_connect_postgres()` (`R/connections_postgres.R:5-53`) enforces a password, but templates commonly rely on peer auth. Allow missing `password` when `sslmode` or local socket usage is configured.
- `_connect_mysql()` / `_connect_sqlserver()` perform simple regex host validation (`^[a-zA-Z0-9.-]+$`) blocking legitimate hostnames containing underscores or IPv6 literals. Expand validation or rely on driver-level errors.
- `_connect_sqlserver()` sets `TrustServerCertificate = "yes"` by default with no way to disable other than removing key. Honour explicit `FALSE` or allow custom connection options.
- `_create_*_db()` helpers (Postgres/MySQL/SQL Server/SQLite/DuckDB) aren’t surfaced anywhere; either wire them into CLI commands or remove to cut dead code.

## Driver Discovery & Installation
- `drivers_status()` (`R/drivers.R:1-47`) deduplicates by package then prints a table. Because PostgreSQL/MySQL share packages, driver-specific status (e.g., MariaDB vs MySQL) is lost. Consider reporting per driver regardless of shared package.
- `drivers_install()` is largely interactive (stdin prompts). Provide non-interactive pathways for automation (e.g., `drivers_install(drivers = c("postgres"))` should skip readline entirely even when other drivers missing).

## Query Wrappers
- `query_get()` / `query_execute()` (`R/queries.R:19-67`) pipe the result of `connection_get()` into an anonymous function. When pooling is active, they leave the pool open, which is correct, but there’s no logging/control around errors or instrumentation. Add optional verbose logging and unify error messaging with `connection_*` helpers.
- `connection_find()` restricts results to `LIMIT 1`, but DB2/SQL Server use `TOP`; ensure DBI handles translation or document Postgres/MySQL focus.

---

Next actions: address pool lifecycle (disconnect guard, global env cache), modernize config discovery in diagnostics, harden CRUD helpers for vector inputs, and fix SQL Server trust logic. Update status after remediation items are planned.
