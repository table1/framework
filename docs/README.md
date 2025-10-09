# Framework Documentation

This directory contains development documentation for the Framework R package.

## Directory Structure

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

### `architecture/` (future)
Design documents and architectural decision records (ADRs)

### `api/` (future)
API documentation and usage guides

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
