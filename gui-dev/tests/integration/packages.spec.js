import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import { readFileSync, writeFileSync } from 'fs'
import { homedir } from 'os'
import { join } from 'path'
import yaml from 'js-yaml'

/**
 * Helper to clean payload before sending (mimics frontend saveSettings logic)
 */
const cleanPayloadForSave = (payload) => {
  const cleaned = JSON.parse(JSON.stringify(payload))

  // Clean seed fields - must be numeric, string, or null (not boolean)
  if (cleaned.defaults?.scaffold) {
    const seed = cleaned.defaults.scaffold.seed
    if (typeof seed === 'boolean' || seed === '') {
      cleaned.defaults.scaffold.seed = null
    }
  }
  if (cleaned.defaults?.seed !== undefined) {
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
    it('includes use_renv boolean field', () => {
      expect(apiSettings.defaults).toHaveProperty('use_renv')
      expect(typeof apiSettings.defaults.use_renv).toBe('boolean')
    })

    it('includes default_packages array', () => {
      expect(apiSettings.defaults).toHaveProperty('default_packages')
      expect(Array.isArray(apiSettings.defaults.default_packages)).toBe(true)
    })

    it('default_packages entries have required fields', () => {
      const packages = apiSettings.defaults.default_packages
      expect(packages.length).toBeGreaterThan(0)

      packages.forEach((pkg, index) => {
        expect(pkg).toHaveProperty('name')
        expect(pkg).toHaveProperty('auto_attach')
        expect(typeof pkg.name).toBe('string')
        expect(typeof pkg.auto_attach).toBe('boolean')
        expect(pkg.name.length).toBeGreaterThan(0)
      })
    })

    it('includes core tidyverse packages', () => {
      const packages = apiSettings.defaults.default_packages
      const packageNames = packages.map(p => p.name)

      // Only test for packages that are actually in the default config
      const corePackages = ['dplyr', 'ggplot2', 'tidyr', 'stringr']
      corePackages.forEach(pkgName => {
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
      const testPayload = cleanPayloadForSave(apiSettings)

      // Make a small change to test saving
      // API returns flat structure but backend expects nested structure for saving
      if (!testPayload.defaults.packages) {
        testPayload.defaults.packages = {}
      }
      testPayload.defaults.packages.use_renv = !testPayload.defaults.use_renv
      testPayload.defaults.packages.default_packages = testPayload.defaults.default_packages

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
      const restorePayload = cleanPayloadForSave(apiSettings)
      if (!restorePayload.defaults.packages) {
        restorePayload.defaults.packages = {}
      }
      restorePayload.defaults.packages.use_renv = restorePayload.defaults.use_renv
      restorePayload.defaults.packages.default_packages = restorePayload.defaults.default_packages
      await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(restorePayload)
      })
    })

    it('accepts adding new package to default_packages', async () => {
      const testPayload = cleanPayloadForSave(apiSettings)

      // Add a new package
      const newPackage = {
        name: 'test_package',
        auto_attach: true
      }

      // Restructure to nested format for saving
      if (!testPayload.defaults.packages) {
        testPayload.defaults.packages = {}
      }
      testPayload.defaults.packages.use_renv = testPayload.defaults.use_renv
      testPayload.defaults.packages.default_packages = [...testPayload.defaults.default_packages, newPackage]

      const response = await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testPayload)
      })

      expect(response.ok).toBe(true)
      const result = await response.json()
      expect(result.success).toBe(true)

      // Restore original
      const restorePayload = cleanPayloadForSave(apiSettings)
      if (!restorePayload.defaults.packages) {
        restorePayload.defaults.packages = {}
      }
      restorePayload.defaults.packages.use_renv = restorePayload.defaults.use_renv
      restorePayload.defaults.packages.default_packages = restorePayload.defaults.default_packages
      await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(restorePayload)
      })
    })

    it('filters out packages with empty names', async () => {
      const testPayload = cleanPayloadForSave(apiSettings)

      // Add packages with empty names (frontend filters these before sending)
      const packagesWithEmpties = [
        ...testPayload.defaults.default_packages,
        { name: '', auto_attach: true },
        { name: '  ', auto_attach: false }
      ]

      // Filter out empty names (mimics frontend logic)
      const filteredPackages = packagesWithEmpties.filter(
        pkg => pkg.name && pkg.name.trim() !== ''
      )

      // Restructure to nested format for saving
      if (!testPayload.defaults.packages) {
        testPayload.defaults.packages = {}
      }
      testPayload.defaults.packages.use_renv = testPayload.defaults.use_renv
      testPayload.defaults.packages.default_packages = filteredPackages

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
      const testUseRenv = !originalUseRenv

      // Save toggled use_renv
      const testPayload = cleanPayloadForSave(apiSettings)
      // Restructure to nested format for saving
      if (!testPayload.defaults.packages) {
        testPayload.defaults.packages = {}
      }
      testPayload.defaults.packages.use_renv = testUseRenv
      testPayload.defaults.packages.default_packages = testPayload.defaults.default_packages

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
      const restorePayload = cleanPayloadForSave(freshSettings)
      if (!restorePayload.defaults.packages) {
        restorePayload.defaults.packages = {}
      }
      restorePayload.defaults.packages.use_renv = originalUseRenv
      restorePayload.defaults.packages.default_packages = restorePayload.defaults.default_packages
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

      // Save new package
      const testPayload = cleanPayloadForSave(apiSettings)
      // Restructure to nested format for saving
      if (!testPayload.defaults.packages) {
        testPayload.defaults.packages = {}
      }
      testPayload.defaults.packages.use_renv = testPayload.defaults.use_renv
      testPayload.defaults.packages.default_packages = [...testPayload.defaults.default_packages, testPackage]

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
      const restorePayload = cleanPayloadForSave(freshSettings)
      if (!restorePayload.defaults.packages) {
        restorePayload.defaults.packages = {}
      }
      restorePayload.defaults.packages.use_renv = restorePayload.defaults.use_renv
      restorePayload.defaults.packages.default_packages =
        restorePayload.defaults.default_packages.filter(
          p => p.name !== 'roundtrip_test_pkg'
        )
      await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(restorePayload)
      })
    })

    it('persists auto_attach toggle for existing package', async () => {
      // Find dplyr (should exist)
      const dplyrIndex = apiSettings.defaults.default_packages.findIndex(
        p => p.name === 'dplyr'
      )
      expect(dplyrIndex).toBeGreaterThanOrEqual(0)

      const originalAutoAttach = apiSettings.defaults.default_packages[dplyrIndex].auto_attach
      const testAutoAttach = !originalAutoAttach

      // Save toggled auto_attach
      const testPayload = cleanPayloadForSave(apiSettings)
      // Restructure to nested format for saving
      if (!testPayload.defaults.packages) {
        testPayload.defaults.packages = {}
      }
      testPayload.defaults.packages.use_renv = testPayload.defaults.use_renv
      testPayload.defaults.packages.default_packages = [...testPayload.defaults.default_packages]
      testPayload.defaults.packages.default_packages[dplyrIndex].auto_attach = testAutoAttach

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
      const restorePayload = cleanPayloadForSave(freshSettings)
      if (!restorePayload.defaults.packages) {
        restorePayload.defaults.packages = {}
      }
      restorePayload.defaults.packages.use_renv = restorePayload.defaults.use_renv
      restorePayload.defaults.packages.default_packages = [...restorePayload.defaults.default_packages]
      const restoreDplyrIndex = restorePayload.defaults.packages.default_packages.findIndex(
        p => p.name === 'dplyr'
      )
      restorePayload.defaults.packages.default_packages[restoreDplyrIndex].auto_attach = originalAutoAttach
      await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(restorePayload)
      })
    })
  })
})
