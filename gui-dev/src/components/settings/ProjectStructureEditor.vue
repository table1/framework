<template>
  <div class="space-y-6">
    <!-- Project-specific settings (if catalog defines any) -->
    <SettingsPanel
      v-if="projectTypeSettings.length > 0"
      title="Project Settings"
      description="Default settings applied when creating new projects of this type."
    >
      <SettingsBlock>
        <div class="space-y-5">
          <template v-for="setting in projectTypeSettings" :key="setting.id">
            <Toggle
              v-if="setting.control === 'toggle'"
              :model-value="localSettings[setting.id]"
              @update:model-value="updateSetting(setting.id, $event)"
              :label="setting.label"
              :description="setting.description"
              :disabled="disabled"
            />
            <Select
              v-else-if="setting.control === 'select'"
              :model-value="localSettings[setting.id]"
              @update:model-value="updateSetting(setting.id, $event)"
              :label="setting.label"
              :hint="setting.hint"
            >
              <option v-for="opt in setting.options" :key="opt.value" :value="opt.value">
                {{ opt.label }}
              </option>
            </Select>
            <Input
              v-else-if="setting.control === 'text'"
              :model-value="localSettings[setting.id]"
              @update:model-value="updateSetting(setting.id, $event)"
              :label="setting.label"
              :hint="setting.hint"
              :placeholder="setting.placeholder"
            />
          </template>
        </div>
      </SettingsBlock>
    </SettingsPanel>

    <!-- Quick navigation -->
    <div class="flex flex-wrap items-center justify-between gap-3">
      <div class="flex flex-wrap gap-2 text-xs font-medium text-gray-600 dark:text-gray-400">
        <button
          v-if="isPresentationProject"
          type="button"
          class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
          @click="scrollToSection('primary-files')"
        >
          Primary Files
        </button>
        <button
          v-if="isPresentationProject"
          type="button"
          class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
          @click="scrollToSection('optional-directories')"
        >
          Optional Directories
        </button>
        <button
          v-if="isCourseProject"
          type="button"
          class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
          @click="scrollToSection('materials')"
        >
          Materials
        </button>
        <button
          v-if="!isPresentationProject && !isCourseProject && inputFields.length > 0"
          type="button"
          class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
          @click="scrollToSection('inputs')"
        >
          Inputs
        </button>
        <button
          v-if="!isPresentationProject && !isCourseProject && workspaceFields.length > 0"
          type="button"
          class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
          @click="scrollToSection('workspaces')"
        >
          Workspaces
        </button>
        <button
          v-if="!isPresentationProject && !isCourseProject && outputFields.length > 0"
          type="button"
          class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
          @click="scrollToSection('outputs')"
        >
          Outputs
        </button>
        <button
          v-if="!isPresentationProject && !isCourseProject && utilityFields.length > 0"
          type="button"
          class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
          @click="scrollToSection('utility')"
        >
          Utility
        </button>
        <button
          type="button"
          class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
          @click="scrollToSection('gitignore')"
        >
          .gitignore
        </button>
      </div>
      <Button v-if="!disabled && allowDestruction" variant="secondary" size="sm" class="mt-3 sm:mt-0" @click="$emit('reset')">
        Reset to Defaults
      </Button>
    </div>

    <!-- Presentation Primary Files -->
    <div v-if="isPresentationProject" :id="`section-primary-files`">
      <SettingsPanel
        title="Primary Files"
        description="The main presentation file and where rendered slides are output."
      >
        <div class="space-y-4">
          <Input
            :model-value="localDirectories.presentation_source"
            @update:model-value="updateDirectory('presentation_source', $event)"
            label="Presentation source file"
            placeholder="presentation.qmd"
            hint="Main Quarto file for your slides"
            :disabled="disabled"
          />
          <Input
            :model-value="localDirectories.rendered_slides"
            @update:model-value="updateDirectory('rendered_slides', $event)"
            label="Rendered slides directory"
            placeholder="."
            hint="Rendered slides write to the project root by default (.)"
            prefix="/"
            monospace
            :disabled="disabled"
          />
        </div>
      </SettingsPanel>
    </div>

    <!-- Presentation Optional Directories -->
    <div v-if="isPresentationProject" :id="`section-optional-directories`">
      <SettingsPanel
        title="Optional Directories"
        description="Toggle extra scaffolding when you need supporting data, scripts, or helper utilities."
      >
        <div class="space-y-4">
          <div class="space-y-2">
            <Toggle
              :model-value="localEnabled.data"
              @update:model-value="updateEnabled('data', $event)"
              label="Include data directory"
              description="Adds a /data folder for sample data used in the presentation."
              :disabled="isToggleDisabled('data')"
            />
            <Input
              v-if="localEnabled.data"
              :model-value="getDirectoryValue('data')"
              @update:model-value="updateDirectory('data', $event)"
              prefix="/"
              monospace
              :disabled="disabled"
            />
          </div>

          <div class="space-y-2">
            <Toggle
              :model-value="localEnabled.scripts"
              @update:model-value="updateEnabled('scripts', $event)"
              label="Include scripts directory"
              description="Adds a scripts/ folder for demo code or automation."
              :disabled="isToggleDisabled('scripts')"
            />
            <Input
              v-if="localEnabled.scripts"
              :model-value="getDirectoryValue('scripts')"
              @update:model-value="updateDirectory('scripts', $event)"
              prefix="/"
              monospace
              :disabled="disabled"
            />
          </div>

          <div class="space-y-2">
            <Toggle
              :model-value="localEnabled.functions"
              @update:model-value="updateEnabled('functions', $event)"
              label="Include functions directory"
              description="Adds functions/ for helper utilities that should load automatically."
              :disabled="isToggleDisabled('functions')"
            />
            <Input
              v-if="localEnabled.functions"
              :model-value="getDirectoryValue('functions')"
              @update:model-value="updateDirectory('functions', $event)"
              prefix="/"
              monospace
              :disabled="disabled"
            />
          </div>

          <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
            <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Add Custom Directories</h4>
            <Repeater
              v-if="!disabled"
              :model-value="extraDirectoriesByType('workspace')"
              @update:model-value="updateNewExtras('workspace', $event)"
              add-label="Add Directory"
              :default-item="() => ({ key: '', label: '', path: '', type: 'workspace', _id: Date.now() })"
            >
              <template #default="{ item, update }">
                <div class="grid grid-cols-2 gap-3">
                  <Input
                    :model-value="item.key"
                    @update:model-value="update('key', $event)"
                    label="Key"
                    placeholder="e.g., assets"
                    monospace
                    size="sm"
                  />
                  <Input
                    :model-value="item.label"
                    @update:model-value="update('label', $event)"
                    label="Label"
                    placeholder="e.g., Assets"
                    size="sm"
                  />
                  <Input
                    :model-value="item.path"
                    @update:model-value="update('path', $event)"
                    label="Path"
                    placeholder="e.g., assets"
                    prefix="/"
                    monospace
                    size="sm"
                    class="col-span-2"
                  />
                </div>
              </template>
            </Repeater>
          </div>
        </div>
      </SettingsPanel>
    </div>

    <!-- Course Materials -->
    <div v-if="isCourseProject" :id="`section-materials`">
      <CourseDirectoriesPanel
        :directories-enabled="localEnabled"
        @update:directories-enabled="(val) => { localEnabled = val; emit('update:enabled', val) }"
        :directories="localDirectories"
        @update:directories="(val) => { localDirectories = val; emit('update:directories', val) }"
        :render-dirs="localRenderDirs"
        @update:render-dirs="(val) => { localRenderDirs = val; emit('update:renderDirs', val) }"
        :catalog="catalog"
        :extra-directories="extraDirectories.filter(d => d.type === 'course')"
        :extra-directories-enabled="{}"
        @update:extra-directories-enabled="() => {}"
        :project-custom-directories="[]"
        @update:project-custom-directories="() => {}"
        :allow-custom-directories="false"
        :flush="false"
      />
    </div>

    <!-- Inputs Section -->
    <div v-if="!isPresentationProject && !isCourseProject && inputFields.length > 0" :id="`section-inputs`">
      <SettingsPanel
        title="Inputs"
        :description="isSensitiveProject ? 'Keep private inputs compartmentalized; publish processed outputs into public folders when ready.' : 'Define the read-only locations where raw and prepared data live.'"
      >
        <!-- Privacy Sensitive: Private/Public Split -->
        <div v-if="isSensitiveProject">
          <div class="grid gap-4 sm:grid-cols-2 text-xs font-semibold uppercase text-gray-500 dark:text-gray-400 mb-4">
            <div>Private</div>
            <div>Public</div>
          </div>

          <div class="space-y-5">
            <div v-for="pair in inputFields" :key="pair.privateKey" class="grid gap-4 sm:grid-cols-2">
              <div class="space-y-2">
                <Toggle
                  :model-value="localEnabled[pair.privateKey]"
                  @update:model-value="updateEnabled(pair.privateKey, $event)"
                  :label="pair.privateLabel"
                  :disabled="isToggleDisabled(pair.privateKey)"
                />
                <Input
                  v-if="localEnabled[pair.privateKey] !== false"
                  :model-value="getDirectoryValue(pair.privateKey)"
                  @update:model-value="updateDirectory(pair.privateKey, $event)"
                  prefix="/"
                  monospace
                  :disabled="disabled"
                />
              </div>
              <div class="space-y-2">
                <Toggle
                  :model-value="localEnabled[pair.publicKey]"
                  @update:model-value="updateEnabled(pair.publicKey, $event)"
                  :label="pair.publicLabel"
                  :disabled="isToggleDisabled(pair.publicKey)"
                />
                <Input
                  v-if="localEnabled[pair.publicKey] !== false"
                  :model-value="getDirectoryValue(pair.publicKey)"
                  @update:model-value="updateDirectory(pair.publicKey, $event)"
                  prefix="/"
                  monospace
                  :disabled="disabled"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- Standard: Flat List -->
        <div v-else class="space-y-5">
          <div v-for="field in inputFields" :key="field.key" class="space-y-1.5">
            <Toggle
              :model-value="localEnabled[field.key]"
              @update:model-value="updateEnabled(field.key, $event)"
              :label="field.label"
              :description="field.hint"
              :disabled="isToggleDisabled(field.key)"
            />
            <Input
              v-if="localEnabled[field.key] !== false"
              :model-value="getDirectoryValue(field.key)"
              @update:model-value="updateDirectory(field.key, $event)"
              prefix="/"
              monospace
              :disabled="disabled"
            />
          </div>
        </div>

        <!-- Additional Input Directories -->
        <div v-if="savedInputExtras.length > 0 || true" class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
          <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Additional Input Directories</h4>

          <!-- Saved extra directories -->
          <div v-if="savedInputExtras.length > 0" class="space-y-3 mb-4">
            <div v-for="dir in savedInputExtras" :key="dir.key" class="space-y-1.5">
              <Toggle
                :model-value="localEnabled[dir.key]"
                @update:model-value="updateEnabled(dir.key, $event)"
                :label="dir.label"
                :disabled="isToggleDisabled(dir.key)"
              />
              <Input
                v-if="localEnabled[dir.key] !== false"
                :model-value="dir.path"
                @update:model-value="updateExtraDirectoryPath(dir.key, $event)"
                prefix="/"
                monospace
              :disabled="disabled"
              />
            </div>
          </div>

          <!-- New directories repeater -->
          <Repeater
            v-if="!disabled"
            :model-value="newInputExtras"
            @update:model-value="updateNewExtras('input', $event)"
            addLabel="Add Input Directory"
            :defaultItem="() => ({ key: '', label: '', path: '', type: 'input', _id: Date.now() })"
          >
            <template #default="{ item, update }">
              <div class="space-y-3">
                <Input
                  :model-value="item.key"
                  @update:model-value="update('key', $event)"
                  label="Key"
                  placeholder="inputs_archive"
                  hint="Unique identifier (alphanumeric and underscores)"
                />
                <Input
                  :model-value="item.label"
                  @update:model-value="update('label', $event)"
                  label="Label"
                  placeholder="Archive"
                />
                <Input
                  :model-value="item.path"
                  @update:model-value="update('path', $event)"
                  label="Path"
                  prefix="/"
                  placeholder="inputs/archive"
                  monospace
              :disabled="disabled"
                />
              </div>
            </template>
          </Repeater>
        </div>
      </SettingsPanel>
    </div>

    <!-- Workspaces Section -->
    <div v-if="!isPresentationProject && !isCourseProject && workspaceFields.length > 0" :id="`section-workspaces`">
      <SettingsPanel
        title="Workspaces"
        description="Functions, notebooks, and scripts scaffolded into every project."
      >
        <div class="space-y-5">
          <!-- Renderable directories (notebooks, docs) - 2 column layout -->
          <div v-for="field in workspaceRenderableFields" :key="field.key" class="space-y-1.5">
            <Toggle
              :model-value="localEnabled[field.key]"
              @update:model-value="updateEnabled(field.key, $event)"
              :label="field.label"
              :description="field.hint"
              :disabled="isToggleDisabled(field.key)"
            />
            <div v-if="localEnabled[field.key] !== false" class="grid grid-cols-2 gap-3">
              <Input
                :model-value="getDirectoryValue(field.key)"
                @update:model-value="updateDirectory(field.key, $event)"
                label="Source files"
                prefix="/"
                monospace
              :disabled="disabled"
              />
              <Input
                :model-value="localRenderDirs[field.key]"
                @update:model-value="updateRenderDir(field.key, $event)"
                label="Quarto render directory"
                prefix="/"
                monospace
              :disabled="disabled"
              />
            </div>
          </div>

          <!-- Non-renderable directories (functions, scripts) - single column -->
          <div v-for="field in workspaceNonRenderableFields" :key="field.key" class="space-y-1.5">
            <Toggle
              :model-value="localEnabled[field.key]"
              @update:model-value="updateEnabled(field.key, $event)"
              :label="field.label"
              :description="field.hint"
              :disabled="isToggleDisabled(field.key)"
            />
            <Input
              v-if="localEnabled[field.key] !== false"
              :model-value="getDirectoryValue(field.key)"
              @update:model-value="updateDirectory(field.key, $event)"
              prefix="/"
              monospace
              :disabled="disabled"
            />
          </div>
        </div>

        <!-- Additional Workspace Directories -->
        <div v-if="savedWorkspaceExtras.length > 0 || true" class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
          <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Additional Workspace Directories</h4>

          <!-- Saved extra directories -->
          <div v-if="savedWorkspaceExtras.length > 0" class="space-y-3 mb-4">
            <div v-for="dir in savedWorkspaceExtras" :key="dir.key" class="space-y-1.5">
              <Toggle
                :model-value="localEnabled[dir.key]"
                @update:model-value="updateEnabled(dir.key, $event)"
                :label="dir.label"
                :disabled="isToggleDisabled(dir.key)"
              />
              <Input
                v-if="localEnabled[dir.key] !== false"
                :model-value="dir.path"
                @update:model-value="updateExtraDirectoryPath(dir.key, $event)"
                prefix="/"
                monospace
              :disabled="disabled"
              />
            </div>
          </div>

          <!-- New directories repeater -->
          <Repeater
            v-if="!disabled"
            :model-value="newWorkspaceExtras"
            @update:model-value="updateNewExtras('workspace', $event)"
            addLabel="Add Workspace Directory"
            :defaultItem="() => ({ key: '', label: '', path: '', type: 'workspace', _id: Date.now() })"
          >
            <template #default="{ item, update }">
              <div class="space-y-3">
                <Input
                  :model-value="item.key"
                  @update:model-value="update('key', $event)"
                  label="Key"
                  placeholder="templates"
                  hint="Unique identifier (alphanumeric and underscores)"
                />
                <Input
                  :model-value="item.label"
                  @update:model-value="update('label', $event)"
                  label="Label"
                  placeholder="Templates"
                />
                <Input
                  :model-value="item.path"
                  @update:model-value="update('path', $event)"
                  label="Path"
                  prefix="/"
                  placeholder="templates"
                  monospace
              :disabled="disabled"
                />
              </div>
            </template>
          </Repeater>
        </div>
      </SettingsPanel>
    </div>

    <!-- Outputs Section -->
    <div v-if="!isPresentationProject && !isCourseProject && outputFields.length > 0" :id="`section-outputs`">
      <SettingsPanel
        title="Outputs"
        :description="isSensitiveProject ? 'Review outputs before promotion; private folders remain gitignored while public copies are ready to share.' : 'Results, figures, models, and reports generated by your analysis.'"
      >
        <!-- Privacy Sensitive: Private/Public Split -->
        <div v-if="isSensitiveProject">
          <div class="grid gap-4 sm:grid-cols-2 text-xs font-semibold uppercase text-gray-500 dark:text-gray-400 mb-4">
            <div>Private</div>
            <div>Public</div>
          </div>

          <div class="space-y-5">
            <div v-for="pair in outputFields" :key="pair.privateKey" class="grid gap-4 sm:grid-cols-2">
              <div class="space-y-2">
                <Toggle
                  :model-value="localEnabled[pair.privateKey]"
                  @update:model-value="updateEnabled(pair.privateKey, $event)"
                  :label="pair.privateLabel"
                  :disabled="isToggleDisabled(pair.privateKey)"
                />
                <Input
                  v-if="localEnabled[pair.privateKey] !== false"
                  :model-value="getDirectoryValue(pair.privateKey)"
                  @update:model-value="updateDirectory(pair.privateKey, $event)"
                  prefix="/"
                  monospace
                  :disabled="disabled"
                />
              </div>
              <div class="space-y-2">
                <Toggle
                  :model-value="localEnabled[pair.publicKey]"
                  @update:model-value="updateEnabled(pair.publicKey, $event)"
                  :label="pair.publicLabel"
                  :disabled="isToggleDisabled(pair.publicKey)"
                />
                <Input
                  v-if="localEnabled[pair.publicKey] !== false"
                  :model-value="getDirectoryValue(pair.publicKey)"
                  @update:model-value="updateDirectory(pair.publicKey, $event)"
                  prefix="/"
                  monospace
                  :disabled="disabled"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- Standard: Flat List -->
        <div v-else class="space-y-5">
          <div v-for="field in outputFields" :key="field.key" class="space-y-1.5">
            <Toggle
              :model-value="localEnabled[field.key]"
              @update:model-value="updateEnabled(field.key, $event)"
              :label="field.label"
              :description="field.hint"
              :disabled="isToggleDisabled(field.key)"
            />
            <Input
              v-if="localEnabled[field.key] !== false"
              :model-value="getDirectoryValue(field.key)"
              @update:model-value="updateDirectory(field.key, $event)"
              prefix="/"
              monospace
              :disabled="disabled"
            />
          </div>
        </div>

        <!-- Additional Output Directories -->
        <div v-if="savedOutputExtras.length > 0 || true" class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
          <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Additional Output Directories</h4>

          <!-- Saved extra directories -->
          <div v-if="savedOutputExtras.length > 0" class="space-y-3 mb-4">
            <div v-for="dir in savedOutputExtras" :key="dir.key" class="space-y-1.5">
              <Toggle
                :model-value="localEnabled[dir.key]"
                @update:model-value="updateEnabled(dir.key, $event)"
                :label="dir.label"
                :disabled="isToggleDisabled(dir.key)"
              />
              <Input
                v-if="localEnabled[dir.key] !== false"
                :model-value="dir.path"
                @update:model-value="updateExtraDirectoryPath(dir.key, $event)"
                prefix="/"
                monospace
              :disabled="disabled"
              />
            </div>
          </div>

          <!-- New directories repeater -->
          <Repeater
            v-if="!disabled"
            :model-value="newOutputExtras"
            @update:model-value="updateNewExtras('output', $event)"
            addLabel="Add Output Directory"
            :defaultItem="() => ({ key: '', label: '', path: '', type: 'output', _id: Date.now() })"
          >
            <template #default="{ item, update }">
              <div class="space-y-3">
                <Input
                  :model-value="item.key"
                  @update:model-value="update('key', $event)"
                  label="Key"
                  placeholder="outputs_archive"
                  hint="Unique identifier (alphanumeric and underscores)"
                />
                <Input
                  :model-value="item.label"
                  @update:model-value="update('label', $event)"
                  label="Label"
                  placeholder="Archive"
                />
                <Input
                  :model-value="item.path"
                  @update:model-value="update('path', $event)"
                  label="Path"
                  prefix="/"
                  placeholder="outputs/archive"
                  monospace
              :disabled="disabled"
                />
              </div>
            </template>
          </Repeater>
        </div>
      </SettingsPanel>
    </div>

    <!-- Utility Section -->
    <div v-if="!isPresentationProject && !isCourseProject && utilityFields.length > 0" :id="`section-utility`">
      <SettingsPanel
        title="Utility"
        description="Cache, scratch space, and other temporary directories (gitignored by default)."
      >
        <div class="space-y-5">
          <div v-for="field in utilityFields" :key="field.key" class="space-y-1.5">
            <Toggle
              :model-value="localEnabled[field.key]"
              @update:model-value="updateEnabled(field.key, $event)"
              :label="field.label"
              :description="field.hint"
              :disabled="isToggleDisabled(field.key)"
            />
            <Input
              v-if="localEnabled[field.key] !== false"
              :model-value="getDirectoryValue(field.key)"
              @update:model-value="updateDirectory(field.key, $event)"
              prefix="/"
              monospace
              :disabled="disabled"
            />
          </div>
        </div>
      </SettingsPanel>
    </div>

    <!-- .gitignore Section -->
    <div :id="`section-gitignore`">
      <SettingsPanel
        title=".gitignore Patterns"
        description="Define which files and directories Git should ignore."
      >
        <SettingsBlock>
          <Textarea
            :model-value="localGitignore"
            @update:model-value="$emit('update:gitignore', $event)"
            :rows="12"
            :disabled="disabled"
            monospace
            placeholder="# Framework gitignore patterns
