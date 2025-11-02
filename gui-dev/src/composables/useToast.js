import { ref } from 'vue'

// Global toast container reference
let toastContainer = null

export function setToastContainer(container) {
  toastContainer = container
}

export function useToast() {
  const show = (options) => {
    if (!toastContainer) {
      console.warn('ToastContainer not initialized. Add <ToastContainer ref="toastContainer" /> to your App.vue')
      return
    }
    return toastContainer.addToast(options)
  }

  const success = (title, description = null, options = {}) => {
    return show({
      title,
      description,
      type: 'success',
      ...options
    })
  }

  const error = (title, description = null, options = {}) => {
    return show({
      title,
      description,
      type: 'error',
      ...options
    })
  }

  const warning = (title, description = null, options = {}) => {
    return show({
      title,
      description,
      type: 'warning',
      ...options
    })
  }

  const info = (title, description = null, options = {}) => {
    return show({
      title,
      description,
      type: 'info',
      ...options
    })
  }

  const remove = (id) => {
    if (toastContainer) {
      toastContainer.removeToast(id)
    }
  }

  const clearAll = () => {
    if (toastContainer) {
      toastContainer.clearAll()
    }
  }

  return {
    show,
    success,
    error,
    warning,
    info,
    remove,
    clearAll
  }
}
