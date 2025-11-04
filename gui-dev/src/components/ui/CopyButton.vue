<template>
  <button
    type="button"
    @click="copyToClipboard"
    :class="[
      baseClasses,
      variantClasses,
      copied && 'ring-2 ring-sky-500/20'
    ]"
    :title="copied ? 'Copied!' : 'Copy to clipboard'"
  >
    <slot :copied="copied">
      <!-- Default slot content -->
      <svg
        v-if="!copied"
        class="h-4 w-4"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"
        />
      </svg>
      <svg
        v-else
        class="h-4 w-4 text-sky-600 dark:text-sky-500"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M5 13l4 4L19 7"
        />
      </svg>
      <span v-if="showLabel">{{ copied ? 'Copied!' : 'Copy' }}</span>
    </slot>
  </button>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useToast } from '@/composables/useToast'

const props = defineProps({
  value: {
    type: String,
    required: true
  },
  showLabel: {
    type: Boolean,
    default: false
  },
  variant: {
    type: String,
    default: 'default', // 'default', 'ghost', 'bare'
    validator: (value) => ['default', 'ghost', 'bare'].includes(value)
  },
  successMessage: {
    type: String,
    default: 'Copied to clipboard'
  }
})

const toast = useToast()
const copied = ref(false)
let resetTimeout = null

const baseClasses = computed(() => (
  props.variant === 'bare'
    ? 'inline-flex items-center text-sm font-medium transition-all'
    : 'inline-flex items-center gap-1.5 rounded-md px-2.5 py-1.5 text-sm font-medium transition-all'
))

const variantClasses = computed(() => {
  if (props.variant === 'ghost') {
    return 'text-zinc-600 hover:bg-zinc-100 dark:text-zinc-400 dark:hover:bg-zinc-800'
  }
  if (props.variant === 'bare') {
    return 'gap-2 rounded-lg transition-all focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-sky-500'
  }
  return 'bg-zinc-100 text-zinc-700 hover:bg-zinc-200 dark:bg-zinc-800 dark:text-zinc-300 dark:hover:bg-zinc-700'
})

const copyToClipboard = async () => {
  try {
    await navigator.clipboard.writeText(props.value)
    copied.value = true

    // Show toast
    toast.success('Copied!', props.successMessage)

    // Reset the copied state after 2 seconds
    if (resetTimeout) clearTimeout(resetTimeout)
    resetTimeout = setTimeout(() => {
      copied.value = false
    }, 2000)
  } catch (err) {
    toast.error('Copy failed', 'Could not copy to clipboard')
    console.error('Failed to copy:', err)
  }
}
</script>
