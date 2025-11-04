<template>
  <div>
    <div v-if="loading" class="flex items-center justify-center h-96">
      <div class="text-zinc-600 dark:text-zinc-400">Loading project...</div>
    </div>

    <div v-else-if="error" class="flex-1 p-10">
      <Alert type="error" title="Error Loading Project" :description="error" />
    </div>

    <div v-else-if="project" class="flex min-h-screen">
    <!-- Left Sidebar -->
    <nav class="w-64 shrink-0 border-r border-gray-200 p-6 dark:border-gray-800">
      <h2 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">{{ project.name }}</h2>
      <div class="flex items-center gap-2 mb-4">
        <span class="text-xs text-gray-500 dark:text-gray-400 font-mono truncate">{{ project.path }}</span>
        <CopyButton :value="project.path" variant="ghost" successMessage="Path copied" class="shrink-0" />
      </div>

      <div class="space-y-1">
        <a
          href="#overview"
          @click.prevent="activeSection = 'overview'"
          :class="getSidebarLinkClasses('overview')"
        >
          <InformationCircleIcon class="h-4 w-4" />
          Overview
        </a>

        <!-- SETTINGS Heading -->
        <div class="pt-4 pb-2">
          <h3 class="px-3 text-xs font-semibold text-gray-500 uppercase tracking-wider dark:text-gray-400">
            Settings
          </h3>
        </div>

        <a
          href="#settings"
          @click.prevent="activeSection = 'settings'"
          :class="getSidebarLinkClasses('settings')"
        >
          <Cog6ToothIcon class="h-4 w-4" />
          Project Settings
        </a>

        <!-- Settings Sub-links -->
        <div v-if="activeSection === 'settings'" class="ml-6 space-y-0.5 mt-1">
          <a
            href="#settings-project"
            @click.prevent="scrollToSection('settings-project')"
            class="flex items-center gap-2 px-3 py-1 rounded-md text-xs text-gray-600 hover:bg-gray-50 dark:text-gray-400 dark:hover:bg-gray-800 transition"
          >
            Project Information
          </a>
          <a
            href="#settings-author"
            @click.prevent="scrollToSection('settings-author')"
            class="flex items-center gap-2 px-3 py-1 rounded-md text-xs text-gray-600 hover:bg-gray-50 dark:text-gray-400 dark:hover:bg-gray-800 transition"
          >
            Author Information
          </a>
          <a
            href="#settings-options"
            @click.prevent="scrollToSection('settings-options')"
            class="flex items-center gap-2 px-3 py-1 rounded-md text-xs text-gray-600 hover:bg-gray-50 dark:text-gray-400 dark:hover:bg-gray-800 transition"
          >
            Project Options
          </a>
          <a
            href="#settings-git"
            @click.prevent="scrollToSection('settings-git')"
            class="flex items-center gap-2 px-3 py-1 rounded-md text-xs text-gray-600 hover:bg-gray-50 dark:text-gray-400 dark:hover:bg-gray-800 transition"
          >
            Git Configuration
          </a>
          <a
            href="#settings-ai"
            @click.prevent="scrollToSection('settings-ai')"
            class="flex items-center gap-2 px-3 py-1 rounded-md text-xs text-gray-600 hover:bg-gray-50 dark:text-gray-400 dark:hover:bg-gray-800 transition"
          >
            AI Assistant
          </a>
        </div>

        <a
          href="#connections"
          @click.prevent="activeSection = 'connections'"
          :class="getSidebarLinkClasses('connections')"
        >
          <ServerIcon class="h-4 w-4" />
          Connections
        </a>

        <!-- Connection Sub-links -->
        <div v-if="activeSection === 'connections' && connections && connections.connections" class="ml-6 space-y-0.5 mt-1">
          <a
            v-for="(conn, name) in connections.connections"
            :key="name"
            :href="`#connection-${name}`"
            @click.prevent="scrollToConnection(name)"
            class="flex items-center gap-2 px-3 py-1 rounded-md text-xs text-gray-600 hover:bg-gray-50 dark:text-gray-400 dark:hover:bg-gray-800 transition"
          >
            {{ name }}
          </a>
        </div>

        <a
          href="#packages"
          @click.prevent="activeSection = 'packages'"
          :class="getSidebarLinkClasses('packages')"
        >
          <CubeIcon class="h-4 w-4" />
          Packages
        </a>

        <a
          href="#directories"
          @click.prevent="activeSection = 'directories'"
          :class="getSidebarLinkClasses('directories')"
        >
          <FolderIcon class="h-4 w-4" />
          Directories
        </a>

        <!-- Directory Sub-links -->
        <div v-if="activeSection === 'directories'" class="ml-6 space-y-0.5 mt-1">
          <a
            href="#directory-work"
            @click.prevent="scrollToSection('directory-work')"
            class="flex items-center gap-2 px-3 py-1 rounded-md text-xs text-gray-600 hover:bg-gray-50 dark:text-gray-400 dark:hover:bg-gray-800 transition"
          >
            Work Directories
          </a>
          <a
            href="#directory-inputs"
            @click.prevent="scrollToSection('directory-inputs')"
            class="flex items-center gap-2 px-3 py-1 rounded-md text-xs text-gray-600 hover:bg-gray-50 dark:text-gray-400 dark:hover:bg-gray-800 transition"
          >
            Input Directories
          </a>
          <a
            href="#directory-private-outputs"
            @click.prevent="scrollToSection('directory-private-outputs')"
            class="flex items-center gap-2 px-3 py-1 rounded-md text-xs text-gray-600 hover:bg-gray-50 dark:text-gray-400 dark:hover:bg-gray-800 transition"
          >
            Private Outputs
          </a>
          <a
            href="#directory-public-outputs"
            @click.prevent="scrollToSection('directory-public-outputs')"
            class="flex items-center gap-2 px-3 py-1 rounded-md text-xs text-gray-600 hover:bg-gray-50 dark:text-gray-400 dark:hover:bg-gray-800 transition"
          >
            Public Outputs
          </a>
          <a
            href="#directory-other"
            @click.prevent="scrollToSection('directory-other')"
            class="flex items-center gap-2 px-3 py-1 rounded-md text-xs text-gray-600 hover:bg-gray-50 dark:text-gray-400 dark:hover:bg-gray-800 transition"
          >
            Other
          </a>
        </div>

        <a
          href="#data"
          @click.prevent="activeSection = 'data'"
          :class="getSidebarLinkClasses('data')"
        >
          <CircleStackIcon class="h-4 w-4" />
          Data
        </a>

        <a
          href="#env"
          @click.prevent="activeSection = 'env'"
          :class="getSidebarLinkClasses('env')"
        >
          <KeyIcon class="h-4 w-4" />
          .env
        </a>

        <!-- OUTPUTS Heading -->
        <div class="pt-4 pb-2">
          <h3 class="px-3 text-xs font-semibold text-gray-500 uppercase tracking-wider dark:text-gray-400">
            Outputs
          </h3>
        </div>

        <a
          href="#notebooks"
          @click.prevent="activeSection = 'notebooks'"
          :class="getSidebarLinkClasses('notebooks')"
        >
          <DocumentTextIcon class="h-4 w-4" />
          Notebooks
        </a>
      </div>
    </nav>

    <!-- Main Content -->
    <div class="flex-1 p-10">
      <!-- Overview Section -->
      <div v-show="activeSection === 'overview'" id="overview">
        <div class="flex items-start justify-between mb-6">
          <div>
            <h2 class="text-2xl font-semibold text-gray-900 dark:text-white">{{ project.name }}</h2>
            <Badge variant="sky" class="mt-2">{{ project.type }}</Badge>
          </div>
        </div>

        <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
          <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">Project Information</h3>

          <div class="grid grid-cols-2 gap-6">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Project Type
              </label>
              <p class="text-sm text-gray-600 dark:text-gray-400">
                {{ project.type }}
              </p>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Created
              </label>
              <p class="text-sm text-gray-600 dark:text-gray-400">
                {{ project.created }}
              </p>
            </div>
            <div v-if="project.author">
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Author
              </label>
              <p class="text-sm text-gray-600 dark:text-gray-400">
                {{ project.author }}
              </p>
            </div>
            <div v-if="project.author_email">
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Email
              </label>
              <p class="text-sm text-gray-600 dark:text-gray-400">
                {{ project.author_email }}
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Settings Section -->
      <div v-show="activeSection === 'settings'" id="settings">
        <div v-if="settingsLoading">
          <div class="text-center py-12 text-zinc-500 dark:text-zinc-400">
            Loading settings...
          </div>
        </div>

        <div v-else-if="settingsError">
          <Alert type="error" title="Error Loading Settings" :description="settingsError" />
        </div>

        <div v-else>
          <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Project Settings</h2>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
            Configure settings for this project.
          </p>

          <div class="space-y-6">
            <!-- Project Info -->
            <div id="settings-project" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 scroll-mt-6">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">Project Information</h3>

              <div class="space-y-4">
                <Input
                  v-model="editableSettings.project_name"
                  label="Project Name"
                  hint="Display name for this project"
                />

                <div>
                  <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-2">
                    Project Type
                  </label>
                  <div class="flex gap-4">
                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="radio"
                        v-model="editableSettings.project_type"
                        value="project"
                        class="text-sky-600 focus:ring-sky-500"
                      />
                      <span class="text-sm text-zinc-700 dark:text-zinc-300">Project</span>
                    </label>
                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="radio"
                        v-model="editableSettings.project_type"
                        value="course"
                        class="text-sky-600 focus:ring-sky-500"
                      />
                      <span class="text-sm text-zinc-700 dark:text-zinc-300">Course</span>
                    </label>
                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="radio"
                        v-model="editableSettings.project_type"
                        value="presentation"
                        class="text-sky-600 focus:ring-sky-500"
                      />
                      <span class="text-sm text-zinc-700 dark:text-zinc-300">Presentation</span>
                    </label>
                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="radio"
                        v-model="editableSettings.project_type"
                        value="project_sensitive"
                        class="text-sky-600 focus:ring-sky-500"
                      />
                      <span class="text-sm text-zinc-700 dark:text-zinc-300">Sensitive</span>
                    </label>
                  </div>
                </div>
              </div>
            </div>

            <!-- Author Info -->
            <div id="settings-author" v-if="editableSettings.author" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 scroll-mt-6">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">Author Information</h3>

              <div class="grid grid-cols-2 gap-4">
                <Input
                  v-model="editableSettings.author.name"
                  label="Author Name"
                />
                <Input
                  v-model="editableSettings.author.email"
                  label="Email"
                  type="email"
                />
                <Input
                  v-model="editableSettings.author.affiliation"
                  label="Affiliation"
                  class="col-span-2"
                />
              </div>
            </div>

            <!-- Options -->
            <div id="settings-options" v-if="editableSettings.options" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 scroll-mt-6">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">Project Options</h3>

              <div class="space-y-4">
                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-2">
                      Default Notebook Format
                    </label>
                    <div class="flex gap-4">
                      <label class="flex items-center gap-2 cursor-pointer">
                        <input
                          type="radio"
                          v-model="editableSettings.options.default_notebook_format"
                          value="quarto"
                          class="text-sky-600 focus:ring-sky-500"
                        />
                        <span class="text-sm text-zinc-700 dark:text-zinc-300">Quarto</span>
                      </label>
                      <label class="flex items-center gap-2 cursor-pointer">
                        <input
                          type="radio"
                          v-model="editableSettings.options.default_notebook_format"
                          value="rmarkdown"
                          class="text-sky-600 focus:ring-sky-500"
                        />
                        <span class="text-sm text-zinc-700 dark:text-zinc-300">RMarkdown</span>
                      </label>
                    </div>
                  </div>

                  <Input
                    v-model.number="editableSettings.options.seed"
                    label="Random Seed"
                    type="number"
                    hint="For reproducibility (YYYYMMDD format)"
                  />
                </div>

                <Toggle
                  v-model="editableSettings.options.seed_on_scaffold"
                  label="Set Seed on Scaffold"
                  description="Automatically set random seed when loading project"
                />
              </div>
            </div>

            <!-- Git Settings -->
            <div id="settings-git" v-if="editableSettings.git" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 scroll-mt-6">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">Git Configuration</h3>

              <div class="space-y-4">
                <Input
                  v-model="editableSettings.git.url"
                  label="Repository URL"
                  hint="Git repository URL for this project"
                />
                <div class="grid grid-cols-2 gap-4">
                  <Input
                    v-model="editableSettings.git.author"
                    label="Git Author"
                  />
                  <Input
                    v-model="editableSettings.git.email"
                    label="Git Email"
                    type="email"
                  />
                </div>
              </div>
            </div>

            <!-- AI Settings -->
            <div id="settings-ai" v-if="editableSettings.ai" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 scroll-mt-6">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">AI Assistant Configuration</h3>

              <Input
                v-model="editableSettings.ai.canonical_file"
                label="Canonical AI File"
                hint="Main file for AI context (e.g., CLAUDE.md)"
              />
            </div>

            <!-- Save Button -->
            <div class="flex justify-end gap-3 pt-4 border-t border-zinc-200 dark:border-zinc-700">
              <Button
                variant="secondary"
                @click="loadProjectSettings"
              >
                Reset
              </Button>
              <Button
                variant="primary"
                @click="saveSettings"
                :disabled="saving"
              >
                {{ saving ? 'Saving...' : 'Save Settings' }}
              </Button>
            </div>
          </div>
        </div>
      </div>

      <!-- Notebooks Section -->
      <div v-show="activeSection === 'notebooks'" id="notebooks">
        <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Rendered Notebooks</h2>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
          Browse and access your rendered Quarto/RMarkdown notebooks.
        </p>

        <div class="rounded-lg bg-gray-50 p-12 dark:bg-gray-800/50 text-center">
          <DocumentTextIcon class="h-12 w-12 mx-auto mb-4 text-gray-400" />
          <p class="text-sm text-gray-500 dark:text-gray-400">
            Notebook browser coming soon...
          </p>
        </div>
      </div>

      <!-- Data Section -->
      <div v-show="activeSection === 'data'" id="data">
        <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Data Catalog</h2>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
          Browse your project's data sources with copy commands.
        </p>

        <div v-if="dataCatalog && Object.keys(flattenedDataCatalog).length > 0" class="rounded-lg bg-gray-50 dark:bg-gray-800/50">
          <div class="divide-y divide-zinc-200 dark:divide-zinc-700">
            <div
              v-for="(item, key) in flattenedDataCatalog"
              :key="key"
              class="p-4 first:rounded-t-lg last:rounded-b-lg"
            >
              <div class="flex items-start justify-between gap-4">
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 mb-1">
                    <h4 class="text-sm font-semibold text-zinc-900 dark:text-white font-mono">
                      {{ key }}
                    </h4>
                    <Badge variant="gray" class="text-xs">{{ item.type || 'csv' }}</Badge>
                  </div>
                  <p class="text-xs text-zinc-500 dark:text-zinc-400 font-mono truncate">
                    {{ item.path }}
                  </p>
                </div>
                <div class="flex items-center gap-2 shrink-0">
                  <CopyButton
                    :value="item.path"
                    successMessage="Path copied"
                    variant="ghost"
                    title="Copy path"
                  />
                  <CopyButton
                    :value="`data_read('${key}')`"
                    successMessage="data_read() command copied"
                    variant="ghost"
                    title="Copy data_read() command"
                  />
                  <CopyButton
                    :value="key"
                    successMessage="Dot notation copied"
                    variant="ghost"
                    title="Copy dot notation"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>

        <EmptyState
          v-else
          title="No Data Sources"
          description="This project doesn't have any data sources defined in its settings"
          icon="database"
        />
      </div>

      <!-- Connections Section -->
      <div v-show="activeSection === 'connections'" id="connections">
        <div v-if="connectionsLoading">
          <div class="text-center py-12 text-zinc-500 dark:text-zinc-400">
            Loading connections...
          </div>
        </div>

        <div v-else-if="connectionsError">
          <Alert type="error" title="Error Loading Connections" :description="connectionsError" />
        </div>

        <div v-else>
          <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Connections</h2>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
            Manage database and external service connections for this project.
          </p>

          <div class="space-y-6">
            <!-- Default Connection Option -->
            <div v-if="connections && connections.options" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">Connection Options</h3>
              <Input
                v-model="connections.options.default_connection"
                label="Default Connection"
                hint="Name of the default connection to use"
              />
            </div>

            <!-- Connections List -->
            <div v-if="connections && connections.connections">
              <div v-if="Object.keys(connections.connections).length === 0" class="rounded-lg bg-gray-50 p-12 dark:bg-gray-800/50 text-center">
                <ServerIcon class="h-12 w-12 mx-auto mb-4 text-gray-400" />
                <p class="text-sm text-gray-500 dark:text-gray-400">
                  No connections defined yet
                </p>
              </div>

              <div v-else class="space-y-4">
                <div
                  v-for="(conn, name) in connections.connections"
                  :key="name"
                  :id="`connection-${name}`"
                  :class="[
                    'rounded-lg p-6 scroll-mt-6 relative transition',
                    connectionsToDelete.has(name)
                      ? 'bg-red-50 dark:bg-red-900/10 opacity-60'
                      : 'bg-gray-50 dark:bg-gray-800/50'
                  ]"
                >
                  <!-- Delete Button -->
                  <button
                    @click="toggleConnectionDelete(name)"
                    :class="[
                      'absolute top-3 right-3 p-1.5 rounded-md border border-gray-300 transition dark:border-gray-600',
                      connectionsToDelete.has(name)
                        ? 'text-gray-600 hover:bg-gray-100 hover:border-gray-400 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:border-gray-500'
                        : 'text-red-700 hover:bg-gray-100 hover:border-red-600 dark:text-red-400 dark:hover:bg-gray-700 dark:hover:border-red-500'
                    ]"
                    :title="connectionsToDelete.has(name) ? 'Undo delete' : 'Delete connection'"
                  >
                    <svg v-if="connectionsToDelete.has(name)" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 15L3 9m0 0l6-6M3 9h12a6 6 0 010 12h-3" />
                    </svg>
                    <svg v-else class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                    </svg>
                  </button>

                  <div :class="{ 'line-through opacity-50': connectionsToDelete.has(name) }">
                    <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4 font-mono pr-8">
                      {{ name }}
                    </h3>

                    <div class="space-y-4">
                      <div v-for="(value, key) in conn" :key="key">
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                          {{ key }}
                        </label>
                        <input
                          v-model="connections.connections[name][key]"
                          type="text"
                          :disabled="connectionsToDelete.has(name)"
                          class="w-full rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2 text-sm text-gray-900 dark:text-gray-100 focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500 font-mono disabled:opacity-50 disabled:cursor-not-allowed"
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Save Button -->
            <div class="flex justify-end gap-3 pt-4 border-t border-zinc-200 dark:border-zinc-700">
              <Button
                variant="secondary"
                @click="loadConnections"
              >
                Reset
              </Button>
              <Button
                variant="primary"
                @click="saveConnections"
                :disabled="savingConnections"
              >
                {{ savingConnections ? 'Saving...' : 'Save Connections' }}
              </Button>
            </div>
          </div>
        </div>
      </div>

      <!-- Packages Section -->
      <div v-show="activeSection === 'packages'" id="packages">
        <div v-if="packagesLoading">
          <div class="text-center py-12">
            <div class="text-sm text-gray-500 dark:text-gray-400">Loading packages...</div>
          </div>
        </div>

        <div v-else-if="packagesError">
          <Alert type="error" title="Error Loading Packages" :description="packagesError" />
        </div>

        <div v-else>
          <div class="mb-6">
            <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Package Management</h2>
            <p class="text-sm text-gray-600 dark:text-gray-400">
              Manage R packages for this project. Packages with auto-attach will be loaded when scaffold() runs.
            </p>
          </div>

          <!-- Empty State -->
          <div v-if="packages.length === 0" class="rounded-lg bg-gray-50 p-12 dark:bg-gray-800/50 text-center mb-6">
            <CubeIcon class="h-12 w-12 mx-auto mb-4 text-gray-400" />
            <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
              No packages configured
            </p>
            <Button variant="primary" @click="addPackage">
              Add Your First Package
            </Button>
          </div>

          <!-- Package List -->
          <div v-else class="space-y-6">
            <!-- Top Actions -->
            <div class="flex items-center justify-between">
              <Button variant="primary" size="sm" @click="addPackage">
                + Add Package
              </Button>
              <div class="flex gap-3">
                <Button
                  variant="secondary"
                  @click="loadPackages"
                >
                  Reset
                </Button>
                <Button
                  variant="primary"
                  @click="savePackages"
                  :disabled="savingPackages"
                >
                  {{ savingPackages ? 'Saving...' : 'Save Packages' }}
                </Button>
              </div>
            </div>

            <!-- Package Table -->
            <div class="rounded-lg bg-gray-50 dark:bg-gray-800/50 overflow-hidden">
              <table class="w-full">
                <thead>
                  <tr class="border-b border-gray-200 dark:border-gray-700">
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-700 dark:text-gray-300">
                      Package Name
                    </th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-700 dark:text-gray-300">
                      Source
                    </th>
                    <th class="px-4 py-3 text-center text-xs font-semibold text-gray-700 dark:text-gray-300">
                      Auto-attach
                    </th>
                    <th class="px-4 py-3 text-center text-xs font-semibold text-gray-700 dark:text-gray-300 w-20">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-white dark:bg-gray-900">
                  <tr
                    v-for="(pkg, index) in packages"
                    :key="index"
                    class="border-b border-gray-200 dark:border-gray-700 last:border-b-0"
                  >
                    <!-- Package Name -->
                    <td class="px-4 py-3">
                      <input
                        v-model="pkg.name"
                        type="text"
                        placeholder="dplyr"
                        class="w-full rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2 text-sm text-gray-900 dark:text-gray-100 font-mono focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500"
                      />
                    </td>

                    <!-- Source -->
                    <td class="px-4 py-3">
                      <div class="relative">
                        <select
                          v-model="pkg.source"
                          class="w-full appearance-none rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 pl-3 pr-10 py-2 text-sm text-gray-900 dark:text-gray-100 focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500"
                        >
                          <option value="cran">CRAN</option>
                          <option value="github">GitHub</option>
                          <option value="bioc">Bioconductor</option>
                        </select>
                        <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3">
                          <svg class="h-4 w-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                          </svg>
                        </div>
                      </div>
                    </td>

                    <!-- Auto-attach -->
                    <td class="px-4 py-3 text-center">
                      <input
                        v-model="pkg.auto_attach"
                        type="checkbox"
                        style="accent-color: rgb(2, 132, 199)"
                        class="h-4 w-4 rounded border-gray-300 focus:ring-sky-500 dark:border-gray-600"
                      />
                    </td>

                    <!-- Actions -->
                    <td class="px-4 py-3 text-center">
                      <button
                        @click="removePackage(index)"
                        class="text-xs text-gray-600 hover:text-gray-900 font-medium dark:text-gray-400 dark:hover:text-gray-200"
                      >
                        Delete
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Bottom Actions -->
            <div class="flex items-center justify-between pt-4 border-t border-gray-200 dark:border-gray-700">
              <Button variant="primary" size="sm" @click="addPackage">
                + Add Package
              </Button>
              <div class="flex gap-3">
                <Button
                  variant="secondary"
                  @click="loadPackages"
                >
                  Reset
                </Button>
                <Button
                  variant="primary"
                  @click="savePackages"
                  :disabled="savingPackages"
                >
                  {{ savingPackages ? 'Saving...' : 'Save Packages' }}
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Directories Section -->
      <div v-show="activeSection === 'directories'" id="directories">
        <div v-if="directoriesLoading">
          <div class="text-center py-12">
            <div class="text-sm text-gray-500 dark:text-gray-400">Loading directories...</div>
          </div>
        </div>

        <div v-else-if="directoriesError">
          <Alert type="error" title="Error Loading Directories" :description="directoriesError" />
        </div>

        <div v-else>
          <div class="mb-6">
            <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Project Directories</h2>
            <p class="text-sm text-gray-600 dark:text-gray-400">
              Override directory structure for this project. Leave empty to use global defaults.
            </p>
          </div>

          <div class="space-y-6">
            <!-- Work Directories -->
            <div id="directory-work" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 scroll-mt-6">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">Work Directories</h3>
              <div class="space-y-4">
                <Input
                  v-model="directories.notebooks"
                  label="Notebooks"
                  placeholder="notebooks"
                />
                <Input
                  v-model="directories.scripts"
                  label="Scripts"
                  placeholder="scripts"
                />
                <Input
                  v-model="directories.functions"
                  label="Functions"
                  placeholder="functions"
                />
              </div>
            </div>

            <!-- Input Directories -->
            <div id="directory-inputs" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 scroll-mt-6">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">Input Directories</h3>
              <div class="space-y-4">
                <Input
                  v-model="directories.inputs_raw"
                  label="Raw Inputs"
                  placeholder="inputs/raw"
                />
                <Input
                  v-model="directories.inputs_intermediate"
                  label="Intermediate Inputs"
                  placeholder="inputs/intermediate"
                />
                <Input
                  v-model="directories.inputs_final"
                  label="Final Inputs"
                  placeholder="inputs/final"
                />
                <Input
                  v-model="directories.reference"
                  label="Reference Materials"
                  placeholder="reference"
                />
              </div>
            </div>

            <!-- Private Output Directories -->
            <div id="directory-private-outputs" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 scroll-mt-6">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">Private Outputs</h3>
              <div class="space-y-4">
                <Input
                  v-model="directories.outputs_tables"
                  label="Tables"
                  placeholder="outputs/private/tables"
                />
                <Input
                  v-model="directories.outputs_figures"
                  label="Figures"
                  placeholder="outputs/private/figures"
                />
                <Input
                  v-model="directories.outputs_models"
                  label="Models"
                  placeholder="outputs/private/models"
                />
                <Input
                  v-model="directories.outputs_notebooks"
                  label="Notebooks"
                  placeholder="outputs/private/notebooks"
                />
                <Input
                  v-model="directories.outputs_docs"
                  label="Docs"
                  placeholder="outputs/private/docs"
                />
                <Input
                  v-model="directories.outputs_final"
                  label="Final"
                  placeholder="outputs/private/final"
                />
              </div>
            </div>

            <!-- Public Output Directories -->
            <div id="directory-public-outputs" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 scroll-mt-6">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">Public Outputs</h3>
              <div class="space-y-4">
                <Input
                  v-model="directories.outputs_tables_public"
                  label="Tables"
                  placeholder="outputs/public/tables"
                />
                <Input
                  v-model="directories.outputs_figures_public"
                  label="Figures"
                  placeholder="outputs/public/figures"
                />
                <Input
                  v-model="directories.outputs_models_public"
                  label="Models"
                  placeholder="outputs/public/models"
                />
                <Input
                  v-model="directories.outputs_notebooks_public"
                  label="Notebooks"
                  placeholder="outputs/public/notebooks"
                />
                <Input
                  v-model="directories.outputs_docs_public"
                  label="Docs"
                  placeholder="outputs/public/docs"
                />
                <Input
                  v-model="directories.outputs_final_public"
                  label="Final"
                  placeholder="outputs/public/final"
                />
              </div>
            </div>

            <!-- Other Directories -->
            <div id="directory-other" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 scroll-mt-6">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">Other</h3>
              <div class="space-y-4">
                <Input
                  v-model="directories.cache"
                  label="Cache"
                  placeholder="outputs/private/cache"
                />
                <Input
                  v-model="directories.scratch"
                  label="Scratch"
                  placeholder="outputs/private/scratch"
                />
              </div>
            </div>

            <!-- Save Button -->
            <div class="flex justify-end gap-3 pt-4 border-t border-zinc-200 dark:border-zinc-700">
              <Button
                variant="secondary"
                @click="loadDirectories"
              >
                Reset
              </Button>
              <Button
                variant="primary"
                @click="saveDirectories"
                :disabled="savingDirectories"
              >
                {{ savingDirectories ? 'Saving...' : 'Save Directories' }}
              </Button>
            </div>
          </div>
        </div>
      </div>

      <!-- .env Section -->
      <div v-show="activeSection === 'env'" id="env">
        <div v-if="envLoading">
          <div class="text-center py-12 text-zinc-500 dark:text-zinc-400">
            Loading environment variables...
          </div>
        </div>

        <div v-else-if="envError">
          <Alert type="error" title="Error Loading .env" :description="envError" />
        </div>

        <div v-else>
          <div class="mb-6">
            <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Environment Variables</h2>
            <p class="text-sm text-gray-600 dark:text-gray-400">
              Manage environment variables for this project (.env file).
            </p>
          </div>

          <!-- Security Warning -->
          <Alert type="warning" title="⚠️ Contains Sensitive Data" class="mb-6">
            This file contains passwords and secrets. It is automatically excluded from version control (.gitignore).
            <template #actions>
              <Button
                v-if="envViewMode === 'grouped'"
                variant="soft"
                size="sm"
                @click="showEnvValues = !showEnvValues"
              >
                {{ showEnvValues ? 'Hide Values' : 'Show Values' }}
              </Button>
            </template>
          </Alert>

          <!-- View Tabs -->
          <Tabs
            v-model="envViewMode"
            :tabs="[
              { id: 'grouped', label: 'Grouped By Prefix' },
              { id: 'raw', label: 'Raw' }
            ]"
            variant="pills"
            class="mb-6"
          />

          <!-- Grouped View -->
          <div v-if="envViewMode === 'grouped'" class="space-y-6">
            <!-- Variables Grouped by Prefix -->
            <div v-if="Object.keys(envGroups).length === 0" class="rounded-lg bg-gray-50 p-12 dark:bg-gray-800/50 text-center">
              <KeyIcon class="h-12 w-12 mx-auto mb-4 text-gray-400" />
              <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
                No environment variables found
              </p>
              <Button variant="primary" @click="addEnvVariable">
                Add Your First Variable
              </Button>
            </div>

            <div v-else class="space-y-6">
              <div
                v-for="(vars, prefix) in envGroups"
                :key="prefix"
                class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50"
              >
                <div class="flex items-center justify-between mb-4">
                  <h3 class="text-sm font-semibold text-gray-900 dark:text-white">
                    {{ prefix === 'Other' ? 'Other Variables' : prefix.toUpperCase() + ' Variables' }}
                  </h3>
                  <Button variant="soft" size="sm" @click="addEnvVariable">
                    + Add
                  </Button>
                </div>

                <div class="space-y-4">
                  <div
                    v-for="(info, varName) in vars"
                    :key="varName"
                    class="space-y-2"
                  >
                    <div class="flex items-start gap-3">
                      <!-- Status Badge -->
                      <div class="mt-2">
                        <Badge
                          v-if="info.defined && info.used"
                          variant="green"
                          class="text-xs"
                        >✓</Badge>
                        <Badge
                          v-else-if="!info.defined && info.used"
                          variant="yellow"
                          class="text-xs"
                        >⚠</Badge>
                        <Badge
                          v-else
                          variant="gray"
                          class="text-xs"
                        >✗</Badge>
                      </div>

                      <div class="flex-1 grid grid-cols-2 gap-3">
                        <input
                          :value="varName"
                          @input="(e) => {
                            const newKey = e.target.value
                            if (newKey !== varName) {
                              envVariables[newKey] = envVariables[varName] || ''
                              delete envVariables[varName]
                            }
                          }"
                          type="text"
                          placeholder="VARIABLE_NAME"
                          class="w-full rounded-md border border-zinc-300 dark:border-zinc-600 bg-white dark:bg-zinc-800 px-3 py-2 text-sm text-zinc-900 dark:text-zinc-100 focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500 font-mono uppercase"
                        />
                        <div class="relative">
                          <input
                            v-model="envVariables[varName]"
                            @input="info.value = envVariables[varName]"
                            :type="isFieldVisible(varName) ? 'text' : 'password'"
                            :placeholder="info.defined ? 'value' : '(not set)'"
                            :class="[
                              'w-full rounded-md border border-zinc-300 dark:border-zinc-600 bg-white dark:bg-zinc-800 px-3 py-2 text-sm text-zinc-900 dark:text-zinc-100 focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500 font-mono',
                              isPasswordField(varName) ? 'pr-10' : ''
                            ]"
                          />
                          <button
                            v-if="isPasswordField(varName)"
                            @click="toggleFieldVisibility(varName)"
                            type="button"
                            class="absolute right-2 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-300"
                          >
                            <EyeIcon v-if="!isFieldVisible(varName)" class="h-4 w-4" />
                            <EyeSlashIcon v-else class="h-4 w-4" />
                          </button>
                        </div>
                      </div>
                      <Button
                        variant="soft"
                        size="sm"
                        @click="removeEnvVariable(varName)"
                      >
                        ×
                      </Button>
                    </div>

                    <!-- Usage Info -->
                    <div v-if="info.used && info.used_in.length > 0" class="ml-10 text-xs text-zinc-500 dark:text-zinc-400">
                      Used in: {{ info.used_in.join(', ') }}
                    </div>
                    <div v-else-if="info.defined && !info.used" class="ml-10 text-xs text-zinc-400 dark:text-zinc-500">
                      Not referenced in any files
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Regroup Option -->
            <div class="rounded-lg bg-gray-50 p-4 dark:bg-gray-800/50 border border-zinc-200 dark:border-zinc-700">
              <Toggle
                v-model="regroupOnSave"
                label="Regroup .env file by prefix when saving"
                description="⚠️ This will rewrite the entire file grouped by prefix and will lose all comments and original order."
              />
            </div>

            <!-- Save Button -->
            <div class="flex justify-end gap-3 pt-4 border-t border-zinc-200 dark:border-zinc-700">
              <Button
                variant="secondary"
                @click="loadEnv"
              >
                Reset
              </Button>
              <Button
                variant="primary"
                @click="saveEnv"
                :disabled="savingEnv"
              >
                {{ savingEnv ? 'Saving...' : 'Save .env' }}
              </Button>
            </div>
          </div>

          <!-- Raw View -->
          <div v-else-if="envViewMode === 'raw'" class="space-y-6">
            <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">
                Raw .env File
              </h3>
              <textarea
                v-model="envRawContent"
                class="w-full h-96 font-mono text-sm rounded-md border border-zinc-300 dark:border-zinc-600 bg-white dark:bg-zinc-800 px-3 py-2 text-zinc-900 dark:text-zinc-100 focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500"
                placeholder="# Environment variables
