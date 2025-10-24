# Docker Test Database Infrastructure

This directory contains Docker Compose configuration and initialization scripts for testing Framework's multi-database support.

## Supported Databases

- **PostgreSQL 16** (port 5432)
- **MySQL 8.0** (port 3306)
- **MariaDB 11** (port 3307)
- **SQL Server 2022** (port 1433)
- **DuckDB** (file-based, no container needed)
- **SQLite** (file-based, no container needed)

## Quick Start

### Start All Databases
```bash
# From project root
docker-compose -f docker-compose.test.yml up -d

# Wait for health checks
docker-compose -f docker-compose.test.yml ps
```

### Start Individual Database
```bash
docker-compose -f docker-compose.test.yml up -d postgres
docker-compose -f docker-compose.test.yml up -d mysql
docker-compose -f docker-compose.test.yml up -d mariadb
docker-compose -f docker-compose.test.yml up -d sqlserver
```

### Initialize SQL Server (requires manual step)
SQL Server's docker-entrypoint-initdb.d doesn't work the same way. Run:
```bash
./tests/docker/scripts/init-sqlserver.sh
```

### Stop All Databases
```bash
docker-compose -f docker-compose.test.yml down
```

### Stop and Remove Volumes (clean slate)
```bash
docker-compose -f docker-compose.test.yml down -v
```

## Connection Details

### PostgreSQL
```yaml
driver: postgres
host: localhost
port: 5432
database: framework_test
user: framework
password: framework_test_pass
```

### MySQL
```yaml
driver: mysql
host: localhost
port: 3306
database: framework_test
user: framework
password: framework_test_pass
```

### MariaDB
```yaml
driver: mariadb
host: localhost
port: 3307
database: framework_test
user: framework
password: framework_test_pass
```

### SQL Server
```yaml
driver: sqlserver
host: localhost
port: 1433
database: framework_test
user: sa
password: Framework_Test_Pass123!
```

## Test Configuration

Create a test config file for multi-database testing:

```yaml
# tests/testthat/config.test.yml
default:
  connections:
    test_postgres:
      driver: postgres
      host: !expr Sys.getenv("TEST_POSTGRES_HOST", "localhost")
      port: 5432
      database: framework_test
      user: framework
      password: framework_test_pass

    test_mysql:
      driver: mysql
      host: !expr Sys.getenv("TEST_MYSQL_HOST", "localhost")
      port: 3306
      database: framework_test
      user: framework
      password: framework_test_pass

    test_mariadb:
      driver: mariadb
      host: !expr Sys.getenv("TEST_MARIADB_HOST", "localhost")
      port: 3307
      database: framework_test
      user: framework
      password: framework_test_pass

    test_sqlserver:
      driver: sqlserver
      host: !expr Sys.getenv("TEST_SQLSERVER_HOST", "localhost")
      port: 1433
      database: framework_test
      user: sa
      password: Framework_Test_Pass123!
```

## Troubleshooting

### Check Container Health
```bash
docker-compose -f docker-compose.test.yml ps
```

### View Container Logs
```bash
docker-compose -f docker-compose.test.yml logs postgres
docker-compose -f docker-compose.test.yml logs mysql
docker-compose -f docker-compose.test.yml logs mariadb
docker-compose -f docker-compose.test.yml logs sqlserver
```

### Connect Directly to Database
```bash
# PostgreSQL
docker exec -it framework_test_postgres psql -U framework -d framework_test

# MySQL
docker exec -it framework_test_mysql mysql -uframework -pframework_test_pass framework_test

# MariaDB
docker exec -it framework_test_mariadb mariadb -uframework -pframework_test_pass framework_test

# SQL Server
docker exec -it framework_test_sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Framework_Test_Pass123! -d framework_test
```

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Multi-Database Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: framework_test
          POSTGRES_USER: framework
          POSTGRES_PASSWORD: framework_test_pass
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      mysql:
        image: mysql:8.0
        env:
          MYSQL_DATABASE: framework_test
          MYSQL_USER: framework
          MYSQL_PASSWORD: framework_test_pass
          MYSQL_ROOT_PASSWORD: root_test_pass
        options: >-
          --health-cmd "mysqladmin ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 3306:3306

    steps:
      - uses: actions/checkout@v3

      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: 'release'

      - name: Install system dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y libpq-dev libmysqlclient-dev

      - name: Install R dependencies
        run: |
          install.packages(c("DBI", "RPostgres", "RMariaDB", "testthat"))
        shell: Rscript {0}

      - name: Run tests
        run: |
          Rscript -e 'devtools::test()'
```

## Database Schema

Each test database contains:

### `users` table (with soft-delete)
- `id` (primary key)
- `email` (unique)
- `name`
- `age`
- `created_at`
- `updated_at`
- `deleted_at` (nullable, for soft-delete pattern)

### `products` table (without soft-delete)
- `id` (primary key)
- `name`
- `price`
- `in_stock`
- `created_at`

Sample data is pre-populated in each database, including one soft-deleted user (Charlie).
