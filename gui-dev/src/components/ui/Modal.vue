<template>
  <Teleport to="body">
    <Transition name="modal">
      <div v-if="modelValue" class="relative z-50">
        <!-- Backdrop -->
        <div
          class="fixed inset-0 bg-gray-500/75 transition-opacity dark:bg-gray-900/50"
          @click="handleBackdropClick"
        ></div>

        <!-- Modal container -->
        <div class="fixed inset-0 z-10 overflow-y-auto">
          <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
            <!-- Modal panel -->
            <div
              :class="panelClasses"
              role="dialog"
              aria-modal="true"
              :aria-labelledby="titleId"
            >
              <!-- Icon (optional) -->
              <div v-if="$slots.icon || icon" :class="iconWrapperClasses">
                <slot name="icon">
                  <component :is="iconComponent" v-if="icon" class="size-6" />
                </slot>
              </div>

              <!-- Content -->
              <div :class="contentClasses">
                <h3 v-if="title" :id="titleId" :class="titleClasses">
                  {{ title }}
                </h3>
                <div v-if="description || $slots.default" :class="descriptionClasses">
                  <p v-if="description" class="text-sm text-gray-500 dark:text-gray-400">
                    {{ description }}
                  </p>
                  <slot v-else />
                </div>
              </div>

              <!-- Actions -->
              <div v-if="$slots.actions" :class="actionsClasses">
                <slot name="actions" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { computed, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  title: {
    type: String,
    default: null
  },
  description: {
    type: String,
    default: null
  },
  icon: {
    type: String,
    default: null,
    validator: (value) => ['success', 'error', 'warning', 'info'].includes(value)
  },
  size: {
    type: String,
    default: 'md',
    validator: (value) => ['sm', 'md', 'lg', 'xl'].includes(value)
  },
  variant: {
    type: String,
    default: 'centered',
    validator: (value) => ['centered', 'side-icon', 'left'].includes(value)
  },
  closeOnBackdrop: {
    type: Boolean,
    default: true
  }
})

const emit = defineEmits(['update:modelValue', 'close'])

const titleId = computed(() => `modal-title-${Math.random().toString(36).substr(2, 9)}`)

const sizeClasses = {
  sm: 'sm:max-w-sm',
  md: 'sm:max-w-lg',
  lg: 'sm:max-w-2xl',
  xl: 'sm:max-w-4xl'
}

const panelClasses = computed(() => {
  const classes = [
    'relative',
    'transform',
    'overflow-hidden',
    'rounded-lg',
    'bg-white',
    'px-4',
    'pt-5',
    'pb-4',
    'text-left',
    'shadow-xl',
    'transition-all',
    'sm:my-8',
    'sm:w-full',
    'sm:p-6',
    'dark:bg-gray-800',
    'dark:outline',
    'dark:-outline-offset-1',
    'dark:outline-white/10',
    sizeClasses[props.size]
  ]
  return classes.join(' ')
})

const iconWrapperClasses = computed(() => {
  const baseClasses = [
    'flex',
    'items-center',
    'justify-center',
    'rounded-full'
  ]

  if (props.variant === 'centered') {
    baseClasses.push('mx-auto', 'size-12')
  } else {
    baseClasses.push('shrink-0', 'sm:mx-0', 'sm:size-10')
  }

  const iconColors = {
    success: 'bg-sky-100 text-sky-600 dark:bg-sky-500/10 dark:text-sky-400',
    error: 'bg-red-100 text-red-600 dark:bg-red-500/10 dark:text-red-400',
    warning: 'bg-yellow-100 text-yellow-600 dark:bg-yellow-500/10 dark:text-yellow-400',
    info: 'bg-blue-100 text-blue-600 dark:bg-blue-500/10 dark:text-blue-400'
  }

  if (props.icon) {
    baseClasses.push(iconColors[props.icon])
  }

  return baseClasses.join(' ')
})

const contentClasses = computed(() => {
  const classes = []

  if (props.variant === 'centered') {
    classes.push('mt-3', 'text-center', 'sm:mt-5')
  } else if (props.variant === 'left') {
    classes.push('text-left')
  } else {
    classes.push('mt-3', 'text-center', 'sm:mt-0', 'sm:ml-4', 'sm:text-left')
  }

  if (props.variant === 'side-icon' && (props.icon || props.$slots.icon)) {
    classes.push('sm:flex', 'sm:items-start')
  }

  return classes.join(' ')
})

const titleClasses = computed(() => {
  if (props.variant === 'left') {
    return 'text-lg font-bold text-gray-900 dark:text-white mb-4'
  }
  return 'text-base font-semibold text-gray-900 dark:text-white'
})

const descriptionClasses = computed(() => {
  return props.variant === 'centered' ? 'mt-2' : 'mt-2'
})

const actionsClasses = computed(() => {
  if (props.variant === 'left') {
    return 'mt-6 pt-4 border-t border-gray-200 dark:border-gray-700 flex gap-3 justify-between'
  }
  return props.variant === 'centered' ? 'mt-5 sm:mt-6 flex gap-3 justify-end' : 'mt-5 sm:mt-4 flex gap-3 justify-end'
})

const iconComponent = computed(() => {
  if (props.icon === 'success') {
    return {
      template: `
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
          <path d="m4.5 12.75 6 6 9-13.5" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
      `
    }
  } else if (props.icon === 'error' || props.icon === 'warning') {
    return {
      template: `
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
          <path d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
      `
    }
  } else if (props.icon === 'info') {
    return {
      template: `
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
          <path d="M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12V8.25z" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
      `
    }
  }
  return null
})

const handleBackdropClick = () => {
  if (props.closeOnBackdrop) {
    close()
  }
}

const handleKeydown = (e) => {
  if (e.key === 'Escape' && props.modelValue) {
    close()
  }
}

const close = () => {
  emit('update:modelValue', false)
  emit('close')
}

// Add/remove keyboard listener
onMounted(() => {
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})

// Expose close method for parent components
defineExpose({ close })
</script>

<style scoped>
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-active .modal-panel,
.modal-leave-active .modal-panel {
  transition: all 0.3s ease;
}

.modal-enter-from .modal-panel,
.modal-leave-to .modal-panel {
  opacity: 0;
  transform: translateY(1rem) scale(0.95);
}

@media (min-width: 640px) {
  .modal-enter-from .modal-panel,
  .modal-leave-to .modal-panel {
    transform: translateY(0) scale(0.95);
  }
}
</style>
