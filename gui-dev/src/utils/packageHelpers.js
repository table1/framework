// Helpers for normalizing package settings between API payloads and UI components.

const normalizePackageEntry = (pkg = {}) => ({
  name: pkg.name || '',
  source: pkg.source || 'cran',
  auto_attach: pkg.auto_attach !== false
})

// Defaults/global settings: input can be array or { use_renv, default_packages }
export const normalizeDefaultPackages = (value) => {
  if (!value) {
    return { use_renv: false, default_packages: [] }
  }

  // Already in nested shape
  if (value.default_packages) {
    return {
      use_renv: !!value.use_renv,
      default_packages: (value.default_packages || []).map(normalizePackageEntry)
    }
  }

  // Legacy flat array
  if (Array.isArray(value)) {
    return {
      use_renv: false,
      default_packages: value.map(normalizePackageEntry)
    }
  }

  return { use_renv: !!value.use_renv, default_packages: [] }
}

export const mapDefaultPackagesToPayload = (packagesModel = {}) => {
  const use_renv = !!packagesModel.use_renv
  const default_packages = (packagesModel.default_packages || [])
    .filter((pkg) => pkg?.name && pkg.name.trim() !== '')
    .map(normalizePackageEntry)

  return { use_renv, default_packages }
}

// Per-project packages API uses { use_renv, packages } for reading, but backend expects default_packages
export const normalizeProjectPackages = (value) => ({
  use_renv: !!value?.use_renv,
  default_packages: (value?.packages || []).map(normalizePackageEntry)
})

export const mapProjectPackagesToPayload = (packagesModel = {}) => {
  const use_renv = !!packagesModel.use_renv
  const default_packages = (packagesModel.default_packages || [])
    .filter((pkg) => pkg?.name && pkg.name.trim() !== '')
    .map(normalizePackageEntry)

  // Backend expects default_packages, not packages
  return { use_renv, default_packages }
}