# Example:
# DB_HOST=localhost
# DB_PORT=5432
# API_KEY=your_key_here"
              ></textarea>
              <p class="mt-2 text-xs text-gray-500 dark:text-gray-400">
                Edit the .env file directly. Comments and formatting will be preserved.
              </p>
            </div>

            <!-- Save Button -->
            <div class="flex justify-end gap-3 pt-4 border-t border-zinc-200 dark:border-zinc-700">
              <Button
                variant="secondary"
                @click="loadEnv"
              >
                Reset
              </Button>
              <Button
                variant="primary"
                @click="saveEnv"
                :disabled="savingEnv"
              >
                {{ savingEnv ? 'Saving...' : 'Save .env' }}
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
    </div>

    <!-- Add Package Modal -->
    <Modal v-model="showAddPackageModal" title="Add Package" size="md" variant="left">
    <div class="space-y-6">
      <!-- Search Input -->
      <div>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Search CRAN Packages
        </label>
        <input
          v-model="packageSearch"
          @keydown="handleSearchKeydown"
          type="text"
          placeholder="Type to search CRAN..."
          class="w-full rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2 text-sm text-gray-900 dark:text-gray-100 font-mono focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500"
        />
      </div>

      <!-- Search Results -->
      <div v-if="packageSearchResults.length > 0" class="max-h-64 overflow-y-auto border border-gray-200 dark:border-gray-700 rounded-md">
        <button
          v-for="(pkg, index) in packageSearchResults"
          :key="pkg.name"
          @click="selectPackage(pkg)"
          @mouseenter="packageSearchHighlightIndex = index"
          :class="[
            'w-full px-3 py-2 text-left border-b border-gray-200 dark:border-gray-700 last:border-b-0 transition',
            packageSearchHighlightIndex === index
              ? 'bg-sky-50 dark:bg-sky-900/20'
              : 'hover:bg-gray-50 dark:hover:bg-gray-800'
          ]"
        >
          <div class="flex items-start justify-between gap-2">
            <div class="flex-1 min-w-0">
              <div class="text-sm font-mono font-medium text-gray-900 dark:text-gray-100">
                {{ pkg.name }}
              </div>
              <div v-if="pkg.title" class="text-xs text-gray-600 dark:text-gray-400 mt-0.5 line-clamp-1">
                {{ pkg.title }}
              </div>
              <div v-if="pkg.author" class="text-xs text-gray-500 dark:text-gray-500 mt-0.5">
                {{ pkg.author }}
              </div>
            </div>
            <div class="text-xs text-gray-500 dark:text-gray-500 font-mono shrink-0">
              v{{ pkg.version }}
            </div>
          </div>
        </button>
      </div>

      <!-- Package Name (editable) -->
      <div>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Package Name
        </label>
        <input
          v-model="newPackage.name"
          type="text"
          placeholder="dplyr"
          class="w-full rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2 text-sm text-gray-900 dark:text-gray-100 font-mono focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500"
        />
        <p v-if="newPackage.source === 'github'" class="text-xs text-gray-500 dark:text-gray-400 mt-1">
          GitHub: user/repo (e.g., tidyverse/dplyr)
        </p>
        <p v-if="newPackage.source === 'bioc'" class="text-xs text-gray-500 dark:text-gray-400 mt-1">
          Bioconductor: name only (e.g., DESeq2)
        </p>
      </div>

      <!-- Source -->
      <div>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Source
        </label>
        <div class="relative">
          <select
            v-model="newPackage.source"
            class="w-full appearance-none rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 pl-3 pr-10 py-2 text-sm text-gray-900 dark:text-gray-100 focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500"
          >
            <option value="cran">CRAN</option>
            <option value="github">GitHub</option>
            <option value="bioc">Bioconductor</option>
          </select>
          <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3">
            <svg class="h-4 w-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
            </svg>
          </div>
        </div>
        <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
          <template v-if="newPackage.source === 'cran'">CRAN: name only (e.g., dplyr)</template>
          <template v-else-if="newPackage.source === 'github'">GitHub: user/repo (e.g., tidyverse/dplyr)</template>
          <template v-else-if="newPackage.source === 'bioc'">Bioconductor: name only (e.g., DESeq2)</template>
        </p>
      </div>

      <!-- Auto-attach -->
      <div>
        <Toggle
          v-model="newPackage.auto_attach"
          label="Auto-attach on scaffold()"
        />
      </div>
    </div>

    <template #actions>
      <Button variant="primary" @click="confirmAddPackage" :disabled="!newPackage.name.trim()">
        Add Package
      </Button>
      <Button variant="secondary" @click="showAddPackageModal = false">
        Cancel
      </Button>
    </template>
    </Modal>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from '../composables/useToast'
