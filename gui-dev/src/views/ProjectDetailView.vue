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
    <nav class="w-64 shrink-0 border-r border-gray-200 p-6 dark:border-gray-800 flex flex-col">
      <div class="mb-4">
        <h2 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">{{ project.name }}</h2>
        <div class="flex items-center gap-2">
          <span class="text-xs text-gray-500 dark:text-gray-400 font-mono truncate">{{ project.path }}</span>
          <CopyButton :value="project.path" variant="ghost" successMessage="Path copied" class="shrink-0" />
        </div>
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
        <NavigationSectionHeading>Settings</NavigationSectionHeading>

        <a
          href="#basics"
          @click.prevent="activeSection = 'basics'"
          :class="getSidebarLinkClasses('basics')"
        >
          <Cog6ToothIcon class="h-4 w-4" />
          Basics
        </a>

        <a
          href="#settings"
          @click.prevent="activeSection = 'settings'"
          :class="getSidebarLinkClasses('settings')"
        >
          <FolderIcon class="h-4 w-4" />
          Project Structure
        </a>

        <a
          href="#packages"
          @click.prevent="activeSection = 'packages'"
          :class="getSidebarLinkClasses('packages')"
        >
          <CubeIcon class="h-4 w-4" />
          Packages
        </a>

        <a
          href="#ai"
          @click.prevent="activeSection = 'ai'"
          :class="getSidebarLinkClasses('ai')"
        >
          <SparklesIcon class="h-4 w-4" />
          AI Assistants
        </a>

        <a
          href="#git"
          @click.prevent="activeSection = 'git'"
          :class="getSidebarLinkClasses('git')"
        >
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
          </svg>
          Git & Hooks
        </a>

        <a
          href="#connections"
          @click.prevent="activeSection = 'connections'"
          :class="getSidebarLinkClasses('connections')"
        >
          <ServerStackIcon class="h-4 w-4" />
          Connections
        </a>
        <a
          href="#env"
          @click.prevent="activeSection = 'env'"
          :class="getSidebarLinkClasses('env')"
        >
          <KeyIcon class="h-4 w-4" />
          .env Defaults
        </a>
        <a
          href="#scaffold"
          @click.prevent="activeSection = 'scaffold'"
          :class="getSidebarLinkClasses('scaffold')"
        >
          <AdjustmentsVerticalIcon class="h-4 w-4" />
          Scaffold Behavior
        </a>

        <!-- PROJECT Heading -->
        <NavigationSectionHeading>Project</NavigationSectionHeading>

        <a
          href="#data"
          @click.prevent="activeSection = 'data'"
          :class="getSidebarLinkClasses('data')"
        >
          <CircleStackIcon class="h-4 w-4" />
          Data
        </a>

        <div v-if="activeSection === 'data' && dataSectionSublinks.length" class="ml-6 mt-1 space-y-0.5">
          <a
            v-for="link in dataSectionSublinks"
            :key="link.anchorId"
            :href="`#${link.anchorId}`"
            @click.prevent="handleDataSublinkClick(link)"
            class="flex items-center justify-between gap-2 rounded-md px-3 py-1 text-xs text-gray-600 transition hover:bg-gray-50 dark:text-gray-400 dark:hover:bg-gray-800"
          >
            <span class="truncate">{{ link.label }}</span>
            <span v-if="link.count" class="shrink-0 rounded-full bg-gray-100 px-2 py-0.5 text-[10px] font-medium text-gray-500 dark:bg-gray-800 dark:text-gray-300">
              {{ link.count }}
            </span>
          </a>
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

      <!-- Save Button (right after navigation) -->
      <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
        <Button
          variant="primary"
          @click="saveCurrentSection"
          :disabled="saving || savingPackages || savingEnv || savingAI || savingGit || savingConnections"
          class="w-full"
        >
          {{
            (saving || savingPackages || savingEnv || savingAI || savingGit || savingConnections)
              ? 'Saving...'
              : 'Save'
          }}
        </Button>
      </div>

      <!-- Delete Project Link (pushed to absolute bottom) -->
      <div class="mt-auto pt-4 border-t border-gray-200 dark:border-gray-700">
        <div class="text-center py-3">
          <button
            @click="showDeleteModal = true"
            class="text-xs text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-400 transition"
          >
            Delete Project
          </button>
        </div>
      </div>
    </nav>

    <!-- Main Content -->
    <div class="flex-1 p-10">
      <!-- Overview Section -->
      <div v-show="activeSection === 'overview'" id="overview">
        <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Overview</h2>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
          Quick overview of your project settings.
        </p>

        <div class="space-y-3">
          <OverviewCard title="Basics" @click="activeSection = 'basics'">
            <div class="text-gray-900 dark:text-white">
              {{ basicsOverview.name }}
              <template v-if="basicsOverview.author">
                <span class="text-gray-400 dark:text-gray-500 mx-1">·</span>
                <span class="text-gray-600 dark:text-gray-400">{{ basicsOverview.author }}</span>
              </template>
            </div>
            <p v-if="basicsOverview.path" class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              {{ basicsOverview.path }}
            </p>
          </OverviewCard>

          <OverviewCard title="Project Structure" @click="activeSection = 'settings'">
            <span class="text-gray-600 dark:text-gray-400">
              {{ projectStructureLabel }}
            </span>
          </OverviewCard>

          <OverviewCard title="Notebooks & Scripts" @click="activeSection = 'scaffold'">
            <span class="text-gray-600 dark:text-gray-400">
              {{ notebookFormatLabel }}
            </span>
          </OverviewCard>

          <OverviewCard title="AI Assistants" @click="activeSection = 'ai'">
            <span :class="aiSettings.enabled ? 'text-green-600 dark:text-green-400' : 'text-gray-600 dark:text-gray-400'">
              {{ aiOverviewText }}
            </span>
          </OverviewCard>

          <OverviewCard title="Git & Hooks" @click="activeSection = 'git'">
            <span class="text-gray-600 dark:text-gray-400">{{ gitOverviewText }}</span>
          </OverviewCard>

          <OverviewCard title="Packages" @click="activeSection = 'packages'">
            <span class="text-gray-600 dark:text-gray-400">{{ packagesOverviewText }}</span>
          </OverviewCard>

          <OverviewCard title=".env" @click="activeSection = 'env'">
            <span class="text-gray-600 dark:text-gray-400">{{ envOverviewText }}</span>
          </OverviewCard>
        </div>
      </div>

      <!-- Basics Section -->
      <div v-show="activeSection === 'basics'" id="basics">
        <div v-if="settingsLoading">
          <div class="text-center py-12 text-zinc-500 dark:text-zinc-400">
            Loading settings...
          </div>
        </div>

        <div v-else-if="settingsError">
          <Alert type="error" title="Error Loading Settings" :description="settingsError" />
        </div>

        <div v-else>
          <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Basics</h2>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
            Essential project settings.
          </p>

          <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
            <div v-if="editableSettings.scaffold" class="space-y-5">
              <Input
                v-model="project.name"
                label="Project Name"
                hint="Changing this will rename the project directory"
              />

              <div>
                <label class="block text-sm font-semibold text-gray-900 dark:text-white mb-2">
                  Filesystem Location
                </label>
                <div class="flex items-center gap-2">
                  <code class="flex-1 px-3 py-2 text-sm font-mono text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-700 rounded-md">
                    {{ project.path }}
                  </code>
                  <CopyButton :value="project.path" successMessage="Path copied" />
                </div>
              </div>

              <div>
                <label class="block text-sm font-semibold text-gray-900 dark:text-white mb-3">
                  Supported Editors
                </label>
                <Checkbox
                  v-model="editableSettings.scaffold.positron"
                  id="support-positron-edit"
                  description="Enable Positron-specific workspace and settings files"
                >
                  Positron
                </Checkbox>
                <p class="text-sm text-gray-500 dark:text-gray-400 mt-3">
                  RStudio supported by default
                </p>
              </div>

              <Select
                v-model="editableSettings.scaffold.notebook_format"
                label="Default Notebook Format"
                hint="Format used when creating new notebooks"
              >
                <option value="quarto">Quarto (.qmd)</option>
                <option value="rmarkdown">R Markdown (.Rmd)</option>
              </Select>

              <!-- Author Information Subheading -->
              <div class="pt-6 border-t border-gray-200 dark:border-gray-700">
                <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">
                  Author Information
                </h3>
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-5">
                  Configure author details for this project.
                </p>
                <div v-if="editableSettings.author" class="space-y-5">
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
                  />
                </div>
              </div>
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
          <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Project Structure</h2>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
            This project uses the <strong>{{ projectTypeLabel }}</strong> structure. Existing directories cannot be renamed or removed, but you can add custom directories below.
          </p>

          <!-- Workspace Directories -->
          <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 mb-6">
            <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">Workspaces</h3>
            <p class="text-xs text-gray-600 dark:text-gray-400 mb-4">
              Functions, notebooks, and scripts scaffolded into every project.
            </p>

            <!-- Existing workspace directories -->
            <div class="space-y-4 mb-6">
              <div v-for="(value, key) in workspaceDirectories" :key="key" class="flex items-start gap-4">
                <div class="flex items-center gap-2 w-32 shrink-0">
                  <Toggle :model-value="true" disabled class="pointer-events-none opacity-50" />
                  <label class="text-sm text-gray-700 dark:text-gray-300 capitalize">
                    {{ formatDirectoryLabel(key) }}
                  </label>
                </div>
                <div class="flex-1">
                  <Input :model-value="value" disabled prefix="/" monospace class="opacity-75" />
                </div>
              </div>
            </div>

            <!-- Add custom workspace directories -->
            <div class="border-t border-gray-200 dark:border-gray-700 pt-4">
              <Repeater
                v-model="customWorkspaceDirectories"
                add-label="Add Workspace Directory"
                :default-item="() => ({ key: '', label: '', path: '', category: 'workspace', _id: Date.now() })"
              >
                <template #default="{ item, index, update }">
                  <div class="space-y-3">
                    <Input
                      :model-value="item.key"
                      @update:model-value="update('key', $event)"
                      label="Key"
                      placeholder="e.g., helpers"
                      size="sm"
                      monospace
                    />
                    <Input
                      :model-value="item.label"
                      @update:model-value="update('label', $event)"
                      label="Label"
                      placeholder="e.g., Helper Scripts"
                      size="sm"
                    />
                    <Input
                      :model-value="item.path"
                      @update:model-value="update('path', $event)"
                      label="Path"
                      placeholder="e.g., helpers"
                      prefix="/"
                      monospace
                      size="sm"
                    />
                  </div>
                </template>
              </Repeater>
            </div>
          </div>

          <!-- Input Directories -->
          <div v-if="inputDirectories && Object.keys(inputDirectories).length > 0" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 mb-6">
            <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">Inputs</h3>
            <p class="text-xs text-gray-600 dark:text-gray-400 mb-4">
              Define the read-only locations where raw and prepared data live.
            </p>

            <!-- Existing input directories -->
            <div class="space-y-4 mb-6">
              <div v-for="(value, key) in inputDirectories" :key="key" class="flex items-start gap-4">
                <div class="flex items-center gap-2 w-32 shrink-0">
                  <Toggle :model-value="true" disabled class="pointer-events-none opacity-50" />
                  <label class="text-sm text-gray-700 dark:text-gray-300 capitalize">
                    {{ formatDirectoryLabel(key) }}
                  </label>
                </div>
                <div class="flex-1">
                  <Input :model-value="value" disabled prefix="/" monospace class="opacity-75" />
                </div>
              </div>
            </div>

            <!-- Add custom input directories -->
            <div class="border-t border-gray-200 dark:border-gray-700 pt-4">
              <Repeater
                v-model="customInputDirectories"
                add-label="Add Input Directory"
                :default-item="() => ({ key: '', label: '', path: '', category: 'input', _id: Date.now() })"
              >
                <template #default="{ item, index, update }">
                  <div class="space-y-3">
                    <Input
                      :model-value="item.key"
                      @update:model-value="update('key', $event)"
                      label="Key"
                      placeholder="e.g., inputs_archive"
                      size="sm"
                      monospace
                    />
                    <Input
                      :model-value="item.label"
                      @update:model-value="update('label', $event)"
                      label="Label"
                      placeholder="e.g., Archived Inputs"
                      size="sm"
                    />
                    <Input
                      :model-value="item.path"
                      @update:model-value="update('path', $event)"
                      label="Path"
                      placeholder="e.g., inputs/archive"
                      prefix="/"
                      monospace
                      size="sm"
                    />
                  </div>
                </template>
              </Repeater>
            </div>
          </div>

          <!-- Output Directories -->
          <div v-if="outputDirectories && Object.keys(outputDirectories).length > 0" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 mb-6">
            <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">Outputs</h3>
            <p class="text-xs text-gray-600 dark:text-gray-400 mb-4">
              Results, figures, tables, and rendered outputs.
            </p>

            <!-- Existing output directories -->
            <div class="space-y-4 mb-6">
              <div v-for="(value, key) in outputDirectories" :key="key" class="flex items-start gap-4">
                <div class="flex items-center gap-2 w-32 shrink-0">
                  <Toggle :model-value="true" disabled class="pointer-events-none opacity-50" />
                  <label class="text-sm text-gray-700 dark:text-gray-300 capitalize">
                    {{ formatDirectoryLabel(key) }}
                  </label>
                </div>
                <div class="flex-1">
                  <Input :model-value="value" disabled prefix="/" monospace class="opacity-75" />
                </div>
              </div>
            </div>

            <!-- Add custom output directories -->
            <div class="border-t border-gray-200 dark:border-gray-700 pt-4">
              <Repeater
                v-model="customOutputDirectories"
                add-label="Add Output Directory"
                :default-item="() => ({ key: '', label: '', path: '', category: 'output', _id: Date.now() })"
              >
                <template #default="{ item, index, update }">
                  <div class="space-y-3">
                    <Input
                      :model-value="item.key"
                      @update:model-value="update('key', $event)"
                      label="Key"
                      placeholder="e.g., outputs_animations"
                      size="sm"
                      monospace
                    />
                    <Input
                      :model-value="item.label"
                      @update:model-value="update('label', $event)"
                      label="Label"
                      placeholder="e.g., Animations"
                      size="sm"
                    />
                    <Input
                      :model-value="item.path"
                      @update:model-value="update('path', $event)"
                      label="Path"
                      placeholder="e.g., outputs/animations"
                      prefix="/"
                      monospace
                      size="sm"
                    />
                  </div>
                </template>
              </Repeater>
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
        <div class="mb-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 class="text-2xl font-semibold text-gray-900 dark:text-white">Data Catalog</h2>
            <p class="text-sm text-gray-600 dark:text-gray-400">
              Browse your project's data sources with copy commands.
            </p>
          </div>
          <Button
            variant="primary"
            size="sm"
            class="inline-flex items-center gap-2"
            @click="openDataCreator"
          >
            <PlusIcon class="h-4 w-4" />
            Add Data Source
          </Button>
        </div>

        <div class="mb-6">
          <Input
            v-model="dataSearch"
            label="Search data sources"
            placeholder="Filter by name, prefix, or file path"
          />
        </div>

        <div v-if="displayDataTree.length > 0" class="space-y-4">
          <DataCatalogTree
            v-for="node in displayDataTree"
            :key="node.fullKey"
            :node="node"
            :expanded-keys="expandedDataKeys"
            :auto-expanded-keys="autoExpandedDataKeys"
            :toggle-group="toggleDataGroup"
            :search-term="dataSearch"
            :hierarchical="useHierarchicalDataView"
            :pending-deletes="dataEntriesToDelete"
            @edit="openDataEditor"
            @delete="toggleDataDelete"
          />
        </div>

        <div v-if="hasPendingDataDeletes" class="mt-4 rounded-lg border border-red-200 bg-red-50 p-4 dark:border-red-500/40 dark:bg-red-900/20">
          <div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p class="text-sm font-medium text-red-700 dark:text-red-200">
                {{ pendingDeleteCount }} data source{{ pendingDeleteCount === 1 ? '' : 's' }} marked for deletion.
              </p>
              <p class="text-xs text-red-600 dark:text-red-200/80">
                Changes will be applied when you save.
              </p>
            </div>
            <div class="flex gap-2">
              <Button
                variant="secondary"
                size="sm"
                class="shadow-none"
                :disabled="savingDataDeletes"
                @click="clearPendingDataDeletes"
              >
                Cancel
              </Button>
              <Button
                size="sm"
                class="bg-red-600 text-white hover:bg-red-500 focus-visible:outline-red-600 dark:bg-red-500 dark:hover:bg-red-400"
                :disabled="savingDataDeletes"
                @click="savePendingDataDeletes"
              >
                {{ savingDataDeletes ? 'Saving…' : 'Save Changes' }}
              </Button>
            </div>
          </div>
          <ul class="mt-3 list-disc space-y-1 pl-5 text-xs font-mono text-red-700 dark:text-red-200/90">
            <li v-for="key in pendingDeleteList" :key="key">{{ key }}</li>
          </ul>
        </div>

        <div v-else-if="isFilteringData" class="rounded-xl border border-dashed border-zinc-300 bg-white/70 p-10 text-center dark:border-zinc-700 dark:bg-zinc-900/40">
          <p class="text-sm font-medium text-zinc-700 dark:text-zinc-200">
            No data sources match "{{ dataSearch }}".
          </p>
          <p class="mt-2 text-xs text-zinc-500 dark:text-zinc-400">
            Try adjusting your search terms or clearing the filter.
          </p>
        </div>

        <template v-else>
          <EmptyState
            v-if="!hasPendingDataDeletes && (!dataCatalog || Object.keys(dataCatalog || {}).length === 0)"
            title="No Data Sources"
            description="This project doesn't have any data sources defined in its settings"
            icon="database"
          />
        </template>
      </div>

      <DataCatalogEditModal
        :mode="isCreatingDataEntry ? 'create' : 'edit'"
        v-model="isEditingDataEntry"
        :entry="editingDataEntry"
        :saving="savingDataEntry"
        :error="dataEditError"
        @save="handleDataEntrySave"
        @update:modelValue="handleDataModalVisibility"
      />

      <!-- Connections Section -->
      <div v-show="activeSection === 'connections'" id="connections">
        <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Connections</h2>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
          Database and storage connections for this project.
        </p>

        <ConnectionsPanel
          v-model:database-connections="databaseConnections"
          v-model:s3-connections="s3Connections"
          v-model:default-database="defaultDatabase"
          v-model:default-storage-bucket="defaultStorageBucket"
        />

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
          <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Packages & Dependencies</h2>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
            Configure package management and default packages for this project.
          </p>

          <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
            <div class="space-y-5">
              <Toggle
                v-model="editablePackages.use_renv"
                label="Enable renv"
                description="Use renv for package version management and reproducibility"
              />

              <div class="pt-4 border-t border-gray-200 dark:border-gray-700">
                <p class="text-xs text-gray-600 dark:text-gray-400 mb-4">Use this list to preseed notebooks with your preferred helpers.</p>

                <div class="space-y-3" v-if="editablePackages.default_packages && editablePackages.default_packages.length">
                  <div
                    v-for="(pkg, idx) in editablePackages.default_packages"
                    :key="`pkg-${idx}`"
                    class="rounded-md border border-gray-200 p-4 dark:border-gray-700"
                  >
                    <div class="flex flex-col gap-3">
                      <div class="grid gap-3 grid-cols-[1fr_160px]">
                        <PackageAutocomplete
                          v-if="pkg.source === 'cran' || pkg.source === 'bioconductor'"
                          v-model="pkg.name"
                          :source="pkg.source"
                          label="Package"
                          :placeholder="pkg.source === 'cran' ? 'Search CRAN...' : 'Search Bioconductor...'"
                          @select="(selectedPkg) => pkg.name = selectedPkg.name"
                        />
                        <Input
                          v-else
                          v-model="pkg.name"
                          label="Package"
                          placeholder="user/repo"
                        />
                        <Select v-model="pkg.source" label="Source">
                          <option value="cran">CRAN</option>
                          <option value="github">GitHub</option>
                          <option value="bioconductor">Bioconductor</option>
                        </Select>
                      </div>
                      <div class="flex items-center justify-between">
                        <Toggle v-model="pkg.auto_attach" label="Auto-Attach" description="Call library() when scaffold() runs." />
                        <Button size="sm" variant="secondary" @click="removePackage(idx)">Remove</Button>
                      </div>
                    </div>
                  </div>
                </div>

                <p v-else class="text-xs text-gray-500 dark:text-gray-400 mb-4">No packages configured. Add packages to include tidyverse helpers or internal utilities automatically.</p>

                <div class="mt-4">
                  <Button size="sm" variant="secondary" @click="addPackage">Add Package</Button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- AI Assistants Section -->
      <div v-show="activeSection === 'ai'" id="ai">
        <div v-if="aiLoading">
          <div class="text-center py-12 text-sm text-gray-500 dark:text-gray-400">Loading AI settings...</div>
        </div>

        <div v-else-if="aiError">
          <Alert type="error" title="Error Loading AI Settings" :description="aiError" />
        </div>

        <div v-else>
          <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">AI Assistants</h2>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
            Framework maintains context files for selected assistants and keeps them in sync before commits.
          </p>

          <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 space-y-6">
            <Toggle
              v-model="aiSettings.enabled"
              label="Enable AI Support"
              description="Generate and sync assistant-specific context files."
            />

            <div
              v-if="aiSettings.enabled"
              class="space-y-6 pt-6 border-t border-gray-200 dark:border-gray-700"
            >
              <div>
                <h4 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Canonical context file</h4>
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                  This file is the source of truth; other instructions files are synced to it when AI hooks run.
                </p>
                <Select
                  v-model="aiSettings.canonical_file"
                  label="Canonical Context File"
                  @change="handleCanonicalFileChange($event?.target?.value)"
                >
                  <option value="AGENTS.md">AGENTS.md (multi-agent orchestrator)</option>
                  <option value="CLAUDE.md">CLAUDE.md</option>
                  <option value=".github/copilot-instructions.md">.github/copilot-instructions.md</option>
                </Select>
              </div>

              <div>
                <h4 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Assistants</h4>
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                  Choose which assistants receive context updates.
                </p>
                <div class="space-y-2">
                  <Checkbox
                    v-for="assistant in availableAssistants"
                    :key="assistant.id"
                    :id="`project-ai-${assistant.id}`"
                    :model-value="aiSettings.assistants.includes(assistant.id)"
                    @update:model-value="(value) => toggleAiAssistant(assistant.id, value)"
                    :description="assistant.description"
                  >
                    {{ assistant.label }}
                  </Checkbox>
                </div>
              </div>

              <div>
                <h4 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Canonical instructions</h4>
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                  Edit the canonical file directly. Framework mirrors this content to other assistant files.
                </p>
                <Alert
                  v-if="!aiContentMeta.exists"
                  type="info"
                  title="New canonical file"
                  :description="`Saving copies the current instructions into ${aiSettings.canonical_file || 'CLAUDE.md'}. The original file stays on disk; if AI sync hooks are enabled they mirror everything from the new canonical file.`"
                  class="mb-4"
                />
                <CodeEditor
                  v-model="aiSettings.canonical_content"
                  language="markdown"
                  min-height="400px"
                  :disabled="canonicalContentLoading"
                />
                <p v-if="canonicalContentLoading" class="text-xs text-gray-500 dark:text-gray-400 mt-2">
                  Loading {{ aiSettings.canonical_file }}…
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Git & Hooks Section -->
      <div v-show="activeSection === 'git'" id="git">
        <div v-if="gitLoading">
          <div class="text-center py-12 text-sm text-gray-500 dark:text-gray-400">Loading git settings...</div>
        </div>

        <div v-else-if="gitError">
          <Alert type="error" title="Error Loading Git Settings" :description="gitError" />
        </div>

        <div v-else>
          <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Git & Hooks</h2>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
            Configure repository initialization, commit identity, git hooks, and security scanning.
          </p>

          <GitHooksPanel v-model="gitPanelModel">
            <template #note>
              Project-specific .gitignore templates can be customized in Project Defaults.
            </template>
          </GitHooksPanel>
        </div>
      </div>

      <!-- Scaffold Behavior Section -->
      <div v-show="activeSection === 'scaffold'" id="scaffold">
        <div v-if="settingsLoading">
          <div class="text-center py-12 text-zinc-500 dark:text-zinc-400">
            Loading settings...
          </div>
        </div>

        <div v-else-if="settingsError">
          <Alert type="error" title="Error Loading Settings" :description="settingsError" />
        </div>

        <div v-else>
          <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Scaffold Behavior</h2>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
            Automatic actions when <code class="px-1.5 py-0.5 bg-gray-200 dark:bg-gray-700 rounded text-xs">scaffold()</code> runs to initialize your project environment.
          </p>

          <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
            <ScaffoldBehaviorPanel
              v-if="editableSettings.scaffold"
              v-model="editableSettings.scaffold"
              flush
            />
          </div>
        </div>
      </div>

      <!-- .env Section -->
      <div v-show="activeSection === 'env'" id="env">
        <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Environment Variables</h2>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
          Manage environment variables for this project (.env file).
        </p>

        <EnvEditor
          :loading="envLoading"
          :error="envError"
          :groups="envGroups"
          v-model:variables="envVariables"
          v-model:raw-content="envRawContent"
          v-model:view-mode="envViewMode"
          v-model:regroup-on-save="regroupOnSave"
          @save="saveEnv"
        />
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

    <!-- Delete Project Modal -->
    <Modal
      v-model="showDeleteModal"
      title="Delete Project"
      size="md"
    >
      <div class="space-y-4 text-left">
        <p class="text-sm text-gray-600 dark:text-gray-400">
          Choose how you want to remove this project:
        </p>

        <!-- Option 1: Remove from Framework -->
        <label :class="[
          'block cursor-pointer rounded-lg border-2 p-4 transition',
          deleteOption === 'untrack'
            ? 'border-sky-500 bg-sky-50 dark:border-sky-600 dark:bg-sky-950/30'
            : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
        ]">
          <div class="flex items-start gap-3">
            <input
              type="radio"
              id="delete-untrack"
              value="untrack"
              v-model="deleteOption"
              class="mt-1"
            />
            <div class="flex-1">
              <div class="font-medium text-gray-900 dark:text-white">
                Remove from Framework
              </div>
              <div class="text-sm text-gray-600 dark:text-gray-400 mt-1">
                Stop tracking this project in Framework. Files remain on disk.
              </div>
            </div>
          </div>
        </label>

        <!-- Option 2: Delete Entire Project -->
        <label :class="[
          'block cursor-pointer rounded-lg border-2 p-4 transition',
          deleteOption === 'delete'
            ? 'border-red-500 bg-red-50 dark:border-red-700 dark:bg-red-950/30'
            : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
        ]">
          <div class="flex items-start gap-3">
            <input
              type="radio"
              id="delete-files"
              value="delete"
              v-model="deleteOption"
              class="mt-1"
            />
            <div class="flex-1">
              <div class="font-medium text-red-700 dark:text-red-400">
                Delete Entire Project
              </div>
              <div class="text-sm text-gray-600 dark:text-gray-400 mt-1">
                Permanently delete all files and folders. This cannot be undone.
              </div>
            </div>
          </div>

          <!-- Confirmation input for delete -->
          <div v-if="deleteOption === 'delete'" class="mt-4">
            <div class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Type <span class="font-mono font-bold">{{ project?.name }}</span> to confirm:
            </div>
            <Input
              v-model="deleteConfirmation"
              placeholder="Project name"
              class="font-mono"
            />
          </div>
        </label>
      </div>

      <template #actions>
        <Button variant="secondary" @click="cancelDelete">
          Cancel
        </Button>
        <Button
          variant="primary"
          @click="confirmDelete"
          :disabled="!canDelete"
          class="bg-red-600 hover:bg-red-500 focus-visible:outline-red-600 dark:bg-red-500 dark:hover:bg-red-400"
        >
          {{ deleteOption === 'delete' ? 'Delete Project' : 'Remove from Framework' }}
        </Button>
      </template>
    </Modal>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed, watch, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from '../composables/useToast'
