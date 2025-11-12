<template>
  <div class="flex min-h-screen">
    <!-- Left Sidebar -->
    <nav class="w-64 shrink-0 border-r border-gray-200 p-6 dark:border-gray-800">
      <h2 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">New Project</h2>

      <div class="space-y-1 mb-6">
        <template v-for="section in sections" :key="section.id">
          <!-- Add SETTINGS heading before Basics section -->
          <NavigationSectionHeading v-if="section.id === 'basics'">Settings</NavigationSectionHeading>

          <a
            href="#"
            @click.prevent="activeSection = section.id"
            :class="[
              'flex items-center gap-2 px-3 py-2 rounded-md text-sm transition',
              activeSection === section.id
                ? 'bg-sky-50 text-sky-700 font-medium dark:bg-sky-900/20 dark:text-sky-400'
                : 'text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-800'
            ]"
          >
            <component v-if="section.icon" :is="section.icon" class="h-4 w-4" />
            <svg
              v-else-if="section.svgIcon"
              class="h-4 w-4"
              :fill="section.svgFill ?? 'none'"
              :viewBox="section.svgViewBox ?? '0 0 24 24'"
              :stroke="section.svgStroke ?? 'currentColor'"
            >
              <path
                :stroke-linecap="section.svgStrokeLinecap ?? 'round'"
                :stroke-linejoin="section.svgStrokeLinejoin ?? 'round'"
                :stroke-width="section.svgStrokeWidth ?? 2"
                :fill="section.svgPathFill ?? 'none'"
                :d="section.svgIcon"
              />
            </svg>
            {{ section.label }}
          </a>
        </template>
      </div>

      <div class="pt-6 border-t border-gray-200 dark:border-gray-700">
        <Button
          variant="primary"
          size="md"
          class="w-full"
          :disabled="creating || !project.name || !project.location"
          @click="createProject"
        >
          {{ creating ? 'Creating...' : 'Create Project' }}
        </Button>
      </div>
    </nav>

    <!-- Main Content -->
    <div class="flex-1 p-10">
      <PageHeader
        :title="currentSectionTitle"
        :description="currentSectionDescription"
      />

      <div class="mt-8 space-y-6">
        <!-- Overview Section -->
        <div v-show="activeSection === 'overview'">
          <div class="space-y-3">
              <!-- Basics Card -->
              <OverviewCard
                title="Basics"
                @click="activeSection = 'basics'"
              >
                <span class="text-gray-600 dark:text-gray-400">{{ project.name || 'Untitled Project' }}</span>
                <template v-if="project.author.name">
                  <span class="text-gray-400 dark:text-gray-500 mx-1">·</span>
                  <span class="text-gray-600 dark:text-gray-400">{{ project.author.name }}</span>
                </template>
                <span class="text-gray-400 dark:text-gray-500 mx-1">·</span>
                <span class="text-gray-600 dark:text-gray-400">{{ getProjectTypeLabel(project.type) }}</span>
              </OverviewCard>

              <!-- Project Structure Card -->
              <OverviewCard
                title="Project Structure"
                @click="activeSection = 'structure'"
              >
                <span class="text-gray-600 dark:text-gray-400">{{ getProjectTypeLabel(project.type) }}</span>
                <span class="text-gray-400 dark:text-gray-500 mx-1">·</span>
                <span class="text-gray-600 dark:text-gray-400">{{ countDirectoriesByCategory('workspace') }} workspace</span>
                <span class="text-gray-400 dark:text-gray-500 mx-1">·</span>
                <span class="text-gray-600 dark:text-gray-400">{{ countDirectoriesByCategory('input') }} input</span>
                <template v-if="countDirectoriesByCategory('output') > 0">
                  <span class="text-gray-400 dark:text-gray-500 mx-1">·</span>
                  <span class="text-gray-600 dark:text-gray-400">{{ countDirectoriesByCategory('output') }} output</span>
                </template>
              </OverviewCard>

              <!-- Packages Card -->
              <OverviewCard
                title="Packages"
                @click="activeSection = 'packages'"
              >
                <span class="text-gray-600 dark:text-gray-400">
                  renv: {{ project.packages.use_renv ? 'enabled' : 'disabled' }}
                </span>
                <template v-if="project.packages.default_packages && project.packages.default_packages.length > 0">
                  <span class="text-gray-400 dark:text-gray-500 mx-1">·</span>
                  <span class="text-gray-600 dark:text-gray-400">
                    {{ project.packages.default_packages.length }} package{{ project.packages.default_packages.length !== 1 ? 's' : '' }}
                  </span>
                </template>
              </OverviewCard>

              <!-- AI Assistants Card -->
              <OverviewCard
                title="AI Assistants"
                @click="activeSection = 'ai'"
              >
                <template v-if="project.ai.enabled && Array.isArray(project.ai.assistants) && project.ai.assistants.length > 0">
                  {{ project.ai.assistants.map(a => a.charAt(0).toUpperCase() + a.slice(1)).join(', ') }}
                  <span class="text-gray-400 dark:text-gray-500 mx-1">·</span>
                  <span class="text-gray-600 dark:text-gray-400">{{ project.ai.canonical_file }}</span>
                </template>
                <template v-else-if="project.ai.enabled">
                  <span class="text-gray-600 dark:text-gray-400">Enabled (no assistants selected)</span>
                </template>
                <template v-else>
                  <span class="text-gray-600 dark:text-gray-400">Disabled</span>
                </template>
              </OverviewCard>

              <!-- Git & Hooks Card -->
              <OverviewCard
                title="Git & Hooks"
                @click="activeSection = 'git'"
              >
                <span class="text-gray-600 dark:text-gray-400">
                  Git: {{ project.git.initialize ? 'enabled' : 'disabled' }}
                </span>
                <template v-if="project.git.initialize && enabledGitHooks.length > 0">
                  <span class="text-gray-400 dark:text-gray-500 mx-1">·</span>
                  <span class="text-gray-600 dark:text-gray-400">{{ enabledGitHooks.join(', ') }}</span>
                </template>
              </OverviewCard>

              <!-- Connections Card -->
              <OverviewCard
                title="Connections"
                @click="activeSection = 'connections'"
              >
                <template v-if="connectionsSummary.databases > 0 || connectionsSummary.buckets > 0">
                  <span class="text-gray-600 dark:text-gray-400">
                    {{ connectionsSummary.databases }} database{{ connectionsSummary.databases !== 1 ? 's' : '' }}
                  </span>
                  <template v-if="connectionsSummary.buckets > 0">
                    <span class="text-gray-400 dark:text-gray-500 mx-1">·</span>
                    <span class="text-gray-600 dark:text-gray-400">
                      {{ connectionsSummary.buckets }} bucket{{ connectionsSummary.buckets !== 1 ? 's' : '' }}
                    </span>
                  </template>
                </template>
                <template v-else>
                  <span class="text-gray-600 dark:text-gray-400">framework_db only</span>
                </template>
              </OverviewCard>

              <!-- Scaffold Behavior Card -->
              <OverviewCard
                title="Scaffold Behavior"
                @click="activeSection = 'scaffold'"
              >
                <span class="text-gray-600 dark:text-gray-400">
                  <template v-if="project.scaffold.source_all_functions">
                    Functions loaded from <code class="text-xs bg-gray-100 dark:bg-gray-800 px-1 rounded">functions/</code>
                  </template>
                  <template v-else>
                    Does not load functions
                  </template>
                </span>
                <span class="text-gray-400 dark:text-gray-500 mx-1">·</span>
                <span class="text-gray-600 dark:text-gray-400">
                  <template v-if="project.scaffold.set_theme_on_scaffold">
                    ggplot2: {{ (project.scaffold.ggplot_theme || 'theme_minimal').replace('theme_', '') }}
                  </template>
                  <template v-else>
                    No ggplot theme
                  </template>
                </span>
                <span class="text-gray-400 dark:text-gray-500 mx-1">·</span>
                <span class="text-gray-600 dark:text-gray-400">
                  {{ project.scaffold.seed_on_scaffold ? 'Seed: ' + (project.scaffold.seed || 'default') : 'No random seed' }}
                </span>
              </OverviewCard>
            </div>
        </div>

        <!-- Basics Section -->
        <div v-show="activeSection === 'basics'">
          <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
            <div class="space-y-5">
              <Input
                ref="projectNameInput"
                v-model="project.name"
                label="Project Name"
                hint="Human-readable name for your project"
                placeholder="My Analysis Project"
                required
              />

              <Input
                :model-value="project.location"
                @update:modelValue="handleLocationInput"
                label="Project Location"
                hint="Directory where the project will be created"
                placeholder="e.g., ~/projects or /Users/yourname/code"
              />

              <Select
                v-model="project.type"
                label="Project Type"
                hint="Choose the template structure for your project"
              >
                <option value="project">Research Project</option>
                <option value="course">Course</option>
                <option value="presentation">Presentation</option>
              </Select>

              <div>
                <label class="block text-sm font-semibold text-gray-900 dark:text-white mb-3">
                  Supported Editors
                </label>
                <Checkbox
                  v-model="project.scaffold.positron"
                  id="support-positron"
                  description="Enable Positron-specific workspace and settings files"
                >
                  Positron
                </Checkbox>
                <p class="text-sm text-gray-500 dark:text-gray-400 mt-3">
                  RStudio supported by default
                </p>
              </div>

              <Select
                v-model="project.scaffold.notebook_format"
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
                  Author information is embedded in project templates and documentation.
                </p>
                <div class="space-y-5">
                  <Input
                    v-model="project.author.name"
                    label="Your Name"
                    placeholder="Your Name"
                  />
                  <Input
                    v-model="project.author.email"
                    type="email"
                    label="Email"
                    placeholder="your.email@example.com"
                  />
                  <Input
                    v-model="project.author.affiliation"
                    label="Affiliation"
                    placeholder="Organization"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Scaffold Behavior Section -->
        <div v-show="activeSection === 'scaffold'">
          <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50 space-y-6">
            <div>
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">
                Scaffold Behavior
              </h3>
              <p class="text-sm text-gray-600 dark:text-gray-400">
                Automatic actions when <code class="px-1.5 py-0.5 bg-gray-200 dark:bg-gray-700 rounded text-xs">scaffold()</code> runs to initialize your project environment.
              </p>
            </div>

            <ScaffoldBehaviorPanel v-model="project.scaffold" flush />
          </div>
        </div>

        <!-- Project Structure Section -->
        <div v-show="activeSection === 'structure'" class="space-y-6">
            <!-- Project Type Selection -->
            <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <RadioGroup
                legend="Project Type"
                description="Select a project type to customize the directory structure."
              >
                <Radio v-model="project.type" id="type-project" name="project-type" value="project">
                  <div>
                    <div class="font-medium text-sm">Research Project</div>
                    <div class="text-xs text-gray-600 dark:text-gray-400 mt-0.5">
                      Full-featured with organized data, work, and output directories
                    </div>
                  </div>
                </Radio>
                <Radio v-model="project.type" id="type-sensitive" name="project-type" value="project_sensitive">
                  <div>
                    <div class="font-medium text-sm">Privacy Sensitive Project</div>
                    <div class="text-xs text-gray-600 dark:text-gray-400 mt-0.5">
                      Enhanced privacy controls with separate private/public flows
                    </div>
                  </div>
                </Radio>
                <Radio v-model="project.type" id="type-presentation" name="project-type" value="presentation">
                  <div>
                    <div class="font-medium text-sm">Presentation</div>
                    <div class="text-xs text-gray-600 dark:text-gray-400 mt-0.5">
                      Minimal structure for slides and presentations
                    </div>
                  </div>
                </Radio>
                <Radio v-model="project.type" id="type-course" name="project-type" value="course">
                  <div>
                    <div class="font-medium text-sm">Course/Teaching</div>
                    <div class="text-xs text-gray-600 dark:text-gray-400 mt-0.5">
                      Simplified structure for teaching materials
                    </div>
                  </div>
                </Radio>
              </RadioGroup>
            </div>

            <!-- Presentation Source File (only for presentation type) -->
            <div v-if="project.type === 'presentation'" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">Presentation File</h3>
              <Input
                v-model="project.directories.presentation_source"
                label="Presentation source file"
                placeholder="presentation.qmd"
                hint="Main Quarto file for your slides"
              />
            </div>

            <!-- Directories - Research Project -->
            <!-- Workspaces -->
            <div v-if="project.type === 'project'" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Workspaces</h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">Functions, notebooks, and scripts scaffolded into every project.</p>
              <div class="space-y-3">
                  <!-- Default directories -->
                  <div
                    v-for="dirKey in ['functions', 'notebooks', 'scripts']"
                    :key="dirKey"
                  >
                    <Toggle
                      :id="`dir-${dirKey}`"
                      v-model="project.directories_enabled[dirKey]"
                      :label="currentProjectTypeDirectories[dirKey]?.label || dirKey"
                      :description="currentProjectTypeDirectories[dirKey]?.hint"
                      class="mb-2"
                    />
                    <Input
                      v-if="project.directories_enabled[dirKey]"
                      v-model="project.directories[dirKey]"
                      :placeholder="currentProjectTypeDirectories[dirKey]?.default"
                      prefix="/"
                    />
                  </div>

                  <!-- Custom directories from global settings -->
                  <div
                    v-for="dir in globalExtraDirectoriesByType('workspace')"
                    :key="`extra-${dir.key}`"
                  >
                    <Toggle
                      :id="`extra-dir-${dir.key}`"
                      v-model="project.extra_directories_enabled[dir.key]"
                      :label="dir.label"
                      :description="`Custom: ${dir.path}`"
                      class="mb-2"
                    />
                    <Input
                      v-if="project.extra_directories_enabled[dir.key]"
                      v-model="dir.path"
                      :placeholder="dir.path"
                      prefix="/"
                      monospace
                    />
                  </div>
                </div>

              <!-- Add project-specific custom directories -->
              <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Add Custom Workspace Directories</h4>
                <p class="text-xs text-gray-600 dark:text-gray-400 mb-3">Add directories specific to this project only.</p>
                <Repeater
                  :model-value="projectExtraDirectoriesByType('workspace')"
                  @update:model-value="updateProjectExtraDirectories('workspace', $event)"
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

            <!-- Inputs -->
            <div v-if="project.type === 'project'" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Inputs</h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">Define the read-only locations where raw and prepared data live.</p>
              <div class="space-y-3">
                  <!-- Default directories -->
                  <div
                    v-for="dirKey in ['inputs_raw', 'inputs_intermediate', 'inputs_final', 'reference']"
                    :key="dirKey"
                  >
                    <Toggle
                      :id="`dir-${dirKey}`"
                      v-model="project.directories_enabled[dirKey]"
                      :label="currentProjectTypeDirectories[dirKey]?.label || dirKey"
                      :description="currentProjectTypeDirectories[dirKey]?.hint"
                      class="mb-2"
                    />
                    <Input
                      v-if="project.directories_enabled[dirKey]"
                      v-model="project.directories[dirKey]"
                      :placeholder="currentProjectTypeDirectories[dirKey]?.default"
                      prefix="/"
                    />
                  </div>

                  <!-- Custom directories from global settings -->
                  <div
                    v-for="dir in globalExtraDirectoriesByType('input')"
                    :key="`extra-${dir.key}`"
                  >
                    <Toggle
                      :id="`extra-dir-${dir.key}`"
                      v-model="project.extra_directories_enabled[dir.key]"
                      :label="dir.label"
                      :description="`Custom: ${dir.path}`"
                      class="mb-2"
                    />
                    <Input
                      v-if="project.extra_directories_enabled[dir.key]"
                      v-model="dir.path"
                      :placeholder="dir.path"
                      prefix="/"
                      monospace
                    />
                  </div>
                </div>

              <!-- Add project-specific custom directories -->
              <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Add Custom Input Directories</h4>
                <p class="text-xs text-gray-600 dark:text-gray-400 mb-3">Add directories specific to this project only.</p>
                <Repeater
                  :model-value="projectExtraDirectoriesByType('input')"
                  @update:model-value="updateProjectExtraDirectories('input', $event)"
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

            <!-- Outputs -->
            <div v-if="project.type === 'project'" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Outputs</h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">Outputs are public by default so results are easy to share.</p>
              <div class="space-y-3">
                  <!-- Default directories -->
                  <div
                    v-for="dirKey in ['outputs_notebooks', 'outputs_tables', 'outputs_figures', 'outputs_models', 'outputs_reports']"
                    :key="dirKey"
                  >
                    <Toggle
                      :id="`dir-${dirKey}`"
                      v-model="project.directories_enabled[dirKey]"
                      :label="currentProjectTypeDirectories[dirKey]?.label || dirKey"
                      :description="currentProjectTypeDirectories[dirKey]?.hint"
                      class="mb-2"
                    />
                    <Input
                      v-if="project.directories_enabled[dirKey]"
                      v-model="project.directories[dirKey]"
                      :placeholder="currentProjectTypeDirectories[dirKey]?.default"
                      prefix="/"
                    />
                  </div>

                  <!-- Custom directories from global settings -->
                  <div v-for="dir in globalExtraDirectoriesByType('output')" :key="`extra-${dir.key}`">
                    <Toggle
                      :id="`extra-${dir.key}`"
                      v-model="project.extra_directories_enabled[dir.key]"
                      :label="dir.label"
                      class="mb-2"
                    />
                    <Input
                      v-if="project.extra_directories_enabled[dir.key]"
                      v-model="dir.path"
                      :placeholder="dir.path"
                      prefix="/"
                    />
                  </div>
                </div>

              <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Add Custom Output Directories</h4>
                <Repeater
                  :model-value="projectExtraDirectoriesByType('output')"
                  @update:model-value="updateProjectExtraDirectories('output', $event)"
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

            <!-- Temporary -->
            <div v-if="project.type === 'project'" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Temporary</h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">Scratch space and cache (gitignored by default).</p>
              <div class="space-y-3">
                  <!-- Default directories -->
                  <div
                    v-for="dirKey in ['cache', 'scratch']"
                    :key="dirKey"
                  >
                    <Toggle
                      :id="`dir-${dirKey}`"
                      v-model="project.directories_enabled[dirKey]"
                      :label="currentProjectTypeDirectories[dirKey]?.label || dirKey"
                      :description="currentProjectTypeDirectories[dirKey]?.hint"
                      class="mb-2"
                    />
                    <Input
                      v-if="project.directories_enabled[dirKey]"
                      v-model="project.directories[dirKey]"
                      :placeholder="currentProjectTypeDirectories[dirKey]?.default"
                      prefix="/"
                    />
                  </div>

                  <!-- Custom directories from global settings -->
                  <div v-for="dir in globalExtraDirectoriesByType('temporary')" :key="`extra-${dir.key}`">
                    <Toggle
                      :id="`extra-${dir.key}`"
                      v-model="project.extra_directories_enabled[dir.key]"
                      :label="dir.label"
                      class="mb-2"
                    />
                    <Input
                      v-if="project.extra_directories_enabled[dir.key]"
                      v-model="dir.path"
                      :placeholder="dir.path"
                      prefix="/"
                    />
                  </div>
                </div>

              <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Add Custom Temporary Directories</h4>
                <Repeater
                  :model-value="projectExtraDirectoriesByType('temporary')"
                  @update:model-value="updateProjectExtraDirectories('temporary', $event)"
                  add-label="Add Temporary Directory"
                  :default-item="() => ({ key: '', label: '', path: '', type: 'temporary', _id: Date.now() })"
                >
                  <template #default="{ item, index, update }">
                    <div class="grid grid-cols-2 gap-3">
                      <Input
                        :model-value="item.key"
                        @update:model-value="update('key', $event)"
                        label="Key"
                        placeholder="e.g., temp_downloads"
                        monospace
                        size="sm"
                      />
                      <Input
                        :model-value="item.label"
                        @update:model-value="update('label', $event)"
                        label="Label"
                        placeholder="e.g., Downloads"
                        size="sm"
                      />
                      <Input
                        :model-value="item.path"
                        @update:model-value="update('path', $event)"
                        label="Path"
                        placeholder="e.g., temp/downloads"
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

            <!-- Directories - Course/Teaching -->
            <!-- Course Materials -->
            <div v-if="project.type === 'course'" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Course Materials</h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">Slides, assignments, readings, and documentation.</p>
                <div class="space-y-3">
                  <div
                    v-for="dirKey in ['slides', 'assignments', 'readings', 'course_docs']"
                    :key="dirKey"
                  >
                    <Toggle
                      :id="`dir-${dirKey}`"
                      v-model="project.directories_enabled[dirKey]"
                      :label="currentProjectTypeDirectories[dirKey]?.label || dirKey"
                      :description="currentProjectTypeDirectories[dirKey]?.hint"
                      class="mb-2"
                    />
                    <Input
                      v-if="project.directories_enabled[dirKey]"
                      v-model="project.directories[dirKey]"
                      :placeholder="currentProjectTypeDirectories[dirKey]?.default"
                      prefix="/"
                    />
                  </div>

                  <!-- Custom directories from global settings -->
                  <div v-for="dir in globalExtraDirectoriesByType('workspace')" :key="`extra-${dir.key}`">
                    <Toggle
                      :id="`extra-dir-${dir.key}`"
                      v-model="project.extra_directories_enabled[dir.key]"
                      :label="dir.label"
                      :description="`Custom: ${dir.path}`"
                      class="mb-2"
                    />
                    <Input
                      v-if="project.extra_directories_enabled[dir.key]"
                      v-model="dir.path"
                      :placeholder="dir.path"
                      prefix="/"
                      monospace
                    />
                  </div>
                </div>

              <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Add Custom Directories</h4>
                <Repeater
                  :model-value="projectExtraDirectoriesByType('workspace')"
                  @update:model-value="updateProjectExtraDirectories('workspace', $event)"
                  add-label="Add Directory"
                  :default-item="() => ({ key: '', label: '', path: '', type: 'workspace', _id: Date.now() })"
                >
                  <template #default="{ item, index, update }">
                    <div class="grid grid-cols-2 gap-3">
                      <Input
                        :model-value="item.key"
                        @update:model-value="update('key', $event)"
                        label="Key"
                        placeholder="e.g., exercises"
                        monospace
                        size="sm"
                      />
                      <Input
                        :model-value="item.label"
                        @update:model-value="update('label', $event)"
                        label="Label"
                        placeholder="e.g., Exercises"
                        size="sm"
                      />
                      <Input
                        :model-value="item.path"
                        @update:model-value="update('path', $event)"
                        label="Path"
                        placeholder="e.g., exercises"
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

            <!-- Workspaces -->
            <div v-if="project.type === 'course'" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Workspaces</h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">Module notebooks, functions, and scripts.</p>
                <div class="space-y-3">
                  <div
                    v-for="dirKey in ['notebooks', 'functions', 'scripts']"
                    :key="dirKey"
                  >
                    <Toggle
                      :id="`dir-${dirKey}`"
                      v-model="project.directories_enabled[dirKey]"
                      :label="currentProjectTypeDirectories[dirKey]?.label || dirKey"
                      :description="currentProjectTypeDirectories[dirKey]?.hint"
                      class="mb-2"
                    />
                    <Input
                      v-if="project.directories_enabled[dirKey]"
                      v-model="project.directories[dirKey]"
                      :placeholder="currentProjectTypeDirectories[dirKey]?.default"
                      prefix="/"
                    />
                  </div>
                </div>
              </div>

            <!-- Data & Storage -->
            <div v-if="project.type === 'course'" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Data & Storage</h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">Course datasets and temporary files.</p>
                <div class="space-y-3">
                  <div
                    v-for="dirKey in ['data', 'inputs', 'outputs', 'cache']"
                    :key="dirKey"
                  >
                    <Toggle
                      :id="`dir-${dirKey}`"
                      v-model="project.directories_enabled[dirKey]"
                      :label="currentProjectTypeDirectories[dirKey]?.label || dirKey"
                      :description="currentProjectTypeDirectories[dirKey]?.hint"
                      class="mb-2"
                    />
                    <Input
                      v-if="project.directories_enabled[dirKey]"
                      v-model="project.directories[dirKey]"
                      :placeholder="currentProjectTypeDirectories[dirKey]?.default"
                      prefix="/"
                    />
                  </div>
                </div>
              </div>

            <!-- Directories - Presentation (simpler, fewer dirs) -->
            <!-- Optional Directories -->
            <div v-if="project.type === 'presentation'" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Optional Directories</h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">Add supporting directories for data, scripts, or helper functions.</p>
                <div class="space-y-3">
                  <div
                    v-for="dirKey in ['data', 'scripts', 'functions']"
                    :key="dirKey"
                  >
                    <Toggle
                      :id="`dir-${dirKey}`"
                      v-model="project.directories_enabled[dirKey]"
                      :label="currentProjectTypeDirectories[dirKey]?.label || dirKey"
                      :description="currentProjectTypeDirectories[dirKey]?.hint"
                      class="mb-2"
                    />
                    <Input
                      v-if="project.directories_enabled[dirKey]"
                      v-model="project.directories[dirKey]"
                      :placeholder="currentProjectTypeDirectories[dirKey]?.default"
                      prefix="/"
                    />
                  </div>

                  <!-- Custom directories from global settings -->
                  <div v-for="dir in globalExtraDirectoriesByType('workspace')" :key="`extra-${dir.key}`">
                    <Toggle
                      :id="`extra-dir-${dir.key}`"
                      v-model="project.extra_directories_enabled[dir.key]"
                      :label="dir.label"
                      :description="`Custom: ${dir.path}`"
                      class="mb-2"
                    />
                    <Input
                      v-if="project.extra_directories_enabled[dir.key]"
                      v-model="dir.path"
                      :placeholder="dir.path"
                      prefix="/"
                      monospace
                    />
                  </div>
                </div>

              <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Add Custom Directories</h4>
                <Repeater
                  :model-value="projectExtraDirectoriesByType('workspace')"
                  @update:model-value="updateProjectExtraDirectories('workspace', $event)"
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

            <!-- Directories - Sensitive (two-column layout) -->
            <!-- Work Directories -->
            <div v-if="project.type === 'project_sensitive'" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Work Directories</h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">Module locations for notebooks, scripts, and helper functions.</p>
              <div class="space-y-3">
                <!-- Default directories -->
                <div
                  v-for="dirKey in ['functions', 'notebooks', 'scripts']"
                  :key="dirKey"
                >
                    <div class="flex items-start gap-3 mb-2">
                      <Toggle
                        :id="`dir-${dirKey}`"
                        v-model="project.directories_enabled[dirKey]"
                        :label="currentProjectTypeDirectories[dirKey]?.label || dirKey"
                        :description="currentProjectTypeDirectories[dirKey]?.hint"
                        class="flex-1"
                      />
                    </div>
                    <Input
                      v-if="project.directories_enabled[dirKey]"
                      v-model="project.directories[dirKey]"
                      :placeholder="currentProjectTypeDirectories[dirKey]?.default"
                      class="mt-2"
                      prefix="/"
                    />
                  </div>

                <!-- Custom directories from global settings -->
                <div v-for="dir in globalExtraDirectoriesByType('workspace')" :key="`extra-${dir.key}`">
                  <Toggle
                    :id="`extra-dir-${dir.key}`"
                    v-model="project.extra_directories_enabled[dir.key]"
                    :label="dir.label"
                    :description="`Custom: ${dir.path}`"
                    class="mb-2"
                  />
                  <Input
                    v-if="project.extra_directories_enabled[dir.key]"
                    v-model="dir.path"
                    :placeholder="dir.path"
                    prefix="/"
                    monospace
                  />
                </div>
                </div>

              <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Add Custom Workspace Directories</h4>
                <Repeater
                  :model-value="projectExtraDirectoriesByType('workspace')"
                  @update:model-value="updateProjectExtraDirectories('workspace', $event)"
                  add-label="Add Workspace Directory"
                  :default-item="() => ({ key: '', label: '', path: '', type: 'workspace', _id: Date.now() })"
                >
                  <template #default="{ item, index, update }">
                    <div class="grid grid-cols-2 gap-3">
                      <Input
                        :model-value="item.key"
                        @update:model-value="update('key', $event)"
                        label="Key"
                        placeholder="e.g., helpers"
                        monospace
                        size="sm"
                      />
                      <Input
                        :model-value="item.label"
                        @update:model-value="update('label', $event)"
                        label="Label"
                        placeholder="e.g., Helper Functions"
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
                        class="col-span-2"
                      />
                    </div>
                  </template>
                </Repeater>
              </div>
            </div>

            <!-- Inputs (Private/Public) -->
            <div v-if="project.type === 'project_sensitive'" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Inputs</h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                Keep private inputs compartmentalized; publish processed data into public folders when ready.
              </p>
                <div class="grid gap-4 sm:grid-cols-2 text-xs font-semibold uppercase text-gray-500 dark:text-gray-400 mb-3">
                  <div>Private</div>
                  <div>Public</div>
                </div>
                <div class="space-y-4">
                  <div
                    v-for="stage in ['raw', 'intermediate', 'final']"
                    :key="stage"
                  >
                    <div class="grid gap-4 sm:grid-cols-2">
                      <div class="p-3 rounded-md">
                        <Toggle
                          :id="`dir-inputs_private_${stage}`"
                          v-model="project.directories_enabled[`inputs_private_${stage}`]"
                          :label="`${stage.charAt(0).toUpperCase() + stage.slice(1)} data`"
                          class="mb-2"
                        />
                        <Input
                          v-if="project.directories_enabled[`inputs_private_${stage}`]"
                          v-model="project.directories[`inputs_private_${stage}`]"
                          :placeholder="`inputs/private/${stage}`"
                          prefix="/"
                        />
                      </div>
                      <div class="p-3 rounded-md">
                        <Toggle
                          :id="`dir-inputs_public_${stage}`"
                          v-model="project.directories_enabled[`inputs_public_${stage}`]"
                          :label="`${stage.charAt(0).toUpperCase() + stage.slice(1)} data`"
                          class="mb-2"
                        />
                        <Input
                          v-if="project.directories_enabled[`inputs_public_${stage}`]"
                          v-model="project.directories[`inputs_public_${stage}`]"
                          :placeholder="`inputs/public/${stage}`"
                          prefix="/"
                        />
                      </div>
                    </div>
                  </div>

                  <!-- Custom directories from global settings -->
                  <div class="grid gap-4 sm:grid-cols-2">
                    <div class="space-y-3">
                      <div v-for="dir in globalExtraDirectoriesByType('input_private')" :key="`extra-${dir.key}`" class="p-3 rounded-md">
                        <Toggle
                          :id="`extra-dir-${dir.key}`"
                          v-model="project.extra_directories_enabled[dir.key]"
                          :label="dir.label"
                          :description="`Custom: ${dir.path}`"
                          class="mb-2"
                        />
                        <Input
                          v-if="project.extra_directories_enabled[dir.key]"
                          v-model="dir.path"
                          :placeholder="dir.path"
                          prefix="/"
                          monospace
                        />
                      </div>
                    </div>
                    <div class="space-y-3">
                      <div v-for="dir in globalExtraDirectoriesByType('input_public')" :key="`extra-${dir.key}`" class="p-3 rounded-md">
                        <Toggle
                          :id="`extra-dir-${dir.key}`"
                          v-model="project.extra_directories_enabled[dir.key]"
                          :label="dir.label"
                          :description="`Custom: ${dir.path}`"
                          class="mb-2"
                        />
                        <Input
                          v-if="project.extra_directories_enabled[dir.key]"
                          v-model="dir.path"
                          :placeholder="dir.path"
                          prefix="/"
                          monospace
                        />
                      </div>
                    </div>
                  </div>
                </div>

              <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-4">Add Custom Input Directories</h4>
                <div class="grid gap-6 sm:grid-cols-2">
                  <div>
                    <p class="text-xs font-semibold uppercase text-gray-500 dark:text-gray-400 mb-3">Private</p>
                    <Repeater
                      :model-value="projectExtraDirectoriesByType('input_private')"
                      @update:model-value="updateProjectExtraDirectories('input_private', $event)"
                      add-label="Add Private Input"
                      :default-item="() => ({ key: '', label: '', path: '', type: 'input_private', _id: Date.now() })"
                    >
                      <template #default="{ item, index, update }">
                        <div class="space-y-2">
                          <Input
                            :model-value="item.key"
                            @update:model-value="update('key', $event)"
                            label="Key"
                            placeholder="e.g., inputs_private_survey"
                            monospace
                            size="sm"
                          />
                          <Input
                            :model-value="item.label"
                            @update:model-value="update('label', $event)"
                            label="Label"
                            placeholder="e.g., Survey Data"
                            size="sm"
                          />
                          <Input
                            :model-value="item.path"
                            @update:model-value="update('path', $event)"
                            label="Path"
                            placeholder="e.g., inputs/private/survey"
                            prefix="/"
                            monospace
                            size="sm"
                          />
                        </div>
                      </template>
                    </Repeater>
                  </div>
                  <div>
                    <p class="text-xs font-semibold uppercase text-gray-500 dark:text-gray-400 mb-3">Public</p>
                    <Repeater
                      :model-value="projectExtraDirectoriesByType('input_public')"
                      @update:model-value="updateProjectExtraDirectories('input_public', $event)"
                      add-label="Add Public Input"
                      :default-item="() => ({ key: '', label: '', path: '', type: 'input_public', _id: Date.now() })"
                    >
                      <template #default="{ item, index, update }">
                        <div class="space-y-2">
                          <Input
                            :model-value="item.key"
                            @update:model-value="update('key', $event)"
                            label="Key"
                            placeholder="e.g., inputs_public_survey"
                            monospace
                            size="sm"
                          />
                          <Input
                            :model-value="item.label"
                            @update:model-value="update('label', $event)"
                            label="Label"
                            placeholder="e.g., Survey Data"
                            size="sm"
                          />
                          <Input
                            :model-value="item.path"
                            @update:model-value="update('path', $event)"
                            label="Path"
                            placeholder="e.g., inputs/public/survey"
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

            <!-- Outputs (Private/Public) -->
            <div v-if="project.type === 'project_sensitive'" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Outputs</h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                Review outputs before promotion; private folders remain gitignored while public copies are ready to share.
              </p>
                <div class="grid gap-4 sm:grid-cols-2 text-xs font-semibold uppercase text-gray-500 dark:text-gray-400 mb-3">
                  <div>Private</div>
                  <div>Public</div>
                </div>
                <div class="space-y-4">
                  <div
                    v-for="outType in ['notebooks', 'tables', 'figures', 'models', 'reports']"
                    :key="outType"
                  >
                    <div class="grid gap-4 sm:grid-cols-2">
                      <div class="p-3 rounded-md">
                        <Toggle
                          :id="`dir-outputs_private_${outType}`"
                          v-model="project.directories_enabled[`outputs_private_${outType}`]"
                          :label="outType.replace('_', ' ').charAt(0).toUpperCase() + outType.replace('_', ' ').slice(1)"
                          class="mb-2"
                        />
                        <Input
                          v-if="project.directories_enabled[`outputs_private_${outType}`]"
                          v-model="project.directories[`outputs_private_${outType}`]"
                          :placeholder="`outputs/private/${outType}`"
                          prefix="/"
                        />
                      </div>
                      <div class="p-3 rounded-md">
                        <Toggle
                          :id="`dir-outputs_public_${outType}`"
                          v-model="project.directories_enabled[`outputs_public_${outType}`]"
                          :label="outType.replace('_', ' ').charAt(0).toUpperCase() + outType.replace('_', ' ').slice(1)"
                          class="mb-2"
                        />
                        <Input
                          v-if="project.directories_enabled[`outputs_public_${outType}`]"
                          v-model="project.directories[`outputs_public_${outType}`]"
                          :placeholder="`outputs/public/${outType}`"
                          prefix="/"
                        />
                      </div>
                    </div>
                  </div>

                  <!-- Custom directories from global settings -->
                  <div class="grid gap-4 sm:grid-cols-2">
                    <div class="space-y-3">
                      <div v-for="dir in globalExtraDirectoriesByType('output_private')" :key="`extra-${dir.key}`" class="p-3 rounded-md">
                        <Toggle
                          :id="`extra-dir-${dir.key}`"
                          v-model="project.extra_directories_enabled[dir.key]"
                          :label="dir.label"
                          :description="`Custom: ${dir.path}`"
                          class="mb-2"
                        />
                        <Input
                          v-if="project.extra_directories_enabled[dir.key]"
                          v-model="dir.path"
                          :placeholder="dir.path"
                          prefix="/"
                          monospace
                        />
                      </div>
                    </div>
                    <div class="space-y-3">
                      <div v-for="dir in globalExtraDirectoriesByType('output_public')" :key="`extra-${dir.key}`" class="p-3 rounded-md">
                        <Toggle
                          :id="`extra-dir-${dir.key}`"
                          v-model="project.extra_directories_enabled[dir.key]"
                          :label="dir.label"
                          :description="`Custom: ${dir.path}`"
                          class="mb-2"
                        />
                        <Input
                          v-if="project.extra_directories_enabled[dir.key]"
                          v-model="dir.path"
                          :placeholder="dir.path"
                          prefix="/"
                          monospace
                        />
                      </div>
                    </div>
                  </div>
                </div>

              <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-4">Add Custom Output Directories</h4>
                <div class="grid gap-6 sm:grid-cols-2">
                  <div>
                    <p class="text-xs font-semibold uppercase text-gray-500 dark:text-gray-400 mb-3">Private</p>
                    <Repeater
                      :model-value="projectExtraDirectoriesByType('output_private')"
                      @update:model-value="updateProjectExtraDirectories('output_private', $event)"
                      add-label="Add Private Output"
                      :default-item="() => ({ key: '', label: '', path: '', type: 'output_private', _id: Date.now() })"
                    >
                      <template #default="{ item, index, update }">
                        <div class="space-y-2">
                          <Input
                            :model-value="item.key"
                            @update:model-value="update('key', $event)"
                            label="Key"
                            placeholder="e.g., outputs_private_videos"
                            monospace
                            size="sm"
                          />
                          <Input
                            :model-value="item.label"
                            @update:model-value="update('label', $event)"
                            label="Label"
                            placeholder="e.g., Videos"
                            size="sm"
                          />
                          <Input
                            :model-value="item.path"
                            @update:model-value="update('path', $event)"
                            label="Path"
                            placeholder="e.g., outputs/private/videos"
                            prefix="/"
                            monospace
                            size="sm"
                          />
                        </div>
                      </template>
                    </Repeater>
                  </div>
                  <div>
                    <p class="text-xs font-semibold uppercase text-gray-500 dark:text-gray-400 mb-3">Public</p>
                    <Repeater
                      :model-value="projectExtraDirectoriesByType('output_public')"
                      @update:model-value="updateProjectExtraDirectories('output_public', $event)"
                      add-label="Add Public Output"
                      :default-item="() => ({ key: '', label: '', path: '', type: 'output_public', _id: Date.now() })"
                    >
                      <template #default="{ item, index, update }">
                        <div class="space-y-2">
                          <Input
                            :model-value="item.key"
                            @update:model-value="update('key', $event)"
                            label="Key"
                            placeholder="e.g., outputs_public_videos"
                            monospace
                            size="sm"
                          />
                          <Input
                            :model-value="item.label"
                            @update:model-value="update('label', $event)"
                            label="Label"
                            placeholder="e.g., Videos"
                            size="sm"
                          />
                          <Input
                            :model-value="item.path"
                            @update:model-value="update('path', $event)"
                            label="Path"
                            placeholder="e.g., outputs/public/videos"
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

            <!-- Cache & Scratch -->
            <div v-if="project.type === 'project_sensitive'" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Temporary</h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">Scratch space and cache (gitignored by default).</p>
              <div class="space-y-3">
                <div
                  v-for="dirKey in ['cache', 'scratch']"
                  :key="dirKey"
                  v-show="currentProjectTypeDirectories[dirKey]"
                >
                    <div class="flex items-start gap-3 mb-2">
                      <Toggle
                        :id="`dir-${dirKey}`"
                        v-model="project.directories_enabled[dirKey]"
                        :label="currentProjectTypeDirectories[dirKey]?.label"
                        :description="currentProjectTypeDirectories[dirKey]?.hint"
                        class="flex-1"
                      />
                    </div>
                    <Input
                      v-if="project.directories_enabled[dirKey]"
                      v-model="project.directories[dirKey]"
                      :placeholder="currentProjectTypeDirectories[dirKey]?.default"
                      class="mt-2"
                      prefix="/"
                    />
                  </div>
                </div>
            </div>

            <!-- .gitignore Template -->
            <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">.gitignore Template</h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                Customize the .gitignore template for this project type. Uses pattern-based matching to catch sensitive directories anywhere in your project tree.
              </p>
              <CodeEditor
                v-model="project.git.gitignore_content"
                language="gitignore"
                class="mb-4"
              />
              <Button
                variant="secondary"
                size="sm"
                @click="resetGitignoreTemplate"
              >
                Restore Default
              </Button>
            </div>
        </div>

        <!-- Connections Section -->
        <div v-show="activeSection === 'connections'">
          <ConnectionsPanel
            v-model:database-connections="project.connections.databaseConnections"
            v-model:s3-connections="project.connections.s3Connections"
            v-model:default-database="project.connections.defaultDatabase"
            v-model:default-storage-bucket="project.connections.defaultStorageBucket"
          />
        </div>

        <!-- Packages Section -->
        <div v-show="activeSection === 'packages'">
          <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
            <div class="space-y-5">
              <Toggle
                v-model="project.packages.use_renv"
                label="Enable renv"
                description="Use renv for package version management and reproducibility"
              />

              <div class="pt-4 border-t border-gray-200 dark:border-gray-700">
                <div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between mb-4">
                  <div>
                    <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300">Default Packages</h4>
                    <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">Installed (and optionally attached) when scaffold() runs.</p>
                  </div>
                  <Button size="sm" variant="secondary" @click="addPackage">Add Package</Button>
                </div>

                <div class="space-y-3" v-if="project.packages.default_packages && project.packages.default_packages.length">
                  <div
                    v-for="(pkg, idx) in project.packages.default_packages"
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

                <p v-else class="text-xs text-gray-500 dark:text-gray-400">No packages configured. Add packages to include tidyverse helpers or internal utilities automatically.</p>
              </div>
            </div>
          </div>
        </div>

        <!-- AI Assistants Section -->
        <div v-show="activeSection === 'ai'">
          <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
            <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
              Framework maintains context files for selected assistants and keeps them in sync before commits.
            </p>

            <div class="space-y-6">
              <div>
                <Toggle
                  v-model="project.ai.enabled"
                  label="Enable AI Support"
                  description="Generate and sync assistant-specific context files."
                />
              </div>

              <template v-if="project.ai.enabled">
                <div class="pt-6 border-t border-gray-200 dark:border-gray-700">
                  <h4 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Canonical context file</h4>
                  <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                    This file is the source of truth; other instructions files are synced to it when AI hooks run.
                  </p>
                  <Select
                    v-model="project.ai.canonical_file"
                    label="Canonical Context File"
                  >
                    <option value="AGENTS.md">AGENTS.md (multi-agent orchestrator)</option>
                    <option value="CLAUDE.md">CLAUDE.md</option>
                    <option value=".github/copilot-instructions.md">.github/copilot-instructions.md</option>
                  </Select>
                </div>

                <div class="pt-6 border-t border-gray-200 dark:border-gray-700">
                  <h4 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Assistants</h4>
                  <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                    Choose which assistants receive context updates.
                  </p>
                  <div class="space-y-2">
                    <Checkbox
                      v-for="assistant in availableAssistants"
                      :key="assistant.id"
                      :id="`ai-${assistant.id}`"
                      :model-value="Array.isArray(project.ai.assistants) && project.ai.assistants.includes(assistant.id)"
                      @update:model-value="toggleAssistant(assistant.id, $event)"
                      :description="assistant.description"
                    >
                      {{ assistant.label }}
                    </Checkbox>
                  </div>
                </div>

                <div class="pt-6 border-t border-gray-200 dark:border-gray-700">
                  <h4 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Canonical instructions</h4>
                  <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                    Edit the canonical file directly. This will be pre-populated when the project is created.
                  </p>
                  <CodeEditor
                    v-model="project.ai.canonical_content"
                    language="markdown"
                    min-height="500px"
                  />
                </div>
              </template>
            </div>
          </div>
        </div>

        <!-- Git & Hooks Section -->
        <div v-show="activeSection === 'git'">
          <GitHooksPanel v-model="gitPanelModel">
            <template #note>
              Project-specific .gitignore templates can be customized in Project Defaults.
            </template>
          </GitHooksPanel>
        </div>

      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import PageHeader from '../components/ui/PageHeader.vue'
