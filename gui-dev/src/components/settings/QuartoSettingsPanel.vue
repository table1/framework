<template>
  <div class="space-y-6">
    <!-- HTML Rendering Settings -->
    <div :class="containerClasses">
      <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-2">
        HTML Rendering
      </h3>
      <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
        Default settings for HTML documents (notebooks, documentation).
      </p>

      <div class="space-y-4">
        <!-- Theme -->
        <Select
          :model-value="localQuarto.html.theme"
          @update:model-value="update('html', 'theme', $event)"
          label="Theme"
        >
          <option value="default">Default</option>
          <option value="cosmo">Cosmo</option>
          <option value="cerulean">Cerulean</option>
          <option value="flatly">Flatly</option>
          <option value="journal">Journal</option>
          <option value="lumen">Lumen</option>
          <option value="minty">Minty</option>
          <option value="pulse">Pulse</option>
          <option value="sandstone">Sandstone</option>
          <option value="simplex">Simplex</option>
          <option value="sketchy">Sketchy</option>
          <option value="slate">Slate</option>
          <option value="solar">Solar</option>
          <option value="spacelab">Spacelab</option>
          <option value="superhero">Superhero</option>
          <option value="united">United</option>
          <option value="yeti">Yeti</option>
        </Select>

        <!-- Document Options -->
        <Toggle
          :model-value="localQuarto.html.embed_resources"
          @update:model-value="update('html', 'embed_resources', $event)"
          label="Embed resources"
          description="Produce standalone HTML files with all dependencies and resources embedded."
        />

        <!-- TOC Options -->
        <Toggle
          :model-value="localQuarto.html.toc"
          @update:model-value="update('html', 'toc', $event)"
          label="Table of contents"
          description="Generate a table of contents sidebar."
        />
        <Input
          type="number"
          :model-value="localQuarto.html.toc_depth"
          @update:model-value="update('html', 'toc_depth', parseInt($event) || 3)"
          label="TOC depth"
          min="1"
          max="6"
        />

        <!-- Code Options -->
        <Toggle
          :model-value="localQuarto.html.code_fold"
          @update:model-value="update('html', 'code_fold', $event)"
          label="Code folding"
          description="Allow readers to collapse/expand code blocks."
        />
        <Toggle
          :model-value="localQuarto.html.code_tools"
          @update:model-value="update('html', 'code_tools', $event)"
          label="Code tools"
          description="Provide code download and viewing options."
        />

        <!-- Syntax Highlighting -->
        <Select
          :model-value="localQuarto.html.highlight_style"
          @update:model-value="update('html', 'highlight_style', $event)"
          label="Syntax highlighting"
        >
          <option value="github">GitHub</option>
          <option value="tango">Tango</option>
          <option value="pygments">Pygments</option>
          <option value="kate">Kate</option>
          <option value="monochrome">Monochrome</option>
          <option value="espresso">Espresso</option>
          <option value="zenburn">Zenburn</option>
          <option value="haddock">Haddock</option>
          <option value="breezedark">Breeze Dark</option>
        </Select>
      </div>
    </div>

    <!-- Presentation Settings (revealjs) -->
    <div :class="containerClasses">
      <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-2">
        Presentations (revealjs)
      </h3>
      <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
        Default settings for slide presentations.
      </p>

      <div class="space-y-4">
        <!-- Theme -->
        <Select
          :model-value="localQuarto.revealjs.theme"
          @update:model-value="update('revealjs', 'theme', $event)"
          label="Theme"
        >
          <option value="default">Default</option>
          <option value="beige">Beige</option>
          <option value="black">Black</option>
          <option value="blood">Blood</option>
          <option value="league">League</option>
          <option value="moon">Moon</option>
          <option value="night">Night</option>
          <option value="serif">Serif</option>
          <option value="simple">Simple</option>
          <option value="sky">Sky</option>
          <option value="solarized">Solarized</option>
          <option value="white">White</option>
        </Select>

        <!-- Display Options -->
        <Toggle
          :model-value="localQuarto.revealjs.incremental"
          @update:model-value="update('revealjs', 'incremental', $event)"
          label="Incremental bullets"
          description="Reveal list items one at a time."
        />
        <Toggle
          :model-value="localQuarto.revealjs.slide_number"
          @update:model-value="update('revealjs', 'slide_number', $event)"
          label="Slide numbers"
          description="Show slide numbers in the corner."
        />

        <Toggle
          :model-value="localQuarto.revealjs.controls"
          @update:model-value="update('revealjs', 'controls', $event)"
          label="Navigation controls"
          description="Show arrow controls for navigation."
        />
        <Toggle
          :model-value="localQuarto.revealjs.progress"
          @update:model-value="update('revealjs', 'progress', $event)"
          label="Progress bar"
          description="Show progress bar at the bottom."
        />

        <Toggle
          :model-value="localQuarto.revealjs.center"
          @update:model-value="update('revealjs', 'center', $event)"
          label="Center slides"
          description="Vertically center slide content."
        />

        <!-- Transitions -->
        <Select
          :model-value="localQuarto.revealjs.transition"
          @update:model-value="update('revealjs', 'transition', $event)"
          label="Slide transition"
        >
          <option value="none">None</option>
          <option value="fade">Fade</option>
          <option value="slide">Slide</option>
          <option value="convex">Convex</option>
          <option value="concave">Concave</option>
          <option value="zoom">Zoom</option>
        </Select>

        <Select
          :model-value="localQuarto.revealjs.background_transition"
          @update:model-value="update('revealjs', 'background_transition', $event)"
          label="Background transition"
        >
          <option value="none">None</option>
          <option value="fade">Fade</option>
          <option value="slide">Slide</option>
          <option value="convex">Convex</option>
          <option value="concave">Concave</option>
          <option value="zoom">Zoom</option>
        </Select>

        <!-- Syntax Highlighting -->
        <Select
          :model-value="localQuarto.revealjs.highlight_style"
          @update:model-value="update('revealjs', 'highlight_style', $event)"
          label="Syntax highlighting"
        >
          <option value="github">GitHub</option>
          <option value="tango">Tango</option>
          <option value="pygments">Pygments</option>
          <option value="kate">Kate</option>
          <option value="monochrome">Monochrome</option>
          <option value="espresso">Espresso</option>
          <option value="zenburn">Zenburn</option>
          <option value="haddock">Haddock</option>
          <option value="breezedark">Breeze Dark</option>
        </Select>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, computed } from 'vue'
