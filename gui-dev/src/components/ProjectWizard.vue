<template>
  <div :class="outerClass" @click.self="handleBackdropClick">
    <Card :class="cardClass">
      <template #header>
        <div class="flex items-center justify-between">
          <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Create New Project</h2>
          <button
            v-if="isModal"
            @click="$emit('close')"
            class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 transition"
          >
            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      </template>

      <div class="space-y-6">
        <!-- Project Directory -->
        <Input
          v-model="form.directory"
          label="Project Directory"
          :placeholder="directoryPlaceholder"
          :hint="directoryHint"
          @input="suggestName"
        />

        <div
          v-if="normalizedRoot || showFullPathPreview"
          class="text-xs text-gray-500 dark:text-gray-400 space-y-1"
        >
          <p v-if="normalizedRoot">
            Projects will be created inside <span class="font-mono">{{ normalizedRoot }}</span>.
          </p>
          <p v-if="showFullPathPreview">
            Full path: <span class="font-mono">{{ resolvedDirectory }}</span>
          </p>
        </div>

        <!-- Project Name -->
        <Input
          v-model="form.name"
          label="Project Name"
          placeholder="My Analysis"
        />

        <!-- Project Type -->
        <div>
          <label class="block text-sm/6 font-medium text-gray-900 dark:text-white mb-3">
            Project Type
          </label>
          <div class="space-y-2">
            <div
              v-for="type in projectTypes"
              :key="type.id"
              @click="form.type = type.id"
              :class="[
                'border-2 rounded-lg p-4 cursor-pointer transition',
                form.type === type.id
                  ? 'border-sky-600 bg-sky-50 dark:bg-sky-900/20 dark:border-sky-500'
                  : 'border-gray-200 dark:border-gray-700 hover:border-sky-300 dark:hover:border-sky-600'
              ]"
            >
              <div class="flex items-start gap-3">
                <div class="text-2xl mt-0.5">{{ type.icon }}</div>
                <div class="flex-1">
                  <h3 class="font-semibold text-gray-900 dark:text-white">{{ type.title }}</h3>
                  <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">{{ type.description }}</p>
                </div>
                <div v-if="form.type === type.id" class="text-sky-600 dark:text-sky-400">
                  <svg class="h-6 w-6" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                  </svg>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Privacy Mode (only for project type) -->
        <div v-if="form.type === 'project'" class="bg-gray-50 dark:bg-gray-800/50 rounded-lg p-4">
          <Checkbox
            v-model="form.sensitive"
            id="sensitive"
            description="Creates separate public/private directories for inputs, reference materials, and outputs. Recommended for PHI, PII, or IRB-restricted data."
          >
            Privacy-first mode
          </Checkbox>
        </div>

        <!-- Options -->
        <div class="space-y-3">
          <Checkbox v-model="form.use_git" id="use_git">
            Initialize git repository
          </Checkbox>

          <Checkbox v-model="form.use_renv" id="use_renv">
            Enable renv for package management
          </Checkbox>

          <Checkbox v-model="form.attach_defaults" id="attach_defaults">
            Auto-load common packages (dplyr, tidyr, ggplot2)
          </Checkbox>
        </div>

        <!-- Error message -->
        <Alert v-if="error" type="error" :description="error" />

        <!-- Success message -->
        <Alert v-if="success" type="success" title="Project created successfully!">
          <p class="mt-2">Next steps:</p>
          <ol class="list-decimal list-inside mt-1 space-y-1">
            <li>cd {{ resolvedDirectory }}</li>
            <li>R</li>
            <li>library(framework)</li>
            <li>scaffold()</li>
          </ol>
        </Alert>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-3">
          <Button variant="secondary" @click="$emit('close')">
            Cancel
          </Button>
          <Button
            variant="primary"
            @click="createProject"
            :disabled="creating || !form.directory"
          >
            {{ creating ? 'Creating...' : 'Create Project' }}
          </Button>
        </div>
      </template>
    </Card>
  </div>
</template>

