## AI Guidance Issues

Documenting specific failure patterns we keep hitting while dogfooding framework so we can improve our prompts, helpers, or tooling.

1. **data.yml hallucinations** – Claude confidently invents a new structure for `data.yml` even when provided the correct format. Feeding it the actual file works, but it still rewrites the schema from scratch.
2. **package loading amnesia** – It rarely remembers that `framework()` automatically loads packages declared in `packages.yml`, so it keeps suggesting `library(dplyr)` or similar explicit calls.
3. **working directory confusion** – Claude forgets that `framework()` normalizes the working directory and repeatedly reaches for `here::here()` scaffolding that we no longer need.
4. **ignoring data_read helpers** – Instead of using our `data_read_*` helpers it reaches for base `load()` or `readr` calls, or simply skips over the data-loading step entirely.

These keep costing us time when we rely on AI assistance, so we need prompt/context improvements or lint-style guardrails to prevent regressions.
