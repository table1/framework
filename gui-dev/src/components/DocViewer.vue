<template>
  <div v-if="loading" class="flex items-center justify-center py-12">
    <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
  </div>

  <div v-else-if="doc" class="max-w-4xl prose prose-slate dark:prose-invert">
    <!-- Function header -->
    <div class="not-prose mb-8">
      <div class="flex items-center gap-3 mb-2">
        <span class="px-3 py-1 bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300 rounded text-sm font-medium">
          {{ doc.category }}
        </span>
      </div>
      <h1 class="text-4xl font-bold text-slate-900 dark:text-white mb-4">
        {{ doc.title }}
      </h1>
      <p class="text-lg text-slate-600 dark:text-slate-400">
        {{ doc.description }}
      </p>
    </div>

    <!-- Usage -->
    <div class="not-prose mb-8">
      <h2 class="text-2xl font-bold text-slate-900 dark:text-white mb-4">Usage</h2>
      <div class="bg-slate-900 dark:bg-slate-950 rounded-lg p-4 overflow-x-auto">
        <pre class="text-sm text-slate-100"><code>{{ doc.usage }}</code></pre>
      </div>
    </div>

    <!-- Parameters -->
    <div v-if="doc.params && doc.params.length > 0" class="not-prose mb-8">
      <h2 class="text-2xl font-bold text-slate-900 dark:text-white mb-4">Parameters</h2>
      <div class="space-y-4">
        <div v-for="param in doc.params" :key="param.name" class="border-l-4 border-indigo-500 pl-4">
          <div class="flex items-baseline gap-2 mb-1">
            <code class="text-base font-mono font-semibold text-slate-900 dark:text-white">
              {{ param.name }}
            </code>
            <span class="text-sm text-slate-500 dark:text-slate-400">
              {{ param.type }}
            </span>
            <span v-if="param.required" class="text-xs text-red-600 dark:text-red-400 font-medium">
              required
            </span>
            <span v-if="param.default" class="text-xs text-slate-500 dark:text-slate-400">
              default: <code>{{ param.default }}</code>
            </span>
          </div>
          <p class="text-sm text-slate-600 dark:text-slate-400">
            {{ param.description }}
          </p>
        </div>
      </div>
    </div>

    <!-- Returns -->
    <div class="not-prose mb-8">
      <h2 class="text-2xl font-bold text-slate-900 dark:text-white mb-4">Returns</h2>
      <p class="text-slate-700 dark:text-slate-300">
        {{ doc.returns }}
      </p>
    </div>

    <!-- Details -->
    <div v-if="doc.details" class="not-prose mb-8">
      <h2 class="text-2xl font-bold text-slate-900 dark:text-white mb-4">Details</h2>
      <div class="text-slate-700 dark:text-slate-300 whitespace-pre-line">
        {{ doc.details }}
      </div>
    </div>

    <!-- Examples -->
    <div v-if="doc.examples && doc.examples.length > 0" class="not-prose mb-8">
      <h2 class="text-2xl font-bold text-slate-900 dark:text-white mb-4">Examples</h2>
      <div class="space-y-6">
        <div v-for="(example, index) in doc.examples" :key="index">
          <div class="bg-slate-900 dark:bg-slate-950 rounded-lg p-4 overflow-x-auto mb-2">
            <pre class="text-sm text-slate-100"><code>{{ example.code }}</code></pre>
          </div>
          <p class="text-sm text-slate-600 dark:text-slate-400">
            {{ example.description }}
          </p>
        </div>
      </div>
    </div>

    <!-- See Also -->
    <div v-if="doc.see_also && doc.see_also.length > 0" class="not-prose mb-8">
      <h2 class="text-2xl font-bold text-slate-900 dark:text-white mb-4">See Also</h2>
      <ul class="space-y-2">
        <li v-for="related in doc.see_also" :key="related.name">
          <code class="text-indigo-600 dark:text-indigo-400 font-mono font-semibold">
            {{ related.name }}()
          </code>
          <span class="text-slate-700 dark:text-slate-300"> - {{ related.description }}</span>
        </li>
      </ul>
    </div>

    <!-- Notes -->
    <div v-if="doc.notes && doc.notes.length > 0" class="not-prose mb-8">
      <div class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-4">
        <h3 class="text-lg font-semibold text-amber-900 dark:text-amber-200 mb-2">Notes</h3>
        <ul class="list-disc list-inside space-y-1 text-sm text-amber-800 dark:text-amber-300">
          <li v-for="(note, index) in doc.notes" :key="index">
            {{ note }}
          </li>
        </ul>
      </div>
    </div>

    <!-- Tags -->
    <div v-if="doc.tags && doc.tags.length > 0" class="not-prose">
      <div class="flex items-center gap-2 flex-wrap">
        <span class="text-sm text-slate-500 dark:text-slate-400">Tags:</span>
        <span
          v-for="tag in doc.tags"
          :key="tag"
          class="px-2 py-1 bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 rounded text-xs"
        >
          {{ tag }}
        </span>
      </div>
    </div>
  </div>

  <div v-else class="text-center py-12">
    <p class="text-slate-600 dark:text-slate-400">Documentation not found.</p>
  </div>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue'

const props = defineProps({
  functionName: {
    type: String,
    required: true
  }
})

const doc = ref(null)
const loading = ref(true)

const loadDoc = async () => {
  loading.value = true
  try {
    const response = await fetch(`/docs/${props.functionName}.json`)
    if (response.ok) {
      doc.value = await response.json()
    } else {
      doc.value = null
    }
  } catch (error) {
    console.error('Failed to load documentation:', error)
    doc.value = null
  } finally {
    loading.value = false
  }
}

watch(() => props.functionName, loadDoc)
onMounted(loadDoc)
</script>
