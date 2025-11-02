<template>
  <button
    v-if="action"
    type="button"
    @click="handleClick"
    :class="containerClasses"
  >
    <slot name="icon">
      <component :is="iconComponent" v-if="icon" class="mx-auto size-12 text-gray-400 dark:text-gray-500" />
    </slot>
    <span class="mt-2 block text-sm font-semibold text-gray-900 dark:text-white">
      {{ title }}
    </span>
    <p v-if="description" class="mt-1 text-sm text-gray-500 dark:text-gray-400">
      {{ description }}
    </p>
  </button>
  <div v-else :class="containerClasses.replace('hover:border-gray-400', '').replace('focus:outline-2', '')">
    <slot name="icon">
      <component :is="iconComponent" v-if="icon" class="mx-auto size-12 text-gray-400 dark:text-gray-500" />
    </slot>
    <h3 class="mt-2 text-sm font-semibold text-gray-900 dark:text-white">
      {{ title }}
    </h3>
    <p v-if="description" class="mt-1 text-sm text-gray-500 dark:text-gray-400">
      {{ description }}
    </p>
    <div v-if="$slots.actions" class="mt-6">
      <slot name="actions" />
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  title: {
    type: String,
    required: true
  },
  description: {
    type: String,
    default: null
  },
  icon: {
    type: String,
    default: null,
    validator: (value) => ['database', 'folder', 'document', 'users', 'inbox', 'photo'].includes(value)
  },
  action: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['click'])

const containerClasses = computed(() => {
  const classes = [
    'relative',
    'block',
    'w-full',
    'rounded-lg',
    'border-2',
    'border-dashed',
    'border-gray-300',
    'p-12',
    'text-center',
    'dark:border-white/15'
  ]

  if (props.action) {
    classes.push(
      'hover:border-gray-400',
      'focus:outline-2',
      'focus:outline-offset-2',
      'focus:outline-sky-600',
      'dark:hover:border-white/25',
      'dark:focus:outline-sky-500',
      'transition-colors'
    )
  }

  return classes.join(' ')
})

const iconComponent = computed(() => {
  const icons = {
    database: {
      template: `
        <svg viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M8 14v20c0 4.418 7.163 8 16 8 1.381 0 2.721-.087 4-.252M8 14c0 4.418 7.163 8 16 8s16-3.582 16-8M8 14c0-4.418 7.163-8 16-8s16 3.582 16 8m0 0v14m0-4c0 4.418-7.163 8-16 8S8 28.418 8 24m32 10v6m0 0v6m0-6h6m-6 0h-6" />
        </svg>
      `
    },
    folder: {
      template: `
        <svg viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M3 7v30a4 4 0 004 4h34a4 4 0 004-4V13a4 4 0 00-4-4H23.343a4 4 0 01-2.829-1.172l-2.828-2.828A4 4 0 0014.858 4H7a4 4 0 00-4 4v0zM37 17v6m0 0v6m0-6h6m-6 0h-6" />
        </svg>
      `
    },
    document: {
      template: `
        <svg viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M8 4a4 4 0 00-4 4v32a4 4 0 004 4h32a4 4 0 004-4V8a4 4 0 00-4-4H8zm24 16v6m0 0v6m0-6h6m-6 0h-6" />
        </svg>
      `
    },
    users: {
      template: `
        <svg viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M17 21a5 5 0 110-10 5 5 0 010 10zm-6.5 8a7.5 7.5 0 0115 0H10.5zM31 21a5 5 0 110-10 5 5 0 010 10zm-6.5 8a7.5 7.5 0 0115 0H24.5z" />
        </svg>
      `
    },
    inbox: {
      template: `
        <svg viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M4 8h40M4 8v28a4 4 0 004 4h32a4 4 0 004-4V8M4 8l18 14a2 2 0 002.4 0L44 8" />
        </svg>
      `
    },
    photo: {
      template: `
        <svg viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M4 8a4 4 0 014-4h32a4 4 0 014 4v32a4 4 0 01-4 4H8a4 4 0 01-4-4V8zm10 6a3 3 0 100-6 3 3 0 000 6zM4 40l12-12 8 8 8-8L44 40" />
        </svg>
      `
    }
  }

  return icons[props.icon] || null
})

const handleClick = () => {
  if (props.action) {
    emit('click')
  }
}
</script>
