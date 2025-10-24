#!/bin/bash
# Initialize SQL Server test database
# SQL Server doesn't support docker-entrypoint-initdb.d in the same way,
# so we need to wait for the server to start and then run the init script

set -e

echo "Waiting for SQL Server to be ready..."

# Wait for SQL Server to be healthy
until docker exec framework_test_sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Framework_Test_Pass123!" -Q "SELECT 1" > /dev/null 2>&1
do
    echo "SQL Server is unavailable - sleeping"
    sleep 5
done

echo "SQL Server is up - initializing database..."

# Run the initialization script
docker exec -i framework_test_sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Framework_Test_Pass123!" < "$(dirname "$0")/../sqlserver/init.sql"

echo "SQL Server initialization complete!"
