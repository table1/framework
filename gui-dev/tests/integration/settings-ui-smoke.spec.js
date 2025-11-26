import { describe, it, beforeEach, afterEach, expect } from 'vitest'
import { render, fireEvent, screen, waitFor } from '@testing-library/vue'
import { createRouter, createMemoryHistory } from 'vue-router'
import SettingsView from '../../src/views/SettingsView.vue'

const makeRouter = () =>
  createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: '/settings/:section?/:subsection?',
        name: 'settings',
        component: SettingsView
      }
    ]
  })

const catalogFixture = {
  project_types: {
    project: {
      label: 'Standard Project Structure',
      description: 'General-purpose analysis project.',
      directories: {
        notebooks: 'notebooks',
        scripts: 'scripts',
        functions: 'R/functions',
        inputs_raw: 'inputs/raw',
        cache: 'outputs/cache'
      },
      render_dirs: {}
    },
    project_sensitive: {
      label: 'Privacy Sensitive Project Structure',
      description: 'PHI/PII-friendly layout with separate private/public flows.',
      directories: {
        inputs_private_raw: 'inputs/private/raw',
        inputs_public_raw: 'inputs/public/raw',
        scripts: 'scripts'
      },
      render_dirs: {}
    }
  }
}

const settingsFixture = {
  global: { projects_root: '/tmp/projects' },
  defaults: {
    project_type: 'project',
    notebook_format: 'quarto',
    ide: 'vscode',
    positron: false,
    use_git: true,
    use_renv: false,
    ai_support: true,
    ai_canonical_file: 'CLAUDE.md',
    ai_assistants: ['claude'],
    scaffold: {
      source_all_functions: true,
      set_theme_on_scaffold: true,
      ggplot_theme: 'theme_minimal',
      seed_on_scaffold: false,
      seed: ''
    },
    packages: {
      use_renv: false,
      default_packages: [{ name: 'dplyr', source: 'cran', auto_attach: true }]
    },
    git_hooks: {
      ai_sync: false,
      data_security: false,
      check_sensitive_dirs: false
    },
    env: { raw: '' }
  },
  project_types: catalogFixture.project_types
}

const templateResponse = { contents: '' }

const mockFetch = () =>
  vi.fn(async (url) => {
    if (url.includes('/api/settings/catalog')) {
      return new Response(JSON.stringify(catalogFixture), { status: 200 })
    }
    if (url.includes('/api/settings/get')) {
      return new Response(JSON.stringify(settingsFixture), { status: 200 })
    }
    if (url.includes('/api/templates/')) {
      return new Response(JSON.stringify(templateResponse), { status: 200 })
    }
    return new Response('{}', { status: 200 })
  })

describe('Settings UI smoke', () => {
  let fetchSpy

  beforeEach(() => {
    fetchSpy = mockFetch()
    vi.stubGlobal('fetch', fetchSpy)
    // Stub scrollIntoView for happy-dom
    if (!window.HTMLElement.prototype.scrollIntoView) {
      window.HTMLElement.prototype.scrollIntoView = vi.fn()
    }
  })

  afterEach(() => {
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  const renderSettings = async (path = '/settings') => {
    const router = makeRouter()
    router.push(path)
    await router.isReady()
    return render(SettingsView, {
      global: {
        plugins: [router]
      }
    })
  }

  it('shows Overview cards on load', async () => {
    await renderSettings()
    const headings = await screen.findAllByText('Overview')
    expect(headings.length).toBeGreaterThan(0)
    expect(screen.getByText('Overview of your Framework global settings and preferences.')).toBeTruthy()
  })

  it('renders Basics fields when navigating', async () => {
    await renderSettings()
    const basicsLink = (await screen.findAllByRole('link', { name: 'Basics' }))[0]
    await fireEvent.click(basicsLink)
    expect(await screen.findByText('Default Projects Directory')).toBeTruthy()
    expect(screen.getByText('Author Information')).toBeTruthy()
  })

  it('renders Project Structure section', async () => {
    await renderSettings()
    const structureLink = (await screen.findAllByRole('link', { name: 'Project Structure' }))[0]
    await fireEvent.click(structureLink)
    expect(await screen.findByText('Project Structure Defaults')).toBeTruthy()
    expect(screen.getByText('Standard Project Structure')).toBeTruthy()
  })

  it('renders Standard Project directories from catalog', async () => {
    await renderSettings('/settings/project-structure/project')
    // Should land on Standard Project editor with directories from catalog fixture
    expect(await screen.findByDisplayValue('notebooks')).toBeTruthy()
    expect(await screen.findByDisplayValue('scripts')).toBeTruthy()
  })

  it('renders Privacy Sensitive directories from catalog', async () => {
    await renderSettings('/settings/project-structure/sensitive-project')
    expect(await screen.findByDisplayValue('inputs/private/raw')).toBeTruthy()
    expect(await screen.findByDisplayValue('inputs/public/raw')).toBeTruthy()
  })

  it('renders Packages section with defaults', async () => {
    await renderSettings()
    const packagesLink = (await screen.findAllByRole('link', { name: 'Packages' }))[0]
    await fireEvent.click(packagesLink)
    expect(await screen.findByText('Default packages')).toBeTruthy()
    // PackagesEditor should render the default package name
    const pkgInputs = await screen.findAllByDisplayValue('dplyr')
    expect(pkgInputs.length).toBeGreaterThan(0)
    // renv toggle label present
    expect(screen.getByText('Enable renv')).toBeTruthy()

    // Toggle renv and ensure UI reflects it (mocked payload)
    const renvLabel = await screen.findByText('Enable renv')
    await fireEvent.click(renvLabel)
    // We can’t assert backend, but UI should still have the input rendered
    expect(await screen.findByText('Default packages')).toBeTruthy()
  })

  it('renders Git & Hooks section and respects Initialize Git toggle', async () => {
    await renderSettings()
    const gitLink = (await screen.findAllByRole('link', { name: 'Git & Hooks' }))[0]
    await fireEvent.click(gitLink)

    expect(await screen.findByText('Git Hooks')).toBeTruthy()
    // Wait for the section to finish hydrating
    await screen.findByText('Git identity')
    expect(screen.getByText('Sync AI Files Before Commit')).toBeTruthy()

    // Turning off git initialization disables identity inputs and hook toggles
    const initToggleInput = await screen.findByLabelText('Initialize Git')
    expect(initToggleInput).toBeChecked()
    await fireEvent.click(initToggleInput)
    await waitFor(() => expect(initToggleInput).not.toBeChecked())
  })
})