import PageHeader from '../components/ui/PageHeader.vue'
import Card from '../components/ui/Card.vue'
import Alert from '../components/ui/Alert.vue'
import CopyButton from '../components/ui/CopyButton.vue'
import EmptyState from '../components/ui/EmptyState.vue'
import Input from '../components/ui/Input.vue'
import Button from '../components/ui/Button.vue'
import Toggle from '../components/ui/Toggle.vue'
import Checkbox from '../components/ui/Checkbox.vue'
import Select from '../components/ui/Select.vue'
import CodeEditor from '../components/ui/CodeEditor.vue'
import Tabs from '../components/ui/Tabs.vue'
import TabPanel from '../components/ui/TabPanel.vue'
import Modal from '../components/ui/Modal.vue'
import NavigationSectionHeading from '../components/ui/NavigationSectionHeading.vue'
import Repeater from '../components/ui/Repeater.vue'
import PackageAutocomplete from '../components/ui/PackageAutocomplete.vue'
import OverviewCard from '../components/ui/OverviewCard.vue'
import DataCatalogEditModal from '../components/DataCatalogEditModal.vue'
import DataCatalogTree from '../components/DataCatalogTree.vue'
import { createDataAnchorId } from '../utils/dataCatalog.js'
import GitHooksPanel from '../components/settings/GitHooksPanel.vue'
import ScaffoldBehaviorPanel from '../components/settings/ScaffoldBehaviorPanel.vue'
import ConnectionsPanel from '../components/settings/ConnectionsPanel.vue'
import EnvEditor from '../components/env/EnvEditor.vue'
import {
  InformationCircleIcon,
  UserIcon,
  Cog6ToothIcon,
  DocumentTextIcon,
  CircleStackIcon,
  ServerIcon,
  EyeIcon,
  EyeSlashIcon,
  CubeIcon,
  FolderIcon,
  PlusIcon,
  SparklesIcon,
  DocumentCheckIcon,
  AdjustmentsVerticalIcon,
  ServerStackIcon,
  KeyIcon
} from '@heroicons/vue/24/outline'

