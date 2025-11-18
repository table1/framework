<template>
  <div class="space-y-6">
    <!-- renv Toggle -->
    <div v-if="showRenvToggle" :class="renvContainerClasses">
      <Toggle
        :model-value="localPackages.use_renv"
        @update:model-value="updateUseRenv"
        label="Enable renv"
        description="Create renv environments for new projects."
      />
    </div>

    <!-- Packages List -->
    <div :class="packagesContainerClasses">
      <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-2">
        Default packages
      </h3>
      <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
        Installed (and optionally attached) when scaffold() runs.
      </p>
      <p class="text-xs text-gray-600 dark:text-gray-400 mb-4">
        Use this list to preseed notebooks with your preferred helpers.
      </p>

      <div class="space-y-3" v-if="localPackages.default_packages && localPackages.default_packages.length">
        <div
          v-for="(pkg, idx) in localPackages.default_packages"
          :key="`pkg-${idx}`"
          class="rounded-md border border-gray-200 p-4 dark:border-gray-700"
        >
          <div class="flex flex-col gap-3">
            <div class="grid gap-3 grid-cols-[1fr_160px]">
              <PackageAutocomplete
                v-if="pkg.source === 'cran' || pkg.source === 'bioconductor'"
                :model-value="pkg.name"
                @update:model-value="updatePackageName(idx, $event)"
                :source="pkg.source"
                label="Package"
                :placeholder="pkg.source === 'cran' ? 'Search CRAN...' : 'Search Bioconductor...'"
                @select="(selectedPkg) => updatePackageName(idx, selectedPkg.name)"
              />
              <Input
                v-else
                :model-value="pkg.name"
                @update:model-value="updatePackageName(idx, $event)"
                label="Package"
                placeholder="user/repo"
              />
              <Select
                :model-value="pkg.source"
                @update:model-value="updatePackageSource(idx, $event)"
                label="Source"
              >
                <option value="cran">CRAN</option>
                <option value="github">GitHub</option>
                <option value="bioconductor">Bioconductor</option>
              </Select>
            </div>
            <div class="flex items-center justify-between">
              <Toggle
                :model-value="pkg.auto_attach"
                @update:model-value="updatePackageAutoAttach(idx, $event)"
                label="Auto-Attach"
                description="Call library() when scaffold() runs."
              />
              <Button size="sm" variant="secondary" @click="removePackage(idx)">Remove</Button>
            </div>
          </div>
        </div>
      </div>

      <p v-else class="text-xs text-gray-500 dark:text-gray-400 mb-4">
        No packages configured. Add packages to include tidyverse helpers or internal utilities automatically.
      </p>

      <div class="mt-4">
        <Button size="sm" variant="secondary" @click="addPackage">Add Package</Button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, computed } from 'vue'
import Toggle from '../ui/Toggle.vue'
import Input from '../ui/Input.vue'
import Select from '../ui/Select.vue'
import Button from '../ui/Button.vue'
import PackageAutocomplete from '../ui/PackageAutocomplete.vue'

const props = defineProps({
  modelValue: {
    type: Object,
    required: true
  },
  showRenvToggle: {
    type: Boolean,
    default: true
  },
  flush: {
    type: Boolean,
    default: false
  }
})

const renvContainerClasses = computed(() =>
  props.flush ? '' : 'rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50'
)

const packagesContainerClasses = computed(() =>
  props.flush ? '' : 'rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50'
)

const emit = defineEmits(['update:modelValue'])

const localPackages = ref({
  use_renv: props.modelValue.use_renv ?? false,
  default_packages: props.modelValue.default_packages ?? []
})

// Watch for external changes
watch(() => props.modelValue, (newValue) => {
  localPackages.value = {
    use_renv: newValue.use_renv ?? false,
    default_packages: newValue.default_packages ?? []
  }
}, { deep: true })

const emitUpdate = () => {
  emit('update:modelValue', { ...localPackages.value })
}

const updateUseRenv = (value) => {
  localPackages.value.use_renv = value
  emitUpdate()
}

const updatePackageName = (idx, value) => {
  localPackages.value.default_packages[idx].name = value
  emitUpdate()
}

const updatePackageSource = (idx, value) => {
  localPackages.value.default_packages[idx].source = value
  emitUpdate()
}

const updatePackageAutoAttach = (idx, value) => {
  localPackages.value.default_packages[idx].auto_attach = value
  emitUpdate()
}

const addPackage = () => {
  localPackages.value.default_packages.push({
    name: '',
    source: 'cran',
    auto_attach: true
  })
  emitUpdate()
}

const removePackage = (idx) => {
  localPackages.value.default_packages.splice(idx, 1)
  emitUpdate()
}
</script>
