<template>
  <div class="relative inline-block" ref="dropdownRef">
    <!-- Trigger button -->
    <button
      type="button"
      @click="toggle"
      :class="buttonClasses"
      :aria-expanded="isOpen"
      aria-haspopup="true"
    >
      <slot name="trigger">
        {{ label }}
        <svg viewBox="0 0 20 20" fill="currentColor" class="-mr-1 size-5 text-gray-400">
          <path d="M5.22 8.22a.75.75 0 0 1 1.06 0L10 11.94l3.72-3.72a.75.75 0 1 1 1.06 1.06l-4.25 4.25a.75.75 0 0 1-1.06 0L5.22 9.28a.75.75 0 0 1 0-1.06Z" clip-rule="evenodd" fill-rule="evenodd" />
        </svg>
      </slot>
    </button>

    <!-- Dropdown menu -->
    <Transition
      enter-active-class="transition duration-100 ease-out"
      enter-from-class="transform scale-95 opacity-0"
      enter-to-class="transform scale-100 opacity-100"
      leave-active-class="transition duration-75 ease-in"
      leave-from-class="transform scale-100 opacity-100"
      leave-to-class="transform scale-95 opacity-0"
    >
      <div
        v-if="isOpen"
        :class="menuClasses"
        role="menu"
        aria-orientation="vertical"
      >
        <slot :close="close" />
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  label: {
    type: String,
    default: 'Options'
  },
  align: {
    type: String,
    default: 'right',
    validator: (value) => ['left', 'right'].includes(value)
  },
  width: {
    type: String,
    default: 'w-56'
  },
  divided: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['open', 'close'])

const isOpen = ref(false)
const dropdownRef = ref(null)

const buttonClasses = computed(() => {
  return [
    'inline-flex',
    'w-full',
    'justify-center',
    'gap-x-1.5',
    'rounded-md',
    'bg-white',
    'px-3',
    'py-2',
    'text-sm',
    'font-semibold',
    'text-gray-900',
    'shadow-xs',
    'inset-ring-1',
    'inset-ring-gray-300',
    'hover:bg-gray-50',
    'dark:bg-white/10',
    'dark:text-white',
    'dark:shadow-none',
    'dark:inset-ring-white/5',
    'dark:hover:bg-white/20'
  ].join(' ')
})

const menuClasses = computed(() => {
  const classes = [
    'absolute',
    'z-10',
    'mt-2',
    props.width,
    'rounded-md',
    'bg-white',
    'shadow-lg',
    'outline-1',
    'outline-black/5',
    'dark:bg-gray-800',
    'dark:shadow-none',
    'dark:-outline-offset-1',
    'dark:outline-white/10'
  ]

  // Alignment
  if (props.align === 'right') {
    classes.push('right-0', 'origin-top-right')
  } else {
    classes.push('left-0', 'origin-top-left')
  }

  // Divided sections
  if (props.divided) {
    classes.push('divide-y', 'divide-gray-100', 'dark:divide-white/10')
  }

  return classes.join(' ')
})

const toggle = () => {
  isOpen.value = !isOpen.value
  emit(isOpen.value ? 'open' : 'close')
}

const close = () => {
  isOpen.value = false
  emit('close')
}

const handleClickOutside = (event) => {
  if (dropdownRef.value && !dropdownRef.value.contains(event.target)) {
    close()
  }
}

const handleEscape = (event) => {
  if (event.key === 'Escape' && isOpen.value) {
    close()
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
  document.addEventListener('keydown', handleEscape)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
  document.removeEventListener('keydown', handleEscape)
})

defineExpose({ close, isOpen })
</script>
