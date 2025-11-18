<template>
  <div class="flex flex-col gap-3 rounded-2xl border border-zinc-200 bg-white p-5 shadow-sm dark:border-zinc-800 dark:bg-zinc-900 sm:flex-row sm:items-center sm:justify-between">
    <div class="min-w-0">
      <p class="text-sm font-medium text-zinc-700 dark:text-zinc-200">{{ label }}</p>
      <p class="mt-1 font-mono text-sm text-zinc-600 dark:text-zinc-400 truncate">{{ value }}</p>
    </div>
    <div class="flex items-center gap-2">
      <CopyButton
        v-if="copyable"
        :value="value"
        variant="ghost"
        show-label
        :success-message="copyMessage"
      />
      <slot name="actions"></slot>
    </div>
  </div>
</template>

<script setup>
import CopyButton from './CopyButton.vue'

defineProps({
  label: {
    type: String,
    required: true
  },
  value: {
    type: String,
    required: true
  },
  copyable: {
    type: Boolean,
    default: false
  },
  copyMessage: {
    type: String,
    default: 'Copied!'
  }
})
</script>
