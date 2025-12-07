<template>
  <div class="space-y-3">
    <div
      v-for="leaf in flatLeaves"
      :key="leaf.fullKey"
      class="rounded-md border border-gray-200 bg-white px-4 py-3 dark:border-gray-700 dark:bg-gray-900"
    >
      <div class="flex items-start justify-between gap-3">
        <div class="min-w-0">
          <div class="flex items-center gap-2 mb-2">
            <h3 class="text-sm font-semibold text-gray-900 dark:text-white truncate">{{ leaf.fullKey }}</h3>
            <span
              v-if="leaf.data?.type"
              class="inline-flex items-center rounded-full border border-gray-200 bg-white px-2.5 py-0.5 text-xs font-medium text-gray-700 dark:border-gray-600 dark:bg-gray-900 dark:text-gray-100"
            >
              {{ leaf.data.type }}
            </span>
            <span
              v-if="isPendingSave(leaf)"
              class="inline-flex items-center rounded-full bg-emerald-100 px-2.5 py-0.5 text-[11px] font-medium text-emerald-800 dark:bg-emerald-900 dark:text-emerald-100"
            >
              Pending save
            </span>
            <LockClosedIcon
              v-if="leaf.data?.locked"
              class="h-4 w-4 text-gray-400 dark:text-gray-500"
              aria-label="Locked data source"
            />
          </div>
          <div class="mt-2 space-y-1">
            <div class="flex flex-wrap items-center gap-2 text-xs text-gray-600 dark:text-gray-300">
              <span class="text-sm font-semibold text-gray-700 dark:text-gray-200">Path:</span>
              <span class="font-mono break-all">{{ leaf.data?.path || '—' }}</span>
              <CopyButton
                v-if="leaf.data?.path"
                :value="relativePath(leaf)"
                size="xs"
                variant="secondary"
                class="!px-2 !py-1 text-[11px]"
                successMessage="Relative path copied"
              >
                Copy relative path
              </CopyButton>
              <CopyButton
                v-if="leaf.data?.path"
                :value="fullPath(leaf)"
                size="xs"
                variant="secondary"
                class="!px-2 !py-1 text-[11px]"
                successMessage="Full path copied"
              >
                Copy full path
              </CopyButton>
            </div>
            <div class="flex flex-wrap items-center gap-2 text-xs text-gray-600 dark:text-gray-300">
              <span class="text-sm font-semibold text-gray-700 dark:text-gray-200">Usage:</span>
              <span class="font-mono break-all">data_read('{{ leaf.fullKey }}')</span>
              <CopyButton
                :value="`data_read('${leaf.fullKey}')`"
                size="xs"
                variant="secondary"
                class="!px-2 !py-1 text-[11px]"
                successMessage="Usage copied"
              >
                Copy
              </CopyButton>
            </div>
          </div>
        </div>
        <div class="flex items-center gap-2 shrink-0">
          <Button
            size="sm"
            variant="secondary"
            :class="deleteButtonClass(leaf)"
            @click.stop="emit('delete', leaf)"
          >
            {{ isMarkedForDelete(leaf) ? 'Undo' : 'Delete' }}
          </Button>
          <Button
            size="sm"
            variant="secondary"
            class="shadow-none"
            @click="emit('edit', leaf)"
          >
            Edit
          </Button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import Button from './ui/Button.vue'
import CopyButton from './ui/CopyButton.vue'
import { LockClosedIcon } from '@heroicons/vue/20/solid'

const props = defineProps({
  node: {
    type: Object,
    required: true
  },
  pendingDeletes: {
    type: Object,
    default: () => new Set()
  },
  pendingUpdates: {
    type: Boolean,
    default: false
  },
  pendingAdds: {
    type: Array,
    default: () => []
  },
  searchTerm: {
    type: String,
    default: ''
  },
  projectPath: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['edit', 'delete'])

const flattenLeaves = (node, acc = []) => {
  if (!node) return acc
  if (!node.children || node.children.length === 0) {
    acc.push(node)
    return acc
  }
  node.children.forEach((child) => flattenLeaves(child, acc))
  return acc
}

const matchesSearch = (leaf) => {
  const term = props.searchTerm?.toLowerCase?.().trim()
  if (!term) return true
  return (
    leaf.fullKey?.toLowerCase().includes(term) ||
    leaf.data?.path?.toLowerCase?.().includes(term)
  )
}

const flatLeaves = computed(() => {
  const leaves = flattenLeaves(props.node, [])
  return leaves
    .filter(matchesSearch)
    .sort((a, b) => (a.fullKey || '').localeCompare(b.fullKey || ''))
})

const isMarkedForDelete = (leaf) => props.pendingDeletes?.has?.(leaf.fullKey)
const deleteButtonClass = (leaf) =>
  isMarkedForDelete(leaf)
    ? 'border-red-200 text-red-700 dark:border-red-800 dark:text-red-200'
    : ''

const isPendingSave = (leaf) =>
  props.pendingUpdates || (Array.isArray(props.pendingAdds) && props.pendingAdds.includes(leaf.fullKey))

const relativePath = (leaf) => leaf.data?.path || ''

const fullPath = (leaf) => {
  const rel = relativePath(leaf).replace(/\\/g, '/').replace(/^\/+/, '')
  const root = props.projectPath ? props.projectPath.replace(/\\/g, '/').replace(/\/+$/, '') : ''
  return root && rel ? `${root}/${rel}` : rel
}
</script>
