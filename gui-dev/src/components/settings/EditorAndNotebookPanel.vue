<template>
  <div class="space-y-5">
    <div>
      <label class="block text-sm font-semibold text-gray-900 dark:text-white mb-3">
        Supported Editors
      </label>
      <Checkbox
        :model-value="positron"
        @update:model-value="$emit('update:positron', $event)"
        id="support-positron"
        description="Creates .code-workspace file for Positron/VS Code users"
      >
        Positron / VS Code
      </Checkbox>
      <p class="text-sm text-gray-500 dark:text-gray-400 mt-3">
        RStudio supported by default
      </p>
    </div>

    <Select
      :model-value="notebookFormat"
      @update:model-value="$emit('update:notebookFormat', $event)"
      label="Default Notebook Format"
      hint="Format used when creating new notebooks"
    >
      <option value="quarto">Quarto (.qmd)</option>
      <option value="rmarkdown">R Markdown (.Rmd)</option>
    </Select>
  </div>
</template>

<script setup>
import Checkbox from '../ui/Checkbox.vue'
import Select from '../ui/Select.vue'

defineProps({
  positron: {
    type: Boolean,
    default: false
  },
  notebookFormat: {
    type: String,
    default: 'quarto'
  }
})

defineEmits(['update:positron', 'update:notebookFormat'])
</script>
