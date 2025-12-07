<template>
  <Modal
    :model-value="modelValue"
    variant="left"
    size="lg"
    title="Edit Data Entry"
    @update:modelValue="(value) => emit('update:modelValue', value)"
  >
    <template v-if="entry || isCreateMode" #default>
      <div class="space-y-6">
        <div v-if="!isCreateMode">
          <p class="text-xs font-medium uppercase tracking-wide text-gray-500 dark:text-gray-400">
            Data Key
          </p>
          <p class="mt-1 font-mono text-sm text-gray-900 dark:text-gray-100 break-words">
            {{ entry.fullKey }}
          </p>
        </div>
        <div v-else>
          <Input
            v-model="form.fullKey"
            label="Dot Notation Key"
            placeholder="e.g., inputs.raw.custom_dataset"
            hint="Use dot notation to place this entry within the catalog hierarchy."
          />
        </div>

    <Input
      v-model="form.path"
      label="File Path"
      placeholder="inputs/raw/example.csv"
      required
      :error="pathFieldError"
      monospace
      hint="Provide a path relative to the project root (e.g., inputs/raw/data.csv) or an absolute path."
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
        {{ saving ? 'Saving…' : (isCreateMode ? 'Add Entry' : 'Save Entry') }}
      </Button>
    </template>
  </Modal>
</template>

<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue'
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
  mode: {
    type: String,
    default: 'edit',
    validator: (value) => ['edit', 'create'].includes(value)
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
  },
  projectId: {
    type: [String, Number],
    required: true
  },
  existingPaths: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits(['update:modelValue', 'save'])

const typeOptions = Object.freeze([
  { value: 'csv', label: 'CSV (comma-separated)' },
  { value: 'tsv', label: 'TSV (tab-separated)' },
  { value: 'csv_custom', label: 'Delimited text (custom)' },
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
const showValidationErrors = ref(false)
const isCreateMode = computed(() => props.mode === 'create')

const form = reactive({
  path: '',
  fullKey: '',
  type: '',
  description: '',
  delimiter: '',
  locked: false,
  additionalFields: []
})

const pickerFiles = ref([])
const pickerError = ref(null)
const pickerSearch = ref('')
const showPicker = ref(false)

const normalizedExistingPaths = computed(() => {
  const set = new Set()
  props.existingPaths.forEach((p) => {
    if (typeof p === 'string') {
      const norm = p.replace(/\\/g, '/').replace(/^\.\/+/, '').replace(/^\/+/, '').toLowerCase()
      set.add(norm)
    }
  })
  return set
})

const untrackedFiles = computed(() =>
  pickerFiles.value.filter((f) => {
    const norm = (f.path || '').replace(/\\/g, '/').replace(/^\.\/+/, '').replace(/^\/+/, '').toLowerCase()
    return norm && !normalizedExistingPaths.value.has(norm)
  })
)

const filteredFiles = computed(() => {
  const term = pickerSearch.value.trim().toLowerCase()
  const source = untrackedFiles.value
  if (!term) return source
  return source.filter((f) => f.path.toLowerCase().includes(term))
})

const shouldShowDelimiter = computed(() => form.type === 'csv_custom')

const deriveKeyFromPath = (path) => {
  if (!path) return ''
  let normalized = path.trim()
  normalized = normalized.replace(/\\/g, '/')
  normalized = normalized.replace(/^\.\/+/, '')
  normalized = normalized.replace(/^\/+/, '')
  normalized = normalized.replace(/\/+$/, '')
  normalized = normalized.replace(/\.[^./]+$/, '')
  normalized = normalized.replace(/\/+/g, '.')
  normalized = normalized.replace(/[^A-Za-z0-9._-]/g, '_')
  normalized = normalized.replace(/\.{2,}/g, '.')
  normalized = normalized.replace(/^\.|\.$/g, '')
  return normalized
}

const localError = computed(() => {
  if (!props.entry && !isCreateMode.value) return null
  const duplicateKeys = findDuplicateKeys()
  if (duplicateKeys.length > 0) {
    return `Duplicate metadata keys: ${duplicateKeys.join(', ')}`
  }
  return null
})

const pathError = computed(() => (!form.path.trim() ? 'File path is required' : null))
const pathFieldError = computed(() => {
  if (!isCreateMode.value) return pathError.value
  return showValidationErrors.value ? pathError.value : null
})

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
    if (isCreateMode.value && !form.fullKey.trim()) {
      form.fullKey = deriveKeyFromPath(newPath)
    }
    if (typeManuallySelected.value) return
    const guess = guessTypeFromPath(newPath)
    if (!guess) return
    if (guess.type === 'csv') {
      form.type = 'csv'
      form.delimiter = defaultDelimiterForType('csv')
    } else if (guess.type === 'tsv') {
      form.type = 'tsv'
      form.delimiter = defaultDelimiterForType('tsv')
    } else {
      form.type = guess.type
      form.delimiter = ''
    }
  }
)

