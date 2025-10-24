# Multi-Database Support Implementation Plan

**Status:** Phase 1 Complete (Docker Infrastructure)
**Last Updated:** 2025-10-23

## Executive Summary

Framework is expanding from SQLite/PostgreSQL-only to support **5 major database backends**: PostgreSQL, MySQL, SQLite, SQL Server, and DuckDB. This document outlines the consensus-driven implementation strategy based on Zen Consensus analysis (Gemini 2.5 Pro, 9/10 confidence).

## Design Decisions (Consensus-Backed)

### ✅ Dependency Strategy: SUGGESTS
**Decision:** All database drivers (except RSQLite) go in `Suggests`, not `Imports`

**Rationale:**
- CRAN standard (matches dplyr, data.table, pool)
- Lightweight installation (no forced system dependencies)
- Runtime checks with `requireNamespace()` + helpful errors

**Implementation:**
```r
.require_driver <- function(driver_name, package_name) {
  if (!requireNamespace(package_name, quietly = TRUE)) {
    stop(sprintf(
      "%s connections require the %s package.\nInstall with: install.packages('%s')",
      driver_name, package_name, package_name
    ))
  }
}
```

### ✅ API Scope: Minimalist
**Included:**
- ✅ Basic CRUD (find, find_by, insert, update, delete)
- ✅ Transaction helpers (`connection_transaction()`)
- ✅ Raw SQL as primary interface

**Excluded (Strategic Decision):**
- ❌ NO migrations (too much support burden, R users mostly read data)
- ❌ NO query builder (keeps scope tight, reduces maintenance)

**Why this is a strength:** Focuses package on core competencies, complements (not competes with) dbplyr.

### ✅ Cross-Database Abstraction: S3 Dispatch
**Problem:** Current `connection_find()` uses SQLite-specific `PRAGMA table_info()`

**Solution:** S3 generic dispatch on connection class
```r
.has_column <- function(conn, table_name, column_name) {
  UseMethod(".has_column")
}

.has_column.SQLiteConnection <- function(conn, table_name, column_name) {
  # SQLite: PRAGMA table_info()
}

.has_column.PqConnection <- function(conn, table_name, column_name) {
  # PostgreSQL: information_schema.columns
}

.has_column.default <- function(conn, table_name, column_name) {
  # Generic: information_schema.columns (MySQL, SQL Server)
}
```

## Implementation Phases

### Phase 1: Docker Test Infrastructure ✅ COMPLETE
**Delivered:**
- `docker-compose.test.yml` with 4 databases (PostgreSQL, MySQL, MariaDB, SQL Server)
- Database initialization scripts with test data (users, products tables)
- Helper scripts (`init-sqlserver.sh`, `test-connections.R`)
- Makefile targets (`make db-up`, `make db-down`, `make db-test`)
- Comprehensive documentation (`tests/docker/README.md`)

**Test Schema:**
- `users` table WITH soft-delete (`deleted_at` column)
- `products` table WITHOUT soft-delete
- Pre-populated data including soft-deleted records

**Usage:**
```bash
make db-up              # Start all databases
make db-test            # Verify connections
make db-init-sqlserver  # Initialize SQL Server (requires manual step)
make db-down            # Stop databases
make db-clean           # Stop + remove volumes
```

### Phase 2: Dependency Management (NEXT)
**Tasks:**
1. Update `DESCRIPTION`:
   - Keep RSQLite in Imports (for framework.db)
   - Move RPostgres to Suggests
   - Add: RMariaDB, odbc, duckdb to Suggests

2. Create `R/driver_helpers.R`:
   - `.require_driver()` function
   - Standardized error messages

**Example DESCRIPTION:**
```
Imports:
    DBI,
    RSQLite,      # Keep for framework.db
    checkmate,
    yaml,
    ...

Suggests:
    RPostgres,    # PostgreSQL
    RMariaDB,     # MySQL/MariaDB
    odbc,         # SQL Server
    duckdb,       # DuckDB
    testthat,
    ...
```

### Phase 3: New Database Drivers
**Files to Create:**
- `R/connections_mysql.R` - MySQL/MariaDB support
- `R/connections_sqlserver.R` - SQL Server support
- `R/connections_duckdb.R` - DuckDB support

**Update:**
- `R/connections.R` - Add switch cases for new drivers

**Driver Mapping:**
| Config Driver | R Package | Port | Notes |
|--------------|-----------|------|-------|
| `postgres`, `postgresql` | RPostgres | 5432 | Existing |
| `mysql`, `mariadb` | RMariaDB | 3306 | New |
| `sqlserver`, `mssql` | odbc | 1433 | New |
| `duckdb` | duckdb | N/A | File-based |
| `sqlite` | RSQLite | N/A | Existing |

