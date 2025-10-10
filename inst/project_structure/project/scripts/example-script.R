#!/usr/bin/env Rscript
# Example Script
#
# This is an example R script demonstrating Framework usage.
# Delete this file and create your own scripts with make_script().

# Load project environment
library(framework)
scaffold()

# Example workflow:
# 1. Load data from catalog
# data <- load_data("source.private.example")

# 2. Process data
# processed <- data %>%
#   # Your transformations here

# 3. Save results
# save_data(processed, "results.processed")

message("Script completed successfully!")