import PageHeader from '../components/ui/PageHeader.vue'
import Card from '../components/ui/Card.vue'
import Badge from '../components/ui/Badge.vue'
import Alert from '../components/ui/Alert.vue'
import CopyButton from '../components/ui/CopyButton.vue'
import EmptyState from '../components/ui/EmptyState.vue'
import Input from '../components/ui/Input.vue'
import Button from '../components/ui/Button.vue'
import Toggle from '../components/ui/Toggle.vue'
import Tabs from '../components/ui/Tabs.vue'
import TabPanel from '../components/ui/TabPanel.vue'
import Modal from '../components/ui/Modal.vue'
import {
  InformationCircleIcon,
  Cog6ToothIcon,
  DocumentTextIcon,
  CircleStackIcon,
  ServerIcon,
  KeyIcon,
  EyeIcon,
  EyeSlashIcon,
  CubeIcon,
  FolderIcon
} from '@heroicons/vue/24/outline'

const route = useRoute()
const router = useRouter()
const toast = useToast()
const project = ref(null)
const loading = ref(true)
const error = ref(null)
const activeSection = ref('overview')
const dataCatalog = ref(null)
const projectSettings = ref(null)
const editableSettings = ref({})
const settingsLoading = ref(false)
const settingsError = ref(null)
const saving = ref(false)
const connections = ref(null)
const connectionsLoading = ref(false)
const connectionsError = ref(null)
const savingConnections = ref(false)
const connectionsToDelete = ref(new Set())
const packages = ref([])
const packagesLoading = ref(false)
const packagesError = ref(null)
const savingPackages = ref(false)
const showAddPackageModal = ref(false)
const packageSearch = ref('')
const packageSearchResults = ref([])
const packageSearching = ref(false)
const packageSearchHighlightIndex = ref(-1)
const newPackage = ref({ name: '', source: 'cran', auto_attach: true })
const directories = ref({})
const directoriesLoading = ref(false)
const directoriesError = ref(null)
const savingDirectories = ref(false)
const envVariables = ref({})
const envGroups = ref({})
const envRawContent = ref('')
const envLoading = ref(false)
const envError = ref(null)
const savingEnv = ref(false)
const showEnvValues = ref(false)
const visibleEnvFields = ref({})
const envViewMode = ref('grouped') // 'grouped' or 'raw'
const regroupOnSave = ref(false) // If true, regroup .env file by prefix (loses comments)

