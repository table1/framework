import { ref } from 'vue'
import { createHighlighter } from 'shiki'

const highlighter = ref(null)
const isLoading = ref(true)
const isReady = ref(false)

// Initialize highlighter once (singleton pattern)
let initPromise = null

export function useHighlighter() {
  const initHighlighter = async () => {
    if (highlighter.value) return highlighter.value

    if (!initPromise) {
      initPromise = createHighlighter({
        themes: ['github-light', 'github-dark'],
        langs: ['r']
      })
    }

    try {
      highlighter.value = await initPromise
      isLoading.value = false
      isReady.value = true
      console.log('Shiki highlighter initialized successfully')
    } catch (err) {
      console.error('Failed to initialize syntax highlighter:', err)
      isLoading.value = false
    }

    return highlighter.value
  }

  const highlight = (code, lang = 'r') => {
    if (!code) {
      return '<pre><code></code></pre>'
    }

    if (!highlighter.value) {
      // Fallback when highlighter isn't ready - still wrap in pre/code
      return `<pre><code>${escapeHtml(code)}</code></pre>`
    }

    try {
      // Use single theme for now - simpler and more reliable
      return highlighter.value.codeToHtml(code, {
        lang,
        theme: 'github-light'
      })
    } catch (err) {
      console.error('Highlight error:', err)
      return `<pre><code>${escapeHtml(code)}</code></pre>`
    }
  }

  return {
    highlighter,
    isLoading,
    isReady,
    initHighlighter,
    highlight
  }
}

function escapeHtml(text) {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
}
