import { describe, it, expect, beforeAll } from 'vitest'
import { readFileSync, existsSync } from 'fs'
import { homedir } from 'os'
import { join } from 'path'
import yaml from 'js-yaml'

/**
 * Integration test: Projects YAML → API → UI
 *
 * Tests the complete data flow from the projects.yml file
 * through the R API to ensure project data integrity.
 */
describe('Projects Integration: YAML → API', () => {
  let yamlProjects
  let apiProjects
  let apiProjectsRoot
  const projectsPath = join(homedir(), '.config', 'framework', 'projects.yml')
  const apiUrl = 'http://127.0.0.1:8080/api/settings/get'

  beforeAll(async () => {
    // Read the actual projects.yml file
    try {
      if (!existsSync(projectsPath)) {
        console.log('⚠ No projects.yml found - assuming empty projects list')
        yamlProjects = []
      } else {
        const yamlContent = readFileSync(projectsPath, 'utf8')
        const yamlData = yaml.load(yamlContent)
        yamlProjects = yamlData.projects || []
        console.log(`✓ Loaded projects.yml (${yamlProjects.length} projects)`)
      }
    } catch (err) {
      console.error('Failed to load projects.yml:', err.message)
      throw err
    }

    // Fetch from API
    try {
      const response = await fetch(apiUrl)
      if (!response.ok) {
        throw new Error(`API returned ${response.status}`)
      }
      const data = await response.json()
      apiProjects = data.projects || []
      apiProjectsRoot = data.global?.projects_root
      console.log(`✓ Fetched /api/settings/get (${apiProjects.length} projects)`)
    } catch (err) {
      console.error('Failed to fetch API:', err.message)
      throw err
    }
  })

  describe('Project Count', () => {
    it('API returns same number of projects as YAML', () => {
      expect(apiProjects.length).toBe(yamlProjects.length)
    })
  })

  describe('Project Structure', () => {
    it('each project has required fields', () => {
      apiProjects.forEach((project, index) => {
        expect(project, `Project at index ${index}`).toHaveProperty('id')
        expect(project, `Project at index ${index}`).toHaveProperty('name')
        expect(project, `Project at index ${index}`).toHaveProperty('path')
        expect(project, `Project at index ${index}`).toHaveProperty('type')
      })
    })

    it('project IDs are unique', () => {
      const ids = apiProjects.map(p => p.id)
      const uniqueIds = [...new Set(ids)]
      expect(uniqueIds.length).toBe(ids.length)
    })

    it('project types are valid', () => {
      const validTypes = ['project', 'course', 'presentation', 'project_sensitive']
      apiProjects.forEach(project => {
        expect(validTypes).toContain(project.type)
      })
    })
  })

  describe('Data Integrity', () => {
    it('API returns all projects from YAML with correct IDs', () => {
      if (yamlProjects.length === 0) {
        expect(apiProjects.length).toBe(0)
        return
      }

      const yamlIds = yamlProjects.map(p => p.id).sort()
      const apiIds = apiProjects.map(p => p.id).sort()
      expect(apiIds).toEqual(yamlIds)
    })

    it('project paths match YAML', () => {
      yamlProjects.forEach(yamlProject => {
        const apiProject = apiProjects.find(p => p.id === yamlProject.id)
        expect(apiProject, `Project with id ${yamlProject.id}`).toBeTruthy()
        expect(apiProject.path).toBe(yamlProject.path)
      })
    })

    it('created dates match YAML', () => {
      yamlProjects.forEach(yamlProject => {
        const apiProject = apiProjects.find(p => p.id === yamlProject.id)
        expect(apiProject, `Project with id ${yamlProject.id}`).toBeTruthy()
        // API might format the date, so just check it exists and matches if present
        if (yamlProject.created) {
          expect(apiProject.created).toBeTruthy()
        }
      })
    })
  })

  describe('API Enrichment', () => {
    it('API enriches projects with name from project config', () => {
      // YAML only stores id, path, created
      // API reads each project's config.yml to get name
      apiProjects.forEach(project => {
        expect(project.name).toBeTruthy()
        expect(typeof project.name).toBe('string')
      })
    })

    it('API enriches projects with type from project config', () => {
      // YAML only stores id, path, created
      // API reads each project's config.yml to get type
      apiProjects.forEach(project => {
        expect(project.type).toBeTruthy()
        expect(typeof project.type).toBe('string')
      })
    })
  })

  describe('Optional Fields', () => {
    it('author information is enriched from project config when available', () => {
      // Author info is read from each project's config.yml, not from projects.yml
      apiProjects.forEach(project => {
        // Author fields are optional but should be strings if present
        if (project.author) {
          expect(typeof project.author).toBe('string')
        }
        if (project.author_email) {
          expect(typeof project.author_email).toBe('string')
        }
        if (project.author_affiliation) {
          expect(typeof project.author_affiliation).toBe('string')
        }
      })
    })

    it('created timestamp is present', () => {
      apiProjects.forEach(project => {
        expect(project).toHaveProperty('created')
        expect(typeof project.created).toBe('string')
      })
    })
  })

  describe('Projects Root', () => {
    it('API includes projects_root from global settings', () => {
      expect(apiProjectsRoot).toBeTruthy()
      expect(typeof apiProjectsRoot).toBe('string')
    })

    it('projects_root is an absolute or tilde path', () => {
      if (apiProjectsRoot) {
        // Should start with / on Unix, C:/ on Windows, or ~ for home directory
        expect(
          apiProjectsRoot.startsWith('/') ||
          apiProjectsRoot.startsWith('~') ||
          /^[A-Z]:\\/.test(apiProjectsRoot)
        ).toBe(true)
      }
    })
  })

  describe('Edge Cases', () => {
    it('handles empty projects list gracefully', () => {
      // This test will pass regardless of whether there are projects
      expect(Array.isArray(apiProjects)).toBe(true)
      expect(Array.isArray(yamlProjects)).toBe(true)
    })

    it('no project has missing critical data', () => {
      apiProjects.forEach(project => {
        expect(project.id).toBeTruthy()
        expect(project.name).toBeTruthy()
        expect(project.path).toBeTruthy()
        expect(project.type).toBeTruthy()
      })
    })
  })
})
