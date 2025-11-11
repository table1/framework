<template>
  <div class="flex min-h-screen">
    <!-- Sidebar -->
    <nav class="w-64 shrink-0 border-r border-gray-200 p-6 dark:border-gray-800">
      <h2 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">New Project Defaults</h2>

      <div class="space-y-1">
        <div v-for="section in sections" :key="section.id">
          <!-- Insert SETTINGS heading before Basics -->
          <NavigationSectionHeading v-if="section.id === 'basics'">Settings</NavigationSectionHeading>

          <a
            :href="buildSettingsHref(section.slug)"
            @click.prevent="navigateToSection(section.id)"
            :class="[
              'flex items-center gap-2 px-3 py-2 rounded-md text-sm transition',
              activeSection === section.id
                ? 'bg-sky-50 text-sky-700 font-medium dark:bg-sky-900/20 dark:text-sky-400'
                : 'text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-800'
            ]"
          >
            <component v-if="section.icon" :is="section.icon" class="h-4 w-4" />
            <svg v-else-if="section.svgIcon" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" :d="section.svgIcon" />
            </svg>
            {{ section.label }}
          </a>

          <div
            v-if="section.id === 'structure' && activeSection === 'structure'"
            class="ml-4 mt-2 space-y-0.5 border-l border-gray-200 pl-3 dark:border-gray-700"
          >
            <a
              v-for="item in projectStructureSubnav"
              :key="item.key"
              :href="buildSettingsHref('project-structure', item.slug)"
              @click.prevent="navigateToProjectType(item.key)"
              :class="[
                'block rounded-md py-1 pl-4 pr-2 text-xs font-medium transition',
                currentProjectTypeKey === item.key
                  ? 'bg-sky-100 text-sky-700 dark:bg-sky-900/30 dark:text-sky-300'
                  : 'text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-800'
              ]"
            >
              {{ item.label }}
            </a>
          </div>

          <div
            v-else-if="section.id === 'templates' && activeSection === 'templates'"
            class="ml-4 mt-2 space-y-0.5 border-l border-gray-200 pl-3 dark:border-gray-700"
          >
            <a
              v-for="item in templatesSubnav"
              :key="item.id"
              :href="`#${item.id}`"
              @click.prevent="scrollToSection(item.id)"
              class="block rounded-md py-1 pl-4 pr-2 text-xs font-medium text-gray-600 transition hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-800"
            >
              {{ item.label }}
            </a>
          </div>
        </div>
      </div>

      <!-- Save Button in Sidebar -->
      <div class="mt-6 px-3">
        <Button
          variant="primary"
          size="md"
          :disabled="saving"
          @click="saveSettings"
          class="w-full"
        >
          {{ saving ? 'Saving…' : 'Save Changes' }}
        </Button>
      </div>
    </nav>

    <!-- Main Content -->
    <div class="flex-1 p-10 pb-24">
      <PageHeader
        :title="pageHeaderTitle"
        :description="pageHeaderDescription"
      />

      <div class="mt-8 space-y-10">
        <!-- Overview -->
        <div id="overview" v-show="activeSection === 'overview'">
          <div class="space-y-3">
            <!-- Basics Card -->
            <OverviewCard
              title="Basics"
              @click="activeSection = 'basics'"
            >
              <template v-if="settings.projects_root || (settings.author && settings.author.name)">
                <span v-if="settings.projects_root" class="text-gray-600 dark:text-gray-400">{{ settings.projects_root }}</span>
                <template v-if="settings.projects_root && settings.author && settings.author.name">
                  <span class="text-gray-400 dark:text-gray-500 mx-1">·</span>
                </template>
                <span v-if="settings.author && settings.author.name">{{ settings.author.name }}</span>
              </template>
              <span v-else class="text-gray-600 dark:text-gray-400">Not set</span>
            </OverviewCard>

            <!-- Project Structure Card -->
            <OverviewCard
              title="Project Structure"
              @click="activeSection = 'structure'"
            >
              <span v-if="settings.defaults && settings.defaults.project_type">{{ settings.defaults.project_type }}</span>
              <span v-else class="text-gray-600 dark:text-gray-400">Not set</span>
            </OverviewCard>

            <!-- Notebooks & Scripts Card -->
            <OverviewCard
              title="Notebooks & Scripts"
              @click="activeSection = 'notebooksScripts'"
            >
              <span v-if="settings.defaults && settings.defaults.notebook_format">{{ settings.defaults.notebook_format }}</span>
              <span v-else class="text-gray-600 dark:text-gray-400">quarto</span>
            </OverviewCard>

            <!-- AI Assistants Card -->
            <OverviewCard
              title="AI Assistants"
              @click="activeSection = 'ai'"
            >
              <span v-if="settings.ai_config && settings.ai_config.enabled" class="text-green-600 dark:text-green-400">Enabled</span>
              <span v-else class="text-gray-600 dark:text-gray-400">Disabled</span>
            </OverviewCard>

            <!-- Git & Hooks Card -->
            <OverviewCard
              title="Git & Hooks"
              @click="activeSection = 'git'"
            >
              <span v-if="settings.git && settings.git.auto_init" class="text-green-600 dark:text-green-400">Auto-initialize repositories</span>
              <span v-else class="text-gray-600 dark:text-gray-400">Manual initialization</span>
            </OverviewCard>

            <!-- Packages Card -->
            <OverviewCard
              title="Packages"
              @click="activeSection = 'packages'"
            >
              <span v-if="settings.packages && settings.packages.length > 0">
                {{ settings.packages.length }} package{{ settings.packages.length !== 1 ? 's' : '' }}
              </span>
              <span v-else class="text-gray-600 dark:text-gray-400">No default packages</span>
            </OverviewCard>
          </div>
        </div>

        <!-- Basics -->
        <div id="basics" v-show="activeSection === 'basics'">
          <SettingsPanel
            description="Essential project defaults that apply to all new projects."
          >
            <SettingsBlock>
              <div class="space-y-5">
                <Input
                  v-model="settings.projects_root"
                  label="Default Projects Directory"
                  hint="New projects will be created in this directory by default"
                  placeholder="e.g., ~/projects or /Users/yourname/code"
                />

                <div>
                  <label class="block text-sm font-semibold text-gray-900 dark:text-white mb-3">
                    Supported Editors
                  </label>
                  <Checkbox
                    v-model="settings.defaults.positron"
                    id="support-positron-defaults"
                    description="Enable Positron-specific workspace and settings files"
                  >
                    Positron
                  </Checkbox>
                  <p class="text-sm text-gray-500 dark:text-gray-400 mt-3">
                    RStudio supported by default
                  </p>
                </div>

                <Select
                  v-model="settings.defaults.notebook_format"
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
                    Used as defaults when scaffold() creates README files and notebook headers, so every project starts with the right attribution.
                  </p>
                  <div class="space-y-5">
                    <Input v-model="settings.author.name" label="Your Name" placeholder="Your Name" />
                    <Input v-model="settings.author.email" type="email" label="Email" placeholder="your.email@example.com" />
                    <Input v-model="settings.author.affiliation" label="Affiliation" placeholder="Organization" />
                  </div>
                </div>
              </div>
            </SettingsBlock>
          </SettingsPanel>
        </div>

        <!-- Project Structure -->
        <div id="structure" v-show="activeSection === 'structure'" class="space-y-8">
          <!-- Index page when no project type is selected -->
          <div v-if="!currentProjectTypeKey" class="space-y-6">

            <div class="space-y-3">
              <button
                v-for="item in projectStructureSubnav"
                :key="item.key"
                @click="navigateToProjectType(item.key)"
                class="group relative w-full rounded-lg border border-gray-200 p-6 text-left transition hover:border-sky-300 dark:border-gray-700 dark:hover:border-sky-600"
              >
                <div class="flex items-start gap-3">
                  <FolderIcon class="h-6 w-6 flex-shrink-0 text-gray-400 transition group-hover:text-sky-600 dark:group-hover:text-sky-400" />
                  <div>
                    <h3 class="font-semibold text-gray-900 dark:text-white">
                      {{ item.label }}
                    </h3>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                      {{ settings.project_types[item.key]?.description || '' }}
                    </p>
                  </div>
                </div>
              </button>
            </div>
          </div>

          <!-- Existing project type editor when a type is selected -->
          <div v-else-if="currentProjectType" class="space-y-6">
            <div v-if="currentProjectTypeKey === 'project'" class="space-y-6">
              <!-- Project-specific settings (e.g., ggplot theme) -->
              <div v-if="currentProjectTypeSettings && currentProjectTypeSettings.length > 0">
                <SettingsPanel
                  title="Project Settings"
                  description="Default settings applied when creating new projects of this type."
                >
                  <SettingsBlock>
                    <div class="space-y-5">
                      <template v-for="setting in currentProjectTypeSettings" :key="setting.id">
                        <Toggle
                          v-if="setting.control === 'toggle'"
                          v-model="settings.project_types[currentProjectTypeKey][setting.id]"
                          :label="setting.label"
                          :description="setting.description"
                        />
                        <Select
                          v-else-if="setting.control === 'select'"
                          v-model="settings.project_types[currentProjectTypeKey][setting.id]"
                          :label="setting.label"
                          :hint="setting.hint"
                        >
                          <option v-for="opt in setting.options" :key="opt.value" :value="opt.value">
                            {{ opt.label }}
                          </option>
                        </Select>
                        <Input
                          v-else-if="setting.control === 'text'"
                          v-model="settings.project_types[currentProjectTypeKey][setting.id]"
                          :label="setting.label"
                          :hint="setting.hint"
                          :placeholder="setting.placeholder"
                        />
                      </template>
                    </div>
                  </SettingsBlock>
                </SettingsPanel>
              </div>

              <div class="flex flex-wrap items-center justify-between gap-3">
                <div class="flex flex-wrap gap-2 text-xs font-medium text-gray-600 dark:text-gray-400">
                  <button
                    type="button"
                    class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
                    @click="scrollToSection(`project-${currentProjectTypeKey}-inputs`)"
                  >
                  Inputs
                </button>
                <button
                  type="button"
                  class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
                  @click="scrollToSection(`project-${currentProjectTypeKey}-workspaces`)"
                >
                  Workspaces
                </button>
                <button
                  type="button"
                  class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
                  @click="scrollToSection(`project-${currentProjectTypeKey}-outputs`)"
                >
                  Outputs
                </button>
                <button
                  type="button"
                  class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
                  @click="scrollToSection(`project-${currentProjectTypeKey}-utility`)"
                  >
                    Utility
                  </button>
                <button
                  type="button"
                  class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
                  @click="scrollToSection(`project-${currentProjectTypeKey}-gitignore`)"
                  >
                    .gitignore
                  </button>
                </div>
                <Button variant="secondary" size="sm" class="mt-3 sm:mt-0" @click="showResetConfirm(currentProjectTypeKey)">
                  Reset to Defaults
                </Button>
              </div>

              <div :id="`project-${currentProjectTypeKey}-inputs`">
                <SettingsPanel
                  title="Inputs"
                  description="Define the read-only locations where raw and prepared data live."
                >
                  <template v-for="field in generalInputFields" :key="field.key">
                    <Input
                      v-if="hasDirectory(currentProjectTypeKey, field.key)"
                      v-model="settings.project_types[currentProjectTypeKey].directories[field.key]"
                      :label="field.label"
                      :hint="field.hint"
                      prefix="/"
                      monospace
                    />
                  </template>

                  <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                    <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Additional Input Directories</h4>
                    <Repeater
                      :model-value="extraDirectoriesByType(currentProjectTypeKey, 'input')"
                      @update:model-value="updateExtraDirectories(currentProjectTypeKey, 'input', $event)"
                      add-label="Add Input Directory"
                      :default-item="() => ({ key: '', label: '', path: '', type: 'input', _id: Date.now() })"
                    >
                      <template #default="{ item, index, update }">
                        <div class="grid grid-cols-2 gap-3">
                          <Input
                            :model-value="item.key"
                            @update:model-value="update('key', $event)"
                            label="Key"
                            placeholder="e.g., inputs_archive"
                            :error="validateExtraDirectoryKey(item.key, currentProjectTypeKey, 'input', index)"
                            monospace
                            size="sm"
                          />
                          <Input
                            :model-value="item.label"
                            @update:model-value="update('label', $event)"
                            label="Label"
                            placeholder="e.g., Archive"
                            size="sm"
                          />
                          <Input
                            :model-value="item.path"
                            @update:model-value="update('path', $event)"
                            label="Path"
                            placeholder="e.g., inputs/archive"
                            :error="validateExtraDirectoryPath(item.path)"
                            prefix="/"
                            monospace
                            size="sm"
                            class="col-span-2"
                          />
                        </div>
                      </template>
                    </Repeater>
                  </div>
                </SettingsPanel>
              </div>

              <div :id="`project-${currentProjectTypeKey}-workspaces`">
                <SettingsPanel
                  title="Workspaces"
                  description="Functions, notebooks, and scripts scaffolded into every project."
                >
                  <template v-for="field in generalWorkspaceFields" :key="field.key">
                    <Input
                      v-if="hasDirectory(currentProjectTypeKey, field.key)"
                      v-model="settings.project_types[currentProjectTypeKey].directories[field.key]"
                      :label="field.label"
                      :hint="field.hint"
                      prefix="/"
                      monospace
                    />
                  </template>

                  <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                    <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Additional Workspace Directories</h4>
                    <Repeater
                      :model-value="extraDirectoriesByType(currentProjectTypeKey, 'workspace')"
                      @update:model-value="updateExtraDirectories(currentProjectTypeKey, 'workspace', $event)"
                      add-label="Add Workspace Directory"
                      :default-item="() => ({ key: '', label: '', path: '', type: 'workspace', _id: Date.now() })"
                    >
                      <template #default="{ item, index, update }">
                        <div class="grid grid-cols-2 gap-3">
                          <Input
                            :model-value="item.key"
                            @update:model-value="update('key', $event)"
                            label="Key"
                            placeholder="e.g., tests"
                            :error="validateExtraDirectoryKey(item.key, currentProjectTypeKey, 'workspace', index)"
                            monospace
                            size="sm"
                          />
                          <Input
                            :model-value="item.label"
                            @update:model-value="update('label', $event)"
                            label="Label"
                            placeholder="e.g., Tests"
                            size="sm"
                          />
                          <Input
                            :model-value="item.path"
                            @update:model-value="update('path', $event)"
                            label="Path"
                            placeholder="e.g., tests"
                            :error="validateExtraDirectoryPath(item.path)"
                            prefix="/"
                            monospace
                            size="sm"
                            class="col-span-2"
                          />
                        </div>
                      </template>
                    </Repeater>
                  </div>
                </SettingsPanel>
              </div>

              <div :id="`project-${currentProjectTypeKey}-outputs`">
                <SettingsPanel
                  title="Outputs"
                  description="Outputs are public by default so results are easy to share."
                >
                  <template v-for="field in generalOutputFields" :key="field.key">
                    <Input
                      v-if="hasDirectory(currentProjectTypeKey, field.key)"
                      v-model="settings.project_types[currentProjectTypeKey].directories[field.key]"
                      :label="field.label"
                      :hint="field.hint"
                      prefix="/"
                      monospace
                    />
                  </template>
                  <Input
                    v-model="settings.project_types[currentProjectTypeKey].quarto.render_dir"
                    label="Notebook output directory"
                    hint="Rendered notebooks and reports are written here by default."
                    prefix="/"
                    monospace
                  />

                  <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                    <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Additional Output Directories</h4>
                    <Repeater
                      :model-value="extraDirectoriesByType(currentProjectTypeKey, 'output')"
                      @update:model-value="updateExtraDirectories(currentProjectTypeKey, 'output', $event)"
                      add-label="Add Output Directory"
                      :default-item="() => ({ key: '', label: '', path: '', type: 'output', _id: Date.now() })"
                    >
                      <template #default="{ item, index, update }">
                        <div class="grid grid-cols-2 gap-3">
                          <Input
                            :model-value="item.key"
                            @update:model-value="update('key', $event)"
                            label="Key"
                            placeholder="e.g., outputs_animations"
                            :error="validateExtraDirectoryKey(item.key, currentProjectTypeKey, 'output', index)"
                            monospace
                            size="sm"
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
                            :error="validateExtraDirectoryPath(item.path)"
                            prefix="/"
                            monospace
                            size="sm"
                            class="col-span-2"
                          />
                        </div>
                      </template>
                    </Repeater>
                  </div>
                </SettingsPanel>
              </div>

              <div :id="`project-${currentProjectTypeKey}-utility`">
                <SettingsPanel
                  title="Utility directories"
                  description="Cache and scratch folders are gitignored so temporary artifacts never leak into version control."
                >
                  <template v-for="field in generalUtilityFields" :key="field.key">
                    <Input
                      v-if="hasDirectory(currentProjectTypeKey, field.key)"
                      v-model="settings.project_types[currentProjectTypeKey].directories[field.key]"
                      :label="field.label"
                      :hint="field.hint"
                      prefix="/"
                      monospace
                    />
                  </template>
                </SettingsPanel>
              </div>

            </div>

            <div v-else-if="currentProjectTypeKey === 'project_sensitive'" class="space-y-6">
              <!-- Project-specific settings (e.g., ggplot theme) -->
              <div v-if="currentProjectTypeSettings && currentProjectTypeSettings.length > 0">
                <SettingsPanel
                  title="Project Settings"
                  description="Default settings applied when creating new projects of this type."
                >
                  <SettingsBlock>
                    <div class="space-y-5">
                      <template v-for="setting in currentProjectTypeSettings" :key="setting.id">
                        <Toggle
                          v-if="setting.control === 'toggle'"
                          v-model="settings.project_types[currentProjectTypeKey][setting.id]"
                          :label="setting.label"
                          :description="setting.description"
                        />
                        <Select
                          v-else-if="setting.control === 'select'"
                          v-model="settings.project_types[currentProjectTypeKey][setting.id]"
                          :label="setting.label"
                          :hint="setting.hint"
                        >
                          <option v-for="opt in setting.options" :key="opt.value" :value="opt.value">
                            {{ opt.label }}
                          </option>
                        </Select>
                        <Input
                          v-else-if="setting.control === 'text'"
                          v-model="settings.project_types[currentProjectTypeKey][setting.id]"
                          :label="setting.label"
                          :hint="setting.hint"
                          :placeholder="setting.placeholder"
                        />
                      </template>
                    </div>
                  </SettingsBlock>
                </SettingsPanel>
              </div>

              <div class="flex flex-wrap items-center justify-between gap-3">
                <div class="flex flex-wrap gap-2 text-xs font-medium text-gray-600 dark:text-gray-400">
                  <button
                    type="button"
                    class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
                    @click="scrollToSection(`project-${currentProjectTypeKey}-workspaces`)"
                  >
                    Workspaces
                  </button>
                <button
                  type="button"
                  class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
                  @click="scrollToSection(`project-${currentProjectTypeKey}-inputs-private`)"
                >
                  Inputs
                </button>
                <button
                  type="button"
                  class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
                  @click="scrollToSection(`project-${currentProjectTypeKey}-outputs-private`)"
                >
                  Outputs
                </button>
                <button
                  type="button"
                  class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
                  @click="scrollToSection(`project-${currentProjectTypeKey}-utility`)"
                  >
                    Utility
                  </button>
                </div>
                <Button variant="secondary" size="sm" class="mt-3 sm:mt-0" @click="showResetConfirm(currentProjectTypeKey)">
                  Reset to Defaults
                </Button>
              </div>

              <div :id="`project-${currentProjectTypeKey}-workspaces`">
                <SettingsPanel
                  title="Workspaces"
                  description="Module locations for notebooks, scripts, and helper functions."
                >
                  <div class="space-y-3">
                    <template v-for="field in generalWorkspaceFields" :key="`sensitive-${field.key}`">
                      <Input
                        v-if="hasDirectory(currentProjectTypeKey, field.key)"
                        v-model="settings.project_types[currentProjectTypeKey].directories[field.key]"
                        :label="field.label"
                        :hint="field.hint"
                        prefix="/"
                        monospace
                      />
                    </template>
                  </div>

                  <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                    <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Additional Workspace Directories</h4>
                    <Repeater
                      :model-value="extraDirectoriesByType(currentProjectTypeKey, 'workspace')"
                      @update:model-value="updateExtraDirectories(currentProjectTypeKey, 'workspace', $event)"
                      add-label="Add Workspace Directory"
                      :default-item="() => ({ key: '', label: '', path: '', type: 'workspace', _id: Date.now() })"
                    >
                      <template #default="{ item, index, update }">
                        <div class="grid grid-cols-2 gap-3">
                          <Input
                            :model-value="item.key"
                            @update:model-value="update('key', $event)"
                            label="Key"
                            placeholder="e.g., tests"
                            :error="validateExtraDirectoryKey(item.key, currentProjectTypeKey, 'workspace', index)"
                            monospace
                            size="sm"
                          />
                          <Input
                            :model-value="item.label"
                            @update:model-value="update('label', $event)"
                            label="Label"
                            placeholder="e.g., Tests"
                            size="sm"
                          />
                          <Input
                            :model-value="item.path"
                            @update:model-value="update('path', $event)"
                            label="Path"
                            placeholder="e.g., tests"
                            :error="validateExtraDirectoryPath(item.path)"
                            prefix="/"
                            monospace
                            size="sm"
                            class="col-span-2"
                          />
                        </div>
                      </template>
                    </Repeater>
                  </div>
                </SettingsPanel>
              </div>

              <div :id="`project-${currentProjectTypeKey}-inputs-private`">
                <SettingsPanel
                  title="Inputs"
                  description="Keep private inputs compartmentalized; publish processed outputs into public folders when ready."
                >
                  <div class="grid gap-4 sm:grid-cols-2 text-xs font-semibold uppercase text-gray-500 dark:text-gray-400">
                    <div>Private</div>
                    <div>Public</div>
                  </div>
                  <div v-for="pair in sensitiveInputPairs" :key="pair.privateKey" class="grid gap-4 sm:grid-cols-2">
                    <template v-if="hasDirectory(currentProjectTypeKey, pair.privateKey)">
                      <Input
                        v-model="settings.project_types[currentProjectTypeKey].directories[pair.privateKey]"
                        :label="pair.privateLabel || `${pair.label} (private)`"
                        prefix="/"
                        monospace
                      />
                    </template>
                    <template v-if="hasDirectory(currentProjectTypeKey, pair.publicKey)">
                      <Input
                        v-model="settings.project_types[currentProjectTypeKey].directories[pair.publicKey]"
                        :label="pair.publicLabel || `${pair.label} (public)`"
                        prefix="/"
                        monospace
                      />
                    </template>
                  </div>

                  <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                    <div class="grid gap-4 sm:grid-cols-2">
                      <div>
                        <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Additional Private Inputs</h4>
                        <Repeater
                          :model-value="extraDirectoriesByType(currentProjectTypeKey, 'input_private')"
                          @update:model-value="updateExtraDirectories(currentProjectTypeKey, 'input_private', $event)"
                          add-label="Add Private Input"
                          :default-item="() => ({ key: '', label: '', path: '', type: 'input_private', _id: Date.now() })"
                        >
                          <template #default="{ item, index, update }">
                            <div class="space-y-3">
                              <Input
                                :model-value="item.key"
                                @update:model-value="update('key', $event)"
                                label="Key"
                                placeholder="e.g., inputs_archive"
                                :error="validateExtraDirectoryKey(item.key, currentProjectTypeKey, 'input_private', index)"
                                monospace
                                size="sm"
                              />
                              <Input
                                :model-value="item.label"
                                @update:model-value="update('label', $event)"
                                label="Label"
                                placeholder="e.g., Archive"
                                size="sm"
                              />
                              <Input
                                :model-value="item.path"
                                @update:model-value="update('path', $event)"
                                label="Path"
                                placeholder="e.g., inputs/archive"
                                :error="validateExtraDirectoryPath(item.path)"
                                prefix="/"
                                monospace
                                size="sm"
                              />
                            </div>
                          </template>
                        </Repeater>
                      </div>

                      <div>
                        <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Additional Public Inputs</h4>
                        <Repeater
                          :model-value="extraDirectoriesByType(currentProjectTypeKey, 'input_public')"
                          @update:model-value="updateExtraDirectories(currentProjectTypeKey, 'input_public', $event)"
                          add-label="Add Public Input"
                          :default-item="() => ({ key: '', label: '', path: '', type: 'input_public', _id: Date.now() })"
                        >
                          <template #default="{ item, index, update }">
                            <div class="space-y-3">
                              <Input
                                :model-value="item.key"
                                @update:model-value="update('key', $event)"
                                label="Key"
                                placeholder="e.g., inputs_public_archive"
                                :error="validateExtraDirectoryKey(item.key, currentProjectTypeKey, 'input_public', index)"
                                monospace
                                size="sm"
                              />
                              <Input
                                :model-value="item.label"
                                @update:model-value="update('label', $event)"
                                label="Label"
                                placeholder="e.g., Archive (Public)"
                                size="sm"
                              />
                              <Input
                                :model-value="item.path"
                                @update:model-value="update('path', $event)"
                                label="Path"
                                placeholder="e.g., inputs_public/archive"
                                :error="validateExtraDirectoryPath(item.path)"
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
                </SettingsPanel>
              </div>

              <div :id="`project-${currentProjectTypeKey}-outputs-private`">
                <SettingsPanel
                  title="Outputs"
                  description="Review outputs before promotion; private folders remain gitignored while public copies are ready to share."
                >
                  <div class="grid gap-4 sm:grid-cols-2 text-xs font-semibold uppercase text-gray-500 dark:text-gray-400">
                    <div>Private</div>
                    <div>Public</div>
                  </div>
                  <div v-for="pair in sensitiveOutputPairs" :key="pair.privateKey" class="grid gap-4 sm:grid-cols-2">
                    <template v-if="hasDirectory(currentProjectTypeKey, pair.privateKey)">
                      <Input
                        v-model="settings.project_types[currentProjectTypeKey].directories[pair.privateKey]"
                        :label="pair.privateLabel || `${pair.label} (private)`"
                        prefix="/"
                        monospace
                      />
                    </template>
                    <template v-if="hasDirectory(currentProjectTypeKey, pair.publicKey)">
                      <Input
                        v-model="settings.project_types[currentProjectTypeKey].directories[pair.publicKey]"
                        :label="pair.publicLabel || `${pair.label} (public)`"
                        prefix="/"
                        monospace
                      />
                    </template>
                  </div>
                  <Input
                    v-model="settings.project_types[currentProjectTypeKey].quarto.render_dir"
                    label="Notebook output directory"
                    hint="Rendered docs default to a public location but can be moved if needed."
                    prefix="/"
                    monospace
                  />

                  <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                    <div class="grid gap-4 sm:grid-cols-2">
                      <div>
                        <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Additional Private Outputs</h4>
                        <Repeater
                          :model-value="extraDirectoriesByType(currentProjectTypeKey, 'output_private')"
                          @update:model-value="updateExtraDirectories(currentProjectTypeKey, 'output_private', $event)"
                          add-label="Add Private Output"
                          :default-item="() => ({ key: '', label: '', path: '', type: 'output_private', _id: Date.now() })"
                        >
                          <template #default="{ item, index, update }">
                            <div class="space-y-3">
                              <Input
                                :model-value="item.key"
                                @update:model-value="update('key', $event)"
                                label="Key"
                                placeholder="e.g., outputs_animations"
                                :error="validateExtraDirectoryKey(item.key, currentProjectTypeKey, 'output_private', index)"
                                monospace
                                size="sm"
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
                                :error="validateExtraDirectoryPath(item.path)"
                                prefix="/"
                                monospace
                                size="sm"
                              />
                            </div>
                          </template>
                        </Repeater>
                      </div>

                      <div>
                        <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Additional Public Outputs</h4>
                        <Repeater
                          :model-value="extraDirectoriesByType(currentProjectTypeKey, 'output_public')"
                          @update:model-value="updateExtraDirectories(currentProjectTypeKey, 'output_public', $event)"
                          add-label="Add Public Output"
                          :default-item="() => ({ key: '', label: '', path: '', type: 'output_public', _id: Date.now() })"
                        >
                          <template #default="{ item, index, update }">
                            <div class="space-y-3">
                              <Input
                                :model-value="item.key"
                                @update:model-value="update('key', $event)"
                                label="Key"
                                placeholder="e.g., outputs_public_animations"
                                :error="validateExtraDirectoryKey(item.key, currentProjectTypeKey, 'output_public', index)"
                                monospace
                                size="sm"
                              />
                              <Input
                                :model-value="item.label"
                                @update:model-value="update('label', $event)"
                                label="Label"
                                placeholder="e.g., Animations (Public)"
                                size="sm"
                              />
                              <Input
                                :model-value="item.path"
                                @update:model-value="update('path', $event)"
                                label="Path"
                                placeholder="e.g., outputs_public/animations"
                                :error="validateExtraDirectoryPath(item.path)"
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
                </SettingsPanel>
              </div>

              <div :id="`project-${currentProjectTypeKey}-utility`">
                <SettingsPanel
                  title="Utility directories"
                  description="Keep cache and scratch in private space for safety; both remain gitignored."
                >
                  <div class="space-y-3">
                    <template v-for="field in generalUtilityFields" :key="`sensitive-${field.key}`">
                      <Input
                        v-if="hasDirectory(currentProjectTypeKey, field.key)"
                        v-model="settings.project_types[currentProjectTypeKey].directories[field.key]"
                        :label="field.label"
                        :hint="field.hint"
                        prefix="/"
                        monospace
                      />
                    </template>
                  </div>
                </SettingsPanel>
              </div>

            </div>

            <div v-else-if="currentProjectTypeKey === 'presentation'" class="space-y-6">
              <!-- Project-specific settings (e.g., ggplot theme) -->
              <div v-if="currentProjectTypeSettings && currentProjectTypeSettings.length > 0">
                <SettingsPanel
                  title="Project Settings"
                  description="Default settings applied when creating new projects of this type."
                >
                  <SettingsBlock>
                    <div class="space-y-5">
                      <template v-for="setting in currentProjectTypeSettings" :key="setting.id">
                        <Toggle
                          v-if="setting.control === 'toggle'"
                          v-model="settings.project_types[currentProjectTypeKey][setting.id]"
                          :label="setting.label"
                          :description="setting.description"
                        />
                        <Select
                          v-else-if="setting.control === 'select'"
                          v-model="settings.project_types[currentProjectTypeKey][setting.id]"
                          :label="setting.label"
                          :hint="setting.hint"
                        >
                          <option v-for="opt in setting.options" :key="opt.value" :value="opt.value">
                            {{ opt.label }}
                          </option>
                        </Select>
                        <Input
                          v-else-if="setting.control === 'text'"
                          v-model="settings.project_types[currentProjectTypeKey][setting.id]"
                          :label="setting.label"
                          :hint="setting.hint"
                          :placeholder="setting.placeholder"
                        />
                      </template>
                    </div>
                  </SettingsBlock>
                </SettingsPanel>
              </div>

              <div class="flex flex-wrap items-center justify-between gap-3">
                <div class="flex flex-wrap gap-2 text-xs font-medium text-gray-600 dark:text-gray-400">
                  <button
                    type="button"
                    class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
                    @click="scrollToSection(`project-${currentProjectTypeKey}-primary`)"
                  >
                    Primary files
                  </button>
                  <button
                    type="button"
                    class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
                    @click="scrollToSection(`project-${currentProjectTypeKey}-optional`)"
                  >
                    Optional folders
                  </button>
                </div>
                <Button variant="secondary" size="sm" class="mt-3 sm:mt-0" @click="showResetConfirm(currentProjectTypeKey)">
                  Reset to Defaults
                </Button>
              </div>
              <div :id="`project-${currentProjectTypeKey}-primary`">
                <SettingsPanel title="Primary files">
                  <div class="space-y-3">
                    <Input
                      v-model="settings.project_types[currentProjectTypeKey].directories.presentation_source"
                      label="Presentation source file"
                      hint="Relative path to your primary presentation.qmd."
                      monospace
                    />
                    <Input
                      v-model="settings.project_types[currentProjectTypeKey].directories.rendered_slides"
                      label="Rendered slides directory"
                      hint="Rendered slides write to the project root by default ('.')."
                      monospace
                    />
                  </div>
                </SettingsPanel>
              </div>

              <div :id="`project-${currentProjectTypeKey}-optional`">
                <SettingsPanel title="Optional folders" description="Toggle extra scaffolding when you need supporting data, scripts, or helper utilities.">
                  <div class="space-y-4">
                    <div class="space-y-2">
                      <Toggle
                        v-model="presentationOptions.includeInputs"
                        label="Include inputs directory"
                        description="Adds an inputs/ folder for sample data used in the presentation."
                      />
                      <Input
                        v-if="presentationOptions.includeInputs"
                        v-model="settings.project_types[currentProjectTypeKey].directories.inputs"
                        label="Inputs directory"
                        prefix="/"
                        monospace
                      />
                    </div>

                    <div class="space-y-2">
                      <Toggle
                        v-model="presentationOptions.includeScripts"
                        label="Include scripts directory"
                        description="Adds a scripts/ folder for demo code or automation."
                      />
                      <Input
                        v-if="presentationOptions.includeScripts"
                        v-model="settings.project_types[currentProjectTypeKey].directories.scripts"
                        label="Scripts directory"
                        prefix="/"
                        monospace
                      />
                    </div>

                    <div class="space-y-2">
                      <Toggle
                        v-model="presentationOptions.includeFunctions"
                        label="Include functions directory"
                        description="Adds R/functions for helper utilities that should load automatically."
                      />
                      <Input
                        v-if="presentationOptions.includeFunctions"
                        v-model="settings.project_types[currentProjectTypeKey].directories.functions"
                        label="Functions directory"
                        prefix="/"
                        monospace
                      />
                    </div>

                    <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                      <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Custom Directories</h4>
                      <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">Add any additional directories you need for your presentations.</p>
                      <Repeater
                        :model-value="settings.project_types[currentProjectTypeKey].extra_directories || []"
                        @update:model-value="settings.project_types[currentProjectTypeKey].extra_directories = $event"
                        add-label="Add Directory"
                        :default-item="() => ({ key: '', label: '', path: '', type: 'workspace', _id: Date.now() })"
                      >
                        <template #default="{ item, index, update }">
                          <div class="grid grid-cols-2 gap-3">
                            <Input
                              :model-value="item.key"
                              @update:model-value="update('key', $event)"
                              label="Key"
                              placeholder="e.g., assets"
                              :error="validateExtraDirectoryKey(item.key, currentProjectTypeKey, 'workspace', index)"
                              monospace
                              size="sm"
                            />
                            <Input
                              :model-value="item.label"
                              @update:model-value="update('label', $event)"
                              label="Label"
                              placeholder="e.g., Assets"
                              size="sm"
                            />
                            <Input
                              :model-value="item.path"
                              @update:model-value="update('path', $event)"
                              label="Path"
                              placeholder="e.g., assets"
                              :error="validateExtraDirectoryPath(item.path)"
                              prefix="/"
                              monospace
                              size="sm"
                              class="col-span-2"
                            />
                          </div>
                        </template>
                      </Repeater>
                    </div>
                  </div>
                </SettingsPanel>
              </div>

            </div>

            <div v-else-if="currentProjectTypeKey === 'course'" class="space-y-6">
              <!-- Project-specific settings (e.g., ggplot theme) -->
              <div v-if="currentProjectTypeSettings && currentProjectTypeSettings.length > 0">
                <SettingsPanel
                  title="Project Settings"
                  description="Default settings applied when creating new projects of this type."
                >
                  <SettingsBlock>
                    <div class="space-y-5">
                      <template v-for="setting in currentProjectTypeSettings" :key="setting.id">
                        <Toggle
                          v-if="setting.control === 'toggle'"
                          v-model="settings.project_types[currentProjectTypeKey][setting.id]"
                          :label="setting.label"
                          :description="setting.description"
                        />
                        <Select
                          v-else-if="setting.control === 'select'"
                          v-model="settings.project_types[currentProjectTypeKey][setting.id]"
                          :label="setting.label"
                          :hint="setting.hint"
                        >
                          <option v-for="opt in setting.options" :key="opt.value" :value="opt.value">
                            {{ opt.label }}
                          </option>
                        </Select>
                        <Input
                          v-else-if="setting.control === 'text'"
                          v-model="settings.project_types[currentProjectTypeKey][setting.id]"
                          :label="setting.label"
                          :hint="setting.hint"
                          :placeholder="setting.placeholder"
                        />
                      </template>
                    </div>
                  </SettingsBlock>
                </SettingsPanel>
              </div>

              <div class="flex flex-wrap items-center justify-between gap-3">
                <div class="flex flex-wrap gap-2 text-xs font-medium text-gray-600 dark:text-gray-400">
                  <button
                    type="button"
                    class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
                    @click="scrollToSection(`project-${currentProjectTypeKey}-core`)"
                  >
                    Core folders
                  </button>
                  <button
                    type="button"
                    class="rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
                    @click="scrollToSection(`project-${currentProjectTypeKey}-quarto`)"
                  >
                    Quarto render directory
                  </button>
                </div>
                <Button variant="secondary" size="sm" class="mt-3 sm:mt-0" @click="showResetConfirm(currentProjectTypeKey)">
                  Reset to Defaults
                </Button>
              </div>
              <div :id="`project-${currentProjectTypeKey}-core`">
                <SettingsPanel title="Core folders" description="Configure folders for course datasets, slide decks, assignments, and readings.">
                  <div class="space-y-3">
                    <Input
                      v-model="settings.project_types[currentProjectTypeKey].directories.data"
                      label="Course data"
                      prefix="/"
                      monospace
                      hint="Shared datasets distributed with the course."
                    />
                    <Input
                      v-model="settings.project_types[currentProjectTypeKey].directories.slides"
                      label="Slides"
                      prefix="/"
                      monospace
                      hint="Lecture slide sources."
                    />
                    <Input
                      v-model="settings.project_types[currentProjectTypeKey].directories.assignments"
                      label="Assignments"
                      prefix="/"
                      monospace
                      hint="Homework or lab materials."
                    />
                    <Input
                      v-model="settings.project_types[currentProjectTypeKey].directories.course_docs"
                      label="Course documents"
                      prefix="/"
                      monospace
                      hint="Syllabus, policies, grading guides."
                    />
                    <Input
                      v-model="settings.project_types[currentProjectTypeKey].directories.readings"
                      label="Readings"
                      prefix="/"
                      monospace
                      hint="Assigned readings and references."
                    />
                    <Input
                      v-model="settings.project_types[currentProjectTypeKey].directories.notebooks"
                      label="Module notebooks"
                      prefix="/"
                      monospace
                      hint="Module notebooks or workshop materials."
                    />
                  </div>
                </SettingsPanel>
              </div>

              <div :id="`project-${currentProjectTypeKey}-quarto`">
                <SettingsPanel title="Quarto render directory" description="Default location for rendered course documentation.">
                  <Input
                    v-model="settings.project_types[currentProjectTypeKey].quarto.render_dir"
                    label="Render directory"
                    prefix="/"
                    monospace
                  />
                </SettingsPanel>

                <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                  <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Custom Directories</h4>
                  <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">Add any additional directories you need for your courses.</p>
                  <Repeater
                    :model-value="settings.project_types[currentProjectTypeKey].extra_directories || []"
                    @update:model-value="settings.project_types[currentProjectTypeKey].extra_directories = $event"
                    add-label="Add Directory"
                    :default-item="() => ({ key: '', label: '', path: '', type: 'workspace', _id: Date.now() })"
                  >
                    <template #default="{ item, index, update }">
                      <div class="grid grid-cols-2 gap-3">
                        <Input
                          :model-value="item.key"
                          @update:model-value="update('key', $event)"
                          label="Key"
                          placeholder="e.g., resources"
                          :error="validateExtraDirectoryKey(item.key, currentProjectTypeKey, 'workspace', index)"
                          monospace
                          size="sm"
                        />
                        <Input
                          :model-value="item.label"
                          @update:model-value="update('label', $event)"
                          label="Label"
                          placeholder="e.g., Resources"
                          size="sm"
                        />
                        <Input
                          :model-value="item.path"
                          @update:model-value="update('path', $event)"
                          label="Path"
                          placeholder="e.g., resources"
                          :error="validateExtraDirectoryPath(item.path)"
                          prefix="/"
                          monospace
                          size="sm"
                          class="col-span-2"
                        />
                      </div>
                    </template>
                  </Repeater>
                </div>
              </div>

            </div>

            <div :id="`project-${currentProjectTypeKey}-gitignore`">
              <SettingsPanel
                title=".gitignore Template"
                description="Patterns applied to all new projects of this type."
              >
                <CodeEditor
                  v-model="templateEditors[`gitignore_${currentProjectTypeKey}`].contents"
                  language="text"
                  min-height="400px"
                  :disabled="templateEditors[`gitignore_${currentProjectTypeKey}`].loading"
                />
                <p v-if="templateEditors[`gitignore_${currentProjectTypeKey}`].loading" class="text-xs text-gray-500 dark:text-gray-400 mt-2">Loading .gitignore template…</p>

                <div class="flex justify-end mt-3">
                  <Button size="sm" variant="secondary" @click="resetInlineTemplate(`gitignore-${currentProjectTypeKey}`, `gitignore_${currentProjectTypeKey}`)">Restore Default</Button>
                </div>
              </SettingsPanel>
            </div>
          </div>
        </div>

        <!-- Templates -->
        <div id="templates" v-show="activeSection === 'templates'" class="space-y-8">
          <div id="templates-notebook">
            <SettingsPanel>
              <SettingsBlock
                title="Notebook Template"
                description="Used by framework::make_notebook() to populate new notebooks."
              >
                <CodeEditor
                  v-model="templateEditors.notebook.contents"
                  language="markdown"
                  min-height="500px"
                  :disabled="templateEditors.notebook.loading"
                />
                <p v-if="templateEditors.notebook.loading" class="text-xs text-gray-500 dark:text-gray-400 mt-2">Loading notebook template…</p>
                <div class="flex justify-end mt-3">
                  <Button size="sm" variant="secondary" @click="resetInlineTemplate('notebook')">Restore Default</Button>
                </div>
              </SettingsBlock>
            </SettingsPanel>
          </div>

          <div id="templates-script">
            <SettingsPanel>
              <SettingsBlock
                title="Script Template"
                description="Used by framework::make_script() for quick task scaffolds."
              >
                <CodeEditor
                  v-model="templateEditors.script.contents"
                  language="r"
                  min-height="450px"
                  :disabled="templateEditors.script.loading"
                />
                <p v-if="templateEditors.script.loading" class="text-xs text-gray-500 dark:text-gray-400 mt-2">Loading script template…</p>
                <div class="flex justify-end mt-3">
                  <Button size="sm" variant="secondary" @click="resetInlineTemplate('script')">Restore Default</Button>
                </div>
              </SettingsBlock>
            </SettingsPanel>
          </div>

          <div id="templates-presentation">
            <SettingsPanel>
              <SettingsBlock
                title="Presentation Template"
                description="Used by framework::make_notebook(stub = 'revealjs') for slide decks."
              >
                <CodeEditor
                  v-model="templateEditors.presentation.contents"
                  language="markdown"
                  min-height="500px"
                  :disabled="templateEditors.presentation.loading"
                />
                <p v-if="templateEditors.presentation.loading" class="text-xs text-gray-500 dark:text-gray-400 mt-2">Loading presentation template…</p>
                <div class="flex justify-end mt-3">
                  <Button size="sm" variant="secondary" @click="resetInlineTemplate('presentation')">Restore Default</Button>
                </div>
              </SettingsBlock>
            </SettingsPanel>
          </div>
        </div>

        <!-- AI Assistants -->
        <div id="ai" v-show="activeSection === 'ai'">
          <SettingsPanel
            description="Framework maintains context files for selected assistants and keeps them in sync before commits."
          >
            <SettingsBlock>
              <Toggle
                v-model="settings.defaults.ai_support"
                label="Enable AI Support"
                description="Generate and sync assistant-specific context files."
              />
            </SettingsBlock>

            <SettingsBlock
              title="Canonical context file"
              description="This file is the source of truth; other instructions files are synced to it when AI hooks run."
            >
              <Select
                v-model="settings.defaults.ai_canonical_file"
                :disabled="!settings.defaults.ai_support"
                label="Canonical Context File"
              >
                <option value="AGENTS.md">AGENTS.md (multi-agent orchestrator)</option>
                <option value="CLAUDE.md">CLAUDE.md</option>
                <option value=".github/copilot-instructions.md">.github/copilot-instructions.md</option>
              </Select>
            </SettingsBlock>

            <template v-if="settings.defaults.ai_support">
              <SettingsBlock
                title="Assistants"
                description="Choose which assistants receive context updates."
              >
                <div class="space-y-2">
                  <Checkbox
                    v-for="assistant in availableAssistants"
                    :key="assistant.id"
                    :id="`ai-${assistant.id}`"
                    v-model="aiAssistants[assistant.id]"
                    :description="assistant.description"
                  >
                    {{ assistant.label }}
                  </Checkbox>
                </div>
              </SettingsBlock>

              <SettingsBlock>
                <Toggle
                  v-model="settings.defaults.git_hooks.ai_sync"
                  label="Sync AI Files Before Commit"
                  description="Update non-canonical files so assistants share the same instructions."
                />
              </SettingsBlock>

              <SettingsBlock
                title="Canonical instructions"
                description="Edit the canonical file directly. Restore defaults if you want to start over."
              >
                <CodeEditor
                  v-model="templateEditors.canonical.contents"
                  language="markdown"
                  min-height="500px"
                  :disabled="templateEditors.canonical.loading || !settings.defaults.ai_support"
                />
                <div class="flex justify-end mt-3">
                  <Button size="sm" variant="secondary" :disabled="templateEditors.canonical.loading" @click="resetCanonicalTemplateInline">Restore Default</Button>
                </div>
              </SettingsBlock>
            </template>
          </SettingsPanel>
        </div>

        <!-- Git & Hooks -->
        <div id="git" v-show="activeSection === 'git'">
          <SettingsPanel
            description="Configure how Framework initializes repositories, commits, and pre-commit hooks."
          >
            <SettingsBlock>
              <Toggle
                v-model="settings.defaults.use_git"
                label="Initialize Git"
                description="Run git init for every new project."
              />
            </SettingsBlock>

            <SettingsBlock
              title="Git identity"
              description="Overrides Author Information when provided."
            >
              <div class="grid gap-4 sm:grid-cols-2">
                <Input
                  v-model="settings.git.user_name"
                  label="Git Name"
                  placeholder="Jane Analyst"
                />
                <Input
                  v-model="settings.git.user_email"
                  label="Git Email"
                  placeholder="jane@example.com"
                  hint="Used for git config user.email during project setup."
                />
              </div>
            </SettingsBlock>

            <SettingsBlock
              title="Git Hooks"
              description="Pre-commit hooks that run automatically before each commit."
            >
              <div class="space-y-4">
                <Toggle
                  v-model="settings.defaults.git_hooks.ai_sync"
                  label="Sync AI Files Before Commit"
                  description="Update non-canonical files so assistants share the same instructions."
                />
                <Toggle
                  v-model="settings.privacy.secret_scan"
                  label="Check for Secrets"
                  description="Run a lightweight scan for API keys and credentials before commits."
                />
                <Toggle
                  v-model="settings.defaults.git_hooks.check_sensitive_dirs"
                  label="Warn About Unignored Sensitive Directories"
                  description="Block commits if directories with sensitive names aren't gitignored."
                />
              </div>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-4">
                Project-specific .gitignore templates can be customized in <a href="#/settings/project-defaults" class="text-sky-600 dark:text-sky-400 hover:underline">Project Defaults</a>.
              </p>
            </SettingsBlock>
          </SettingsPanel>
        </div>

        <!-- Packages -->
        <div id="packages" v-show="activeSection === 'packages'">
          <SettingsPanel>
            <SettingsBlock>
              <Toggle
                v-model="settings.defaults.packages.use_renv"
                label="Enable renv"
                description="Create renv environments for new projects."
              />
            </SettingsBlock>

            <SettingsBlock
              title="Default packages"
              description="Installed (and optionally attached) when scaffold() runs."
            >
              <p class="text-xs text-gray-600 dark:text-gray-400 mb-4">Use this list to preseed notebooks with your preferred helpers.</p>

              <div class="space-y-3" v-if="settings.defaults.packages.default_packages && settings.defaults.packages.default_packages.length">
                <div
                  v-for="(pkg, idx) in settings.defaults.packages.default_packages"
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
            </SettingsBlock>
          </SettingsPanel>
        </div>

      </div>

    </div>

    <!-- Template Editor Modal -->
    <Modal v-model="templateModal.open" size="lg" :title="templateModal.title">
      <template #default>
        <p class="text-sm text-gray-600 dark:text-gray-300 mb-4">{{ templateModal.description }}</p>
        <Textarea v-model="templateModal.contents" :rows="18" monospace />
      </template>
      <template #actions>
        <div class="flex gap-3 justify-end">
          <Button variant="secondary" @click="templateModal.open = false">Cancel</Button>
          <Button variant="primary" :disabled="templateModal.loading" @click="saveTemplate">
            {{ templateModal.loading ? 'Saving…' : 'Save Template' }}
          </Button>
        </div>
      </template>
    </Modal>

    <!-- Reset to Defaults Confirmation Modal -->
    <Modal v-model="resetConfirmModal.open" size="md" title="Reset to Defaults" icon="warning">
      <template #default>
        <p class="text-sm text-gray-600 dark:text-gray-300">
          Are you sure you want to reset <strong>{{ resetConfirmModal.projectTypeName }}</strong> to default settings?
          This will discard all your customizations for this project type.
        </p>
      </template>
      <template #actions>
        <div class="flex gap-3 justify-end">
          <Button variant="secondary" @click="resetConfirmModal.open = false">Cancel</Button>
          <Button variant="primary" @click="resetProjectType">
            Reset to Defaults
          </Button>
        </div>
      </template>
    </Modal>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import PageHeader from '../components/ui/PageHeader.vue'
