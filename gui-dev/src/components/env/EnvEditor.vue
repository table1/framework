<template>
  <div>
    <div v-if="error" class="mb-4">
      <Alert type="error" title="Error" :description="error" />
    </div>

    <div v-if="showSecurityAlert" class="mb-4">
      <Alert type="warning" title="⚠️ Contains Sensitive Data">
        This file can include passwords and secrets. Keep it out of version control.
        <template #actions>
          <Button
            v-if="viewMode === 'grouped' && allowShowValuesToggle"
            variant="soft"
            size="sm"
            @click="toggleGlobalVisibility"
          >
            {{ showEnvValues ? 'Hide Values' : 'Show Values' }}
          </Button>
        </template>
      </Alert>
    </div>

    <Tabs
      v-model="internalViewMode"
      :tabs="[
        { id: 'grouped', label: 'Key/Value Editor' },
        { id: 'raw', label: 'Raw .env' }
      ]"
      variant="pills"
      class="mb-4"
    />

    <div v-if="internalViewMode === 'grouped'" class="space-y-6">
      <div v-if="Object.keys(activeGroups).length === 0" class="rounded-lg bg-gray-50 p-8 text-center dark:bg-gray-800/40">
        <KeyIcon class="mx-auto mb-3 h-10 w-10 text-gray-400" />
        <p class="text-sm text-gray-500 dark:text-gray-400">No environment variables yet.</p>
        <Button v-if="allowAdd" variant="primary" class="mt-4" @click="addVariable">
          Add Variable
        </Button>
      </div>

      <div v-else class="space-y-5">
        <div
          v-for="(vars, prefix) in activeGroups"
          :key="prefix"
          class="rounded-lg bg-gray-50 p-5 dark:bg-gray-800/40"
        >
          <div class="mb-4">
            <p class="text-sm font-semibold text-gray-900 dark:text-white">
              {{ prefix === 'Other' ? 'Uncategorized' : prefix.toUpperCase() }}
            </p>
            <p class="text-xs text-gray-500 dark:text-gray-400">Variables with the {{ prefix }} prefix.</p>
          </div>

          <div class="space-y-3">
            <div
              v-for="(info, varName) in vars"
              :key="varName"
              class="space-y-2"
            >
              <div class="flex items-start gap-3">
                <div class="grid flex-1 grid-cols-2 gap-3">
                  <input
                    :value="varName"
                    @input="(e) => renameVariable(varName, e.target.value)"
                    type="text"
                    class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 font-mono text-sm uppercase text-gray-900 focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500 dark:border-gray-600 dark:bg-gray-900 dark:text-gray-100"
                    :disabled="loading"
                  />

                  <div class="relative">
                    <input
                      v-model="localVariables[varName]"
                      :type="isFieldVisible(varName) ? 'text' : 'password'"
                      :placeholder="info.defined ? 'value' : '(not set)'"
                      class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 font-mono text-sm text-gray-900 focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500 dark:border-gray-600 dark:bg-gray-900 dark:text-gray-100"
                      :disabled="loading"
                    />
                    <button
                      v-if="isPasswordField(varName) && allowShowValuesToggle"
                      type="button"
                      class="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-300"
                      @click="toggleFieldVisibility(varName)"
                    >
                      <EyeSlashIcon v-if="isFieldVisible(varName)" class="h-4 w-4" />
                      <EyeIcon v-else class="h-4 w-4" />
                    </button>
                  </div>
                </div>

                <button
                  v-if="allowRemove"
                  type="button"
                  class="mt-2 text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-300"
                  @click="removeVariable(varName)"
                >
                  <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
            </div>
          </div>

          <div v-if="allowAdd" class="mt-4">
            <Button variant="secondary" size="sm" @click="addVariable">
              + Add Variable
            </Button>
          </div>
        </div>
      </div>

      <div v-if="allowRegroupOption" class="rounded-lg border border-gray-200 bg-gray-50 p-4 text-sm dark:border-gray-700 dark:bg-gray-800/60">
        <Toggle
          v-model="internalRegroup"
          label="Regroup .env file by prefix when saving"
          description="Rewrites the file grouped by prefix and strips comments."
        />
      </div>
    </div>

    <div v-else class="space-y-3">
      <textarea
        v-model="localRaw"
        class="h-80 w-full rounded-md border border-gray-300 bg-white px-3 py-2 font-mono text-sm text-gray-900 focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500 dark:border-gray-600 dark:bg-gray-900 dark:text-gray-100"
        :disabled="loading"
      ></textarea>
      <p class="text-xs text-gray-500">Edit the .env file directly. Comments and formatting are preserved.</p>
    </div>

    <div v-if="showSaveButton" class="mt-4 flex justify-end">
      <Button :disabled="loading" variant="primary" @click="$emit('save')">
        {{ saveLabel }}
      </Button>
    </div>
  </div>
