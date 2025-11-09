<template>
  <section class="rounded-lg bg-gray-50 p-6 space-y-6 dark:bg-gray-800/50">
    <header v-if="title || description" class="space-y-2">
      <h2 v-if="title" class="text-lg font-semibold text-gray-900 dark:text-white">{{ title }}</h2>
      <p v-if="description" class="text-sm text-gray-600 dark:text-gray-400">{{ description }}</p>
    </header>

    <div class="space-y-6">
      <slot />
    </div>
  </section>
</template>

<script setup>
defineProps({
  title: {
    type: String,
    default: ''
  },
  description: {
    type: String,
    default: ''
  }
})
</script>
