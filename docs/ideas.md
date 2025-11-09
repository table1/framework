# Directory Hygiene Helper

- Build a `framework prune-empty` CLI (or `framework::prune_empty()` helper) that scans the project for empty directories created by the scaffold.
- Present an interactive prompt (batch flag optional) that lists candidates grouped by top-level bucket (`inputs/`, `outputs/`, etc.).
- Let users choose which directories to remove; skip anything added manually to the allowlist (e.g., `.gitkeep` presence or a comment in `framework.yml`).
- Support a dry-run mode that logs what would be removed alongside the total disk footprint recovered.
- Consider hooking into scaffold or release workflow to suggest a cleanup when no tracked files exist in the generated namespace.

# Manifest + Helper Concepts

- `data_add(path, key = NULL, manifest = "data.yml")`: derive `key` from basename when omitted, strip project root, and append metadata (`path`, timestamp, optional description) under nested keys based on subdirectories (e.g., `inputs/raw/unit_1/file.csv` → `unit_1`).
- Mirror helpers (`slides_add()`, `assignment_add()`, etc.) so each starter pack component has an ergonomic way to register artifacts.
- Provide companion utilities (`data_list()`, `data_remove()`) to inspect and prune manifest entries without hand-editing YAML.

# Post-Project-Creation Hook

**Use Case:** Automatically perform custom actions after creating a new Framework project.

**Motivation:**
- Users have personal workflows that should trigger when new projects are created
- Examples: tmux session setup, IDE workspace configuration, project registration in external systems
- Likely power-user feature but provides extensibility without bloating core Framework

**Design:**

1. **Hook Location:** `~/.config/framework/hooks/post-create` (or `hooks/post-create.R`)

2. **Input:** Hook receives project metadata as JSON or R list:
   ```r
   # Example data structure passed to hook:
   list(
     name = "My Analysis Project",
     path = "/Users/erik/framework-projects/my-analysis-project",
     type = "project",
     author = list(
       name = "Erik Westlund",
       email = "erik@example.com",
       affiliation = "Organization"
     ),
     settings = list(
       ide = "vscode",
       use_git = TRUE,
       use_renv = FALSE,
       notebook_format = "quarto",
       directories = list(...)
     ),
     created_at = "2025-11-08T10:30:00Z"
   )
   ```

3. **Hook Execution:**
   - Hook is optional - if file doesn't exist, skip silently
   - Execute after project creation succeeds but before returning to user
   - Run in isolated environment (don't pollute session)
   - Capture stdout/stderr for debugging
   - Non-zero exit code triggers warning but doesn't fail project creation

4. **Example Use Cases:**

   **tmux Session Setup:**
   ```bash
   #!/bin/bash
   # ~/.config/framework/hooks/post-create

   # Parse JSON input (or use R to read passed data)
   PROJECT_NAME="$1"
   PROJECT_PATH="$2"

   # Create tmux session file
   cat > ~/projects/tmux/${PROJECT_NAME}.yml <<EOF
   name: ${PROJECT_NAME}
   root: ${PROJECT_PATH}
   windows:
     - shell:
         panes:
           - cd ${PROJECT_PATH}
     - ai-agents:
         panes:
           - cd ${PROJECT_PATH} && cursor .
     - r-repl:
         panes:
           - cd ${PROJECT_PATH} && R
   EOF

   echo "✓ Created tmux session config: ~/projects/tmux/${PROJECT_NAME}.yml"
   ```

   **Project Registration:**
   ```r
   # ~/.config/framework/hooks/post-create.R
   post_create_hook <- function(project_data) {
     # Add to personal project tracker
     tracker_file <- "~/Documents/my-projects.csv"
     new_row <- data.frame(
       name = project_data$name,
       path = project_data$path,
       type = project_data$type,
       created = project_data$created_at
     )

     if (file.exists(tracker_file)) {
       existing <- read.csv(tracker_file)
       updated <- rbind(existing, new_row)
     } else {
       updated <- new_row
     }

     write.csv(updated, tracker_file, row.names = FALSE)
     message("✓ Added to project tracker: ", tracker_file)
   }
   ```

5. **Implementation Notes:**
   - Hook should be fast (< 1 second) to avoid blocking GUI
   - Consider async execution for slow operations
   - Provide clear error messages if hook fails
   - Document hook contract in Framework docs
   - Maybe add `framework::hooks_list()` to show registered hooks
   - Consider pre-create hooks too (validation, quota checks, etc.)

**Priority:** Medium - Nice to have for power users, but not blocking core functionality
