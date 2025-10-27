# Multi-Database Support

Framework now supports 5 database backends with a unified API:

- **PostgreSQL** - Enterprise-grade open source database
- **MySQL/MariaDB** - Popular open source relational databases
- **SQLite** - Embedded, serverless database (default for framework.db)
- **DuckDB** - High-performance analytical database
- **SQL Server** - Microsoft enterprise database (requires ODBC driver)

## Driver Management

### Check Driver Status

See which database drivers are installed:

```r
library(framework)

# Show all drivers
drivers_status()
```

Output:
```
=== Database Driver Status ===

     driver   package installed version
 PostgreSQL RPostgres      TRUE   1.4.8
      MySQL  RMariaDB      TRUE   1.3.4
 SQL Server      odbc     FALSE    <NA>
     DuckDB    duckdb      TRUE   1.2.1
     SQLite   RSQLite      TRUE   2.4.3

To install missing drivers:
  install.packages('odbc')
  # Also requires ODBC driver: https://learn.microsoft.com/en-us/sql/connect/odbc/
```

### Install Drivers

Install one or more database drivers:

```r
# Install specific drivers
drivers_install(c("postgres", "mysql"))

# Interactive mode (prompts for selection)
drivers_install()
```

The function:
- ✅ Skips already installed drivers
- ✅ Provides special instructions for ODBC (SQL Server)
- ✅ Shows updated status after installation

### Check Connection Readiness

Before connecting, diagnose if a connection is properly configured:

```r
# Check if connection is ready
diag <- connection_check("my_db")

if (diag$ready) {
  conn <- connection_get("my_db")
} else {
  # See what's wrong
  print(diag$messages)
}
```

Output for misconfigured connection:
```
=== Connection Check: my_db ===

Driver: postgres
Package: RPostgres
Package installed: ✗
Config valid: ✓

Issues:
  • Driver package 'RPostgres' not installed
  • Install with: install.packages('RPostgres')
```

The `connection_check()` function returns:
- `ready` - Whether connection can be established
- `driver` - Database driver name
- `package` - Required R package
- `package_installed` - Package availability
- `config_valid` - Whether config has required fields
- `messages` - Diagnostic messages

## Configuration

Add database connections to `settings.yml`:

### PostgreSQL

```yaml
connections:
  my_postgres:
    driver: postgres
    host: localhost
    port: 5432
    database: mydb
    user: myuser
    password: ${DB_PASSWORD}  # From .env file
```

### MySQL/MariaDB

```yaml
connections:
  my_mysql:
    driver: mysql  # or 'mariadb'
    host: 127.0.0.1
    port: 3306
    database: mydb
    user: myuser
    password: ${DB_PASSWORD}
```

### SQLite

```yaml
connections:
  my_sqlite:
    driver: sqlite
    database: data/mydb.sqlite
```

### DuckDB

```yaml
connections:
  my_duckdb:
    driver: duckdb
    database: data/mydb.duckdb
    # Optional settings:
    read_only: false
    memory_limit: "4GB"
    threads: 4
```

### SQL Server

```yaml
connections:
  my_sqlserver:
    driver: sqlserver
    server: localhost
    port: 1433
    database: mydb
    user: sa
    password: ${DB_PASSWORD}
    # Optional:
    trust_server_certificate: true  # For dev/test
```

## Usage

All database operations work the same across backends:

```r
# Connect
conn <- connection_get("my_db")

# CRUD operations
user <- connection_find(conn, "users", 42)
users <- connection_find_by(conn, "users", status = "active")
id <- connection_insert(conn, "users", list(name = "Alice", email = "alice@example.com"))
connection_update(conn, "users", 42, list(status = "inactive"))
connection_delete(conn, "users", 42, soft = TRUE)
connection_restore(conn, "users", 42)

# Transactions
result <- connection_transaction(conn, {
  id <- connection_insert(conn, "users", list(name = "Bob"))
  connection_update(conn, "posts", 1, list(author_id = id))
  id
})

# Always disconnect
DBI::dbDisconnect(conn)
```