cache/
scratch/
*.log"
          />
        </SettingsBlock>
      </SettingsPanel>
    </div>
  </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue'
import SettingsPanel from './SettingsPanel.vue'
import SettingsBlock from './SettingsBlock.vue'
import Toggle from '../ui/Toggle.vue'
import Input from '../ui/Input.vue'
import Select from '../ui/Select.vue'
import Textarea from '../ui/Textarea.vue'
import Button from '../ui/Button.vue'
import Repeater from '../ui/Repeater.vue'
import CourseDirectoriesPanel from './CourseDirectoriesPanel.vue'

const props = defineProps({
  projectType: {
    type: String,
    required: true
  },
  directories: {
    type: Object,
    required: true
  },
  renderDirs: {
    type: Object,
    default: () => ({})
  },
  enabled: {
    type: Object,
    required: true
  },
  extraDirectories: {
    type: Array,
    default: () => []
  },
  settings: {
    type: Object,
    default: () => ({})
  },
  gitignore: {
    type: String,
    default: ''
  },
  catalog: {
    type: Object,
    required: true
  },
  newExtraIds: {
    type: Set,
    default: () => new Set()
  },
  disabled: {
    type: Boolean,
    default: false
  },
  allowDestruction: {
    type: Boolean,
    default: true
  }
})

