<template>
  <div>
    <!-- Search/Filter -->
    <div v-if="files.length > 0 || searchTerm" class="mb-4">
      <Input
        v-model="searchTerm"
        placeholder="Filter files..."
        class="max-w-sm"
      >
        <template #prefix>
          <MagnifyingGlassIcon class="h-4 w-4 text-gray-400" />
        </template>
      </Input>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-sky-600"></div>
    </div>

    <!-- Empty State -->
    <EmptyState
      v-else-if="files.length === 0"
      :title="emptyTitle"
      :description="emptyDescription"
      icon="folder"
    />

    <!-- No Results -->
    <EmptyState
      v-else-if="filteredFiles.length === 0"
      title="No matching files"
      description="Try a different search term"
      icon="search"
    />

    <!-- File List -->
    <div v-else class="space-y-2">
      <div
        v-for="file in filteredFiles"
        :key="file.path"
        class="flex items-center justify-between gap-4 rounded-lg border border-gray-200 bg-white p-4 transition hover:border-gray-300 dark:border-gray-700 dark:bg-gray-800/50 dark:hover:border-gray-600"
      >
        <div class="flex items-center gap-3 min-w-0">
          <!-- File Type Icon -->
          <div class="shrink-0">
            <DocumentIcon v-if="!file.is_dir" class="h-5 w-5 text-gray-400" />
            <FolderIcon v-else class="h-5 w-5 text-sky-500" />
          </div>

          <!-- File Info -->
          <div class="min-w-0">
            <p class="text-sm font-medium text-gray-900 dark:text-white truncate" :title="file.name">
              {{ file.name }}
            </p>
            <div class="flex items-center gap-3 mt-1 text-xs text-gray-500 dark:text-gray-400">
              <span v-if="file.size !== undefined && !file.is_dir">
                {{ formatSize(file.size) }}
              </span>
              <span v-if="file.modified">
                {{ file.modified }}
              </span>
            </div>
          </div>
        </div>

        <!-- Actions -->
        <div class="flex items-center gap-2 shrink-0">
          <CopyButton
            :value="file.path"
            successMessage="Path copied"
            variant="ghost"
            title="Copy path"
          />
        </div>
      </div>
    </div>

    <!-- File Count -->
    <p v-if="files.length > 0 && !loading" class="mt-4 text-xs text-gray-500 dark:text-gray-400">
      {{ filteredFiles.length }} of {{ files.length }} files
    </p>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import Input from './ui/Input.vue'
import CopyButton from './ui/CopyButton.vue'
import EmptyState from './ui/EmptyState.vue'
import { DocumentIcon, FolderIcon, MagnifyingGlassIcon } from '@heroicons/vue/24/outline'

const props = defineProps({
  files: {
    type: Array,
    default: () => []
  },
  loading: {
    type: Boolean,
    default: false
  },
  emptyTitle: {
    type: String,
    default: 'No files'
  },
  emptyDescription: {
    type: String,
    default: 'This directory is empty or does not exist yet.'
  }
})

const searchTerm = ref('')

const filteredFiles = computed(() => {
  if (!searchTerm.value) {
    return props.files
  }
  const term = searchTerm.value.toLowerCase()
  return props.files.filter(file =>
    file.name.toLowerCase().includes(term) ||
    file.path.toLowerCase().includes(term)
  )
})

const formatSize = (bytes) => {
  if (bytes === 0) return '0 B'
  if (!bytes) return ''
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i]
}
</script>
