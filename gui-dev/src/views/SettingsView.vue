<template>
  <div class="flex min-h-screen">
    <!-- Left Sidebar -->
    <nav class="w-64 shrink-0 border-r border-gray-200 p-6 dark:border-gray-800">
      <h2 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">Settings</h2>

      <div class="space-y-1">
        <a
          href="#author"
          @click.prevent="activeSection = 'author'"
          :class="[
            'block px-3 py-2 rounded-md text-sm transition',
            activeSection === 'author'
              ? 'bg-sky-50 text-sky-700 font-medium dark:bg-sky-900/20 dark:text-sky-400'
              : 'text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-800'
          ]"
        >
          Author Info
        </a>

        <a
          href="#defaults"
          @click.prevent="activeSection = 'defaults'"
          :class="[
            'block px-3 py-2 rounded-md text-sm transition',
            activeSection === 'defaults'
              ? 'bg-sky-50 text-sky-700 font-medium dark:bg-sky-900/20 dark:text-sky-400'
              : 'text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-800'
          ]"
        >
          General Defaults
        </a>

        <div class="pt-4 pb-2">
          <h3 class="px-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
            Project Templates
          </h3>
        </div>

        <a
          href="#project"
          @click.prevent="activeSection = 'project'"
          :class="[
            'block px-3 py-2 rounded-md text-sm transition',
            activeSection === 'project'
              ? 'bg-sky-50 text-sky-700 font-medium dark:bg-sky-900/20 dark:text-sky-400'
              : 'text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-800'
          ]"
        >
          <div class="font-medium">General Projects</div>
          <div class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">Standard data analysis</div>
        </a>

        <a
          href="#project-sensitive"
          @click.prevent="activeSection = 'project-sensitive'"
          :class="[
            'block px-3 py-2 rounded-md text-sm transition',
            activeSection === 'project-sensitive'
              ? 'bg-sky-50 text-sky-700 font-medium dark:bg-sky-900/20 dark:text-sky-400'
              : 'text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-800'
          ]"
        >
          <div class="font-medium">Sensitive Projects</div>
          <div class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">Privacy-first structure</div>
        </a>

        <a
          href="#presentation"
          @click.prevent="activeSection = 'presentation'"
          :class="[
            'block px-3 py-2 rounded-md text-sm transition',
            activeSection === 'presentation'
              ? 'bg-sky-50 text-sky-700 font-medium dark:bg-sky-900/20 dark:text-sky-400'
              : 'text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-800'
          ]"
        >
          <div class="font-medium">Presentations</div>
          <div class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">Slides and talks</div>
        </a>

        <a
          href="#course"
          @click.prevent="activeSection = 'course'"
          :class="[
            'block px-3 py-2 rounded-md text-sm transition',
            activeSection === 'course'
              ? 'bg-sky-50 text-sky-700 font-medium dark:bg-sky-900/20 dark:text-sky-400'
              : 'text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-800'
          ]"
        >
          <div class="font-medium">Courses</div>
          <div class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">Teaching materials</div>
        </a>
      </div>
    </nav>

    <!-- Main Content -->
    <div class="flex-1 p-10">
      <PageHeader
        title="Global Settings"
        description="Configure Framework defaults that apply to all new projects."
      />

      <div class="mt-8">
        <!-- Author Section (Global) -->
        <div v-show="activeSection === 'author'" id="author">
          <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Author Information</h2>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
            Your contact information used across all project types.
          </p>
          <Card>
            <div class="space-y-6">
              <Input
                v-model="settings.author.name"
                label="Your Name"
                placeholder="Your Name"
              />

              <Input
                v-model="settings.author.email"
                type="email"
                label="Email"
                placeholder="your.email@example.com"
              />

              <Input
                v-model="settings.author.affiliation"
                label="Affiliation"
                placeholder="University or Organization"
              />
            </div>
          </Card>
        </div>

        <!-- General Defaults Section -->
        <div v-show="activeSection === 'defaults'" id="defaults">
          <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">General Defaults</h2>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
            Settings shared across all project types.
          </p>

          <div class="space-y-6">
            <!-- General Settings -->
            <div class="rounded-lg bg-gray-50 p-4 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">General</h3>
              <p class="text-xs text-gray-600 dark:text-gray-400 mb-3">Core project settings.</p>
              <div class="space-y-4">
                <Select
                  v-model="settings.defaults.notebook_format"
                  label="Notebook Format"
                >
                  <option value="quarto">Quarto</option>
                  <option value="rmarkdown">RMarkdown</option>
                </Select>

                <Select
                  v-model="settings.defaults.ide"
                  label="IDE"
                >
                  <option value="vscode">Positron/VS Code</option>
                  <option value="rstudio">RStudio</option>
                  <option value="both">Both</option>
                  <option value="none">None</option>
                </Select>

                <Toggle
                  v-model="settings.defaults.use_git"
                  label="Use Git"
                  description="Initialize git repositories"
                />

                <Toggle
                  v-model="settings.defaults.use_renv"
                  label="Use renv"
                  description="Enable dependency management"
                />

                <Input
                  v-model="settings.defaults.seed"
                  label="Random Seed"
                  placeholder="e.g., 20250102"
                  hint="For reproducibility"
                />

                <Toggle
                  v-model="settings.defaults.seed_on_scaffold"
                  label="Set Seed on Scaffold"
                  description="Auto-set seed when loading"
                />
              </div>
            </div>

            <!-- AI Assistants -->
            <div class="rounded-lg bg-gray-50 p-4 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">AI Assistants</h3>
              <p class="text-xs text-gray-600 dark:text-gray-400 mb-3">AI configuration files.</p>
              <div class="space-y-4">
                <Toggle
                  v-model="settings.defaults.ai_support"
                  label="Enable AI Support"
                  description="Include AI config files"
                />

                <div v-if="settings.defaults.ai_support" class="space-y-3">
                  <div>
                    <label class="block text-sm font-medium text-gray-900 dark:text-white mb-2">
                      Assistants
                    </label>
                    <div class="space-y-2">
                      <Checkbox v-model="aiAssistants.claude" id="ai-claude">
                        Claude
                      </Checkbox>
                      <Checkbox v-model="aiAssistants.agents" id="ai-agents">
                        Multi-Agent
                      </Checkbox>
                      <Checkbox v-model="aiAssistants.copilot" id="ai-copilot">
                        GitHub Copilot
                      </Checkbox>
                    </div>
                  </div>

                  <Select
                    v-model="settings.defaults.ai_canonical_file"
                    label="Canonical File"
                  >
                    <option value="CLAUDE.md">CLAUDE.md</option>
                    <option value="AGENTS.md">AGENTS.md</option>
                    <option value=".github/copilot-instructions.md">Copilot</option>
                  </Select>
                  <p class="text-xs text-gray-500 dark:text-gray-400">
                    Source of truth for syncing
                  </p>
                </div>
              </div>
            </div>

            <!-- Git Hooks -->
            <div class="rounded-lg bg-gray-50 p-4 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Git Hooks</h3>
              <p class="text-xs text-gray-600 dark:text-gray-400 mb-3">Pre-commit automation.</p>
              <div class="space-y-4">
                <Toggle
                  v-model="settings.defaults.git_hooks.ai_sync"
                  label="AI File Sync"
                  description="Sync AI files before commits"
                />

                <Toggle
                  v-model="settings.defaults.git_hooks.data_security"
                  label="Data Security"
                  description="Check for secrets"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- Project Directories -->
        <div v-show="activeSection === 'project'" id="project">
          <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Project Directories</h2>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
            Directory structure for general data analysis projects with notebooks, scripts, and data pipelines.
          </p>
          <p class="text-sm text-gray-500 dark:text-gray-400 mb-6">
            All paths are relative to the project root directory.
          </p>

          <div class="space-y-6">
              <!-- Work Directories -->
              <div class="rounded-lg bg-gray-50 p-4 dark:bg-gray-800/50">
                <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Work Directories</h3>
                <p class="text-xs text-gray-600 dark:text-gray-400 mb-3">Where you create and organize your analysis work.</p>
                <div class="space-y-2">
                  <Input
                    v-model="settings.defaults.directories.notebooks"
                    label="Notebooks"
                    hint="Quarto/RMarkdown notebooks for analysis"
                    prefix="/"
                    monospace
                  />
                  <Input
                    v-model="settings.defaults.directories.scripts"
                    label="Scripts"
                    hint="R scripts for automation"
                    prefix="/"
                    monospace
                  />
                  <Input
                    v-model="settings.defaults.directories.functions"
                    label="Functions"
                    hint="Custom R functions (auto-sourced)"
                    prefix="/"
                    monospace
                  />
                </div>
              </div>

              <!-- Input Directories -->
              <div class="rounded-lg bg-gray-50 p-4 dark:bg-gray-800/50">
                <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Input Directories</h3>
                <p class="text-xs text-gray-600 dark:text-gray-400 mb-3">Data files flowing through your analysis pipeline.</p>
                <div class="space-y-2">
                  <Input
                    v-model="settings.defaults.directories.inputs_raw"
                    label="Raw"
                    hint="Original, unmodified data"
                    prefix="/"
                    monospace
                  />
                  <Input
                    v-model="settings.defaults.directories.inputs_intermediate"
                    label="Intermediate"
                    hint="Processed data for analysis"
                    prefix="/"
                    monospace
                  />
                  <Input
                    v-model="settings.defaults.directories.inputs_final"
                    label="Final"
                    hint="Analysis-ready datasets"
                    prefix="/"
                    monospace
                  />
                  <Input
                    v-model="settings.defaults.directories.inputs_reference"
                    label="Reference"
                    hint="Codebooks, documentation"
                    prefix="/"
                    monospace
                  />
                </div>
              </div>

              <!-- Output Directories -->
              <div class="rounded-lg bg-gray-50 p-4 dark:bg-gray-800/50">
                <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Output Directories</h3>
                <p class="text-xs text-gray-600 dark:text-gray-400 mb-3">Results, reports, and temporary files.</p>
                <div class="space-y-2">
                  <Input
                    v-model="settings.defaults.directories.outputs_private"
                    label="Private"
                    hint="Sensitive results (gitignored)"
                    prefix="/"
                    monospace
                  />
                  <Input
                    v-model="settings.defaults.directories.outputs_public"
                    label="Public"
                    hint="Shareable outputs"
                    prefix="/"
                    monospace
                  />
                  <Input
                    v-model="settings.defaults.directories.cache"
                    label="Cache"
                    hint="Temporary cached data"
                    prefix="/"
                    monospace
                  />
                  <Input
                    v-model="settings.defaults.directories.scratch"
                    label="Scratch"
                    hint="Exploratory work"
                    prefix="/"
                    monospace
                  />
                </div>
              </div>
          </div>
        </div>

        <!-- Sensitive Project Directories -->
        <div v-show="activeSection === 'project-sensitive'" id="project-sensitive">
          <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Sensitive Project Directories</h2>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
            Privacy-first directory structure with /private/ and /public/ subdirectories for sensitive data handling.
          </p>
          <Card>
            <p class="text-sm text-gray-500 dark:text-gray-400">Sensitive project directory configuration coming soon...</p>
          </Card>
        </div>

        <!-- Presentation Directories -->
        <div v-show="activeSection === 'presentation'" id="presentation">
          <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Presentation Directories</h2>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
            Directory structure for creating presentations and slide decks with Quarto Reveal.js.
          </p>
          <Card>
            <p class="text-sm text-gray-500 dark:text-gray-400">Presentation directory configuration coming soon...</p>
          </Card>
        </div>

        <!-- Course Directories -->
        <div v-show="activeSection === 'course'" id="course">
          <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Course Directories</h2>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
            Directory structure for creating course materials including slides, assignments, and reading lists.
          </p>
          <Card>
            <p class="text-sm text-gray-500 dark:text-gray-400">Course directory configuration coming soon...</p>
          </Card>
        </div>
      </div>

      <!-- Save Button (fixed at bottom) -->
      <div class="mt-8 flex justify-end">
        <Button @click="saveSettings" size="lg">
          Save All Settings
        </Button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, onUnmounted, watch } from 'vue'
