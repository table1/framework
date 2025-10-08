.PHONY: build install check clean test help

# Default target
help:
	@echo "Available targets:"
	@echo "  build    - Build the package tarball"
	@echo "  install  - Install the package locally"
	@echo "  check    - Run R CMD check"
	@echo "  test     - Run tests"
	@echo "  clean    - Clean build artifacts"
	@echo "  docs     - Generate documentation"
	@echo "  help     - Show this help"

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