import Input from '../components/ui/Input.vue'
import PackageAutocomplete from '../components/ui/PackageAutocomplete.vue'
import Select from '../components/ui/Select.vue'
import Toggle from '../components/ui/Toggle.vue'
import Checkbox from '../components/ui/Checkbox.vue'
import Button from '../components/ui/Button.vue'
import CopyButton from '../components/ui/CopyButton.vue'
import OverviewCard from '../components/ui/OverviewCard.vue'
import NavigationSectionHeading from '../components/ui/NavigationSectionHeading.vue'
import Modal from '../components/ui/Modal.vue'
import Textarea from '../components/ui/Textarea.vue'
import CodeEditor from '../components/ui/CodeEditor.vue'
import Repeater from '../components/ui/Repeater.vue'
import { useToast } from '../composables/useToast'
import SettingsPanel from '../components/settings/SettingsPanel.vue'
import SettingsBlock from '../components/settings/SettingsBlock.vue'
import {
  InformationCircleIcon,
  UserIcon,
  Cog6ToothIcon,
  CubeIcon,
  DocumentTextIcon,
  FolderIcon
} from '@heroicons/vue/24/outline'

const toast = useToast()
const router = useRouter()
const route = useRoute()

const sections = [
  { id: 'overview', label: 'Overview', slug: 'overview', icon: InformationCircleIcon },
  { id: 'basics', label: 'Basics', slug: 'basics', icon: Cog6ToothIcon },
  { id: 'structure', label: 'Project Structure', slug: 'project-structure', icon: FolderIcon },
  { id: 'packages', label: 'Packages', slug: 'packages-dependencies', icon: CubeIcon },
  { id: 'ai', label: 'AI Assistants', slug: 'ai-assistants', svgIcon: 'M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z' },
  { id: 'git', label: 'Git & Hooks', slug: 'git-hooks', svgIcon: 'M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4' },
  { id: 'templates', label: 'Templates', slug: 'templates', icon: DocumentTextIcon }
]

