## Configuration

**Simple:**
```yaml
default:
  packages:
    - dplyr
    - ggplot2
  data:
    example: data/example.csv
```

**Advanced:** Split config into `settings/` files:
```yaml
default:
  data: settings/data.yml
  packages: settings/packages.yml
  connections: settings/connections.yml
  security: settings/security.yml
```

Use `.env` for secrets:
```env
DB_HOST=localhost
DB_PASS=secret
DATA_ENCRYPTION_KEY=key123
```

Reference in config (two syntaxes supported):
```yaml
# Recommended: Clean env() syntax
security:
  data_key: env("DATA_ENCRYPTION_KEY")
connections:
  db:
    host: env("DB_HOST")
    password: env("DB_PASS", "default_password")  # With default

# Also works: Traditional !expr syntax
security:
  data_key: !expr Sys.getenv("DATA_ENCRYPTION_KEY")
```

### AI Assistant Support

Framework can create instruction files that help AI coding assistants understand your project structure:

```r
# During CLI install, you'll be asked once about AI support
framework::cli_install()

# Reconfigure AI assistant preferences anytime
framework::configure_ai_agents()

# Or via CLI
framework configure ai-agents
```

Supported assistants:
- **Claude Code** (CLAUDE.md)
- **GitHub Copilot** (.github/copilot-instructions.md)
- **AGENTS.md** (cross-platform standard)

Your preferences are stored in `~/.frameworkrc` and used as defaults for new projects.
