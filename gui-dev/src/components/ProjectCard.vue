<template>
  <div class="group relative overflow-hidden rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm transition-all duration-300 hover:shadow-xl hover:shadow-zinc-900/5 dark:border-zinc-800 dark:bg-zinc-900 dark:hover:shadow-sky-500/5">
    <!-- Gradient blob -->
    <div class="absolute -right-6 -top-6 h-24 w-24 rounded-full bg-gradient-to-br from-sky-500/10 to-sky-600/10 blur-2xl transition-all duration-300 group-hover:scale-150"></div>

    <div class="relative">
      <div class="flex items-start justify-between">
        <div class="flex-1">
          <div class="flex items-center gap-3">
            <ProjectTypeIcon :type="project.type" />
            <Badge variant="sky">
              {{ typeLabel }}
            </Badge>
          </div>

          <h3 class="mt-4 text-xl font-bold text-zinc-900 dark:text-white">
            {{ project.name }}
          </h3>
          <p class="mt-2 text-sm text-zinc-600 dark:text-zinc-400 font-mono truncate">
            {{ project.path }}
          </p>

          <!-- Author info if available -->
          <ProjectAuthor v-if="project.author" :author="project" class="mt-3" />

          <!-- Created date -->
          <ProjectCreatedDate :date="project.created" class="mt-3" />
        </div>
      </div>

      <div class="mt-6 flex gap-2">
        <Button
          variant="primary"
          size="md"
          @click="$emit('view', project)"
          class="flex-1"
        >
          View Project
        </Button>
        <Button
          variant="secondary"
          size="md"
          @click="$emit('details', project)"
          class="flex-1"
        >
          See More
        </Button>
      </div>
    </div>
  </div>
</template>

<script setup>
import ProjectTypeIcon from './ProjectTypeIcon.vue'
import ProjectAuthor from './ProjectAuthor.vue'
import ProjectCreatedDate from './ProjectCreatedDate.vue'
import Badge from './ui/Badge.vue'
import Button from './ui/Button.vue'

defineProps({
  project: {
    type: Object,
    required: true
  },
  typeLabel: {
    type: String,
    required: true
  }
})

defineEmits(['view', 'details'])
</script>
