<template>
  <div class="flex min-h-screen">
    <!-- Middle Sidebar - Function List -->
    <nav class="w-64 shrink-0 border-r border-gray-200 p-6 dark:border-gray-800 overflow-y-auto">
      <h2 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">{{ category?.name || 'Documentation' }}</h2>
      <p v-if="category?.description" class="text-xs text-gray-500 dark:text-gray-400 mb-4">
        {{ category.description }}
      </p>

      <!-- Search within category -->
      <div class="relative mb-4">
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Filter..."
          class="w-full rounded-md border border-gray-300 bg-white px-3 py-1.5 pl-8 text-sm placeholder-gray-400 focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white dark:placeholder-gray-500"
        />
        <svg class="absolute left-2.5 top-2 h-4 w-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      </div>

      <!-- Loading -->
      <div v-if="loading" class="flex items-center justify-center py-8">
        <svg class="h-6 w-6 animate-spin text-sky-600" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
      </div>

      <!-- Function List -->
      <div v-else class="space-y-4">
        <!-- Common Functions -->
        <div v-if="commonFunctions.length > 0">
          <h3 class="px-3 text-xs font-semibold text-gray-500 uppercase tracking-wider dark:text-gray-400 pb-2">Common</h3>
          <div class="space-y-0.5">
            <a
              v-for="func in commonFunctions"
              :key="func.id"
              href="#"
              @click.prevent="selectFunction(func.name)"
              class="group relative"
            >
              <span
                :class="[
                  'block rounded-md px-3 py-2 text-sm transition truncate',
                  selectedFunction === func.name
                    ? 'bg-sky-50 text-sky-700 font-medium dark:bg-sky-900/20 dark:text-sky-400'
                    : 'text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-800'
                ]"
              >
                <span class="font-mono text-xs">{{ func.name }}()</span>
              </span>
            </a>
          </div>
        </div>

        <!-- Other Functions -->
        <div v-if="otherFunctions.length > 0">
          <h3 v-if="commonFunctions.length > 0" class="px-3 text-xs font-semibold text-gray-500 uppercase tracking-wider dark:text-gray-400 pt-4 pb-2">Other</h3>
          <div class="space-y-0.5">
            <a
              v-for="func in otherFunctions"
              :key="func.id"
              href="#"
              @click.prevent="selectFunction(func.name)"
              class="group relative"
            >
              <span
                :class="[
                  'block rounded-md px-3 py-2 text-sm transition truncate',
                  selectedFunction === func.name
                    ? 'bg-sky-50 text-sky-700 font-medium dark:bg-sky-900/20 dark:text-sky-400'
                    : 'text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-800'
                ]"
              >
                <span class="font-mono text-xs">{{ func.name }}()</span>
              </span>
            </a>
          </div>
        </div>

        <!-- Empty state -->
        <div v-if="filteredFunctions.length === 0 && searchQuery" class="text-center py-4">
          <p class="text-sm text-gray-500 dark:text-gray-400">No matches</p>
        </div>
      </div>
    </nav>

    <!-- Main Content - Function Documentation -->
    <div class="flex-1 pt-10 pb-8 px-10 overflow-y-auto border-l border-gray-100 bg-gray-50/30 dark:border-gray-800 dark:bg-gray-900/20">
      <!-- Loading doc -->
      <div v-if="loadingDoc" class="flex items-center justify-center py-12">
        <svg class="h-8 w-8 animate-spin text-sky-600" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
      </div>

      <!-- No function selected -->
      <div v-else-if="!selectedFunction && !loadingDoc" class="flex h-full items-center justify-center">
        <div class="text-center max-w-md">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
          </svg>
          <h3 class="mt-4 text-lg font-medium text-gray-900 dark:text-white">Select a function</h3>
          <p class="mt-2 text-sm text-gray-600 dark:text-gray-400">
            Choose a function from the list to view its documentation.
          </p>
        </div>
      </div>

      <!-- Function Documentation -->
      <div v-else-if="doc" class="max-w-3xl text-[15px] leading-relaxed">
        <!-- Function header -->
        <header class="mb-8">
          <!-- Eyebrow: Category + source row -->
          <div class="flex items-center justify-between text-sm tracking-wide text-gray-400 dark:text-gray-500 mb-2">
            <span>Function · {{ category?.name || 'Documentation' }}</span>
            <span v-if="doc.source_file" class="font-mono">{{ doc.source_file }}</span>
          </div>
          <h1 class="text-2xl font-semibold text-gray-900 dark:text-white font-mono leading-tight mb-3">{{ doc.name }}()</h1>
          <p v-if="doc.title" class="text-base text-gray-600 dark:text-gray-400 leading-relaxed">{{ doc.title }}</p>
        </header>

        <!-- Description -->
        <section v-if="doc.description" class="mb-5">
          <h2 class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1.5">Description</h2>
          <MarkdownText :content="doc.description" class="text-[15px] text-gray-700 dark:text-gray-300 leading-relaxed" />
        </section>

        <!-- Usage -->
        <section v-if="doc.usage" class="mb-5" :key="'usage-' + highlighterReady">
          <h2 class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1.5">Usage</h2>
          <div class="relative group">
            <div class="code-block rounded overflow-x-auto border border-gray-200 dark:border-gray-700" v-html="highlightCode(doc.usage)"></div>
            <CopyButton
              :value="doc.usage"
              variant="ghost"
              class="absolute top-1.5 right-1.5 opacity-0 group-hover:opacity-100 transition-opacity text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
            />
          </div>
        </section>

        <!-- Parameters as table -->
        <section v-if="doc.parameters && doc.parameters.length > 0" class="mb-5">
          <h2 class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1.5">Arguments</h2>
          <div class="overflow-hidden rounded border border-gray-200 dark:border-gray-700">
            <table class="w-full">
              <thead class="bg-gray-50 dark:bg-gray-800/50 text-xs text-gray-500 dark:text-gray-400">
                <tr>
                  <th class="text-left px-3 py-1.5 font-medium w-28">Argument</th>
                  <th class="text-left px-3 py-1.5 font-medium">Description</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
                <tr v-for="param in doc.parameters" :key="param.name" class="bg-white dark:bg-gray-900">
                  <td class="px-3 py-2 align-top">
                    <code class="text-sm font-mono font-medium text-gray-900 dark:text-white">{{ param.name }}</code>
                  </td>
                  <td class="px-3 py-2 text-[15px] text-gray-600 dark:text-gray-400">
                    <MarkdownText v-if="param.description" :content="param.description" />
                    <span v-else>—</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <!-- Details -->
        <section v-if="doc.details" class="mb-5">
          <h2 class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1.5">Details</h2>
          <MarkdownText :content="doc.details" class="text-[15px] text-gray-700 dark:text-gray-300 leading-relaxed" />
        </section>

        <!-- Value (Return) -->
        <section v-if="doc.value" class="mb-5">
          <h2 class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1.5">Returns</h2>
          <MarkdownText :content="doc.value" class="text-[15px] text-gray-700 dark:text-gray-300 leading-relaxed" />
        </section>

        <!-- Sections -->
        <template v-if="doc.sections && doc.sections.length > 0">
          <section v-for="section in doc.sections" :key="section.id" class="mb-5">
            <h2 class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1.5">{{ section.title }}</h2>
            <MarkdownText :content="section.content" class="text-[15px] text-gray-700 dark:text-gray-300 leading-relaxed" />
            <div v-if="section.subsections && section.subsections.length > 0" class="mt-2 pl-3 border-l-2 border-gray-200 dark:border-gray-700">
              <div v-for="subsection in section.subsections" :key="subsection.title" class="mb-2 last:mb-0">
                <h3 class="text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">{{ subsection.title }}</h3>
                <MarkdownText :content="subsection.content" class="text-sm text-gray-600 dark:text-gray-400 leading-relaxed" />
              </div>
            </div>
          </section>
        </template>

        <!-- Examples -->
        <section v-if="doc.examples && doc.examples.length > 0" class="mb-5" :key="'examples-' + highlighterReady">
          <h2 class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1.5">Examples</h2>
          <div class="space-y-2">
            <div v-for="(example, index) in doc.examples" :key="index" class="relative group">
              <div class="code-block rounded overflow-x-auto border border-gray-200 dark:border-gray-700" v-html="highlightCode(formatExample(example.content))"></div>
              <CopyButton
                :value="example.content"
                variant="ghost"
                class="absolute top-1.5 right-1.5 opacity-0 group-hover:opacity-100 transition-opacity text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
              />
            </div>
          </div>
        </section>

        <!-- See Also -->
        <section v-if="doc.seealso && doc.seealso.length > 0" class="mb-5">
          <h2 class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1.5">See also</h2>
          <div class="flex flex-wrap gap-1.5">
            <a
              v-for="related in doc.seealso"
              :key="related.target"
              href="#"
              @click.prevent="selectFunction(related.target)"
              class="inline-flex items-center px-2 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-sky-600 dark:text-sky-400 font-mono text-sm hover:bg-gray-200 dark:hover:bg-gray-700 transition"
            >{{ related.link_text || related.target }}</a>
          </div>
        </section>

        <!-- Aliases -->
        <section v-if="doc.aliases && doc.aliases.length > 0" class="mb-5">
          <h2 class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1.5">Aliases</h2>
          <div class="flex flex-wrap gap-1.5">
            <span
              v-for="alias in doc.aliases"
              :key="alias"
              class="inline-flex items-center px-2 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 font-mono text-sm"
            >{{ alias }}()</span>
          </div>
        </section>

        <!-- Note -->
        <section v-if="doc.note" class="mb-5">
          <div class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded px-3 py-2">
            <h3 class="text-xs font-medium text-amber-600 dark:text-amber-400 mb-1">Note</h3>
            <MarkdownText :content="doc.note" class="text-[15px] text-amber-700 dark:text-amber-300 leading-relaxed" />
          </div>
        </section>
      </div>

      <!-- Function not found -->
      <div v-else-if="selectedFunction && !doc && !loadingDoc" class="text-center py-12">
        <p class="text-gray-600 dark:text-gray-400">
          Documentation for <code class="font-mono">{{ selectedFunction }}</code> not found.
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import CopyButton from '@/components/ui/CopyButton.vue'
import MarkdownText from '@/components/ui/MarkdownText.vue'
import { useHighlighter } from '@/composables/useHighlighter'

