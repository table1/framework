<template>
  <Modal
    :model-value="modelValue"
    variant="left"
    size="lg"
    title="Edit Data Entry"
    @update:modelValue="(value) => emit('update:modelValue', value)"
  >
    <template v-if="entry" #default>
      <div class="space-y-6">
        <div>
          <p class="text-xs font-medium uppercase tracking-wide text-gray-500 dark:text-gray-400">
            Data Key
          </p>
          <p class="mt-1 font-mono text-sm text-gray-900 dark:text-gray-100 break-words">
            {{ entry.fullKey }}
          </p>
        </div>

        <Input
          v-model="form.path"
          label="File Path"
          placeholder="inputs/raw/example.csv"
          required
          :error="pathError"
          monospace
        />

        <div class="grid gap-4 sm:grid-cols-2">
          <Select
            :model-value="form.type"
            label="Type"
            @update:modelValue="handleTypeChange"
          >
            <option disabled value="">Select file type</option>
            <option
              v-for="option in typeOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </Select>

          <div class="sm:col-span-2">
            <Toggle
              v-model="form.locked"
              label="Locked"
              description="Treat this data source as read-only."
            />
          </div>

          <div v-if="shouldShowDelimiter" class="sm:col-span-2">
            <Input
              v-model="form.delimiter"
              label="Delimiter"
              placeholder="e.g., tab or |"
              hint="Use keywords 'tab', 'comma', 'semicolon', 'space' or supply a single character (e.g., |). Keywords map to their respective delimiters."
            />
          </div>
        </div>

        <Textarea
          v-model="form.description"
          label="Description"
          placeholder="Explain what this source contains or how it was produced."
          :rows="4"
        />

        <div class="space-y-3">
          <div class="flex items-center justify-between">
            <h4 class="text-sm font-semibold text-gray-900 dark:text-gray-100">
              Additional Metadata
            </h4>
            <Button
              size="sm"
              variant="secondary"
              class="shadow-none"
              @click="addField"
            >
              Add Field
            </Button>
          </div>
          <p class="text-xs text-gray-500 dark:text-gray-400">
            Store any extra properties (e.g., source, codebook details). Complex values can be provided as JSON.
          </p>

          <div v-if="form.additionalFields.length === 0" class="rounded-md border border-dashed border-gray-300 p-4 text-sm text-gray-500 dark:border-gray-600 dark:text-gray-400">
            No additional metadata fields.
          </div>

          <div
            v-for="field in form.additionalFields"
            :key="field.id"
            class="rounded-md border border-gray-200 bg-white/80 p-4 dark:border-gray-700 dark:bg-gray-900/40"
          >
            <div class="grid gap-3 sm:grid-cols-[1fr_auto] sm:items-start">
              <Input
                v-model="field.key"
                label="Key"
                placeholder="e.g., source"
                :error="fieldError(field)"
              />
              <Button
                size="sm"
                variant="secondary"
                class="shadow-none"
                @click="removeField(field.id)"
              >
                Remove
              </Button>
          </div>

          <div class="mt-3">
            <component
              :is="field.isMultiline ? Textarea : Input"
              v-model="field.valueInput"
              :label="field.isMultiline ? 'Value (JSON)' : 'Value'"
              :rows="field.isMultiline ? 4 : undefined"
              :placeholder="field.isMultiline ? sampleJsonPlaceholder : 'comma'"
              :monospace="!field.isMultiline ? false : undefined"
            />
            <p v-if="field.isMultiline" class="mt-2 text-xs text-gray-500 dark:text-gray-400">
              Provide valid JSON to store complex data structures.
            </p>
            <div class="mt-2 flex justify-end">
              <Button
                size="xs"
                variant="soft"
                @click="toggleFieldMode(field)"
              >
                {{ field.isMultiline ? 'Use single-line value' : 'Use JSON value' }}
              </Button>
            </div>
          </div>
        </div>
        </div>

        <p v-if="localError" class="text-sm text-red-600 dark:text-red-400">
          {{ localError }}
        </p>
        <p v-if="parseError" class="text-sm text-red-600 dark:text-red-400">
          {{ parseError }}
        </p>
        <p v-if="error" class="text-sm text-red-600 dark:text-red-400">
          {{ error }}
        </p>
      </div>
    </template>

    <template v-if="entry" #actions>
      <Button
        size="sm"
        variant="secondary"
        class="shadow-none"
        @click="emit('update:modelValue', false)"
      >
        Cancel
      </Button>
      <Button
        size="sm"
        :disabled="saving"
        @click="handleSave"
      >
        {{ saving ? 'Saving…' : 'Save Entry' }}
      </Button>
    </template>
  </Modal>
</template>

