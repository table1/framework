<template>
  <section
    :class="[
      'space-y-6',
      flush ? '' : 'rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50'
    ]"
  >
    <header v-if="title || description" class="space-y-2">
      <h2 v-if="title" class="text-lg font-semibold text-gray-900 dark:text-white">{{ title }}</h2>
      <p v-if="description" class="text-sm text-gray-600 dark:text-gray-400">{{ description }}</p>
    </header>

    <div class="space-y-6">
      <slot />
    </div>

    <div
      v-if="$slots.actions"
      :class="[
        'flex justify-end',
        flush ? '' : 'pt-4 border-t border-gray-200 dark:border-gray-700'
      ]"
    >
      <slot name="actions" />
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
  },
  flush: {
    type: Boolean,
    default: false
  }
})
</script>