const route = useRoute()
const router = useRouter()
const toast = useToast()
const project = ref(null)
const loading = ref(true)
const error = ref(null)
const activeSection = ref('overview')
const VALID_SECTIONS = ['overview', 'basics', 'settings', 'notebooks', 'connections', 'data', 'packages', 'ai', 'git', 'scaffold', 'env']

const dataCatalog = ref(null)
const dataSearch = ref('')
const expandedDataKeys = ref(new Set())
const isEditingDataEntry = ref(false)
const editingDataEntry = ref(null)
const savingDataEntry = ref(false)
const dataEditError = ref(null)
const isCreatingDataEntry = ref(false)
const dataEntriesToDelete = ref(new Set())
const savingDataDeletes = ref(false)
const projectSettings = ref(null)
const editableSettings = ref({})
const settingsLoading = ref(false)
const settingsError = ref(null)
const saving = ref(false)
const gitSettings = ref({
  initialize: true,
  user_name: '',
  user_email: '',
  hooks: {
    ai_sync: false,
    data_security: false,
    check_sensitive_dirs: false
  }
})
const gitLoading = ref(false)
const gitError = ref(null)
const gitLoaded = ref(false)
const savingGit = ref(false)
const customWorkspaceDirectories = ref([])
const customInputDirectories = ref([])
const customOutputDirectories = ref([])
const savingCustomDirs = ref(false)
const databaseConnections = ref([])  // framework_db is implicit/reserved
const s3Connections = ref([])
const defaultDatabase = ref(null)
const defaultStorageBucket = ref(null)
const savingConnections = ref(false)
const packages = ref([])
const editablePackages = ref({ use_renv: false, default_packages: [] })
const packagesLoading = ref(false)
const packagesError = ref(null)
const savingPackages = ref(false)
const showAddPackageModal = ref(false)
const showDeleteModal = ref(false)
const deleteOption = ref('untrack') // 'untrack' or 'delete'
const deleteConfirmation = ref('')
const packageSearch = ref('')
const packageSearchResults = ref([])
const packageSearching = ref(false)
const packageSearchHighlightIndex = ref(-1)
const newPackage = ref({ name: '', source: 'cran', auto_attach: true })
const envVariables = ref({})
const envGroups = ref({})
const envRawContent = ref('')
const envLoading = ref(false)
const envError = ref(null)
const envLoaded = ref(false)
const savingEnv = ref(false)
const envViewMode = ref('grouped') // 'grouped' or 'raw'
const regroupOnSave = ref(false) // If true, regroup .env file by prefix (loses comments)
const availableAssistants = [
  { id: 'claude', label: 'Claude Code', description: "Anthropic's IDE-focused assistant." },
  { id: 'copilot', label: 'GitHub Copilot', description: 'Complements VS Code and JetBrains editors.' },
  { id: 'agents', label: 'Multi-Agent (OpenAI Codex, Cursor, etc.)', description: 'Shared instructions for multi-model orchestrators.' }
]
const aiSettings = ref({
  enabled: false,
  canonical_file: 'CLAUDE.md',
  canonical_content: '',
  assistants: []
})
const aiLoading = ref(false)
const aiError = ref(null)
const aiLoaded = ref(false)
const savingAI = ref(false)
const canonicalContentLoading = ref(false)
const aiContentMeta = ref({
  file: 'CLAUDE.md',
  exists: true
})
const envVariableCount = computed(() => Object.keys(envVariables.value || {}).length)
const basicsOverview = computed(() => {
  const name = project.value?.name || 'Untitled'
  const path = project.value?.path || ''
  const author = editableSettings.value?.author?.name || projectSettings.value?.author?.name || project.value?.author || ''
  return { name, path, author }
})
const projectStructureLabel = computed(() => {
  return project.value?.type || projectSettings.value?.project_type || 'Not set'
})
const notebookFormatLabel = computed(() => {
  return editableSettings.value?.scaffold?.notebook_format ||
    projectSettings.value?.scaffold?.notebook_format ||
    'quarto'
})
const formatAssistantLabel = (value) => {
  if (!value) return ''
  return value.charAt(0).toUpperCase() + value.slice(1)
}
const aiOverviewText = computed(() => {
  if (!aiSettings.value.enabled) {
    return 'Disabled'
  }
  const assistants = Array.isArray(aiSettings.value.assistants) ? aiSettings.value.assistants : []
  const assistantText = assistants.length
    ? assistants.map(formatAssistantLabel).join(', ')
    : 'Enabled'
  const canonical = aiSettings.value.canonical_file || 'CLAUDE.md'
  return `${assistantText} · ${canonical}`
})
const gitHookLabels = {
  ai_sync: 'AI sync',
  data_security: 'Secret scan',
  check_sensitive_dirs: 'Sensitive dirs'
}
const enabledGitHooks = computed(() => {
  const hooks = gitSettings.value?.hooks || {}
  return Object.entries(hooks)
    .filter(([, enabled]) => Boolean(enabled))
    .map(([key]) => gitHookLabels[key] || key)
})
const gitOverviewText = computed(() => {
  const base = gitSettings.value.initialize ? 'Auto-initialize repositories' : 'Manual initialization'
  return enabledGitHooks.value.length ? `${base} · ${enabledGitHooks.value.join(', ')}` : base
})
const packagesCount = computed(() => {
  return editablePackages.value?.default_packages?.length || 0
})
const packagesOverviewText = computed(() => {
  const renvText = editablePackages.value?.use_renv ? 'renv enabled' : 'renv disabled'
  return packagesCount.value > 0
    ? `${packagesCount.value} package${packagesCount.value === 1 ? '' : 's'} · ${renvText}`
    : `No default packages · ${renvText}`
})
const envOverviewText = computed(() => {
  return envVariableCount.value > 0
    ? `${envVariableCount.value} variable${envVariableCount.value === 1 ? '' : 's'}`
    : 'No variables defined'
})

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

