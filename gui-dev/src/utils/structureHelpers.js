/**
 * Normalize project structure directories from catalog metadata and optional user defaults.
 * Accepts catalog entries as either strings or objects with { default, enabled_by_default }.
 */
export const normalizeDirectoriesFromCatalog = (
  catalogDirectories = {},
  userDirectories = {},
  userEnabled = {},
  fallbackDirectories = {}
) => {
  const normalizePath = (entry) => {
    if (typeof entry === 'string') return entry
    if (entry && typeof entry === 'object') return entry.default || ''
    return ''
  }

  const directories = {}
  const directories_enabled = {}

  Object.entries(catalogDirectories).forEach(([key, entry]) => {
    const catalogDefault = normalizePath(entry)
    const fallback = fallbackDirectories[key] || ''

    directories[key] = userDirectories[key] || catalogDefault || fallback

    if (userEnabled[key] !== undefined) {
      directories_enabled[key] = userEnabled[key]
    } else if (entry && typeof entry === 'object' && entry.enabled_by_default !== undefined) {
      directories_enabled[key] = entry.enabled_by_default === true
    } else {
      directories_enabled[key] = true
    }
  })

  return { directories, directories_enabled }
}

export const normalizeRenderDirsFromCatalog = (catalogRenderDirs = {}, userRenderDirs = {}, fallbackRenderDirs = {}) => {
  const normalizePath = (entry) => {
    if (typeof entry === 'string') return entry
    if (entry && typeof entry === 'object') return entry.default || ''
    return ''
  }

  const render_dirs = {}
  Object.entries(catalogRenderDirs).forEach(([key, entry]) => {
    const catalogDefault = normalizePath(entry)
    const fallback = fallbackRenderDirs[key] || ''
    render_dirs[key] = userRenderDirs[key] || catalogDefault || fallback
  })

  return render_dirs
}

/**
 * Filter extra_directories: remove incomplete entries and those explicitly disabled.
 */
export const filterExtraDirectories = (extraDirectories = [], enabled = {}) =>
  (extraDirectories || []).filter((dir) => {
    if (!dir.key || !dir.label || !dir.path || !dir.type) return false
    if (enabled && enabled[dir.key] === false) return false
    return true
  })

/**
 * Normalize enabled map to only valid keys (catalog dirs + extra dirs).
 */
export const cleanEnabledMap = (catalogDirs = {}, extraDirectories = [], enabled = {}) => {
  const validKeys = new Set()
  Object.keys(catalogDirs || {}).forEach((key) => validKeys.add(key))
  ;(extraDirectories || []).forEach((dir) => {
    if (dir.key) validKeys.add(dir.key)
  })
  const cleaned = {}
  Object.keys(enabled || {}).forEach((key) => {
    if (validKeys.has(key)) cleaned[key] = enabled[key]
  })
  return cleaned
}
