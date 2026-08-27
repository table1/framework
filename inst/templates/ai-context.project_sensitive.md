# {ProjectName}

This file provides guidance to AI assistants working with this Framework project.
It is the canonical context file; detailed workflow instructions live in the
skills listed below. Edit freely - add project-specific notes at the bottom.

**This is a privacy-sensitive project.** Follow the `framework-sensitive-data`
skill before ANY data operation, output, commit, or publish step. Never commit
or publish anything under a `private/` directory.

## Skills

Detailed instructions live in skill files, loaded on demand. Claude Code discovers
them automatically; other agents should read the relevant SKILL.md before working
on a matching task.

| Skill | Covers | Path |
|-------|--------|------|
| `framework-workflow` | scaffold() initialization, critical rules, creating notebooks/scripts | `.claude/skills/framework-workflow/SKILL.md` |
| `framework-data` | reading and saving data (data_read/data_save are mandatory) | `.claude/skills/framework-data/SKILL.md` |
| `framework-packages` | adding and managing R packages (package_add, never install.packages) | `.claude/skills/framework-packages/SKILL.md` |
| `framework-outputs` | results, caching, database queries, publishing | `.claude/skills/framework-outputs/SKILL.md` |
| `framework-sensitive-data` | PII/PHI handling and private/public directory rules | `.claude/skills/framework-sensitive-data/SKILL.md` |

## Framework Environment

This project uses the Framework R package. **Every notebook and script MUST
begin with `scaffold()`**, which sets the working directory, loads `.env`,
installs/attaches packages from settings.yml, and sources the functions
directory. See the `framework-workflow` skill before writing any code.

## Project Notes

*Add your project-specific notes, conventions, and documentation here.*
