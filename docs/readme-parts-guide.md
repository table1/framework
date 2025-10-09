# README Parts System Guide

Both framework and framework-project repos use a modular README system for easy maintenance.

## Quick Reference

### Framework Repo (6 parts)
```bash
cd ~/code/framework
vim readme-parts/4_usage_notebooks.md  # Edit shared content here
Rscript readme-parts/build.R           # Rebuild README.md
```

### Framework-Project Repo (5 parts, omits part 4)
```bash
cd ~/code/framework-project
vim readme-parts/2_quickstart.md       # Edit quickstart
Rscript readme-parts/build.R           # Rebuild README.md
```

## Part Structure

### Framework
1. `1_header.md` - Title and description
2. `2_quickstart.md` - Installation and project types
3. `3_workflow_intro.md` - "Core Workflow" header + step 1
4. `4_usage_notebooks.md` - **Step 2: make_notebook() usage** ← SHARED
5. `5_usage_data.md` - Steps 3-6: Load data, cache, results, queries
6. `6_rest.md` - Configuration, functions table, security, renv, etc.

### Framework-Project
1. `1_header.md` - Same as framework
2. `2_quickstart.md` - Same as framework
3. `3_workflow_intro.md` - Same as framework
4. **(omitted)** - No notebook usage documentation
5. `5_usage_data.md` - **Renumbered to steps 2-5** (not 3-6)
6. `6_rest.md` - Same as framework

## Updating Shared Content

The `make_notebook()` documentation in part 4 is shared between repos:

### Step-by-Step

1. **Always edit in framework repo:**
   ```bash
   cd ~/code/framework
   vim readme-parts/4_usage_notebooks.md
   ```

2. **Build framework README:**
   ```bash
   Rscript readme-parts/build.R
   ```

3. **If you want to include it in framework-project** (optional):
   ```bash
   cp readme-parts/4_usage_notebooks.md ~/code/framework-project/readme-parts/
   cd ~/code/framework-project
   # Renumber it from "### 2." to match the flow
   # Then build
   Rscript readme-parts/build.R
   ```

**Note:** Typically framework-project omits part 4 entirely. It's for package users, not template users.

## Adding New Content

### To framework only:
- Add to the appropriate part (usually `6_rest.md`)
- Run `Rscript readme-parts/build.R`

### To both repos:
- Decide if it should be in an existing part or a new part
- If new shared part, add to both repos
- Update this guide

## Benefits

✅ **Modular** - Edit only the section you need
✅ **Clear** - Numbered parts show structure
✅ **Shared** - Part 4 is obviously special
✅ **Simple** - Just R script, no complex hooks
✅ **Versioned** - Parts are in git, changes tracked
✅ **Flexible** - Easy to add/remove/reorder parts

## Troubleshooting

**README looks wrong after build?**
- Check you're in the correct repo (framework vs framework-project)
- Verify all expected parts exist: `ls readme-parts/*.md`
- Check build output: `Rscript readme-parts/build.R`

**Want to sync part 4?**
```bash
# Always copy FROM framework TO framework-project (if needed)
cp ~/code/framework/readme-parts/4_usage_notebooks.md \
   ~/code/framework-project/readme-parts/
```

**Want to omit part 4 from framework-project again?**
```bash
cd ~/code/framework-project
rm readme-parts/4_usage_notebooks.md
Rscript readme-parts/build.R
```