import PageHeader from '../components/ui/PageHeader.vue'
import Card from '../components/ui/Card.vue'
import Input from '../components/ui/Input.vue'
import Select from '../components/ui/Select.vue'
import Toggle from '../components/ui/Toggle.vue'
import Checkbox from '../components/ui/Checkbox.vue'
import Button from '../components/ui/Button.vue'
import { useToast } from '../composables/useToast'

const toast = useToast()

const activeSection = ref('author')

const projectTabs = [
  { id: 'defaults', label: 'Defaults' },
  { id: 'ai', label: 'AI Assistants' },
  { id: 'directories', label: 'Directories' },
  { id: 'hooks', label: 'Git Hooks' }
]

const settings = ref({
  author: {
    name: '',
    email: '',
    affiliation: ''
  },
  defaults: {
    project_type: 'project',
    notebook_format: 'quarto',
    ide: 'vscode',
    use_git: true,
    use_renv: false,
    seed: '',
    seed_on_scaffold: true,
    ai_support: true,
    ai_assistants: [],
    ai_canonical_file: 'CLAUDE.md',
    directories: {
      notebooks: 'notebooks',
      scripts: 'scripts',
      functions: 'functions',
      inputs_raw: 'inputs/raw',
      inputs_intermediate: 'inputs/intermediate',
      inputs_final: 'inputs/final',
      inputs_reference: 'inputs/reference',
      outputs_private: 'outputs/private',
      outputs_public: 'outputs/public',
      cache: 'outputs/private/cache',
      scratch: 'outputs/private/scratch'
    },
    git_hooks: {
      ai_sync: false,
      data_security: false
    }
  }
})

