<template>
  <div :class="alertClasses" role="alert">
    <div class="flex gap-3">
      <!-- Icon -->
      <component :is="iconComponent" class="h-5 w-5 shrink-0" />

      <!-- Content -->
      <div class="flex-1">
        <p v-if="title" :class="titleClasses">{{ title }}</p>
        <p v-if="description || $slots.default" :class="descriptionClasses">
          <slot>{{ description }}</slot>
        </p>
      </div>

      <!-- Dismiss button -->
      <button
        v-if="dismissible"
        type="button"
        @click="dismiss"
        :class="dismissClasses"
      >
        <span class="sr-only">Dismiss</span>
        <svg viewBox="0 0 20 20" fill="currentColor" class="size-5">
          <path d="M6.28 5.22a.75.75 0 0 0-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 1 0 1.06 1.06L10 11.06l3.72 3.72a.75.75 0 1 0 1.06-1.06L11.06 10l3.72-3.72a.75.75 0 0 0-1.06-1.06L10 8.94 6.28 5.22Z" />
        </svg>
      </button>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  type: {
    type: String,
    default: 'info',
    validator: (value) => ['success', 'error', 'warning', 'info'].includes(value)
  },
  title: {
    type: String,
    default: null
  },
  description: {
    type: String,
    default: null
  },
  dismissible: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['dismiss'])

const typeStyles = {
  success: {
    container: 'bg-sky-50 dark:bg-sky-900/20 inset-ring inset-ring-sky-200 dark:inset-ring-sky-800',
    icon: 'text-sky-600 dark:text-sky-400',
    title: 'text-sky-800 dark:text-sky-200',
    description: 'text-sky-700 dark:text-sky-300',
    dismiss: 'text-sky-600 hover:text-sky-700 dark:text-sky-400 dark:hover:text-sky-300'
  },
  error: {
    container: 'bg-red-50 dark:bg-red-900/20 inset-ring inset-ring-red-200 dark:inset-ring-red-800',
    icon: 'text-red-600 dark:text-red-400',
    title: 'text-red-800 dark:text-red-200',
    description: 'text-red-700 dark:text-red-300',
    dismiss: 'text-red-600 hover:text-red-700 dark:text-red-400 dark:hover:text-red-300'
  },
  warning: {
    container: 'bg-yellow-50 dark:bg-yellow-900/20 inset-ring inset-ring-yellow-200 dark:inset-ring-yellow-800',
    icon: 'text-yellow-600 dark:text-yellow-400',
    title: 'text-yellow-800 dark:text-yellow-200',
    description: 'text-yellow-700 dark:text-yellow-300',
    dismiss: 'text-yellow-600 hover:text-yellow-700 dark:text-yellow-400 dark:hover:text-yellow-300'
  },
  info: {
    container: 'bg-blue-50 dark:bg-blue-900/20 inset-ring inset-ring-blue-200 dark:inset-ring-blue-800',
    icon: 'text-blue-600 dark:text-blue-400',
    title: 'text-blue-800 dark:text-blue-200',
    description: 'text-blue-700 dark:text-blue-300',
    dismiss: 'text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300'
  }
}

const alertClasses = computed(() => {
  return `rounded-lg p-4 ${typeStyles[props.type].container}`
})

const titleClasses = computed(() => {
  return `text-sm font-medium ${typeStyles[props.type].title}`
})

const descriptionClasses = computed(() => {
  const classes = [`text-sm ${typeStyles[props.type].description}`]
  if (props.title) classes.push('mt-1')
  return classes.join(' ')
})

const dismissClasses = computed(() => {
  return `rounded-md p-1 ${typeStyles[props.type].dismiss} focus:outline-2 focus:outline-offset-2`
})

const iconComponent = computed(() => {
  const baseClass = typeStyles[props.type].icon

  const icons = {
    success: {
      template: `
        <svg viewBox="0 0 20 20" fill="currentColor" class="${baseClass}">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" clip-rule="evenodd" />
        </svg>
      `
    },
    error: {
      template: `
        <svg viewBox="0 0 20 20" fill="currentColor" class="${baseClass}">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clip-rule="evenodd" />
        </svg>
      `
    },
    warning: {
      template: `
        <svg viewBox="0 0 20 20" fill="currentColor" class="${baseClass}">
          <path fill-rule="evenodd" d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z" clip-rule="evenodd" />
        </svg>
      `
    },
    info: {
      template: `
        <svg viewBox="0 0 20 20" fill="currentColor" class="${baseClass}">
          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a.75.75 0 000 1.5h.253a.25.25 0 01.244.304l-.459 2.066A1.75 1.75 0 0010.747 15H11a.75.75 0 000-1.5h-.253a.25.25 0 01-.244-.304l.459-2.066A1.75 1.75 0 009.253 9H9z" clip-rule="evenodd" />
        </svg>
      `
    }
  }

  return icons[props.type]
})

const dismiss = () => {
  emit('dismiss')
}
</script>
