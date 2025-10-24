# Getting Started with Database Support

Framework provides simple, unified database access across 5 popular database backends. This guide will help you get started quickly.

## Supported Databases

Framework supports the following databases with a single, consistent API:

| Database | Driver Package | Installation | Use Case |
|----------|---------------|--------------|----------|
| **SQLite** | `RSQLite` | ✅ Built-in | Local, embedded databases |
| **PostgreSQL** | `RPostgres` | `install.packages("RPostgres")` | Production, multi-user |
| **MySQL** | `RMariaDB` | `install.packages("RMariaDB")` | Web applications |
| **MariaDB** | `RMariaDB` | `install.packages("RMariaDB")` | MySQL alternative |
| **DuckDB** | `duckdb` | `install.packages("duckdb")` | Analytics, large datasets |
| **SQL Server** | `odbc` | See below | Microsoft environments |

**Notes:**
- **SQLite** is always available (used for framework.db)
- All other drivers are **optional** - install only what you need
- Framework will give clear error messages if a driver is missing

## Quick Start

### Step 1: Check What You Have

```r
library(framework)

# See which database drivers are installed
drivers_status()
```

Output:
```
=== Database Driver Status ===

     driver   package installed version
 PostgreSQL RPostgres      TRUE   1.4.8
      MySQL  RMariaDB     FALSE    <NA>
     DuckDB    duckdb      TRUE   1.2.1
     SQLite   RSQLite      TRUE   2.4.3

To install missing drivers:
  install.packages('RMariaDB')
```

### Step 2: Install Drivers You Need

```r
# Install specific drivers
drivers_install(c("postgres", "mysql"))

# Or use interactive mode
drivers_install()  # Shows menu to select drivers
```

### Step 3: Configure Your Connection

Add database connection to `config.yml`:

```yaml
connections:
  my_db:
    driver: postgres
    host: localhost
    port: 5432
    database: mydb
    user: myuser
    password: ${DB_PASSWORD}  # From .env file
```

**Security Note:** Never commit passwords! Use environment variables:

```bash
# .env (this file is gitignored)
DB_PASSWORD=your_secret_password
```

### Step 4: Test Your Connection

```r
# Check if connection is ready
diag <- connection_check("my_db")

if (diag$ready) {
  # Connect and use
  conn <- connection_get("my_db")
  result <- DBI::dbGetQuery(conn, "SELECT * FROM users LIMIT 5")
  DBI::dbDisconnect(conn)
} else {
  # See what's wrong
  print(diag$messages)
}
```

## Installing Database Drivers

### PostgreSQL

```r
# Install the R package
install.packages("RPostgres")

# Or use Framework helper
drivers_install("postgres")
```

**System Requirements:** None (RPostgres is pure R/C)

### MySQL/MariaDB

```r
# Install the R package
install.packages("RMariaDB")

# Or use Framework helper
drivers_install("mysql")
```

**System Requirements:** None (RMariaDB bundles the client library)

### DuckDB

```r
# Install the R package
install.packages("duckdb")

# Or use Framework helper
drivers_install("duckdb")
```

**System Requirements:** None (DuckDB is embedded)

### SQL Server

SQL Server requires **two steps**:

**1. Install the R package:**
```r
install.packages("odbc")

# Or use Framework helper (shows instructions)
drivers_install("sqlserver")
```

**2. Install ODBC Driver:**

**macOS (Homebrew):**
```bash
brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
brew install msodbcsql18 mssql-tools18
```

**Ubuntu/Debian:**
```bash
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
sudo apt-get install -y msodbcsql18
```

**Windows:**
Download from [Microsoft ODBC Driver Download](https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server)

**Verify installation:**
```bash
# Should list "ODBC Driver 18 for SQL Server"
odbcinst -q -d
```

## Configuration Examples

### PostgreSQL

```yaml
connections:
  postgres_prod:
    driver: postgres
    host: db.example.com
    port: 5432
    database: production
    user: app_user
    password: ${POSTGRES_PASSWORD}
```

### MySQL/MariaDB

```yaml
connections:
  mysql_dev:
    driver: mysql  # or 'mariadb'
    host: 127.0.0.1
    port: 3306
    database: myapp_dev
    user: developer
    password: ${MYSQL_PASSWORD}
```

### SQLite

```yaml
connections:
  local_db:
    driver: sqlite
    database: data/local.sqlite
    # SQLite has no other required fields
```

### DuckDB

```yaml
connections:
  analytics:
    driver: duckdb
    database: data/analytics.duckdb

    # Optional settings:
    read_only: false
    memory_limit: "4GB"
    threads: 4
```

### SQL Server

```yaml
connections:
  sqlserver_prod:
    driver: sqlserver
    server: sql.example.com
    port: 1433
    database: AppDatabase
    user: app_user
    password: ${SQLSERVER_PASSWORD}

    # For development (self-signed certs):
    trust_server_certificate: true
```

## Common Tasks

### Connect and Query

```r
# Simple query (auto-connects and disconnects)
users <- query_get("SELECT * FROM users WHERE active = TRUE", "my_db")

# Multiple operations with automatic cleanup (RECOMMENDED)
result <- connection_with("my_db", {
  users <- DBI::dbGetQuery(conn, "SELECT * FROM users")
  posts <- DBI::dbGetQuery(conn, "SELECT * FROM posts")
  list(users = users, posts = posts)
})

# Manual connection (you must remember to disconnect!)
conn <- connection_get("my_db")
on.exit(DBI::dbDisconnect(conn))  # Ensure cleanup
users <- DBI::dbGetQuery(conn, "SELECT * FROM users")
posts <- DBI::dbGetQuery(conn, "SELECT * FROM posts")
# Connection auto-closes when function exits
```

