<template>
  <div :class="containerClasses">
    <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">
      {{ title || 'Renderable Workspaces' }}
    </h3>
    <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
      {{ description || 'Workspaces that render to output directories.' }}
    </p>

    <div class="space-y-4">
      <!-- Core renderable directories -->
      <div v-for="dirKey in renderableKeys" :key="dirKey">
        <Toggle
          :id="`renderable-${dirKey}-${componentId}`"
          :model-value="isDirectoryEnabled(dirKey)"
          @update:model-value="(val) => toggleDirectory(dirKey, val)"
          :label="getDirectoryLabel(dirKey)"
          :description="getDirectoryHint(dirKey)"
          class="mb-3"
        />

        <div v-if="isDirectoryEnabled(dirKey)" class="grid grid-cols-1 gap-3 ml-6">
          <!-- Source directory -->
          <div>
            <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
              Source directory
            </label>
            <Input
              :model-value="getDirectoryPath(dirKey)"
              @update:model-value="(val) => updateDirectoryPath(dirKey, val)"
              :placeholder="getDirectoryDefault(dirKey)"
              prefix="/"
              monospace
              size="sm"
            />
          </div>

          <!-- Output directory (only for Quarto) -->
          <div v-if="notebookFormat === 'quarto'">
            <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
              Renders to
            </label>
            <Input
              :model-value="getOutputPath(dirKey)"
              @update:model-value="(val) => updateOutputPath(dirKey, val)"
              :placeholder="getOutputDefault(dirKey)"
              prefix="/"
              monospace
              size="sm"
            />
          </div>

          <!-- RMarkdown hint -->
          <div v-else class="text-xs text-gray-500 dark:text-gray-400 italic">
            RMarkdown renders to source directory (output directory not configurable)
          </div>
        </div>
      </div>

      <!-- Extra directories from global settings -->
      <div
        v-for="dir in extraDirectories"
        :key="`extra-${dir.key}`"
      >
        <Toggle
          :id="`extra-renderable-${dir.key}-${componentId}`"
          :model-value="isExtraDirectoryEnabled(dir.key)"
          @update:model-value="(val) => toggleExtraDirectory(dir.key, val)"
          :label="dir.label"
          :description="`Custom: ${dir.path}`"
          class="mb-3"
        />

        <div v-if="isExtraDirectoryEnabled(dir.key)" class="grid grid-cols-1 gap-3 ml-6">
          <!-- Source directory (readonly for global extras) -->
          <div>
            <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
              Source directory
            </label>
            <Input
              :model-value="dir.path"
              :placeholder="dir.path"
              prefix="/"
              monospace
              size="sm"
              readonly
            />
          </div>

          <!-- Output directory -->
          <div v-if="notebookFormat === 'quarto' && dir.renderable !== false">
            <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
              Renders to
            </label>
            <Input
              :model-value="dir.output || `outputs/${dir.path}`"
              :placeholder="dir.output || `outputs/${dir.path}`"
              prefix="/"
              monospace
              size="sm"
              readonly
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Add project-specific custom renderable directories -->
    <div v-if="allowCustomDirectories" class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
      <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">
        Add Custom Renderable Directories
      </h4>
      <p class="text-xs text-gray-600 dark:text-gray-400 mb-3">
        Add renderable directories specific to this project only.
      </p>
      <Repeater
        :model-value="projectCustomDirectories"
        @update:model-value="$emit('update:projectCustomDirectories', $event)"
        add-label="Add Renderable Directory"
        :default-item="() => ({
          key: '',
          label: '',
          path: '',
          output: '',
          type: customDirType || 'renderable',
          renderable: true,
          _id: Date.now()
        })"
      >
        <template #default="{ item, index, update }">
          <div class="grid grid-cols-2 gap-3">
            <Input
              :model-value="item.key"
              @update:model-value="update('key', $event)"
              label="Key"
              placeholder="e.g., tutorials"
              monospace
              size="sm"
            />
            <Input
              :model-value="item.label"
              @update:model-value="update('label', $event)"
              label="Label"
              placeholder="e.g., Tutorials"
              size="sm"
            />
            <Input
              :model-value="item.path"
              @update:model-value="update('path', $event)"
              label="Source Path"
              placeholder="e.g., tutorials"
              prefix="/"
              monospace
              size="sm"
            />
            <Input
              v-if="notebookFormat === 'quarto'"
              :model-value="item.output"
              @update:model-value="update('output', $event)"
              label="Output Path"
              placeholder="e.g., outputs/tutorials"
              prefix="/"
              monospace
              size="sm"
            />
          </div>
        </template>
      </Repeater>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import Toggle from '../ui/Toggle.vue'
