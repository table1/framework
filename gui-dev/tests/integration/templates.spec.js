import { describe, it, expect, beforeAll, afterAll } from 'vitest'

/**
 * Integration test: Templates API
 *
 * Tests the template CRUD operations:
 * - GET /api/templates/<name> - fetch template contents
 * - POST /api/templates/<name> - save template contents
 * - DELETE /api/templates/<name> - reset template to defaults
 */

const API_BASE = 'http://127.0.0.1:8080'

// Template names used in the GUI
// Note: 'canonical' in the GUI maps to 'ai_canonical' or 'ai_claude' in the API
const TEMPLATE_NAMES = ['notebook', 'script', 'presentation', 'ai_canonical']

describe('Templates Integration: API', () => {
  // Store original contents to restore after tests
  const originalContents = {}

  beforeAll(async () => {
    // Fetch and store original contents for all templates
    for (const name of TEMPLATE_NAMES) {
      try {
        const response = await fetch(`${API_BASE}/api/templates/${name}`)
        if (response.ok) {
          const data = await response.json()
          originalContents[name] = data.contents
        }
      } catch (err) {
        console.warn(`Could not fetch original ${name} template:`, err.message)
      }
    }
    console.log('✓ Stored original template contents')
  })

  afterAll(async () => {
    // Restore original contents (or reset to defaults)
    for (const name of TEMPLATE_NAMES) {
      try {
        if (originalContents[name] !== undefined) {
          await fetch(`${API_BASE}/api/templates/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ contents: originalContents[name] })
          })
        }
      } catch (err) {
        console.warn(`Could not restore ${name} template:`, err.message)
      }
    }
    console.log('✓ Restored original template contents')
  })

  describe('GET /api/templates/<name>', () => {
    it.each(TEMPLATE_NAMES)('fetches %s template successfully', async (name) => {
      const response = await fetch(`${API_BASE}/api/templates/${name}`)
      expect(response.ok).toBe(true)

      const data = await response.json()
      expect(data).toHaveProperty('success', true)
      expect(data).toHaveProperty('name', name)
      expect(data).toHaveProperty('contents')
      expect(typeof data.contents).toBe('string')
    })

    it('notebook template contains expected Quarto frontmatter', async () => {
      const response = await fetch(`${API_BASE}/api/templates/notebook`)
      const data = await response.json()

      // Should have YAML frontmatter markers
      expect(data.contents).toContain('---')
      // Should have title placeholder
      expect(data.contents.toLowerCase()).toMatch(/title|filename/)
    })

    it('script template contains R shebang or library calls', async () => {
      const response = await fetch(`${API_BASE}/api/templates/script`)
      const data = await response.json()

      // Should have either shebang or library/scaffold reference
      expect(
        data.contents.includes('#!/') ||
        data.contents.includes('library(') ||
        data.contents.includes('scaffold()')
      ).toBe(true)
    })

    it('presentation template contains revealjs or slide content', async () => {
      const response = await fetch(`${API_BASE}/api/templates/presentation`)
      const data = await response.json()

      // Should have YAML frontmatter or slide markers
      expect(
        data.contents.includes('---') ||
        data.contents.includes('##') ||
        data.contents.includes('format:')
      ).toBe(true)
    })

    it('ai_canonical template is a string', async () => {
      const response = await fetch(`${API_BASE}/api/templates/ai_canonical`)
      const data = await response.json()

      expect(data.success).toBe(true)
      expect(typeof data.contents).toBe('string')
    })
  })

  describe('POST /api/templates/<name>', () => {
    it('saves template contents successfully', async () => {
      const testContent = '# Test Template\n\nThis is a test.'

      // Save new content
      const saveResponse = await fetch(`${API_BASE}/api/templates/notebook`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents: testContent })
      })
      expect(saveResponse.ok).toBe(true)

      const saveData = await saveResponse.json()
      expect(saveData).toHaveProperty('success', true)

      // Verify it was saved by fetching again
      const fetchResponse = await fetch(`${API_BASE}/api/templates/notebook`)
      const fetchData = await fetchResponse.json()

      expect(fetchData.contents).toBe(testContent)
    })

    it('handles empty content', async () => {
      const saveResponse = await fetch(`${API_BASE}/api/templates/script`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents: '' })
      })
      expect(saveResponse.ok).toBe(true)

      const fetchResponse = await fetch(`${API_BASE}/api/templates/script`)
      const fetchData = await fetchResponse.json()

      expect(fetchData.contents).toBe('')
    })

    it('preserves special characters and formatting', async () => {
      const specialContent = `---
title: "Test {filename}"
date: "{date}"
---

## Section with special chars

- Item with "quotes"
- Item with 'apostrophes'
- Code: \`library(dplyr)\`

\`\`\`r
# R code block
data %>%
  filter(x > 0) %>%
  mutate(y = x * 2)
\`\`\`
`

      await fetch(`${API_BASE}/api/templates/presentation`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents: specialContent })
      })

      const fetchResponse = await fetch(`${API_BASE}/api/templates/presentation`)
      const fetchData = await fetchResponse.json()

      expect(fetchData.contents).toBe(specialContent)
    })
  })

  describe('DELETE /api/templates/<name>', () => {
    it('resets template to default contents', async () => {
      // First, save custom content
      const customContent = '# Custom content that will be reset'
      await fetch(`${API_BASE}/api/templates/notebook`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents: customContent })
      })

      // Verify custom content is saved
      let fetchResponse = await fetch(`${API_BASE}/api/templates/notebook`)
      let fetchData = await fetchResponse.json()
      expect(fetchData.contents).toBe(customContent)

      // Reset to default
      const deleteResponse = await fetch(`${API_BASE}/api/templates/notebook`, {
        method: 'DELETE'
      })
      expect(deleteResponse.ok).toBe(true)

      const deleteData = await deleteResponse.json()
      expect(deleteData).toHaveProperty('success', true)

      // Verify it's back to default (not our custom content)
      fetchResponse = await fetch(`${API_BASE}/api/templates/notebook`)
      fetchData = await fetchResponse.json()

      expect(fetchData.contents).not.toBe(customContent)
      // Default notebook template should have frontmatter
      expect(fetchData.contents).toContain('---')
    })

    it.each(TEMPLATE_NAMES)('reset %s returns to package default', async (name) => {
      // Reset the template
      const deleteResponse = await fetch(`${API_BASE}/api/templates/${name}`, {
        method: 'DELETE'
      })
      expect(deleteResponse.ok).toBe(true)

      // Fetch and verify it's a valid template
      const fetchResponse = await fetch(`${API_BASE}/api/templates/${name}`)
      const fetchData = await fetchResponse.json()

      expect(fetchData.success).toBe(true)
      expect(typeof fetchData.contents).toBe('string')
      // All templates should have some content
      expect(fetchData.contents.length).toBeGreaterThan(0)
    })
  })

  describe('Round-trip: Save → Fetch → Reset', () => {
    it('complete workflow works correctly', async () => {
      const templateName = 'script'
      const testContent = '#!/usr/bin/env Rscript\n# Test round-trip\nprint("Hello")'

      // 1. Save custom content
      const saveResponse = await fetch(`${API_BASE}/api/templates/${templateName}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents: testContent })
      })
      expect(saveResponse.ok).toBe(true)

      // 2. Fetch and verify
      let fetchResponse = await fetch(`${API_BASE}/api/templates/${templateName}`)
      let fetchData = await fetchResponse.json()
      expect(fetchData.contents).toBe(testContent)

      // 3. Reset to default
      const deleteResponse = await fetch(`${API_BASE}/api/templates/${templateName}`, {
        method: 'DELETE'
      })
      expect(deleteResponse.ok).toBe(true)

      // 4. Verify it's reset (different from test content)
      fetchResponse = await fetch(`${API_BASE}/api/templates/${templateName}`)
      fetchData = await fetchResponse.json()
      expect(fetchData.contents).not.toBe(testContent)
    })
  })
})