const getNestedLinkClasses = (section) => {
  const isActive = activeSection.value === section
  return [
    'flex items-center gap-2 rounded-md px-3 py-1 text-xs font-medium transition',
    isActive
      ? 'bg-sky-100 text-sky-700 dark:bg-sky-900/30 dark:text-sky-300'
      : 'text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-800'
  ]
}

// Initialize activeSection from URL query param
const initializeSection = () => {
  const sectionFromUrl = route.query.section
  if (sectionFromUrl && VALID_SECTIONS.includes(sectionFromUrl)) {
    activeSection.value = sectionFromUrl
    if (sectionFromUrl === 'env') {
      loadEnv()
      nextTick(() => scrollToEnvSection())
    }
  } else {
    activeSection.value = 'overview'
  }
}

// Watch for activeSection changes and update URL
watch(activeSection, (newSection) => {
  router.replace({ query: { ...route.query, section: newSection } })

  // Load settings when Settings or Basics section is activated
  if ((newSection === 'settings' || newSection === 'basics' || newSection === 'scaffold') && !projectSettings.value) {
    loadProjectSettings()
  }

  // Load connections when Connections section is activated
  if (newSection === 'connections') {
    if (databaseConnections.value.length === 0 && s3Connections.value.length === 0) {
      loadConnections()
    }
  }

  // Load packages when Packages section is activated
  if (newSection === 'packages' && packages.value.length === 0) {
    loadPackages()
  }

  if (newSection === 'git' && !gitLoaded.value) {
    loadGitSettings()
  }

  if (newSection === 'ai' && !aiLoaded.value) {
    loadAISettings()
  }

  if (newSection === 'env' && !envLoaded.value) {
    loadEnv()
  }
})

