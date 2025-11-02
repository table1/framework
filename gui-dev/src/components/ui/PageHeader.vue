<template>
  <div class="flex items-start justify-between">
    <div>
      <h1 class="text-3xl font-bold tracking-tight text-gray-900 dark:text-white">
        {{ title }}
      </h1>
      <p v-if="description" class="mt-2 text-sm text-gray-600 dark:text-gray-400">
        {{ description }}
      </p>
    </div>
    <div v-if="$slots.actions">
      <slot name="actions" />
    </div>
  </div>
</template>

<script setup>
defineProps({
  title: {
    type: String,
    required: true
  },
  description: {
    type: String,
    default: null
  }
})
</script>
