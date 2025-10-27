# Connection Pooling

Connection pooling is the **recommended way** to work with databases in Framework. Pools automatically manage connection lifecycle, reuse connections for better performance, and handle failures gracefully.

## Why Use Connection Pools?

**Without pooling (manual connections):**
```r
# Every query creates a new connection
conn1 <- connection_get("my_db")
users <- DBI::dbGetQuery(conn1, "SELECT * FROM users")
DBI::dbDisconnect(conn1)

conn2 <- connection_get("my_db")
posts <- DBI::dbGetQuery(conn2, "SELECT * FROM posts")
DBI::dbDisconnect(conn2)  # Easy to forget!
```

**Problems:**
- ❌ Connection overhead on every query
- ❌ Easy to forget to disconnect
- ❌ Connection leaks if errors occur
- ❌ No automatic reconnection on failures

**With pooling:**
```r
# Create pool once
pool <- connection_pool("my_db")

# Reuse connections automatically
users <- DBI::dbGetQuery(pool, "SELECT * FROM users")
posts <- DBI::dbGetQuery(pool, "SELECT * FROM posts")

# No need to disconnect - pool manages everything
```

**Benefits:**
- ✅ Automatic connection reuse (faster)
- ✅ No manual cleanup required
- ✅ Graceful error handling and reconnection
- ✅ Thread-safe for Shiny apps
- ✅ Health checking (validates connections before use)
- ✅ Configurable limits (min/max connections)

## Quick Start

### 1. Install pool Package

```r
install.packages("pool")
```

### 2. Enable Pooling in settings.yml

```yaml
connections:
  my_db:
    driver: postgres
    host: localhost
    port: 5432
    database: mydb
    user: myuser
    password: ${DB_PASSWORD}

    # Enable connection pooling
    pool: true
    pool_min_size: 1
    pool_max_size: 5
```

### 3. Use as Normal

```r
library(framework)

# Pooling happens automatically
users <- query_get("SELECT * FROM users", "my_db")
posts <- query_get("SELECT * FROM posts", "my_db")

# Or with manual connections
conn <- connection_get("my_db")  # Returns a pool
result <- DBI::dbGetQuery(conn, "SELECT * FROM users")
# No disconnect needed - pool manages it
```

That's it! Framework handles the rest automatically.

## Configuration

### Basic Pool Configuration

Enable pooling by adding `pool: true` to any connection in `settings.yml`:

```yaml
connections:
  # Remote database - enable pooling (recommended)
  postgres_prod:
    driver: postgres
    host: remote.example.com
    database: mydb
    user: analyst
    password: ${DB_PASSWORD}
    pool: true  # Enable connection pooling

  # Local database - no pooling needed
  local_sqlite:
    driver: sqlite
    database: data/local.db
    # pool: false (default)
```

### Advanced Pool Settings

Fine-tune pool behavior per connection:

```yaml
connections:
  my_db:
    driver: postgres
    host: localhost
    database: mydb
    user: myuser
    password: ${DB_PASSWORD}

    # Pool configuration
    pool: true
    pool_min_size: 1               # Minimum connections to keep alive
    pool_max_size: 10              # Maximum concurrent connections
    pool_idle_timeout: 60          # Close idle connections after 60s
    pool_validation_interval: 60   # Check connection health every 60s
```

**Recommendations by Use Case:**

| Use Case | min_size | max_size | Why |
|----------|----------|----------|-----|
| Solo analysis | 1 | 3 | Low concurrency, save resources |
| Shared analysis server | 2 | 10 | Multiple users, balanced resources |
| Shiny app (production) | 2 | 20 | Handle traffic spikes |
| High-volume ETL | 1 | 5 | Sequential processing, control load |

## Common Patterns

### Notebook / Interactive Session

```r
# At the top of your notebook
library(framework)
pool <- connection_pool("my_db")

# Throughout the notebook, use the pool
users <- DBI::dbGetQuery(pool, "SELECT * FROM users")
# ... analysis ...
posts <- DBI::dbGetQuery(pool, "SELECT * FROM posts")
# ... more analysis ...

# No cleanup needed - pool persists across code chunks
```

### Shiny Application

```r
# server.R or app.R
library(shiny)
library(framework)

# Create pool once when app starts
pool <- connection_pool("my_db", min_size = 2, max_size = 20)

# Register cleanup when app stops
onStop(function() {
  connection_pool_close("my_db")
})

server <- function(input, output, session) {
  # All users share the same pool
  output$users_table <- renderTable({
    DBI::dbGetQuery(pool, "SELECT * FROM users LIMIT 10")
  })

  observeEvent(input$refresh, {
    # Pool handles concurrent access safely
    data <- DBI::dbGetQuery(pool, "SELECT * FROM latest_data")
    # ... update UI ...
  })
}
```

### Long-Running Script

```r
#!/usr/bin/env Rscript
library(framework)

# Create pool at start
pool <- connection_pool("analytics_db")

# Process data in batches
for (batch in 1:100) {
  # Pool reuses connections efficiently
  data <- DBI::dbGetQuery(pool, sprintf("SELECT * FROM data WHERE batch = %d", batch))

  # Process...
  results <- analyze(data)

  # Write back
  DBI::dbWriteTable(pool, "results", results, append = TRUE)

  message(sprintf("Processed batch %d", batch))
}

# Optional cleanup at end
connection_pool_close("analytics_db")
```

### with dbplyr