// Watch for URL query param changes (browser back/forward)
watch(() => route.query.section, (newSection) => {
  if (newSection && VALID_SECTIONS.includes(newSection)) {
    activeSection.value = newSection
    if (newSection === 'env') {
      nextTick(() => scrollToEnvSection())
      if (!envLoaded.value) {
        loadEnv()
      }
    }
  } else if (!newSection) {
    activeSection.value = 'overview'
  }
})

let suppressCanonicalWatch = false
let suppressEnvWatch = false

watch(
  () => aiSettings.value.canonical_file,
  (newFile, oldFile) => {
    if (suppressCanonicalWatch) return
    if (!aiLoaded.value) return
    if (!newFile || newFile === oldFile) return
    handleCanonicalFileChange(newFile)
  }
)

// Watch env changes (these trigger from EnvEditor v-model updates)
watch(envVariables, (newVal) => {
  if (suppressEnvWatch) return
  console.log('[envVariables watcher] Value changed (not suppressed)')
}, { deep: true })

watch(envGroups, (newVal) => {
  if (suppressEnvWatch) return
  console.log('[envGroups watcher] Value changed (not suppressed)')
}, { deep: true })

watch(envRawContent, (newVal) => {
  if (suppressEnvWatch) return
  console.log('[envRawContent watcher] Value changed (not suppressed)')
})

// Debounce package search
let searchTimeout = null
watch(packageSearch, () => {
  if (searchTimeout) clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => {
    searchPackages()
  }, 300)
})

const formatNodeTitle = (value = '') => {
  return value
    .split(/[._-]/)
    .filter(Boolean)
    .map(part => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ')
}

const cloneDeep = (value) => JSON.parse(JSON.stringify(value))

const toNodeEntries = (value) => {
  if (Array.isArray(value)) {
    return value.map((item, index) => [String(index), item])
  }

  return Object.entries(value)
}

const buildDataTree = (value, prefix = '', depth = 0) => {
  if (!value || typeof value !== 'object') {
    return []
  }

  return toNodeEntries(value).reduce((acc, [key, child]) => {
    if (child == null) {
      return acc
    }

    const newKey = prefix ? `${prefix}.${key}` : key

    if (typeof child === 'object' && !Array.isArray(child) && child.path) {
      acc.push({
        type: 'leaf',
        name: key,
        displayName: formatNodeTitle(key),
        fullKey: newKey,
        data: child,
        leafCount: 1,
        depth: depth
      })
      return acc
    }

    if (typeof child === 'object') {
      const children = buildDataTree(child, newKey, depth + 1)
      if (children.length > 0) {
        const leafCount = children.reduce((total, item) => total + (item.leafCount || 0), 0)
        acc.push({
          type: 'group',
          name: key,
          displayName: formatNodeTitle(key),
          fullKey: newKey,
          children,
          leafCount,
          depth
        })
      }
    }

    return acc
  }, [])
}

const sortDataNodes = (nodes) => {
  return nodes
    .slice()
    .sort((a, b) => a.displayName.localeCompare(b.displayName, undefined, { sensitivity: 'base', numeric: true }))
    .map((node) => {
      if (node.type === 'group') {
        return {
          ...node,
          children: sortDataNodes(node.children)
        }
      }

      return node
    })
}

const nodeMatchesTerm = (node, term) => {
  if (!term) return true
  const lowerTerm = term.toLowerCase()
  const valuesToCheck = [node.displayName, node.name, node.fullKey]
  if (node.type === 'leaf' && node.data?.path) {
    valuesToCheck.push(node.data.path)
  }
  return valuesToCheck.some((value) => value && value.toLowerCase().includes(lowerTerm))
}

const filterDataNodes = (nodes, term) => {
  if (!term) {
    return {
      nodes,
      matchedKeys: new Set()
    }
  }

  const filteredNodes = []
  const matchedKeys = new Set()

  nodes.forEach((node) => {
    if (node.type === 'leaf') {
      if (nodeMatchesTerm(node, term)) {
        filteredNodes.push(node)
        matchedKeys.add(node.fullKey)
      }
      return
    }

    const childResult = filterDataNodes(node.children, term)
    const groupMatches = nodeMatchesTerm(node, term)

    if (groupMatches || childResult.nodes.length > 0) {
      const children = childResult.nodes
      const leafCount = children.reduce((total, item) => total + (item.leafCount || 0), 0)
      filteredNodes.push({
        ...node,
        children,
        leafCount: leafCount || node.leafCount
      })
      matchedKeys.add(node.fullKey)
      childResult.matchedKeys.forEach((value) => matchedKeys.add(value))
    }
  })

  return {
    nodes: filteredNodes,
    matchedKeys
  }
}

const dataTree = computed(() => {
  const catalog = dataCatalog.value

  if (!catalog || typeof catalog !== 'object') {
    return []
  }

  if (!Array.isArray(catalog) && catalog.path) {
    return [{
      type: 'leaf',
      name: catalog.name || 'data',
      displayName: formatNodeTitle(catalog.name || 'data'),
      fullKey: catalog.name || 'data',
      data: catalog,
      leafCount: 1,
      depth: 0
    }]
  }

  return sortDataNodes(buildDataTree(catalog))
})

const normalizedDataSearch = computed(() => dataSearch.value.trim().toLowerCase())

const filteredDataResult = computed(() => {
  const term = normalizedDataSearch.value
  if (!term) {
    return {
      nodes: dataTree.value,
      matchedKeys: new Set()
    }
  }

  return filterDataNodes(dataTree.value, term)
})

const displayDataTree = computed(() => filteredDataResult.value.nodes)
const autoExpandedDataKeys = computed(() => filteredDataResult.value.matchedKeys)
const isFilteringData = computed(() => normalizedDataSearch.value.length > 0)

const dataSectionSublinks = computed(() => {
  if (isFilteringData.value) return []

  return (dataTree.value || [])
    .filter((node) => (node.depth || 0) === 0)
    .map((node) => {
      const key = node.fullKey || node.name || ''
      return {
        anchorId: key ? createDataAnchorId(key) : null,
        label: node.displayName || formatNodeTitle(node.name || key || 'data source'),
        count: node.leafCount || (node.type === 'leaf' ? 1 : 0),
        nodeKey: key
      }
    })
    .filter((link) => link.anchorId && link.label)
})
const hasPendingDataDeletes = computed(() => dataEntriesToDelete.value.size > 0)
const pendingDeleteCount = computed(() => dataEntriesToDelete.value.size)
const pendingDeleteList = computed(() => Array.from(dataEntriesToDelete.value))

const computeMaxDepth = (nodes) => {
  let maxDepth = 0
  nodes.forEach((node) => {
    maxDepth = Math.max(maxDepth, node.depth || 0)
    if (node.type === 'group' && node.children) {
      maxDepth = Math.max(maxDepth, computeMaxDepth(node.children))
    }
  })
  return maxDepth
}

const maxDataDepth = computed(() => computeMaxDepth(dataTree.value))
const useHierarchicalDataView = computed(() => maxDataDepth.value > 2)

// Project Structure computed properties
const workspaceDirectories = computed(() => {
  const dirs = editableSettings.value.directories || {}
  const workspace = {}
  const workspaceKeys = ['functions', 'notebooks', 'scripts']

  Object.keys(dirs).forEach(key => {
    if (workspaceKeys.includes(key)) {
      workspace[key] = dirs[key]
    }
  })

  return workspace
})

const inputDirectories = computed(() => {
  const dirs = editableSettings.value.directories || {}
  const inputs = {}

  Object.keys(dirs).forEach(key => {
    if (key.startsWith('inputs_') || key.includes('_raw') || key.includes('_intermediate') || key.includes('_final')) {
      inputs[key] = dirs[key]
    }
  })

  return inputs
})

const outputDirectories = computed(() => {
  const dirs = editableSettings.value.directories || {}
  const outputs = {}

  Object.keys(dirs).forEach(key => {
    if ((key.startsWith('outputs_') || key.includes('_figures') || key.includes('_tables') || key.includes('_models') || key.includes('_reports') || key === 'cache' || key === 'scratch') && !key.startsWith('inputs_')) {
      outputs[key] = dirs[key]
    }
  })

  return outputs
})

const formatDirectoryLabel = (key) => {
  return key.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
}

const projectTypeLabel = computed(() => {
  const type = project.value?.type
  if (!type) return 'Standard Project Structure'

  // Map project types to their full labels
  const typeLabels = {
    'project': 'Standard Project Structure',
    'project_sensitive': 'Privacy Sensitive Project Structure',
    'presentation': 'Presentation Structure',
    'course': 'Course Structure'
  }

  return typeLabels[type] || type
})

const canDelete = computed(() => {
  if (deleteOption.value === 'untrack') {
    return true
  }
  if (deleteOption.value === 'delete') {
    return deleteConfirmation.value === project.value?.name
  }
  return false
})

const upsertDataCatalogEntry = (catalog, fullKey, newValue) => {
  const segments = fullKey.split('.').filter(Boolean)
  if (segments.length === 0) return null

  const updatedCatalog = cloneDeep(catalog || {})
  let cursor = updatedCatalog

  for (let i = 0; i < segments.length - 1; i++) {
    const segment = segments[i]
    if (!cursor[segment] || typeof cursor[segment] !== 'object' || Array.isArray(cursor[segment])) {
      cursor[segment] = {}
    }
    cursor = cursor[segment]
  }

  cursor[segments[segments.length - 1]] = cloneDeep(newValue)
  return updatedCatalog
}

const getDataCatalogEntry = (catalog, fullKey) => {
  if (!catalog || !fullKey) return null
  const segments = fullKey.split('.').filter(Boolean)
  if (segments.length === 0) return null

  let cursor = catalog
  for (let i = 0; i < segments.length; i++) {
    const segment = segments[i]
    if (!cursor || typeof cursor !== 'object' || !(segment in cursor)) {
      return null
    }
    cursor = cursor[segment]
  }
  return cursor
}

const ensureDataPathExpanded = (fullKey) => {
  const segments = fullKey.split('.').filter(Boolean)
  if (segments.length <= 1) return

  const updated = new Set(expandedDataKeys.value)
  let prefix = ''
  for (let i = 0; i < segments.length - 1; i++) {
    prefix = prefix ? `${prefix}.${segments[i]}` : segments[i]
    updated.add(prefix)
  }
  expandedDataKeys.value = updated
}

const scrollToDataAnchor = async (anchorId, nodeKey) => {
  if (!anchorId) return

  if (nodeKey) {
    ensureDataPathExpanded(nodeKey)
    const updated = new Set(expandedDataKeys.value)
    updated.add(nodeKey)
    expandedDataKeys.value = updated
  }

  await nextTick()

  const element = document.getElementById(anchorId)
  if (element) {
    element.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }
}

const persistDataCatalog = async (catalog) => {
  const response = await fetch(`/api/project/${route.params.id}/data`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ data: catalog })
  })
  const result = await response.json()
  if (!response.ok || result.error) {
    throw new Error(result.error || 'Failed to save data catalog')
  }
}