// Sidebar link classes
const getSidebarLinkClasses = (section) => {
  const isActive = activeSection.value === section
  return [
    'flex items-center gap-2 px-3 py-2 rounded-md text-sm transition',
    isActive
      ? 'bg-sky-50 text-sky-700 font-medium dark:bg-sky-900/20 dark:text-sky-400'
      : 'text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-800'
  ]
}

// Initialize activeSection from URL query param
const initializeSection = () => {
  const sectionFromUrl = route.query.section
  const validSections = ['overview', 'settings', 'notebooks', 'data', 'connections', 'packages', 'directories', 'env']
  if (sectionFromUrl && validSections.includes(sectionFromUrl)) {
    activeSection.value = sectionFromUrl
  } else {
    activeSection.value = 'overview'
  }
}

// Watch for activeSection changes and update URL
watch(activeSection, (newSection) => {
  router.replace({ query: { ...route.query, section: newSection } })

  // Load settings when Settings section is activated
  if (newSection === 'settings' && !projectSettings.value) {
    loadProjectSettings()
  }

  // Load connections when Connections section is activated
  if (newSection === 'connections' && !connections.value) {
    loadConnections()
  }

  // Load packages when Packages section is activated
  if (newSection === 'packages' && packages.value.length === 0) {
    loadPackages()
  }

  // Load directories when Directories section is activated
  if (newSection === 'directories' && Object.keys(directories.value).length === 0) {
    loadDirectories()
  }

  // Load env when .env section is activated
  if (newSection === 'env' && Object.keys(envVariables.value).length === 0) {
    loadEnv()
  }
})

