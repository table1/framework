<template>
  <span :class="badgeClasses">
    <svg
      v-if="dot"
      viewBox="0 0 6 6"
      aria-hidden="true"
      :class="dotClasses"
    >
      <circle r="3" cx="3" cy="3" />
    </svg>
    <slot />
  </span>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  variant: {
    type: String,
    default: 'gray',
    validator: (value) => ['gray', 'red', 'yellow', 'green', 'blue', 'indigo', 'purple', 'pink', 'emerald'].includes(value)
  },
  pill: {
    type: Boolean,
    default: false
  },
  dot: {
    type: Boolean,
    default: false
  }
})

const badgeClasses = computed(() => {
  const classes = [
    'inline-flex',
    'items-center',
    'px-2',
    'py-1',
    'text-xs',
    'font-medium',
    'inset-ring'
  ]

  // Rounded
  classes.push(props.pill ? 'rounded-full' : 'rounded-md')

  // Gap for dot
  if (props.dot) {
    classes.push('gap-x-1.5')
  }

  // Color variants
  const variantMap = {
    gray: {
      bg: 'bg-gray-50',
      text: 'text-gray-600',
      ring: 'inset-ring-gray-500/10',
      darkBg: 'dark:bg-gray-400/10',
      darkText: props.dot ? 'dark:text-gray-200' : 'dark:text-gray-400',
      darkRing: props.dot ? 'dark:inset-ring-white/10' : 'dark:inset-ring-gray-400/20'
    },
    red: {
      bg: 'bg-red-50',
      text: 'text-red-700',
      ring: 'inset-ring-red-600/10',
      darkBg: 'dark:bg-red-400/10',
      darkText: 'dark:text-red-400',
      darkRing: 'dark:inset-ring-red-400/20'
    },
    yellow: {
      bg: 'bg-yellow-50',
      text: 'text-yellow-800',
      ring: 'inset-ring-yellow-600/20',
      darkBg: 'dark:bg-yellow-400/10',
      darkText: 'dark:text-yellow-500',
      darkRing: 'dark:inset-ring-yellow-400/20'
    },
    green: {
      bg: 'bg-green-50',
      text: 'text-green-700',
      ring: 'inset-ring-green-600/20',
      darkBg: 'dark:bg-green-400/10',
      darkText: 'dark:text-green-400',
      darkRing: 'dark:inset-ring-green-500/20'
    },
    emerald: {
      bg: 'bg-sky-50',
      text: 'text-sky-700',
      ring: 'inset-ring-sky-600/20',
      darkBg: 'dark:bg-sky-400/10',
      darkText: 'dark:text-sky-400',
      darkRing: 'dark:inset-ring-sky-500/20'
    },
    blue: {
      bg: 'bg-blue-50',
      text: 'text-blue-700',
      ring: 'inset-ring-blue-700/10',
      darkBg: 'dark:bg-blue-400/10',
      darkText: 'dark:text-blue-400',
      darkRing: 'dark:inset-ring-blue-400/30'
    },
    indigo: {
      bg: 'bg-indigo-50',
      text: 'text-indigo-700',
      ring: 'inset-ring-indigo-700/10',
      darkBg: 'dark:bg-indigo-400/10',
      darkText: 'dark:text-indigo-400',
      darkRing: 'dark:inset-ring-indigo-400/30'
    },
    purple: {
      bg: 'bg-purple-50',
      text: 'text-purple-700',
      ring: 'inset-ring-purple-700/10',
      darkBg: 'dark:bg-purple-400/10',
      darkText: 'dark:text-purple-400',
      darkRing: 'dark:inset-ring-purple-400/30'
    },
    pink: {
      bg: 'bg-pink-50',
      text: 'text-pink-700',
      ring: 'inset-ring-pink-700/10',
      darkBg: 'dark:bg-pink-400/10',
      darkText: 'dark:text-pink-400',
      darkRing: 'dark:inset-ring-pink-400/20'
    }
  }

  const variant = variantMap[props.variant]

  // For dot variant, use neutral colors with colored dot
  if (props.dot) {
    classes.push(
      'text-gray-900',
      'inset-ring-gray-200',
      'dark:text-white',
      'dark:inset-ring-white/10'
    )
  } else {
    classes.push(
      variant.bg,
      variant.text,
      variant.ring,
      variant.darkBg,
      variant.darkText,
      variant.darkRing
    )
  }

  return classes.join(' ')
})

const dotClasses = computed(() => {
  const fillMap = {
    gray: 'fill-gray-500 dark:fill-gray-400',
    red: 'fill-red-500 dark:fill-red-400',
    yellow: 'fill-yellow-500 dark:fill-yellow-400',
    green: 'fill-green-500 dark:fill-green-400',
    emerald: 'fill-sky-500 dark:fill-sky-400',
    blue: 'fill-blue-500 dark:fill-blue-400',
    indigo: 'fill-indigo-500 dark:fill-indigo-400',
    purple: 'fill-purple-500 dark:fill-purple-400',
    pink: 'fill-pink-500 dark:fill-pink-400'
  }

  return `size-1.5 ${fillMap[props.variant]}`
})
</script>
