.PHONY: build install check clean test help db-up db-down db-test

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
	@echo "  db-down            - Stop test databases and delete their data"
	@echo "  db-test            - Run the integration tests"
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

# Integration test servers (tests/integration/compose.yml)
COMPOSE = docker compose -f tests/integration/compose.yml

db-up:
	$(COMPOSE) up -d --wait

db-down:
	$(COMPOSE) down -v

db-test:
	NOT_CRAN=true Rscript -e 'devtools::test(filter = "integration|multi")'