import Input from '../ui/Input.vue'
import Repeater from '../ui/Repeater.vue'

const props = defineProps({
  // Which directories are enabled
  directoriesEnabled: {
    type: Object,
    required: true
  },

  // Source directory paths
  directories: {
    type: Object,
    required: true
  },

  // Output directory paths (e.g., { notebooks: "outputs/notebooks" })
  outputDirectories: {
    type: Object,
    default: () => ({})
  },

  // Directory metadata from catalog
  catalog: {
    type: Object,
    default: () => ({})
  },

  // List of renderable workspace keys for this project type
  // e.g., ['notebooks', 'docs'] for project type
  renderableKeys: {
    type: Array,
    required: true
  },

  // Notebook format (quarto or rmarkdown)
  notebookFormat: {
    type: String,
    default: 'quarto',
    validator: (value) => ['quarto', 'rmarkdown'].includes(value)
  },

  // Extra directories enabled
  extraDirectoriesEnabled: {
    type: Object,
    default: () => ({})
  },

  // Extra directories from global settings
  extraDirectories: {
    type: Array,
    default: () => []
  },

  // Project-specific custom directories
  projectCustomDirectories: {
    type: Array,
    default: () => []
  },

  // Whether to show "Add Custom Directory" section
  allowCustomDirectories: {
    type: Boolean,
    default: false
  },

  // Custom directory type for new items
  customDirType: {
    type: String,
    default: 'renderable'
  },

  // Optional title override
  title: {
    type: String,
    default: ''
  },

  // Optional description override
  description: {
    type: String,
    default: ''
  },

  // UI control
  flush: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits([
  'update:directoriesEnabled',
  'update:directories',
  'update:outputDirectories',
  'update:extraDirectoriesEnabled',
  'update:projectCustomDirectories'
])

const componentId = ref(Math.random().toString(36).substring(7))

const containerClasses = computed(() =>
  props.flush ? '' : 'rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50'
)

// Directory enabled/disabled
const isDirectoryEnabled = (key) => {
  return props.directoriesEnabled[key] ?? true
}

const toggleDirectory = (key, enabled) => {
  emit('update:directoriesEnabled', {
    ...props.directoriesEnabled,
    [key]: enabled
  })
}

// Source directory paths
const getDirectoryPath = (key) => {
  return props.directories[key] || ''
}

const updateDirectoryPath = (key, value) => {
  emit('update:directories', {
    ...props.directories,
    [key]: value
  })
}

// Output directory paths
const getOutputPath = (key) => {
  return props.outputDirectories[key] || ''
}

const updateOutputPath = (key, value) => {
  emit('update:outputDirectories', {
    ...props.outputDirectories,
    [key]: value
  })
}

// Directory metadata from catalog
const getDirectoryLabel = (key) => {
  if (!props.catalog || typeof props.catalog !== 'object') {
    return key.charAt(0).toUpperCase() + key.slice(1)
  }
  return props.catalog[key]?.label || key.charAt(0).toUpperCase() + key.slice(1)
}

const getDirectoryHint = (key) => {
  if (!props.catalog || typeof props.catalog !== 'object') {
    return ''
  }
  return props.catalog[key]?.hint || ''
}

const getDirectoryDefault = (key) => {
  if (!props.catalog || typeof props.catalog !== 'object') {
    return key
  }
  return props.catalog[key]?.default || key
}

const getOutputDefault = (key) => {
  if (!props.catalog || typeof props.catalog !== 'object') {
    return `outputs/${key}`
  }
  return props.catalog[key]?.output || `outputs/${key}`
}

// Extra directories (from global settings)
const isExtraDirectoryEnabled = (key) => {
  return props.extraDirectoriesEnabled[key] ?? false
}

const toggleExtraDirectory = (key, enabled) => {
  emit('update:extraDirectoriesEnabled', {
    ...props.extraDirectoriesEnabled,
    [key]: enabled
  })
}
</script>
