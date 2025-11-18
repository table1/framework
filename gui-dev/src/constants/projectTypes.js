/**
 * Project Type Constants
 *
 * These constants define the structure and optional directories for each project type.
 * They should match the settings catalog (inst/config/settings-catalog.yml).
 */

/**
 * Optional directories for presentation project type
 * These directories have enabled_by_default: false in the catalog
 *
 * IMPORTANT: This list must stay in sync with:
 * - inst/config/settings-catalog.yml (presentation.directories where enabled_by_default: false)
 * - NewProjectView.vue (uses currentProjectTypeOptionalDirectories computed from catalog)
 * - SettingsView.vue (uses presentationOptions reactive object)
 */
export const PRESENTATION_OPTIONAL_DIRECTORIES = [
  'inputs',
  'outputs',
  'scripts',
  'functions'
]

/**
 * Presentation directory metadata
 * Used for labels, descriptions, and defaults
 */
export const PRESENTATION_DIRECTORY_META = {
  inputs: {
    label: 'Inputs',
    description: 'Raw data or reference materials for the presentation.',
    default: 'inputs'
  },
  outputs: {
    label: 'Outputs',
    description: 'Figures, tables, and other presentation outputs.',
    default: 'outputs'
  },
  scripts: {
    label: 'Scripts',
    description: 'Data processing or analysis scripts.',
    default: 'scripts'
  },
  functions: {
    label: 'Functions',
    description: 'Helper functions for analysis or visualization.',
    default: 'functions'
  }
}