const props = defineProps({
  categoryId: {
    type: String,
    required: true
  }
})

const route = useRoute()
const router = useRouter()
const { initHighlighter, highlight, isReady: highlighterReady } = useHighlighter()

const loading = ref(true)
const loadingDoc = ref(false)
const category = ref(null)
const functions = ref([])
const searchQuery = ref('')
const selectedFunction = ref(null)
const doc = ref(null)

const filteredFunctions = computed(() => {
  let funcs = functions.value
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase()
    funcs = funcs.filter(func =>
      func.name.toLowerCase().includes(query) ||
      (func.title && func.title.toLowerCase().includes(query))
    )
  }
  return funcs
})

// Split functions into common and other
const commonFunctions = computed(() => {
  return filteredFunctions.value.filter(func => func.is_common === 1)
})

const otherFunctions = computed(() => {
  return filteredFunctions.value.filter(func => func.is_common !== 1)
})

const loadCategory = async () => {
  loading.value = true

  try {
    // Load category info
    const categoriesResponse = await fetch('/api/docs/categories')
    const categoriesData = await categoriesResponse.json()

    if (!categoriesData.error) {
      category.value = categoriesData.categories?.find(c => c.id === parseInt(props.categoryId))
    }

    // Load functions in this category
    const functionsResponse = await fetch(`/api/docs/functions?category_id=${props.categoryId}`)
    const functionsData = await functionsResponse.json()

    if (!functionsData.error) {
      functions.value = functionsData.functions || []

      // Auto-select first function if none selected and we have functions
      if (!selectedFunction.value && functions.value.length > 0) {
        // Check if there's a function in the URL query
        if (route.query.fn) {
          selectFunction(route.query.fn)
        } else {
          selectFunction(functions.value[0].name)
        }
      }
    }
  } catch (err) {
    console.error('Failed to load category:', err)
  } finally {
    loading.value = false
  }
}

