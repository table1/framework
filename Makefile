.PHONY: build install check clean test help db-up db-down db-test db-init-sqlserver

# Default target
help:
	@echo "Available targets:"
	@echo "  build              - Build the package tarball"
	@echo "  install            - Install the package locally"
	@echo "  check              - Run R CMD check"
	@echo "  test               - Run tests"
	@echo "  clean              - Clean build artifacts"
	@echo "  docs               - Generate documentation"
	@echo "  db-up              - Start all test databases (Docker)"
	@echo "  db-down            - Stop all test databases"
	@echo "  db-clean           - Stop databases and remove volumes"
	@echo "  db-test            - Test all database connections"
	@echo "  db-init-sqlserver  - Initialize SQL Server database"
	@echo "  help               - Show this help"

# Build package tarball
build:
	R CMD build .

# Install package locally
install: build
	R CMD INSTALL *.tar.gz

# Quick install (no tarball)
install-quick:
	R CMD INSTALL .

# Run R CMD check
check:
	R CMD check . --no-manual

# Run tests
test:
	R -e "testthat::test_dir('tests')"

# Clean build artifacts
clean:
	rm -f *.tar.gz
	rm -rf *.Rcheck

# Generate documentation
docs:
	R -e "devtools::document()"

# Full release workflow
release: clean docs test check
	@echo "Package ready for release!"

# Database management targets
db-up:
	@echo "Starting all test databases..."
	docker-compose -f docker-compose.test.yml up -d
	@echo "Waiting for databases to be healthy..."
	@sleep 10
	docker-compose -f docker-compose.test.yml ps

db-down:
	@echo "Stopping all test databases..."
	docker-compose -f docker-compose.test.yml down

db-clean:
	@echo "Stopping databases and removing volumes..."
	docker-compose -f docker-compose.test.yml down -v

db-test:
	@echo "Testing database connections..."
	./tests/docker/scripts/test-connections.R

db-init-sqlserver:
	@echo "Initializing SQL Server database..."
	./tests/docker/scripts/init-sqlserver.sh