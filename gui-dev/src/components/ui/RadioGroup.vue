<template>
  <fieldset>
    <legend class="text-sm/6 font-semibold text-gray-900 dark:text-white">{{ legend }}</legend>
    <p v-if="description" class="mt-1 text-sm/6 text-gray-600 dark:text-gray-400">{{ description }}</p>
    <div class="mt-6 space-y-6">
      <slot />
    </div>
  </fieldset>
</template>

<script setup>
defineProps({
  legend: {
    type: String,
    required: true
  },
  description: {
    type: String,
    default: null
  }
})
</script>
