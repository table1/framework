<template>
  <div v-if="loading" class="flex items-center justify-center h-96">
    <div class="text-zinc-600 dark:text-zinc-400">Loading project...</div>
  </div>

  <div v-else-if="error" class="mx-auto max-w-5xl p-10">
    <Alert type="error" title="Error Loading Project" :description="error" />
  </div>

  <div v-else-if="project" class="mx-auto max-w-5xl p-10">
    <PageHeader
      :title="project.name"
      :description="project.path"
    >
      <template #badge>
        <Badge variant="sky">{{ project.type }}</Badge>
      </template>
    </PageHeader>

    <div class="mt-10 grid gap-6">
      <!-- Project Info Card -->
      <Card>
        <template #header>
          <h3 class="text-lg font-semibold text-zinc-900 dark:text-white">
            Project Information
          </h3>
        </template>

        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">
              Project Type
            </label>
            <p class="text-sm text-zinc-600 dark:text-zinc-400">
              {{ project.type }}
            </p>
          </div>

          <div>
            <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">
              Location
            </label>
            <div class="flex items-center gap-2">
              <p class="flex-1 text-sm text-zinc-600 dark:text-zinc-400 font-mono bg-zinc-50 dark:bg-zinc-800 px-3 py-2 rounded-lg">
                {{ project.path }}
              </p>
              <CopyButton :value="project.path" successMessage="Path copied to clipboard" />
            </div>
          </div>

          <div v-if="project.author" class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">
                Author
              </label>
              <p class="text-sm text-zinc-600 dark:text-zinc-400">
                {{ project.author }}
              </p>
            </div>
            <div v-if="project.author_email">
              <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">
                Email
              </label>
              <p class="text-sm text-zinc-600 dark:text-zinc-400">
                {{ project.author_email }}
              </p>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">
              Created
            </label>
            <p class="text-sm text-zinc-600 dark:text-zinc-400">
              {{ project.created }}
            </p>
          </div>
        </div>
      </Card>

      <!-- Project Actions Card -->
      <Card>
        <template #header>
          <h3 class="text-lg font-semibold text-zinc-900 dark:text-white">
            Quick Actions
          </h3>
        </template>

        <div class="space-y-3">
          <Button
            variant="primary"
            size="md"
            class="w-full justify-center"
            @click="openInFinder"
          >
            <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
            </svg>
            Open in Finder
          </Button>

          <Button
            variant="secondary"
            size="md"
            class="w-full justify-center"
            @click="openInEditor"
          >
            <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
            </svg>
            Open in Editor
          </Button>
        </div>
      </Card>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import PageHeader from '../components/ui/PageHeader.vue'
import Card from '../components/ui/Card.vue'
import Badge from '../components/ui/Badge.vue'
import Button from '../components/ui/Button.vue'
import Alert from '../components/ui/Alert.vue'
import CopyButton from '../components/ui/CopyButton.vue'

const route = useRoute()
const project = ref(null)
const loading = ref(true)
const error = ref(null)

const loadProject = async () => {
  loading.value = true
  error.value = null

  try {
    const response = await fetch(`/api/project/${route.params.id}`)
    const data = await response.json()

    if (data.error) {
      error.value = data.error
    } else {
      project.value = data
    }
  } catch (err) {
    error.value = 'Failed to load project: ' + err.message
  } finally {
    loading.value = false
  }
}

const openInFinder = () => {
  // This would need to be implemented via an API endpoint
  console.log('Open in Finder:', project.value.path)
}

const openInEditor = () => {
  // This would need to be implemented via an API endpoint
  console.log('Open in Editor:', project.value.path)
}

onMounted(() => {
  loadProject()
})
</script>