const openDataEditor = (node) => {
  if (!node) return
  isCreatingDataEntry.value = false
  editingDataEntry.value = {
    fullKey: node.fullKey,
    name: node.name,
    data: cloneDeep(node.data || {})
  }
  dataEditError.value = null
  isEditingDataEntry.value = true
}

const openDataCreator = () => {
  isCreatingDataEntry.value = true
  editingDataEntry.value = {
    fullKey: '',
    data: {}
  }
  dataEditError.value = null
  isEditingDataEntry.value = true
}

const handleDataModalVisibility = (value) => {
  isEditingDataEntry.value = value
  if (!value) {
    editingDataEntry.value = null
    dataEditError.value = null
    savingDataEntry.value = false
    isCreatingDataEntry.value = false
  }
}

const handleDataEntrySave = async (payload) => {
  if (!payload || !payload.fullKey || !payload.data) {
    dataEditError.value = payload?.error || 'Invalid data entry payload'
    return
  }

  const fullKey = payload.fullKey.trim()
  const isNew = Boolean(payload.isNew)

  if (!fullKey) {
    dataEditError.value = 'Dot notation key is required'
    return
  }

  if (isNew && getDataCatalogEntry(dataCatalog.value, fullKey)) {
    dataEditError.value = 'A data source with this key already exists'
    return
  }

  const previousCatalog = cloneDeep(dataCatalog.value)
  const updatedCatalog = upsertDataCatalogEntry(dataCatalog.value, fullKey, payload.data)

  if (!updatedCatalog) {
    dataEditError.value = 'Unable to write data entry to catalog'
    return
  }

  dataCatalog.value = updatedCatalog
  savingDataEntry.value = true
  dataEditError.value = null

  try {
    await persistDataCatalog(updatedCatalog)
    ensureDataPathExpanded(fullKey)
    toast.success(isNew ? 'Data Source Added' : 'Data Catalog Updated', isNew ? 'Data entry created successfully' : 'Data entry saved successfully')
    isEditingDataEntry.value = false
    editingDataEntry.value = null
    isCreatingDataEntry.value = false
    if (dataEntriesToDelete.value.has(fullKey)) {
      const updatedDeletes = new Set(dataEntriesToDelete.value)
      updatedDeletes.delete(fullKey)
      dataEntriesToDelete.value = updatedDeletes
    }
  } catch (err) {
    dataCatalog.value = previousCatalog
    dataEditError.value = err.message || 'Failed to save data catalog'
    toast.error('Save Failed', err.message || 'Failed to save data catalog')
  } finally {
    savingDataEntry.value = false
  }
}

const removeDataCatalogEntry = (catalog, fullKey) => {
  if (!catalog || !fullKey) return null
  const segments = fullKey.split('.').filter(Boolean)
  if (segments.length === 0) return null

  const updatedCatalog = cloneDeep(catalog)
  const pathStack = []
  let cursor = updatedCatalog

  for (let i = 0; i < segments.length; i++) {
    const segment = segments[i]
    if (!cursor || typeof cursor !== 'object' || !(segment in cursor)) {
      return null
    }
    pathStack.push({ parent: cursor, key: segment })
    cursor = cursor[segment]
  }

  const last = pathStack.pop()
  if (!last) return null
  delete last.parent[last.key]

  // Clean up empty objects up the chain
  for (let i = pathStack.length - 1; i >= 0; i--) {
    const { parent, key } = pathStack[i]
    if (parent[key] && typeof parent[key] === 'object' && !Array.isArray(parent[key]) && Object.keys(parent[key]).length === 0) {
      delete parent[key]
    }
  }

  return updatedCatalog
}

const savePendingDataDeletes = async () => {
  if (!hasPendingDataDeletes.value) return
  savingDataDeletes.value = true
  const currentCatalog = cloneDeep(dataCatalog.value)
  let nextCatalog = cloneDeep(currentCatalog)

  for (const key of dataEntriesToDelete.value) {
    const updated = removeDataCatalogEntry(nextCatalog, key)
    if (!updated) {
      toast.error('Delete Failed', `Unable to locate ${key} in catalog`)
      savingDataDeletes.value = false
      return
    }
    nextCatalog = updated
  }

  try {
    await persistDataCatalog(nextCatalog)
    dataCatalog.value = nextCatalog
    toast.success('Data Catalog Updated', 'Staged deletions have been saved')
    dataEntriesToDelete.value = new Set()
  } catch (err) {
    toast.error('Delete Failed', err.message || 'Failed to save catalog changes')
  } finally {
    savingDataDeletes.value = false
  }
}

const toggleDataDelete = (node) => {
  if (!node || !node.fullKey) return
  const updated = new Set(dataEntriesToDelete.value)
  if (updated.has(node.fullKey)) {
    updated.delete(node.fullKey)
  } else {
    updated.add(node.fullKey)
  }
  dataEntriesToDelete.value = updated
}

const clearPendingDataDeletes = () => {
  dataEntriesToDelete.value = new Set()
}

const toggleDataGroup = (key) => {
  const updated = new Set(expandedDataKeys.value)
  if (updated.has(key)) {
    updated.delete(key)
  } else {
    updated.add(key)
  }
  expandedDataKeys.value = updated
}

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

      // Ensure scaffold object exists with defaults
      if (!editableSettings.value.scaffold) {
        editableSettings.value.scaffold = {
          notebook_format: 'quarto',
          positron: false
        }
      }
    }
  } catch (err) {
    settingsError.value = 'Failed to load settings: ' + err.message
  } finally {
    settingsLoading.value = false
  }
}

const saveCurrentSection = async () => {
  switch (activeSection.value) {
    case 'author':
    case 'settings':
      await saveSettings()
      break
    case 'packages':
      await savePackages()
      break
    case 'scaffold':
      await saveSettings()
      break
    case 'git':
      await saveGitSettings()
      break
    case 'connections':
      await saveConnections()
      break
    case 'ai':
      await saveAISettings()
      break
    case 'env':
      await saveEnv()
      break
    case 'overview':
    case 'notebooks':
    case 'data':
      toast.info('No Changes to Save', 'This section has no editable settings')
      break
    default:
      toast.info('No Changes to Save', 'This section has no editable settings')
  }
}