const emit = defineEmits([
  'update:directories',
  'update:renderDirs',
  'update:enabled',
  'update:extraDirectories',
  'update:settings',
  'update:gitignore',
  'update:newExtraIds',
  'reset'
])

// Local state
const localDirectories = ref({ ...props.directories })
const localRenderDirs = ref({ ...props.renderDirs })
const localEnabled = ref({ ...props.enabled })
const localSettings = ref({ ...props.settings })
const localGitignore = ref(props.gitignore)

// Helper to get directory value (from local state or catalog default)
const getDirectoryValue = (key) => {
  if (localDirectories.value[key]) {
    return localDirectories.value[key]
  }
  // Fall back to catalog default if directory not in local state (e.g., when disabled)
  // Catalog format is: directories[key] = { label, default, enabled_by_default, hint }
  return props.catalog?.directories?.[key]?.default || ''
}

// Watch for external changes
watch(() => props.directories, (newVal) => { localDirectories.value = { ...newVal } }, { deep: true })
watch(() => props.renderDirs, (newVal) => { localRenderDirs.value = { ...newVal } }, { deep: true })
watch(() => props.enabled, (newVal) => { localEnabled.value = { ...newVal } }, { deep: true })
watch(() => props.settings, (newVal) => { localSettings.value = { ...newVal } }, { deep: true })
watch(() => props.gitignore, (newVal) => { localGitignore.value = newVal })