</template>

<script setup>
import { computed, ref, watch, nextTick } from 'vue'
import Alert from '../ui/Alert.vue'
import Button from '../ui/Button.vue'
import Tabs from '../ui/Tabs.vue'
import Badge from '../ui/Badge.vue'
import Toggle from '../ui/Toggle.vue'
import { EyeIcon, EyeSlashIcon, KeyIcon } from '@heroicons/vue/24/outline'

const props = defineProps({
  loading: { type: Boolean, default: false },
  error: { type: String, default: '' },
  showSecurityAlert: { type: Boolean, default: true },
  allowAdd: { type: Boolean, default: true },
  allowRemove: { type: Boolean, default: true },
  allowShowValuesToggle: { type: Boolean, default: true },
  allowRegroupOption: { type: Boolean, default: true },
  showSaveButton: { type: Boolean, default: true },
  saveLabel: { type: String, default: 'Save .env' },
  groups: { type: Object, default: () => ({}) },
  variables: { type: Object, default: () => ({}) },
  rawContent: { type: String, default: '' },
  viewMode: { type: String, default: 'grouped' },
  regroupOnSave: { type: Boolean, default: false }
})

const emit = defineEmits(['update:variables', 'update:rawContent', 'update:viewMode', 'update:regroupOnSave', 'save'])

const clone = (val) => JSON.parse(JSON.stringify(val || {}))

const localVariables = ref(clone(props.variables))
const localRaw = ref(props.rawContent || '')
const internalViewMode = ref(props.viewMode || 'grouped')
const internalRegroup = ref(!!props.regroupOnSave)
const showEnvValues = ref(false)
const visibleFields = ref({})
let syncingVariablesFromProps = false
let syncingRawFromProps = false

watch(
  () => props.variables,
  (val) => {
    syncingVariablesFromProps = true
    localVariables.value = clone(val)
    nextTick(() => {
      syncingVariablesFromProps = false
    })
  },
  { deep: true }
)

watch(
  () => props.rawContent,
  (val) => {
    syncingRawFromProps = true
    localRaw.value = val || ''
    nextTick(() => {
      syncingRawFromProps = false
    })
  },
  { immediate: true }
)

watch(
  () => props.viewMode,
  (val) => {
    internalViewMode.value = val || 'grouped'
  }
)

watch(
  () => props.regroupOnSave,
  (val) => {
    internalRegroup.value = !!val
  }
)

watch(localVariables, (val) => {
  if (syncingVariablesFromProps) return
  emit('update:variables', clone(val))
  if (internalViewMode.value !== 'raw') {
    // Smart update: preserve original order and structure (or regroup if enabled)
    localRaw.value = updateRawContentPreservingOrder(localRaw.value, val, internalRegroup.value)
    emit('update:rawContent', localRaw.value)
  }
}, { deep: true })

watch(localRaw, (val) => {
  if (syncingRawFromProps) return
  if (internalViewMode.value === 'raw') {
    emit('update:rawContent', val)
    const parsed = parseRaw(val)
    localVariables.value = parsed
    emit('update:variables', clone(parsed))
  }
})

watch(internalViewMode, (val, oldVal) => {
  emit('update:viewMode', val)
  // When switching TO raw mode, ensure localRaw is synced
  if (val === 'raw' && oldVal !== 'raw') {
    // Sync from variables if we have any
    if (Object.keys(localVariables.value).length > 0) {
      localRaw.value = updateRawContentPreservingOrder(localRaw.value, localVariables.value, internalRegroup.value)
    }
    // Or from props if localRaw is still empty
    else if (!localRaw.value && props.rawContent) {
      localRaw.value = props.rawContent
    }
  }
})

watch(internalRegroup, (val) => {
  emit('update:regroupOnSave', val)
})

const parseRaw = (raw) => {
  const lines = (raw || '').split(/\r?\n/)
  const result = {}
  lines.forEach((line) => {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith('#') || !trimmed.includes('=')) return
    const [key, ...rest] = trimmed.split('=')
    result[key.trim()] = rest.join('=').replace(/^"|"$/g, '')
  })
  return result
}

const buildGroupsFromVariables = (vars) => {
  const entries = Object.entries(vars || {})
  if (!entries.length) return {}
  return entries.reduce((acc, [key, value]) => {
    const prefix = key.includes('_') ? key.split('_')[0] : 'Other'
    if (!acc[prefix]) acc[prefix] = {}
    acc[prefix][key] = {
      defined: !!value,
      used: false,
      used_in: [],
      value
    }
    return acc
  }, {})
}