```r
library(dplyr)
library(dbplyr)
library(framework)

# Get pool
pool <- connection_pool("my_db")

# Use with dplyr verbs
users_tbl <- tbl(pool, "users")

active_users <- users_tbl %>%
  filter(status == "active") %>%
  select(id, name, email) %>%
  collect()

# Pool handles all connections behind the scenes
```

## Pool Management

### List Active Pools

```r
# See all pools
connection_pool_list()
```

Output:
```
     name valid connections
  my_db  TRUE           2
  analytics_db  TRUE           1
```

### Close a Specific Pool

```r
# Close when done (optional)
connection_pool_close("my_db")
```

### Close All Pools

```r
# Cleanup everything (useful in .Rprofile or onStop)
connection_pool_close_all()
```

### Recreate a Pool

```r
# Force recreate (e.g., after config change)
pool <- connection_pool("my_db", recreate = TRUE)
```

## When NOT to Use Pools

Pools add slight overhead. Skip them for:

**✅ Use `query_get()` instead:**
```r
# One-off query in short script
users <- query_get("SELECT * FROM users", "my_db")
```

**✅ Use `connection_with()` instead:**
```r
# Few operations, then done
result <- connection_with("my_db", {
  DBI::dbGetQuery(conn, "SELECT * FROM users")
})
```

**❌ Don't use pools:**
- Scripts that run once and exit immediately
- Single query, then done
- Prototype/exploratory code
- When pool package isn't installed

## Error Handling

Pools handle errors gracefully:

```r
pool <- connection_pool("my_db")

# Connection fails? Pool auto-reconnects
tryCatch({
  result <- DBI::dbGetQuery(pool, "SELECT * FROM users")
}, error = function(e) {
  message("Query failed, but pool is still valid")
  # Pool will automatically reconnect on next query
})

# Next query works fine
users <- DBI::dbGetQuery(pool, "SELECT * FROM users")
```

## Debugging Connection Issues

### Check if Pool is Valid

```r
pool::dbIsValid(pool)  # TRUE if pool is healthy
```

### Monitor Connection Count

```r
# See active connections
connection_pool_list()
```

### Check for Connection Leaks

```r
# If using manual connections instead of pools
connection_check_leaks()  # Warns about unclosed connections
```

### Force Pool Refresh

```r
# If pool seems stuck
connection_pool_close("my_db")
pool <- connection_pool("my_db")
```

## Performance Tips

### Tune Pool Size

```r
# Too few connections = waiting
pool <- connection_pool("my_db", max_size = 3)  # May wait for available connection

# Too many connections = overwhelming database
pool <- connection_pool("my_db", max_size = 100)  # Database may reject

# Just right (start here)
pool <- connection_pool("my_db", min_size = 2, max_size = 10)
```

### Idle Timeout

```r
# Close idle connections quickly (saves resources)
pool <- connection_pool("my_db", idle_timeout = 30)

# Keep connections alive longer (fewer reconnections)
pool <- connection_pool("my_db", idle_timeout = 300)
```

### Validation Interval

```r
# Check connections frequently (safer, slight overhead)
pool <- connection_pool("my_db", validation_interval = 30)

# Check connections rarely (faster, might use stale connections)
pool <- connection_pool("my_db", validation_interval = 300)
```

## Comparison: pool vs manual connections

| Feature | `connection_pool()` | `connection_get()` |
|---------|---------------------|-------------------|
| **Setup** | Once per R session | Every operation |
| **Cleanup** | Automatic | Manual (`dbDisconnect`) |
| **Reuse** | Yes (fast) | No (new connection each time) |
| **Error recovery** | Auto-reconnect | Must handle manually |
| **Thread-safe** | Yes | No |
| **Health checks** | Automatic | None |
| **When to use** | Long sessions, Shiny apps | Short scripts, one-off queries |

## Migration Guide

### From Manual Connections

**Before:**
```r
conn <- connection_get("my_db")
users <- DBI::dbGetQuery(conn, "SELECT * FROM users")
posts <- DBI::dbGetQuery(conn, "SELECT * FROM posts")
DBI::dbDisconnect(conn)
```

**After:**
```r
pool <- connection_pool("my_db")
users <- DBI::dbGetQuery(pool, "SELECT * FROM users")
posts <- DBI::dbGetQuery(pool, "SELECT * FROM posts")
# No disconnect needed
```

### From query_get()

**Before:**
```r
users <- query_get("SELECT * FROM users", "my_db")
posts <- query_get("SELECT * FROM posts", "my_db")
```

**After (if many queries):**
```r
pool <- connection_pool("my_db")
users <- DBI::dbGetQuery(pool, "SELECT * FROM users")
posts <- DBI::dbGetQuery(pool, "SELECT * FROM posts")
```

**Or keep query_get() if just a few queries** - it's fine for simple cases!

## Best Practices

1. **Create pools early** - Top of script or app startup
2. **Reuse pools** - Don't create new pools unnecessarily
3. **Configure limits** - Set sensible `max_size` for your database
4. **Clean up in production** - Use `onStop()` in Shiny apps
5. **Use `connection_with_pool()`** - For cleaner code
6. **Monitor in production** - Use `connection_pool_list()` to check health
7. **Don't over-pool** - For simple scripts, `query_get()` is fine

## Troubleshooting

### "pool package not installed"

```r
install.packages("pool")
```

### "Too many connections"

Reduce `max_size`:
```r
pool <- connection_pool("my_db", max_size = 5)
```

### Pool seems stuck

Recreate it:
```r
connection_pool_close("my_db")
pool <- connection_pool("my_db")
```

### Shiny app not releasing connections

Add cleanup:
```r
onStop(function() {
  connection_pool_close_all()
})
```