const saveSettings = async () => {
  saving.value = true

  try {
    // First, save custom directories if there are any
    const allCustomDirectories = [
      ...customWorkspaceDirectories.value,
      ...customInputDirectories.value,
      ...customOutputDirectories.value
    ]

    if (allCustomDirectories.length > 0) {
      const dirResponse = await fetch(`/api/project/${route.params.id}/directories`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ directories: allCustomDirectories })
      })

      const dirResult = await dirResponse.json()

      if (!dirResult.success) {
        toast.error('Directory Creation Failed', dirResult.error || 'Failed to create directories')
        saving.value = false
        return
      }

      // Clear the custom directory arrays after successful save
      customWorkspaceDirectories.value = []
      customInputDirectories.value = []
      customOutputDirectories.value = []
    }

    // Then save settings
    const response = await fetch(`/api/project/${route.params.id}/settings`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(editableSettings.value)
    })

    const result = await response.json()

    if (result.success) {
      const message = allCustomDirectories.length > 0
        ? `Settings updated and ${allCustomDirectories.length} director${allCustomDirectories.length === 1 ? 'y' : 'ies'} created`
        : 'Project settings have been updated'

      toast.success('Settings Saved', message)
      projectSettings.value = JSON.parse(JSON.stringify(editableSettings.value))
      // Reload settings to verify save and show new directories
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

const handleDataSublinkClick = (link) => {
  if (!link) return
  scrollToDataAnchor(link.anchorId, link.nodeKey)
}

const scrollToEnvSection = () => {
  const element = document.getElementById('env')
  if (element) {
    element.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }
}

// DISABLED - connections removed
const loadConnections = async () => {
  try {
    const response = await fetch(`/api/project/${route.params.id}/connections`)
    const data = await response.json()

    if (data.error) {
      console.error('Failed to load connections:', data.error)
    } else {
      // Convert databases object to array for Repeater
      const dbArray = Object.entries(data.databases || {}).map(([name, conn]) => ({
        _id: name,
        name,
        ...conn
      }))

      // Convert storage_buckets object to array for Repeater
      const s3Array = Object.entries(data.storage_buckets || {}).map(([name, conn]) => ({
        _id: name,
        name,
        ...conn
      }))

      databaseConnections.value = dbArray
      s3Connections.value = s3Array
      defaultDatabase.value = data.default_database || null
      defaultStorageBucket.value = data.default_storage_bucket || null
    }
  } catch (err) {
    console.error('Failed to load connections:', err.message)
  }
}

// DISABLED - connections removed
// const toggleConnectionDelete = (name) => {
//   if (connectionsToDelete.value.has(name)) {
//     connectionsToDelete.value.delete(name)
//   } else {
//     connectionsToDelete.value.add(name)
//   }
// }

const saveCustomDirectories = async (category) => {
  // Get the appropriate ref based on category
  let directoriesRef
  let categoryLabel

  if (category === 'workspace') {
    directoriesRef = customWorkspaceDirectories
    categoryLabel = 'workspace'
  } else if (category === 'input') {
    directoriesRef = customInputDirectories
    categoryLabel = 'input'
  } else if (category === 'output') {
    directoriesRef = customOutputDirectories
    categoryLabel = 'output'
  } else {
    return
  }

  if (directoriesRef.value.length === 0) return

  savingCustomDirs.value = true

  try {
    const response = await fetch(`/api/project/${route.params.id}/directories`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ directories: directoriesRef.value })
    })

    const result = await response.json()

    if (result.success) {
      const count = directoriesRef.value.length
      toast.success('Directories Created', `${count} ${categoryLabel} director${count === 1 ? 'y' : 'ies'} created`)
      directoriesRef.value = []
      await loadProjectSettings() // Reload to show new directories
    } else {
      toast.error('Creation Failed', result.error || 'Failed to create directories')
    }
  } catch (err) {
    toast.error('Creation Failed', err.message)
  } finally {
    savingCustomDirs.value = false
  }
}

// DISABLED - connections removed
// const saveConnections = async () => {
//   savingConnections.value = true
//
//   try {
//     // Filter out connections marked for deletion
//     const connectionsToSave = { ...connections.value }
//     if (connectionsToSave.connections) {
//       connectionsToSave.connections = Object.fromEntries(
//         Object.entries(connectionsToSave.connections)
//           .filter(([name]) => !connectionsToDelete.value.has(name))
//       )
//     }
//
//     const response = await fetch(`/api/project/${route.params.id}/connections`, {
//       method: 'POST',
//       headers: { 'Content-Type': 'application/json' },
//       body: JSON.stringify(connectionsToSave)
//     })
//
//     const result = await response.json()
//
//     if (result.success) {
//       connectionsToDelete.value.clear() // Clear staged deletions
//       toast.success('Connections Saved', 'Connection settings have been updated')
//       await loadConnections()
//     } else {
//       toast.error('Save Failed', result.error || 'Failed to save connections')
//     }
//   } catch (err) {
//     toast.error('Save Failed', err.message)
//   } finally {
//     savingConnections.value = false
//   }
// }

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

      // Also populate editablePackages for the new UI
      editablePackages.value = {
        use_renv: data.use_renv || false,
        default_packages: JSON.parse(JSON.stringify(packages.value))
      }
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
      body: JSON.stringify({
        use_renv: editablePackages.value.use_renv,
        packages: editablePackages.value.default_packages
      })
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

const saveConnections = async () => {
  savingConnections.value = true

  try {
    // Convert arrays to nested object structure for YAML storage
    const databases = {}
    databaseConnections.value.forEach(conn => {
      const { _id, name, ...fields } = conn
      databases[name] = fields
    })

    const storage_buckets = {}
    s3Connections.value.forEach(conn => {
      const { _id, name, ...fields } = conn
      storage_buckets[name] = fields
    })

    const response = await fetch(`/api/project/${route.params.id}/connections`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        default_database: defaultDatabase.value,
        default_storage_bucket: defaultStorageBucket.value,
        databases,
        storage_buckets
      })
    })

    const result = await response.json()

    if (result.success) {
      toast.success('Connections Saved', 'Connection configuration has been updated')
    } else {
      toast.error('Save Failed', result.error || 'Failed to save connections')
    }
  } catch (err) {
    toast.error('Save Failed', err.message)
  } finally {
    savingConnections.value = false
  }
}

const addPackage = () => {
  if (!editablePackages.value.default_packages) {
    editablePackages.value.default_packages = []
  }
  editablePackages.value.default_packages.push({
    name: '',
    source: 'cran',
    auto_attach: true
  })
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

const cancelDelete = () => {
  showDeleteModal.value = false
  deleteOption.value = 'untrack'
  deleteConfirmation.value = ''
}

const confirmDelete = async () => {
  if (!canDelete.value) {
    console.log('[DELETE] Cannot delete - canDelete is false')
    return
  }

  console.log('[DELETE] Starting delete with option:', deleteOption.value)
  console.log('[DELETE] Project ID:', route.params.id)

  try {
    const endpoint = deleteOption.value === 'delete'
      ? `/api/projects/${route.params.id}/delete`
      : `/api/projects/${route.params.id}/untrack`

    console.log('[DELETE] Calling endpoint:', endpoint)

    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    })

    console.log('[DELETE] Response status:', response.status)

    if (!response.ok) {
      const error = await response.json()
      console.error('[DELETE] Error response:', error)
      throw new Error(error.message || 'Failed to delete project')
    }

    const result = await response.json()
    console.log('[DELETE] Success result:', result)

    const action = deleteOption.value === 'delete' ? 'deleted' : 'removed from Framework'
    toast.success('Project Removed', `${project.value.name} has been ${action}`)

    // Full page reload to refresh sidebar menu
    setTimeout(() => {
      window.location.href = '/projects'
    }, 500) // Small delay to show toast
  } catch (error) {
    console.error('[DELETE] Failed to delete project:', error)
    toast.error('Delete Failed', error.message || 'Could not delete project')
  }
}

const removePackage = (index) => {
  editablePackages.value.default_packages.splice(index, 1)
}

const normalizeAssistantList = (value) => {
  if (!value) return []
  if (Array.isArray(value)) {
    return Array.from(new Set(value.map((item) => String(item))))
  }
  if (typeof value === 'string') {
    return [value]
  }
  return []
}

const fetchProjectAI = async (canonicalOverride) => {
  let endpoint = `/api/project/${route.params.id}/ai`
  if (canonicalOverride) {
    const params = new URLSearchParams()
    params.set('canonical_file', canonicalOverride)
    endpoint += `?${params.toString()}`
  }

  const response = await fetch(endpoint)
  if (!response.ok) {
    throw new Error('Failed to load AI settings')
  }
  return response.json()
}