const activeGroups = computed(() => {
  const provided = props.groups || {}
  if (Object.keys(provided).length) {
    return provided
  }
  return buildGroupsFromVariables(localVariables.value)
})

const updateRawContentPreservingOrder = (rawContent, variables, shouldRegroup = false) => {
  // If regrouping is enabled, rebuild the entire file grouped by prefix
  if (shouldRegroup) {
    const grouped = {}
    for (const [key, value] of Object.entries(variables)) {
      const prefix = key.includes('_') ? key.split('_')[0] : 'Other'
      if (!grouped[prefix]) grouped[prefix] = []
      grouped[prefix].push([key, value])
    }

    const result = []
    const prefixes = Object.keys(grouped).sort()

    for (let i = 0; i < prefixes.length; i++) {
      const prefix = prefixes[i]
      const vars = grouped[prefix]

      // Add two blank lines between groups (but not before the first group)
      if (i > 0) {
        result.push('')
        result.push('')
      }

      result.push(`# ${prefix === 'Other' ? 'Other variables' : prefix.toUpperCase()}`)
      for (const [key, value] of vars) {
        result.push(`${key}=${value ?? ''}`)
      }
    }

    return result.join('\n')
  }

  // Otherwise, preserve the original order and do find-and-replace
  const lines = (rawContent || '').split(/\r?\n/)
  const updatedKeys = new Set()
  const result = []

  // First pass: update existing lines
  for (const line of lines) {
    const trimmed = line.trim()

    // Preserve comments and empty lines
    if (!trimmed || trimmed.startsWith('#') || !trimmed.includes('=')) {
      result.push(line)
      continue
    }

    // Parse the key and value
    const [key, ...valueParts] = trimmed.split('=')
    const cleanKey = key.trim()
    const originalValue = valueParts.join('=').trim()

    // If this key still exists in variables, update its value
    if (cleanKey in variables) {
      const value = variables[cleanKey] ?? ''
      result.push(`${cleanKey}=${value}`)
      updatedKeys.add(cleanKey)
    } else if (Object.keys(variables).length === 0 || originalValue === '') {
      // Preserve the line if:
      // 1. Variables object is empty (no edits made yet), OR
      // 2. Original value was empty (preserve empty variable declarations)
      result.push(line)
    }
    // Otherwise, skip this line (variable was explicitly removed by user)
  }

  // Second pass: add new variables that weren't in the original content
  // Group them by prefix and add with spacing
  const newVars = Object.entries(variables).filter(([key]) => !updatedKeys.has(key))

  if (newVars.length > 0) {
    // Group by prefix
    const grouped = {}
    for (const [key, value] of newVars) {
      const prefix = key.includes('_') ? key.split('_')[0] : 'Other'
      if (!grouped[prefix]) grouped[prefix] = []
      grouped[prefix].push([key, value])
    }

    // Add each group with spacing
    for (const [prefix, vars] of Object.entries(grouped)) {
      if (result.length > 0 && result[result.length - 1] !== '') {
        result.push('') // Add blank line before new group
        result.push('') // Two blank lines between groups
      }
      result.push(`# ${prefix === 'Other' ? 'Other variables' : prefix.toUpperCase()}`)
      for (const [key, value] of vars) {
        result.push(`${key}=${value ?? ''}`)
      }
    }
  }

  return result.join('\n')
}

const addVariable = () => {
  if (!props.allowAdd) return
  const base = 'NEW_VARIABLE'
  let idx = 1
  let candidate = `${base}_${idx}`
  while (localVariables.value[candidate]) {
    idx += 1
    candidate = `${base}_${idx}`
  }
  localVariables.value = { ...localVariables.value, [candidate]: '' }
}

const removeVariable = (key) => {
  if (!props.allowRemove) return
  const next = clone(localVariables.value)
  delete next[key]
  localVariables.value = next
}

const renameVariable = (oldKey, newKey) => {
  if (!newKey || oldKey === newKey) return
  const sanitized = newKey.replace(/[^A-Z0-9_]/gi, '').toUpperCase()
  if (!sanitized) return
  const next = clone(localVariables.value)
  if (next[sanitized]) return
  next[sanitized] = next[oldKey]
  delete next[oldKey]
  localVariables.value = next
}

const isPasswordField = (key) => {
  const markers = ['PASSWORD', 'SECRET', 'KEY', 'TOKEN']
  const upper = key.toUpperCase()
  return markers.some((marker) => upper.includes(marker))
}

const isFieldVisible = (key) => {
  return showEnvValues.value || visibleFields.value[key] || !isPasswordField(key)
}

const toggleFieldVisibility = (key) => {
  visibleFields.value[key] = !visibleFields.value[key]
}

const toggleGlobalVisibility = () => {
  showEnvValues.value = !showEnvValues.value
}
</script>
