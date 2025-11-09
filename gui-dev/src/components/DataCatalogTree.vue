<template>
  <div>
    <div v-if="isGroup" :id="anchorId || undefined" :class="groupWrapperClass">
      <template v-if="hierarchical">
        <button
          type="button"
          class="flex w-full items-start gap-3 text-left transition hover:text-zinc-900 focus:outline-none"
          @click="handleToggle"
          :aria-expanded="isExpanded"
        >
          <ChevronRightIcon
            class="mt-1.5 h-4 w-4 shrink-0 text-zinc-400 transition-transform"
            :class="{ 'rotate-90 text-sky-500': isExpanded }"
          />

          <div class="flex-1">
            <p :class="titleClass">
              <template v-for="(part, index) in nameParts" :key="index">
                <mark
                  v-if="part.highlight"
                  class="rounded bg-amber-200/70 px-0.5 text-amber-900 dark:bg-amber-700/40 dark:text-amber-100"
                >
                  {{ part.text }}
                </mark>
                <span v-else>{{ part.text }}</span>
              </template>
            </p>
            <p class="mt-1 text-xs text-zinc-500 dark:text-zinc-400">
              {{ entryLabel }}
            </p>
          </div>

          <span class="text-xs font-medium uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
            {{ isExpanded ? 'Hide' : 'Show' }}
          </span>
        </button>

        <transition name="catalog-collapse">
          <div v-show="isExpanded" :class="childContainerClass">
            <DataCatalogTree
              v-for="child in node.children"
              :key="child.fullKey"
              :node="child"
              :depth="depth + 1"
              :expanded-keys="expandedKeys"
              :auto-expanded-keys="autoExpandedKeys"
              :toggle-group="toggleGroup"
              :search-term="searchTerm"
              :hierarchical="hierarchical"
              :pending-deletes="pendingDeletes"
              @edit="emit('edit', $event)"
              @delete="emit('delete', $event)"
            />
          </div>
        </transition>
      </template>

      <template v-else>
        <div class="flex items-start gap-3">
          <div class="flex-1">
            <p :class="titleClass">
              <template v-for="(part, index) in nameParts" :key="index">
                <mark
                  v-if="part.highlight"
                  class="rounded bg-amber-200/70 px-0.5 text-amber-900 dark:bg-amber-700/40 dark:text-amber-100"
                >
                  {{ part.text }}
                </mark>
                <span v-else>{{ part.text }}</span>
              </template>
            </p>
            <p class="mt-1 text-xs text-zinc-500 dark:text-zinc-400">
              {{ entryLabel }}
            </p>
          </div>
        </div>

        <div :class="childContainerClass">
          <DataCatalogTree
            v-for="child in node.children"
            :key="child.fullKey"
            :node="child"
            :depth="depth + 1"
            :expanded-keys="expandedKeys"
            :auto-expanded-keys="autoExpandedKeys"
            :toggle-group="toggleGroup"
            :search-term="searchTerm"
            :hierarchical="hierarchical"
            :pending-deletes="pendingDeletes"
            @edit="emit('edit', $event)"
            @delete="emit('delete', $event)"
          />
        </div>
      </template>
    </div>

    <div v-else :id="anchorId || undefined" :class="leafWrapperClass">
      <div class="flex items-start justify-between gap-4">
        <div class="min-w-0 flex items-center gap-2">
          <h3 class="text-sm font-semibold text-gray-900 dark:text-white">
            <template v-for="(part, index) in nameParts" :key="`leaf-${index}`">
              <mark
                v-if="part.highlight"
                class="rounded bg-amber-200/70 px-0.5 text-amber-900 dark:bg-amber-700/40 dark:text-amber-100"
              >
                {{ part.text }}
              </mark>
              <span v-else>{{ part.text }}</span>
            </template>
          </h3>
          <span
            v-if="node.data?.type"
            class="inline-flex items-center rounded-full border border-gray-200 bg-white px-2.5 py-1 text-xs font-medium text-gray-700 dark:border-gray-600 dark:bg-gray-900 dark:text-gray-100"
          >
            {{ node.data.type }}
          </span>
        </div>

        <div class="flex items-center gap-2 shrink-0">
          <Button
            size="sm"
            variant="secondary"
            :class="deleteButtonClass"
            @click.stop="emit('delete', node)"
          >
            {{ isMarkedForDelete ? 'Undo' : 'Delete' }}
          </Button>
          <Button
            size="sm"
            variant="secondary"
            class="shadow-none"
            @click="emit('edit', node)"
          >
            Edit
          </Button>
        </div>
      </div>

      <div class="mt-5 space-y-4">
        <div
          v-if="node.data?.description"
          class="space-y-2"
        >
          <p class="text-xs font-medium text-gray-600 dark:text-zinc-200">
            Description
          </p>
          <p class="text-sm leading-relaxed text-gray-600 dark:text-zinc-300">
            {{ node.data.description }}
          </p>
        </div>

        <div
          v-if="node.fullKey"
          class="flex items-start gap-3"
        >
          <CopyButton
            :value="node.fullKey || ''"
            successMessage="Dot notation copied"
            variant="bare"
            :class="copyButtonClass"
            title="Copy dot notation"
          >
            <template #default="{ copied }">
              <svg
                v-if="!copied"
                class="h-4 w-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"
                />
              </svg>
              <svg
                v-else
                class="h-4 w-4 text-emerald-500"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                />
              </svg>
            </template>
          </CopyButton>

          <div class="min-w-0 flex-1">
            <p class="text-xs font-medium text-gray-700 dark:text-zinc-100">
              Location (in Dot Notation)
            </p>
            <p class="mt-1 font-mono text-sm leading-relaxed text-gray-900 dark:text-zinc-100">
              <template v-if="keyParts.length > 0">
                <template v-for="(part, index) in keyParts" :key="`key-${index}`">
                  <mark
                    v-if="part.highlight"
                    class="rounded bg-amber-200/60 px-0.5 text-amber-900 dark:bg-amber-700/40 dark:text-amber-100"
                  >
                    {{ part.text }}
                  </mark>
                  <span v-else>{{ part.text }}</span>
                </template>
              </template>
              <span v-else class="text-zinc-500">—</span>
            </p>
          </div>
        </div>

        <div class="flex items-start gap-3 pt-4 border-t border-gray-200 dark:border-zinc-700">
          <CopyButton
            :value="node.data?.path || ''"
            successMessage="Path copied"
            variant="bare"
            :class="copyButtonClass"
            title="Copy path"
          >
            <template #default="{ copied }">
              <svg
                v-if="!copied"
                class="h-4 w-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"
                />
              </svg>
              <svg
                v-else
                class="h-4 w-4 text-emerald-500"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                />
              </svg>
            </template>
          </CopyButton>

          <div class="min-w-0 flex-1">
            <p class="text-xs font-medium text-gray-700 dark:text-zinc-100">
              File Path
            </p>
            <p class="mt-1 font-mono text-sm leading-relaxed text-gray-900 dark:text-zinc-100">
              <template v-if="pathParts.length > 0">
                <template v-for="(part, index) in pathParts" :key="`path-${index}`">
                  <mark
                    v-if="part.highlight"
                    class="rounded bg-amber-200/60 px-0.5 text-amber-900 dark:bg-amber-700/40 dark:text-amber-100"
                  >
                    {{ part.text }}
                  </mark>
                  <span v-else>{{ part.text }}</span>
                </template>
              </template>
              <span v-else class="text-zinc-500">—</span>
            </p>
          </div>
        </div>

        <div
          v-for="(value, key) in additionalMetadata"
          :key="`meta-${key}`"
          class="flex items-start justify-between gap-3 border-t border-gray-200 pt-4 text-sm dark:border-zinc-700"
        >
          <div class="min-w-0">
            <p class="text-xs font-medium uppercase tracking-wide text-gray-600 dark:text-zinc-200">
              {{ formatMetadataKey(key) }}
            </p>
            <pre class="mt-1 whitespace-pre-wrap break-words font-mono text-[13px] text-gray-800 dark:text-zinc-200">{{ formatMetadataValue(value) }}</pre>
          </div>
        </div>

        <div class="flex items-start gap-3 pt-4 border-t border-gray-200 dark:border-zinc-700">
          <CopyButton
            :value="helperCommand"
            successMessage="data_read() command copied"
            variant="bare"
            :class="[copyButtonClass, 'w-10']"
            title="Copy data_read() helper"
            :aria-label="`Copy ${helperCommand}`"
          >
            <template #default="{ copied }">
              <svg
                v-if="!copied"
                class="h-4 w-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8z"
                />
              </svg>
              <svg
                v-else
                class="h-4 w-4 text-emerald-500"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                />
              </svg>
            </template>
          </CopyButton>

          <div class="min-w-0 flex-1">
            <p class="text-xs font-medium text-gray-700 dark:text-zinc-100">
              Usage
            </p>
            <p
              class="mt-1 font-mono text-sm leading-relaxed text-gray-900 dark:text-zinc-100 truncate"
              :title="helperCommand"
            >
              {{ helperCommand }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import Button from './ui/Button.vue'
import CopyButton from './ui/CopyButton.vue'
import { ChevronRightIcon } from '@heroicons/vue/24/outline'
import { createDataAnchorId } from '../utils/dataCatalog.js'

defineOptions({ name: 'DataCatalogTree' })

const emit = defineEmits(['edit', 'delete'])

const props = defineProps({
  node: {
    type: Object,
    required: true
  },
  depth: {
    type: Number,
    default: 0
  },
  expandedKeys: {
    type: Object,
    required: true
  },
  autoExpandedKeys: {
    type: Object,
    required: true
  },
  toggleGroup: {
    type: Function,
    required: true
  },
  searchTerm: {
    type: String,
    default: ''
  },
  hierarchical: {
    type: Boolean,
    default: true
  },
  pendingDeletes: {
    type: Object,
    default: null
  }
})

const isGroup = computed(() => props.node?.type === 'group')
const isTopLevel = computed(() => props.depth === 0)

const isExpanded = computed(() => {
  if (!isGroup.value) return false
  if (!props.hierarchical) return true

  const key = props.node?.fullKey
  if (!key) return false

  const expandedSet = props.expandedKeys
  const autoExpandedSet = props.autoExpandedKeys
  const isExpandedManually = typeof expandedSet?.has === 'function' ? expandedSet.has(key) : Boolean(expandedSet?.[key])
  const isExpandedAutomatically = typeof autoExpandedSet?.has === 'function' ? autoExpandedSet.has(key) : Boolean(autoExpandedSet?.[key])

  return isExpandedManually || isExpandedAutomatically
})

const entryLabel = computed(() => {
  const total = props.node?.leafCount || 0
  return `${total} ${total === 1 ? 'entry' : 'entries'}`
})

const groupWrapperClass = computed(() => (
  isTopLevel.value
    ? 'mb-4 rounded-xl border border-gray-200 bg-white p-6 transition hover:border-gray-300 scroll-mt-16 dark:border-gray-700/70 dark:bg-gray-900 dark:hover:border-gray-600'
    : 'mb-3 rounded-lg border border-gray-200 bg-white p-4 transition hover:border-gray-300 dark:border-gray-700/60 dark:bg-gray-900/60 dark:hover:border-gray-600'
))

const titleClass = computed(() => (
  isTopLevel.value
    ? 'text-lg font-semibold text-zinc-900 dark:text-white'
    : 'text-sm font-semibold text-zinc-900 dark:text-white'
))

const childContainerClass = computed(() => (
  isTopLevel.value ? 'mt-4 space-y-3' : 'mt-3 space-y-3'
))

const pendingDeleteSet = computed(() => {
  if (props.pendingDeletes instanceof Set) return props.pendingDeletes
  if (props.pendingDeletes && typeof props.pendingDeletes === 'object' && props.pendingDeletes.value instanceof Set) {
    return props.pendingDeletes.value
  }
  return new Set()
})
const isMarkedForDelete = computed(() => pendingDeleteSet.value.has(props.node?.fullKey))

const additionalMetadata = computed(() => {
  const data = props.node?.data || {}
  const reserved = new Set(['path', 'type', 'description', 'locked', 'delimiter'])
  return Object.keys(data)
    .filter((key) => !reserved.has(key))
    .reduce((acc, key) => {
      acc[key] = data[key]
      return acc
    }, {})
})

const leafWrapperClass = computed(() => {
  const base = 'relative rounded-lg p-6 transition focus-within:ring-2'
  const topLevelClass = isTopLevel.value ? 'scroll-mt-16' : ''

  if (isMarkedForDelete.value) {
    return `${base} border border-red-200 bg-red-50 hover:bg-red-100 focus-within:ring-red-300 ${topLevelClass} dark:border-red-500/40 dark:bg-red-900/30 dark:hover:bg-red-900/40 dark:focus-within:ring-red-500/40`
  }

  return `${base} border border-gray-200 bg-gray-50 hover:bg-gray-100 focus-within:ring-sky-200 ${topLevelClass} dark:border-gray-700/50 dark:bg-gray-800/50 dark:hover:bg-gray-800/60 dark:focus-within:ring-sky-500/40`
})

const copyButtonClass = 'mt-1.5 inline-flex h-10 w-10 items-center justify-center rounded-md border border-gray-200 bg-white text-gray-500 transition hover:border-gray-300 hover:text-gray-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-500 dark:border-gray-600 dark:bg-gray-900 dark:text-gray-300 dark:hover:border-gray-500 dark:hover:text-gray-100'

const deleteButtonClass = computed(() => (
  isMarkedForDelete.value
    ? 'shadow-none border border-red-200 text-red-700 hover:bg-red-50 dark:border-red-500/40 dark:text-red-200 dark:hover:bg-red-900/30'
    : 'shadow-none'
))

const normalizedSearch = computed(() => props.searchTerm.trim().toLowerCase())

const highlightText = (text = '') => {
  const value = text ?? ''
  const term = normalizedSearch.value

  if (!term) {
    return [{ text: value, highlight: false }]
  }

  const lowerValue = value.toLowerCase()
  const parts = []
  let start = 0
  let index = lowerValue.indexOf(term)

  while (index !== -1) {
    if (index > start) {
      parts.push({ text: value.slice(start, index), highlight: false })
    }

    parts.push({ text: value.slice(index, index + term.length), highlight: true })
    start = index + term.length
    index = lowerValue.indexOf(term, start)
  }

  if (start < value.length) {
    parts.push({ text: value.slice(start), highlight: false })
  }

  return parts.length > 0 ? parts : [{ text: value, highlight: false }]
}

const displayName = computed(() => props.node?.displayName || props.node?.name || '')
const nameParts = computed(() => highlightText(displayName.value))
const pathParts = computed(() => highlightText(props.node?.data?.path || ''))
const keyParts = computed(() => highlightText(props.node?.fullKey || ''))

const helperCommand = computed(() => {
  const key = props.node?.fullKey || ''
  return key ? `data_read('${key}')` : 'data_read()'
})

const formatMetadataKey = (key = '') => key.replace(/_/g, ' ')
const formatMetadataValue = (value) => {
  if (value == null) return ''
  if (typeof value === 'object') {
    return JSON.stringify(value, null, 2)
  }
  return String(value)
}

const anchorId = computed(() => {
  if (!isTopLevel.value) return null
  const identifier = props.node?.fullKey || props.node?.name
  if (!identifier) return null
  return createDataAnchorId(identifier)
})

const handleToggle = () => {
  if (!isGroup.value || !props.hierarchical) return
  props.toggleGroup(props.node.fullKey)
}
</script>

<style scoped>
.catalog-collapse-enter-active,
.catalog-collapse-leave-active {
  transition: all 0.18s ease;
}

.catalog-collapse-enter-from,
.catalog-collapse-leave-to {
  max-height: 0;
  opacity: 0;
  transform: translateY(-4px);
}

.catalog-collapse-enter-to,
.catalog-collapse-leave-from {
  max-height: 400px;
  opacity: 1;
  transform: translateY(0);
}
</style>
