<template>
  <div class="flex h-full">
    <!-- Function List Sidebar -->
    <div class="w-64 flex-shrink-0 border-r border-zinc-900/10 dark:border-white/10 overflow-y-auto">
      <div class="p-4">
        <h2 class="text-xs font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
          Core Functions
        </h2>
        <ul class="mt-3 space-y-1">
          <li v-for="func in coreFunctions" :key="func.name">
            <router-link
              :to="`/docs/${func.name}`"
              class="block rounded-md px-3 py-2 text-sm font-medium hover:bg-zinc-50 dark:hover:bg-zinc-800"
              :class="functionName === func.name
                ? 'bg-sky-50 text-sky-600 dark:bg-sky-400/10 dark:text-sky-400'
                : 'text-zinc-700 dark:text-zinc-300'"
            >
              {{ func.title }}
            </router-link>
          </li>
        </ul>

        <h2 class="mt-6 text-xs font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
          Data Functions
        </h2>
        <ul class="mt-3 space-y-1">
          <li v-for="func in dataFunctions" :key="func.name">
            <router-link
              :to="`/docs/${func.name}`"
              class="block rounded-md px-3 py-2 text-sm font-medium hover:bg-zinc-50 dark:hover:bg-zinc-800"
              :class="functionName === func.name
                ? 'bg-sky-50 text-sky-600 dark:bg-sky-400/10 dark:text-sky-400'
                : 'text-zinc-700 dark:text-zinc-300'"
            >
              {{ func.title }}
            </router-link>
          </li>
        </ul>

        <h2 class="mt-6 text-xs font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
          Cache Functions
        </h2>
        <ul class="mt-3 space-y-1">
          <li v-for="func in cacheFunctions" :key="func.name">
            <router-link
              :to="`/docs/${func.name}`"
              class="block rounded-md px-3 py-2 text-sm font-medium hover:bg-zinc-50 dark:hover:bg-zinc-800"
              :class="functionName === func.name
                ? 'bg-sky-50 text-sky-600 dark:bg-sky-400/10 dark:text-sky-400'
                : 'text-zinc-700 dark:text-zinc-300'"
            >
              {{ func.title }}
            </router-link>
          </li>
        </ul>
      </div>
    </div>

    <!-- Documentation Content -->
    <div class="flex-1 overflow-y-auto">
      <DocViewer v-if="functionName" :functionName="functionName" />
      <div v-else class="flex h-full items-center justify-center p-8">
        <div class="text-center">
          <h2 class="text-2xl font-bold text-zinc-900 dark:text-white">Framework Documentation</h2>
          <p class="mt-2 text-zinc-600 dark:text-zinc-400">
            Select a function from the sidebar to view its documentation.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import DocViewer from '../components/DocViewer.vue'

const route = useRoute()
const functionName = computed(() => route.params.functionName)

const coreFunctions = [
  { name: 'scaffold', title: 'scaffold()' }
]

const dataFunctions = [
  { name: 'data_load', title: 'data_load()' }
]

const cacheFunctions = [
  { name: 'cache_get', title: 'cache_get()' }
]
</script>
