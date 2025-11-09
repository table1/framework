<template>
  <div class="relative">
    <Input
      v-model="searchQuery"
      :label="label"
      :placeholder="placeholder"
      @keydown="handleKeydown"
    />

    <!-- Search Results Dropdown -->
    <div
      v-if="results.length > 0"
      class="absolute z-10 mt-1 w-full max-h-64 overflow-y-auto border border-gray-200 dark:border-gray-700 rounded-md bg-white dark:bg-gray-800 shadow-lg"
    >
      <button
        v-for="(pkg, index) in results"
        :key="pkg.name"
        @click="selectPackage(pkg)"
        @mouseenter="highlightIndex = index"
        :class="[
          'w-full px-3 py-2 text-left border-b border-gray-200 dark:border-gray-700 last:border-b-0 transition',
          highlightIndex === index
            ? 'bg-sky-50 dark:bg-sky-900/20'
            : 'hover:bg-gray-50 dark:hover:bg-gray-700'
        ]"
      >
        <div class="flex items-center justify-between gap-3">
          <div class="flex-1 min-w-0">
            <div class="font-medium text-gray-900 dark:text-white">{{ pkg.name }}</div>
            <div class="text-xs text-gray-500 dark:text-gray-400 truncate">{{ pkg.title }}</div>
          </div>
          <div class="ml-3 text-xs text-gray-400 dark:text-gray-500 shrink-0 flex items-center gap-1.5">
            <span class="text-[10px] font-medium">{{ pkg.source === 'cran' ? 'CRAN' : pkg.source === 'bioconductor' ? 'Bioconductor' : pkg.source }}</span>
            <span>·</span>
            <span>v{{ pkg.version }}</span>
          </div>
        </div>
      </button>
    </div>

    <!-- Loading indicator -->
    <div v-if="searching" class="absolute right-3 top-9 text-gray-400">
      <svg class="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import Input from './Input.vue'

const props = defineProps({
  modelValue: {
    type: String,
    default: ''
  },
  label: {
    type: String,
    default: 'Search Packages'
  },
  placeholder: {
    type: String,
    default: 'Type to search...'
  },
  source: {
    type: String,
    default: 'cran',
    validator: (value) => ['cran', 'bioconductor', 'github'].includes(value)
  }
})

const emit = defineEmits(['update:modelValue', 'select'])

const searchQuery = ref(props.modelValue)
const results = ref([])
const searching = ref(false)
const highlightIndex = ref(-1)
let searchTimeout = null

// Watch for external updates
watch(() => props.modelValue, (newVal) => {
  searchQuery.value = newVal
})

// Watch for search query changes
watch(searchQuery, (newVal) => {
  emit('update:modelValue', newVal)

  if (searchTimeout) clearTimeout(searchTimeout)

  if (newVal.length < 2) {
    results.value = []
    highlightIndex.value = -1
    return
  }

  searchTimeout = setTimeout(() => {
    searchPackages(newVal)
  }, 300)
})

const searchPackages = async (query) => {
  searching.value = true
  try {
    const response = await fetch(`/api/packages/search?q=${encodeURIComponent(query)}&source=${encodeURIComponent(props.source)}`)
    const data = await response.json()
    results.value = data.packages || []
    highlightIndex.value = results.value.length > 0 ? 0 : -1
  } catch (err) {
    console.error('Failed to search packages:', err)
    results.value = []
    highlightIndex.value = -1
  } finally {
    searching.value = false
  }
}

const handleKeydown = (e) => {
  if (results.value.length === 0) return

  if (e.key === 'ArrowDown') {
    e.preventDefault()
    highlightIndex.value = Math.min(highlightIndex.value + 1, results.value.length - 1)
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    highlightIndex.value = Math.max(highlightIndex.value - 1, 0)
  } else if (e.key === 'Enter' && highlightIndex.value >= 0) {
    e.preventDefault()
    selectPackage(results.value[highlightIndex.value])
  } else if (e.key === 'Escape') {
    results.value = []
    highlightIndex.value = -1
  }
}

const selectPackage = (pkg) => {
  searchQuery.value = pkg.name
  emit('update:modelValue', pkg.name)
  emit('select', pkg)
  results.value = []
  highlightIndex.value = -1
}
</script>
