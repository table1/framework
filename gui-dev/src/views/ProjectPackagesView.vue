<template>
  <div class="mx-auto max-w-5xl p-10">
    <PageHeader
      title="Packages"
      description="Manage R packages for this project."
    />

    <div class="mt-10 rounded-2xl border border-zinc-200 bg-white p-8 shadow-sm dark:border-zinc-800 dark:bg-zinc-900">
      <div class="flex items-center gap-3 border-b border-zinc-100 pb-6 dark:border-zinc-800">
        <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-sky-500 to-sky-600 shadow-lg shadow-sky-500/20">
          <svg class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
          </svg>
        </div>
        <h3 class="text-xl font-bold text-zinc-900 dark:text-white">Package Configuration</h3>
      </div>

      <div class="mt-8">
        <p class="text-sm text-zinc-600 dark:text-zinc-400">
          Package management interface coming soon. This page will allow you to:
        </p>
        <ul class="mt-4 space-y-2 text-sm text-zinc-600 dark:text-zinc-400">
          <li class="flex items-center gap-2">
            <svg class="h-4 w-4 text-sky-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            Add and remove project packages
          </li>
          <li class="flex items-center gap-2">
            <svg class="h-4 w-4 text-sky-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            Specify package versions
          </li>
          <li class="flex items-center gap-2">
            <svg class="h-4 w-4 text-sky-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            Toggle renv integration
          </li>
          <li class="flex items-center gap-2">
            <svg class="h-4 w-4 text-sky-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            Install and update packages
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import PageHeader from '../components/ui/PageHeader.vue'

const packages = ref([])

onMounted(async () => {
  // TODO: Load packages from project config
})
</script>