<script setup>
import { computed, reactive, ref, watch } from 'vue'
import Button from './ui/Button.vue'
import Input from './ui/Input.vue'
import Modal from './ui/Modal.vue'
import Select from './ui/Select.vue'
import Textarea from './ui/Textarea.vue'
import Toggle from './ui/Toggle.vue'

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  entry: {
    type: Object,
    default: null
  },
  saving: {
    type: Boolean,
    default: false
  },
  error: {
    type: String,
    default: null
  }
})

const emit = defineEmits(['update:modelValue', 'save'])

const typeOptions = Object.freeze([
  { value: 'csv', label: 'CSV (comma-separated)' },
  { value: 'tsv', label: 'TSV (tab-separated)' },
  { value: 'rds', label: 'RDS (R serialized)' },
  { value: 'excel', label: 'Excel (.xlsx / .xls)' },
  { value: 'stata', label: 'Stata (.dta)' },
  { value: 'spss', label: 'SPSS (.sav / .zsav)' },
  { value: 'spss_por', label: 'SPSS Portable (.por)' },
  { value: 'sas', label: 'SAS (.sas7bdat / .sas7bcat)' },
  { value: 'sas_xpt', label: 'SAS Transport (.xpt)' }
])

const reservedKeys = ['path', 'type', 'description', 'locked', 'delimiter']
const sampleJsonPlaceholder = '{"source": "data-catalog"}'

const parseError = ref(null)
const typeManuallySelected = ref(false)

const form = reactive({
  path: '',
  type: '',
  description: '',
  delimiter: '',
  locked: false,
  additionalFields: []
})

const shouldShowDelimiter = computed(() => form.type && !['csv', 'tsv'].includes(form.type))

const localError = computed(() => {
  if (!props.entry) return null
  const duplicateKeys = findDuplicateKeys()
  if (duplicateKeys.length > 0) {
    return `Duplicate metadata keys: ${duplicateKeys.join(', ')}`
  }
  if (form.additionalFields.some((field) => !field.key.trim())) {
    return 'Metadata keys cannot be empty.'
  }
  return null
})

const pathError = computed(() => (!form.path.trim() ? 'File path is required' : null))

watch(
  () => props.entry,
  (entry) => {
    if (!entry) {
      resetForm()
      return
    }
    initializeForm(entry)
  },
  { immediate: true }
)

watch(
  () => form.path,
  (newPath) => {
    const guess = guessTypeFromPath(newPath)
    if (!guess) return
    if (!typeManuallySelected.value || !form.type) {
      form.type = guess.type
    }
    if (!shouldShowDelimiter.value || !form.delimiter) {
      form.delimiter = guess.delimiter || defaultDelimiterForType(form.type)
    }
  }
)

watch(
  () => form.type,
  (newType) => {
    if (!newType) return
    if (['csv', 'tsv'].includes(newType)) {
      form.delimiter = defaultDelimiterForType(newType)
    } else if (!shouldShowDelimiter.value) {
      form.delimiter = ''
    }
  }
)

function generateId () {
  return `field-${Math.random().toString(36).slice(2, 9)}`
}

function defaultDelimiterForType (type) {
  if (type === 'csv') return 'comma'
  if (type === 'tsv') return 'tab'
  return ''
}

function guessTypeFromPath (path) {
  if (!path) return null
  const lower = path.toLowerCase()
  if (lower.endsWith('.csv')) return { type: 'csv', delimiter: 'comma' }
  if (lower.endsWith('.tsv') || lower.endsWith('.txt') || lower.endsWith('.dat')) {
    return { type: 'tsv', delimiter: 'tab' }
  }
  if (lower.endsWith('.rds')) return { type: 'rds', delimiter: '' }
  if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) return { type: 'excel', delimiter: '' }
  if (lower.endsWith('.dta')) return { type: 'stata', delimiter: '' }
  if (lower.endsWith('.sav') || lower.endsWith('.zsav')) return { type: 'spss', delimiter: '' }
  if (lower.endsWith('.por')) return { type: 'spss_por', delimiter: '' }
  if (lower.endsWith('.sas7bdat') || lower.endsWith('.sas7bcat')) return { type: 'sas', delimiter: '' }
  if (lower.endsWith('.xpt')) return { type: 'sas_xpt', delimiter: '' }
  return null
}

function handleTypeChange (value) {
  if (!value) {
    form.type = ''
    form.delimiter = ''
    typeManuallySelected.value = false
    return
  }
  form.type = value
  typeManuallySelected.value = true
  if (['csv', 'tsv'].includes(value)) {
    form.delimiter = defaultDelimiterForType(value)
  } else if (!form.delimiter || ['csv', 'tsv'].includes(form.type)) {
    form.delimiter = ''
  }
}

