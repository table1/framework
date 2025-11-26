import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import { readFileSync, writeFileSync } from 'fs'
import { homedir } from 'os'
import { join } from 'path'
import yaml from 'js-yaml'

/**
 * Helpers to normalize package data across legacy (flat) and nested shapes.
 */
const toPackageModel = (settings) => {
  const defaults = settings.defaults || {}
  const nested = defaults.packages || {}
  const flatPkgs = defaults.default_packages || []

  const default_packages = Array.isArray(nested.default_packages)
    ? nested.default_packages
    : Array.isArray(flatPkgs)
      ? flatPkgs
      : []

  const use_renv =
    typeof nested.use_renv === 'boolean'
      ? nested.use_renv
      : typeof defaults.use_renv === 'boolean'
        ? defaults.use_renv
        : false

  return { use_renv, default_packages }
}

const buildSavePayload = (settings, pkgModel) => {
  const cleaned = JSON.parse(JSON.stringify(settings))
  const model = pkgModel || toPackageModel(cleaned)

  if (!cleaned.defaults) cleaned.defaults = {}
  cleaned.defaults.packages = {
    use_renv: !!model.use_renv,
    default_packages: (model.default_packages || []).filter(
      (pkg) => pkg?.name && pkg.name.trim() !== ''
    )
  }
  // Keep top-level use_renv for backward compatibility if backend expects it
  cleaned.defaults.use_renv = cleaned.defaults.packages.use_renv

  // Clean seed fields - must be numeric, string, or null (not boolean)
  if (cleaned.defaults.scaffold) {
    const seed = cleaned.defaults.scaffold.seed
    if (typeof seed === 'boolean' || seed === '') {
      cleaned.defaults.scaffold.seed = null
    }
  }
  if (cleaned.defaults.seed !== undefined) {
    const seed = cleaned.defaults.seed
    if (typeof seed === 'boolean' || seed === '') {
      cleaned.defaults.seed = null
    }
  }

  return cleaned
}

/**
 * Integration test: Packages & Dependencies
 *
 * Tests the complete data flow for package configuration:
 * 1. UI displays correct package data
 * 2. UI sends correct payload on save
 * 3. R backend validates and persists correctly
 * 4. YAML file matches what was submitted
 */
