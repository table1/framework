<template>
  <div>
    <!-- Filter Tabs -->
    <div v-if="results.length > 0 || activeFilter !== 'all'" class="mb-4">
      <div class="flex flex-wrap gap-2">
        <button
          v-for="filter in filterOptions"
          :key="filter.value"
          @click="activeFilter = filter.value"
          :class="[
            'px-3 py-1.5 text-xs font-medium rounded-full transition',
            activeFilter === filter.value
              ? 'bg-sky-100 text-sky-700 dark:bg-sky-900/40 dark:text-sky-300'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-gray-700'
          ]"
        >
          {{ filter.label }}
          <span v-if="filter.count > 0" class="ml-1 text-[10px] opacity-70">
            ({{ filter.count }})
          </span>
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-sky-600"></div>
    </div>

    <!-- Empty State -->
    <EmptyState
      v-else-if="results.length === 0"
      title="No saved results"
      description="Results will appear here when you use save_table(), save_figure(), save_model(), etc."
      icon="chart"
    />

    <!-- No Results for Filter -->
    <EmptyState
      v-else-if="filteredResults.length === 0"
      title="No results match this filter"
      description="Try selecting a different type"
      icon="filter"
    />

    <!-- Results List -->
    <div v-else class="space-y-3">
      <div
        v-for="result in filteredResults"
        :key="result.name"
        class="rounded-lg border border-gray-200 bg-white p-4 dark:border-gray-700 dark:bg-gray-800/50"
      >
        <div class="flex items-start justify-between gap-4">
          <div class="flex items-start gap-3 min-w-0">
            <!-- Type Icon -->
            <div class="shrink-0 mt-0.5">
              <TableCellsIcon v-if="result.type === 'table'" class="h-5 w-5 text-emerald-500" />
              <ChartBarIcon v-else-if="result.type === 'figure'" class="h-5 w-5 text-violet-500" />
              <CubeIcon v-else-if="result.type === 'model'" class="h-5 w-5 text-amber-500" />
              <DocumentTextIcon v-else-if="result.type === 'report'" class="h-5 w-5 text-rose-500" />
              <BookOpenIcon v-else-if="result.type === 'notebook'" class="h-5 w-5 text-sky-500" />
              <DocumentIcon v-else class="h-5 w-5 text-gray-400" />
            </div>

            <!-- Result Info -->
            <div class="min-w-0">
              <div class="flex items-center gap-2">
                <p class="text-sm font-medium text-gray-900 dark:text-white truncate" :title="result.name">
                  {{ result.name }}
                </p>
                <Badge :variant="getTypeBadgeVariant(result.type)" size="sm">
                  {{ result.type }}
                </Badge>
                <Badge v-if="result.public" variant="sky" size="sm">
                  public
                </Badge>
              </div>

              <p v-if="result.comment" class="mt-1 text-sm text-gray-600 dark:text-gray-400 line-clamp-2">
                {{ result.comment }}
              </p>

              <div class="flex items-center gap-3 mt-2 text-xs text-gray-500 dark:text-gray-400">
                <span v-if="result.created_at" :title="'Created: ' + result.created_at">
                  {{ formatDate(result.updated_at || result.created_at) }}
                </span>
                <span v-if="result.hash" class="font-mono text-[10px]" :title="'Hash: ' + result.hash">
                  {{ result.hash.substring(0, 8) }}...
                </span>
              </div>
            </div>
          </div>

          <!-- Actions -->
          <div class="flex items-center gap-2 shrink-0">
            <CopyButton
              :value="result.name"
              successMessage="Filename copied"
              variant="ghost"
              title="Copy filename"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Result Count -->
    <p v-if="results.length > 0 && !loading" class="mt-4 text-xs text-gray-500 dark:text-gray-400">
      {{ filteredResults.length }} of {{ results.length }} results
    </p>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import Badge from './ui/Badge.vue'
import CopyButton from './ui/CopyButton.vue'
import EmptyState from './ui/EmptyState.vue'
import {
  TableCellsIcon,
  ChartBarIcon,
  CubeIcon,
  DocumentTextIcon,
  BookOpenIcon,
  DocumentIcon
} from '@heroicons/vue/24/outline'

const props = defineProps({
  results: {
    type: Array,
    default: () => []
  },
  loading: {
    type: Boolean,
    default: false
  }
})

const activeFilter = ref('all')

const filterOptions = computed(() => {
  const counts = {
    all: props.results.length,
    table: 0,
    figure: 0,
    model: 0,
    report: 0,
    notebook: 0
  }

  props.results.forEach(r => {
    if (counts[r.type] !== undefined) {
      counts[r.type]++
    }
  })

  return [
    { value: 'all', label: 'All', count: counts.all },
    { value: 'table', label: 'Tables', count: counts.table },
    { value: 'figure', label: 'Figures', count: counts.figure },
    { value: 'model', label: 'Models', count: counts.model },
    { value: 'report', label: 'Reports', count: counts.report },
    { value: 'notebook', label: 'Notebooks', count: counts.notebook }
  ].filter(f => f.value === 'all' || f.count > 0)
})

const filteredResults = computed(() => {
  if (activeFilter.value === 'all') {
    return props.results
  }
  return props.results.filter(r => r.type === activeFilter.value)
})

const getTypeBadgeVariant = (type) => {
  const variants = {
    table: 'green',
    figure: 'blue',
    model: 'yellow',
    report: 'red',
    notebook: 'sky'
  }
  return variants[type] || 'gray'
}

const formatDate = (dateStr) => {
  if (!dateStr) return ''
  try {
    const date = new Date(dateStr)
    const now = new Date()
    const diffMs = now - date
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))

    if (diffDays === 0) {
      return 'today'
    } else if (diffDays === 1) {
      return 'yesterday'
    } else if (diffDays < 7) {
      return `${diffDays} days ago`
    } else {
      return date.toLocaleDateString()
    }
  } catch {
    return dateStr
  }
}
</script>