// Fallback directory definitions (used when catalog doesn't have them)
const workspaceRenderableFallback = [
  { key: 'notebooks', label: 'Notebooks', hint: 'Quarto or R Markdown notebooks for analysis.', defaultRenderDir: 'outputs/notebooks' },
  { key: 'docs', label: 'Documentation', hint: 'Codebooks, documentation, and other reference materials.', defaultRenderDir: 'outputs/docs' }
]

const workspaceNonRenderableFallback = [
  { key: 'functions', label: 'Functions', hint: 'R files here are sourced by scaffold(), so helper functions are available in every project session.' },
  { key: 'scripts', label: 'Scripts', hint: 'Reusable R scripts, job runners, or automation tasks.' }
]

const inputFallback = [
  { key: 'inputs_raw', label: 'Raw data', hint: 'Read-only exports from source systems.' },
  { key: 'inputs_intermediate', label: 'Intermediate data', hint: 'Data after light cleaning or pre-processing steps.' },
  { key: 'inputs_final', label: 'Analysis-ready data', hint: 'Final inputs ready for modeling or reporting.' }
]

const outputFallback = [
  { key: 'outputs_tables', label: 'Tables', hint: 'Publishable tables ready for reports or manuscripts.' },
  { key: 'outputs_figures', label: 'Figures', hint: 'Final plots and graphics.' },
  { key: 'outputs_models', label: 'Models', hint: 'Serialized models or model summaries.' },
  { key: 'outputs_reports', label: 'Reports', hint: 'Final reports and deliverables ready for publication.' }
]

