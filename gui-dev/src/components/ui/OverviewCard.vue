<template>
  <button
    @click="$emit('click')"
    class="w-full text-left px-4 py-3 rounded-md bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-700 hover:border-sky-300 dark:hover:border-sky-700 transition"
  >
    <div class="flex items-center justify-between">
      <div class="flex-1">
        <div class="text-xs text-gray-500 dark:text-gray-400 mb-1">{{ title }}</div>
        <div class="text-sm text-gray-900 dark:text-white">
          <slot />
        </div>
      </div>
      <svg class="h-5 w-5 text-gray-400 shrink-0 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
      </svg>
    </div>
  </button>
</template>

<script setup>
defineProps({
  title: {
    type: String,
    required: true
  }
})

defineEmits(['click'])
</script>