const sectionSlugMap = Object.fromEntries(sections.map(({ id, slug }) => [id, slug]))
const sectionSlugToId = Object.fromEntries(sections.map(({ id, slug }) => [slug, id]))
const defaultSectionId = 'overview'

const fallbackProjectTypes = {
  project: {
    label: 'Standard Project Structure',
    description: 'General-purpose analysis project with notebooks, scripts, and shared outputs.',
    directories: {
      functions: 'R/functions',
      notebooks: 'notebooks',
      scripts: 'scripts',
      inputs_raw: 'inputs/raw',
      inputs_intermediate: 'inputs/intermediate',
      inputs_final: 'inputs/final',
      reference: 'reference',
      outputs_notebooks: 'outputs/notebooks',
      outputs_tables: 'outputs/tables',
      outputs_figures: 'outputs/figures',
      outputs_models: 'outputs/models',
      outputs_reports: 'outputs/reports',
      cache: 'outputs/cache',
      scratch: 'scratch'
    },
    quarto: { render_dir: 'outputs/notebooks' },
    notebook_template: 'notebook',
    extra_directories: []
  },
  project_sensitive: {
    label: 'Privacy Sensitive Project Structure',
    description: 'Projects handling PHI/PII with dedicated private/public data flows.',
    directories: {
      functions: 'R/functions',
      notebooks: 'notebooks',
      scripts: 'scripts',
      inputs_private_raw: 'inputs/private/raw',
      inputs_private_intermediate: 'inputs/private/intermediate',
      inputs_private_final: 'inputs/private/final',
      inputs_public_raw: 'inputs/public/raw',
      inputs_public_intermediate: 'inputs/public/intermediate',
      inputs_public_final: 'inputs/public/final',
      outputs_private_tables: 'outputs/private/tables',
      outputs_private_figures: 'outputs/private/figures',
      outputs_private_models: 'outputs/private/models',
      outputs_private_docs: 'outputs/private/docs',
      outputs_private_data_final: 'outputs/private/data_final',
      outputs_public_tables: 'outputs/public/tables',
      outputs_public_figures: 'outputs/public/figures',
      outputs_public_models: 'outputs/public/models',
      outputs_public_docs: 'outputs/public/docs',
      outputs_public_data_final: 'outputs/public/data_final',
      cache: 'outputs/private/cache',
      scratch: 'scratch'
    },
    quarto: { render_dir: 'outputs/public/docs' },
    notebook_template: 'notebook',
    extra_directories: []
  },
  presentation: {
    label: 'Presentation Structure',
    description: 'Single talk or slide deck with minimal analysis scaffolding.',
    directories: {
      presentation_source: 'presentation.qmd',
      rendered_slides: '.'
    },
    quarto: { render_dir: '.' },
    notebook_template: 'notebook',
    extra_directories: []
  },
  course: {
    label: 'Course Structure',
    description: 'Courses with modules, assignments, and lecture materials.',
    directories: {
      data: 'data',
      slides: 'slides',
      assignments: 'assignments',
      course_docs: 'course_docs',
      readings: 'readings',
      notebooks: 'modules'
    },
    quarto: { render_dir: 'course_docs' },
    notebook_template: 'notebook',
    extra_directories: []
  }
}