const utilityFallback = [
  { key: 'cache', label: 'Cache', hint: 'Temporary artifacts (gitignored).' },
  { key: 'scratch', label: 'Scratch', hint: 'Short-lived explorations (gitignored).' }
]

// Helper to get directory metadata from catalog
const getDirectoryMeta = (dirKey) => {
  return props.catalog?.directories?.[dirKey] || {}
}

// Build field list from fallback with catalog overrides
const buildFields = (fallback) => {
  return fallback.map(entry => {
    const meta = getDirectoryMeta(entry.key)
    return {
      key: entry.key,
      label: meta.label || entry.label,
      hint: meta.hint || entry.hint || '',
      defaultRenderDir: entry.defaultRenderDir || ''
    }
  })
}

// Detect project type
const isSensitiveProject = computed(() => props.projectType === 'project_sensitive')
const isPresentationProject = computed(() => props.projectType === 'presentation')
const isCourseProject = computed(() => props.projectType === 'course')

// Helper to build privacy-paired fields (private/public columns)
const buildSensitivePairs = (baseFallback, prefix) => {
  return baseFallback.map(entry => {
    const privateKey = `${prefix}_private_${entry.key.replace(prefix + '_', '')}`
    const publicKey = `${prefix}_public_${entry.key.replace(prefix + '_', '')}`
    const privateMeta = getDirectoryMeta(privateKey)
    const publicMeta = getDirectoryMeta(publicKey)

    return {
      privateKey,
      publicKey,
      privateLabel: privateMeta.label || `${entry.label} (private)`,
      publicLabel: publicMeta.label || `${entry.label} (public)`,
      hint: entry.hint || ''
    }
  })
}

