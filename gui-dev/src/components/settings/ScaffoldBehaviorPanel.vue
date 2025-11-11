<template>
  <div :class="containerClasses">
    <div class="space-y-5">
      <div>
        <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Auto-Load Functions</h4>
        <Toggle
          :model-value="state.source_all_functions"
          label="Source all R files from functions/ directory"
          description="Automatically loads all helper functions when scaffold() runs"
          @update:modelValue="(val) => emitUpdate({ source_all_functions: val })"
        />
      </div>

      <div>
        <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">ggplot2 Theme</h4>
        <Toggle
          :model-value="state.set_theme_on_scaffold"
          label="Set ggplot2 theme when scaffold() runs"
          description="Automatically sets ggplot2 theme for consistent plot styling"
          @update:modelValue="(val) => emitUpdate({ set_theme_on_scaffold: val })"
        />
        <Select
          v-if="state.set_theme_on_scaffold"
          :model-value="state.ggplot_theme"
          label="Theme"
          class="mt-4"
          @update:modelValue="(val) => emitUpdate({ ggplot_theme: val })"
        >
          <option value="">None</option>
          <option value="theme_minimal">Minimal</option>
          <option value="theme_bw">Black & White</option>
          <option value="theme_classic">Classic</option>
          <option value="theme_gray">Gray (default)</option>
          <option value="theme_light">Light</option>
          <option value="theme_dark">Dark</option>
          <option value="theme_void">Void</option>
        </Select>
      </div>

      <div>
        <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Random Seed</h4>
        <Toggle
          :model-value="state.seed_on_scaffold"
          label="Set random seed when scaffold() runs"
          description="Ensures deterministic behavior for reproducibility"
          @update:modelValue="(val) => emitUpdate({ seed_on_scaffold: val })"
        />
        <Input
          v-if="state.seed_on_scaffold"
          :model-value="state.seed"
          label="Seed Value"
          placeholder="e.g., 1234 or 20241107"
          hint="Leave empty to use global default"
          class="mt-4"
          @update:modelValue="(val) => emitUpdate({ seed: val })"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import Toggle from '../ui/Toggle.vue'
import Select from '../ui/Select.vue'
import Input from '../ui/Input.vue'

const props = defineProps({
  modelValue: {
    type: Object,
    required: true
  },
  flush: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:modelValue'])

const normalize = () => ({
  source_all_functions: props.modelValue?.source_all_functions ?? true,
  set_theme_on_scaffold: props.modelValue?.set_theme_on_scaffold ?? true,
  ggplot_theme: props.modelValue?.ggplot_theme ?? 'theme_minimal',
  seed_on_scaffold: props.modelValue?.seed_on_scaffold ?? false,
  seed: props.modelValue?.seed ?? ''
})

const state = computed(normalize)

const containerClasses = computed(() =>
  props.flush ? 'space-y-5' : 'rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 space-y-5'
)

const emitUpdate = (patch) => {
  const base = normalize()
  emit('update:modelValue', {
    ...base,
    ...patch
  })
}

</script>
