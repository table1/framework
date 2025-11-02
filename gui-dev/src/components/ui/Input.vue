<template>
  <div>
    <label v-if="label" :for="id" class="block text-sm/6 font-medium text-gray-900 dark:text-white">
      {{ label }}
    </label>
    <div :class="['mt-2', error ? 'grid grid-cols-1' : '']">
      <input
        :id="id"
        :type="type"
        :value="modelValue"
        :placeholder="placeholder"
        :required="required"
        :disabled="disabled"
        :aria-invalid="error ? 'true' : undefined"
        :aria-describedby="error ? `${id}-error` : hint ? `${id}-description` : undefined"
        @input="$emit('update:modelValue', $event.target.value)"
        :class="inputClasses"
      />
      <svg
        v-if="error"
        viewBox="0 0 16 16"
        fill="currentColor"
        data-slot="icon"
        aria-hidden="true"
        class="pointer-events-none col-start-1 row-start-1 mr-3 size-5 self-center justify-self-end text-red-500 sm:size-4 dark:text-red-400"
      >
        <path d="M8 15A7 7 0 1 0 8 1a7 7 0 0 0 0 14ZM8 4a.75.75 0 0 1 .75.75v3a.75.75 0 0 1-1.5 0v-3A.75.75 0 0 1 8 4Zm0 8a1 1 0 1 0 0-2 1 1 0 0 0 0 2Z" clip-rule="evenodd" fill-rule="evenodd" />
      </svg>
    </div>
    <p v-if="error" :id="`${id}-error`" class="mt-2 text-sm text-red-600 dark:text-red-400">
      {{ error }}
    </p>
    <p v-if="hint && !error" :id="`${id}-description`" class="mt-2 text-sm text-gray-500 dark:text-gray-400">
      {{ hint }}
    </p>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  id: {
    type: String,
    default: () => `input-${Math.random().toString(36).substr(2, 9)}`
  },
  modelValue: {
    type: [String, Number],
    default: ''
  },
  type: {
    type: String,
    default: 'text'
  },
  label: {
    type: String,
    default: null
  },
  placeholder: {
    type: String,
    default: ''
  },
  required: {
    type: Boolean,
    default: false
  },
  disabled: {
    type: Boolean,
    default: false
  },
  error: {
    type: String,
    default: null
  },
  hint: {
    type: String,
    default: null
  }
})

defineEmits(['update:modelValue'])

const inputClasses = computed(() => {
  const classes = [
    'block',
    'w-full',
    'rounded-md',
    'bg-white',
    'px-3',
    'py-1.5',
    'text-base',
    'outline-1',
    '-outline-offset-1',
    'placeholder:text-gray-400',
    'focus:outline-2',
    'focus:-outline-offset-2',
    'sm:text-sm/6',
    'dark:bg-white/5',
    'dark:placeholder:text-gray-500'
  ]

  if (props.error) {
    classes.push(
      'col-start-1',
      'row-start-1',
      'pr-10',
      'pl-3',
      'text-red-900',
      'outline-red-300',
      'placeholder:text-red-300',
      'focus:outline-red-600',
      'sm:pr-9',
      'dark:text-red-400',
      'dark:outline-red-500/50',
      'dark:placeholder:text-red-400/70',
      'dark:focus:outline-red-400'
    )
  } else {
    classes.push(
      'text-gray-900',
      'outline-gray-300',
      'focus:outline-sky-600',
      'dark:text-white',
      'dark:outline-white/10',
      'dark:focus:outline-sky-500'
    )
  }

  return classes.join(' ')
})
</script>
