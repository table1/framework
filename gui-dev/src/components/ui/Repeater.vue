<template>
  <div class="space-y-4">
    <div
      v-for="(item, index) in modelValue"
      :key="item._id || index"
      class="rounded-lg border border-gray-200 p-4 dark:border-gray-700"
    >
      <div class="flex items-start gap-4">
        <div class="flex-1">
          <slot :item="item" :index="index" :update="(field, value) => updateItem(index, field, value)" />
        </div>
        <button
          type="button"
          @click="removeItem(index)"
          class="shrink-0 rounded-md p-1.5 text-gray-400 transition hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-900/20 dark:hover:text-red-400"
          title="Remove"
        >
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    </div>

    <Button
      variant="secondary"
      size="sm"
      @click="addItem"
      class="inline-flex items-center"
    >
      <svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
      </svg>
      {{ addLabel }}
    </Button>
  </div>
</template>

<script setup>
import { defineProps, defineEmits } from 'vue'
import Button from './Button.vue'

const props = defineProps({
  modelValue: {
    type: Array,
    default: () => []
  },
  addLabel: {
    type: String,
    default: 'Add Item'
  },
  defaultItem: {
    type: [Object, Function],
    default: () => ({})
  }
})

const emit = defineEmits(['update:modelValue'])

const addItem = () => {
  const newItem = typeof props.defaultItem === 'function'
    ? props.defaultItem()
    : { ...props.defaultItem, _id: Date.now() }

  emit('update:modelValue', [...props.modelValue, newItem])
}

const removeItem = (index) => {
  const updated = props.modelValue.filter((_, i) => i !== index)
  emit('update:modelValue', updated)
}

const updateItem = (index, field, value) => {
  const updated = [...props.modelValue]
  updated[index] = { ...updated[index], [field]: value }
  emit('update:modelValue', updated)
}
</script>
