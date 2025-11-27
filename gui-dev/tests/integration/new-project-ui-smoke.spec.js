import { describe, it, beforeEach, afterEach, expect } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/vue'
import { createRouter, createMemoryHistory } from 'vue-router'
import NewProjectView from '../../src/views/NewProjectView.vue'

const makeRouter = () =>
  createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: '/projects/new',
        name: 'project-create',
        component: NewProjectView
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
    description: 'Projects handling PHI/PII with dedicated private/public data flows.',
    directories: {
      inputs_private_raw: 'inputs/private/raw',
      inputs_public_raw: 'inputs/public/raw',
      scripts: 'scripts'
    },
    render_dirs: {}
  },
  presentation: {
    label: 'Presentation',
    description: 'Minimal structure for slides and supporting assets.',
    directories: {
      presentation_source: 'presentation.qmd',
      rendered_slides: 'outputs/slides'
    },
    render_dirs: {}
  },
  course: {
    label: 'Course/Teaching',
    description: 'Simplified structure for teaching materials.',
    directories: {
      data: 'data',
      slides: 'slides',
      assignments: 'assignments',
      course_docs: 'course_docs',
      readings: 'readings',
      notebooks: 'modules'
    },
    render_dirs: {}
  }
}
}

const settingsFixture = {
  global: { projects_root: '/tmp/projects' },
  author: { name: 'Test User', email: 'test@example.com', affiliation: 'Org' },
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
    use_renv: true,
    default_packages: [{ name: 'dplyr', source: 'cran', auto_attach: true }],
    git_hooks: {
      ai_sync: false,
      data_security: false,
      check_sensitive_dirs: false
    },
    env: { raw: '' },
    connections: {
      default_database: 'warehouse',
      default_storage_bucket: 's3_bucket',
      databases: {
        warehouse: {
          driver: 'postgres',
          host: 'localhost',
          port: '5432',
          database: 'analytics'
        }
      },
      storage_buckets: {
        s3_bucket: {
          bucket: 'my-bucket',
          region: 'us-east-1'
        }
      }
    }
  },
  project_types: catalogFixture.project_types
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
    if (pathname.includes('/api/settings-catalog')) {
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

describe('New Project UI smoke (data ↔ UI)', () => {
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
    globalThis.location = new URL('http://localhost/')
    // Stub scrollIntoView
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
    router.push('/projects/new')
    await router.isReady()
    const utils = render(NewProjectView, {
      global: {
        plugins: [router],
        provide: {
          loadProjects: vi.fn()
        }
      }
    })
    return { ...utils, router }
  }

  it('prefills Basics from defaults (project type, author)', async () => {
    await renderPage()
    const basicsLink = (await screen.findAllByRole('link', { name: /Basics/i }))[0]
    await basicsLink.click()
    expect(await screen.findByLabelText('Project Name')).toBeTruthy()
    expect(screen.getByLabelText('Project Type').value).toBe('project')
  })

  it('renders Packages defaults (renv on, package row)', async () => {
    await renderPage()
    const packagesTab = (await screen.findAllByRole('link', { name: 'Packages' }))[0]
    await packagesTab.click()
    // dplyr default package row present
    expect(await screen.findByDisplayValue('dplyr')).toBeTruthy()
  })

  it('shows default project directories in structure editor', async () => {
    await renderPage()
    const structureTab = (await screen.findAllByRole('link', { name: 'Project Structure' }))[0]
    await structureTab.click()
    expect(await screen.findByDisplayValue('notebooks')).toBeTruthy()
    expect(await screen.findByDisplayValue('scripts')).toBeTruthy()
  })

  it('switches to Privacy Sensitive project type and shows private/public directories', async () => {
    const { router } = await renderPage()

    // Navigate to Basics to change project type
    await router.replace({ path: '/projects/new', query: { section: 'basics' } })
    await screen.findByLabelText('Project Name')
    const typeSelect = await screen.findByLabelText('Project Type')
    await fireEvent.update(typeSelect, 'project_sensitive')

    // Navigate to Project Structure
    await router.replace({ path: '/projects/new', query: { section: 'structure' } })

    // Ensure the structure section is active
    await screen.findByRole('radio', { name: /Privacy Sensitive Project/i })

    // Verify private/public directory fields render with the expected paths
    expect(await screen.findByDisplayValue('inputs/private/raw')).toBeTruthy()
    expect(await screen.findByDisplayValue('inputs/public/raw')).toBeTruthy()
  })

  it('switches to Presentation project type and shows presentation files', async () => {
    const { router } = await renderPage()

    // Set project type from Basics
    await router.replace({ path: '/projects/new', query: { section: 'basics' } })
    await screen.findByLabelText('Project Name')
    const typeSelect = await screen.findByLabelText('Project Type')
    await fireEvent.update(typeSelect, 'presentation')

    // Navigate to Project Structure
    await router.replace({ path: '/projects/new', query: { section: 'structure' } })
    await screen.findByRole('radio', { name: /Presentation/i })

    expect(await screen.findByDisplayValue('presentation.qmd')).toBeTruthy()
    expect(await screen.findByDisplayValue('outputs/slides')).toBeTruthy()
  })

  it('switches to Course project type and shows course directories', async () => {
    const { router } = await renderPage()

    await router.replace({ path: '/projects/new', query: { section: 'basics' } })
    await screen.findByLabelText('Project Name')
    const typeSelect = await screen.findByLabelText('Project Type')
    await fireEvent.update(typeSelect, 'course')

    await router.replace({ path: '/projects/new', query: { section: 'structure' } })

    expect(await screen.findByDisplayValue('slides')).toBeTruthy()
    expect(await screen.findByDisplayValue('assignments')).toBeTruthy()
    expect(await screen.findByDisplayValue('course_docs')).toBeTruthy()
    expect(await screen.findByDisplayValue('modules')).toBeTruthy()
  })
})
