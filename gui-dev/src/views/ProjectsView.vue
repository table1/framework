<template>
  <div class="mx-auto max-w-5xl p-10">
    <PageHeader
      title="Your Projects"
      description="Framework projects you've created."
    >
      <template #actions>
        <div class="flex gap-3">
          <Button size="lg" variant="secondary" @click="showImportModal = true">
            Import Project
          </Button>
          <Button size="lg" @click="goToNewProject">
            New Project
          </Button>
        </div>
      </template>
    </PageHeader>

    <InfoCard
      v-if="projectsRoot"
      class="mt-6"
      label="Projects Root"
      :value="projectsRoot"
      copyable
      copy-message="Root path copied"
    >
      <template #actions>
        <Button size="sm" variant="secondary" @click="router.push('/settings')">
          Edit
        </Button>
      </template>
    </InfoCard>

    <!-- Project List -->
    <div v-if="settings.projects && settings.projects.length > 0" class="mt-10 grid gap-6 sm:grid-cols-2">
      <ProjectCard
        v-for="(project, index) in settings.projects"
        :key="index"
        :project="project"
        :type-label="getProjectTypeLabel(project.type)"
        @view="$router.push(`/project/${project.id}`)"
        @details="viewProjectDetails"
      />
    </div>

    <!-- Empty State -->
    <div v-else class="mt-12 overflow-hidden rounded-3xl bg-gradient-to-br from-sky-600 via-sky-500 to-teal-500 p-12 shadow-2xl shadow-sky-500/20">
      <div class="relative">
        <div class="absolute -right-10 -top-10 h-40 w-40 rounded-full bg-white/10 blur-3xl"></div>
        <div class="absolute -bottom-10 -left-10 h-40 w-40 rounded-full bg-white/10 blur-3xl"></div>

        <div class="relative text-center">
          <div class="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-white/20 backdrop-blur-sm">
            <svg class="h-8 w-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
          </div>

          <h2 class="mt-6 text-3xl font-bold text-white">Ready to start?</h2>
          <p class="mt-3 text-lg text-sky-50">
            Create a new Framework project with a sensible structure and best practices built-in.
          </p>

          <button
            @click="goToNewProject"
            class="mt-8 inline-flex items-center gap-2 rounded-xl bg-white px-6 py-3 text-base font-semibold text-sky-600 shadow-xl transition-all duration-200 hover:scale-105 hover:shadow-2xl focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white"
          >
            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Create Your First Project
          </button>
        </div>
      </div>
    </div>

    <!-- Project Wizard Modal -->
    <ProjectWizard
      v-if="showWizard"
      :projects-root="projectsRoot"
      @close="handleWizardClose"
      @created="handleWizardCreated"
    />

    <!-- Import Project Modal -->
    <Modal
      v-model="showImportModal"
      title="Import Existing Project"
      size="md"
    >
      <div class="space-y-4">
        <p class="text-sm text-zinc-600 dark:text-zinc-400">
          Import an existing Framework project that isn't in your registry yet.
        </p>

        <div>
          <label for="import-path" class="block text-sm font-medium text-zinc-900 dark:text-white mb-2">
            Project Directory Path
          </label>
          <input
            id="import-path"
            v-model="importPath"
            type="text"
            placeholder="/Users/you/projects/my-framework-project"
            class="block w-full rounded-lg border-0 px-4 py-2.5 text-zinc-900 shadow-sm ring-1 ring-inset ring-zinc-300 placeholder:text-zinc-400 focus:ring-2 focus:ring-inset focus:ring-sky-600 dark:bg-zinc-800 dark:text-white dark:ring-zinc-700 dark:placeholder:text-zinc-500 dark:focus:ring-sky-500 sm:text-sm sm:leading-6 font-mono"
            :class="{ 'ring-red-500 dark:ring-red-500': importError }"
          />
          <p class="mt-2 text-xs text-zinc-500 dark:text-zinc-500">
            Enter the full path to the Framework project directory
          </p>

          <p v-if="importError" class="mt-2 text-sm text-red-600 dark:text-red-400">
            {{ importError }}
          </p>
        </div>
      </div>

      <template #actions>
        <div class="flex gap-3 justify-end">
          <Button variant="secondary" @click="closeImportModal">
            Cancel
          </Button>
          <Button
            variant="primary"
            @click="handleImport"
            :disabled="!importPath || importing"
          >
            {{ importing ? 'Importing...' : 'Import' }}
          </Button>
        </div>
      </template>
    </Modal>

    <!-- Project Details Modal -->
    <Modal
      v-model="showDetailsModal"
      title="Project Details"
      size="lg"
    >
      <div v-if="selectedProject" class="space-y-6">
        <!-- Project Name & Type -->
        <div>
          <h3 class="text-lg font-semibold text-zinc-900 dark:text-white mb-3">
            {{ selectedProject.name }}
          </h3>
          <Badge :variant="'sky'" class="mb-4">
            {{ selectedProject.type }}
          </Badge>
        </div>

        <!-- Details Grid -->
        <div class="grid gap-4">
          <!-- Path -->
          <div>
            <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">
              Location
            </label>
            <p class="text-sm text-zinc-600 dark:text-zinc-400 font-mono bg-zinc-50 dark:bg-zinc-800 px-3 py-2 rounded-lg">
              {{ selectedProject.path }}
            </p>
          </div>

          <!-- Author Info -->
          <div v-if="selectedProject.author" class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">
                Author
              </label>
              <p class="text-sm text-zinc-600 dark:text-zinc-400">
                {{ selectedProject.author }}
              </p>
            </div>
            <div v-if="selectedProject.author_email">
              <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">
                Email
              </label>
              <p class="text-sm text-zinc-600 dark:text-zinc-400">
                {{ selectedProject.author_email }}
              </p>
            </div>
          </div>

          <!-- Created Date -->
          <div>
            <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">
              Created
            </label>
            <p class="text-sm text-zinc-600 dark:text-zinc-400">
              {{ selectedProject.created }}
            </p>
          </div>
        </div>
      </div>

      <template #actions>
        <div class="flex gap-3 justify-end">
          <Button variant="secondary" @click="showDetailsModal = false">
            Close
          </Button>
          <Button variant="primary" @click="$router.push(`/project/${selectedProject.id}`); showDetailsModal = false">
            View Full Details
          </Button>
        </div>
      </template>
    </Modal>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import ProjectWizard from '../components/ProjectWizard.vue'
