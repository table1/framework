---
title: Retrieve Cached Computation
category: Caching
tags: caching, performance, memoization
---

# Retrieve Cached Computation

Retrieve a previously cached computation result. Works with cache_write()
and get_or_cache() to provide fast access to expensive computations.


## Usage

```r
cache_get(name, default = NULL)
```
## Parameters

- **`name`** (character) *(required)*: Name of the cached item to retrieve
- **`default`** (any): Value to return if cache miss or expired

## Returns

The cached object if found and valid, otherwise the default value.
Returns NULL if cache miss and no default specified.

## Details

cache_get() is part of Framework's caching system for expensive computations:

**How it works:**
- Looks up cache entry in framework.db
- Checks if cache is expired (if expiration set)
- Verifies cache file integrity via hash
- Loads and returns cached object
- Updates last_read_at timestamp

**Cache expiration:**
- Respects expire_at timestamp from cache_write()
- Returns default if expired
- Use cache = Inf for never-expiring cache

**Performance:**
- Fast lookup via SQLite index
- Hash verification prevents corruption
- Updates access time for cache management

**Common patterns:**
- Check cache first, compute if missing
- Use get_or_cache() for automatic pattern
- Pair with cache_delete() for invalidation
## Examples

```r
# Try to get cached result
result <- cache_get("expensive_analysis")
if (is.null(result)) {
  result <- expensive_function()
  cache_write("expensive_analysis", result)
}

```

Manual cache check pattern

```r
# Provide default value for cache miss
result <- cache_get("analysis", default = data.frame())

```

Cache with fallback default

```r
# Better: use get_or_cache() for automatic pattern
result <- get_or_cache("expensive_analysis", {
  expensive_function()
})

```

Recommended approach using get_or_cache()

```r
# Check what's in cache
cache_list()  # See all cached items
cache_get("my_cache")  # Retrieve specific item

```

Exploring cached items## See Also

- [`cache_write()`](cache_write) - Store computation result in cache
- [`get_or_cache()`](get_or_cache) - Get cached value or compute and cache
- [`cache_delete()`](cache_delete) - Remove item from cache## Notes

- Cache files stored in directory specified by config("cache")
- Default cache directory is data/cached/
- Use cache_list() to see all cached items and expiration
- Cache integrity verified via MD5 hash