const loadAISettings = async () => {
  aiLoading.value = true
  aiError.value = null

  try {
    const data = await fetchProjectAI()

    if (data.error) {
      aiError.value = data.error
      aiLoaded.value = false
      return
    }

    const ai = data.ai || {}
    suppressCanonicalWatch = true
    const initialSettings = {
      enabled: Boolean(ai.enabled),
      canonical_file: ai.canonical_file || 'CLAUDE.md',
      canonical_content: ai.canonical_content || '',
      assistants: normalizeAssistantList(ai.assistants)
    }
    aiSettings.value = initialSettings

    aiContentMeta.value = {
      file: ai.content_file || ai.canonical_file || 'CLAUDE.md',
      exists: Boolean(ai.content_exists)
    }
    suppressCanonicalWatch = false

    await loadCanonicalContent(initialSettings.canonical_file, { preserveContentIfMissing: false })

    aiLoaded.value = true
  } catch (err) {
    aiError.value = err.message || 'Failed to load AI settings'
    aiLoaded.value = false
  } finally {
    suppressCanonicalWatch = false
    aiLoading.value = false
    canonicalContentLoading.value = false
  }
}

const loadGitSettings = async () => {
  gitLoading.value = true
  gitError.value = null

  try {
    const response = await fetch(`/api/project/${route.params.id}/git`)
    const data = await response.json()

    if (data.error) {
      gitError.value = data.error
      gitLoaded.value = false
      return
    }

    const git = data.git || {}
    gitSettings.value = {
      initialize: git.initialize !== undefined ? Boolean(git.initialize) : true,
      user_name: git.user_name || '',
      user_email: git.user_email || '',
      hooks: {
        ai_sync: git.hooks?.ai_sync || false,
        data_security: git.hooks?.data_security || false,
        check_sensitive_dirs: git.hooks?.check_sensitive_dirs || false
      }
    }

    gitLoaded.value = true
  } catch (err) {
    gitError.value = err.message || 'Failed to load Git settings'
    gitLoaded.value = false
  } finally {
    gitLoading.value = false
  }
}

const gitPanelModel = computed({
  get() {
    return {
      initialize: gitSettings.value.initialize,
      user_name: gitSettings.value.user_name || '',
      user_email: gitSettings.value.user_email || '',
      hooks: {
        ai_sync: gitSettings.value.hooks?.ai_sync || false,
        data_security: gitSettings.value.hooks?.data_security || false,
        check_sensitive_dirs: gitSettings.value.hooks?.check_sensitive_dirs || false
      }
    }
  },
  set(val) {
    gitSettings.value = {
      initialize: val.initialize,
      user_name: val.user_name,
      user_email: val.user_email,
      hooks: {
        ai_sync: val.hooks.ai_sync,
        data_security: val.hooks.data_security,
        check_sensitive_dirs: val.hooks.check_sensitive_dirs
      }
    }
  }
})

const loadCanonicalContent = async (fileName, { preserveContentIfMissing = true } = {}) => {
  if (!fileName) return
  canonicalContentLoading.value = true

  try {
    const data = await fetchProjectAI(fileName)
    if (data.error) {
      toast.error('Load Failed', data.error)
      return
    }

    const ai = data.ai || {}
    aiContentMeta.value = {
      file: ai.content_file || fileName,
      exists: Boolean(ai.content_exists)
    }

    if (ai.content_exists || !preserveContentIfMissing) {
      aiSettings.value.canonical_content = ai.canonical_content || ''
    }
  } catch (err) {
    toast.error('Load Failed', err.message || 'Unable to load canonical file')
  } finally {
    canonicalContentLoading.value = false
  }
}

const handleCanonicalFileChange = (value) => {
  const nextValue = typeof value === 'string' && value.length > 0 ? value : 'CLAUDE.md'
  loadCanonicalContent(nextValue, { preserveContentIfMissing: true })
}

const toggleAiAssistant = (assistantId, enabled) => {
  if (!assistantId) return
  const current = new Set(aiSettings.value.assistants)
  if (enabled) {
    current.add(assistantId)
  } else {
    current.delete(assistantId)
  }
  aiSettings.value.assistants = Array.from(current)
}

const saveAISettings = async () => {
  savingAI.value = true

  try {
    const response = await fetch(`/api/project/${route.params.id}/ai`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        enabled: aiSettings.value.enabled,
        canonical_file: aiSettings.value.canonical_file,
        assistants: aiSettings.value.assistants,
        canonical_content: aiSettings.value.canonical_content
      })
    })

    const result = await response.json()

    if (result.success) {
      toast.success('AI Settings Saved', 'AI assistant configuration has been updated')
      aiLoaded.value = false
      await loadAISettings()
    } else {
      toast.error('Save Failed', result.error || 'Failed to save AI settings')
    }
  } catch (err) {
    toast.error('Save Failed', err.message || 'Failed to save AI settings')
  } finally {
    savingAI.value = false
  }
}

const saveGitSettings = async () => {
  savingGit.value = true

  try {
    const response = await fetch(`/api/project/${route.params.id}/git`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        initialize: gitSettings.value.initialize,
        user_name: gitSettings.value.user_name,
        user_email: gitSettings.value.user_email,
        hooks: gitSettings.value.hooks
      })
    })

    const result = await response.json()

    if (result.success) {
      toast.success('Git Settings Saved', 'Repository configuration has been updated')
      gitLoaded.value = false
      await loadGitSettings()
    } else {
      toast.error('Save Failed', result.error || 'Failed to save Git settings')
    }
  } catch (err) {
    toast.error('Save Failed', err.message || 'Failed to save Git settings')
  } finally {
    savingGit.value = false
  }
}

const loadEnv = async () => {
  if (envLoading.value || envLoaded.value) {
    console.log('[loadEnv] Blocked: already loading or loaded', { loading: envLoading.value, loaded: envLoaded.value })
    return
  }

  envLoading.value = true
  envError.value = null

  try {
    const response = await fetch(`/api/project/${route.params.id}/env`)
    const data = await response.json()

    if (data.error) {
      envError.value = data.error
      envLoaded.value = false
    } else {
      // Suppress watchers while updating reactive values
      suppressEnvWatch = true
      console.log('[loadEnv] Updating env values with suppressEnvWatch = true')

      envLoaded.value = true
      envVariables.value = data.variables || {}
      envGroups.value = data.groups || {}
      envRawContent.value = data.raw_content || ''

      suppressEnvWatch = false
      console.log('[loadEnv] Env values updated, suppressEnvWatch = false')
    }
  } catch (err) {
    envError.value = 'Failed to load .env: ' + err.message
    envLoaded.value = false
  } finally {
    suppressEnvWatch = false
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
      envLoaded.value = false
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

// Keyboard shortcuts
const handleKeydown = (e) => {
  // Cmd/Ctrl + S to save
  if ((e.metaKey || e.ctrlKey) && e.key === 's') {
    e.preventDefault()
    if (activeSection.value === 'settings' || activeSection.value === 'scaffold') {
      saveSettings()
    } else if (activeSection.value === 'connections') {
      saveConnections()
    } else if (activeSection.value === 'packages') {
      savePackages()
    } else if (activeSection.value === 'git') {
      saveGitSettings()
    } else if (activeSection.value === 'ai') {
      saveAISettings()
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
  loadProjectSettings()
  loadPackages()
  loadAISettings()
  loadGitSettings()
  loadEnv()
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})

// Watch for route changes to reload project when switching between projects
watch(() => route.params.id, (newId, oldId) => {
  if (newId && newId !== oldId) {
    // Reset state
    activeSection.value = 'overview'
    project.value = null
    projectSettings.value = null
    editableSettings.value = {}
    settingsError.value = null
    settingsLoading.value = false
    // DISABLED - connections removed
    // connections.value = null
    // connectionsError.value = null
    // connectionsToDelete.value = new Set()
    // connectionsLoading.value = false
    packages.value = []
    editablePackages.value = { use_renv: false, default_packages: [] }
    packagesError.value = null
    packagesLoading.value = false
    dataCatalog.value = null
    dataEntriesToDelete.value = new Set()
    dataEditError.value = null
    editingDataEntry.value = null
    envVariables.value = {}
    envGroups.value = {}
    envRawContent.value = ''
    envError.value = null
    envLoading.value = false
    envViewMode.value = 'grouped'
    regroupOnSave.value = false
    gitSettings.value = {
      initialize: true,
      user_name: '',
      user_email: '',
      hooks: {
        ai_sync: false,
        data_security: false,
        check_sensitive_dirs: false
      }
    }
    gitLoaded.value = false
    gitError.value = null
    gitLoading.value = false

    suppressCanonicalWatch = true
    aiSettings.value = {
      enabled: false,
      canonical_file: 'CLAUDE.md',
      canonical_content: '',
      assistants: []
    }
    aiContentMeta.value = { file: 'CLAUDE.md', exists: true }
    aiLoaded.value = false
    aiError.value = null
    aiLoading.value = false
    canonicalContentLoading.value = false
    suppressCanonicalWatch = false
    envLoaded.value = false
    envError.value = null
    envLoading.value = false
    dataCatalog.value = null

    // Reload project data
    initializeSection()
    loadProject()
    loadDataCatalog()
    loadProjectSettings()
    loadPackages()
    loadAISettings()
    loadGitSettings()
    loadEnv()
  }
})
</script>