// Watch for URL query param changes (browser back/forward)
watch(() => route.query.section, (newSection) => {
  const validSections = ['overview', 'settings', 'notebooks', 'data', 'connections', 'packages', 'directories', 'env']
  if (newSection && newSection !== activeSection.value && validSections.includes(newSection)) {
    activeSection.value = newSection
  }
})

// Debounce package search
let searchTimeout = null
watch(packageSearch, () => {
  if (searchTimeout) clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => {
    searchPackages()
  }, 300)
})

// Flatten nested data catalog into dot notation
const flattenDataCatalog = (obj, prefix = '') => {
  const result = {}

  for (const key in obj) {
    const value = obj[key]
    const newKey = prefix ? `${prefix}.${key}` : key

    if (value && typeof value === 'object' && value.path) {
      result[newKey] = value
    } else if (value && typeof value === 'object') {
      Object.assign(result, flattenDataCatalog(value, newKey))
    }
  }

  return result
}

const flattenedDataCatalog = computed(() => {
  if (!dataCatalog.value) return {}
  return flattenDataCatalog(dataCatalog.value)
})

const loadProject = async () => {
  loading.value = true
  error.value = null

  try {
    const response = await fetch(`/api/project/${route.params.id}`)
    const data = await response.json()

    if (data.error) {
      error.value = data.error
    } else {
      project.value = data
    }
  } catch (err) {
    error.value = 'Failed to load project: ' + err.message
  } finally {
    loading.value = false
  }
}

