<template>
  <div class="flex min-h-screen bg-white dark:bg-zinc-900">
    <!-- Sidebar -->
    <div class="hidden lg:fixed lg:inset-y-0 lg:z-50 lg:flex lg:w-72 lg:flex-col xl:w-80">
      <div class="flex grow flex-col overflow-y-auto border-r border-zinc-900/10 px-6 pb-8 pt-4 dark:border-white/10">
        <!-- Logo -->
        <router-link to="/" class="flex items-center gap-3">
          <img src="/framework-logo.png" alt="Framework" class="h-10 w-10" />
          <span class="text-lg font-semibold text-zinc-900 dark:text-white">Framework</span>
        </router-link>

        <!-- Navigation -->
        <nav class="mt-10">
          <ul role="list">
            <!-- Framework Section -->
            <li class="relative mt-6">
              <h2 class="text-xs font-semibold text-zinc-900 dark:text-white">
                Framework
              </h2>
              <div class="relative mt-3 pl-2">
                <div class="absolute inset-y-0 left-2 w-px bg-zinc-900/10 dark:bg-white/5"></div>
                <!-- Active page marker -->
                <div
                  v-if="getActiveGroupIndex('framework') >= 0"
                  class="absolute left-2 h-6 w-px bg-sky-500 transition-all duration-200"
                  :style="{ top: `${getActiveGroupIndex('framework') * 32 + 4}px` }"
                ></div>
                <ul role="list" class="border-l border-transparent">
                  <li v-for="tab in frameworkTabs" :key="tab.id" class="relative">
                    <router-link
                      :to="tab.to"
                      :class="[
                        'flex justify-between gap-2 py-1 pl-4 pr-3 text-sm transition',
                        $route.path.startsWith(tab.to)
                          ? 'text-zinc-900 dark:text-white'
                          : 'text-zinc-600 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-white'
                      ]"
                    >
                      <span class="truncate">{{ tab.label }}</span>
                    </router-link>
                  </li>
                </ul>
              </div>
            </li>

            <!-- Projects Section -->
            <li v-if="projects.length > 0" class="relative mt-6">
              <h2 class="text-xs font-semibold text-zinc-900 dark:text-white">
                Your Projects
              </h2>
              <div class="relative mt-3 pl-2">
                <div class="absolute inset-y-0 left-2 w-px bg-zinc-900/10 dark:bg-white/5"></div>
                <!-- Active page marker -->
                <div
                  v-if="getActiveProjectIndex() >= 0"
                  class="absolute left-2 h-6 w-px bg-sky-500 transition-all duration-200"
                  :style="{ top: `${getActiveProjectIndex() * 32 + 4}px` }"
                ></div>
                <ul role="list" class="border-l border-transparent">
                  <li v-for="project in projects" :key="project.id" class="relative">
                    <router-link
                      :to="`/project/${project.id}`"
                      :class="[
                        'flex justify-between gap-2 py-1 pl-4 pr-3 text-sm transition',
                        $route.path === `/project/${project.id}`
                          ? 'text-zinc-900 dark:text-white'
                          : 'text-zinc-600 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-white'
                      ]"
                    >
                      <span class="truncate">{{ project.name }}</span>
                      <span v-if="project.type" class="text-xs text-zinc-400 dark:text-zinc-500">
                        {{ project.type === 'project' ? '📁' : project.type === 'course' ? '📚' : '📊' }}
                      </span>
                    </router-link>
                  </li>
                </ul>
              </div>
            </li>

            <!-- Dark Mode Toggle -->
            <li class="sticky bottom-0 mt-6 border-t border-zinc-900/10 pt-6 dark:border-white/10">
              <button
                @click="toggleDarkMode"
                class="flex w-full items-center gap-3 text-sm text-zinc-600 transition hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-white"
              >
                <component :is="isDark ? SunIcon : MoonIcon" class="h-5 w-5 shrink-0" />
                {{ isDark ? 'Light Mode' : 'Dark Mode' }}
              </button>
            </li>
          </ul>
        </nav>
      </div>
    </div>

    <!-- Main content -->
    <div class="lg:pl-72 xl:pl-80 w-full">
      <main class="h-screen overflow-auto">
        <router-view />
      </main>
    </div>

    <!-- Toast notifications (global) -->
    <ToastContainer ref="toastContainer" />
  </div>
</template>

<script setup>
import { ref, h, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useDarkMode } from './composables/useDarkMode'
import ToastContainer from './components/ui/ToastContainer.vue'
import { setToastContainer } from './composables/useToast'

const toastContainer = ref(null)

const route = useRoute()
const { isDark, toggle: toggleDarkMode } = useDarkMode()
const projects = ref([])

const getActiveGroupIndex = (group) => {
  const tabs = frameworkTabs
  return tabs.findIndex(tab => route.path.startsWith(tab.to))
}

const getActiveProjectIndex = () => {
  return projects.value.findIndex(project => route.path === `/project/${project.id}`)
}

// Icons for dark mode toggle
const MoonIcon = () => h('svg', { class: 'h-5 w-5', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z' })
])

const SunIcon = () => h('svg', { class: 'h-5 w-5', fill: 'none', viewBox: '0 0 24 24', stroke: 'currentColor' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z' })
])

// Framework tabs (always visible)
const frameworkTabs = [
  { id: 'projects', label: 'Projects', to: '/projects' },
  { id: 'settings', label: 'Global Settings', to: '/settings' }
]

// Load projects and initialize
onMounted(async () => {
  // Initialize toast container
  setToastContainer(toastContainer.value)

  // Load projects from API
  try {
    const response = await fetch('/api/settings/get')
    const data = await response.json()

    // Set projects with enriched metadata
    projects.value = data.projects || []
  } catch (error) {
    console.error('Failed to load projects:', error)
  }
})
</script>
