<template>
  <div class="space-y-3">
    <div v-if="title || description" class="space-y-1">
      <h3 v-if="title" class="text-sm font-semibold text-gray-900 dark:text-white">{{ title }}</h3>
      <p v-if="description" class="text-xs text-gray-600 dark:text-gray-400">{{ description }}</p>
    </div>
    <div class="space-y-3">
      <slot />
    </div>
  </div>
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
