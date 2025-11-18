<template>
  <div class="space-y-3">
    <button
      v-for="item in projectTypeOptions"
      :key="item.key"
      @click="selectType(item.key)"
      :class="[
        'group relative w-full rounded-lg border p-6 text-left transition',
        selectedType === item.key
          ? 'border-sky-600 bg-sky-50 dark:border-sky-500 dark:bg-sky-900/20'
          : 'border-gray-200 hover:border-sky-300 dark:border-gray-700 dark:hover:border-sky-600'
      ]"
    >
      <div class="flex items-start gap-3">
        <FolderIcon
          :class="[
            'h-6 w-6 flex-shrink-0 transition',
            selectedType === item.key
              ? 'text-sky-600 dark:text-sky-400'
              : 'text-gray-400 group-hover:text-sky-600 dark:group-hover:text-sky-400'
          ]"
        />
        <div>
          <h3 class="font-semibold text-gray-900 dark:text-white">
            {{ item.label }}
          </h3>
          <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
            {{ item.description }}
          </p>
        </div>
      </div>
    </button>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { FolderIcon } from '@heroicons/vue/24/outline'

const props = defineProps({
  modelValue: {
    type: String,
    required: true
  },
  projectTypes: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['update:modelValue'])

const selectedType = computed(() => props.modelValue)

const projectTypeOptions = computed(() => {
  return Object.entries(props.projectTypes).map(([key, config]) => ({
    key,
    label: config.label || key,
    description: config.description || ''
  }))
})

const selectType = (typeKey) => {
  emit('update:modelValue', typeKey)
}
</script>
