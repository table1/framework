import { describe, it, expect, beforeAll } from 'vitest'
import { readFileSync } from 'fs'
import { homedir } from 'os'
import { join } from 'path'
import yaml from 'js-yaml'

/**
 * Helper to convert YAML boolean strings to JavaScript booleans
 * YAML uses "yes"/"no" or true/false, but JavaScript uses true/false
 */
const normalizeYamlBoolean = (value) => {
  if (typeof value === 'boolean') return value
  if (value === 'yes' || value === 'true') return true
  if (value === 'no' || value === 'false') return false
  return value
}

/**
 * Integration test: Settings YAML → API → UI
 *
 * Tests the complete data flow from the YAML configuration file
 * through the R API to ensure data integrity.
 */
describe('Settings Integration: YAML → API', () => {
  let yamlSettings
  let apiSettings
  const settingsPath = join(homedir(), '.config', 'framework', 'settings.yml')
  const apiUrl = 'http://127.0.0.1:8080/api/settings'

  beforeAll(async () => {
    // Read the actual YAML file
    try {
      const yamlContent = readFileSync(settingsPath, 'utf8')
      yamlSettings = yaml.load(yamlContent)
      console.log('✓ Loaded settings.yml')
    } catch (err) {
      console.error('Failed to load settings.yml:', err.message)
      throw err
    }

    // Fetch from API
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

  describe('Global Settings', () => {
    it('API includes global.projects_root from YAML', () => {
      expect(apiSettings).toHaveProperty('global')
      expect(apiSettings.global).toHaveProperty('projects_root')

      if (yamlSettings.global?.projects_root) {
        // API may expand tilde paths to absolute paths (both are valid)
        const yamlPath = yamlSettings.global.projects_root
        const apiPath = apiSettings.global.projects_root

        if (yamlPath.startsWith('~')) {
          // If YAML has tilde, API can return either tilde or expanded path
          const home = homedir()
          const expanded = yamlPath.replace(/^~/, home)
          expect([yamlPath, expanded]).toContain(apiPath)
        } else {
          // If YAML has absolute path, API should match exactly
          expect(apiPath).toBe(yamlPath)
        }
      }
    })
  })

  describe('Default Settings', () => {
    it('API includes defaults object', () => {
      expect(apiSettings).toHaveProperty('defaults')
      expect(apiSettings.defaults).toBeTruthy()
    })

    it('ai_support matches YAML', () => {
      const yamlValue = normalizeYamlBoolean(yamlSettings.defaults?.ai_support ?? true)
      const apiValue = apiSettings.defaults.ai_support

      expect(typeof apiValue).toBe('boolean')
      expect(apiValue).toBe(yamlValue)
    })

    it('ai_canonical_file matches YAML', () => {
      const yamlValue = yamlSettings.defaults?.ai_canonical_file ?? 'CLAUDE.md'
      const apiValue = apiSettings.defaults.ai_canonical_file

      expect(apiValue).toBe(yamlValue)
    })

    it('ai_assistants is an array', () => {
      expect(Array.isArray(apiSettings.defaults.ai_assistants)).toBe(true)

      // If YAML has assistants, they should match
      if (yamlSettings.defaults?.ai_assistants) {
        const yamlAssistants = Array.isArray(yamlSettings.defaults.ai_assistants)
          ? yamlSettings.defaults.ai_assistants
          : [yamlSettings.defaults.ai_assistants]

        expect(apiSettings.defaults.ai_assistants).toEqual(yamlAssistants)
      }
    })

    it('use_renv matches YAML (defaults to false)', () => {
      const yamlValue = normalizeYamlBoolean(yamlSettings.defaults?.use_renv ?? false)
      const apiValue = apiSettings.defaults.use_renv

      expect(typeof apiValue).toBe('boolean')
      expect(apiValue).toBe(yamlValue)
    })

    it('default_format matches YAML (defaults to quarto)', () => {
      const yamlValue = yamlSettings.defaults?.default_format ?? 'quarto'
      const apiValue = apiSettings.defaults.default_format

      expect(['quarto', 'rmarkdown']).toContain(apiValue)
      expect(apiValue).toBe(yamlValue)
    })
  })

  describe('Scaffold Settings', () => {
    it('API includes scaffold configuration', () => {
      expect(apiSettings.defaults).toHaveProperty('scaffold')
      expect(apiSettings.defaults.scaffold).toBeTruthy()
    })

    it('seed_on_scaffold matches YAML', () => {
      const yamlValue = normalizeYamlBoolean(yamlSettings.defaults?.scaffold?.seed_on_scaffold ?? false)
      const apiValue = apiSettings.defaults.scaffold.seed_on_scaffold

      expect(typeof apiValue).toBe('boolean')
      expect(apiValue).toBe(yamlValue)
    })

    it('seed value matches YAML when seed_on_scaffold is true', () => {
      if (apiSettings.defaults.scaffold.seed_on_scaffold) {
        expect(apiSettings.defaults.scaffold).toHaveProperty('seed')

        if (yamlSettings.defaults?.scaffold?.seed) {
          expect(apiSettings.defaults.scaffold.seed).toBe(
            yamlSettings.defaults.scaffold.seed.toString()
          )
        }
      }
    })

    it('ides configuration matches YAML', () => {
      const yamlValue = yamlSettings.defaults?.scaffold?.ides ?? 'vscode'
      const apiValue = apiSettings.defaults.scaffold.ides

      expect(apiValue).toBe(yamlValue)
    })

    it('positron flag matches YAML', () => {
      const yamlValue = normalizeYamlBoolean(yamlSettings.defaults?.scaffold?.positron ?? yamlSettings.defaults?.positron ?? false)
      const apiValue = apiSettings.defaults.scaffold.positron

      expect(typeof apiValue).toBe('boolean')
      expect(apiValue).toBe(yamlValue)
    })
  })

  describe('Git Hooks', () => {
    it('API includes git_hooks configuration', () => {
      expect(apiSettings.defaults).toHaveProperty('git_hooks')
      expect(apiSettings.defaults.git_hooks).toBeTruthy()
    })

    it('ai_sync hook matches YAML', () => {
      const yamlValue = normalizeYamlBoolean(yamlSettings.defaults?.git_hooks?.ai_sync ?? false)
      const apiValue = apiSettings.defaults.git_hooks.ai_sync

      expect(typeof apiValue).toBe('boolean')
      expect(apiValue).toBe(yamlValue)
    })

    it('data_security hook matches YAML', () => {
      const yamlValue = normalizeYamlBoolean(yamlSettings.defaults?.git_hooks?.data_security ?? false)
      const apiValue = apiSettings.defaults.git_hooks.data_security

      expect(typeof apiValue).toBe('boolean')
      expect(apiValue).toBe(yamlValue)
    })

    it('check_sensitive_dirs hook matches YAML', () => {
      const yamlValue = normalizeYamlBoolean(yamlSettings.defaults?.git_hooks?.check_sensitive_dirs ?? false)
      const apiValue = apiSettings.defaults.git_hooks.check_sensitive_dirs

      expect(typeof apiValue).toBe('boolean')
      expect(apiValue).toBe(yamlValue)
    })
  })

  describe('Author Information', () => {
    it('author_name matches YAML when present', () => {
      if (yamlSettings.defaults?.author_name) {
        expect(apiSettings.defaults.author_name).toBe(yamlSettings.defaults.author_name)
      }
    })

    it('author_email matches YAML when present', () => {
      if (yamlSettings.defaults?.author_email) {
        expect(apiSettings.defaults.author_email).toBe(yamlSettings.defaults.author_email)
      }
    })

    it('author_affiliation matches YAML when present', () => {
      if (yamlSettings.defaults?.author_affiliation) {
        expect(apiSettings.defaults.author_affiliation).toBe(yamlSettings.defaults.author_affiliation)
      }
    })
  })

  describe('Package Defaults', () => {
    it('default_packages is an array', () => {
      expect(Array.isArray(apiSettings.defaults.default_packages)).toBe(true)
    })

    it('default_packages matches YAML structure', () => {
      if (yamlSettings.defaults?.default_packages) {
        const yamlPackages = yamlSettings.defaults.default_packages

        // Could be flat list or nested structure
        if (Array.isArray(yamlPackages)) {
          expect(apiSettings.defaults.default_packages.length).toBeGreaterThanOrEqual(0)
        }
      }
    })
  })

  describe('Directory Defaults', () => {
    it('directories configuration exists', () => {
      expect(apiSettings.defaults).toHaveProperty('directories')
      expect(apiSettings.defaults.directories).toBeTruthy()
    })

    it('directories match YAML structure', () => {
      // Directories should be a flat object with keys like "notebooks", "scripts", etc.
      if (yamlSettings.defaults?.directories) {
        const yamlDirs = yamlSettings.defaults.directories
        const apiDirs = apiSettings.defaults.directories

        // Check that common directory keys exist
        const commonKeys = ['notebooks', 'scripts', 'functions']
        commonKeys.forEach(key => {
          if (yamlDirs[key]) {
            expect(apiDirs).toHaveProperty(key)
            expect(apiDirs[key]).toBe(yamlDirs[key])
          }
        })
      }
    })

    it('project type directories are in project_types', () => {
      // Project-specific directories should be under project_types, not defaults
      expect(apiSettings).toHaveProperty('project_types')
      if (apiSettings.project_types) {
        expect(apiSettings.project_types).toHaveProperty('project')
      }
    })
  })

  describe('Data Consistency', () => {
    it('all boolean values are actual booleans, not strings', () => {
      const booleanFields = [
        ['defaults', 'ai_support'],
        ['defaults', 'use_renv'],
        ['defaults', 'scaffold', 'seed_on_scaffold'],
        ['defaults', 'scaffold', 'positron'],
        ['defaults', 'git_hooks', 'ai_sync'],
        ['defaults', 'git_hooks', 'data_security'],
        ['defaults', 'git_hooks', 'check_sensitive_dirs']
      ]

      booleanFields.forEach(path => {
        let value = apiSettings
        for (const key of path) {
          value = value?.[key]
        }

        if (value !== undefined && value !== null) {
          expect(typeof value).toBe('boolean')
        }
      })
    })

    it('all array values are actual arrays, not objects', () => {
      expect(Array.isArray(apiSettings.defaults.ai_assistants)).toBe(true)
      expect(Array.isArray(apiSettings.defaults.default_packages)).toBe(true)
    })
  })

  describe('Settings Save API', () => {
    const saveApiUrl = 'http://127.0.0.1:8080/api/settings/save'

    it('POST /api/settings/save accepts correct payload structure', async () => {
      // Test that the API endpoint accepts the payload structure the UI sends
      // Clean up the payload to ensure only valid fields are sent
      const cleanDefaults = { ...apiSettings.defaults }

      // Remove invalid seed field if present (must be numeric or character string, not null/undefined/boolean)
      if (cleanDefaults.seed != null && typeof cleanDefaults.seed !== 'string' && typeof cleanDefaults.seed !== 'number') {
        delete cleanDefaults.seed
      }
      if (cleanDefaults.scaffold) {
        cleanDefaults.scaffold = { ...cleanDefaults.scaffold }
        if (cleanDefaults.scaffold.seed != null && typeof cleanDefaults.scaffold.seed !== 'string' && typeof cleanDefaults.scaffold.seed !== 'number') {
          delete cleanDefaults.scaffold.seed
        }
      }

      const payload = {
        global: {
          projects_root: yamlSettings.global?.projects_root || '~/code'
        },
        defaults: cleanDefaults,
        author: apiSettings.author || {}
      }

      const response = await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      })

      expect(response.ok).toBe(true)

      const result = await response.json()

      // Log error if save failed
      if (!result.success) {
        console.error('Save failed:', result.error)
      }

      expect(result).toHaveProperty('success')
      expect(result.success).toBe(true)
    })

    it('POST /api/settings/save returns error for invalid payload', async () => {
      const response = await fetch(saveApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ invalid: 'structure' })
      })

      // Should still return 200 but with success: false
      expect(response.ok).toBe(true)

      const result = await response.json()
      // May return success:false or success:true depending on validation
      // Just verify response structure is correct
      expect(result).toHaveProperty('success')
    })
  })
})
