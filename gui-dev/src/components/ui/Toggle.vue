<template>
  <div class="flex items-center gap-3">
    <div
      class="group relative inline-flex w-11 shrink-0 rounded-full p-0.5 inset-ring inset-ring-gray-900/5 outline-offset-2 transition-colors duration-200 ease-in-out dark:inset-ring-white/10"
      :class="[
        modelValue
          ? 'bg-sky-600 outline-sky-600 dark:bg-sky-500 dark:outline-sky-500'
          : 'bg-gray-200 outline-sky-600 dark:bg-white/5 dark:outline-sky-500'
      ]"
    >
      <span
        class="size-5 rounded-full bg-white shadow-xs ring-1 ring-gray-900/5 transition-transform duration-200 ease-in-out"
        :class="{ 'translate-x-5': modelValue }"
      ></span>
      <input
        :id="id"
        type="checkbox"
        :name="name"
        :checked="modelValue"
        :disabled="disabled"
        :aria-label="ariaLabel || label"
        class="absolute inset-0 appearance-none focus:outline-hidden cursor-pointer disabled:cursor-not-allowed"
        @change="handleChange"
      />
    </div>

    <div v-if="label || description" class="text-sm/6">
      <label
        v-if="label"
        :for="id"
        class="font-medium text-gray-900 cursor-pointer dark:text-white"
        :class="{ 'cursor-not-allowed opacity-50': disabled }"
      >
        {{ label }}
      </label>
      <p
        v-if="description"
        :id="`${id}-description`"
        class="text-gray-500 dark:text-gray-400"
      >
        {{ description }}
      </p>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  id: {
    type: String,
    default: () => `toggle-${Math.random().toString(36).substr(2, 9)}`
  },
  name: {
    type: String,
    default: null
  },
  modelValue: {
    type: Boolean,
    default: false
  },
  label: {
    type: String,
    default: null
  },
  description: {
    type: String,
    default: null
  },
  ariaLabel: {
    type: String,
    default: null
  },
  disabled: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:modelValue', 'change'])

const handleChange = (event) => {
  if (!props.disabled) {
    const checked = event.target.checked
    emit('update:modelValue', checked)
    emit('change', checked)
  }
}
</script>
