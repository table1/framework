<template>
  <div class="flex gap-3">
    <div class="flex h-6 shrink-0 items-center">
      <div class="group grid size-4 grid-cols-1">
        <input
          :id="id"
          type="checkbox"
          :name="name"
          :checked="modelValue"
          :aria-describedby="description ? `${id}-description` : undefined"
          @change="$emit('update:modelValue', $event.target.checked)"
          class="col-start-1 row-start-1 appearance-none rounded-sm border border-gray-300 bg-white checked:border-sky-600 checked:bg-sky-600 indeterminate:border-sky-600 indeterminate:bg-sky-600 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-600 disabled:border-gray-300 disabled:bg-gray-100 disabled:checked:bg-gray-100 dark:border-white/10 dark:bg-white/5 dark:checked:border-sky-500 dark:checked:bg-sky-500 dark:indeterminate:border-sky-500 dark:indeterminate:bg-sky-500 dark:focus-visible:outline-sky-500 dark:disabled:border-white/5 dark:disabled:bg-white/10 dark:disabled:checked:bg-white/10 forced-colors:appearance-auto"
        />
        <svg
          viewBox="0 0 14 14"
          fill="none"
          class="pointer-events-none col-start-1 row-start-1 size-3.5 self-center justify-self-center stroke-white group-has-disabled:stroke-gray-950/25 dark:group-has-disabled:stroke-white/25"
        >
          <path
            d="M3 8L6 11L11 3.5"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="opacity-0 group-has-checked:opacity-100"
          />
          <path
            d="M3 7H11"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="opacity-0 group-has-indeterminate:opacity-100"
          />
        </svg>
      </div>
    </div>
    <div class="text-sm/6">
      <label :for="id" class="font-medium text-gray-900 dark:text-white">
        <slot />
      </label>
      <p v-if="description" :id="`${id}-description`" class="text-gray-500 dark:text-gray-400">
        {{ description }}
      </p>
    </div>
  </div>
</template>

<script setup>
defineProps({
  id: {
    type: String,
    required: true
  },
  name: {
    type: String,
    default: null
  },
  modelValue: {
    type: Boolean,
    default: false
  },
  description: {
    type: String,
    default: null
  }
})

defineEmits(['update:modelValue'])
</script>
