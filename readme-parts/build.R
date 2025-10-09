#!/usr/bin/env Rscript
# Build README.md from parts in readme-parts/

# Get all numbered markdown files in order
parts <- list.files("readme-parts", pattern = "^[0-9]+_.*\\.md$", full.names = TRUE)
parts <- sort(parts)

if (length(parts) == 0) {
  stop("No numbered parts found in readme-parts/")
}

# Read and combine all parts
content <- sapply(parts, function(f) {
  paste(readLines(f, warn = FALSE), collapse = "\n")
})

# Combine with blank lines between sections
readme <- paste(content, collapse = "\n\n")

# Write to README.md
writeLines(readme, "README.md")

cat("✓ Built README.md from", length(parts), "parts\n")
cat("Parts used:\n")
for (part in basename(parts)) {
  cat("  -", part, "\n")
}
