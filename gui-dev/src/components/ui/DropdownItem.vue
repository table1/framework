<template>
  <component
    :is="href ? 'a' : 'button'"
    :href="href"
    :type="href ? undefined : 'button'"
    :class="itemClasses"
    @click="handleClick"
    role="menuitem"
  >
    <svg
      v-if="icon"
      viewBox="0 0 20 20"
      fill="currentColor"
      class="size-5 text-gray-400 dark:text-gray-500"
    >
      <component :is="icon" />
    </svg>
    <slot />
  </component>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  href: {
    type: String,
    default: null
  },
  icon: {
    type: [Object, Function],
    default: null
  },
  variant: {
    type: String,
    default: 'default',
    validator: (value) => ['default', 'danger'].includes(value)
  },
  disabled: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['click'])

const itemClasses = computed(() => {
  const classes = [
    'flex',
    'items-center',
    'gap-2',
    'w-full',
    'px-4',
    'py-2',
    'text-sm',
    'text-left',
    'transition-colors'
  ]

  if (props.disabled) {
    classes.push(
      'opacity-50',
      'cursor-not-allowed'
    )
  } else {
    if (props.variant === 'danger') {
      classes.push(
        'text-red-700',
        'hover:bg-red-50',
        'hover:text-red-900',
        'focus:bg-red-50',
        'focus:text-red-900',
        'focus:outline-hidden',
        'dark:text-red-400',
        'dark:hover:bg-red-500/10',
        'dark:hover:text-red-300',
        'dark:focus:bg-red-500/10',
        'dark:focus:text-red-300'
      )
    } else {
      classes.push(
        'text-gray-700',
        'hover:bg-gray-100',
        'hover:text-gray-900',
        'focus:bg-gray-100',
        'focus:text-gray-900',
        'focus:outline-hidden',
        'dark:text-gray-300',
        'dark:hover:bg-white/5',
        'dark:hover:text-white',
        'dark:focus:bg-white/5',
        'dark:focus:text-white'
      )
    }
  }

  return classes.join(' ')
})

const handleClick = (event) => {
  if (!props.disabled) {
    emit('click', event)
  } else {
    event.preventDefault()
  }
}
</script>
