# Framework Documentation

This directory contains development documentation for the Framework R package.

## Directory Structure

### User Guides

- **`database-getting-started.md`** - Complete guide to using Framework's database functionality
  - Which databases are supported and what drivers are needed
  - How to install and configure database drivers
  - Configuration examples for all 5 database backends
  - Common tasks (CRUD, transactions, queries)
  - Troubleshooting and best practices

- **`connection-pooling.md`** - Connection pooling guide (RECOMMENDED)
  - Why use connection pools vs manual connections
  - Quick start and configuration
  - Common patterns (notebooks, Shiny apps, scripts, dbplyr)
  - Pool management and debugging
  - Performance tuning and best practices

- **`multi-database-support.md`** - Technical reference for database support
  - Full API documentation for all database functions
  - Driver management functions (`drivers_status()`, `drivers_install()`, `connection_check()`)
  - Cross-database features (soft deletes, auto-timestamps, schema introspection)
  - Architecture notes and implementation details

### Developer Documentation

### `CLAUDE.md`
Development standards and conventions for AI assistants and developers working on the package. Covers:
- Code quality standards
- Error handling patterns
- Testing guidelines
- Documentation requirements
- Git commit standards

### `debug/`
Debugging logs, bug reports, and fix documentation:
- `BUG_FIXES.md` - Log of bugs discovered and fixed during development

### `features/`
Feature proposals and development tracking

### `architecture/` (future)
Design documents and architectural decision records (ADRs)

## Documentation Philosophy

1. **Keep root clean** - Detailed notes go in `docs/`, not project root
2. **Document as you go** - Add notes during development, not after
3. **Be specific** - Include file paths, line numbers, error messages
4. **Show examples** - Good and bad code examples for clarity
5. **Explain why** - Document rationale for decisions

## For AI Assistants

When working on the Framework package:
1. Read `CLAUDE.md` for coding standards
2. Place bug reports in `debug/`
3. Document architectural decisions in `architecture/`
4. Update this README when adding new documentation categories

## For Developers

This documentation is optimized for AI-assisted development but useful for all contributors. Follow the standards in `CLAUDE.md` to maintain code quality and consistency.