const defaultProjectTypes = ref(JSON.parse(JSON.stringify(fallbackProjectTypes)))

const projectTypeSlugMap = {
  project: 'project',
  project_sensitive: 'sensitive-project',
  presentation: 'presentation',
  course: 'course'
}

const projectSlugToKey = Object.fromEntries(Object.entries(projectTypeSlugMap).map(([key, slug]) => [slug, key]))
const defaultProjectTypeKey = 'project'

const defaultProjectDescriptions = {
  project: 'Tune the standard analysis layout—functions, notebooks, inputs, and outputs live here by default.',
  project_sensitive: 'Private and public inputs stay separate so sensitive data never leaves restricted folders.',
  presentation: 'Control where your presentation source lives and where rendered slides are written.',
  course: 'Adjust the folders used for slides, assignments, readings, and course documentation.'
}

const formatProjectTypeName = (key) => String(key).replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())

const catalog = ref(null)

const generalWorkspaceFallback = [
  {
    key: 'functions',
    label: 'Functions',
    hint: 'R files here are sourced by scaffold(), so helper functions are available in every project session.'
  },
  {
    key: 'notebooks',
    label: 'Notebooks',
    hint: 'Where Quarto or R Markdown analysis notebooks live.'
  },
  {
    key: 'scripts',
    label: 'Scripts',
    hint: 'Reusable R scripts, job runners, or automation tasks.'
  },
  {
    key: 'reference',
    label: 'Reference materials',
    hint: 'Codebooks, documentation, and other background resources.'
  }
]