import Input from '../components/ui/Input.vue'
import Select from '../components/ui/Select.vue'
import Toggle from '../components/ui/Toggle.vue'
import Button from '../components/ui/Button.vue'
import Radio from '../components/ui/Radio.vue'
import RadioGroup from '../components/ui/RadioGroup.vue'
import Checkbox from '../components/ui/Checkbox.vue'
import Repeater from '../components/ui/Repeater.vue'
import CodeEditor from '../components/ui/CodeEditor.vue'
import PackageAutocomplete from '../components/ui/PackageAutocomplete.vue'
import OverviewCard from '../components/ui/OverviewCard.vue'
import NavigationSectionHeading from '../components/ui/NavigationSectionHeading.vue'
import GitHooksPanel from '../components/settings/GitHooksPanel.vue'
import ScaffoldBehaviorPanel from '../components/settings/ScaffoldBehaviorPanel.vue'
import ConnectionsPanel from '../components/settings/ConnectionsPanel.vue'
import { useToast } from '../composables/useToast'
import {
  InformationCircleIcon,
  UserIcon,
  FolderIcon,
  CubeIcon,
  DocumentCheckIcon,
  Cog6ToothIcon,
  ServerStackIcon
} from '@heroicons/vue/24/outline'

const router = useRouter()
const route = useRoute()
const toast = useToast()

