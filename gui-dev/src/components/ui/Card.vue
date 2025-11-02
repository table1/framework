<template>
  <div :class="cardClasses">
    <div v-if="$slots.header" class="px-4 py-5 sm:px-6">
      <slot name="header" />
    </div>
    <div class="px-4 py-5 sm:p-6">
      <slot />
    </div>
    <div v-if="$slots.footer" class="px-4 py-4 sm:px-6">
      <slot name="footer" />
    </div>
  </div>
</template>

<script setup>
import { computed, useSlots } from 'vue'

const slots = useSlots()

const cardClasses = computed(() => {
  const classes = [
    'overflow-hidden',
    'rounded-lg',
    'bg-white',
    'shadow-sm',
    'dark:bg-gray-800/50',
    'dark:shadow-none',
    'dark:outline',
    'dark:-outline-offset-1',
    'dark:outline-white/10'
  ]

  // Add dividers if we have header or footer
  if (slots.header || slots.footer) {
    classes.push('divide-y', 'divide-gray-200', 'dark:divide-white/10')
  }

  return classes.join(' ')
})
</script>