const generalInputFallback = [
  { key: 'inputs_raw', label: 'Raw data', hint: 'Read-only exports from source systems.' },
  { key: 'inputs_intermediate', label: 'Intermediate data', hint: 'Data after light cleaning or pre-processing steps.' },
  { key: 'inputs_final', label: 'Analysis-ready data', hint: 'Final inputs ready for modeling or reporting.' }
]

const generalOutputFallback = [
  { key: 'outputs_notebooks', label: 'Rendered notebooks', hint: 'Compiled Quarto/R Markdown notebooks.' },
  { key: 'outputs_tables', label: 'Tables', hint: 'Publishable tables ready for reports or manuscripts.' },
  { key: 'outputs_figures', label: 'Figures', hint: 'Final plots and graphics.' },
  { key: 'outputs_models', label: 'Models', hint: 'Serialized models or model summaries.' },
  { key: 'outputs_reports', label: 'Reports', hint: 'Final reports and deliverables ready for publication.' }
]

const generalUtilityFallback = [
  { key: 'cache', label: 'Cache', hint: 'Temporary artifacts (gitignored).' },
  { key: 'scratch', label: 'Scratch', hint: 'Short-lived explorations (gitignored).' }
]

const sensitiveInputFallback = [
  { privateKey: 'inputs_private_raw', publicKey: 'inputs_public_raw', label: 'Raw data', privateLabel: 'Raw data (private)', publicLabel: 'Raw data (public)' },
  { privateKey: 'inputs_private_intermediate', publicKey: 'inputs_public_intermediate', label: 'Intermediate data', privateLabel: 'Intermediate data (private)', publicLabel: 'Intermediate data (public)' },
  { privateKey: 'inputs_private_final', publicKey: 'inputs_public_final', label: 'Analysis-ready data', privateLabel: 'Analysis-ready data (private)', publicLabel: 'Analysis-ready data (public)' }
]