const loadDataCatalog = async () => {
  try {
    const response = await fetch(`/api/project/${route.params.id}/data`)
    const data = await response.json()

    if (!data.error) {
      dataCatalog.value = data.data || data
    }
  } catch (err) {
    console.error('Failed to load data catalog:', err)
  }
}

const loadProjectSettings = async () => {
  settingsLoading.value = true
  settingsError.value = null

  try {
    const response = await fetch(`/api/project/${route.params.id}/settings`)
    const data = await response.json()

    if (data.error) {
      settingsError.value = data.error
    } else {
      projectSettings.value = data.settings
      editableSettings.value = JSON.parse(JSON.stringify(data.settings))
    }
  } catch (err) {
    settingsError.value = 'Failed to load settings: ' + err.message
  } finally {
    settingsLoading.value = false
  }
}

const saveSettings = async () => {
  saving.value = true

  try {
    const response = await fetch(`/api/project/${route.params.id}/settings`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(editableSettings.value)
    })

    const result = await response.json()

    if (result.success) {
      toast.success('Settings Saved', 'Project settings have been updated')
      projectSettings.value = JSON.parse(JSON.stringify(editableSettings.value))
      // Reload settings to verify save
      await loadProjectSettings()
    } else {
      toast.error('Save Failed', result.error || 'Failed to save settings')
    }
  } catch (err) {
    toast.error('Save Failed', err.message)
  } finally {
    saving.value = false
  }
}

