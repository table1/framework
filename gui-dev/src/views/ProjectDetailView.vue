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
          <CopyButton :value="project.path" successMessage="Path copied" class="shrink-0" />
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
          href="#quarto"
          @click.prevent="activeSection = 'quarto'"
          :class="getSidebarLinkClasses('quarto')"
        >
          <DocumentTextIcon class="h-4 w-4" />
          Quarto
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
          href="#inputs"
          @click.prevent="activeSection = 'inputs'"
          :class="getSidebarLinkClasses('inputs')"
        >
          <ArrowDownTrayIcon class="h-4 w-4" />
          Inputs
        </a>

        <a
          href="#outputs"
          @click.prevent="activeSection = 'outputs'"
          :class="getSidebarLinkClasses('outputs')"
        >
          <ArrowUpTrayIcon class="h-4 w-4" />
          Outputs
        </a>

        <a
          href="#results"
          @click.prevent="activeSection = 'results'"
          :class="getSidebarLinkClasses('results')"
        >
          <ChartBarIcon class="h-4 w-4" />
          Results
        </a>

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
          :disabled="saving || savingPackages || savingEnv || savingAI || savingGit || savingConnections || savingQuartoFiles || savingQuartoDefaults"
          class="w-full"
        >
          {{
            (saving || savingPackages || savingEnv || savingAI || savingGit || savingConnections || savingQuartoFiles || savingQuartoDefaults)
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

        <OverviewSummary
          :cards="overviewCards"
          @navigate="(section) => activeSection = section"
        />
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
                  description="Creates .code-workspace file for Positron/VS Code users"
                >
                  Positron / VS Code
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
              <div v-if="editableSettings.author" class="pt-6 border-t border-gray-200 dark:border-gray-700">
                <AuthorInformationPanel v-model="editableSettings.author" />
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

        <div v-else-if="projectSettings">
          <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Project Structure</h2>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
            This project uses the <strong>{{ projectTypeLabel }}</strong> structure.
          </p>

          <Alert
            type="info"
            title="Append-Only Mode"
            description="You can enable disabled directories and add new custom directories. Directories that are already enabled cannot be turned off to prevent accidental data loss."
            class="mb-6"
          />

          <ProjectStructureEditor
            :project-type="project.type"
            :directories="editableSettings.directories || {}"
            :render-dirs="editableSettings.render_dirs || {}"
            :enabled="editableSettings.enabled || directoriesEnabledForDisplay"
            :extra-directories="editableSettings.extra_directories || []"
            :settings="editableSettings"
            :gitignore="editableSettings.gitignore || ''"
            :catalog="settingsCatalog?.project_types?.[project.type] || {}"
            :new-extra-ids="newExtraIds"
            :allow-destruction="false"
            @update:directories="editableSettings.directories = $event"
            @update:render-dirs="editableSettings.render_dirs = $event"
            @update:enabled="editableSettings.enabled = $event"
            @update:extra-directories="editableSettings.extra_directories = $event"
            @update:gitignore="editableSettings.gitignore = $event"
            @update:newExtraIds="newExtraIds = $event"
          />
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
            :pending-updates="pendingDataUpdates"
            :pending-adds="pendingAddedList"
            :project-path="project?.path || ''"
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
        </div>
        <div v-if="hasPendingDataAdds || pendingDataUpdates" class="mt-4 rounded-lg border border-emerald-200 bg-emerald-50 p-4 dark:border-emerald-500/40 dark:bg-emerald-900/20">
          <p class="text-sm font-medium text-emerald-800 dark:text-emerald-200">
            {{ hasPendingDataAdds ? `${pendingAddedList.length} data source${pendingAddedList.length === 1 ? '' : 's'} added.` : 'Data changes pending save.' }}
          </p>
          <p class="text-xs text-emerald-700 dark:text-emerald-200/80">
            {{ hasPendingDataAdds ? 'Adds will be applied when you save.' : 'Changes will be applied when you save.' }}
          </p>
          <ul v-if="pendingAddedList.length > 0" class="mt-2 list-disc space-y-1 pl-5 text-xs font-mono text-emerald-800 dark:text-emerald-100">
            <li v-for="key in pendingAddedList" :key="key">{{ key }}</li>
          </ul>
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

          <div v-if="untrackedInputFiles.length > 0" class="mt-6">
            <div class="space-y-1">
              <div class="text-sm font-semibold text-zinc-800 dark:text-zinc-100">Input files not in catalog</div>
              <p class="text-xs text-zinc-500 dark:text-zinc-400">
                We scanned your input directory and found these files aren't in the data catalog yet. Click Add to include them.
              </p>
            </div>

            <div
              class="mt-4 space-y-2"
            >
              <div class="flex items-center justify-between">
                <div class="text-sm text-zinc-600 dark:text-zinc-300">
                  {{ untrackedInputFiles.length }} file{{ untrackedInputFiles.length === 1 ? '' : 's' }} found in inputs/
                </div>
                <div v-if="inputFilesError" class="text-xs text-red-600 dark:text-red-400">
                  {{ inputFilesError }}
                </div>
              </div>

              <div class="max-h-64 overflow-y-auto space-y-2">
                <div
                  v-for="file in untrackedInputFiles"
                  :key="file.path"
                  class="flex items-center justify-between gap-3 rounded-lg border border-zinc-200 bg-white px-3 py-2 shadow-sm dark:border-zinc-700 dark:bg-zinc-900/60"
                >
                  <div class="min-w-0">
                    <div class="font-mono text-sm text-zinc-900 dark:text-zinc-100 truncate">{{ file.path }}</div>
                    <div class="text-xs text-zinc-500 dark:text-zinc-400">Type: {{ file.type || 'auto-detect' }}</div>
                  </div>
                  <Button size="xs" variant="secondary" @click="openDataCreatorWithPath(file)">
                    Add to Data Catalog
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </template>
      </div>

      <DataCatalogEditModal
        :mode="isCreatingDataEntry ? 'create' : 'edit'"
        v-model="isEditingDataEntry"
        :entry="editingDataEntry"
        :saving="savingDataEntry"
        :project-id="route.params.id"
        :existing-paths="dataCatalogPaths"
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

      <!-- Inputs Section -->
      <div v-show="activeSection === 'inputs'" id="inputs">
        <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Input Files</h2>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
          Browse files in your input directories.
        </p>

        <Tabs v-model="inputsTab" :tabs="inputTabs" variant="pills" class="mb-6">
          <TabPanel id="raw" :active="inputsTab === 'raw'">
            <FileBrowser
              :files="inputsRaw"
              :loading="loadingInputs"
              emptyTitle="No raw input files"
              emptyDescription="Add raw data files to your inputs/raw directory."
            />
          </TabPanel>
          <TabPanel id="intermediate" :active="inputsTab === 'intermediate'">
            <FileBrowser
              :files="inputsIntermediate"
              :loading="loadingInputs"
              emptyTitle="No intermediate files"
              emptyDescription="Processed data files will appear in inputs/intermediate."
            />
          </TabPanel>
          <TabPanel id="final" :active="inputsTab === 'final'">
            <FileBrowser
              :files="inputsFinal"
              :loading="loadingInputs"
              emptyTitle="No final input files"
              emptyDescription="Final processed data files will appear in inputs/final."
            />
          </TabPanel>
          <TabPanel id="reference" :active="inputsTab === 'reference'">
            <FileBrowser
              :files="inputsReference"
              :loading="loadingInputs"
              emptyTitle="No reference files"
              emptyDescription="Reference data and lookup tables go in inputs/reference."
            />
          </TabPanel>
        </Tabs>
      </div>

      <!-- Outputs Section -->
      <div v-show="activeSection === 'outputs'" id="outputs">
        <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Output Files</h2>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
          Browse files in your output directories.
        </p>

        <Tabs v-model="outputsTab" :tabs="outputTabs" variant="pills" class="mb-6">
          <TabPanel id="tables" :active="outputsTab === 'tables'">
            <FileBrowser
              :files="outputsTables"
              :loading="loadingOutputs"
              emptyTitle="No saved tables"
              emptyDescription="Tables saved with save_table() will appear here."
            />
          </TabPanel>
          <TabPanel id="figures" :active="outputsTab === 'figures'">
            <FileBrowser
              :files="outputsFigures"
              :loading="loadingOutputs"
              emptyTitle="No saved figures"
              emptyDescription="Figures saved with save_figure() will appear here."
            />
          </TabPanel>
          <TabPanel id="models" :active="outputsTab === 'models'">
            <FileBrowser
              :files="outputsModels"
              :loading="loadingOutputs"
              emptyTitle="No saved models"
              emptyDescription="Models saved with save_model() will appear here."
            />
          </TabPanel>
          <TabPanel id="reports" :active="outputsTab === 'reports'">
            <FileBrowser
              :files="outputsReports"
              :loading="loadingOutputs"
              emptyTitle="No saved reports"
              emptyDescription="Reports saved with save_report() will appear here."
            />
          </TabPanel>
          <TabPanel id="notebooks_output" :active="outputsTab === 'notebooks_output'">
            <FileBrowser
              :files="outputsNotebooks"
              :loading="loadingOutputs"
              emptyTitle="No rendered notebooks"
              emptyDescription="Notebooks saved with save_notebook() will appear here."
            />
          </TabPanel>
        </Tabs>
      </div>

      <!-- Results Section -->
      <div v-show="activeSection === 'results'" id="results">
        <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Saved Results</h2>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
          Results tracked in the database via save_table(), save_figure(), save_model(), etc.
        </p>

        <ResultsList
          :results="projectResults"
          :loading="loadingResults"
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

          <PackagesEditor
            v-model="editablePackages"
            :show-renv-toggle="true"
            :flush="false"
          />
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

          <AIAssistantsPanel
            v-model="aiSettings"
            :flush="false"
            :show-editor="true"
            editor-height="400px"
            :editor-disabled="canonicalContentLoading"
            :editor-loading="canonicalContentLoading"
          >
            <template #editor-alert>
              <Alert
                v-if="!aiContentMeta.exists"
                type="info"
                title="New canonical file"
                :description="`Saving copies the current instructions into ${aiSettings.canonical_file || 'CLAUDE.md'}. The original file stays on disk; if AI sync hooks are enabled they mirror everything from the new canonical file.`"
                class="mb-4"
              />
            </template>
          </AIAssistantsPanel>
        </div>
      </div>

      <!-- Quarto Section -->
      <div v-show="activeSection === 'quarto'" id="quarto">
        <div v-if="loadingQuartoFiles">
          <div class="text-center py-12 text-sm text-gray-500 dark:text-gray-400">Loading Quarto files...</div>
        </div>

        <div v-else>
          <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">Quarto</h2>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
            Edit project _quarto.yml files and default rendering options.
          </p>

          <!-- File Editor Section -->
          <div class="rounded-lg bg-gray-50 p-4 dark:bg-gray-800/50 space-y-3">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Configuration File
              </label>
              <select
                v-model="selectedQuartoFileKey"
                class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm shadow-sm focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-200"
              >
                <option v-for="file in quartoFiles" :key="file.key" :value="file.key">
                  {{ file.label }} — {{ file.path }}
                </option>
              </select>
            </div>

            <div v-if="selectedQuartoFile" class="rounded-md border border-gray-200 dark:border-gray-700 overflow-hidden">
              <CodeEditor
                v-model="selectedQuartoFileContent"
                language="yaml"
                :auto-grow="true"
                class="min-h-[300px] w-full"
              />
            </div>
            <div v-else class="text-sm text-gray-500 dark:text-gray-400 py-8 text-center">
              No Quarto files detected for this project.
            </div>
          </div>

          <!-- Quarto Defaults Section -->
          <div class="mt-4 rounded-lg bg-gray-50 p-4 dark:bg-gray-800/50">
            <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-3">Quarto Defaults</h3>
            <QuartoSettingsPanel v-model="projectQuartoDefaults" flush />
          </div>

          <!-- Regenerate Section -->
          <div class="mt-4 rounded-lg border border-amber-200 bg-amber-50 p-4 dark:border-amber-800 dark:bg-amber-900/20">
            <div class="flex items-start justify-between gap-4">
              <div>
                <h3 class="text-sm font-semibold text-amber-900 dark:text-amber-100 mb-1">Regenerate Configurations</h3>
                <p class="text-sm text-amber-800 dark:text-amber-200">
                  Overwrite all _quarto.yml files using current settings. Existing files are backed up to <code class="px-1 py-0.5 bg-amber-100 dark:bg-amber-800 rounded text-xs">.quarto_backups/</code>.
                </p>
              </div>
              <Button
                variant="secondary"
                size="sm"
                @click="regenerateQuartoConfigs"
                :disabled="regeneratingQuarto"
                class="shrink-0"
              >
                {{ regeneratingQuarto ? 'Regenerating...' : 'Regenerate' }}
              </Button>
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
import OverviewSummary from '../components/OverviewSummary.vue'
import DataCatalogEditModal from '../components/DataCatalogEditModal.vue'
import DataCatalogTree from '../components/DataCatalogTree.vue'
import FileBrowser from '../components/FileBrowser.vue'
import ResultsList from '../components/ResultsList.vue'
import { createDataAnchorId } from '../utils/dataCatalog.js'
import AuthorInformationPanel from '../components/settings/AuthorInformationPanel.vue'
import PackagesEditor from '../components/settings/PackagesEditor.vue'
import AIAssistantsPanel from '../components/settings/AIAssistantsPanel.vue'
import GitHooksPanel from '../components/settings/GitHooksPanel.vue'
import ScaffoldBehaviorPanel from '../components/settings/ScaffoldBehaviorPanel.vue'
import ProjectStructureEditor from '../components/settings/ProjectStructureEditor.vue'
import ConnectionsPanel from '../components/settings/ConnectionsPanel.vue'
import QuartoSettingsPanel from '../components/settings/QuartoSettingsPanel.vue'
import EnvEditor from '../components/env/EnvEditor.vue'
import { buildGitPanelModel, applyGitPanelModel } from '../utils/gitHelpers'
import { hydrateStructureFromProjectSettings, serializeStructureForSave } from '../utils/structureMapping'
import {
  normalizeProjectPackages,
  mapProjectPackagesToPayload
} from '../utils/packageHelpers'
import {
  mapConnectionsToArrays,
  mapConnectionsToPayload
} from '../utils/connectionHelpers'
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
  KeyIcon,
  ArrowDownTrayIcon,
  ArrowUpTrayIcon,
  ChartBarIcon
} from '@heroicons/vue/24/outline'

const route = useRoute()
const router = useRouter()
const toast = useToast()
const project = ref(null)
const loading = ref(true)
const error = ref(null)
const activeSection = ref('overview')
const VALID_SECTIONS = ['overview', 'basics', 'settings', 'quarto', 'notebooks', 'connections', 'data', 'inputs', 'outputs', 'results', 'packages', 'ai', 'git', 'scaffold', 'env']

const dataCatalog = ref(null)
const dataSearch = ref('')
const expandedDataKeys = ref(new Set())
const isEditingDataEntry = ref(false)
const editingDataEntry = ref(null)
const savingDataEntry = ref(false)
const dataEditError = ref(null)
const isCreatingDataEntry = ref(false)
const pendingDataUpdates = ref(false)
const pendingAddedKeys = ref(new Set())
const pendingAddedList = computed(() => Array.from(pendingAddedKeys.value))
const inputFiles = ref([])
const loadingInputFiles = ref(false)
const inputFilesError = ref(null)
const dataEntriesToDelete = ref(new Set())

// Inputs state
const inputsTab = ref('raw')
const inputTabs = [
  { id: 'raw', label: 'Raw' },
  { id: 'intermediate', label: 'Intermediate' },
  { id: 'final', label: 'Final' },
  { id: 'reference', label: 'Reference' }
]
const inputsRaw = ref([])
const inputsIntermediate = ref([])
const inputsFinal = ref([])
const inputsReference = ref([])
const loadingInputs = ref(false)

// Outputs state
const outputsTab = ref('tables')
const outputTabs = [
  { id: 'tables', label: 'Tables' },
  { id: 'figures', label: 'Figures' },
  { id: 'models', label: 'Models' },
  { id: 'reports', label: 'Reports' },
  { id: 'notebooks_output', label: 'Notebooks' }
]
const outputsTables = ref([])
const outputsFigures = ref([])
const outputsModels = ref([])
const outputsReports = ref([])
const outputsNotebooks = ref([])
const loadingOutputs = ref(false)

// Results state
const projectResults = ref([])
const loadingResults = ref(false)

const projectSettings = ref(null)
const settingsCatalog = ref(null)
const editableSettings = ref({})
const settingsLoading = ref(false)
const settingsError = ref(null)
const newExtraIds = ref(new Set())
const saving = ref(false)
const regeneratingQuarto = ref(false)
const savingQuartoDefaults = ref(false)
const quartoFiles = ref([])
const originalQuartoContents = ref({}) // Track original file contents for diff
const originalQuartoDefaults = ref(null) // Track original defaults for diff
const selectedQuartoFileKey = ref(null)
const loadingQuartoFiles = ref(false)
const savingQuartoFiles = ref(false)
const projectQuartoDefaults = ref({
  html: {
    format: 'html',
    embed_resources: true,
    theme: 'default',
    toc: true,
    toc_depth: 3,
    code_fold: false,
    code_tools: false,
    highlight_style: 'github'
  },
  revealjs: {
    format: 'revealjs',
    theme: 'default',
    incremental: false,
    slide_number: true,
    transition: 'slide',
    background_transition: 'fade',
    controls: true,
    progress: true,
    center: true,
    highlight_style: 'github'
  }
})
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

// Auto-manage default connections when only one exists or default is removed
watch(databaseConnections, (connections) => {
  const current = defaultDatabase.value
  const exists = connections.some(c => c.name === current)
  if (connections.length === 1) {
    const first = connections[0]
    if (first?.name && first.name !== 'framework_db') {
      defaultDatabase.value = first.name
    }
  } else if (current && !exists) {
    defaultDatabase.value = null
  }
}, { deep: true })

watch(s3Connections, (connections) => {
  const current = defaultStorageBucket.value
  const exists = connections.some(c => c.name === current)
  if (connections.length === 1) {
    const first = connections[0]
    if (first?.name) {
      defaultStorageBucket.value = first.name
    }
  } else if (current && !exists) {
    defaultStorageBucket.value = null
  }
}, { deep: true })

// Overview data for OverviewSummary component
const overviewCards = computed(() => {
  const name = basicsOverview.value.name
  const path = basicsOverview.value.path
  const author = basicsOverview.value.author
  const projectType = projectStructureLabel.value
  const notebookFormat = notebookFormatLabel.value
  const aiEnabled = aiSettings.value.enabled
  const aiProvider = aiSettings.value.enabled ? (Array.isArray(aiSettings.value.assistants) ? aiSettings.value.assistants.map(formatAssistantLabel).join(', ') : 'Enabled') : ''
  const aiCanonical = aiSettings.value.canonical_file || 'CLAUDE.md'
  const gitInit = gitSettings.value.initialize
  const gitHooks = enabledGitHooks.value
  const pkgCount = packagesCount.value
  const renvEnabled = editablePackages.value?.use_renv || false
  const envCount = envVariableCount.value

  return [
    {
      id: 'basics',
      title: 'Basics',
      section: 'basics',
      content: `<div>${name} · ${author}</div><div class="text-sm text-gray-600 dark:text-gray-400 mt-1">${path}</div>`
    },
    {
      id: 'structure',
      title: 'Project Structure',
      section: 'settings',
      content: `${projectTypeLabel.value} · ${Object.keys(workspaceDirectories.value).length} workspace · ${Object.keys(inputDirectories.value).length} input · ${Object.keys(outputDirectories.value).length} output`
    },
    {
      id: 'notebooks',
      title: 'Notebooks & Scripts',
      section: 'scaffold',
      content: notebookFormat
    },
    {
      id: 'packages',
      title: 'Packages',
      section: 'packages',
      content: pkgCount > 0
        ? `${pkgCount} packages · renv ${renvEnabled ? 'enabled' : 'disabled'}`
        : `renv: ${renvEnabled ? 'enabled' : 'disabled'}`
    },
    {
      id: 'env',
      title: '.env',
      section: 'env',
      content: envCount > 0 ? `${envCount} variable${envCount === 1 ? '' : 's'}` : 'No variables defined'
    },
    {
      id: 'ai',
      title: 'AI Assistants',
      section: 'ai',
      content: aiEnabled
        ? `${aiProvider} · ${aiCanonical}`
        : 'Disabled'
    },
    {
      id: 'git',
      title: 'Git & Hooks',
      section: 'git',
      content: gitInit
        ? `Auto-initialize repositories${gitHooks.length ? ` · ${gitHooks.join(', ')}` : ''}`
        : 'Manual initialization'
    }
  ]
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

  // Load settings when Settings, Basics, Scaffold, or Connections section is activated
  if ((newSection === 'settings' || newSection === 'basics' || newSection === 'scaffold' || newSection === 'connections') && !projectSettings.value) {
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

  // Load inputs when Inputs section is activated
  if (newSection === 'inputs' && inputsRaw.value.length === 0) {
    loadInputFiles()
  }

  // Load outputs when Outputs section is activated
  if (newSection === 'outputs' && outputsTables.value.length === 0) {
    loadOutputFiles()
  }

  // Load results when Results section is activated
  if (newSection === 'results' && projectResults.value.length === 0) {
    loadResults()
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
const hasPendingDataAdds = computed(() => pendingAddedKeys.value.size > 0)
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

  // Note: cache is excluded - it's always lazy-created and not user-configurable
  Object.keys(dirs).forEach(key => {
    if ((key.startsWith('outputs_') || key.includes('_figures') || key.includes('_tables') || key.includes('_models') || key.includes('_reports') || key === 'scratch') && !key.startsWith('inputs_') && key !== 'cache') {
      outputs[key] = dirs[key]
    }
  })

  return outputs
})

// Existing custom directories by type
const existingCustomInputDirectories = computed(() => {
  const extraDirs = editableSettings.value.extra_directories || []
  return extraDirs.filter(dir => dir.type === 'input')
})

const existingCustomOutputDirectories = computed(() => {
  const extraDirs = editableSettings.value.extra_directories || []
  return extraDirs.filter(dir => dir.type === 'output')
})

const existingCustomWorkspaceDirectories = computed(() => {
  const extraDirs = editableSettings.value.extra_directories || []
  return extraDirs.filter(dir => dir.type === 'workspace')
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

// Create enabled map from existing directories (for read-only display)
const directoriesEnabledForDisplay = computed(() => {
  if (!projectSettings.value?.directories) return {}

  const enabled = {}
  const savedDirectories = projectSettings.value.directories || {}

  // Check catalog for all possible directories
  const catalogDirs = settingsCatalog.value?.project_types?.[project.value.type]?.directories || {}

  Object.keys(catalogDirs).forEach(key => {
    // If directory exists in saved config, it's enabled
    // If it doesn't exist, it was disabled
    enabled[key] = key in savedDirectories
  })

  // Also mark extra directories as enabled
  if (projectSettings.value.extra_directories) {
    projectSettings.value.extra_directories.forEach(dir => {
      enabled[dir.key] = true
    })
  }

  return enabled
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

const dataCatalogPaths = computed(() => {
  const paths = new Set()
  const walk = (node) => {
    if (!node || typeof node !== 'object' || Array.isArray(node)) return
    Object.values(node).forEach((value) => {
      if (value && typeof value === 'object' && !Array.isArray(value)) {
        if (typeof value.path === 'string') {
          const norm = value.path.replace(/\\/g, '/').replace(/^\.\/+/, '').replace(/^\/+/, '')
          paths.add(norm.toLowerCase())
        }
        walk(value)
      }
    })
  }
  walk(dataCatalog.value)
  return Array.from(paths)
})

const normalizedCatalogPaths = computed(() => {
  const set = new Set()
  dataCatalogPaths.value.forEach((p) => set.add(p.toLowerCase()))
  return set
})

const untrackedInputFiles = computed(() =>
  inputFiles.value.filter((f) => {
    const norm = (f.path || '').replace(/\\/g, '/').replace(/^\.\/+/, '').replace(/^\/+/, '').toLowerCase()
    return norm && !normalizedCatalogPaths.value.has(norm)
  })
)

const fetchInputFiles = async () => {
  loadingInputFiles.value = true
  inputFilesError.value = null
  try {
    const res = await fetch(`/api/project/${route.params.id}/inputs`)
    const json = await res.json()
    if (!res.ok || json.error) {
      inputFilesError.value = json.error || 'Failed to load input files'
      inputFiles.value = []
      return
    }
    inputFiles.value = Array.isArray(json.files) ? json.files : []
  } catch (err) {
    inputFilesError.value = err?.message || 'Failed to load input files'
    inputFiles.value = []
  } finally {
    loadingInputFiles.value = false
  }
}

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

const deriveKeyFromPath = (path) => {
  if (!path) return ''
  let normalized = path.trim()
  normalized = normalized.replace(/\\/g, '/')
  normalized = normalized.replace(/^\.\/+/, '')
  normalized = normalized.replace(/^\/+/, '')
  normalized = normalized.replace(/\/+$/, '')
  normalized = normalized.replace(/\.[^./]+$/, '')
  normalized = normalized.replace(/\/+/g, '.')
  normalized = normalized.replace(/[^A-Za-z0-9._-]/g, '_')
  normalized = normalized.replace(/\.{2,}/g, '.')
  normalized = normalized.replace(/^\.|\.$/g, '')
  return normalized
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

const openDataCreatorWithPath = (file) => {
  const path = file?.path || ''
  const type = file?.type || ''
  isCreatingDataEntry.value = true
  editingDataEntry.value = {
    fullKey: deriveKeyFromPath(path),
    data: {
      path,
      type
    }
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
  pendingDataUpdates.value = true
  if (isNew) {
    const updatedAdds = new Set(pendingAddedKeys.value)
    updatedAdds.add(fullKey)
    pendingAddedKeys.value = updatedAdds
  }
  savingDataEntry.value = true
  dataEditError.value = null

  try {
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

  // Refresh available inputs list
  fetchInputFiles()
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

const toggleDataDelete = (node) => {
  if (!node || !node.fullKey) return

  // If this entry was newly added and not yet saved, removing it should cancel the addition
  if (pendingAddedKeys.value.has(node.fullKey)) {
    const updatedAdds = new Set(pendingAddedKeys.value)
    updatedAdds.delete(node.fullKey)
    pendingAddedKeys.value = updatedAdds
    const updatedCatalog = removeDataCatalogEntry(dataCatalog.value, node.fullKey)
    if (updatedCatalog) {
      dataCatalog.value = updatedCatalog
    }
    return
  }

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

const saveDataCatalogChanges = async () => {
  // Apply staged deletions to the current catalog before persisting
  let nextCatalog = cloneDeep(dataCatalog.value)
  if (hasPendingDataDeletes.value) {
    for (const key of dataEntriesToDelete.value) {
      const updated = removeDataCatalogEntry(nextCatalog, key)
      if (!updated) {
        toast.error('Delete Failed', `Unable to locate ${key} in catalog`)
        return
      }
      nextCatalog = updated
    }
  }

  try {
    await persistDataCatalog(nextCatalog)
    dataCatalog.value = nextCatalog
    dataEntriesToDelete.value = new Set()
    pendingAddedKeys.value = new Set()
    pendingDataUpdates.value = false
    fetchInputFiles()
  } catch (err) {
    toast.error('Save Failed', err.message || 'Failed to save data catalog')
  }
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
      const incoming = data.data || data
      dataCatalog.value = (!incoming || Array.isArray(incoming)) ? {} : incoming
    }
  } catch (err) {
    console.error('Failed to load data catalog:', err)
  }
}

const hasAnyConnections = (connectionsConfig = {}) => {
  const dbs = connectionsConfig.databases || {}
  const buckets = connectionsConfig.storage_buckets || {}
  return Boolean(
    Object.keys(dbs).length ||
    Object.keys(buckets).length ||
    connectionsConfig.default_database ||
    connectionsConfig.default_storage_bucket
  )
}

const hydrateConnectionsFromConfig = (connectionsConfig = {}) => {
  const mapped = mapConnectionsToArrays(connectionsConfig || {})
  databaseConnections.value = mapped.databaseConnections
  s3Connections.value = mapped.s3Connections
  defaultDatabase.value = mapped.defaultDatabase
  defaultStorageBucket.value = mapped.defaultStorageBucket
}

const loadProjectSettings = async () => {
  settingsLoading.value = true
  settingsError.value = null

  try {
    const [settingsResponse, catalogResponse] = await Promise.all([
      fetch(`/api/project/${route.params.id}/settings`),
      fetch('/api/settings/catalog')
    ])

    const data = await settingsResponse.json()
    const catalogData = await catalogResponse.json()

    settingsCatalog.value = catalogData

    if (data.error) {
      settingsError.value = data.error
    } else {
      console.log('[DEBUG] Loaded project settings:', data.settings)
      console.log('[DEBUG] extra_directories:', data.settings.extra_directories)
      projectSettings.value = data.settings
      const hydrated = hydrateStructureFromProjectSettings(
        data.settings,
        settingsCatalog.value?.project_types?.[data.settings?.type || project.value.type]?.directories || {}
      )
      editableSettings.value = {
        ...JSON.parse(JSON.stringify(data.settings)),
        directories: hydrated.directories,
        render_dirs: hydrated.render_dirs,
        extra_directories: hydrated.extra_directories,
        enabled: hydrated.enabled
      }
      // Load Quarto defaults for editing
      loadQuartoDefaults(editableSettings.value.quarto)

      // Ensure scaffold object exists with defaults
      if (!editableSettings.value.scaffold) {
        editableSettings.value.scaffold = {
          notebook_format: 'quarto',
          positron: false
        }
      }

      // Hydrate connections from project settings (fallback when /connections endpoint is unavailable)
      if (data.settings?.connections) {
        hydrateConnectionsFromConfig(data.settings.connections)
      }

      // Load Quarto defaults from project settings if present
      if (data.settings?.quarto) {
        loadQuartoDefaults(data.settings.quarto)
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
    case 'quarto':
      await saveQuartoSection()
      break
    case 'env':
      await saveEnv()
      break
    case 'data':
      if (hasPendingDataDeletes.value || pendingDataUpdates.value || hasPendingDataAdds.value) {
        await saveDataCatalogChanges()
      }
      break
    case 'overview':
    case 'notebooks':
      toast.info('No Changes to Save', 'This section has no editable settings')
      break
    default:
      toast.info('No Changes to Save', 'This section has no editable settings')
  }
}

const saveSettings = async () => {
  console.log('[DEBUG] saveSettings called! Stack trace:', new Error().stack)
  saving.value = true

  try {
    // First, create any new directories that were added
    const newDirectories = (editableSettings.value.extra_directories || [])
      .filter(dir => newExtraIds.value.has(dir._id))

    if (newDirectories.length > 0) {
      const dirResponse = await fetch(`/api/project/${route.params.id}/directories`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ directories: newDirectories })
      })

      const dirResult = await dirResponse.json()

      if (!dirResult.success) {
        toast.error('Directory Creation Failed', dirResult.error || 'Failed to create directories')
        saving.value = false
        return
      }

      // Clear the newExtraIds Set after successful save
      newExtraIds.value = new Set()
    }

    const catalogDirs = settingsCatalog.value?.project_types?.[project.value.type]?.directories || {}
    const serialized = serializeStructureForSave({
      catalogDirs,
      directories: editableSettings.value.directories || {},
      render_dirs: editableSettings.value.render_dirs || {},
      enabled: editableSettings.value.enabled || {},
      extra_directories: editableSettings.value.extra_directories || []
    })

    // Create clean settings object for sending
    const settingsToSave = {
      ...editableSettings.value,
      directories: serialized.directories,
      render_dirs: serialized.render_dirs,
      enabled: serialized.enabled,
      extra_directories: serialized.extra_directories,
      quarto: projectQuartoDefaults.value
    }

    console.log('[DEBUG] Saving settings with extra_directories:', settingsToSave.extra_directories)

    const response = await fetch(`/api/project/${route.params.id}/settings`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(settingsToSave)
    })

    const result = await response.json()

    if (result.success) {
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
  // Prefer cached project settings when available
  if (projectSettings.value?.connections) {
    hydrateConnectionsFromConfig(projectSettings.value.connections)
  }

  try {
    const response = await fetch(`/api/project/${route.params.id}/connections`)
    const data = await response.json()

    if (data.error) {
      console.error('Failed to load connections:', data.error)
    } else if (hasAnyConnections(data)) {
      hydrateConnectionsFromConfig(data)
      if (projectSettings.value) {
        projectSettings.value.connections = data
      }
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
      const mapped = normalizeProjectPackages(data)
      packages.value = JSON.parse(JSON.stringify(mapped.default_packages || []))
      editablePackages.value = mapped
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
      body: JSON.stringify(mapProjectPackagesToPayload(editablePackages.value))
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
    const payload = mapConnectionsToPayload({
      databaseConnections: databaseConnections.value,
      s3Connections: s3Connections.value,
      defaultDatabase: defaultDatabase.value,
      defaultStorageBucket: defaultStorageBucket.value
    })

    const response = await fetch(`/api/project/${route.params.id}/connections`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })

    const result = await response.json()

    if (result.success) {
      toast.success('Connections Saved', 'Connection configuration has been updated')
      if (projectSettings.value) {
        projectSettings.value.connections = payload
      }
    } else {
      toast.error('Save Failed', result.error || 'Failed to save connections')
    }
  } catch (err) {
    toast.error('Save Failed', err.message)
  } finally {
    savingConnections.value = false
  }
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

    // Full page reload to refresh sidebar menu - redirect to home
    setTimeout(() => {
      window.location.href = '/'
    }, 500) // Small delay to show toast
  } catch (error) {
    console.error('[DELETE] Failed to delete project:', error)
    toast.error('Delete Failed', error.message || 'Could not delete project')
  }
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
    return buildGitPanelModel({
      useGit: gitSettings.value.initialize,
      gitHooks: gitSettings.value.hooks,
      git: gitSettings.value
    })
  },
  set(val) {
    const next = {
      ...gitSettings.value,
      hooks: { ...(gitSettings.value.hooks || {}) }
    }
    applyGitPanelModel(
      {
        gitTarget: next,
        gitHooksTarget: next.hooks,
        setUseGit: (useGit) => { next.initialize = useGit }
      },
      val
    )
    gitSettings.value = next
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

// Load input files
const loadInputFiles = async () => {
  loadingInputs.value = true

  try {
    const projectId = route.params.id
    const [rawRes, intRes, finalRes, refRes] = await Promise.all([
      fetch(`/api/project/${projectId}/files/inputs_raw`),
      fetch(`/api/project/${projectId}/files/inputs_intermediate`),
      fetch(`/api/project/${projectId}/files/inputs_final`),
      fetch(`/api/project/${projectId}/files/inputs_reference`)
    ])

    const [rawData, intData, finalData, refData] = await Promise.all([
      rawRes.json(),
      intRes.json(),
      finalRes.json(),
      refRes.json()
    ])

    inputsRaw.value = rawData.files || []
    inputsIntermediate.value = intData.files || []
    inputsFinal.value = finalData.files || []
    inputsReference.value = refData.files || []
  } catch (err) {
    console.error('Failed to load input files:', err)
  } finally {
    loadingInputs.value = false
  }
}

// Load output files
const loadOutputFiles = async () => {
  loadingOutputs.value = true

  try {
    const projectId = route.params.id
    const [tablesRes, figuresRes, modelsRes, reportsRes, notebooksRes] = await Promise.all([
      fetch(`/api/project/${projectId}/files/outputs_tables`),
      fetch(`/api/project/${projectId}/files/outputs_figures`),
      fetch(`/api/project/${projectId}/files/outputs_models`),
      fetch(`/api/project/${projectId}/files/outputs_reports`),
      fetch(`/api/project/${projectId}/files/outputs_notebooks`)
    ])

    const [tablesData, figuresData, modelsData, reportsData, notebooksData] = await Promise.all([
      tablesRes.json(),
      figuresRes.json(),
      modelsRes.json(),
      reportsRes.json(),
      notebooksRes.json()
    ])

    outputsTables.value = tablesData.files || []
    outputsFigures.value = figuresData.files || []
    outputsModels.value = modelsData.files || []
    outputsReports.value = reportsData.files || []
    outputsNotebooks.value = notebooksData.files || []
  } catch (err) {
    console.error('Failed to load output files:', err)
  } finally {
    loadingOutputs.value = false
  }
}

// Load results from database
const loadResults = async () => {
  loadingResults.value = true

  try {
    const response = await fetch(`/api/project/${route.params.id}/results`)
    const data = await response.json()
    projectResults.value = data.results || []
  } catch (err) {
    console.error('Failed to load results:', err)
    projectResults.value = []
  } finally {
    loadingResults.value = false
  }
}

const selectedQuartoFile = computed(() => {
  const files = quartoFiles.value || []
  if (!files.length) return null
  return files.find((f) => f.key === selectedQuartoFileKey.value) || files[0]
})

const selectedQuartoFileContent = computed({
  get: () => selectedQuartoFile.value?.contents || '',
  set: (val) => {
    const file = selectedQuartoFile.value
    if (file) file.contents = val
  }
})

const loadQuartoDefaults = (settingsPayload) => {
  const defaults = settingsPayload?.quarto
  if (!defaults) return
  projectQuartoDefaults.value = {
    html: {
      format: 'html',
      embed_resources: defaults.html?.embed_resources ?? true,
      theme: defaults.html?.theme ?? 'default',
      toc: defaults.html?.toc ?? true,
      toc_depth: defaults.html?.toc_depth ?? 3,
      code_fold: defaults.html?.code_fold ?? false,
      code_tools: defaults.html?.code_tools ?? false,
      highlight_style: defaults.html?.highlight_style ?? 'github'
    },
    revealjs: {
      format: 'revealjs',
      theme: defaults.revealjs?.theme ?? 'default',
      incremental: defaults.revealjs?.incremental ?? false,
      slide_number: defaults.revealjs?.slide_number ?? true,
      transition: defaults.revealjs?.transition ?? 'slide',
      background_transition: defaults.revealjs?.background_transition ?? 'fade',
      controls: defaults.revealjs?.controls ?? true,
      progress: defaults.revealjs?.progress ?? true,
      center: defaults.revealjs?.center ?? true,
      highlight_style: defaults.revealjs?.highlight_style ?? 'github'
    }
  }
  // Store original for diff-before-save
  originalQuartoDefaults.value = JSON.parse(JSON.stringify(projectQuartoDefaults.value))
}

const loadQuartoFiles = async () => {
  loadingQuartoFiles.value = true
  try {
    const response = await fetch(`/api/project/${route.params.id}/quarto/files`)
    const data = await response.json()
    if (data.error) {
      throw new Error(data.error)
    }
    quartoFiles.value = data.files || []
    // Store original contents for diff-before-save
    originalQuartoContents.value = {}
    for (const file of quartoFiles.value) {
      originalQuartoContents.value[file.key] = file.contents || ''
    }
    if (quartoFiles.value.length > 0 && !selectedQuartoFileKey.value) {
      selectedQuartoFileKey.value = quartoFiles.value[0].key
    }
  } catch (err) {
    toast.error('Failed to load Quarto configs', err.message)
  } finally {
    loadingQuartoFiles.value = false
  }
}

const saveSelectedQuartoFile = async () => {
  const file = selectedQuartoFile.value
  if (!file) return

  savingQuartoFiles.value = true
  try {
    const response = await fetch(`/api/project/${route.params.id}/quarto/files`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ files: [file] })
    })
    const result = await response.json()
    if (result.success) {
      toast.success('Quarto File Saved', 'Quarto configuration saved to project')
    } else {
      toast.error('Save Failed', result.error || 'Failed to save Quarto configuration')
    }
  } catch (err) {
    toast.error('Save Failed', err.message)
  } finally {
    savingQuartoFiles.value = false
  }
}

const saveQuartoDefaults = async () => {
  savingQuartoDefaults.value = true
  try {
    // Reuse settings save to persist quarto defaults
    await saveSettings()
    toast.success('Quarto Defaults Saved', 'Defaults saved to project settings')
  } catch (err) {
    toast.error('Save Failed', err.message)
  } finally {
    savingQuartoDefaults.value = false
  }
}

// Save all Quarto settings (files and defaults) with diff-before-save
const saveQuartoSection = async () => {
  let savedFiles = false
  let savedDefaults = false
  let hasChanges = false

  // Check and save changed Quarto files
  const changedFiles = quartoFiles.value.filter((file) => {
    const original = originalQuartoContents.value[file.key] || ''
    return file.contents !== original
  })

  if (changedFiles.length > 0) {
    hasChanges = true
    savingQuartoFiles.value = true
    try {
      const response = await fetch(`/api/project/${route.params.id}/quarto/files`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ files: changedFiles })
      })
      const result = await response.json()
      if (result.success) {
        savedFiles = true
        // Update originals after successful save
        for (const file of changedFiles) {
          originalQuartoContents.value[file.key] = file.contents
        }
      } else {
        toast.error('Save Failed', result.error || 'Failed to save Quarto files')
        savingQuartoFiles.value = false
        return
      }
    } catch (err) {
      toast.error('Save Failed', err.message)
      savingQuartoFiles.value = false
      return
    }
    savingQuartoFiles.value = false
  }

  // Check and save changed Quarto defaults
  const defaultsChanged =
    originalQuartoDefaults.value &&
    JSON.stringify(projectQuartoDefaults.value) !== JSON.stringify(originalQuartoDefaults.value)

  if (defaultsChanged) {
    hasChanges = true
    savingQuartoDefaults.value = true
    try {
      await saveSettings()
      savedDefaults = true
      // Update original after successful save
      originalQuartoDefaults.value = JSON.parse(JSON.stringify(projectQuartoDefaults.value))
    } catch (err) {
      toast.error('Save Failed', err.message)
      savingQuartoDefaults.value = false
      return
    }
    savingQuartoDefaults.value = false
  }

  // Show appropriate feedback
  if (!hasChanges) {
    toast.info('No Changes', 'No changes detected in Quarto settings')
  } else if (savedFiles && savedDefaults) {
    toast.success('Quarto Saved', 'Files and defaults saved successfully')
  } else if (savedFiles) {
    toast.success('Quarto Files Saved', `${changedFiles.length} file(s) saved`)
  } else if (savedDefaults) {
    toast.success('Quarto Defaults Saved', 'Defaults saved to project settings')
  }
}

const regenerateQuartoConfigs = async () => {
  regeneratingQuarto.value = true

  try {
    const response = await fetch(`/api/project/${route.params.id}/quarto/regenerate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ backup: true })
    })

    const result = await response.json()

    if (result.success) {
      toast.success(
        'Quarto Configs Regenerated',
        result.message + (result.backup_location ? `\n\nBackup: ${result.backup_location}` : '')
      )
      await loadQuartoFiles()
    } else {
      toast.error('Regeneration Failed', result.error || 'Failed to regenerate Quarto configurations')
    }
  } catch (err) {
    toast.error('Regeneration Failed', err.message)
  } finally {
    regeneratingQuarto.value = false
  }
}

// Save all pending changes across all sections
const saveAll = async () => {
  const saves = []

  // Data catalog changes (adds/edits/deletes)
  if (hasPendingDataDeletes.value || pendingDataUpdates.value || hasPendingDataAdds.value) {
    saves.push(saveDataCatalogChanges())
  }

  // Settings covers: settings, scaffold, directories
  if (editableSettings.value && Object.keys(editableSettings.value).length > 0) {
    saves.push(saveSettings())
  }

  // Connections
  if (databaseConnections.value?.length > 0 || s3Connections.value?.length > 0) {
    saves.push(saveConnections())
  }

  // Packages
  if (packages.value?.length > 0) {
    saves.push(savePackages())
  }

  // Git settings
  if (gitSettings.value) {
    saves.push(saveGitSettings())
  }

  // AI settings
  if (aiSettings.value) {
    saves.push(saveAISettings())
  }

  // Env
  if (envContents.value !== null) {
    saves.push(saveEnv())
  }

  // Quarto (has its own change detection)
  if (quartoFiles.value?.length > 0) {
    saves.push(saveQuartoSection())
  }

  if (saves.length > 0) {
    await Promise.all(saves)
    // Single consolidated toast
    toast.success('Saved', 'All pending changes have been saved')
  }
}

// Keyboard shortcuts
const handleKeydown = (e) => {
  // Cmd/Ctrl + S to save all pending changes
  if ((e.metaKey || e.ctrlKey) && e.key === 's') {
    e.preventDefault()
    saveAll()
  }
}

onMounted(() => {
  initializeSection()
  loadProject()
  fetchInputFiles()
  loadDataCatalog()
  loadProjectSettings()
  loadQuartoFiles()
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
    quartoFiles.value = []
    selectedQuartoFileKey.value = null

    // Reload project data
    initializeSection()
    loadProject()
    loadDataCatalog()
    loadProjectSettings()
    loadQuartoFiles()
    loadPackages()
    loadAISettings()
    loadGitSettings()
    loadEnv()
  }
})
</script>
