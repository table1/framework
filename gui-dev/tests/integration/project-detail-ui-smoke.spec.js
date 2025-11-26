import { describe, it, beforeEach, afterEach, expect } from 'vitest'
import { render, screen } from '@testing-library/vue'
import { createRouter, createMemoryHistory } from 'vue-router'
import ProjectDetailView from '../../src/views/ProjectDetailView.vue'

const makeRouter = () =>
  createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: '/project/:id',
        name: 'project-detail',
        component: ProjectDetailView,
        props: true
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
    }
  }
}

const projectFixture = {
  id: 1,
  name: 'Demo Project',
  path: '/tmp/projects/demo',
  type: 'project',
  author: { name: 'Test User', email: 'test@example.com', affiliation: 'Org' },
  scaffold: {
    positron: false,
    notebook_format: 'quarto'
  }
}

const settingsFixture = {
  project_types: catalogFixture.project_types
}

const projectSettingsFixture = {
  directories: {
    notebooks: 'notebooks',
    scripts: 'scripts'
  },
  render_dirs: {},
  enabled: {
    notebooks: true,
    scripts: true
  },
  extra_directories: [],
  gitignore: '',
  scaffold: {
    source_all_functions: true,
    set_theme_on_scaffold: true,
    ggplot_theme: 'theme_minimal',
    seed_on_scaffold: false,
    seed: ''
  },
  packages: {
    use_renv: true,
    default_packages: [{ name: 'dplyr', source: 'cran', auto_attach: true }]
  }
}

const projectPackagesFixture = {
  use_renv: true,
  packages: [{ name: 'dplyr', source: 'cran', auto_attach: true }]
}

const projectEnvFixture = {
  variables: { POSTGRES_HOST: 'localhost' },
  groups: { POSTGRES: { POSTGRES_HOST: { defined: true, value: 'localhost', used: false, used_in: [] } } },
  raw_content: 'POSTGRES_HOST=localhost'
}

const normalizeUrl = (input) => {
  if (input instanceof Request) return new URL(input.url)
  if (input instanceof URL) return input
  const href = typeof input === 'string' ? input : `${input}`
  if (href.startsWith('http')) return new URL(href)
  const path = href.startsWith('/') ? href : `/${href}`
  return new URL(`http://localhost${path}`)
}

const mockFetch = () =>
  vi.fn(async (url) => {
    const resolved = normalizeUrl(url)
    const pathname = resolved.pathname

    if (pathname.includes('/api/project/1/packages')) {
      return new Response(JSON.stringify(projectPackagesFixture), { status: 200 })
    }
    if (pathname.includes('/api/project/1/env')) {
      return new Response(JSON.stringify(projectEnvFixture), { status: 200 })
    }
    if (pathname.includes('/api/project/1/settings')) {
      return new Response(JSON.stringify({ settings: projectSettingsFixture }), { status: 200 })
    }
    if (pathname.includes('/api/project/1')) {
      return new Response(JSON.stringify(projectFixture), { status: 200 })
    }
    if (pathname.includes('/api/settings-catalog') || pathname.includes('/api/settings/catalog')) {
      return new Response(JSON.stringify(catalogFixture), { status: 200 })
    }
    if (pathname.includes('/api/settings')) {
      return new Response(JSON.stringify(settingsFixture), { status: 200 })
    }
    if (pathname.includes('/api/templates/')) {
      return new Response(JSON.stringify({ contents: '' }), { status: 200 })
    }
    return new Response('{}', { status: 200 })
  })

describe('Project Detail UI smoke (data ↔ UI)', () => {
  let fetchSpy

  beforeEach(() => {
    fetchSpy = mockFetch()
    vi.stubGlobal('fetch', fetchSpy)
    window.fetch = fetchSpy
    const OriginalRequest = Request
    const PatchedRequest = class extends OriginalRequest {
      constructor(input, init) {
        const href = typeof input === 'string' && !input.startsWith('http') ? `http://localhost${input.startsWith('/') ? '' : '/'}${input}` : input
        super(href, init)
      }
    }
    vi.stubGlobal('Request', PatchedRequest)
    window.Request = PatchedRequest
    globalThis.Request = PatchedRequest
    // Stub loadProjects injection target if referenced elsewhere
    vi.stubGlobal('injectedLoadProjects', vi.fn())
    if (!window.HTMLElement.prototype.scrollIntoView) {
      window.HTMLElement.prototype.scrollIntoView = vi.fn()
    }
  })

  afterEach(() => {
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  const renderPage = async () => {
    const router = makeRouter()
    router.push('/project/1')
    await router.isReady()
    return render(ProjectDetailView, {
      global: { plugins: [router] },
      props: { id: '1' }
    })
  }

  it('shows project name/path in sidebar (basics)', async () => {
    await renderPage()
    const nameEls = await screen.findAllByText('Demo Project')
    expect(nameEls.length).toBeGreaterThan(0)
    const pathEls = screen.getAllByText('/tmp/projects/demo')
    expect(pathEls.length).toBeGreaterThan(0)
  })

  it('renders Packages tab with project packages', async () => {
    await renderPage()
    const packagesLink = (await screen.findAllByRole('link', { name: 'Packages' }))[0]
    await packagesLink.click()
    expect(await screen.findByDisplayValue('dplyr')).toBeTruthy()
  })

  it('renders Project Structure tab with directories', async () => {
    await renderPage()
    const structureLink = (await screen.findAllByRole('link', { name: 'Project Structure' }))[0]
    await structureLink.click()
    expect(await screen.findByDisplayValue('notebooks')).toBeTruthy()
  })

  it('renders Env tab with variables', async () => {
    await renderPage()
    const envLink = await screen.findByText('.env Defaults')
    await envLink.click()
    expect(await screen.findByDisplayValue('localhost')).toBeTruthy()
  })
})