// Helper for AI assistants checkboxes
const aiAssistants = reactive({
  claude: false,
  agents: false,
  copilot: false
})

// Sync AI assistants array with checkboxes
watch(aiAssistants, (newVal) => {
  const assistants = []
  if (newVal.claude) assistants.push('claude')
  if (newVal.agents) assistants.push('agents')
  if (newVal.copilot) assistants.push('copilot')
  settings.value.defaults.ai_assistants = assistants
}, { deep: true })

const saveSettings = async () => {
  try {
    // Prepare settings for saving (convert empty seed to null)
    const settingsToSave = {
      ...settings.value,
      defaults: {
        ...settings.value.defaults,
        seed: settings.value.defaults.seed === '' ? null : settings.value.defaults.seed
      }
    }

    const response = await fetch('/api/settings/save', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(settingsToSave)
    })

    if (response.ok) {
      toast.success('Settings saved', 'Your global settings have been saved successfully.')
    } else {
      toast.error('Failed to save', 'There was an error saving your settings. Please try again.')
    }
  } catch (error) {
    console.error('Failed to save settings:', error)
    toast.error('Network error', 'Could not connect to the server. Please check your connection.')
  }
}

const loadSettings = async () => {
  try {
    const response = await fetch('/api/settings/get')
    const data = await response.json()

    if (data.author) {
      settings.value.author = {
        name: data.author?.name || '',
        email: data.author?.email || '',
        affiliation: data.author?.affiliation || ''
      }
    }

    if (data.defaults) {
      // Handle simple fields
      if (data.defaults.project_type) settings.value.defaults.project_type = data.defaults.project_type
      if (data.defaults.notebook_format) settings.value.defaults.notebook_format = data.defaults.notebook_format
      if (data.defaults.ide) settings.value.defaults.ide = data.defaults.ide
      if (data.defaults.use_git !== undefined) settings.value.defaults.use_git = data.defaults.use_git
      if (data.defaults.use_renv !== undefined) settings.value.defaults.use_renv = data.defaults.use_renv
      if (data.defaults.ai_support !== undefined) settings.value.defaults.ai_support = data.defaults.ai_support
      if (data.defaults.ai_canonical_file) settings.value.defaults.ai_canonical_file = data.defaults.ai_canonical_file
      if (data.defaults.seed_on_scaffold !== undefined) settings.value.defaults.seed_on_scaffold = data.defaults.seed_on_scaffold

      // Handle seed (convert null to empty string for input, handle objects)
      if (data.defaults.seed !== undefined) {
        if (data.defaults.seed === null || data.defaults.seed === '') {
          settings.value.defaults.seed = ''
        } else if (typeof data.defaults.seed === 'object') {
          settings.value.defaults.seed = ''
        } else {
          settings.value.defaults.seed = String(data.defaults.seed)
        }
      }

      // Handle nested directories object
      if (data.defaults.directories) {
        settings.value.defaults.directories = {
          ...settings.value.defaults.directories,
          ...data.defaults.directories
        }
      }

      // Handle nested git_hooks object
      if (data.defaults.git_hooks) {
        settings.value.defaults.git_hooks = {
          ...settings.value.defaults.git_hooks,
          ...data.defaults.git_hooks
        }
      }

      // Set AI assistants checkboxes
      if (data.defaults.ai_assistants) {
        aiAssistants.claude = data.defaults.ai_assistants.includes('claude')
        aiAssistants.agents = data.defaults.ai_assistants.includes('agents')
        aiAssistants.copilot = data.defaults.ai_assistants.includes('copilot')
      }
    }
  } catch (error) {
    console.error('Failed to load settings:', error)
  }
}

// Keyboard shortcut handler
const handleKeyDown = (event) => {
  // Check for Cmd+S (Mac) or Ctrl+S (Windows/Linux)
  if ((event.metaKey || event.ctrlKey) && event.key === 's') {
    event.preventDefault()
    saveSettings()
  }
}

onMounted(() => {
  loadSettings()
  // Add keyboard listener
  window.addEventListener('keydown', handleKeyDown)
})

onUnmounted(() => {
  // Clean up keyboard listener
  window.removeEventListener('keydown', handleKeyDown)
})
</script>