### CRUD Operations

```r
# RECOMMENDED: Use connection_with() for automatic cleanup
result <- connection_with("my_db", {
  # Create (insert)
  id <- connection_insert(conn, "users", list(
    name = "Alice",
    email = "alice@example.com",
    age = 30
  ))

  # Read (find by ID)
  user <- connection_find(conn, "users", id)

  # Read (find by column)
  alice <- connection_find_by(conn, "users", email = "alice@example.com")

  # Update
  connection_update(conn, "users", id, list(age = 31))

  # Delete (soft delete if table has deleted_at column)
  connection_delete(conn, "users", id, soft = TRUE)

  # Restore soft-deleted
  connection_restore(conn, "users", id)

  # Return what you need
  alice
})
# Connection automatically closed, even if error occurs
```

### Transactions

```r
conn <- connection_get("my_db")

# Automatic transaction (commits on success, rolls back on error)
result <- connection_transaction(conn, {
  id <- connection_insert(conn, "orders", list(user_id = 1, total = 99.99))
  connection_insert(conn, "order_items", list(order_id = id, product_id = 42))
  id
})

DBI::dbDisconnect(conn)
```

### Using Environment Variables for Secrets

**1. Create `.env` file (gitignored):**
```bash
# .env
DB_HOST=production.example.com
DB_PASSWORD=super_secret_password
DB_USER=app_user
```

**2. Reference in `config.yml`:**
```yaml
connections:
  production:
    driver: postgres
    host: ${DB_HOST}
    user: ${DB_USER}
    password: ${DB_PASSWORD}
    database: myapp
```

**3. Framework automatically loads `.env` files**

## Troubleshooting

### "Package not installed" Error

**Error:**
```
Error: PostgreSQL connections require the RPostgres package.

Install with: install.packages('RPostgres')
```

**Solution:**
```r
# Check which drivers are installed
drivers_status()

# Install the missing driver
drivers_install("postgres")
```

### Connection Configuration Issues

**Check before connecting:**
```r
diag <- connection_check("my_db")

if (!diag$ready) {
  print(diag$messages)
}
```

**Common issues:**
- Missing required config fields (host, database, user)
- Driver package not installed
- Connection name typo

### SQL Server "No ODBC drivers found"

**Error:**
```
Error: nanodbc/nanodbc.cpp:1021: 00000: [unixODBC][Driver Manager]Can't open lib 'ODBC Driver 18 for SQL Server'
```

**Solution:** Install system ODBC driver (see SQL Server installation above)

**Verify:**
```bash
odbcinst -q -d  # Should show "ODBC Driver 18 for SQL Server"
```

### Connection Refused / Host Unreachable

**Checklist:**
- Is the database server running?
- Is the host/port correct in config.yml?
- Are you using the right network (localhost vs 127.0.0.1)?
- Is firewall blocking the connection?
- For cloud databases, is your IP whitelisted?

### Password Authentication Failed

**Checklist:**
- Is `.env` file in the project root?
- Is the environment variable spelled correctly (`${DB_PASSWORD}`)?
- Did you restart R after creating `.env`?
- Is the password correct in `.env`?

## Best Practices

### 1. Always Check Connection Readiness

```r
diag <- connection_check("production_db")
if (!diag$ready) {
  stop("Database not configured: ", paste(diag$messages, collapse = "; "))
}
```

### 2. Use Environment Variables for Secrets

**Never commit passwords to git!**

```yaml
# ✅ Good - uses environment variable
password: ${DB_PASSWORD}

# ❌ Bad - hardcoded password
password: super_secret_123
```

### 3. Always Disconnect

```r
# Use on.exit for safety
conn <- connection_get("my_db")
on.exit(DBI::dbDisconnect(conn))

# Your code here - connection always closed even if error occurs
```

### 4. Use Transactions for Multi-Step Operations

```r
# Wrap related operations in transaction
connection_transaction(conn, {
  # All succeed or all fail together
  id <- connection_insert(conn, "orders", list(...))
  connection_insert(conn, "order_items", list(order_id = id, ...))
  connection_update(conn, "inventory", 1, list(quantity = quantity - 1))
})
```

### 5. Prefer Query Helpers for Simple Operations

```r
# ✅ Good - auto-manages connection
users <- query_get("SELECT * FROM users WHERE active = TRUE", "my_db")

# ⚠️  Okay for multiple operations
conn <- connection_get("my_db")
users <- DBI::dbGetQuery(conn, "SELECT * FROM users")
posts <- DBI::dbGetQuery(conn, "SELECT * FROM posts")
DBI::dbDisconnect(conn)
```

## Next Steps

- **[Full API Reference](multi-database-support.md)** - Complete documentation of all functions
- **[Testing Guide](../tests/docker/README.md)** - How to test with Docker databases
- **Examples** - See `inst/templates/test-notebook.fr.qmd` for working examples

## Getting Help

### Check Driver Status
```r
drivers_status()
```

### Check Connection
```r
connection_check("my_db")
```

### Test with SQLite First
SQLite requires no setup and is always available:

```yaml
connections:
  test:
    driver: sqlite
    database: test.sqlite
```

```r
conn <- connection_get("test")
DBI::dbWriteTable(conn, "mtcars", mtcars)
result <- DBI::dbGetQuery(conn, "SELECT * FROM mtcars LIMIT 5")
DBI::dbDisconnect(conn)
```

Once SQLite works, you know Framework is working correctly and the issue is likely database-specific configuration.
