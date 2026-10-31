---
id: database
title: Database Integration
section: features
position: 14
description: 'Querying databases with Framework helpers'
---
## Overview

Once your connections are defined (see the [Connections guide](guide:connections)), Framework makes it easy to run database queries, execute statements, and tap into the internal `framework.db`. Use the high-level helpers to avoid hand-managing DBI connections.

## Running Queries

### Get Data

```r
# Query and return results
users <- db_query("SELECT * FROM users WHERE active = true", "analytics")
```

### Execute Statements

```r
# Execute without returning data
db_execute("UPDATE stats SET last_run = NOW()", "analytics")
```

### Manual Connections

Need direct DBI access? Grab a connection and clean up afterward:

```r
conn <- db_connect("analytics")
DBI::dbListTables(conn)
DBI::dbDisconnect(conn)
```

Prefer `db_query()` and `db_execute()` when possible—they open and close connections automatically.

## Supported Databases

Framework supports the following database drivers out of the box:

| Driver | Package | Use Case |
|--------|---------|----------|
| `postgres` / `postgresql` | RPostgres | PostgreSQL databases |
| `sqlite` | RSQLite | Local SQLite files |
| `duckdb` | duckdb | Analytical workloads, Parquet files |
| `mysql` / `mariadb` | RMariaDB | MySQL/MariaDB |
| `sqlserver` / `mssql` | odbc | SQL Server |

Object storage connectors (S3-compatible endpoints) are covered in the [Connections guide](guide:connections#object-storage-connections).

### DuckDB Configuration

DuckDB supports additional options in `settings.yml`:

```yaml
connections:
  warehouse:
    driver: duckdb
    database: data/warehouse.duckdb
    read_only: false
    memory_limit: "4GB"
    threads: 4
```

## The Framework Database

Every project includes a local SQLite database (`framework.db`) for internal tracking:

```r
cache_entries <- db_query("SELECT * FROM cache", "framework")
```

This tracks:

- Data integrity hashes
- Cache metadata
- Results registry

Use regular SQL to inspect or export these tables, just like any other connection.