const globalSettings = ref(null)
const settingsCatalog = ref(null)
const loading = ref(true)

const availableAssistants = [
  { id: 'claude', label: 'Claude Code', description: "Anthropic's IDE-focused assistant." },
  { id: 'copilot', label: 'GitHub Copilot', description: 'Complements VS Code and JetBrains editors.' },
  { id: 'agents', label: 'Multi-Agent (OpenAI Codex, Cursor, etc.)', description: 'Shared instructions for multi-model orchestrators.' }
]

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

const ensureAiAssistantsArray = () => {
  if (!Array.isArray(project.value.ai.assistants)) {
    project.value.ai.assistants = normalizeAssistantList(project.value.ai.assistants)
  }
}

const sections = [
  { id: 'overview', label: 'Overview', icon: InformationCircleIcon },
  { id: 'basics', label: 'Basics', icon: Cog6ToothIcon },
  { id: 'structure', label: 'Project Structure', icon: FolderIcon },
  { id: 'packages', label: 'Packages', icon: CubeIcon },
  { id: 'ai', label: 'AI Assistants', svgIcon: 'M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z' },
  { id: 'git', label: 'Git & Hooks', svgIcon: 'M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4' },
  { id: 'connections', label: 'Connections', icon: ServerStackIcon },
  {
    id: 'scaffold',
    label: 'Scaffold Behavior',
    svgIcon:
      'M256 64L576 64L576 576L64 576L64 192L256 192L256 64zM256 224L96 224L96 544L256 544L256 224zM288 544L544 544L544 96L288 96L288 544zM440 152L488 152L488 200L440 200L440 152zM392 152L392 200L344 200L344 152L392 152zM440 248L488 248L488 296L440 296L440 248zM392 248L392 296L344 296L344 248L392 248zM152 280L200 280L200 328L152 328L152 280zM392 344L392 392L344 392L344 344L392 344zM152 376L200 376L200 424L152 424L152 376zM488 344L488 392L440 392L440 344L488 344z',
    svgViewBox: '0 0 640 640',
    svgFill: 'currentColor',
    svgStroke: 'none',
    svgStrokeWidth: 0,
    svgPathFill: 'currentColor'
  }
]

