<template>
  <Transition
    enter-active-class="transform transition duration-300 ease-out"
    enter-from-class="translate-y-2 opacity-0 sm:translate-x-2 sm:translate-y-0"
    enter-to-class="translate-y-0 opacity-100 sm:translate-x-0"
    leave-active-class="transition duration-200 ease-in"
    leave-from-class="opacity-100"
    leave-to-class="opacity-0"
  >
    <div
      v-if="visible"
      class="pointer-events-auto w-full max-w-sm rounded-lg bg-white shadow-lg outline-1 outline-black/5 dark:bg-gray-800 dark:-outline-offset-1 dark:outline-white/10"
    >
      <div class="p-4">
        <div :class="variant === 'condensed' ? 'flex items-center' : 'flex items-start'">
          <!-- Icon (only for regular variant) -->
          <div v-if="variant === 'regular'" class="shrink-0">
            <component :is="iconComponent" class="size-6" />
          </div>

          <!-- Content -->
          <div :class="[
            variant === 'regular' ? 'ml-3 w-0 flex-1 pt-0.5' : 'flex w-0 flex-1 justify-between'
          ]">
            <p v-if="variant === 'condensed'" class="w-0 flex-1 text-sm font-medium text-gray-900 dark:text-white">
              {{ title }}
            </p>
            <template v-else>
              <p class="text-sm font-medium text-gray-900 dark:text-white">{{ title }}</p>
              <p v-if="description" class="mt-1 text-sm text-gray-500 dark:text-gray-400">{{ description }}</p>
            </template>

            <!-- Action button (condensed variant) -->
            <button
              v-if="variant === 'condensed' && action"
              type="button"
              @click="handleAction"
              class="ml-3 shrink-0 rounded-md bg-white text-sm font-medium text-sky-600 hover:text-sky-500 focus:outline-2 focus:outline-offset-2 focus:outline-sky-500 dark:bg-gray-800 dark:text-sky-400 dark:hover:text-sky-300 dark:focus:outline-sky-400"
            >
              {{ action }}
            </button>
          </div>

          <!-- Close button -->
          <div class="ml-4 flex shrink-0">
            <button
              type="button"
              @click="close"
              class="inline-flex rounded-md text-gray-400 hover:text-gray-500 focus:outline-2 focus:outline-offset-2 focus:outline-sky-600 dark:hover:text-white dark:focus:outline-sky-500"
            >
              <span class="sr-only">Close</span>
              <svg viewBox="0 0 20 20" fill="currentColor" class="size-5">
                <path d="M6.28 5.22a.75.75 0 0 0-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 1 0 1.06 1.06L10 11.06l3.72 3.72a.75.75 0 1 0 1.06-1.06L11.06 10l3.72-3.72a.75.75 0 0 0-1.06-1.06L10 8.94 6.28 5.22Z" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup>
import { ref, computed, onMounted, watch, h } from 'vue'
import {
  CheckCircleIcon,
  ExclamationTriangleIcon,
  InformationCircleIcon,
  XCircleIcon
} from '@heroicons/vue/24/outline'

const props = defineProps({
  title: {
    type: String,
    required: true
  },
  description: {
    type: String,
    default: null
  },
  type: {
    type: String,
    default: 'success',
    validator: (value) => ['success', 'error', 'warning', 'info'].includes(value)
  },
  variant: {
    type: String,
    default: 'regular',
    validator: (value) => ['regular', 'condensed'].includes(value)
  },
  action: {
    type: String,
    default: null
  },
  duration: {
    type: Number,
    default: 5000
  },
  autoClose: {
    type: Boolean,
    default: true
  }
})

const emit = defineEmits(['close', 'action'])

const visible = ref(false)
let timeout = null

const iconComponent = computed(() => {
  const iconMap = {
    success: CheckCircleIcon,
    error: XCircleIcon,
    warning: ExclamationTriangleIcon,
    info: InformationCircleIcon
  }

  const colorMap = {
    success: 'text-sky-400',
    error: 'text-red-400',
    warning: 'text-yellow-400',
    info: 'text-blue-400'
  }

  const Icon = iconMap[props.type]
  const colorClass = colorMap[props.type]

  return () => h(Icon, { class: `size-6 ${colorClass}` })
})

const close = () => {
  visible.value = false
  if (timeout) clearTimeout(timeout)
  setTimeout(() => emit('close'), 200) // Wait for transition
}

const handleAction = () => {
  emit('action')
  close()
}

onMounted(() => {
  visible.value = true
  if (props.autoClose && props.duration > 0) {
    timeout = setTimeout(close, props.duration)
  }
})

watch(() => props.duration, (newDuration) => {
  if (timeout) clearTimeout(timeout)
  if (props.autoClose && newDuration > 0) {
    timeout = setTimeout(close, newDuration)
  }
})
</script>
