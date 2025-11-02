<template>
  <div class="mx-auto max-w-5xl p-10">
    <PageHeader
      title="Connections"
      description="Manage database connections for this project."
    />

    <div class="mt-10 rounded-2xl border border-zinc-200 bg-white p-8 shadow-sm dark:border-zinc-800 dark:bg-zinc-900">
      <div class="flex items-center gap-3 border-b border-zinc-100 pb-6 dark:border-zinc-800">
        <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-sky-500 to-sky-600 shadow-lg shadow-sky-500/20">
          <svg class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
        </div>
        <h3 class="text-xl font-bold text-zinc-900 dark:text-white">Database Connections</h3>
      </div>

      <div class="mt-8">
        <p class="text-sm text-zinc-600 dark:text-zinc-400">
          Connection management interface coming soon. This page will allow you to:
        </p>
        <ul class="mt-4 space-y-2 text-sm text-zinc-600 dark:text-zinc-400">
          <li class="flex items-center gap-2">
            <svg class="h-4 w-4 text-sky-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            Configure database connections (SQLite, PostgreSQL)
          </li>
          <li class="flex items-center gap-2">
            <svg class="h-4 w-4 text-sky-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            Store connection credentials securely
          </li>
          <li class="flex items-center gap-2">
            <svg class="h-4 w-4 text-sky-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            Test database connectivity
          </li>
          <li class="flex items-center gap-2">
            <svg class="h-4 w-4 text-sky-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            Manage connection pooling settings
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import PageHeader from '../components/ui/PageHeader.vue'

const connections = ref([])

onMounted(async () => {
  // TODO: Load connections from project config
})
</script>