const activeSection = ref('basics')
const creating = ref(false)
const projectNameInput = ref(null)
const locationAutoSynced = ref(true)

const project = ref({
  name: '',
  location: '',
  type: 'project',
  author: {
    name: '',
    email: '',
    affiliation: ''
  },
  scaffold: {
    seed_on_scaffold: false,
    seed: '',
    set_theme_on_scaffold: true,
    ggplot_theme: 'theme_minimal',
    source_all_functions: true,
    notebook_format: 'quarto',
    ide: 'vscode',
    positron: false
  },
  packages: {
    use_renv: false,
    default_packages: []
  },
  ai: {
    enabled: true,
    assistants: [],
    canonical_file: 'CLAUDE.md',
    canonical_content: ''
  },
  git: {
    initialize: true,
    gitignore_template: 'gitignore-project',
    gitignore_content: '',
    user_name: '',
    user_email: '',
    hooks: {
      ai_sync: false,
      data_security: false,
      check_sensitive_dirs: false
    }
  },
  connections: {
    databaseConnections: [],  // framework_db is implicit/reserved
    s3Connections: [],
    defaultDatabase: null,
    defaultStorageBucket: null
  },
  directories_enabled: {},
  directories: {},
  extra_directories: [],
  extra_directories_enabled: {}
})

