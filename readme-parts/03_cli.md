## Command Line Interface

The Framework CLI provides a `framework` command that automatically adapts based on where you are:
- **Outside projects**: Create new projects (`framework new`)
- **Inside projects**: Project commands like `framework make:notebook`, `framework scaffold`

### Installation

**One-line install**:
```bash
curl -fsSL https://raw.githubusercontent.com/table1/framework/main/inst/bin/install-cli.sh | bash
```

Or from R:
```r
framework::cli_install()
```

This installs the `framework` command and adds it to your PATH.

### Project Commands

Once inside a Framework project:

```bash
framework scaffold           # Load packages, install dependencies
framework make:notebook analysis  # Create notebooks/analysis.qmd
framework make:script process     # Create scripts/process.R
```

### Updating

```bash
framework update      # Update Framework package on your system
```
