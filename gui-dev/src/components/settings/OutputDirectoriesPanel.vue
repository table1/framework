<template>
  <div class="space-y-6">
    <!-- Outputs Section -->
    <div :class="containerClasses">
      <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Outputs</h3>
      <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
        {{ description || 'Outputs are public by default so results are easy to share.' }}
      </p>

      <div class="space-y-3">
        <!-- Core output directories -->
        <div v-for="dirKey in coreOutputDirs" :key="dirKey">
          <Toggle
            :id="`output-${dirKey}-${componentId}`"
            :model-value="isDirectoryEnabled(dirKey)"
            @update:model-value="(val) => toggleDirectory(dirKey, val)"
            :label="getDirectoryLabel(dirKey)"
            :description="getDirectoryHint(dirKey)"
            class="mb-2"
          />
          <Input
            v-if="isDirectoryEnabled(dirKey)"
            :model-value="getDirectoryPath(dirKey)"
            @update:model-value="(val) => updateDirectoryPath(dirKey, val)"
            :placeholder="getDirectoryDefault(dirKey)"
            prefix="/"
            monospace
          />
        </div>

        <!-- Extra/custom directories from global settings -->
        <div
          v-for="dir in extraDirectories"
          :key="`extra-${dir.key}`"
        >
          <Toggle
            :id="`extra-output-${dir.key}-${componentId}`"
            :model-value="isExtraDirectoryEnabled(dir.key)"
            @update:model-value="(val) => toggleExtraDirectory(dir.key, val)"
            :label="dir.label"
            :description="`Custom: ${dir.path}`"
            class="mb-2"
          />
          <Input
            v-if="isExtraDirectoryEnabled(dir.key)"
            :model-value="dir.path"
            @update:model-value="(val) => updateExtraDirectoryPath(dir.key, val)"
            :placeholder="dir.path"
            prefix="/"
            monospace
            readonly
          />
        </div>
      </div>

      <!-- Add project-specific custom directories -->
      <div v-if="allowCustomDirectories" class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
        <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">
          Add Custom Output Directories
        </h4>
        <p class="text-xs text-gray-600 dark:text-gray-400 mb-3">
          Add directories specific to this project only.
        </p>
        <Repeater
          :model-value="projectCustomDirectories"
          @update:model-value="$emit('update:projectCustomDirectories', $event)"
          add-label="Add Output Directory"
          :default-item="() => ({ key: '', label: '', path: '', type: 'output', _id: Date.now() })"
        >
          <template #default="{ item, index, update }">
            <div class="grid grid-cols-2 gap-3">
              <Input
                :model-value="item.key"
                @update:model-value="update('key', $event)"
                label="Key"
                placeholder="e.g., outputs_animations"
                monospace
                size="sm"
              />
              <Input
                :model-value="item.label"
                @update:model-value="update('label', $event)"
                label="Label"
                placeholder="e.g., Animations"
                size="sm"
              />
              <Input
                :model-value="item.path"
                @update:model-value="update('path', $event)"
                label="Path"
                placeholder="e.g., outputs/animations"
                prefix="/"
                monospace
                size="sm"
                class="col-span-2"
              />
            </div>
          </template>
        </Repeater>
      </div>
    </div>

    <!-- Temporary Section (cache, scratch) -->
    <div v-if="showTemporary" :class="containerClasses">
      <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Temporary</h3>
      <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
        Scratch space and cache (gitignored by default).
      </p>

      <div class="space-y-3">
        <div v-for="dirKey in temporaryDirs" :key="dirKey">
          <Toggle
            :id="`temp-${dirKey}-${componentId}`"
            :model-value="isDirectoryEnabled(dirKey)"
            @update:model-value="(val) => toggleDirectory(dirKey, val)"
            :label="getDirectoryLabel(dirKey)"
            :description="getDirectoryHint(dirKey)"
            class="mb-2"
          />
          <Input
            v-if="isDirectoryEnabled(dirKey)"
            :model-value="getDirectoryPath(dirKey)"
            @update:model-value="(val) => updateDirectoryPath(dirKey, val)"
            :placeholder="getDirectoryDefault(dirKey)"
            prefix="/"
            monospace
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import Toggle from '../ui/Toggle.vue'
import Input from '../ui/Input.vue'
import Repeater from '../ui/Repeater.vue'

const props = defineProps({
  directoriesEnabled: {
    type: Object,
    required: true
  },
  directories: {
    type: Object,
    required: true
  },
  catalog: {
    type: Object,
    default: () => ({})
  },
  extraDirectoriesEnabled: {
    type: Object,
    default: () => ({})
  },
  extraDirectories: {
    type: Array,
    default: () => []
  },
  projectCustomDirectories: {
    type: Array,
    default: () => []
  },
  allowCustomDirectories: {
    type: Boolean,
    default: false
  },
  showTemporary: {
    type: Boolean,
    default: true
  },
  description: {
    type: String,
    default: ''
  },
  flush: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits([
  'update:directoriesEnabled',
  'update:directories',
  'update:extraDirectoriesEnabled',
  'update:projectCustomDirectories'
])

const componentId = ref(Math.random().toString(36).substring(7))
const coreOutputDirs = ['outputs_notebooks', 'outputs_tables', 'outputs_figures', 'outputs_models', 'outputs_reports']
const temporaryDirs = ['cache', 'scratch']

const containerClasses = computed(() =>
  props.flush ? '' : 'rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50'
)

const isDirectoryEnabled = (key) => {
  return props.directoriesEnabled[key] ?? true
}

const toggleDirectory = (key, enabled) => {
  emit('update:directoriesEnabled', {
    ...props.directoriesEnabled,
    [key]: enabled
  })
}

const getDirectoryPath = (key) => {
  return props.directories[key] || ''
}

const updateDirectoryPath = (key, value) => {
  emit('update:directories', {
    ...props.directories,
    [key]: value
  })
}

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

const isExtraDirectoryEnabled = (key) => {
  return props.extraDirectoriesEnabled[key] ?? false
}

const toggleExtraDirectory = (key, enabled) => {
  emit('update:extraDirectoriesEnabled', {
    ...props.extraDirectoriesEnabled,
    [key]: enabled
  })
}

const updateExtraDirectoryPath = (key, value) => {
  console.warn('Extra directory paths are managed in global settings')
}
</script>