const sensitiveOutputFallback = [
  { privateKey: 'outputs_private_tables', publicKey: 'outputs_public_tables', label: 'Tables', privateLabel: 'Tables (private)', publicLabel: 'Tables (public)' },
  { privateKey: 'outputs_private_figures', publicKey: 'outputs_public_figures', label: 'Figures', privateLabel: 'Figures (private)', publicLabel: 'Figures (public)' },
  { privateKey: 'outputs_private_models', publicKey: 'outputs_public_models', label: 'Models', privateLabel: 'Models (private)', publicLabel: 'Models (public)' },
  { privateKey: 'outputs_private_docs', publicKey: 'outputs_public_docs', label: 'Docs & reports', privateLabel: 'Docs (private)', publicLabel: 'Docs (public)' },
  { privateKey: 'outputs_private_data_final', publicKey: 'outputs_public_data_final', label: 'Final data', privateLabel: 'Final data (private)', publicLabel: 'Final data (public)' }
]

const getDirectoryMeta = (typeKey, dirKey) => catalog.value?.project_types?.[typeKey]?.directories?.[dirKey] || {}

const buildDirectoryFields = (typeKey, fallback) =>
  fallback.map((entry) => {
    const meta = getDirectoryMeta(typeKey, entry.key)
    return {
      key: entry.key,
      label: meta.label || entry.label,
      hint: meta.hint || entry.hint || ''
    }
  })

const generalWorkspaceFields = computed(() => buildDirectoryFields('project', generalWorkspaceFallback))
const generalInputFields = computed(() => buildDirectoryFields('project', generalInputFallback))
const generalOutputFields = computed(() => buildDirectoryFields('project', generalOutputFallback))
const generalUtilityFields = computed(() => buildDirectoryFields('project', generalUtilityFallback))

const buildSensitivePairs = (fallback) =>
  fallback.map((entry) => {
    const privateMeta = getDirectoryMeta('project_sensitive', entry.privateKey)
    const publicMeta = getDirectoryMeta('project_sensitive', entry.publicKey)
    return {
      ...entry,
      privateLabel: privateMeta.label || entry.privateLabel,
      publicLabel: publicMeta.label || entry.publicLabel
    }
  })

const sensitiveInputPairs = computed(() => buildSensitivePairs(sensitiveInputFallback))
const sensitiveOutputPairs = computed(() => buildSensitivePairs(sensitiveOutputFallback))

const currentProjectTypeSettings = computed(() => {
  const key = currentProjectTypeKey.value
  if (!key || !catalog.value?.project_types?.[key]?.settings) return []
  return catalog.value.project_types[key].settings
})

const presentationToggleFallbacks = {
  include_inputs: 'inputs',
  include_scripts: 'scripts',
  include_functions: 'R/functions'
}

const presentationOptionalDefaults = computed(() => {
  const toggles = catalog.value?.project_types?.presentation?.optional_toggles || {}
  return {
    inputs: toggles.include_inputs?.default_path || presentationToggleFallbacks.include_inputs,
    scripts: toggles.include_scripts?.default_path || presentationToggleFallbacks.include_scripts,
    functions: toggles.include_functions?.default_path || presentationToggleFallbacks.include_functions
  }
})

const canonicalTemplateMap = {
  'CLAUDE.md': 'ai_claude',
  'AGENTS.md': 'ai_agents',
  '.github/copilot-instructions.md': 'ai_copilot'
}

const availableAssistants = [
  { id: 'claude', label: 'Claude Code', description: "Anthropic's IDE-focused assistant." },
  { id: 'copilot', label: 'GitHub Copilot', description: 'Complements VS Code and JetBrains editors.' },
  { id: 'agents', label: 'Multi-Agent (OpenAI Codex, Cursor, etc.)', description: 'Shared instructions for multi-model orchestrators.' }
]

const activeSection = ref(defaultSectionId)
const saving = ref(false)

const settings = ref({
  projects_root: '',
  project_types: JSON.parse(JSON.stringify(defaultProjectTypes.value)),
  author: {
    name: '',
    email: '',
    affiliation: ''
  },
  defaults: {
    project_type: 'project',
    notebook_format: 'quarto',
    ide: 'vscode',
    ide_support_vscode: false,
    use_git: true,
    use_renv: false,
    seed: '',
    seed_on_scaffold: false,
    ai_support: true,
    ai_assistants: ['claude'],
    ai_canonical_file: 'CLAUDE.md',
    directories: JSON.parse(JSON.stringify(defaultProjectTypes.value.project.directories)),
    git_hooks: {
      ai_sync: false,
      data_security: false,
      check_sensitive_dirs: false
    },
    packages: {
      use_renv: false,
      default_packages: [
        { name: 'dplyr', source: 'cran', auto_attach: true },
        { name: 'ggplot2', source: 'cran', auto_attach: true }
      ]
    }
  },
  git: {
    user_name: '',
    user_email: ''
  },
  privacy: {
    secret_scan: false,
    gitignore_template: 'gitignore'
  }
})

const presentationOptions = reactive({
  includeInputs: false,
  includeScripts: false,
  includeFunctions: false
})

const aiAssistants = reactive({
  claude: true,
  agents: false,
  copilot: false
})

const templateModal = reactive({
  open: false,
  name: '',
  title: '',
  description: '',
  contents: '',
  loading: false
})

const resetConfirmModal = reactive({
  open: false,
  projectTypeKey: null,
  projectTypeName: ''
})

const templateEditors = reactive({
  notebook: { loading: false, contents: '' },
  script: { loading: false, contents: '' },
  presentation: { loading: false, contents: '' },
  canonical: { loading: false, contents: '' },
  gitignore_project: { loading: false, contents: '' },
  gitignore_project_sensitive: { loading: false, contents: '' },
  gitignore_course: { loading: false, contents: '' },
  gitignore_presentation: { loading: false, contents: '' }
})

const projectTypeEntries = computed(() => Object.entries(settings.value.project_types || {}))

const projectStructureSubnav = computed(() =>
  projectTypeEntries.value.map(([key, type]) => ({
    key,
    // Remove " Structure" suffix from labels for menu display
    label: (type.label || formatProjectTypeName(key)).replace(/ Structure$/i, ''),
    slug: projectTypeSlugMap[key] || key
  }))
)

const templatesSubnav = [
  { id: 'templates-notebook', label: 'Notebook' },
  { id: 'templates-script', label: 'Script' },
  { id: 'templates-presentation', label: 'Presentation' }
]

const currentProjectTypeKey = computed(() => {
  const slug = route.params.subsection
  // Return null if no subsection to show index page
  if (!slug) return null
  return projectSlugToKey[slug] || defaultProjectTypeKey
})

const currentProjectType = computed(() => {
  const key = currentProjectTypeKey.value
  if (!key) return null
  return settings.value.project_types?.[key] || null
})

const defaultPageTitle = 'Settings'
const defaultPageDescription = 'Manage defaults shared across new projects.'

const sectionHeaderMeta = {
  overview: {
    title: 'Overview',
    description: 'Overview of your Framework global settings and preferences.'
  },
  basics: {
    title: 'Basics',
    description: 'Essential settings for new projects.'
  },
  author: {
    title: 'Author Information',
    description: 'Defaults that populate README files and notebook headers when scaffold() runs.'
  },
  workflow: {
    title: 'Editor & Workflow',
    description: 'Control how Framework scaffolds projects in your preferred tools.'
  },
  structure: {
    title: 'Project Structure Defaults',
    description: 'Choose a project type to configure its directory structure and default settings.'
  },
  templates: {
    title: 'Templates',
    description: 'Edit the starter templates Framework uses for notebooks, scripts, and presentations.'
  },
  ai: {
    title: 'AI Assistants',
    description: 'Manage assistant support, canonical context files, and sync hooks.'
  },
  git: {
    title: 'Git & Hooks',
    description: 'Configure repository initialization, commit identity, git hooks, and security scanning.'
  },
  packages: {
    title: 'Packages & Dependencies',
    description: 'Define dependency defaults and auto-attach behavior for new projects.'
  }
}

const currentSectionMeta = computed(() => sectionHeaderMeta[activeSection.value] || {
  title: defaultPageTitle,
  description: defaultPageDescription
})

const pageHeaderTitle = computed(() => {
  if (activeSection.value === 'structure' && currentProjectType.value) {
    return currentProjectType.value.label || formatProjectTypeName(currentProjectTypeKey.value)
  }
  return currentSectionMeta.value.title
})

const pageHeaderDescription = computed(() => {
  if (activeSection.value === 'structure' && currentProjectType.value) {
    return (
      currentProjectType.value.description ||
      defaultProjectDescriptions[currentProjectTypeKey.value] ||
      currentSectionMeta.value.description
    )
  }
  return currentSectionMeta.value.description
})

const activeGitignoreTemplate = computed(() => settings.value.privacy.gitignore_template || 'gitignore')

const suggestedGitignoreEntries = computed(() => {
  const entries = new Set()
  const types = settings.value.project_types || {}

  const sensitiveDirs = types.project_sensitive?.directories || {}
  for (const path of Object.values(sensitiveDirs)) {
    if (typeof path === 'string' && path.trim() && path.includes('private')) {
      entries.add(path.replace(/^\/+/, ''))
    }
  }

  const generalDirs = types.project?.directories || {}
  ;['cache', 'scratch'].forEach((key) => {
    const value = generalDirs[key]
    if (typeof value === 'string' && value.trim()) {
      entries.add(value.replace(/^\/+/, ''))
    }
  })

  return Array.from(entries).sort()
})

const canonicalTemplateName = computed(() => canonicalTemplateMap[settings.value.defaults.ai_canonical_file] || 'ai_claude')

const notebookScriptSubnav = [
  { id: 'notebooksScripts-format', label: 'Defaults' },
  { id: 'notebooksScripts-notebook-stub', label: 'Notebook Stub' },
  { id: 'notebooksScripts-script-stub', label: 'Script Stub' }
]

const buildSettingsHref = (sectionSlug, subsectionSlug) => {
  const params = { section: sectionSlug || undefined }
  if (subsectionSlug) params.subsection = subsectionSlug
  return router.resolve({ name: 'settings', params }).href
}