const selectFunction = async (functionName) => {
  selectedFunction.value = functionName
  loadingDoc.value = true
  doc.value = null

  // Update URL without full navigation
  router.replace({
    path: route.path,
    query: { fn: functionName }
  })

  try {
    const response = await fetch(`/api/docs/function/${encodeURIComponent(functionName)}`)
    const data = await response.json()

    if (!data.error) {
      doc.value = data.function_doc
    }
  } catch (err) {
    console.error('Failed to load function:', err)
  } finally {
    loadingDoc.value = false
  }
}

// Watch for category changes
watch(() => props.categoryId, () => {
  selectedFunction.value = null
  doc.value = null
  searchQuery.value = ''
  loadCategory()
})

// Watch for URL query changes (e.g., from see also links)
watch(() => route.query.fn, (newFn) => {
  if (newFn && newFn !== selectedFunction.value) {
    selectFunction(newFn)
  }
})

// Format example code - add blank line before comments for readability
const formatExample = (code) => {
  if (!code) return ''
  const lines = code.split('\n')
  const result = []

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]
    const trimmed = line.trim()
    const prevLine = i > 0 ? lines[i - 1].trim() : ''

    // Add blank line before comment if previous line wasn't blank or a comment
    if (trimmed.startsWith('#') && prevLine && !prevLine.startsWith('#')) {
      result.push('')
    }
    result.push(line)
  }

  return result.join('\n')
}

// Syntax highlight R code
const highlightCode = (code) => {
  const result = highlight(code, 'r')
  console.log('highlightCode input:', code?.substring(0, 50), 'output length:', result?.length)
  return result
}

onMounted(async () => {
  await initHighlighter()
  loadCategory()
})
</script>

<style scoped>
/* Shiki code block styling */
.code-block :deep(pre) {
  margin: 0;
  padding: 0.75rem 1rem;
  font-size: 0.875rem;
  line-height: 1.7;
  overflow-x: auto;
}

.code-block :deep(code) {
  font-family: ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Monaco, Consolas, monospace;
}

/* Light theme styles */
.code-block :deep(.shiki),
.code-block :deep(.shiki span) {
  background-color: transparent !important;
}

.code-block {
  background-color: #f9fafb;
}

/* Dark theme styles */
:root.dark .code-block {
  background-color: rgba(31, 41, 55, 0.5);
}

:root.dark .code-block :deep(.shiki.github-light) {
  display: none;
}

:root:not(.dark) .code-block :deep(.shiki.github-dark) {
  display: none;
}
</style>
