<template>
  <div class="rounded-lg border border-gray-300 overflow-hidden dark:border-gray-600">
    <div ref="editorRef"></div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { EditorView, basicSetup } from 'codemirror'
import { EditorState } from '@codemirror/state'
import { syntaxHighlighting, HighlightStyle } from '@codemirror/language'
import { tags } from '@lezer/highlight'
import { StreamLanguage } from '@codemirror/language'

const props = defineProps({
  modelValue: {
    type: String,
    default: ''
  },
  language: {
    type: String,
    default: 'r',
    validator: (value) => ['r', 'markdown', 'text'].includes(value)
  },
  minHeight: {
    type: String,
    default: '400px'
  },
  disabled: {
    type: Boolean,
    default: false
  },
  placeholder: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['update:modelValue'])

const editorRef = ref(null)
let editorView = null

// Simple comment highlighter - just makes lines starting with # green
const commentHighlighter = StreamLanguage.define({
  token(stream) {
    if (stream.sol() && stream.match(/^#/)) {
      stream.skipToEnd()
      return 'comment'
    }
    stream.skipToEnd()
    return null
  }
})

// Simple styling - just green comments
const commentHighlighting = syntaxHighlighting(HighlightStyle.define([
  { tag: tags.comment, color: '#16a34a' } // green-600
]))

const getLanguageExtension = () => {
  return [commentHighlighter, commentHighlighting]
}

onMounted(() => {
  if (!editorRef.value) return

  const updateListener = EditorView.updateListener.of((update) => {
    if (update.docChanged) {
      emit('update:modelValue', update.state.doc.toString())
    }
  })

  const extensions = [
    basicSetup,
    getLanguageExtension(),
    updateListener,
    EditorView.theme({
      '&': {
        minHeight: props.minHeight,
        fontSize: '13px',
        fontFamily: 'ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, "Liberation Mono", monospace'
      },
      '.cm-scroller': {
        fontFamily: 'ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, "Liberation Mono", monospace'
      },
      '.cm-content': {
        padding: '12px 0'
      },
      '.cm-line': {
        padding: '0 12px'
      }
    })
  ]

  const startState = EditorState.create({
    doc: props.modelValue || '',
    extensions
  })

  editorView = new EditorView({
    state: startState,
    parent: editorRef.value
  })
})

watch(() => props.modelValue, (newValue) => {
  if (editorView && newValue !== editorView.state.doc.toString()) {
    editorView.dispatch({
      changes: {
        from: 0,
        to: editorView.state.doc.length,
        insert: newValue
      }
    })
  }
})
</script>
