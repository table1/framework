<template>
  <component
    :is="href ? 'a' : 'button'"
    :href="href"
    :type="href ? undefined : type"
    :class="buttonClasses"
    @click="handleClick"
  >
    <svg
      v-if="icon && iconPosition === 'left'"
      viewBox="0 0 20 20"
      fill="currentColor"
      data-slot="icon"
      aria-hidden="true"
      :class="iconClasses"
    >
      <component :is="icon" />
    </svg>

    <slot />

    <svg
      v-if="icon && iconPosition === 'right'"
      viewBox="0 0 20 20"
      fill="currentColor"
      data-slot="icon"
      aria-hidden="true"
      :class="iconClasses"
    >
      <component :is="icon" />
    </svg>
  </component>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  variant: {
    type: String,
    default: 'primary',
    validator: (value) => ['primary', 'secondary', 'soft'].includes(value)
  },
  size: {
    type: String,
    default: 'md',
    validator: (value) => ['xs', 'sm', 'md', 'lg', 'xl'].includes(value)
  },
  rounded: {
    type: String,
    default: 'md',
    validator: (value) => ['sm', 'md', 'full'].includes(value)
  },
  type: {
    type: String,
    default: 'button'
  },
  href: {
    type: String,
    default: null
  },
  icon: {
    type: [Object, Function],
    default: null
  },
  iconPosition: {
    type: String,
    default: 'left',
    validator: (value) => ['left', 'right'].includes(value)
  },
  iconOnly: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['click'])

const handleClick = (event) => {
  emit('click', event)
}

const buttonClasses = computed(() => {
  const classes = ['font-semibold', 'focus-visible:outline-2', 'focus-visible:outline-offset-2']

  // Size classes
  const sizeMap = {
    xs: props.iconOnly ? 'p-2' : 'px-3 py-2 text-xs',
    sm: props.iconOnly ? 'p-2.5' : 'px-3 py-2 text-sm',
    md: props.iconOnly ? 'p-3' : 'px-3.5 py-2.5 text-sm',
    lg: props.iconOnly ? 'p-3' : 'px-4 py-3 text-sm',
    xl: props.iconOnly ? 'p-3.5' : 'px-4.5 py-3.5 text-sm'
  }
  classes.push(sizeMap[props.size])

  // Rounded classes
  const roundedMap = {
    sm: 'rounded-sm',
    md: 'rounded-md',
    full: 'rounded-full'
  }
  classes.push(roundedMap[props.rounded])

  // Variant classes
  if (props.variant === 'primary') {
    classes.push(
      'bg-sky-600',
      'text-white',
      'shadow-xs',
      'hover:bg-sky-500',
      'focus-visible:outline-sky-600',
      'dark:bg-sky-500',
      'dark:shadow-none',
      'dark:hover:bg-sky-400',
      'dark:focus-visible:outline-sky-500'
    )
  } else if (props.variant === 'secondary') {
    classes.push(
      'bg-white',
      'text-gray-900',
      'shadow-xs',
      'inset-ring',
      'inset-ring-gray-300',
      'hover:bg-gray-50',
      'dark:bg-white/10',
      'dark:text-white',
      'dark:shadow-none',
      'dark:inset-ring-white/5',
      'dark:hover:bg-white/20'
    )
  } else if (props.variant === 'soft') {
    classes.push(
      'bg-sky-50',
      'text-sky-600',
      'shadow-xs',
      'hover:bg-sky-100',
      'dark:bg-sky-500/20',
      'dark:text-sky-400',
      'dark:shadow-none',
      'dark:hover:bg-sky-500/30'
    )
  }

  // Icon layout
  if (props.icon && !props.iconOnly) {
    classes.push('inline-flex', 'items-center')
    classes.push(props.size === 'xl' ? 'gap-x-2' : 'gap-x-1.5')
  }

  return classes.join(' ')
})

const iconClasses = computed(() => {
  const classes = []

  if (props.iconOnly) {
    classes.push('size-5')
  } else {
    classes.push('size-5')
    if (props.iconPosition === 'left') {
      classes.push('-ml-0.5')
    } else {
      classes.push('-mr-0.5')
    }
  }

  return classes.join(' ')
})
</script>
