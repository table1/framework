<template>
  <div :class="containerClasses">
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Materials</h3>
    <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
      Slides, assignments, readings, and course documentation with automatic rendering to web-ready formats.
    </p>

    <div class="space-y-5">
      <!-- Renderable workspaces (with Quarto render directories) -->
      <div v-for="dirKey in renderableWorkspaces" :key="dirKey">
        <Toggle
          :id="`course-${dirKey}-${componentId}`"
          :model-value="isDirectoryEnabled(dirKey)"
          @update:model-value="(val) => toggleDirectory(dirKey, val)"
          :label="getDirectoryLabel(dirKey)"
          :description="getDirectoryHint(dirKey)"
          class="mb-2"
        />
        <div v-if="isDirectoryEnabled(dirKey)" class="grid grid-cols-2 gap-3">
          <Input
            :model-value="getDirectoryPath(dirKey)"
            @update:model-value="(val) => updateDirectoryPath(dirKey, val)"
            :placeholder="getDirectoryDefault(dirKey)"
            label="Source files"
            prefix="/"
            monospace
          />
          <Input
            :model-value="getRenderDirectory(dirKey)"
            @update:model-value="(val) => updateRenderDirectory(dirKey, val)"
            :placeholder="getRenderDirectoryDefault(dirKey)"
            label="Quarto render directory"
            prefix="/"
            monospace
          />
        </div>
      </div>

      <!-- Reference materials (readings, data) -->
      <div v-for="dirKey in referenceMaterials" :key="dirKey">
        <Toggle
          :id="`course-${dirKey}-${componentId}`"
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

      <!-- Helper code directories (functions, scripts) -->
      <div v-for="dirKey in helperDirectories" :key="dirKey">
        <Toggle
          :id="`course-${dirKey}-${componentId}`"
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
        class="space-y-1.5"
      >
        <Toggle
          :id="`extra-course-${dir.key}-${componentId}`"
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
        Add Custom Course Directories
      </h4>
      <p class="text-xs text-gray-600 dark:text-gray-400 mb-3">
        Add directories specific to this course only.
      </p>
      <Repeater
        :model-value="projectCustomDirectories"
        @update:model-value="$emit('update:projectCustomDirectories', $event)"
        add-label="Add Course Directory"
        :default-item="() => ({ key: '', label: '', path: '', type: 'course', _id: Date.now() })"
      >
        <template #default="{ item, index, update }">
          <div class="grid grid-cols-2 gap-3">
            <Input
              :model-value="item.key"
              @update:model-value="update('key', $event)"
              label="Key"
              placeholder="e.g., course_videos"
              monospace
              size="sm"
            />
            <Input
              :model-value="item.label"
              @update:model-value="update('label', $event)"
              label="Label"
              placeholder="e.g., Videos"
              size="sm"
            />
            <Input
              :model-value="item.path"
              @update:model-value="update('path', $event)"
              label="Path"
              placeholder="e.g., videos"
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
  renderDirs: {
    type: Object,
    default: () => ({})
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
  flush: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits([
  'update:directoriesEnabled',
  'update:directories',
  'update:renderDirs',
  'update:extraDirectoriesEnabled',
  'update:projectCustomDirectories'
])

const componentId = ref(Math.random().toString(36).substring(7))

// Directory order matching SettingsView.vue
const renderableWorkspaces = ['slides', 'assignments', 'course_docs', 'notebooks']
const referenceMaterials = ['readings', 'data']
const helperDirectories = ['functions', 'scripts']

const containerClasses = computed(() =>
  props.flush ? '' : 'rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50'
)

const isDirectoryEnabled = (key) => {
  // Check if explicitly set in directoriesEnabled
  if (key in props.directoriesEnabled) {
    return props.directoriesEnabled[key]
  }
  // Fall back to catalog's enabled_by_default
  const catalogDefault = props.catalog?.directories?.[key]?.enabled_by_default
  return catalogDefault ?? false
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

const getRenderDirectory = (key) => {
  // Map directory key to render_dirs key
  const renderKey = key === 'notebooks' ? 'modules' : key

  // Check if render dir is explicitly set
  if (props.renderDirs[renderKey]) {
    return props.renderDirs[renderKey]
  }

  // Fall back to catalog default
  return props.catalog?.render_dirs?.[renderKey]?.default || ''
}

const updateRenderDirectory = (key, value) => {
  // Map directory key to render_dirs key
  const renderKey = key === 'notebooks' ? 'modules' : key
  emit('update:renderDirs', {
    ...props.renderDirs,
    [renderKey]: value
  })
}

const getRenderDirectoryDefault = (key) => {
  if (!props.catalog || typeof props.catalog !== 'object') {
    return ''
  }

  // Map directory key to render_dirs key
  const renderKey = key === 'notebooks' ? 'modules' : key

  // Check render_dirs in catalog
  const renderDirsCatalog = props.catalog.render_dirs || {}
  return renderDirsCatalog[renderKey]?.default || `rendered/${renderKey}`
}

const getDirectoryLabel = (key) => {
  if (!props.catalog || typeof props.catalog !== 'object') {
    return key.charAt(0).toUpperCase() + key.slice(1)
  }
  const directories = props.catalog.directories || {}
  return directories[key]?.label || key.charAt(0).toUpperCase() + key.slice(1)
}

const getDirectoryHint = (key) => {
  if (!props.catalog || typeof props.catalog !== 'object') {
    return ''
  }
  const directories = props.catalog.directories || {}
  return directories[key]?.hint || ''
}

const getDirectoryDefault = (key) => {
  if (!props.catalog || typeof props.catalog !== 'object') {
    return key
  }
  const directories = props.catalog.directories || {}
  return directories[key]?.default || key
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