<script setup>
import { ref, reactive, computed } from 'vue'
import Card from './ui/Card.vue'
import Button from './ui/Button.vue'
import Input from './ui/Input.vue'
import Checkbox from './ui/Checkbox.vue'
import Alert from './ui/Alert.vue'

const props = defineProps({
  mode: {
    type: String,
    default: 'modal',
    validator: (value) => ['modal', 'page'].includes(value)
  },
  projectsRoot: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['close', 'created'])

const isModal = computed(() => props.mode === 'modal')

const normalizedRoot = computed(() => (props.projectsRoot || '').trim())

const isAbsolutePath = (value) => /^([A-Za-z]:[\\/]|\\\\|\/|~)/.test(value)

const joinPaths = (root, segment) => {
  if (!root) return segment
  const sanitizedSegment = segment.replace(/^[\\/]+/, '')
  if (!sanitizedSegment) return root
  if (root.endsWith('/') || root.endsWith('\\')) {
    return `${root}${sanitizedSegment}`
  }
  const separator = root.includes('\\') && !root.includes('/') ? '\\' : '/'
  return `${root}${separator}${sanitizedSegment}`
}

const outerClass = computed(() => (
  isModal.value
    ? 'fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4'
    : 'flex w-full justify-center'
))

const cardClass = computed(() => (
  isModal.value
    ? 'max-w-2xl w-full max-h-[90vh] overflow-y-auto'
    : 'w-full max-w-2xl shadow-xl'
))

const form = reactive({
  directory: '',
  name: '',
  type: 'project',
  sensitive: false,
  use_git: true,
  use_renv: false,
  attach_defaults: true
})

const resolvedDirectory = computed(() => {
  const dir = form.directory.trim()
  if (!dir) {
    return normalizedRoot.value || ''
  }
  if (isAbsolutePath(dir)) {
    return dir
  }
  if (!normalizedRoot.value) {
    return dir
  }
  return joinPaths(normalizedRoot.value, dir)
})

const showFullPathPreview = computed(() => {
  const dir = form.directory.trim()
  if (!dir) return false
  return normalizedRoot.value.length > 0 || isAbsolutePath(dir)
})

const directoryHint = computed(() => {
  if (normalizedRoot.value) {
    return `Folder will be created inside ${normalizedRoot.value}`
  }
  return 'The directory where your project will be created'
})

const directoryPlaceholder = computed(() => (normalizedRoot.value ? 'analytics-project' : 'my-analysis'))

const projectTypes = [
  {
    id: 'project',
    title: 'Data Analysis',
    description: 'Full-featured project with notebooks, scripts, data management, and results tracking',
    icon: '📊'
  },
  {
    id: 'course',
    title: 'Course Materials',
    description: 'Teaching materials with slides, assignments, and course documentation',
    icon: '🎓'
  },
  {
    id: 'presentation',
    title: 'Presentation',
    description: 'Single talk or presentation with minimal structure',
    icon: '📽️'
  }
]

const creating = ref(false)
const error = ref('')
const success = ref(false)

const handleBackdropClick = () => {
  if (isModal.value) {
    emit('close')
  }
}

const suggestName = () => {
  if (!form.name && form.directory) {
    // Convert directory name to title case
    form.name = form.directory
      .split(/[-_]/)
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ')
  }
}

const createProject = async () => {
  error.value = ''
  success.value = false
  creating.value = true

  try {
    const targetDirectory = resolvedDirectory.value || form.directory

    const response = await fetch('/api/project/create', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        project_dir: targetDirectory,
        project_name: form.name || form.directory,
        type: form.type,
        sensitive: form.sensitive,
        use_git: form.use_git,
        use_renv: form.use_renv,
        attach_defaults: form.attach_defaults
      })
    })

    const result = await response.json()

    if (response.ok && result.success) {
      success.value = true
      if (result && !result.path) {
        result.path = targetDirectory
      }
      emit('created', result)
      if (isModal.value) {
        setTimeout(() => {
          emit('close')
        }, 3000)
      }
    } else {
      error.value = result.error || 'Failed to create project'
    }
  } catch (err) {
    error.value = 'Network error: ' + err.message
  } finally {
    creating.value = false
  }
}
</script>
