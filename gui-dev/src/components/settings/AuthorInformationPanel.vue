<template>
  <div class="rounded-lg bg-gray-50 dark:bg-gray-800/50">
    <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-2">
      Author Information
    </h3>
    <p class="text-sm text-gray-600 dark:text-gray-400 mb-5">
      Used as defaults when creating notebook author settings and similar tasks.
    </p>
    <div class="space-y-5">
      <Input
        :model-value="localAuthor.name"
        @update:model-value="updateName"
        label="Your Name"
        placeholder="Your Name"
      />
      <Input
        :model-value="localAuthor.email"
        @update:model-value="updateEmail"
        type="email"
        label="Email"
        placeholder="your.email@example.com"
      />
      <Input
        :model-value="localAuthor.affiliation"
        @update:model-value="updateAffiliation"
        label="Affiliation"
        placeholder="Organization"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import Input from '../ui/Input.vue'

const props = defineProps({
  modelValue: {
    type: Object,
    required: true,
    validator: (value) => {
      return typeof value.name === 'string' &&
             typeof value.email === 'string' &&
             typeof value.affiliation === 'string'
    }
  }
})

const emit = defineEmits(['update:modelValue'])

const localAuthor = ref({
  name: props.modelValue.name ?? '',
  email: props.modelValue.email ?? '',
  affiliation: props.modelValue.affiliation ?? ''
})

// Watch for external changes
watch(() => props.modelValue, (newValue) => {
  localAuthor.value = {
    name: newValue.name ?? '',
    email: newValue.email ?? '',
    affiliation: newValue.affiliation ?? ''
  }
}, { deep: true })

const emitUpdate = () => {
  emit('update:modelValue', { ...localAuthor.value })
}

const updateName = (value) => {
  localAuthor.value.name = value
  emitUpdate()
}

const updateEmail = (value) => {
  localAuthor.value.email = value
  emitUpdate()
}

const updateAffiliation = (value) => {
  localAuthor.value.affiliation = value
  emitUpdate()
}
</script>