## Cross-Database Features

### Soft Deletes

All databases support soft-delete pattern via `deleted_at` column:

```r
# Soft delete (sets deleted_at timestamp)
connection_delete(conn, "users", 42, soft = TRUE)

# Excluded by default
user <- connection_find(conn, "users", 42)  # Returns empty

# Include soft-deleted
user <- connection_find(conn, "users", 42, with_trashed = TRUE)

# Restore
connection_restore(conn, "users", 42)
```

### Auto-Timestamps

Automatic `created_at` and `updated_at` handling:

```r
# Automatically sets created_at and updated_at
connection_insert(conn, "posts", list(title = "Hello"))

# Automatically updates updated_at
connection_update(conn, "posts", 1, list(title = "Hello World"))

# Disable if needed
connection_insert(conn, "posts", list(...), auto_timestamps = FALSE)
```

### Schema Introspection

Database-specific schema queries via S3 dispatch:

```r
# Works across all databases
has_deleted <- .has_column(conn, "users", "deleted_at")  # TRUE/FALSE
columns <- .list_columns(conn, "users")                  # Character vector
tables <- .list_tables(conn)                              # Character vector
```

## Error Handling

Framework provides helpful errors when drivers are missing:

```r
conn <- connection_get("my_postgres")
# Error: PostgreSQL connections require the RPostgres package.
#
# Install with: install.packages('RPostgres')
```

For SQL Server:
```r
conn <- connection_get("my_sqlserver")
# Error: SQL Server connections require the odbc package.
#
# Install with: install.packages('odbc')
# Also requires ODBC Driver 17 for SQL Server
```

## Best Practices

### 1. Check Before Connecting

```r
diag <- connection_check("production_db")
if (!diag$ready) {
  stop("Database not ready: ", paste(diag$messages, collapse = "; "))
}

conn <- connection_get("production_db")
```

### 2. Use Environment Variables for Secrets

```yaml
# settings.yml
connections:
  prod:
    host: ${DB_HOST}
    password: ${DB_PASSWORD}
```

```bash
# .env (gitignored)
DB_HOST=production.example.com
DB_PASSWORD=super_secret
```

### 3. Always Clean Up Connections

```r
conn <- connection_get("my_db")
on.exit(DBI::dbDisconnect(conn))

# Your database code here
```

Or use query helpers that auto-disconnect:

```r
# Automatically manages connection lifecycle
data <- query_get("SELECT * FROM users", "my_db")
```

### 4. Use Transactions for Multi-Step Operations

```r
connection_transaction(conn, {
  # All or nothing
  id <- connection_insert(conn, "orders", list(...))
  connection_insert(conn, "order_items", list(order_id = id, ...))
  connection_update(conn, "inventory", 1, list(quantity = quantity - 1))
  id
})
```

## Testing

Framework includes comprehensive multi-database tests:

```bash
# Start test databases
make db-up

# Run comprehensive tests (all 5 databases)
./tests/docker/scripts/manual-test.R

# Test driver helpers
./tests/docker/scripts/test-driver-helpers.R

# Stop databases
make db-down
```

## Architecture Notes

- **S3 Dispatch**: Database-specific logic uses R's S3 method dispatch
- **DBI Standard**: All operations use DBI interface for portability
- **Suggests Dependencies**: Drivers are in `Suggests`, not `Imports` (lightweight)
- **Parameter Placeholders**: Automatically handles `?` vs `$1, $2` across databases
- **Cross-Database SQL**: Uses INFORMATION_SCHEMA where possible for portability

## Known Limitations

- **No migrations**: Framework focuses on data analysis, not schema management
- **No query builder**: Use SQL directly (keeps API simple)
- **Basic CRUD only**: Not a full ORM (by design)
- **SQL Server on ARM**: Not available in Docker tests (x86_64 only)
