<template>
  <div :class="containerClasses">
    <Toggle
      :model-value="state.initialize"
      label="Initialize Git"
      description="Run git init for every new project."
      @update:modelValue="(val) => emitUpdate({ initialize: val })"
    />

    <div class="space-y-3">
      <div>
        <h4 class="text-sm font-semibold text-gray-900 dark:text-white">Git Identity</h4>
        <p class="text-sm text-gray-600 dark:text-gray-400">
          Name and email used for git commits. Leave blank to keep your existing global config.
        </p>
      </div>
      <div class="grid gap-4 sm:grid-cols-2">
        <Input
          :model-value="state.user_name"
          label="Git Name"
          placeholder="Jane Analyst"
          :disabled="!state.initialize"
          @update:modelValue="(val) => emitUpdate({ user_name: val })"
        />
        <Input
          :model-value="state.user_email"
          label="Git Email"
          placeholder="jane@example.com"
          hint="Used for git config user.email during project setup."
          :disabled="!state.initialize"
          @update:modelValue="(val) => emitUpdate({ user_email: val })"
        />
      </div>
    </div>

    <div class="space-y-3">
      <div>
        <h4 class="text-sm font-semibold text-gray-900 dark:text-white">Git Hooks</h4>
        <p class="text-sm text-gray-600 dark:text-gray-400">
          Pre-commit hooks that run automatically before each commit.
        </p>
      </div>
      <div class="space-y-4">
        <Toggle
          :model-value="state.hooks.ai_sync"
          label="Sync AI Files Before Commit"
          description="Update non-canonical files so assistants share the same instructions."
          :disabled="!state.initialize"
          @update:modelValue="(val) => updateHook('ai_sync', val)"
        />
        <Toggle
          :model-value="state.hooks.data_security"
          label="Check for Secrets"
          description="Run a lightweight scan for API keys and credentials before commits."
          :disabled="!state.initialize"
          @update:modelValue="(val) => updateHook('data_security', val)"
        />
        <Toggle
          :model-value="state.hooks.check_sensitive_dirs"
          label="Warn About Unignored Sensitive Directories"
          description="Block commits if directories with sensitive names aren't gitignored."
          :disabled="!state.initialize"
          @update:modelValue="(val) => updateHook('check_sensitive_dirs', val)"
        />
      </div>
      <p class="text-xs text-gray-500 dark:text-gray-400">
        <slot name="note">
          Project-specific .gitignore templates can be customized in Project Defaults.
        </slot>
      </p>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import Input from '../ui/Input.vue'
import Toggle from '../ui/Toggle.vue'

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
  initialize: props.modelValue?.initialize ?? true,
  user_name: props.modelValue?.user_name ?? '',
  user_email: props.modelValue?.user_email ?? '',
  hooks: {
    ai_sync: props.modelValue?.hooks?.ai_sync ?? false,
    data_security: props.modelValue?.hooks?.data_security ?? false,
    check_sensitive_dirs: props.modelValue?.hooks?.check_sensitive_dirs ?? false
  }
})

const containerClasses = computed(() =>
  props.flush
    ? 'space-y-6'
    : 'rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 space-y-6'
)

const state = computed(normalize)

const emitUpdate = (patch) => {
  const base = normalize()
  const mergedHooks = {
    ...base.hooks,
    ...(patch?.hooks || {})
  }

  emit('update:modelValue', {
    ...base,
    ...patch,
    hooks: mergedHooks
  })
}

const updateHook = (key, value) => {
  emitUpdate({ hooks: { [key]: value } })
}

</script>