// Computed field lists organized by category
const workspaceRenderableFields = computed(() => buildFields(workspaceRenderableFallback))
const workspaceNonRenderableFields = computed(() => buildFields(workspaceNonRenderableFallback))
const workspaceFields = computed(() => [...workspaceRenderableFields.value, ...workspaceNonRenderableFields.value])

// For sensitive projects, use paired private/public layout
const inputFields = computed(() => {
  if (isSensitiveProject.value) {
    return buildSensitivePairs(inputFallback, 'inputs')
  }
  return buildFields(inputFallback)
})

const outputFields = computed(() => {
  if (isSensitiveProject.value) {
    return buildSensitivePairs(outputFallback, 'outputs')
  }
  return buildFields(outputFallback)
})

const utilityFields = computed(() => buildFields(utilityFallback))

// Project-specific settings from catalog
const projectTypeSettings = computed(() => {
  return props.catalog?.settings || []
})

// Extra directories organized by type
const savedInputExtras = computed(() => {
  return props.extraDirectories.filter(dir => dir.type === 'input' && !props.newExtraIds.has(dir._id))
})

const savedWorkspaceExtras = computed(() => {
  return props.extraDirectories.filter(dir => dir.type === 'workspace' && !props.newExtraIds.has(dir._id))
})

const savedOutputExtras = computed(() => {
  return props.extraDirectories.filter(dir => dir.type === 'output' && !props.newExtraIds.has(dir._id))
})