const scrollToConnection = (name) => {
  const element = document.getElementById(`connection-${name}`)
  if (element) {
    element.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }
}

const scrollToSection = (sectionId) => {
  const element = document.getElementById(sectionId)
  if (element) {
    element.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }
}

const loadConnections = async () => {
  connectionsLoading.value = true
  connectionsError.value = null

  try {
    const response = await fetch(`/api/project/${route.params.id}/connections`)
    const data = await response.json()

    if (data.error) {
      connectionsError.value = data.error
    } else {
      connections.value = data
    }
  } catch (err) {
    connectionsError.value = 'Failed to load connections: ' + err.message
  } finally {
    connectionsLoading.value = false
  }
}

const toggleConnectionDelete = (name) => {
  if (connectionsToDelete.value.has(name)) {
    connectionsToDelete.value.delete(name)
  } else {
    connectionsToDelete.value.add(name)
  }
}

const saveConnections = async () => {
  savingConnections.value = true

  try {
    // Filter out connections marked for deletion
    const connectionsToSave = { ...connections.value }
    if (connectionsToSave.connections) {
      connectionsToSave.connections = Object.fromEntries(
        Object.entries(connectionsToSave.connections)
          .filter(([name]) => !connectionsToDelete.value.has(name))
      )
    }

    const response = await fetch(`/api/project/${route.params.id}/connections`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(connectionsToSave)
    })

    const result = await response.json()

    if (result.success) {
      connectionsToDelete.value.clear() // Clear staged deletions
      toast.success('Connections Saved', 'Connection settings have been updated')
      await loadConnections()
    } else {
      toast.error('Save Failed', result.error || 'Failed to save connections')
    }
  } catch (err) {
    toast.error('Save Failed', err.message)
  } finally {
    savingConnections.value = false
  }
}

