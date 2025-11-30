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
        @update:model-value="updateField('name', $event)"
        label="Your Name"
        placeholder="Your Name"
      />
      <Input
        :model-value="localAuthor.email"
        @update:model-value="updateField('email', $event)"
        type="email"
        label="Email"
        placeholder="your.email@example.com"
      />
      <Input
        :model-value="localAuthor.affiliation"
        @update:model-value="updateField('affiliation', $event)"
        label="Affiliation"
        placeholder="Organization"
      />

      <!-- GitHub Section -->
      <div class="pt-4 border-t border-gray-200 dark:border-gray-700">
        <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">GitHub</h4>
        <div class="space-y-4">
          <Input
            :model-value="localAuthor.github_username"
            @update:model-value="updateField('github_username', $event)"
            label="GitHub Username"
            placeholder="username"
          />
          <Input
            :model-value="localAuthor.github_email"
            @update:model-value="updateField('github_email', $event)"
            type="email"
            label="GitHub Email"
            placeholder="username@users.noreply.github.com"
            hint="For git commits (often different from primary email)"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import Input from '../ui/Input.vue'

const props = defineProps({
  modelValue: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['update:modelValue'])

const localAuthor = ref({
  name: props.modelValue.name ?? '',
  email: props.modelValue.email ?? '',
  affiliation: props.modelValue.affiliation ?? '',
  github_username: props.modelValue.github_username ?? '',
  github_email: props.modelValue.github_email ?? ''
})

// Watch for external changes
watch(() => props.modelValue, (newValue) => {
  localAuthor.value = {
    name: newValue.name ?? '',
    email: newValue.email ?? '',
    affiliation: newValue.affiliation ?? '',
    github_username: newValue.github_username ?? '',
    github_email: newValue.github_email ?? ''
  }
}, { deep: true })

const updateField = (field, value) => {
  localAuthor.value[field] = value
  emit('update:modelValue', { ...localAuthor.value })
}
</script>
