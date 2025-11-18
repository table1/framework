<template>
  <div class="flex items-center gap-2 text-xs text-zinc-600 dark:text-zinc-400">
    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
    </svg>
    <span>{{ author.author }}</span>
    <template v-if="author.author_email">
      <span class="text-zinc-400 dark:text-zinc-500">·</span>
      <span class="truncate">{{ author.author_email }}</span>
    </template>
  </div>
</template>

<script setup>
defineProps({
  author: {
    type: Object,
    required: true
  }
})
</script>
