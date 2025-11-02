# Directory Structure Decision: Flat Inputs

**Date**: 2025-10-30
**Framework Version**: 0.9+
**Status**: ✅ **ADOPTED**

## Decision

Framework adopts **flat input directory structure** for new projects:

```
inputs/
├── raw/                  # Raw hand-offs (gitignored)
├── intermediate/         # Cleaned but still input datasets (gitignored)
├── final/                # Curated analytic datasets (gitignored)
└── reference/            # External documentation/codebooks (gitignored)
```

## Rationale

### Zen Consensus Result

Both **Claude Sonnet 4** and **GPT-4o** recommended the flat structure with **8/10 confidence**.

**Key Reasoning:**

1. **Optimizes for common case**: 90% of data is private, making `private/` wrapper redundant overhead
2. **Navigation efficiency**: Reduces directory depth from 3 to 2 levels, providing measurable daily workflow benefits
3. **Industry alignment**: Cookiecutter Data Science and similar tools use flat structures (`data/raw/`, `data/processed/`)
4. **Philosophy match**: Better aligns with Framework's "convention over configuration" and minimal friction goals
5. **Usability > Symmetry**: Inputs and outputs have different access patterns (inputs read frequently, outputs written once)

### Comparison

| Aspect | Nested (inputs/public/raw/) | Flat (inputs/raw/) |
|--------|------------------------------|---------------------|
| **Depth** | 3 levels | 2 levels ✅ |
| **Common case** | Extra `private/` for 90% of data | No wrapper ✅ |
| **Navigation** | More cd commands | Faster ✅ |
| **Gitignore** | Multiple patterns | Single pattern per namespace: `inputs/raw/**`, etc. |
| **Symmetry with outputs/** | Matches (outputs/private/tables/) | Matches |
| **Industry precedent** | Less common | Cookiecutter Data Science ✅ |

## Implementation

### Changes Made (2025-10-30)

1. ✅ **Template structure** - Restructured `inst/project_structure/project/inputs/`
2. ✅ **Config** - Updated `settings/directories.yml` paths
3. ✅ **Gitignore** - Updated `.gitignore.fr` template
4. ✅ **README** - Updated directory tree in `readme-parts/02_quickstart.md`
5. ✅ **Migration guide** - Updated `docs/migration-0.9.0.md`
6. ⏳ **Git tracking** - Need to force-add `.gitkeep` files
7. ⏳ **Testing** - Need to verify with fresh project creation

### Updated Configuration

**settings/directories.yml:**
```yaml
directories:
  # Input data paths (read-only in code)
  inputs_raw: inputs/raw
  inputs_intermediate: inputs/intermediate
  inputs_final: inputs/final
  inputs_reference: inputs/reference
```

**.gitignore:**
```
# Input directories - Private data (NEVER commit these!)
inputs/raw/
inputs/raw/**
inputs/intermediate/
inputs/intermediate/**
inputs/final/
inputs/final/**
inputs/reference/
inputs/reference/**
```

## Migration Impact

**For existing projects**: No action required. Framework is config-driven and will continue to work with any directory structure defined in `settings.yml`.

**For new projects** (created after this change): Will use flat structure by default.

## Future Considerations

- Monitor user feedback on flat vs nested preference
- Consider making structure configurable via init() parameter if strong demand
- Document that users can customize structure via `settings.yml`

## References

- Zen Consensus output: Both models recommended flat with 8/10 confidence
- Industry precedent: [Cookiecutter Data Science](https://drivendata.github.io/cookiecutter-data-science/)
- Discussion thread: See git commit for this change