import ProjectCard from '../components/ProjectCard.vue'
import PageHeader from '../components/ui/PageHeader.vue'
import Button from '../components/ui/Button.vue'
import Badge from '../components/ui/Badge.vue'
import Modal from '../components/ui/Modal.vue'
import InfoCard from '../components/ui/InfoCard.vue'

const router = useRouter()
const route = useRoute()
const showWizard = ref(false)
const showImportModal = ref(false)
const showDetailsModal = ref(false)
const importPath = ref('')
const importError = ref('')
const importing = ref(false)
const selectedProject = ref(null)

const settings = ref({
  projects: []
})
const projectsRoot = ref('')
const settingsCatalog = ref(null)

// Helper function to get pretty project type labels
const getProjectTypeLabel = (type) => {
  if (!type) return 'Unknown'

  // Try to get from catalog
  const label = settingsCatalog.value?.project_types?.[type]?.label
  if (label) return label

  // Fallback: prettify the type name
  return type
    .split('_')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ')
}

const loadSettings = async () => {
  try {
    const response = await fetch('/api/settings/get')
    const data = await response.json()

    // Always load projects if they exist, regardless of global author settings
    settings.value.projects = data.projects || []
    projectsRoot.value = data.global?.projects_root && data.global.projects_root !== '' ? data.global.projects_root : ''
  } catch (error) {
    console.error('Failed to load settings:', error)
  }
}

const goToNewProject = () => {
  if (route.path === '/projects/new') {
    showWizard.value = true
  } else {
    router.push('/projects/new')
  }
}

const handleWizardClose = () => {
  showWizard.value = false
  if (route.path === '/projects/new') {
    router.push('/projects')
  }
}

const handleWizardCreated = (result) => {
  showWizard.value = false
  loadSettings()

  if (result?.id) {
    router.push(`/project/${result.id}`)
  } else {
    router.push('/projects')
  }
}

const closeImportModal = () => {
  showImportModal.value = false
  importPath.value = ''
  importError.value = ''
}

const viewProjectDetails = (project) => {
  selectedProject.value = project
  showDetailsModal.value = true
}

const handleImport = async () => {
  importError.value = ''
  importing.value = true

  try {
    const response = await fetch('/api/project/import', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ project_dir: importPath.value })
    })

    // Check if response has content before parsing JSON
    const text = await response.text()

    if (!text) {
      importError.value = 'Server returned empty response'
      importing.value = false
      return
    }

    const data = JSON.parse(text)

    if (response.ok) {
      // Success - close modal and reload projects
      closeImportModal()
      loadSettings()
    } else {
      // Show error
      importError.value = data.error || 'Failed to import project'
    }
  } catch (error) {
    importError.value = 'Network error: ' + error.message
  } finally {
    importing.value = false
  }
}

const loadSettingsCatalog = async () => {
  try {
    const response = await fetch('/api/settings-catalog')
    const data = await response.json()
    if (!data.error) {
      settingsCatalog.value = data
    }
  } catch (err) {
    console.error('Failed to load settings catalog:', err)
  }
}

onMounted(() => {
  loadSettings()
  loadSettingsCatalog()
  showWizard.value = route.path === '/projects/new'
})

watch(
  () => route.path,
  (path) => {
    showWizard.value = path === '/projects/new'
  },
  { immediate: true }
)
</script>