watch(
  () => form.type,
  (newType) => {
    if (!newType) return
    if (newType === 'csv') {
      form.delimiter = defaultDelimiterForType('csv')
    } else if (newType === 'tsv') {
      form.delimiter = defaultDelimiterForType('tsv')
    } else if (newType !== 'csv_custom') {
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

function isStandardDelimiter (delimiter, type) {
  if (!delimiter) return false
  const normalized = delimiter.toLowerCase()
  if (type === 'csv') {
    return normalized === 'comma' || delimiter === ','
  }
  if (type === 'tsv') {
    return normalized === 'tab' || delimiter === '\t'
  }
  return false
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

  if (value === 'csv') {
    form.delimiter = defaultDelimiterForType('csv')
  } else if (value === 'tsv') {
    form.delimiter = defaultDelimiterForType('tsv')
  } else if (value === 'csv_custom') {
    form.delimiter = ''
  } else {
    form.delimiter = ''
  }
}

function initializeForm (entry) {
  resetForm()
  showValidationErrors.value = false
  pickerSearch.value = ''
  if (isCreateMode.value) {
    const data = entry?.data || {}
    form.fullKey = entry?.fullKey || ''
    form.path = data.path || ''
    form.type = data.type || ''
    form.description = data.description || ''
    form.locked = Boolean(data.locked)
    form.delimiter = data.delimiter || ''
    typeManuallySelected.value = false
    return
  }

  const data = entry.data || {}
  form.fullKey = entry.fullKey || ''
  form.path = data.path || ''
  const guessed = guessTypeFromPath(form.path)
  const rawType = data.type || guessed?.type || ''
  form.description = data.description || ''
  form.locked = Boolean(data.locked)

  if (rawType === 'csv') {
    const existingDelimiter = data.delimiter || guessed?.delimiter || defaultDelimiterForType('csv')
    if (isStandardDelimiter(existingDelimiter, 'csv')) {
      form.type = 'csv'
      form.delimiter = defaultDelimiterForType('csv')
    } else if (existingDelimiter) {
      form.type = 'csv_custom'
      form.delimiter = existingDelimiter
    } else {
      form.type = 'csv'
      form.delimiter = defaultDelimiterForType('csv')
    }
  } else if (rawType === 'tsv') {
    form.type = 'tsv'
    form.delimiter = defaultDelimiterForType('tsv')
  } else {
    form.type = rawType
    form.delimiter = shouldShowDelimiter.value ? (data.delimiter || '') : ''
  }

  if (!form.type && guessed?.type) {
    form.type = guessed.type
    form.delimiter = guessed.delimiter || defaultDelimiterForType(guessed.type)
  }

  typeManuallySelected.value = Boolean(data.type) || (form.type === 'csv_custom')

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

function togglePicker () {
  showPicker.value = !showPicker.value
}

function applyFileSelection (file) {
  form.path = file.path || ''
  const guess = guessTypeFromPath(file.path)
  if (file.type || guess?.type) {
    form.type = file.type || guess.type
    form.delimiter = guess?.delimiter || ''
  }
  if (isCreateMode.value) {
    form.fullKey = deriveKeyFromPath(file.path)
  }
  showPicker.value = false
}

function resetForm () {
  form.path = ''
  form.fullKey = ''
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
  const key = field.key.trim()
  if (!showValidationErrors.value && !key) return null
  if (!key) return 'Key is required'
  if (reservedKeys.includes(key)) return 'Reserved key name'
  if (form.additionalFields.some((other) => other !== field && other.key.trim() === key)) {
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
  showValidationErrors.value = true
  if (pathError.value || localError.value) return
  if (!isCreateMode.value && !props.entry) return

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

  const typeValue = form.type === 'csv_custom' ? 'csv' : form.type.trim()

  if (typeValue) {
    data.type = typeValue
  }

  if (form.description.trim()) {
    data.description = form.description.trim()
  }

  if (form.type === 'csv_custom') {
    if (!form.delimiter.trim()) {
      throw new Error('Delimiter is required for custom delimited text sources')
    }
    data.delimiter = form.delimiter.trim()
  } else if (form.delimiter.trim() && !isStandardDelimiter(form.delimiter.trim(), form.type)) {
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

  let fullKey = (isCreateMode.value ? form.fullKey : props.entry.fullKey || '').trim()

  if (isCreateMode.value && !fullKey) {
    fullKey = deriveKeyFromPath(form.path)
  }

  if (!fullKey) {
    throw new Error('Dot notation key is required')
  }

  return {
    fullKey,
    data,
    isNew: isCreateMode.value
  }
}

onMounted(async () => {
  try {
    const res = await fetch(`/api/project/${props.projectId}/inputs`)
    const json = await res.json()
    if (!res.ok || json.error) {
      pickerError.value = json.error || 'Failed to load inputs'
      return
    }
    pickerFiles.value = Array.isArray(json.files) ? json.files : []
  } catch (err) {
    pickerError.value = err?.message || 'Failed to load inputs'
  }
})
</script>