// Initialize section from URL query
const initializeSection = () => {
  const sectionFromUrl = route.query.section
  const validSections = ['overview', 'author', 'scaffold', 'structure', 'packages', 'ai', 'git']
  if (sectionFromUrl && validSections.includes(sectionFromUrl)) {
    activeSection.value = sectionFromUrl
  }
}

// Watch for URL changes (browser back/forward)
watch(() => route.query.section, (newSection) => {
  const validSections = ['overview', 'author', 'scaffold', 'structure', 'packages', 'ai', 'git']
  if (newSection && validSections.includes(newSection)) {
    activeSection.value = newSection
  } else if (!newSection) {
    // If no section in URL, default to overview
    activeSection.value = 'overview'
  }
})

// Watch for activeSection changes and update URL
watch(activeSection, (newSection) => {
  const currentSection = route.query.section
  if (currentSection !== newSection) {
    router.replace({ query: { ...route.query, section: newSection } })
  }
})

// Load global settings and catalog on mount
onMounted(async () => {
  console.log('[DEBUG] NewProjectView mounted - starting initialization')

  // Initialize section from URL
  initializeSection()

  try {
    console.log('[DEBUG] Fetching global settings from /api/settings')
    // Load global settings
    const settingsResponse = await fetch('/api/settings')
    console.log('[DEBUG] Settings response status:', settingsResponse.status, settingsResponse.ok)
    if (settingsResponse.ok) {
      globalSettings.value = await settingsResponse.json()

      // Pre-populate from v2 defaults
      if (globalSettings.value) {
        // Pre-fill location from global projects_root
        if (globalSettings.value.global?.projects_root) {
          project.value.location = globalSettings.value.global.projects_root
        }

        // Pre-fill author info
        project.value.author = { ...globalSettings.value.author } || {}

        // Load project type default
        if (globalSettings.value.defaults?.project_type) {
          project.value.type = globalSettings.value.defaults.project_type
        }

        // Load scaffold defaults
        if (globalSettings.value.defaults?.scaffold) {
          project.value.scaffold = { ...globalSettings.value.defaults.scaffold }
        }

        // Load package defaults
        if (globalSettings.value.defaults?.packages) {
          // Handle flat array structure from SettingsView (current format)
          if (Array.isArray(globalSettings.value.defaults.packages)) {
            const mappedPackages = globalSettings.value.defaults.packages.map(pkg => ({
              name: pkg.name || '',
              source: pkg.source || 'cran',
              auto_attach: pkg.auto_attach !== false
            }))

            // Use splice to maintain reactivity instead of replacing the object
            project.value.packages.default_packages.splice(0, project.value.packages.default_packages.length, ...mappedPackages)
          }
          // Handle nested object structure (backwards compatibility)
          else if (globalSettings.value.defaults.packages.default_packages) {
            project.value.packages = {
              use_renv: globalSettings.value.defaults.packages.use_renv || false,
              default_packages: (globalSettings.value.defaults.packages.default_packages || []).map(pkg => ({
                name: pkg.name || '',
                source: pkg.source || 'cran',
                auto_attach: pkg.auto_attach !== false
              }))
            }
          }
        }

        // Load AI defaults
        const defaultAssistants = normalizeAssistantList(globalSettings.value.defaults?.ai_assistants)
        project.value.ai = {
          enabled: globalSettings.value.defaults?.ai_support !== false,
          assistants: defaultAssistants.length > 0 ? defaultAssistants : ['claude'],
          canonical_file: globalSettings.value.defaults?.ai_canonical_file || 'CLAUDE.md',
          canonical_content: ''
        }
        ensureAiAssistantsArray()

        // Load initial AI template content if AI is enabled
        if (project.value.ai.enabled && project.value.ai.canonical_file) {
          loadAITemplate(project.value.ai.canonical_file, project.value.type)
        }

        // Load git defaults
        project.value.git.initialize = globalSettings.value.defaults?.use_git !== false
        project.value.git.user_name = globalSettings.value.git?.user_name || ''
        project.value.git.user_email = globalSettings.value.git?.user_email || ''
        if (globalSettings.value.defaults?.git_hooks) {
          project.value.git.hooks = { ...globalSettings.value.defaults.git_hooks }
        }

        // Initialize gitignore template based on project type
        const gitignoreTemplateMap = {
          'project': 'gitignore-project',
          'project_sensitive': 'gitignore-project_sensitive',
          'course': 'gitignore-course',
          'presentation': 'gitignore-presentation'
        }
        project.value.git.gitignore_template = gitignoreTemplateMap[project.value.type] || 'gitignore-project'

        // Load initial gitignore template content
        if (project.value.git.gitignore_template) {
          loadGitignoreTemplate(project.value.git.gitignore_template)
        }
      }
    }

    // Load settings catalog for directory structure
    const catalogResponse = await fetch('/api/settings-catalog')
    if (catalogResponse.ok) {
      settingsCatalog.value = await catalogResponse.json()
    }

    // Initialize directories for current project type
    loadProjectTypeDefaults()
  } catch (error) {
    console.error('[DEBUG] Failed to load settings:', error)
    console.error('[DEBUG] Error details:', error.message, error.stack)
    toast.error('Load Error', 'Could not load default settings')
  } finally {
    console.log('[DEBUG] Initialization complete, loading =', loading.value)
    loading.value = false

    // Focus project name input after component is fully loaded
    setTimeout(() => {
      if (projectNameInput.value && projectNameInput.value.$el) {
        const inputElement = projectNameInput.value.$el.querySelector('input')
        if (inputElement) {
          inputElement.focus()
        }
      }
    }, 100)
  }
})