const loadPackages = async () => {
  packagesLoading.value = true
  packagesError.value = null

  try {
    const response = await fetch(`/api/project/${route.params.id}/packages`)
    const data = await response.json()

    if (data.error) {
      packagesError.value = data.error
    } else {
      // Normalize packages to ensure defaults
      packages.value = (data.packages || []).map(pkg => ({
        name: pkg.name || '',
        source: pkg.source || 'cran',
        auto_attach: pkg.auto_attach !== undefined ? pkg.auto_attach : true,
        ref: pkg.ref || ''
      }))
    }
  } catch (err) {
    packagesError.value = 'Failed to load packages: ' + err.message
  } finally {
    packagesLoading.value = false
  }
}

const savePackages = async () => {
  savingPackages.value = true

  try {
    const response = await fetch(`/api/project/${route.params.id}/packages`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ packages: packages.value })
    })

    const result = await response.json()

    if (result.success) {
      toast.success('Packages Saved', 'Package configuration has been updated')
      await loadPackages()
    } else {
      toast.error('Save Failed', result.error || 'Failed to save packages')
    }
  } catch (err) {
    toast.error('Save Failed', err.message)
  } finally {
    savingPackages.value = false
  }
}

const addPackage = () => {
  // Reset modal state
  newPackage.value = { name: '', source: 'cran', auto_attach: true }
  packageSearch.value = ''
  packageSearchResults.value = []
  packageSearchHighlightIndex.value = -1
  showAddPackageModal.value = true
}

const searchPackages = async () => {
  if (packageSearch.value.length < 2) {
    packageSearchResults.value = []
    packageSearchHighlightIndex.value = -1
    return
  }

  packageSearching.value = true
  try {
    const response = await fetch(`/api/packages/search?q=${encodeURIComponent(packageSearch.value)}`)
    const data = await response.json()
    console.log('Package search results:', data)
    packageSearchResults.value = data.packages || []
    packageSearchHighlightIndex.value = packageSearchResults.value.length > 0 ? 0 : -1
  } catch (err) {
    console.error('Failed to search packages:', err)
    packageSearchResults.value = []
    packageSearchHighlightIndex.value = -1
  } finally {
    packageSearching.value = false
  }
}

const handleSearchKeydown = (e) => {
  if (packageSearchResults.value.length === 0) return

  if (e.key === 'ArrowDown') {
    e.preventDefault()
    packageSearchHighlightIndex.value = Math.min(
      packageSearchHighlightIndex.value + 1,
      packageSearchResults.value.length - 1
    )
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    packageSearchHighlightIndex.value = Math.max(
      packageSearchHighlightIndex.value - 1,
      0
    )
  } else if (e.key === 'Enter' && packageSearchHighlightIndex.value >= 0) {
    e.preventDefault()
    selectPackage(packageSearchResults.value[packageSearchHighlightIndex.value])
  } else if (e.key === 'Escape') {
    packageSearchResults.value = []
    packageSearchHighlightIndex.value = -1
  }
}

const selectPackage = (pkg) => {
  newPackage.value.name = pkg.name
  newPackage.value.source = pkg.source
  packageSearch.value = ''
  packageSearchResults.value = []
  packageSearchHighlightIndex.value = -1
}

const confirmAddPackage = () => {
  if (!newPackage.value.name.trim()) {
    return
  }

  packages.value.push({
    name: newPackage.value.name.trim(),
    source: newPackage.value.source,
    auto_attach: newPackage.value.auto_attach
  })

  showAddPackageModal.value = false
  toast.success('Package Added', `${newPackage.value.name} added to package list`)
}

const removePackage = (index) => {
  packages.value.splice(index, 1)
}

const loadDirectories = async () => {
  directoriesLoading.value = true
  directoriesError.value = null

  try {
    const response = await fetch(`/api/project/${route.params.id}/directories`)
    const data = await response.json()

    if (data.error) {
      directoriesError.value = data.error
    } else {
      directories.value = data.directories || {}
    }
  } catch (err) {
    directoriesError.value = 'Failed to load directories: ' + err.message
  } finally {
    directoriesLoading.value = false
  }
}

const saveDirectories = async () => {
  savingDirectories.value = true

  try {
    const response = await fetch(`/api/project/${route.params.id}/directories`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ directories: directories.value })
    })

    const result = await response.json()

    if (result.success) {
      toast.success('Directories Saved', 'Directory configuration has been updated')
      await loadDirectories()
    } else {
      toast.error('Save Failed', result.error || 'Failed to save directories')
    }
  } catch (err) {
    toast.error('Save Failed', err.message)
  } finally {
    savingDirectories.value = false
  }
}

const loadEnv = async () => {
  envLoading.value = true
  envError.value = null

  try {
    const response = await fetch(`/api/project/${route.params.id}/env`)
    const data = await response.json()

    if (data.error) {
      envError.value = data.error
    } else {
      envVariables.value = data.variables || {}
      envGroups.value = data.groups || {}
      envRawContent.value = data.raw_content || ''
    }
  } catch (err) {
    envError.value = 'Failed to load .env: ' + err.message
  } finally {
    envLoading.value = false
  }
}

const saveEnv = async () => {
  savingEnv.value = true

  try {
    // Send either raw content or variables based on current view mode
    const payload = envViewMode.value === 'raw'
      ? { raw_content: envRawContent.value }
      : {
          variables: envVariables.value,
          regroup: regroupOnSave.value  // Only regroup if user explicitly opts in
        }

    const response = await fetch(`/api/project/${route.params.id}/env`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })

    const result = await response.json()

    if (result.success) {
      toast.success('.env Saved', 'Environment variables have been updated')
      await loadEnv()
    } else {
      toast.error('Save Failed', result.error || 'Failed to save .env')
    }
  } catch (err) {
    toast.error('Save Failed', err.message)
  } finally {
    savingEnv.value = false
  }
}

const addEnvVariable = () => {
  const newKey = `NEW_VARIABLE_${Object.keys(envVariables.value).length + 1}`
  envVariables.value[newKey] = ''
}

const removeEnvVariable = (key) => {
  delete envVariables.value[key]
}

const isPasswordField = (key) => {
  const passwordKeys = ['PASSWORD', 'SECRET', 'KEY', 'TOKEN', 'CREDENTIAL']
  return passwordKeys.some(pw => key.toUpperCase().includes(pw))
}

const toggleFieldVisibility = (key) => {
  visibleEnvFields.value[key] = !visibleEnvFields.value[key]
}

const isFieldVisible = (key) => {
  return showEnvValues.value || visibleEnvFields.value[key] || !isPasswordField(key)
}

// Keyboard shortcuts
const handleKeydown = (e) => {
  // Cmd/Ctrl + S to save
  if ((e.metaKey || e.ctrlKey) && e.key === 's') {
    e.preventDefault()
    if (activeSection.value === 'settings') {
      saveSettings()
    } else if (activeSection.value === 'connections') {
      saveConnections()
    } else if (activeSection.value === 'packages') {
      savePackages()
    } else if (activeSection.value === 'directories') {
      saveDirectories()
    } else if (activeSection.value === 'env') {
      saveEnv()
    }
  }
}

onMounted(() => {
  initializeSection()
  loadProject()
  loadDataCatalog()
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>
