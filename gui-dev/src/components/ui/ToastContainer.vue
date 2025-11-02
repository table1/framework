<template>
  <Teleport to="body">
    <div
      aria-live="assertive"
      class="pointer-events-none fixed inset-0 flex items-end px-4 py-6 sm:items-start sm:p-6 z-50"
    >
      <div class="flex w-full flex-col items-center space-y-4 sm:items-end">
        <Toast
          v-for="toast in toasts"
          :key="toast.id"
          :title="toast.title"
          :description="toast.description"
          :type="toast.type"
          :variant="toast.variant"
          :action="toast.action"
          :duration="toast.duration"
          :auto-close="toast.autoClose"
          @close="removeToast(toast.id)"
          @action="handleAction(toast)"
        />
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { ref } from 'vue'
import Toast from './Toast.vue'

const toasts = ref([])
let nextId = 1

const addToast = (options) => {
  const toast = {
    id: nextId++,
    title: options.title,
    description: options.description || null,
    type: options.type || 'success',
    variant: options.variant || 'regular',
    action: options.action || null,
    duration: options.duration !== undefined ? options.duration : 5000,
    autoClose: options.autoClose !== undefined ? options.autoClose : true,
    onAction: options.onAction || null
  }
  toasts.value.push(toast)
  return toast.id
}

const removeToast = (id) => {
  const index = toasts.value.findIndex(t => t.id === id)
  if (index > -1) {
    toasts.value.splice(index, 1)
  }
}

const handleAction = (toast) => {
  if (toast.onAction) {
    toast.onAction()
  }
}

const clearAll = () => {
  toasts.value = []
}

defineExpose({
  addToast,
  removeToast,
  clearAll
})
</script>