const newInputExtras = computed(() => {
  return props.extraDirectories.filter(dir => dir.type === 'input' && props.newExtraIds.has(dir._id))
})

const newWorkspaceExtras = computed(() => {
  return props.extraDirectories.filter(dir => dir.type === 'workspace' && props.newExtraIds.has(dir._id))
})

const newOutputExtras = computed(() => {
  return props.extraDirectories.filter(dir => dir.type === 'output' && props.newExtraIds.has(dir._id))
})

// Helper to get all extra directories by type
const extraDirectoriesByType = (type) => {
  return props.extraDirectories.filter(dir => dir.type === type)
}

// Update handlers
const updateDirectory = (key, value) => {
  localDirectories.value[key] = value
  emit('update:directories', { ...localDirectories.value })
}

const updateRenderDir = (key, value) => {
  localRenderDirs.value[key] = value
  emit('update:renderDirs', { ...localRenderDirs.value })
}

const updateEnabled = (key, value) => {
  // In append-only mode, prevent disabling (turning off) directories
  if (!props.allowDestruction && localEnabled.value[key] === true && value === false) {
    return // Prevent disabling in append-only mode
  }
  localEnabled.value[key] = value
  emit('update:enabled', { ...localEnabled.value })
}

// Helper to determine if a toggle should be disabled
const isToggleDisabled = (key) => {
  if (props.disabled) return true
  // In append-only mode, disable toggles that are currently ON (can't turn off)
  if (!props.allowDestruction && localEnabled.value[key] === true) return true
  return false
}

