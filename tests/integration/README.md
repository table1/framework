# Integration test servers

`compose.yml` starts throwaway servers for the integration tests: PostgreSQL
17, MySQL 8.4, MariaDB 11, SQL Server 2022, and S3 (SeaweedFS). The R package,
framework-py, and fw all test against this file. The R repository holds the
canonical copy, and the others copy it with their asset sync, so change it
here.

```bash
docker compose -f tests/integration/compose.yml up -d --wait   # start
docker compose -f tests/integration/compose.yml down -v        # stop and delete data
```

SQL Server is published for amd64 only and runs under emulation on Apple
Silicon. It takes about 30 seconds to become healthy.

## Servers

| Server | Port | User | Password | Variables |
| --- | --- | --- | --- | --- |
| PostgreSQL | 55432 | framework | framework-test | `FW_TEST_PG_HOST`, `FW_TEST_PG_PORT` |
| MySQL | 53306 | framework | framework-test | `FW_TEST_MYSQL_HOST`, `FW_TEST_MYSQL_PORT` |
| MariaDB | 53307 | framework | framework-test | `FW_TEST_MARIADB_HOST`, `FW_TEST_MARIADB_PORT` |
| SQL Server | 51433 | sa | Framework-test-1 | `FW_TEST_MSSQL_HOST`, `FW_TEST_MSSQL_PORT` |
| S3 | 58333 | framework | framework-test | `FW_TEST_S3_ENDPOINT`, `FW_TEST_S3_ACCESS_KEY`, `FW_TEST_S3_SECRET_KEY` |

Every database is `framework_test`, seeded by `<server>/init.sql`. Ports bind
to 127.0.0.1 only. The credentials are test-only values for these local
containers.

## Running the tests

The tests skip when a server is not running and never run on CRAN. Set
`FW_TEST_REQUIRE_SERVERS=1` to make a missing server a failure, as CI does.

```bash
NOT_CRAN=true Rscript -e 'devtools::test(filter = "integration|multi")'
```

Client libraries: R needs RPostgres, RMariaDB, odbc, and aws.s3. SQL Server
also needs Microsoft's ODBC Driver 18 (macOS:
`brew tap microsoft/mssql-release && brew install msodbcsql18`).
