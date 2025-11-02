<template>
  <div>
    <div :class="tabsClasses">
      <nav :class="navClasses" aria-label="Tabs">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          type="button"
          @click="selectTab(tab.id)"
          :class="getTabClasses(tab.id)"
          :aria-current="modelValue === tab.id ? 'page' : undefined"
        >
          <component :is="tab.icon" v-if="tab.icon" class="size-5" />
          {{ tab.label }}
          <Badge v-if="tab.badge" :variant="modelValue === tab.id ? 'emerald' : 'gray'" pill>
            {{ tab.badge }}
          </Badge>
        </button>
      </nav>
    </div>

    <!-- Tab panels -->
    <div class="mt-4">
      <slot />
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import Badge from './Badge.vue'

const props = defineProps({
  modelValue: {
    type: [String, Number],
    required: true
  },
  tabs: {
    type: Array,
    required: true,
    validator: (tabs) => {
      return tabs.every(tab => tab.id && tab.label)
    }
  },
  variant: {
    type: String,
    default: 'pills',
    validator: (value) => ['pills', 'underline'].includes(value)
  },
  size: {
    type: String,
    default: 'md',
    validator: (value) => ['sm', 'md', 'lg'].includes(value)
  }
})

const emit = defineEmits(['update:modelValue', 'change'])

const tabsClasses = computed(() => {
  if (props.variant === 'underline') {
    return 'border-b border-gray-200 dark:border-white/10'
  }
  return ''
})

const navClasses = computed(() => {
  const classes = ['flex', 'gap-2']

  if (props.variant === 'underline') {
    classes.push('-mb-px')
  } else {
    classes.push('p-1', 'bg-gray-100', 'dark:bg-white/5', 'rounded-lg')
  }

  return classes.join(' ')
})

const getTabClasses = (tabId) => {
  const isActive = props.modelValue === tabId
  const classes = ['inline-flex', 'items-center', 'gap-2', 'font-medium', 'transition-colors']

  // Size classes
  const sizeMap = {
    sm: 'px-2.5 py-1.5 text-xs',
    md: 'px-3 py-2 text-sm',
    lg: 'px-4 py-2.5 text-base'
  }
  classes.push(sizeMap[props.size])

  if (props.variant === 'pills') {
    classes.push('rounded-md')

    if (isActive) {
      classes.push(
        'bg-white',
        'text-gray-900',
        'shadow-xs',
        'dark:bg-white/10',
        'dark:text-white'
      )
    } else {
      classes.push(
        'text-gray-600',
        'hover:text-gray-900',
        'dark:text-gray-400',
        'dark:hover:text-white'
      )
    }
  } else {
    // Underline variant
    classes.push('border-b-2', 'pb-3')

    if (isActive) {
      classes.push(
        'border-sky-600',
        'text-sky-600',
        'dark:border-sky-500',
        'dark:text-sky-400'
      )
    } else {
      classes.push(
        'border-transparent',
        'text-gray-600',
        'hover:border-gray-300',
        'hover:text-gray-900',
        'dark:text-gray-400',
        'dark:hover:border-gray-600',
        'dark:hover:text-white'
      )
    }
  }

  return classes.join(' ')
}

const selectTab = (tabId) => {
  emit('update:modelValue', tabId)
  emit('change', tabId)
}
</script>