### Phase 4: Schema Introspection (S3 Dispatch)
**Create:** `R/schema.R`

**Functions:**
- `.has_column(conn, table, column)` - Check if column exists
- `.list_tables(conn)` - List all tables
- `.list_columns(conn, table)` - List columns in table

**Methods to Implement:**
- `.has_column.SQLiteConnection`
- `.has_column.PqConnection` (PostgreSQL)
- `.has_column.MariaDBConnection` (MySQL/MariaDB)
- `.has_column.Microsoft SQL Server` (SQL Server via odbc)
- `.has_column.duckdb_connection` (DuckDB)
- `.has_column.default` - Generic information_schema approach

**Refactor:**
- Update `connection_find()` in `R/queries.R` to use `.has_column()`

### Phase 5: Expanded CRUD Helpers
**Create:** `R/crud.R`

**New Functions:**
```r
#' Find records by column values
connection_find_by(conn, table_name, ..., with_trashed = FALSE)

#' Insert a record
connection_insert(conn, table_name, values)

#' Update a record
connection_update(conn, table_name, id, values)

#' Delete a record (soft or hard)
connection_delete(conn, table_name, id, soft = TRUE)
```

**Design Notes:**
- `connection_find_by()` builds WHERE clause from named arguments
- `connection_delete()` auto-detects soft-delete support via `.has_column()`
- All functions use parameterized queries (SQL injection protection)

### Phase 6: Transaction Helpers
**Create:** `R/transactions.R`

**Function:**
```r
#' Execute code within a database transaction
connection_transaction(conn, code)
```

**Implementation:**
```r
connection_transaction <- function(conn, code) {
  DBI::dbBegin(conn)
  tryCatch({
    result <- force(code)
    DBI::dbCommit(conn)
    result
  }, error = function(e) {
    DBI::dbRollback(conn)
    stop(sprintf("Transaction failed: %s", e$message))
  })
}
```

**Usage:**
```r
connection_transaction(conn, {
  connection_insert(conn, "users", list(name = "Alice", age = 30))
  connection_update(conn, "users", 1, list(age = 31))
})
```

### Phase 7: Comprehensive Test Suite
**Create Test Files:**
- `tests/testthat/test-connections-multi.R` - Test all 5 databases
- `tests/testthat/test-schema.R` - Test S3 dispatch for schema introspection
- `tests/testthat/test-crud.R` - Test new CRUD helpers
- `tests/testthat/test-transactions.R` - Test transaction helper

**Test Strategy:**
- Skip tests if driver not installed (graceful degradation)
- Use Docker containers for integration tests
- Test soft-delete across all databases
- Test SQL dialect differences

**Helper Functions:**
```r
skip_if_no_driver <- function(package_name, driver_name) {
  if (!requireNamespace(package_name, quietly = TRUE)) {
    testthat::skip(sprintf("%s not installed", driver_name))
  }
}
```

### Phase 8: CI/CD Integration
**GitHub Actions Setup:**
- PostgreSQL service (easiest)
- MySQL service (Docker)
- SQLite (file-based, no service needed)
- DuckDB (file-based, no service needed)
- SQL Server (skip for now, add later)

**Workflow File:** `.github/workflows/multi-database-tests.yml`

**Test Matrix:**
```yaml
strategy:
  matrix:
    database: [sqlite, postgres, mysql, duckdb]
    r-version: ['4.1', '4.2', '4.3', 'release']
```

### Phase 9: Documentation & Migration
**Update Files:**
- `README.md` (via `readme-parts/`)
- `inst/templates/framework-cheatsheet.fr.md`
- `docs/database-support.md` (new guide)
- Function roxygen2 docs

**Topics to Cover:**
- Supported databases and driver installation
- Connection configuration examples
- Migration guide from old API
- Known limitations per database
- Troubleshooting guide

## File Structure Overview

```
framework/
├── R/
│   ├── connections.R              # Main entry (updated)
│   ├── connections_postgres.R     # Existing
│   ├── connections_sqlite.R       # Existing
│   ├── connections_mysql.R        # NEW
│   ├── connections_sqlserver.R    # NEW
│   ├── connections_duckdb.R       # NEW
│   ├── schema.R                   # NEW (S3 dispatch)
│   ├── crud.R                     # NEW (CRUD helpers)
│   ├── transactions.R             # NEW (transaction helper)
│   ├── driver_helpers.R           # NEW (.require_driver)
│   └── queries.R                  # Updated (use .has_column)
│
├── tests/
│   ├── docker/
│   │   ├── postgres/init.sql      # ✅ Created
│   │   ├── mysql/init.sql         # ✅ Created
│   │   ├── mariadb/init.sql       # ✅ Created
│   │   ├── sqlserver/init.sql     # ✅ Created
│   │   ├── scripts/
│   │   │   ├── init-sqlserver.sh  # ✅ Created
│   │   │   └── test-connections.R # ✅ Created
│   │   └── README.md              # ✅ Created
│   │
│   └── testthat/
│       ├── test-connections-multi.R  # NEW
│       ├── test-schema.R             # NEW
│       ├── test-crud.R               # NEW
│       └── test-transactions.R       # NEW
│
├── docker-compose.test.yml        # ✅ Created
├── Makefile                       # ✅ Updated
└── DESCRIPTION                    # To update
```