// Watch project type changes to update directories and gitignore template
watch(() => project.value.type, (newType) => {
  loadProjectTypeDefaults()

  // Update gitignore template based on project type
  const gitignoreTemplateMap = {
    'project': 'gitignore-project',
    'project_sensitive': 'gitignore-project_sensitive',
    'course': 'gitignore-course',
    'presentation': 'gitignore-presentation'
  }

  project.value.git.gitignore_template = gitignoreTemplateMap[newType] || 'gitignore-project'
})

// DEBUG: Watch packages changes
watch(() => project.value.packages.default_packages, (newVal, oldVal) => {
  console.log('[DEBUG PACKAGES WATCH] Packages changed!')
  console.log('[DEBUG PACKAGES WATCH] Old:', oldVal)
  console.log('[DEBUG PACKAGES WATCH] New:', newVal)
  console.trace('[DEBUG PACKAGES WATCH] Stack trace:')
}, { deep: true })

// Watch for gitignore template changes and reload content
watch(() => project.value.git.gitignore_template, (newTemplate) => {
  if (newTemplate) {
    loadGitignoreTemplate(newTemplate)
  }
})

watch(() => project.value.name, () => {
  if (!globalSettings.value?.global?.projects_root) return
  updateProjectLocation()
})

// Watch for AI enabled state changes
watch(() => project.value.ai.enabled, (isEnabled) => {
  if (isEnabled && project.value.ai.canonical_file) {
    loadAITemplate(project.value.ai.canonical_file, project.value.type)
  }
})

