# devtools::install_github("table1/framework", force = TRUE)
#
# if ("framework" %in% loadedNamespaces()) {
#   detach("package:framework", unload = TRUE)
# }

library(framework)
scaffold()

config

# Read in config programatically
config <- read_config()
config

# Read in data
data <- load_data("source.private.example")
data |> head()

# Save data
save_data(data, "final.private.example")

# Query databases
## SQLite
get_query("SELECT 1", "framework")
execute_query("SELECT 1", "framework")

## Postgres
get_query("SELECT id, name from users", "db")
execute_query("SELECT 1", "db")

# Save results
save_result("test", 1 + 1, "test")
get_result("test")

save_result("report.html", file = "Example-Notebook.html", type = "report", blind = FALSE, public = TRUE)
get_result("report.html")

save_result(
  name = "report.html",
  file = "test-notebook.html",
  type = "report",
  blind = FALSE,
  public = TRUE,
  comment = "Final results."
)
list_results() |> kable()

# Caching
get_or_cache("test", {
  1 + 1
})
get_cache("test")
uncache("test")

cache("test2", 1 + 1)
get_cache("test2")
uncache("test2")

# Get or cache: if the cache exists, it will be returned, otherwise the function will be executed and the result will be cached
get_or_cache("test3", 2 + 2)
get_cache("test3")
uncache("test3")

# Get and cache: reset the cache with the object and let you grab it later.
get_and_cache("test4", {
  1 + 1
})
get_cache("test4")

get_and_cache("test4", {
  1 + 2
})

get_cache("test4")
forget_cache("test4")

# Clear all cache
get_cache("test5")
get_cache("test6")
clear_cache()
get_cache("test5")