const updateSetting = (key, value) => {
  localSettings.value[key] = value
  emit('update:settings', { ...localSettings.value })
}

const updateExtraDirectoryPath = (key, value) => {
  const updated = props.extraDirectories.map(dir => {
    if (dir.key === key) {
      return { ...dir, path: value }
    }
    return dir
  })
  emit('update:extraDirectories', updated)
}

const updateNewExtras = (type, newItems) => {
  // Get saved items of this type
  const savedItems = props.extraDirectories.filter(dir =>
    dir.type === type && !props.newExtraIds.has(dir._id)
  )

  // Get current new items
  const currentNewItems = props.extraDirectories.filter(dir =>
    dir.type === type && props.newExtraIds.has(dir._id)
  )

  // Find deleted items
  const deletedItems = currentNewItems.filter(current =>
    !newItems.some(item => item._id === current._id)
  )

  // Update tracking set
  const newIds = new Set(props.newExtraIds)
  deletedItems.forEach(item => {
    if (item._id) newIds.delete(item._id)
  })
  newItems.forEach(item => {
    if (item._id) newIds.add(item._id)
  })
  emit('update:newExtraIds', newIds)

  // CRITICAL: Mark newly added directories as enabled (but don't override existing enabled states)
  // This prevents enabling an existing disabled directory when user types a matching key
  const updatedEnabled = { ...localEnabled.value }
  let needsUpdate = false

  newItems.forEach(item => {
    if (item.key) {
      // Only auto-enable if:
      // 1. No enabled state exists for this key yet
      // 2. The key doesn't match any existing saved extra directory
      // 3. The key doesn't match any catalog directory
      const keyExistsInSaved = savedItems.some(saved => saved.key === item.key)
      const keyExistsInCatalog = props.catalog?.directories &&
                                  Object.keys(props.catalog.directories).includes(item.key)

      if (!updatedEnabled.hasOwnProperty(item.key) && !keyExistsInSaved && !keyExistsInCatalog) {
        updatedEnabled[item.key] = true
        needsUpdate = true
      }
    }
  })

  // Emit enabled state update only if we actually added new keys
  if (needsUpdate) {
    emit('update:enabled', updatedEnabled)
  }

  // Merge saved + new items for this type, plus items of other types
  const otherTypeItems = props.extraDirectories.filter(dir => dir.type !== type)
  emit('update:extraDirectories', [...otherTypeItems, ...savedItems, ...newItems])
}

const scrollToSection = (section) => {
  const el = document.getElementById(`section-${section}`)
  if (el) {
    el.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }
}
</script>
