<template>
  <div :class="containerClasses">
    <div class="space-y-6">
      <!-- Enable AI Support Toggle -->
      <div>
        <Toggle
          :model-value="state.enabled"
          label="Enable AI Support"
          description="Generate and sync assistant-specific context files."
          @update:modelValue="(val) => emitUpdate({ enabled: val })"
        />
      </div>

      <!-- AI Settings (shown when enabled) -->
      <template v-if="state.enabled">
        <!-- Canonical File Selection -->
        <div class="pt-6 border-t border-gray-200 dark:border-gray-700">
          <h4 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Canonical context file</h4>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
            This file is the source of truth; other instructions files are synced to it when AI hooks run.
          </p>
          <Select
            :model-value="state.canonical_file"
            label="Canonical Context File"
            @update:modelValue="(val) => emitUpdate({ canonical_file: val })"
          >
            <option value="AGENTS.md">AGENTS.md (multi-agent orchestrator)</option>
            <option value="CLAUDE.md">CLAUDE.md</option>
            <option value=".github/copilot-instructions.md">.github/copilot-instructions.md</option>
          </Select>
        </div>

        <!-- Assistants Selection -->
        <div class="pt-6 border-t border-gray-200 dark:border-gray-700">
          <h4 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Assistants</h4>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
            Choose which assistants receive context updates.
          </p>
          <div class="space-y-2">
            <Checkbox
              v-for="assistant in availableAssistants"
              :key="assistant.id"
              :id="`ai-${assistant.id}-${componentId}`"
              :model-value="state.assistants.includes(assistant.id)"
              @update:model-value="(value) => toggleAssistant(assistant.id, value)"
              :description="assistant.description"
            >
              {{ assistant.label }}
            </Checkbox>
          </div>
        </div>

        <!-- Canonical Instructions Editor -->
        <div v-if="showEditor" class="pt-6 border-t border-gray-200 dark:border-gray-700">
          <h4 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Canonical instructions</h4>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
            <slot name="editor-description">
              Edit the canonical file directly. Framework mirrors this content to other assistant files.
            </slot>
          </p>

          <!-- Optional alert slot (for ProjectDetailView) -->
          <slot name="editor-alert"></slot>

          <CodeEditor
            :model-value="state.canonical_content"
            language="markdown"
            :min-height="editorHeight"
            :disabled="editorDisabled"
            @update:modelValue="(val) => emitUpdate({ canonical_content: val })"
          />

          <!-- Optional actions slot (for SettingsView "Restore Default" button) -->
          <slot name="editor-actions"></slot>

          <p v-if="editorLoading" class="text-xs text-gray-500 dark:text-gray-400 mt-2">
            Loading {{ state.canonical_file }}…
          </p>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import Toggle from '../ui/Toggle.vue'
import Select from '../ui/Select.vue'
import Checkbox from '../ui/Checkbox.vue'
import CodeEditor from '../ui/CodeEditor.vue'

const props = defineProps({
  modelValue: {
    type: Object,
    required: true
  },
  flush: {
    type: Boolean,
    default: false
  },
  showEditor: {
    type: Boolean,
    default: true
  },
  editorHeight: {
    type: String,
    default: '500px'
  },
  editorDisabled: {
    type: Boolean,
    default: false
  },
  editorLoading: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:modelValue'])

// Generate unique ID for checkbox IDs (to avoid conflicts when multiple panels on same page)
const componentId = ref(Math.random().toString(36).substring(7))

const availableAssistants = [
  { id: 'claude', label: 'Claude Code', description: "Anthropic's IDE-focused assistant." },
  { id: 'copilot', label: 'GitHub Copilot', description: 'Complements VS Code and JetBrains editors.' },
  { id: 'agents', label: 'Multi-Agent (OpenAI Codex, Cursor, etc.)', description: 'Shared instructions for multi-model orchestrators.' }
]

const normalize = () => ({
  enabled: props.modelValue?.enabled ?? false,
  canonical_file: props.modelValue?.canonical_file ?? 'CLAUDE.md',
  assistants: Array.isArray(props.modelValue?.assistants)
    ? props.modelValue.assistants
    : [],
  canonical_content: props.modelValue?.canonical_content ?? ''
})

const containerClasses = computed(() =>
  props.flush
    ? 'space-y-6'
    : 'rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 space-y-6'
)

const state = computed(normalize)

const emitUpdate = (patch) => {
  const base = normalize()
  const mergedAssistants = patch.assistants !== undefined
    ? patch.assistants
    : base.assistants

  emit('update:modelValue', {
    ...base,
    ...patch,
    assistants: mergedAssistants
  })
}

const toggleAssistant = (assistantId, value) => {
  const currentAssistants = [...state.value.assistants]

  if (value) {
    // Add if not already present
    if (!currentAssistants.includes(assistantId)) {
      currentAssistants.push(assistantId)
    }
  } else {
    // Remove if present
    const index = currentAssistants.indexOf(assistantId)
    if (index !== -1) {
      currentAssistants.splice(index, 1)
    }
  }

  emitUpdate({ assistants: currentAssistants })
}
</script>