const pushSettingsRoute = (sectionSlug, subsectionSlug) => {
  const params = {}
  if (sectionSlug) params.section = sectionSlug
  if (subsectionSlug) params.subsection = subsectionSlug

  const currentSectionSlug = route.params.section || undefined
  const currentSubSlug = route.params.subsection || undefined
  const nextSectionSlug = params.section || undefined
  const nextSubSlug = params.subsection || undefined

  if (currentSectionSlug === nextSectionSlug && currentSubSlug === nextSubSlug) {
    return Promise.resolve()
  }

  return router.replace({ name: 'settings', params }).catch(() => {})
}

watch(
  () => route.params.section,
  (slug) => {
    if (!slug) {
      pushSettingsRoute(sectionSlugMap[defaultSectionId], undefined)
      return
    }

    const sectionId = sectionSlugToId[slug] || defaultSectionId
    activeSection.value = sectionId

    if (!sectionSlugToId[slug]) {
      pushSettingsRoute(sectionSlugMap[sectionId], undefined)
      return
    }

    // Allow structure section without subsection to show index page
    // No auto-redirect needed
  },
  { immediate: true }
)

// Removed watcher that forced redirect when no subsection
// Now allows index page to display when clicking Project Structure

const toScalar = (value, fallback = '') => {
  if (Array.isArray(value)) {
    return value.length > 0 ? toScalar(value[0], fallback) : fallback
  }
  return value ?? fallback
}

const toBoolean = (value, fallback = false) => {
  const scalar = toScalar(value, fallback)
  if (typeof scalar === 'boolean') return scalar
  if (typeof scalar === 'string') {
    return ['true', '1', 'yes'].includes(scalar.toLowerCase())
  }
  return Boolean(scalar)
}

const flattenArray = (value) => {
  if (!Array.isArray(value)) return []
  return value.flatMap((item) => (Array.isArray(item) ? item : [item])).filter(Boolean)
}

const normalizeDirectories = (dirs = {}, fallback = {}) => {
  const merged = { ...fallback }
  for (const [key, val] of Object.entries(dirs || {})) {
    const candidate = toScalar(val, null)
    if (candidate === null || candidate === '') {
      delete merged[key]
    } else {
      merged[key] = candidate
    }
  }
  return merged
}

const normalizeProjectType = (key, type) => {
  const fallback = defaultProjectTypes.value[key] || {
    directories: {},
    quarto: {},
    extra_directories: []
  }
  return {
    label: toScalar(type?.label, fallback.label || formatProjectTypeName(key)),
    description: toScalar(type?.description, fallback.description || ''),
    ggplot_theme: toScalar(type?.ggplot_theme, 'theme_minimal'),
    set_theme_on_scaffold: toBoolean(type?.set_theme_on_scaffold, true),
    directories: normalizeDirectories(type?.directories, fallback.directories),
    quarto: {
      render_dir: toScalar(type?.quarto?.render_dir, fallback.quarto?.render_dir || '.')
    },
    notebook_template: toScalar(type?.notebook_template, fallback.notebook_template || 'notebook'),
    extra_directories: Array.isArray(type?.extra_directories) ? type.extra_directories : (fallback.extra_directories || [])
  }
}

const hydrateDefaultsFromCatalog = (catalogData) => {
  if (!catalogData || !catalogData.project_types) return

  const normalized = {}
  for (const [key, type] of Object.entries(catalogData.project_types)) {
    const fallback = fallbackProjectTypes[key] || {}
    const directories = {}
    for (const [dirKey, dirMeta] of Object.entries(type.directories || {})) {
      const fallbackDir = fallback.directories?.[dirKey] || ''
      directories[dirKey] = toScalar(dirMeta?.default, fallbackDir)
    }

    normalized[key] = {
      label: toScalar(type.label, fallback.label || formatProjectTypeName(key)),
      description: toScalar(type.description, fallback.description || ''),
      directories,
      quarto: {
        render_dir: toScalar(type.quarto?.render_dir?.default, fallback.quarto?.render_dir || '.')
      },
      notebook_template: toScalar(type.notebook_template?.default, fallback.notebook_template || 'notebook'),
      optional_toggles: type.optional_toggles || {}
    }
  }

  // Ensure any fallback types missing from catalog are preserved
  for (const [key, fallback] of Object.entries(fallbackProjectTypes)) {
    if (!normalized[key]) {
      normalized[key] = JSON.parse(JSON.stringify(fallback))
    }
  }

  defaultProjectTypes.value = normalized
}

const setPresentationDirectory = (dirKey, enabled, defaultPath) => {
  if (!settings.value.project_types?.presentation) return
  const dirs = settings.value.project_types.presentation.directories || (settings.value.project_types.presentation.directories = {})
  if (enabled) {
    if (!dirs[dirKey] || dirs[dirKey] === '') {
      dirs[dirKey] = defaultPath
    }
  } else {
    if (Object.prototype.hasOwnProperty.call(dirs, dirKey)) {
      delete dirs[dirKey]
    }
  }
}

const loadTemplateInline = async (templateName, editorKey = templateName) => {
  if (!templateEditors[editorKey]) return
  templateEditors[editorKey].loading = true
  try {
    const response = await fetch(`/api/templates/${templateName}`)
    if (!response.ok) throw new Error('Request failed')
    const data = await response.json()
    templateEditors[editorKey].contents = data.contents || ''
  } catch (error) {
    toast.error('Template Error', 'Unable to load template contents.')
  } finally {
    templateEditors[editorKey].loading = false
  }
}

const resetInlineTemplate = async (templateName, editorKey = templateName) => {
  if (!templateEditors[editorKey]) return
  try {
    const response = await fetch(`/api/templates/${templateName}`, { method: 'DELETE' })
    if (!response.ok) throw new Error('Request failed')
    await loadTemplateInline(templateName, editorKey)
    toast.success('Template Reset', 'Restored the packaged default template.')
  } catch (error) {
    toast.error('Reset Failed', 'Unable to restore the default template.')
  }
}

const resetCanonicalTemplateInline = () => {
  resetInlineTemplate(canonicalTemplateName.value, 'canonical')
}

watch(aiAssistants, (newVal) => {
  const assistants = []
  if (newVal.claude) assistants.push('claude')
  if (newVal.copilot) assistants.push('copilot')
  if (newVal.agents) assistants.push('agents')
  settings.value.defaults.ai_assistants = assistants
}, { deep: true })

watch(() => settings.value.defaults.ai_canonical_file, async () => {
  await loadTemplateInline(canonicalTemplateName.value, 'canonical')
})

watch(() => settings.value.defaults.git_hooks.data_security, (val) => {
  settings.value.privacy.secret_scan = val
})

watch(() => settings.value.privacy.secret_scan, (val) => {
  settings.value.defaults.git_hooks.data_security = val
})

watch(() => presentationOptions.includeInputs, (enabled) => {
  setPresentationDirectory('inputs', enabled, presentationOptionalDefaults.value.inputs)
})

watch(() => presentationOptions.includeScripts, (enabled) => {
  setPresentationDirectory('scripts', enabled, presentationOptionalDefaults.value.scripts)
})

watch(() => presentationOptions.includeFunctions, (enabled) => {
  setPresentationDirectory('functions', enabled, presentationOptionalDefaults.value.functions)
})

const handleKeyDown = (event) => {
  if ((event.metaKey || event.ctrlKey) && event.key === 's') {
    event.preventDefault()
    saveSettings()
  }
}

const hasDirectory = (typeKey, field) => {
  const dirs = settings.value.project_types?.[typeKey]?.directories
  return !!dirs && Object.prototype.hasOwnProperty.call(dirs, field)
}

const showResetConfirm = (key) => {
  if (!defaultProjectTypes.value[key]) return
  resetConfirmModal.projectTypeKey = key
  resetConfirmModal.projectTypeName = settings.value.project_types[key]?.label || formatProjectTypeName(key)
  resetConfirmModal.open = true
}

const resetProjectType = () => {
  const key = resetConfirmModal.projectTypeKey
  if (!defaultProjectTypes.value[key]) return

  settings.value.project_types[key] = JSON.parse(JSON.stringify(defaultProjectTypes.value[key]))
  if (key === 'presentation') {
    presentationOptions.includeInputs = false
    presentationOptions.includeScripts = false
    presentationOptions.includeFunctions = false
  }

  // Close modal and show success
  resetConfirmModal.open = false
  toast.success('Reset Complete', `${resetConfirmModal.projectTypeName} has been reset to defaults`)
}

const openTemplateEditor = async (name, { title, description }) => {
  templateModal.open = true
  templateModal.loading = true
  templateModal.name = name
  templateModal.title = title
  templateModal.description = description
  try {
    const response = await fetch(`/api/templates/${name}`)
    const data = await response.json()
    templateModal.contents = data.contents || ''
  } catch (error) {
    toast.error('Template Error', 'Unable to load template contents.')
  } finally {
    templateModal.loading = false
  }
}

const openCanonicalTemplate = () => {
  const name = canonicalTemplateMap[settings.value.defaults.ai_canonical_file] || 'ai_claude'
  openTemplateEditor(name, {
    title: `Edit ${settings.value.defaults.ai_canonical_file}`,
    description: 'This file is treated as canonical; other assistant files are synced to it.'
  })
}

const resetTemplate = async (name) => {
  try {
    await fetch(`/api/templates/${name}`, { method: 'DELETE' })
    toast.success('Template Reset', 'Restored the packaged default template.')
  } catch (error) {
    toast.error('Reset Failed', 'Unable to restore the default template.')
  }
}

const resetCanonicalTemplate = () => {
  const name = canonicalTemplateMap[settings.value.defaults.ai_canonical_file] || 'ai_claude'
  resetTemplate(name)
}