## Configuration Examples

### PostgreSQL
```yaml
connections:
  my_postgres:
    driver: postgres
    host: !expr Sys.getenv("DB_HOST", "localhost")
    port: 5432
    database: mydb
    user: !expr Sys.getenv("DB_USER")
    password: !expr Sys.getenv("DB_PASS")
    schema: public  # Optional
```

### MySQL/MariaDB
```yaml
connections:
  my_mysql:
    driver: mysql
    host: localhost
    port: 3306
    database: mydb
    user: !expr Sys.getenv("DB_USER")
    password: !expr Sys.getenv("DB_PASS")
```

### SQL Server
```yaml
connections:
  my_sqlserver:
    driver: sqlserver
    host: localhost
    port: 1433
    database: mydb
    user: sa
    password: !expr Sys.getenv("DB_PASS")
```

### DuckDB
```yaml
connections:
  my_duckdb:
    driver: duckdb
    database: data/my_database.duckdb  # File path
```

### SQLite
```yaml
connections:
  my_sqlite:
    driver: sqlite
    database: data/my_database.db  # File path
```

## Known Limitations & Trade-offs

### Database-Specific Quirks
| Database | Limitation | Workaround |
|----------|-----------|-----------|
| SQLite | No ALTER COLUMN | Recreate table |
| MySQL | Case-insensitive table names (default) | Document behavior |
| SQL Server | Requires ODBC driver install | Document setup |
| DuckDB | File-based only | No workaround needed |

### What We're NOT Building
- ❌ Full ORM (use dbplyr if you need that)
- ❌ Migration system (too much support burden)
- ❌ Query builder (raw SQL is primary interface)
- ❌ Connection pooling (maybe add later via pool package)
- ❌ Schema versioning (users manage schemas)

### CI/CD Considerations
- **SQL Server:** Skip in CI initially (licensing, Docker complexity)
- **PostgreSQL/MySQL:** Use GitHub Actions services
- **SQLite/DuckDB:** File-based, easy to test

## Success Metrics

### Phase 1 ✅ COMPLETE
- [x] Docker Compose setup with 4 databases
- [x] Test data initialization scripts
- [x] Connection test script
- [x] Makefile targets
- [x] Documentation

### Phase 2-9 (TODO)
- [ ] All 5 databases connect via `connection_get()`
- [ ] Soft-delete detection works across all databases
- [ ] CRUD helpers work on all 5 databases
- [ ] Transaction helper works correctly
- [ ] Test suite passes for all installed drivers
- [ ] CI/CD tests PostgreSQL, MySQL, SQLite, DuckDB
- [ ] Documentation updated with examples
- [ ] No breaking changes to existing SQLite/PostgreSQL code

## Next Steps

**Immediate (Phase 2):**
1. Update `DESCRIPTION` with new Suggests
2. Create `.require_driver()` helper
3. Test existing code still works

**Short-term (Phases 3-4):**
1. Add MySQL driver (`connections_mysql.R`)
2. Create S3 dispatch for schema introspection
3. Refactor `connection_find()` to use `.has_column()`

**Medium-term (Phases 5-6):**
1. Add SQL Server and DuckDB drivers
2. Implement CRUD helpers
3. Add transaction helper

**Long-term (Phases 7-9):**
1. Comprehensive test suite
2. CI/CD integration
3. Documentation and migration guide

## Questions/Decisions Needed

1. **SQL Server testing in CI?** Skip initially due to Docker complexity?
2. **Connection pooling?** Add later via `pool` package integration?
3. **Schema migrations?** Firm "no" or revisit after 1.0?
4. **odbc driver version?** Require ODBC 17 or support older versions?

## References

- **Zen Consensus Report:** Gemini 2.5 Pro (9/10 confidence)
- **Recommended Pattern:** dplyr, data.table, pool (all use Suggests)
- **DBI Documentation:** https://dbi.r-dbi.org/
- **Driver Packages:** RPostgres, RMariaDB, odbc, duckdb