import Toggle from '../ui/Toggle.vue'
import Input from '../ui/Input.vue'
import Select from '../ui/Select.vue'

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

const containerClasses = computed(() =>
  props.flush ? '' : 'rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50'
)

// Initialize local state with defaults
const localQuarto = ref({
  html: {
    format: 'html',
    embed_resources: props.modelValue.html?.embed_resources ?? true,
    theme: props.modelValue.html?.theme ?? 'default',
    toc: props.modelValue.html?.toc ?? true,
    toc_depth: props.modelValue.html?.toc_depth ?? 3,
    code_fold: props.modelValue.html?.code_fold ?? false,
    code_tools: props.modelValue.html?.code_tools ?? false,
    highlight_style: props.modelValue.html?.highlight_style ?? 'github'
  },
  revealjs: {
    format: 'revealjs',
    theme: props.modelValue.revealjs?.theme ?? 'default',
    incremental: props.modelValue.revealjs?.incremental ?? false,
    slide_number: props.modelValue.revealjs?.slide_number ?? true,
    transition: props.modelValue.revealjs?.transition ?? 'slide',
    background_transition: props.modelValue.revealjs?.background_transition ?? 'fade',
    controls: props.modelValue.revealjs?.controls ?? true,
    progress: props.modelValue.revealjs?.progress ?? true,
    center: props.modelValue.revealjs?.center ?? true,
    highlight_style: props.modelValue.revealjs?.highlight_style ?? 'github'
  }
})

// Watch for external changes
watch(() => props.modelValue, (newValue) => {
  localQuarto.value = {
    html: {
      format: 'html',
      embed_resources: newValue.html?.embed_resources ?? true,
      theme: newValue.html?.theme ?? 'default',
      toc: newValue.html?.toc ?? true,
      toc_depth: newValue.html?.toc_depth ?? 3,
      code_fold: newValue.html?.code_fold ?? false,
      code_tools: newValue.html?.code_tools ?? false,
      highlight_style: newValue.html?.highlight_style ?? 'github'
    },
    revealjs: {
      format: 'revealjs',
      theme: newValue.revealjs?.theme ?? 'default',
      incremental: newValue.revealjs?.incremental ?? false,
      slide_number: newValue.revealjs?.slide_number ?? true,
      transition: newValue.revealjs?.transition ?? 'slide',
      background_transition: newValue.revealjs?.background_transition ?? 'fade',
      controls: newValue.revealjs?.controls ?? true,
      progress: newValue.revealjs?.progress ?? true,
      center: newValue.revealjs?.center ?? true,
      highlight_style: newValue.revealjs?.highlight_style ?? 'github'
    }
  }
}, { deep: true })

const update = (format, key, value) => {
  localQuarto.value[format][key] = value
  emit('update:modelValue', { ...localQuarto.value })
}
</script>