const saveTemplate = async () => {
  try {
    templateModal.loading = true
    await fetch(`/api/templates/${templateModal.name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ contents: templateModal.contents })
    })
    toast.success('Template Saved', 'Your changes have been saved.')
    templateModal.open = false
  } catch (error) {
    toast.error('Save Failed', 'Could not save template changes.')
  } finally {
    templateModal.loading = false
  }
}

const addPackage = () => {
  if (!settings.value.defaults.packages.default_packages) {
    settings.value.defaults.packages.default_packages = []
  }
  settings.value.defaults.packages.default_packages.push({ name: '', source: 'cran', auto_attach: false })
}

const removePackage = (index) => {
  settings.value.defaults.packages.default_packages.splice(index, 1)
}

const scrollToSection = (id) => {
  const el = document.getElementById(id)
  if (el) {
    el.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }
}

const defaultProjectSectionId = (key) => {
  switch (key) {
    case 'project':
      return `project-${key}-inputs`
    case 'project_sensitive':
      return `project-${key}-workspaces`
    case 'presentation':
      return `project-${key}-primary`
    case 'course':
      return `project-${key}-core`
    default:
      return `project-${key}`
  }
}

const navigateToSection = async (sectionId) => {
  const section = sections.find((s) => s.id === sectionId)
  if (!section) return

  // For structure section, go to index page (no subsection)
  const subsectionSlug = section.id === 'structure' ? undefined : undefined

  await pushSettingsRoute(section.slug, subsectionSlug)
  await nextTick()

  scrollToSection(section.id)
}

const navigateToProjectType = async (key) => {
  const slug = projectTypeSlugMap[key] || projectTypeSlugMap[defaultProjectTypeKey]
  await pushSettingsRoute('project-structure', slug)
  await nextTick()
  scrollToSection(defaultProjectSectionId(key))
}

watch(
  () => currentProjectTypeKey.value,
  (key, prev) => {
    if (activeSection.value !== 'structure') return
    if (!key || key === prev) return
    nextTick(() => scrollToSection(defaultProjectSectionId(key)))
  }
)


const loadSettings = async () => {
  try {
    const [catalogResponse, settingsResponse] = await Promise.all([
      fetch('/api/settings/catalog'),
      fetch('/api/settings/get')
    ])

    if (!catalogResponse.ok) {
      throw new Error('Failed to load settings catalog')
    }

    if (!settingsResponse.ok) {
      throw new Error('Failed to load settings payload')
    }

    const catalogData = await catalogResponse.json()
    catalog.value = catalogData
    hydrateDefaultsFromCatalog(catalogData)

    const data = await settingsResponse.json()

    // V2 format: projects_root is under global
    settings.value.projects_root = toScalar(data.global?.projects_root || data.projects_root, '')

    if (data.project_types) {
      const merged = {}
      const rawTypes = { ...defaultProjectTypes.value, ...data.project_types }
      for (const [key, value] of Object.entries(rawTypes)) {
        merged[key] = normalizeProjectType(key, value)
      }
      settings.value.project_types = merged
    }

    presentationOptions.includeInputs = hasDirectory('presentation', 'inputs')
    presentationOptions.includeScripts = hasDirectory('presentation', 'scripts')
    presentationOptions.includeFunctions = hasDirectory('presentation', 'functions')

    if (data.author) {
      settings.value.author = {
        name: toScalar(data.author.name, ''),
        email: toScalar(data.author.email, ''),
        affiliation: toScalar(data.author.affiliation, '')
      }
    }

    if (data.defaults) {
      const defaults = data.defaults
      settings.value.defaults.project_type = toScalar(defaults.project_type, 'project')
      settings.value.defaults.notebook_format = toScalar(defaults.notebook_format, 'quarto')
      settings.value.defaults.ide = toScalar(defaults.ide, 'vscode')
      settings.value.defaults.use_git = toBoolean(defaults.use_git, true)
      settings.value.defaults.use_renv = toBoolean(defaults.use_renv, false)
      settings.value.defaults.seed_on_scaffold = toBoolean(defaults.seed_on_scaffold, false)
      settings.value.defaults.seed = toScalar(defaults.seed, '')
      settings.value.defaults.ai_support = toBoolean(defaults.ai_support, true)
      settings.value.defaults.ai_canonical_file = toScalar(defaults.ai_canonical_file, 'CLAUDE.md')
      const assistants = flattenArray(defaults.ai_assistants)
      if (assistants.length) {
        settings.value.defaults.ai_assistants = assistants
        aiAssistants.claude = assistants.includes('claude')
        aiAssistants.copilot = assistants.includes('copilot')
        aiAssistants.agents = assistants.includes('agents')
      }

      if (defaults.git_hooks) {
        settings.value.defaults.git_hooks = {
          ...settings.value.defaults.git_hooks,
          ...Object.fromEntries(
            Object.entries(defaults.git_hooks).map(([key, val]) => [key, toBoolean(val, settings.value.defaults.git_hooks[key])])
          )
        }
        settings.value.privacy.secret_scan = settings.value.defaults.git_hooks.data_security
      }

      if (defaults.packages) {
        // New nested structure: packages: { use_renv: bool, default_packages: [...] }
        if (defaults.packages.default_packages) {
          settings.value.defaults.packages = {
            use_renv: toBoolean(defaults.packages.use_renv, false),
            default_packages: (defaults.packages.default_packages || []).map((pkg) => ({
              name: toScalar(pkg.name, ''),
              source: toScalar(pkg.source, 'cran'),
              auto_attach: toBoolean(pkg.auto_attach, false)
            }))
          }
        }
        // Old flat array structure (backward compatibility)
        else if (Array.isArray(defaults.packages)) {
          settings.value.defaults.packages = {
            use_renv: false,
            default_packages: defaults.packages.map((pkg) => ({
              name: toScalar(pkg.name, ''),
              source: toScalar(pkg.source, 'cran'),
              auto_attach: toBoolean(pkg.auto_attach, false)
            }))
          }
        }
      }

      // Keep legacy directories around for backwards compatibility
      if (defaults.directories) {
        settings.value.defaults.directories = {
          ...settings.value.defaults.directories,
          ...Object.fromEntries(
            Object.entries(defaults.directories).map(([key, val]) => [key, toScalar(val, settings.value.defaults.directories[key] || '')])
          )
        }
      } else if (settings.value.project_types.project) {
        settings.value.defaults.directories = {
          ...settings.value.defaults.directories,
          ...settings.value.project_types.project.directories
        }
      }
    }

    if (data.git) {
      settings.value.git = {
        user_name: toScalar(data.git.user_name, ''),
        user_email: toScalar(data.git.user_email, '')
      }
    }

    if (data.privacy) {
      settings.value.privacy.secret_scan = toBoolean(data.privacy.secret_scan, settings.value.defaults.git_hooks.data_security)
      settings.value.privacy.gitignore_template = toScalar(data.privacy.gitignore_template, 'gitignore')
    } else {
      settings.value.privacy.secret_scan = settings.value.defaults.git_hooks.data_security
    }

    await loadTemplateInline(canonicalTemplateName.value, 'canonical')
  } catch (error) {
    console.error('Failed to load settings:', error)
    toast.error('Load Failed', 'Unable to load current settings.')
  }
}

// Helper functions for extra_directories with type field
const extraDirectoriesByType = (projectTypeKey, type) => {
  const projectType = settings.value.project_types[projectTypeKey]
  if (!projectType || !Array.isArray(projectType.extra_directories)) {
    return []
  }
  return projectType.extra_directories.filter(dir => dir.type === type)
}

const updateExtraDirectories = (projectTypeKey, type, updatedItems) => {
  const projectType = settings.value.project_types[projectTypeKey]
  if (!projectType) return

  // Initialize if needed
  if (!Array.isArray(projectType.extra_directories)) {
    projectType.extra_directories = []
  }

  // Remove all items of this type
  const otherTypes = projectType.extra_directories.filter(dir => dir && dir.type !== type)

  // Add the updated items (ensuring they all have the correct type)
  const itemsWithType = updatedItems.map(item => ({ ...item, type }))

  // Replace entire array
  projectType.extra_directories = [...otherTypes, ...itemsWithType]
}

// Validation helpers for extra_directories
const validateExtraDirectoryKey = (key, projectTypeKey, type, currentIndex) => {
  if (!key) return null // Empty is ok, will be caught by backend

  // Check format (alphanumeric + underscore only)
  if (!/^[a-zA-Z0-9_]+$/.test(key)) {
    return 'Only letters, numbers, and underscores allowed'
  }

  // Check for duplicates across ALL extra_directories (not just this type)
  const projectType = settings.value.project_types[projectTypeKey]
  if (!projectType || !Array.isArray(projectType.extra_directories)) {
    return null
  }

  // Get all items of the current type
  const itemsOfType = projectType.extra_directories.filter(dir => dir.type === type)

  // Check for duplicates within the same type
  const duplicateInType = itemsOfType.findIndex((item, idx) =>
    idx !== currentIndex && item.key === key
  )
  if (duplicateInType !== -1) {
    return 'Duplicate key within this section'
  }

  // Check for duplicates across different types
  const allOtherItems = projectType.extra_directories.filter(dir => dir.type !== type)
  const duplicateAcrossTypes = allOtherItems.find(item => item.key === key)
  if (duplicateAcrossTypes) {
    return `Key already used in ${duplicateAcrossTypes.type} directories`
  }

  return null
}

const validateExtraDirectoryPath = (path) => {
  if (!path || path.trim() === '') {
    return null // Will be filtered out on save
  }

  // Check for absolute path
  if (path.startsWith('/')) {
    return 'Must be relative (no leading slash)'
  }

  // Check for path traversal
  if (path.includes('..')) {
    return 'Path traversal not allowed (..)'
  }

  return null
}

const validateExtraDirectoryLabel = (label) => {
  if (!label || label.trim() === '') {
    return null // Will be filtered out on save
  }
  return null
}

const saveSettings = async () => {
  try {
    saving.value = true

    const normalizedRoot = settings.value.projects_root?.trim() || ''
    const payload = JSON.parse(JSON.stringify(settings.value))

    // V2 format: projects_root goes under global, not at root
    if (!payload.global) payload.global = {}
    payload.global.projects_root = normalizedRoot ? normalizedRoot : null
    delete payload.projects_root  // Remove root-level if it exists

    payload.defaults.seed = payload.defaults.seed === '' ? null : payload.defaults.seed

    // Handle nested packages structure: { use_renv: bool, default_packages: [...] }
    if (payload.defaults.packages && payload.defaults.packages.default_packages) {
      payload.defaults.packages.default_packages = (payload.defaults.packages.default_packages || []).filter((pkg) => pkg.name && pkg.name.trim() !== '')
    }

    payload.defaults.directories = payload.project_types?.project?.directories || payload.defaults.directories
    payload.defaults.git_hooks.data_security = payload.privacy.secret_scan
    payload.git = payload.git || { user_name: '', user_email: '' }

    // Filter out incomplete extra_directories entries (missing required fields)
    for (const projectTypeKey in payload.project_types) {
      const projectType = payload.project_types[projectTypeKey]
      if (projectType.extra_directories && Array.isArray(projectType.extra_directories)) {
        projectType.extra_directories = projectType.extra_directories.filter(dir => {
          // Keep only entries with all required fields filled
          return dir.key && dir.key.trim() !== '' &&
                 dir.label && dir.label.trim() !== '' &&
                 dir.path && dir.path.trim() !== '' &&
                 dir.type && dir.type.trim() !== ''
        })
      }
    }

    const response = await fetch('/api/settings/save', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })

    if (!response.ok) {
      const errorText = await response.text()
      throw new Error('Failed to save settings')
    }

    const responseData = await response.json()

    const templateResponses = await Promise.all([
      fetch('/api/templates/notebook', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents: templateEditors.notebook.contents })
      }),
      fetch('/api/templates/script', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents: templateEditors.script.contents })
      }),
      fetch('/api/templates/presentation', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents: templateEditors.presentation.contents })
      }),
      fetch('/api/templates/gitignore-project', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents: templateEditors.gitignore_project.contents })
      }),
      fetch('/api/templates/gitignore-project_sensitive', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents: templateEditors.gitignore_project_sensitive.contents })
      }),
      fetch('/api/templates/gitignore-course', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents: templateEditors.gitignore_course.contents })
      }),
      fetch('/api/templates/gitignore-presentation', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents: templateEditors.gitignore_presentation.contents })
      })
    ])

    if (templateResponses.some((res) => !res.ok)) {
      throw new Error('Template save failed')
    }

    toast.success('Settings Saved', 'Your global defaults were updated.')
  } catch (error) {
    console.error('Failed to save settings:', error)
    toast.error('Save Failed', error?.message || 'Review your changes and try again.')
  } finally {
    saving.value = false
  }
}

onMounted(() => {
  loadSettings()
  loadTemplateInline('notebook')
  loadTemplateInline('script')
  loadTemplateInline('presentation')
  loadTemplateInline('gitignore-project', 'gitignore_project')
  loadTemplateInline('gitignore-project_sensitive', 'gitignore_project_sensitive')
  loadTemplateInline('gitignore-course', 'gitignore_course')
  loadTemplateInline('gitignore-presentation', 'gitignore_presentation')
  loadTemplateInline(canonicalTemplateName.value, 'canonical')
  window.addEventListener('keydown', handleKeyDown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown)
})
</script>
