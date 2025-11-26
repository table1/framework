import {
  normalizeDirectoriesFromCatalog,
  normalizeRenderDirsFromCatalog,
  filterExtraDirectories,
  cleanEnabledMap
} from './structureHelpers'

/**
 * Build editor-ready structure state from catalog + user defaults (Settings/New).
 */
export const hydrateStructureFromCatalog = (catalogType = {}, userType = {}, fallbackDirs = {}, fallbackRenderDirs = {}) => {
  const { directories, directories_enabled } = normalizeDirectoriesFromCatalog(
    catalogType.directories || {},
    userType.directories || {},
    userType.directories_enabled || {},
    fallbackDirs
  )

  const render_dirs = normalizeRenderDirsFromCatalog(
    catalogType.render_dirs || {},
    userType.render_dirs || {},
    fallbackRenderDirs
  )

  const extra_directories = userType.extra_directories || []
  const enabled = {
    ...directories_enabled,
    ...(userType.directories_enabled || {})
  }

  return {
    directories,
    directories_enabled,
    render_dirs,
    extra_directories,
    enabled
  }
}

/**
 * Build editor-ready structure state from project settings payload (Project Detail).
 * Assumes payload already uses string paths; still cleans enabled keys.
 */
export const hydrateStructureFromProjectSettings = (settings = {}, catalogDirs = {}) => {
  const directories = settings.directories || {}
  const render_dirs = settings.render_dirs || {}
  const extra_directories = settings.extra_directories || []
  const enabled = cleanEnabledMap(catalogDirs, extra_directories, settings.enabled || {})

  return {
    directories,
    render_dirs,
    extra_directories,
    enabled
  }
}

/**
 * Serialize editor state to payload for save (both defaults and project save).
 * - Cleans extra_directories (drop incomplete/disabled)
 * - Cleans enabled map to valid keys
 */
export const serializeStructureForSave = ({ catalogDirs = {}, directories = {}, render_dirs = {}, enabled = {}, extra_directories = [] }) => {
  const cleanedEnabled = cleanEnabledMap(catalogDirs, extra_directories, enabled)
  const filteredExtras = filterExtraDirectories(extra_directories, cleanedEnabled)

  return {
    directories,
    render_dirs,
    enabled: cleanedEnabled,
    extra_directories: filteredExtras
  }
}
