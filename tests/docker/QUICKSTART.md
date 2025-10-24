# Docker Test Databases - Quick Start

This guide gets you up and running with Framework's multi-database testing infrastructure in under 5 minutes.

## Prerequisites

- Docker Desktop installed and running
- R with DBI package installed

## Step 1: Start Databases (30 seconds)

```bash
# From framework/ directory
make db-up
```

This starts:
- PostgreSQL (port 5432)
- MySQL (port 3306)
- MariaDB (port 3307)
- SQL Server (port 1433)

Wait ~30 seconds for all containers to be healthy.

## Step 2: Initialize SQL Server (20 seconds)

SQL Server requires manual initialization:

```bash
make db-init-sqlserver
```

## Step 3: Test Connections (10 seconds)

Verify everything works:

```bash
make db-test
```

You should see:
```
Testing PostgreSQL... ✓ OK
Testing MySQL... ✓ OK
Testing MariaDB... ✓ OK
Testing SQLite... ✓ OK
Testing DuckDB... ✓ OK
Testing SQL Server... ✓ OK

✓ All database connections working!
```

## Step 4: Use in Your Code

### R Script Example
```r
library(DBI)
library(RPostgres)

# Connect to PostgreSQL test database
conn <- dbConnect(
  RPostgres::Postgres(),
  host = "localhost",
  port = 5432,
  dbname = "framework_test",
  user = "framework",
  password = "framework_test_pass"
)

# Query the pre-populated users table
users <- dbGetQuery(conn, "SELECT * FROM users")
print(users)

# Query products
products <- dbGetQuery(conn, "SELECT * FROM products WHERE in_stock = TRUE")
print(products)

# Clean up
dbDisconnect(conn)
```

### Using Framework API
```r
library(framework)

# Add to your config.yml:
# connections:
#   test_postgres:
#     driver: postgres
#     host: localhost
#     port: 5432
#     database: framework_test
#     user: framework
#     password: framework_test_pass

# Then use:
result <- query_get("SELECT * FROM users", "test_postgres")
print(result)

# Test soft-delete filtering
conn <- connection_get("test_postgres")
user <- connection_find(conn, "users", 1)  # Should return Alice
deleted_user <- connection_find(conn, "users", 3, with_trashed = TRUE)  # Should return Charlie
dbDisconnect(conn)
```

## Step 5: Stop When Done

```bash
make db-down
```

Or to completely remove data:
```bash
make db-clean  # Stops containers and removes volumes
```

## Available Test Data

Each database contains:

### users table (with soft-delete)
| id | email | name | age | deleted_at |
|----|-------|------|-----|------------|
| 1 | alice@example.com | Alice | 30 | NULL |
| 2 | bob@example.com | Bob | 25 | NULL |
| 3 | charlie@example.com | Charlie | 35 | <timestamp> |

### products table (no soft-delete)
| id | name | price | in_stock |
|----|------|-------|----------|
| 1 | Widget | 19.99 | TRUE |
| 2 | Gadget | 29.99 | TRUE |
| 3 | Doohickey | 9.99 | FALSE |

## Troubleshooting

### Containers won't start
```bash
# Check Docker is running
docker ps

# View logs
docker-compose -f docker-compose.test.yml logs

# Restart from scratch
make db-clean
make db-up
```

### Port already in use
```bash
# Check what's using the port
lsof -i :5432  # PostgreSQL
lsof -i :3306  # MySQL
lsof -i :3307  # MariaDB
lsof -i :1433  # SQL Server

# Either stop the conflicting service or edit docker-compose.test.yml
# to use different ports
```

### Connection refused
```bash
# Wait for health checks (containers might still be starting)
docker-compose -f docker-compose.test.yml ps

# Reinitialize SQL Server if needed
make db-init-sqlserver
```

### SQL Server fails to initialize
```bash
# Check logs
docker-compose -f docker-compose.test.yml logs sqlserver

# Manually run initialization
./tests/docker/scripts/init-sqlserver.sh
```

## Manual Database Access

### PostgreSQL
```bash
docker exec -it framework_test_postgres psql -U framework -d framework_test
```

### MySQL
```bash
docker exec -it framework_test_mysql mysql -uframework -pframework_test_pass framework_test
```

### MariaDB
```bash
docker exec -it framework_test_mariadb mariadb -uframework -pframework_test_pass framework_test
```

### SQL Server
```bash
docker exec -it framework_test_sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Framework_Test_Pass123! -d framework_test
```

## Next Steps

- See `tests/docker/README.md` for full documentation
- See `docs/multi-database-implementation-plan.md` for implementation details
- Run `make help` to see all available commands