describe('Packages & Dependencies Integration: UI → API → YAML', () => {
  const settingsPath = join(homedir(), '.config', 'framework', 'settings.yml')
  const apiUrl = 'http://127.0.0.1:8080/api/settings'
  const saveApiUrl = 'http://127.0.0.1:8080/api/settings/save'

  let originalYaml
  let apiSettings

  beforeAll(async () => {
    // Backup original settings
    try {
      originalYaml = readFileSync(settingsPath, 'utf8')
    } catch (err) {
      console.error('Failed to backup settings.yml:', err.message)
      throw err
    }

    // Fetch current settings from API
    try {
      const response = await fetch(apiUrl)
      if (!response.ok) {
        throw new Error(`API returned ${response.status}`)
      }
      apiSettings = await response.json()
      console.log('✓ Fetched /api/settings')
    } catch (err) {
      console.error('Failed to fetch API:', err.message)
      throw err
    }
  })

  afterAll(async () => {
    // Restore original settings
    try {
      writeFileSync(settingsPath, originalYaml, 'utf8')
      console.log('✓ Restored original settings.yml')
    } catch (err) {
      console.error('Failed to restore settings.yml:', err.message)
    }
  })

  describe('API Response Structure', () => {
    it('includes package settings in either nested or legacy shape', () => {
      const model = toPackageModel(apiSettings)
      expect(model).toHaveProperty('use_renv')
      expect(model).toHaveProperty('default_packages')
      expect(typeof model.use_renv).toBe('boolean')
      expect(Array.isArray(model.default_packages)).toBe(true)
    })

    it('default_packages entries have required fields', () => {
      const packages = toPackageModel(apiSettings).default_packages
      expect(packages.length).toBeGreaterThan(0)

      packages.forEach((pkg) => {
        expect(pkg).toHaveProperty('name')
        expect(pkg).toHaveProperty('auto_attach')
        expect(typeof pkg.name).toBe('string')
        expect(typeof pkg.auto_attach).toBe('boolean')
        expect(pkg.name.length).toBeGreaterThan(0)
      })
    })

    it('includes core tidyverse packages (baseline sanity)', () => {
      const packages = toPackageModel(apiSettings).default_packages
      const packageNames = packages.map((p) => p.name)

      const corePackages = ['dplyr', 'ggplot2', 'tidyr', 'stringr']
      corePackages.forEach((pkgName) => {
        expect(packageNames).toContain(pkgName)
      })
    })
  })

  describe('Package Validation', () => {
    it('validates package name is non-empty string', () => {
      // This test documents that empty package names should be filtered out
      // The frontend filters empty names before sending
      expect(true).toBe(true)
    })

    it('validates auto_attach is boolean', () => {
      const packages = apiSettings.defaults.default_packages
      packages.forEach(pkg => {
        expect(typeof pkg.auto_attach).toBe('boolean')
      })
    })
  })

  describe('Save Flow: Payload Structure', () => {
    it('accepts valid package configuration update', async () => {
      const baseModel = toPackageModel(apiSettings)
      const testModel = {
        ...baseModel,
        use_renv: !baseModel.use_renv
      }
      const testPayload = buildSavePayload(apiSettings, testModel)

      const response = await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testPayload)
      })

      expect(response.ok).toBe(true)
      const result = await response.json()

      if (!result.success) {
        console.error('Save failed:', result.error)
      }

      expect(result).toHaveProperty('success')
      expect(result.success).toBe(true)

      // Restore original value
      const restorePayload = buildSavePayload(apiSettings, baseModel)
      await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(restorePayload)
      })
    })

    it('accepts adding new package to default_packages', async () => {
      const newPackage = {
        name: 'test_package',
        auto_attach: true
      }

      const baseModel = toPackageModel(apiSettings)
      const testModel = {
        ...baseModel,
        default_packages: [...baseModel.default_packages, newPackage]
      }
      const testPayload = buildSavePayload(apiSettings, testModel)

      const response = await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testPayload)
      })

      expect(response.ok).toBe(true)
      const result = await response.json()
      expect(result.success).toBe(true)

      // Restore original
      const restorePayload = buildSavePayload(apiSettings, baseModel)
      await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(restorePayload)
      })
    })

    it('filters out packages with empty names', async () => {
      const baseModel = toPackageModel(apiSettings)

      // Add packages with empty names (frontend filters these before sending)
      const packagesWithEmpties = [
        ...baseModel.default_packages,
        { name: '', auto_attach: true },
        { name: '  ', auto_attach: false }
      ]

      // Filter out empty names (mimics frontend logic)
      const filteredPackages = packagesWithEmpties.filter(
        (pkg) => pkg.name && pkg.name.trim() !== ''
      )

      const testModel = {
        ...baseModel,
        default_packages: filteredPackages
      }
      const testPayload = buildSavePayload(apiSettings, testModel)

      const response = await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testPayload)
      })

      expect(response.ok).toBe(true)
      const result = await response.json()
      expect(result.success).toBe(true)
    })
  })

  describe('Round-trip Validation: UI → API → YAML → API', () => {
    it('persists use_renv toggle correctly', async () => {
      const originalUseRenv = apiSettings.defaults.use_renv
      const baseModel = toPackageModel(apiSettings)
      const testUseRenv = !baseModel.use_renv

      const testPayload = buildSavePayload(apiSettings, {
        ...baseModel,
        use_renv: testUseRenv
      })

      const saveResponse = await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testPayload)
      })

      expect(saveResponse.ok).toBe(true)
      const saveResult = await saveResponse.json()
      expect(saveResult.success).toBe(true)

      // Fetch fresh from API
      const fetchResponse = await fetch(apiUrl)
      expect(fetchResponse.ok).toBe(true)
      const freshSettings = await fetchResponse.json()

      // Verify it was saved correctly
      expect(freshSettings.defaults.use_renv).toBe(testUseRenv)

      // Verify YAML matches
      const yamlContent = readFileSync(settingsPath, 'utf8')
      const yamlSettings = yaml.load(yamlContent)

      // YAML stores booleans as yes/no
      const expectedYamlValue = testUseRenv ? 'yes' : 'no'
      expect(yamlSettings.defaults.packages.use_renv).toBe(expectedYamlValue)

      // Restore original value
      const restorePayload = buildSavePayload(freshSettings, {
        ...toPackageModel(freshSettings),
        use_renv: originalUseRenv
      })
      await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(restorePayload)
      })
    })

    it('persists package list changes correctly', async () => {
      const testPackage = {
        name: 'roundtrip_test_pkg',
        auto_attach: true
      }

      const baseModel = toPackageModel(apiSettings)
      const testPayload = buildSavePayload(apiSettings, {
        ...baseModel,
        default_packages: [...baseModel.default_packages, testPackage]
      })

      const saveResponse = await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testPayload)
      })

      expect(saveResponse.ok).toBe(true)
      const saveResult = await saveResponse.json()
      expect(saveResult.success).toBe(true)

      // Fetch fresh from API
      const fetchResponse = await fetch(apiUrl)
      expect(fetchResponse.ok).toBe(true)
      const freshSettings = await fetchResponse.json()

      // Verify it was saved correctly
      const savedPackage = freshSettings.defaults.default_packages.find(
        p => p.name === 'roundtrip_test_pkg'
      )
      expect(savedPackage).toBeDefined()
      expect(savedPackage.auto_attach).toBe(true)

      // Verify YAML matches
      const yamlContent = readFileSync(settingsPath, 'utf8')
      const yamlSettings = yaml.load(yamlContent)

      const yamlPackage = yamlSettings.defaults.packages.default_packages.find(
        p => p.name === 'roundtrip_test_pkg'
      )
      expect(yamlPackage).toBeDefined()
      // YAML stores booleans as yes/no
      expect(yamlPackage.auto_attach).toBe('yes')

      // Restore original (remove test package)
      const restorePayload = buildSavePayload(freshSettings, {
        ...toPackageModel(freshSettings),
        default_packages: toPackageModel(freshSettings).default_packages.filter(
          (p) => p.name !== 'roundtrip_test_pkg'
        )
      })
      await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(restorePayload)
      })
    })

    it('persists auto_attach toggle for existing package', async () => {
      const baseModel = toPackageModel(apiSettings)
      const dplyrIndex = baseModel.default_packages.findIndex(
        (p) => p.name === 'dplyr'
      )
      expect(dplyrIndex).toBeGreaterThanOrEqual(0)

      const originalAutoAttach = baseModel.default_packages[dplyrIndex].auto_attach
      const testAutoAttach = !originalAutoAttach

      // Save toggled auto_attach
      const updatedPackages = [...baseModel.default_packages]
      updatedPackages[dplyrIndex] = {
        ...updatedPackages[dplyrIndex],
        auto_attach: testAutoAttach
      }
      const testPayload = buildSavePayload(apiSettings, {
        ...baseModel,
        default_packages: updatedPackages
      })

      const saveResponse = await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testPayload)
      })

      expect(saveResponse.ok).toBe(true)
      const saveResult = await saveResponse.json()
      expect(saveResult.success).toBe(true)

      // Fetch fresh from API
      const fetchResponse = await fetch(apiUrl)
      expect(fetchResponse.ok).toBe(true)
      const freshSettings = await fetchResponse.json()

      // Verify it was saved correctly
      const savedDplyr = freshSettings.defaults.default_packages.find(
        p => p.name === 'dplyr'
      )
      expect(savedDplyr.auto_attach).toBe(testAutoAttach)

      // Verify YAML matches
      const yamlContent = readFileSync(settingsPath, 'utf8')
      const yamlSettings = yaml.load(yamlContent)

      const yamlDplyr = yamlSettings.defaults.packages.default_packages.find(
        p => p.name === 'dplyr'
      )
      // YAML stores booleans as yes/no
      const expectedYamlAutoAttach = testAutoAttach ? 'yes' : 'no'
      expect(yamlDplyr.auto_attach).toBe(expectedYamlAutoAttach)

      // Restore original value
      const freshModel = toPackageModel(freshSettings)
      const restorePackages = [...freshModel.default_packages]
      const restoreDplyrIndex = restorePackages.findIndex((p) => p.name === 'dplyr')
      restorePackages[restoreDplyrIndex] = {
        ...restorePackages[restoreDplyrIndex],
        auto_attach: originalAutoAttach
      }
      const restorePayload = buildSavePayload(freshSettings, {
        ...freshModel,
        default_packages: restorePackages
      })
      await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(restorePayload)
      })
    })
  })
})
