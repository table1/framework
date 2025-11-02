<template>
  <div
    v-show="active"
    role="tabpanel"
    :aria-labelledby="`tab-${id}`"
  >
    <slot />
  </div>
</template>

<script setup>
defineProps({
  id: {
    type: [String, Number],
    required: true
  },
  active: {
    type: Boolean,
    required: true
  }
})
</script>
