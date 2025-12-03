<template>
  <div v-html="renderedHtml" class="markdown-text"></div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  content: {
    type: String,
    default: ''
  }
})

const renderedHtml = computed(() => {
  if (!props.content) return ''

  let html = props.content

  // Handle fenced code blocks FIRST (before escaping)
  // Match ```...``` blocks and convert to <pre><code>
  html = html.replace(/```\n?([\s\S]*?)```/g, (match, code) => {
    // Escape HTML inside code blocks
    const escapedCode = code
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
    return `<pre class="bg-gray-100 dark:bg-gray-800 p-3 rounded text-sm font-mono overflow-x-auto my-2"><code>${escapedCode.trim()}</code></pre>`
  })

  // Escape HTML in remaining content (but not already-processed pre blocks)
  // Split by pre tags, escape non-pre parts, rejoin
  const parts = html.split(/(<pre[\s\S]*?<\/pre>)/)
  html = parts.map(part => {
    if (part.startsWith('<pre')) return part
    return part
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
  }).join('')

  // Convert inline code (backticks) - but not inside pre blocks
  html = html.replace(/`([^`]+)`/g, '<code class="bg-gray-100 dark:bg-gray-800 px-1 py-0.5 rounded text-sm font-mono">$1</code>')

  // Convert bold
  html = html.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')

  // Convert italic (but not list markers)
  html = html.replace(/(?<!\S)\*([^*]+)\*(?!\S)/g, '<em>$1</em>')

  // Convert links [text](url)
  html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" class="text-sky-600 hover:underline" target="_blank">$1</a>')

  // Process line by line, grouping into paragraphs and lists
  const lines = html.split('\n')
  const result = []
  let currentParagraph = []
  let currentList = []
  let listType = null // 'ul' or 'ol'

  const flushParagraph = () => {
    if (currentParagraph.length > 0) {
      result.push(`<p>${currentParagraph.join(' ')}</p>`)
      currentParagraph = []
    }
  }

  const flushList = () => {
    if (currentList.length > 0 && listType) {
      const tag = listType
      const items = currentList.map(item => `<li>${item}</li>`).join('')
      result.push(`<${tag} class="list-${listType === 'ul' ? 'disc' : 'decimal'} list-inside space-y-1 my-2">${items}</${tag}>`)
      currentList = []
      listType = null
    }
  }

  let inPreBlock = false
  let preBlockLines = []
  for (const line of lines) {
    const trimmed = line.trim()

    // Check if we're entering or in a pre block
    if (trimmed.startsWith('<pre')) {
      flushParagraph()
      flushList()
      inPreBlock = true
      preBlockLines = [line]
      if (trimmed.includes('</pre>')) {
        // Single-line pre block
        result.push(line)
        inPreBlock = false
        preBlockLines = []
      }
      continue
    }

    if (inPreBlock) {
      preBlockLines.push(line)
      if (trimmed.includes('</pre>')) {
        // Join pre block lines with newlines to preserve formatting
        result.push(preBlockLines.join('\n'))
        inPreBlock = false
        preBlockLines = []
      }
      continue
    }

    // Check for unordered list item
    const ulMatch = trimmed.match(/^[-•]\s+(.*)$/)
    // Check for ordered list item
    const olMatch = trimmed.match(/^\d+\.\s+(.*)$/)

    if (ulMatch) {
      flushParagraph()
      if (listType && listType !== 'ul') {
        flushList()
      }
      listType = 'ul'
      currentList.push(ulMatch[1])
    } else if (olMatch) {
      flushParagraph()
      if (listType && listType !== 'ol') {
        flushList()
      }
      listType = 'ol'
      currentList.push(olMatch[1])
    } else if (trimmed === '') {
      // Empty line - flush everything
      flushParagraph()
      flushList()
    } else {
      // Regular text
      flushList()
      currentParagraph.push(trimmed)
    }
  }

  // Flush remaining content
  flushParagraph()
  flushList()

  return result.join('')
})
</script>

<style scoped>
.markdown-text :deep(p) {
  margin-bottom: 0.75rem;
}
.markdown-text :deep(p:last-child) {
  margin-bottom: 0;
}
.markdown-text :deep(ul),
.markdown-text :deep(ol) {
  margin-top: 0.75rem;
  margin-bottom: 0.75rem;
}
.markdown-text :deep(li) {
  margin-bottom: 0.25rem;
}
.markdown-text :deep(strong) {
  color: var(--tw-prose-bold, #111827);
  font-weight: 600;
}
:root.dark .markdown-text :deep(strong) {
  color: #f3f4f6;
}
</style>