// Watch for AI canonical file changes and reload content
watch(() => project.value.ai.canonical_file, (newFile) => {
  if (newFile && project.value.ai.enabled) {
    loadAITemplate(newFile, project.value.type)
  }
})

// Watch for project type changes - reload AI template if CLAUDE.md is canonical
watch(() => project.value.type, (newType) => {
  if (project.value.ai.canonical_file === 'CLAUDE.md' && project.value.ai.enabled) {
    loadAITemplate('CLAUDE.md', newType)
  }
})

const loadProjectTypeDefaults = () => {
  if (!settingsCatalog.value?.project_types) return

  const catalogType = settingsCatalog.value.project_types[project.value.type]
  if (!catalogType?.directories) return

  // Get user's global settings for this project type (if they exist)
  const userProjectType = globalSettings.value?.project_types?.[project.value.type]

  // Set gitignore template based on project type (if not already set from global settings)
  if (!project.value.git.gitignore_template || project.value.git.gitignore_template === 'gitignore-project') {
    const gitignoreDefaults = {
      'project': 'gitignore-project',
      'project_sensitive': 'gitignore-sensitive',
      'course': 'gitignore-course',
      'presentation': 'gitignore-presentation'
    }
    project.value.git.gitignore_template = gitignoreDefaults[project.value.type] || 'gitignore-project'
  }

  // Load gitignore content for the selected template
  loadGitignoreTemplate(project.value.git.gitignore_template)

  // Initialize directories_enabled based on enabled_by_default
  project.value.directories_enabled = Object.entries(catalogType.directories).reduce((acc, [key, config]) => {
    acc[key] = config.enabled_by_default !== false
    return acc
  }, {})

  // Initialize directories with paths from user's global settings (if available), falling back to catalog defaults
  project.value.directories = Object.entries(catalogType.directories).reduce((acc, [key, config]) => {
    // Prefer user's global settings, then catalog default
    acc[key] = userProjectType?.directories?.[key] || config.default || ''
    return acc
  }, {})

  // Initialize extra_directories from user's global settings
  if (userProjectType?.extra_directories && Array.isArray(userProjectType.extra_directories)) {
    // Mark directories from global settings with _source flag
    project.value.extra_directories = userProjectType.extra_directories.map(dir => ({
      ...dir,
      _source: 'global'
    }))

    // Enable all global extra_directories by default
    project.value.extra_directories_enabled = userProjectType.extra_directories.reduce((acc, dir) => {
      if (dir.key) {
        acc[dir.key] = true
      }
      return acc
    }, {})
  } else {
    project.value.extra_directories = []
    project.value.extra_directories_enabled = {}
  }

  console.log('[DEBUG] loadProjectTypeDefaults() finished - packages still:', project.value.packages.default_packages)
}

const getProjectTypeLabel = (type) => {
  return settingsCatalog.value?.project_types?.[type]?.label || type
}

const getProjectTypeDescription = (type) => {
  return settingsCatalog.value?.project_types?.[type]?.description || ''
}

const currentSectionTitle = computed(() => {
  const titles = {
    overview: 'Overview',
    basics: 'Basics',
    author: 'Author & Metadata',
    scaffold: 'Scaffold Behavior',
    structure: 'Project Structure',
    connections: 'Connections',
    packages: 'Packages & Dependencies',
    ai: 'AI Assistants',
    git: 'Git & Hooks',
    review: 'Review & Create'
  }
  return titles[activeSection.value] || 'New Project'
})

const currentSectionDescription = computed(() => {
  const descriptions = {
    overview: 'Quick overview of your project settings. We used your Framework Project Defaults as a starting point.',
    basics: 'Essential project settings including name, location, type, and editor support.',
    author: 'Configure author information embedded in project templates.',
    scaffold: 'Runtime settings that control what happens when scaffold() runs.',
    structure: 'Customize which directories to create for this project type.',
    connections: 'Database and storage connections for this project.',
    packages: 'Configure package management and default packages.',
    ai: 'Configure AI assistant integration for this project.',
    git: 'Configure version control and git hooks.',
    review: 'Review your project configuration and create the project.'
  }
  return descriptions[activeSection.value] || ''
})

const ideLabel = computed(() => {
  const labels = {
    vscode: 'Positron / VS Code',
    rstudio: 'RStudio',
    'rstudio,vscode': 'Both',
    none: 'Other'
  }
  return labels[project.value.scaffold.ide] || project.value.scaffold.ide
})

const enabledGitHooks = computed(() => {
  const hooks = []
  if (project.value.git.hooks.ai_sync) hooks.push('Sync AI files')
  if (project.value.git.hooks.data_security) hooks.push('Check for secrets')
  if (project.value.git.hooks.check_sensitive_dirs) hooks.push('Warn about sensitive dirs')
  return hooks
})

const connectionsSummary = computed(() => {
  // Count databases (excluding framework_db which is implicit)
  const databases = project.value.connections.databaseConnections.length

  // Count S3 buckets
  const buckets = project.value.connections.s3Connections.length

  return { databases, buckets }
})

const gitPanelModel = computed({
  get() {
    const hooks = project.value.git.hooks || {}
    return {
      initialize: project.value.git.initialize,
      user_name: project.value.git.user_name || '',
      user_email: project.value.git.user_email || '',
      hooks: {
        ai_sync: hooks.ai_sync || false,
        data_security: hooks.data_security || false,
        check_sensitive_dirs: hooks.check_sensitive_dirs || false
      }
    }
  },
  set(val) {
    project.value.git.initialize = val.initialize
    project.value.git.user_name = val.user_name
    project.value.git.user_email = val.user_email
    project.value.git.hooks = {
      ai_sync: val.hooks.ai_sync,
      data_security: val.hooks.data_security,
      check_sensitive_dirs: val.hooks.check_sensitive_dirs
    }
  }
})

const displayLocation = computed(() => {
  const location = project.value.location
  const globalRoot = globalSettings.value?.global?.projects_root

  // If location equals global projects_root or is empty, show "(not set)"
  if (!location || location === globalRoot) {
    return '(not set)'
  }

  return location
})

const getPackagePlaceholder = (source) => {
  const placeholders = {
    cran: 'e.g., dplyr or dplyr@1.1.0',
    github: 'e.g., user/repo or user/repo@branch',
    bioc: 'e.g., DESeq2'
  }
  return placeholders[source] || placeholders.cran
}

const getPackageHint = (source) => {
  const hints = {
    cran: 'CRAN: name only (e.g., dplyr) or with version (dplyr@1.1.0)',
    github: 'GitHub: user/repo format (e.g., tidyverse/dplyr or tidyverse/dplyr@main)',
    bioc: 'Bioconductor: name only (e.g., DESeq2)'
  }
  return hints[source] || hints.cran
}

