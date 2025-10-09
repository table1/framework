# README Sync System

The framework and framework-project repositories share a common section in their READMEs using HTML comment markers.

## How It Works

1. **Shared Content**: `.readme-shared/workflow.md` contains the shared documentation
2. **Markers**: Both READMEs use HTML comments to mark the shared section:
   - `<!-- BEGIN SHARED WORKFLOW -->`
   - `<!-- END SHARED WORKFLOW -->`
3. **Manual Sync**: Edit `.readme-shared/workflow.md` and manually copy to both READMEs between the markers

## Shared Section

The shared section documents the `make_notebook()` stub system:
- How to create notebooks and scripts
- Built-in stubs (default, minimal, revealjs)
- Custom stub creation
- Configuration options

## Updating

To update the shared content:

1. Edit `.readme-shared/workflow.md`
2. Copy the content
3. Paste between markers in `framework/README.md`
4. Paste between markers in `framework-project/README.md`

## Why Not Automated?

A pre-commit hook was attempted but proved fragile across different systems. Manual syncing is more reliable and only needed when changing the stub documentation.

## Locations

- **framework**: `/Users/erikwestlund/code/framework/README.md` (lines ~106-149)
- **framework-project**: `/Users/erikwestlund/code/framework-project/README.md` (lines ~69-112)
- **Shared source**: `/Users/erikwestlund/code/framework/.readme-shared/workflow.md`
