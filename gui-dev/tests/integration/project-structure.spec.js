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
 * Integration test: Project Structure Settings
 *
 * Tests the complete data flow for project structure configuration:
 * 1. UI displays correct project structure data
 * 2. UI sends correct payload on save
 * 3. R backend validates and persists correctly
 * 4. YAML file matches what was submitted
 */
describe('Project Structure Integration: UI → API → YAML', () => {
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
    it('includes project_types object', () => {
      expect(apiSettings).toHaveProperty('project_types')
      expect(typeof apiSettings.project_types).toBe('object')
    })

    it('includes all expected project types', () => {
      const expectedTypes = ['project', 'project_sensitive', 'course', 'presentation']
      expectedTypes.forEach(type => {
        expect(apiSettings.project_types).toHaveProperty(type)
      })
    })

    it('each project type has required fields', () => {
      Object.entries(apiSettings.project_types).forEach(([typeName, typeConfig]) => {
        expect(typeConfig).toHaveProperty('label')
        expect(typeConfig).toHaveProperty('description')
        expect(typeConfig).toHaveProperty('directories')
        expect(typeof typeConfig.label).toBe('string')
        expect(typeof typeConfig.description).toBe('string')
        expect(typeof typeConfig.directories).toBe('object')
      })
    })

    it('standard project has expected directories', () => {
      const project = apiSettings.project_types.project
      expect(project.directories).toHaveProperty('notebooks')
      expect(project.directories).toHaveProperty('scripts')
      expect(project.directories).toHaveProperty('functions')
      expect(project.directories).toHaveProperty('inputs_raw')
      expect(project.directories).toHaveProperty('cache')
    })

    it('privacy-sensitive project has expected public/private directories', () => {
      const projectSensitive = apiSettings.project_types.project_sensitive

      // Core directories - should have at least basic private/public inputs
      expect(projectSensitive.directories).toHaveProperty('inputs_private_raw')
      expect(projectSensitive.directories).toHaveProperty('inputs_public_raw')

      // scripts should be included in minimal set
      expect(projectSensitive.directories).toHaveProperty('scripts')
    })

    it('presentation project has minimal default directories', () => {
      const presentation = apiSettings.project_types.presentation

      // Required directories (always present)
      expect(presentation.directories).toHaveProperty('presentation_source')
      expect(presentation.directories).toHaveProperty('rendered_slides')
    })
  })

  describe('Extra Directories Validation', () => {
    it('extra_directories is an array if present', () => {
      Object.entries(apiSettings.project_types).forEach(([typeName, typeConfig]) => {
        if (typeConfig.extra_directories !== undefined && typeConfig.extra_directories !== null) {
          expect(Array.isArray(typeConfig.extra_directories)).toBe(true)
        }
      })
    })

    it('extra_directories entries have required fields when present', () => {
      Object.entries(apiSettings.project_types).forEach(([typeName, typeConfig]) => {
        if (Array.isArray(typeConfig.extra_directories) && typeConfig.extra_directories.length > 0) {
          typeConfig.extra_directories.forEach((dir, index) => {
            expect(dir).toHaveProperty('key')
            expect(dir).toHaveProperty('label')
            expect(dir).toHaveProperty('path')
            expect(dir).toHaveProperty('type')

            expect(typeof dir.key).toBe('string')
            expect(typeof dir.label).toBe('string')
            expect(typeof dir.path).toBe('string')
            expect(typeof dir.type).toBe('string')

            expect(dir.key.length).toBeGreaterThan(0)
            expect(dir.label.length).toBeGreaterThan(0)
            expect(dir.path.length).toBeGreaterThan(0)
          })
        }
      })
    })
  })

  describe('Save Flow: Payload Structure', () => {
    it('accepts valid project structure update', async () => {
      const testPayload = cleanPayloadForSave(apiSettings)

      // Make a small change to test saving
      testPayload.project_types.project.directories.notebooks = 'notebooks'

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
    })

    it('rejects payload with missing required fields in extra_directories', async () => {
      const testPayload = cleanPayloadForSave(apiSettings)

      // Add invalid extra_directories entry (missing 'path')
      testPayload.project_types.project.extra_directories = [
        {
          key: 'test',
          label: 'Test Directory',
          type: 'workspace'
          // Missing 'path' field
        }
      ]

      const response = await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testPayload)
      })

      expect(response.ok).toBe(true)
      const result = await response.json()

      // Should fail validation
      expect(result.success).toBe(false)
      expect(result.error).toContain('missing required field')
    })

    it('rejects payload with duplicate extra_directories keys', async () => {
      const testPayload = cleanPayloadForSave(apiSettings)

      // Add duplicate keys
      testPayload.project_types.project.extra_directories = [
        {
          key: 'duplicate',
          label: 'First',
          path: 'first',
          type: 'workspace'
        },
        {
          key: 'duplicate',  // Same key!
          label: 'Second',
          path: 'second',
          type: 'output'
        }
      ]

      const response = await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testPayload)
      })

      expect(response.ok).toBe(true)
      const result = await response.json()

      // Should fail validation
      expect(result.success).toBe(false)
      expect(result.error).toContain('duplicate extra_directories key')
    })
  })

  describe('Round-trip Validation: UI → API → YAML → API', () => {
    it('persists extra_directories correctly', async () => {
      const testExtraDir = {
        key: 'test_roundtrip',
        label: 'Test Round-trip Directory',
        path: 'test/roundtrip',
        type: 'output'
      }

      // Save new extra_directories (replacing any existing ones for clean test)
      const testPayload = cleanPayloadForSave(apiSettings)
      testPayload.project_types.project.extra_directories = [testExtraDir]

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

      // Verify it was saved correctly - our test directory should be present
      expect(Array.isArray(freshSettings.project_types.project.extra_directories)).toBe(true)

      // Find our test directory in the results
      const savedDir = freshSettings.project_types.project.extra_directories.find(
        d => d.key === testExtraDir.key
      )
      expect(savedDir).toBeTruthy()
      expect(savedDir.key).toBe(testExtraDir.key)
      expect(savedDir.label).toBe(testExtraDir.label)
      expect(savedDir.path).toBe(testExtraDir.path)
      expect(savedDir.type).toBe(testExtraDir.type)

      // Verify YAML matches
      const yamlContent = readFileSync(settingsPath, 'utf8')
      const yamlSettings = yaml.load(yamlContent)

      expect(Array.isArray(yamlSettings.project_types.project.extra_directories)).toBe(true)
      const yamlSavedDir = yamlSettings.project_types.project.extra_directories.find(
        d => d.key === testExtraDir.key
      )
      expect(yamlSavedDir).toBeTruthy()
      expect(yamlSavedDir.key).toBe(testExtraDir.key)
    })

    it('persists directory path changes correctly', async () => {
      const originalNotebooksDir = apiSettings.project_types.project.directories.notebooks
      const testNotebooksDir = 'my_custom_notebooks_dir'

      // Save new notebooks directory
      const testPayload = cleanPayloadForSave(apiSettings)
      testPayload.project_types.project.directories.notebooks = testNotebooksDir

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
      expect(freshSettings.project_types.project.directories.notebooks).toBe(testNotebooksDir)

      // Verify YAML matches
      const yamlContent = readFileSync(settingsPath, 'utf8')
      const yamlSettings = yaml.load(yamlContent)

      expect(yamlSettings.project_types.project.directories.notebooks).toBe(testNotebooksDir)

      // Restore original value
      const restorePayload = JSON.parse(JSON.stringify(freshSettings))
      restorePayload.project_types.project.directories.notebooks = originalNotebooksDir
      await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(restorePayload)
      })
    })

    it('filters out incomplete extra_directories entries', async () => {
      // Send payload with both complete and incomplete entries
      const testPayload = cleanPayloadForSave(apiSettings)
      testPayload.project_types.project.extra_directories = [
        {
          key: 'complete',
          label: 'Complete Entry',
          path: 'complete/path',
          type: 'workspace'
        },
        {
          key: 'incomplete',
          label: '',  // Empty label
          path: 'incomplete/path',
          type: 'output'
        },
        {
          key: '',  // Empty key
          label: 'Another Incomplete',
          path: 'path',
          type: 'input'
        }
      ]

      // Filter out incomplete entries (mimics frontend saveSettings logic)
      for (const projectTypeKey in testPayload.project_types) {
        const projectType = testPayload.project_types[projectTypeKey]
        if (projectType.extra_directories && Array.isArray(projectType.extra_directories)) {
          projectType.extra_directories = projectType.extra_directories.filter(dir => {
            return dir.key && dir.key.trim() !== '' &&
                   dir.label && dir.label.trim() !== '' &&
                   dir.path && dir.path.trim() !== '' &&
                   dir.type && dir.type.trim() !== ''
          })
        }
      }

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

      // Should only have the complete entry
      expect(freshSettings.project_types.project.extra_directories).toHaveLength(1)
      expect(freshSettings.project_types.project.extra_directories[0].key).toBe('complete')
    })
  })
})