const toggleAssistant = (assistant, enabled) => {
  ensureAiAssistantsArray()
  if (enabled) {
    if (!project.value.ai.assistants.includes(assistant)) {
      project.value.ai.assistants.push(assistant)
    }
  } else {
    project.value.ai.assistants = project.value.ai.assistants.filter(a => a !== assistant)
  }
}

const handleLocationInput = (value) => {
  project.value.location = value
  const projectsRoot = globalSettings.value?.global?.projects_root || ''
  const trimmed = typeof value === 'string' ? value.trim() : ''

  if (!trimmed || (projectsRoot && trimmed === projectsRoot)) {
    locationAutoSynced.value = true
    updateProjectLocation()
  } else {
    locationAutoSynced.value = false
  }
}

const addPackage = () => {
  if (!project.value.packages.default_packages) {
    project.value.packages.default_packages = []
  }
  project.value.packages.default_packages.push({
    name: '',
    source: 'cran',
    auto_attach: false
  })
}

const removePackage = (index) => {
  project.value.packages.default_packages.splice(index, 1)
}

const getGitignoreTemplateLabel = (template) => {
  const labels = {
    'gitignore-project': 'Research Project',
    'gitignore-sensitive': 'Privacy Sensitive Project',
    'gitignore-course': 'Course/Teaching',
    'gitignore-presentation': 'Presentation'
  }
  return labels[template] || template
}

const loadGitignoreTemplate = async (template) => {
  try {
    const response = await fetch(`/api/templates/${template}`)
    if (response.ok) {
      const data = await response.json()
      if (data.success && data.contents) {
        project.value.git.gitignore_content = data.contents
      }
    }
  } catch (error) {
    console.error('Failed to load gitignore template:', error)
  }
}

const resetGitignoreTemplate = async () => {
  // Reload the default template for the current project type
  if (project.value.git.gitignore_template) {
    await loadGitignoreTemplate(project.value.git.gitignore_template)
    toast.success('Template Reset', 'Restored default .gitignore template')
  }
}

const loadAITemplate = async (canonicalFile, projectType) => {
  try {
    let templateName

    // Map canonical file to template name
    if (canonicalFile === 'CLAUDE.md') {
      // For CLAUDE.md, select project-type-specific template
      switch (projectType) {
        case 'project_sensitive':
          templateName = 'ai_claude_sensitive'
          break
        case 'course':
          templateName = 'ai_claude_course'
          break
        case 'presentation':
          templateName = 'ai_claude_presentation'
          break
        default:
          templateName = 'ai_claude_project'
      }
    } else if (canonicalFile === 'AGENTS.md') {
      templateName = 'ai_agents'
    } else if (canonicalFile === '.github/copilot-instructions.md') {
      templateName = 'ai_copilot'
    }

    const response = await fetch(`/api/templates/${templateName}`)
    if (response.ok) {
      const data = await response.json()
      if (data.success && data.contents) {
        project.value.ai.canonical_content = data.contents
      }
    }
  } catch (error) {
    console.error('Failed to load AI template:', error)
  }
}

const currentProjectTypeDirectories = computed(() => {
  if (!settingsCatalog.value?.project_types) return {}

  const catalogType = settingsCatalog.value.project_types[project.value.type]
  return catalogType?.directories || {}
})

const enabledDirectoriesCount = computed(() => {
  return Object.values(project.value.directories_enabled).filter(v => v).length
})

const countDirectoriesByCategory = (category) => {
  const keys = Object.keys(project.value.directories_enabled).filter(key => {
    const enabled = project.value.directories_enabled[key]
    if (!enabled) return false

    if (category === 'workspace') {
      return key === 'notebooks' || key === 'scripts' || key === 'functions'
    } else if (category === 'input') {
      return key.startsWith('inputs_')
    } else if (category === 'output') {
      return key.startsWith('outputs_')
    } else if (category === 'temporary') {
      return key === 'cache' || key === 'scratch'
    }
    return false
  })
  return keys.length
}

// Helper to get extra_directories from global settings by type
const globalExtraDirectoriesByType = (type) => {
  if (!Array.isArray(project.value.extra_directories)) return []
  return project.value.extra_directories.filter(dir => dir.type === type && dir._source === 'global')
}

// Helper to get project-specific extra_directories by type
const projectExtraDirectoriesByType = (type) => {
  if (!Array.isArray(project.value.extra_directories)) return []
  return project.value.extra_directories.filter(dir => dir.type === type && dir._source !== 'global')
}

// Helper to update project-specific extra_directories for a specific type
const updateProjectExtraDirectories = (type, updatedItems) => {
  if (!Array.isArray(project.value.extra_directories)) {
    project.value.extra_directories = []
  }

  // Keep all global directories and all directories of other types
  const keep = project.value.extra_directories.filter(dir =>
    dir._source === 'global' || (dir.type !== type && dir._source !== 'global')
  )

  // Add the updated project-specific items (ensuring they have the correct type and source)
  const itemsWithMeta = updatedItems.map(item => ({
    ...item,
    type,
    _source: 'project'
  }))

  // Replace entire array
  project.value.extra_directories = [...keep, ...itemsWithMeta]

  // Enable newly added directories
  itemsWithMeta.forEach(item => {
    if (item.key && !project.value.extra_directories_enabled[item.key]) {
      project.value.extra_directories_enabled[item.key] = true
    }
  })
}

const navigateToSection = (sectionId) => {
  router.push({ query: { ...route.query, section: sectionId } })
}

const updateProjectLocation = () => {
  if (!locationAutoSynced.value) return
  if (!project.value.name || !project.value.name.trim()) return

  const projectsRoot = globalSettings.value?.global?.projects_root || ''
  if (!projectsRoot) return

  // Only auto-update if the current location is still within projects_root or empty
  const currentLocation = (project.value.location || '').trim()
  if (currentLocation && !currentLocation.startsWith(projectsRoot)) {
    // User has manually changed it to a different location, don't override
    return
  }

  // Convert project name to kebab-case
  const kebabName = project.value.name
    .toLowerCase()
    .trim()
    .replace(/[\s_]+/g, '-')  // Replace spaces and underscores with hyphens
    .replace(/[^a-z0-9-]/g, '') // Remove non-alphanumeric characters except hyphens
    .replace(/-+/g, '-')        // Replace multiple hyphens with single hyphen
    .replace(/^-|-$/g, '')      // Remove leading/trailing hyphens

  if (!kebabName) {
    project.value.location = projectsRoot
    return
  }

  // Normalize root to avoid double slashes
  const normalizedRoot = projectsRoot.replace(/\/+$/, '')
  project.value.location = `${normalizedRoot}/${kebabName}`
}

const resetForm = () => {
  // Reload the page to reset all form data
  window.location.reload()
}

const createProject = async () => {
  // Validate
  if (!project.value.name || !project.value.name.trim()) {
    toast.error('Validation Error', 'Project name is required')
    navigateToSection('overview')
    return
  }

  if (!project.value.location || !project.value.location.trim()) {
    toast.error('Validation Error', 'Project location is required')
    navigateToSection('overview')
    return
  }

  try {
    creating.value = true

    // Build directories object from enabled flags
    const catalogType = settingsCatalog.value?.project_types?.[project.value.type]
    const directories = {}

    if (catalogType?.directories) {
      Object.entries(catalogType.directories).forEach(([key, config]) => {
        if (project.value.directories_enabled[key]) {
          directories[key] = config.default
        }
      })
    }

    // Convert connections arrays to nested object structure for saving
    const databases = {}
    project.value.connections.databaseConnections.forEach(conn => {
      const { _id, name, ...fields } = conn
      databases[name] = fields
    })

    const storage_buckets = {}
    project.value.connections.s3Connections.forEach(conn => {
      const { _id, name, ...fields } = conn
      storage_buckets[name] = fields
    })

    // Build request payload matching v2 structure
    // Location is the FULL path to the project directory
    const payload = {
      name: project.value.name.trim(),
      location: project.value.location.trim(),
      type: project.value.type,
      author: project.value.author,
      scaffold: project.value.scaffold,
      packages: project.value.packages,
      ai: project.value.ai,
      git: project.value.git,
      connections: {
        default_database: project.value.connections.defaultDatabase,
        default_storage_bucket: project.value.connections.defaultStorageBucket,
        databases,
        storage_buckets
      },
      directories
    }

    const response = await fetch('/api/projects/create', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.message || 'Failed to create project')
    }

    const result = await response.json()

    toast.success('Project Created', `${project.value.name} has been created successfully`)

    // Navigate to projects list
    router.push('/projects')
  } catch (error) {
    console.error('Failed to create project:', error)
    toast.error('Creation Failed', error.message || 'Could not create the project')
  } finally {
    creating.value = false
  }
}

// Keyboard shortcut handler
const handleKeydown = (e) => {
  // Cmd/Ctrl + S to create project
  if ((e.metaKey || e.ctrlKey) && e.key === 's') {
    e.preventDefault()
    createProject()
  }
}

// Setup keyboard shortcut
onMounted(() => {
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>