function initializeForm (entry) {
  resetForm()
  const data = entry.data || {}
  form.path = data.path || ''
  const guessed = guessTypeFromPath(form.path)
  form.type = data.type || guessed?.type || ''
  form.description = data.description || ''
  form.locked = Boolean(data.locked)
  form.delimiter = data.delimiter || guessed?.delimiter || defaultDelimiterForType(form.type)
  typeManuallySelected.value = Boolean(data.type)

  const extraFields = Object.entries(data)
    .filter(([key]) => !reservedKeys.includes(key))
    .map(([key, value]) => ({
      id: generateId(),
      key,
      valueInput: formatFieldValue(value),
      valueType: detectValueType(value),
      isMultiline: typeof value === 'object' && value !== null
    }))

  form.additionalFields = extraFields
  parseError.value = null
}

function resetForm () {
  form.path = ''
  form.type = ''
  form.description = ''
  form.delimiter = ''
  form.locked = false
  form.additionalFields = []
  parseError.value = null
  typeManuallySelected.value = false
}

function formatFieldValue (value) {
  if (typeof value === 'object' && value !== null) {
    try {
      return JSON.stringify(value, null, 2)
    } catch (err) {
      return ''
    }
  }
  return value == null ? '' : String(value)
}

function detectValueType (value) {
  if (Array.isArray(value) || (typeof value === 'object' && value !== null)) return 'object'
  if (typeof value === 'boolean') return 'boolean'
  if (typeof value === 'number') return 'number'
  return 'string'
}

function parseFieldValue (field) {
  if (field.valueType === 'object') {
    if (!field.valueInput.trim()) return null
    try {
      return JSON.parse(field.valueInput)
    } catch (err) {
      throw new Error(`Invalid JSON for field "${field.key}"`)
    }
  }

  if (field.valueType === 'number') {
    const parsed = Number(field.valueInput)
    if (Number.isNaN(parsed)) {
      throw new Error(`Value for "${field.key}" must be a number`)
    }
    return parsed
  }

  if (field.valueType === 'boolean') {
    const normalized = field.valueInput.trim().toLowerCase()
    if (['true', 'false'].includes(normalized)) {
      return normalized === 'true'
    }
    throw new Error(`Value for "${field.key}" must be "true" or "false"`)
  }

  return field.valueInput
}

function findDuplicateKeys () {
  const seen = new Set()
  const duplicates = []

  form.additionalFields.forEach((field) => {
    const key = field.key.trim()
    if (!key) return

    if (seen.has(key) || reservedKeys.includes(key)) {
      duplicates.push(key)
    } else {
      seen.add(key)
    }
  })

  return duplicates
}

function fieldError (field) {
  if (!field.key.trim()) return 'Key is required'
  if (reservedKeys.includes(field.key.trim())) return 'Reserved key name'
  if (form.additionalFields.some((other) => other !== field && other.key.trim() === field.key.trim())) {
    return 'Duplicate key'
  }
  return null
}

function addField () {
  form.additionalFields.push({
    id: generateId(),
    key: '',
    valueInput: '',
    valueType: 'string',
    isMultiline: false
  })
  parseError.value = null
}

function removeField (id) {
  form.additionalFields = form.additionalFields.filter((field) => field.id !== id)
}

function toggleFieldMode (field) {
  field.isMultiline = !field.isMultiline
  if (field.isMultiline) {
    field.valueType = 'object'
    if (field.valueInput && !field.valueInput.trim().startsWith('{')) {
      field.valueInput = ''
    }
  } else {
    field.valueType = 'string'
    field.valueInput = field.valueInput != null ? String(field.valueInput) : ''
  }
}

const handleSave = () => {
  parseError.value = null
  if (pathError.value || localError.value) return
  if (!props.entry) return

  try {
    const payload = buildPayload()
    emit('save', payload)
  } catch (err) {
    parseError.value = err.message
  }
}

const buildPayload = () => {
  if (!form.path.trim()) {
    throw new Error('File path is required')
  }

  const data = {}
  data.path = form.path.trim()

  if (form.type.trim()) {
    data.type = form.type.trim()
  }

  if (form.description.trim()) {
    data.description = form.description.trim()
  }

  if (form.delimiter.trim()) {
    data.delimiter = form.delimiter.trim()
  }

  if (form.locked) {
    data.locked = true
  }

  for (const field of form.additionalFields) {
    const key = field.key.trim()
    if (!key || reservedKeys.includes(key)) {
      continue
    }
    const value = parseFieldValue({
      ...field,
      valueType: field.valueType ?? 'string'
    })
    if (value === null || value === '') {
      continue
    }
    data[key] = value
  }

  return {
    fullKey: props.entry.fullKey,
    data
  }
}
</script>
