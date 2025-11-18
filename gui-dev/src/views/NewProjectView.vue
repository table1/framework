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
          <OverviewSummary
            :cards="overviewCards"
            @navigate="(section) => activeSection = section"
          />
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
                <option value="project">Standard Project</option>
                <option value="project_sensitive">Privacy Sensitive Project</option>
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

              <!-- Author Information -->
              <div class="pt-6 border-t border-gray-200 dark:border-gray-700">
                <AuthorInformationPanel v-model="project.author" />
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
                    <div class="font-medium text-sm">Standard Project</div>
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
              <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Primary Files</h3>
              <div class="space-y-4">
                <Input
                  v-model="project.directories.presentation_source"
                  label="Presentation source file"
                  placeholder="presentation.qmd"
                  hint="Main Quarto file for your slides"
                />
                <Input
                  v-model="project.directories.rendered_slides"
                  label="Rendered slides directory"
                  placeholder="."
                  hint="Rendered slides write to the project root by default (.)"
                  prefix="/"
                  monospace
                />
              </div>
            </div>

            <!-- Directories - Standard Project -->
            <div v-if="project.type === 'project'" class="space-y-6">
              <!-- Inputs Section -->
              <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Inputs</h3>
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                  Define the read-only locations where raw and prepared data live.
                </p>

                <div class="space-y-5">
                  <div v-for="field in generalInputFields" :key="field.key" class="space-y-1.5">
                    <Toggle
                      v-model="project.directories_enabled[field.key]"
                      :label="field.label"
                      :description="field.hint"
                    />
                    <Input
                      v-if="project.directories_enabled[field.key] !== false"
                      v-model="project.directories[field.key]"
                      prefix="/"
                      monospace
                    />
                  </div>
                </div>

                <!-- Additional Input Directories -->
                <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                  <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Additional Input Directories</h4>

                  <!-- Global extra directories with toggles -->
                  <div v-if="globalExtraDirectoriesByType('input').length > 0" class="space-y-3 mb-4">
                    <div v-for="dir in globalExtraDirectoriesByType('input')" :key="dir.key" class="space-y-1.5">
                      <Toggle
                        v-model="project.extra_directories_enabled[dir.key]"
                        :label="dir.label"
                      />
                      <Input
                        v-if="project.extra_directories_enabled[dir.key] !== false"
                        :model-value="dir.path"
                        readonly
                        prefix="/"
                        monospace
                      />
                    </div>
                  </div>

                  <!-- New directories with repeater -->
                  <Repeater
                    v-model="newInputDirectories"
                    addLabel="Add Input Directory"
                    :defaultItem="() => ({ key: '', label: '', path: '', type: 'input', _id: Date.now() })"
                  >
                    <template #default="{ item, update }">
                      <div class="space-y-3">
                        <Input
                          :model-value="item.key"
                          @update:model-value="update('key', $event)"
                          label="Key"
                          placeholder="inputs_archive"
                          hint="Unique identifier (alphanumeric and underscores)"
                        />
                        <Input
                          :model-value="item.label"
                          @update:model-value="update('label', $event)"
                          label="Label"
                          placeholder="Archive"
                        />
                        <Input
                          :model-value="item.path"
                          @update:model-value="update('path', $event)"
                          label="Path"
                          prefix="/"
                          placeholder="inputs/archive"
                          monospace
                        />
                      </div>
                    </template>
                  </Repeater>
                </div>
              </div>

              <!-- Workspaces Section -->
              <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Workspaces</h3>
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                  Functions, notebooks, and scripts scaffolded into every project.
                </p>

                <div class="space-y-5">
                  <!-- Renderable directories (Notebooks, Docs) with two-column layout -->
                  <div v-for="field in generalWorkspaceRenderableFields" :key="field.key" class="space-y-1.5">
                    <Toggle
                      v-model="project.directories_enabled[field.key]"
                      :label="field.label"
                      :description="field.hint"
                    />
                    <div v-if="project.directories_enabled[field.key] !== false" class="grid grid-cols-2 gap-3">
                      <Input
                        v-model="project.directories[field.key]"
                        label="Source files"
                        prefix="/"
                        monospace
                      />
                      <Input
                        v-model="project.render_dirs[field.key]"
                        label="Quarto render directory"
                        prefix="/"
                        monospace
                      />
                    </div>
                  </div>

                  <!-- Non-renderable directories (Functions, Scripts) with single-column layout -->
                  <div v-for="field in generalWorkspaceNonRenderableFields" :key="field.key" class="space-y-1.5">
                    <Toggle
                      v-model="project.directories_enabled[field.key]"
                      :label="field.label"
                      :description="field.hint"
                    />
                    <Input
                      v-if="project.directories_enabled[field.key] !== false"
                      v-model="project.directories[field.key]"
                      prefix="/"
                      monospace
                    />
                  </div>
                </div>

                <!-- Additional Workspace Directories -->
                <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                  <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Additional Workspace Directories</h4>

                  <!-- Global extra directories with toggles -->
                  <div v-if="globalExtraDirectoriesByType('workspace').length > 0" class="space-y-3 mb-4">
                    <div v-for="dir in globalExtraDirectoriesByType('workspace')" :key="dir.key" class="space-y-1.5">
                      <Toggle
                        v-model="project.extra_directories_enabled[dir.key]"
                        :label="dir.label"
                      />
                      <Input
                        v-if="project.extra_directories_enabled[dir.key] !== false"
                        :model-value="dir.path"
                        readonly
                        prefix="/"
                        monospace
                      />
                    </div>
                  </div>

                  <!-- New directories with repeater -->
                  <Repeater
                    v-model="newWorkspaceDirectories"
                    addLabel="Add Workspace Directory"
                    :defaultItem="() => ({ key: '', label: '', path: '', type: 'workspace', _id: Date.now() })"
                  >
                    <template #default="{ item, update }">
                      <div class="space-y-3">
                        <Input
                          :model-value="item.key"
                          @update:model-value="update('key', $event)"
                          label="Key"
                          placeholder="tests"
                          hint="Unique identifier (alphanumeric and underscores)"
                        />
                        <Input
                          :model-value="item.label"
                          @update:model-value="update('label', $event)"
                          label="Label"
                          placeholder="Tests"
                        />
                        <Input
                          :model-value="item.path"
                          @update:model-value="update('path', $event)"
                          label="Path"
                          prefix="/"
                          placeholder="tests"
                          monospace
                        />
                      </div>
                    </template>
                  </Repeater>
                </div>
              </div>

              <!-- Outputs Section -->
              <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Outputs</h3>
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                  Outputs are public by default so results are easy to share.
                </p>

                <div class="space-y-5">
                  <div v-for="field in generalOutputFields" :key="field.key" class="space-y-1.5">
                    <Toggle
                      v-model="project.directories_enabled[field.key]"
                      :label="field.label"
                      :description="field.hint"
                    />
                    <Input
                      v-if="project.directories_enabled[field.key] !== false"
                      v-model="project.directories[field.key]"
                      prefix="/"
                      monospace
                    />
                  </div>
                </div>

                <!-- Additional Output Directories -->
                <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                  <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Additional Output Directories</h4>

                  <!-- Global extra directories with toggles -->
                  <div v-if="globalExtraDirectoriesByType('output').length > 0" class="space-y-3 mb-4">
                    <div v-for="dir in globalExtraDirectoriesByType('output')" :key="dir.key" class="space-y-1.5">
                      <Toggle
                        v-model="project.extra_directories_enabled[dir.key]"
                        :label="dir.label"
                      />
                      <Input
                        v-if="project.extra_directories_enabled[dir.key] !== false"
                        :model-value="dir.path"
                        readonly
                        prefix="/"
                        monospace
                      />
                    </div>
                  </div>

                  <!-- New directories with repeater -->
                  <Repeater
                    v-model="newOutputDirectories"
                    addLabel="Add Output Directory"
                    :defaultItem="() => ({ key: '', label: '', path: '', type: 'output', _id: Date.now() })"
                  >
                    <template #default="{ item, update }">
                      <div class="space-y-3">
                        <Input
                          :model-value="item.key"
                          @update:model-value="update('key', $event)"
                          label="Key"
                          placeholder="outputs_animations"
                          hint="Unique identifier (alphanumeric and underscores)"
                        />
                        <Input
                          :model-value="item.label"
                          @update:model-value="update('label', $event)"
                          label="Label"
                          placeholder="Animations"
                        />
                        <Input
                          :model-value="item.path"
                          @update:model-value="update('path', $event)"
                          label="Path"
                          prefix="/"
                          placeholder="outputs/animations"
                          monospace
                        />
                      </div>
                    </template>
                  </Repeater>
                </div>
              </div>

              <!-- Utility Directories Section -->
              <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Utility directories</h3>
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                  Cache and scratch folders are gitignored so temporary artifacts never leak into version control.
                </p>

                <div class="space-y-5">
                  <div v-for="field in generalUtilityFields" :key="field.key" class="space-y-1.5">
                    <Toggle
                      v-model="project.directories_enabled[field.key]"
                      :label="field.label"
                      :description="field.hint"
                    />
                    <Input
                      v-if="project.directories_enabled[field.key] !== false"
                      v-model="project.directories[field.key]"
                      prefix="/"
                      monospace
                    />
                  </div>
                </div>
              </div>
            </div>

            <!-- Directories - Course/Teaching -->
            <CourseDirectoriesPanel
              v-if="project.type === 'course' && settingsCatalog"
              :directories-enabled="project.directories_enabled"
              @update:directories-enabled="project.directories_enabled = $event"
              :directories="project.directories"
              @update:directories="project.directories = $event"
              :render-dirs="project.render_dirs || {}"
              @update:render-dirs="project.render_dirs = $event"
              :catalog="settingsCatalog.project_types?.course || {}"
              :extra-directories-enabled="project.extra_directories_enabled"
              @update:extra-directories-enabled="project.extra_directories_enabled = $event"
              :extra-directories="globalExtraDirectoriesByType('course')"
              :project-custom-directories="projectExtraDirectoriesByType('course')"
              @update:project-custom-directories="updateProjectExtraDirectories('course', $event)"
              :allow-custom-directories="true"
            />

            <!-- Directories - Presentation (simpler, fewer dirs) -->
            <div v-if="project.type === 'presentation'" class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Optional Directories</h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">Toggle extra scaffolding when you need supporting data, scripts, or helper utilities.</p>

              <div class="space-y-4">
                <div class="space-y-2">
                  <Toggle
                    v-model="project.directories_enabled.data"
                    label="Include data directory"
                    description="Adds a /data folder for sample data used in the presentation."
                  />
                  <Input
                    v-if="project.directories_enabled.data"
                    v-model="project.directories.data"
                    prefix="/"
                    monospace
                  />
                </div>

                <div class="space-y-2">
                  <Toggle
                    v-model="project.directories_enabled.scripts"
                    label="Include scripts directory"
                    description="Adds a scripts/ folder for demo code or automation."
                  />
                  <Input
                    v-if="project.directories_enabled.scripts"
                    v-model="project.directories.scripts"
                    prefix="/"
                    monospace
                  />
                </div>

                <div class="space-y-2">
                  <Toggle
                    v-model="project.directories_enabled.functions"
                    label="Include functions directory"
                    description="Adds functions/ for helper utilities that should load automatically."
                  />
                  <Input
                    v-if="project.directories_enabled.functions"
                    v-model="project.directories.functions"
                    prefix="/"
                    monospace
                  />
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
            </div>

            <!-- Directories - Privacy Sensitive -->
            <div v-if="project.type === 'project_sensitive'" class="space-y-6">
              <!-- Inputs Section -->
              <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Inputs</h3>
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                  Keep private inputs compartmentalized; publish processed outputs into public folders when ready.
                </p>

                <div class="grid gap-4 sm:grid-cols-2 text-xs font-semibold uppercase text-gray-500 dark:text-gray-400 mb-4">
                  <div>Private</div>
                  <div>Public</div>
                </div>

                <div class="space-y-5">
                  <div v-for="pair in sensitiveInputPairs" :key="pair.privateKey" class="grid gap-4 sm:grid-cols-2">
                    <div class="space-y-2">
                      <Toggle
                        v-model="project.directories_enabled[pair.privateKey]"
                        :label="pair.privateLabel || `${pair.label} (private)`"
                      />
                      <Input
                        v-if="project.directories_enabled[pair.privateKey] !== false"
                        v-model="project.directories[pair.privateKey]"
                        prefix="/"
                        monospace
                      />
                    </div>
                    <div class="space-y-2">
                      <Toggle
                        v-model="project.directories_enabled[pair.publicKey]"
                        :label="pair.publicLabel || `${pair.label} (public)`"
                      />
                      <Input
                        v-if="project.directories_enabled[pair.publicKey] !== false"
                        v-model="project.directories[pair.publicKey]"
                        prefix="/"
                        monospace
                      />
                    </div>
                  </div>
                </div>

                <!-- Additional Input Directories -->
                <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                  <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Additional Input Directories</h4>

                  <Repeater
                    v-model="newInputDirectories"
                    addLabel="Add Input Directory"
                    :defaultItem="() => ({ key: '', label: '', path: '', type: 'input', _id: Date.now() })"
                  >
                    <template #default="{ item, update }">
                      <div class="space-y-3">
                        <Input
                          :model-value="item.key"
                          @update:model-value="update('key', $event)"
                          label="Key"
                          placeholder="inputs_archive"
                          hint="Unique identifier (alphanumeric and underscores)"
                        />
                        <Input
                          :model-value="item.label"
                          @update:model-value="update('label', $event)"
                          label="Label"
                          placeholder="Archive"
                        />
                        <Input
                          :model-value="item.path"
                          @update:model-value="update('path', $event)"
                          label="Path"
                          prefix="/"
                          placeholder="inputs/archive"
                          monospace
                        />
                      </div>
                    </template>
                  </Repeater>
                </div>
              </div>

              <!-- Workspaces Section -->
              <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Workspaces</h3>
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                  Module locations for notebooks, scripts, and helper functions.
                </p>

                <div class="space-y-5">
                  <!-- Renderable directories (Notebooks, Docs) with two-column layout -->
                  <div v-for="field in generalWorkspaceRenderableFields" :key="`sensitive-${field.key}`" class="space-y-1.5">
                    <Toggle
                      v-model="project.directories_enabled[field.key]"
                      :label="field.label"
                      :description="field.hint"
                    />
                    <div v-if="project.directories_enabled[field.key] !== false" class="grid grid-cols-2 gap-3">
                      <Input
                        v-model="project.directories[field.key]"
                        label="Source files"
                        prefix="/"
                        monospace
                      />
                      <Input
                        v-model="project.render_dirs[field.key]"
                        label="Quarto render directory"
                        prefix="/"
                        monospace
                      />
                    </div>
                  </div>

                  <!-- Non-renderable directories (Functions, Scripts) with single-column layout -->
                  <div v-for="field in generalWorkspaceNonRenderableFields" :key="`sensitive-${field.key}`" class="space-y-1.5">
                    <Toggle
                      v-model="project.directories_enabled[field.key]"
                      :label="field.label"
                      :description="field.hint"
                    />
                    <Input
                      v-if="project.directories_enabled[field.key] !== false"
                      v-model="project.directories[field.key]"
                      prefix="/"
                      monospace
                    />
                  </div>
                </div>

                <!-- Additional Workspace Directories -->
                <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                  <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Additional Workspace Directories</h4>

                  <Repeater
                    v-model="newWorkspaceDirectories"
                    addLabel="Add Workspace Directory"
                    :defaultItem="() => ({ key: '', label: '', path: '', type: 'workspace', _id: Date.now() })"
                  >
                    <template #default="{ item, update }">
                      <div class="space-y-3">
                        <Input
                          :model-value="item.key"
                          @update:model-value="update('key', $event)"
                          label="Key"
                          placeholder="templates"
                          hint="Unique identifier (alphanumeric and underscores)"
                        />
                        <Input
                          :model-value="item.label"
                          @update:model-value="update('label', $event)"
                          label="Label"
                          placeholder="Templates"
                        />
                        <Input
                          :model-value="item.path"
                          @update:model-value="update('path', $event)"
                          label="Path"
                          prefix="/"
                          placeholder="templates"
                          monospace
                        />
                      </div>
                    </template>
                  </Repeater>
                </div>
              </div>

              <!-- Outputs Section -->
              <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Outputs</h3>
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                  Review outputs before promotion; private folders remain gitignored while public copies are ready to share.
                </p>

                <div class="grid gap-4 sm:grid-cols-2 text-xs font-semibold uppercase text-gray-500 dark:text-gray-400 mb-4">
                  <div>Private</div>
                  <div>Public</div>
                </div>

                <div class="space-y-5">
                  <div v-for="pair in sensitiveOutputPairs" :key="pair.privateKey" class="grid gap-4 sm:grid-cols-2">
                    <div class="space-y-2">
                      <Toggle
                        v-model="project.directories_enabled[pair.privateKey]"
                        :label="pair.privateLabel || `${pair.label} (private)`"
                      />
                      <Input
                        v-if="project.directories_enabled[pair.privateKey] !== false"
                        v-model="project.directories[pair.privateKey]"
                        prefix="/"
                        monospace
                      />
                    </div>
                    <div class="space-y-2">
                      <Toggle
                        v-model="project.directories_enabled[pair.publicKey]"
                        :label="pair.publicLabel || `${pair.label} (public)`"
                      />
                      <Input
                        v-if="project.directories_enabled[pair.publicKey] !== false"
                        v-model="project.directories[pair.publicKey]"
                        prefix="/"
                        monospace
                      />
                    </div>
                  </div>
                </div>

                <!-- Additional Output Directories -->
                <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                  <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-3">Additional Output Directories</h4>

                  <Repeater
                    v-model="newOutputDirectories"
                    addLabel="Add Output Directory"
                    :defaultItem="() => ({ key: '', label: '', path: '', type: 'output', _id: Date.now() })"
                  >
                    <template #default="{ item, update }">
                      <div class="space-y-3">
                        <Input
                          :model-value="item.key"
                          @update:model-value="update('key', $event)"
                          label="Key"
                          placeholder="outputs_presentations"
                          hint="Unique identifier (alphanumeric and underscores)"
                        />
                        <Input
                          :model-value="item.label"
                          @update:model-value="update('label', $event)"
                          label="Label"
                          placeholder="Presentations"
                        />
                        <Input
                          :model-value="item.path"
                          @update:model-value="update('path', $event)"
                          label="Path"
                          prefix="/"
                          placeholder="outputs/presentations"
                          monospace
                        />
                      </div>
                    </template>
                  </Repeater>
                </div>
              </div>

              <!-- Utility Directories Section -->
              <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Utility directories</h3>
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                  Keep cache and scratch in private space for safety; both remain gitignored.
                </p>

                <div class="space-y-5">
                  <div v-for="field in generalUtilityFields" :key="`sensitive-${field.key}`" class="space-y-1.5">
                    <Toggle
                      v-model="project.directories_enabled[field.key]"
                      :label="field.label"
                      :description="field.hint"
                    />
                    <Input
                      v-if="project.directories_enabled[field.key] !== false"
                      v-model="project.directories[field.key]"
                      prefix="/"
                      monospace
                    />
                  </div>
                </div>
              </div>
            </div>

            <!-- .gitignore Template -->
            <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
              <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">.gitignore Template</h3>
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

        <!-- .env Defaults Section -->
        <div v-show="activeSection === 'env'">
          <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
            <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
              Environment variables template for this project. These defaults help connections work immediately.
            </p>

            <EnvEditor
              :groups="project.env.groups"
              v-model:variables="project.env.variables"
              v-model:raw-content="project.env.rawContent"
              v-model:view-mode="project.env.viewMode"
              v-model:regroup-on-save="project.env.regroupOnSave"
              :show-save-button="false"
              :allow-show-values-toggle="true"
            />
          </div>
        </div>

        <!-- Packages Section -->
        <div v-show="activeSection === 'packages'">
          <PackagesEditor
            v-model="project.packages"
            :show-renv-toggle="true"
            :flush="false"
          />
        </div>

        <!-- AI Assistants Section -->
        <div v-show="activeSection === 'ai'">
          <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
            <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
              Framework maintains context files for selected assistants and keeps them in sync before commits.
            </p>

            <AIAssistantsPanel
              v-model="project.ai"
              :flush="true"
              :show-editor="true"
              editor-height="500px"
            >
              <template #editor-description>
                Edit the canonical file directly. This will be pre-populated when the project is created.
              </template>
            </AIAssistantsPanel>
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
import OverviewSummary from '../components/OverviewSummary.vue'
import NavigationSectionHeading from '../components/ui/NavigationSectionHeading.vue'
import AuthorInformationPanel from '../components/settings/AuthorInformationPanel.vue'
import PackagesEditor from '../components/settings/PackagesEditor.vue'
import AIAssistantsPanel from '../components/settings/AIAssistantsPanel.vue'
import GitHooksPanel from '../components/settings/GitHooksPanel.vue'
import ScaffoldBehaviorPanel from '../components/settings/ScaffoldBehaviorPanel.vue'
import ConnectionsPanel from '../components/settings/ConnectionsPanel.vue'
import WorkspaceDirectoriesPanel from '../components/settings/WorkspaceDirectoriesPanel.vue'
import RenderableWorkspacesPanel from '../components/settings/RenderableWorkspacesPanel.vue'
import InputDirectoriesPanel from '../components/settings/InputDirectoriesPanel.vue'
import OutputDirectoriesPanel from '../components/settings/OutputDirectoriesPanel.vue'
import CourseDirectoriesPanel from '../components/settings/CourseDirectoriesPanel.vue'
import EnvEditor from '../components/env/EnvEditor.vue'
import { useToast } from '../composables/useToast'
import {
  InformationCircleIcon,
  UserIcon,
  FolderIcon,
  CubeIcon,
  DocumentCheckIcon,
  Cog6ToothIcon,
  ServerStackIcon,
  KeyIcon
} from '@heroicons/vue/24/outline'

const router = useRouter()
const route = useRoute()
const toast = useToast()

const globalSettings = ref(null)
const settingsCatalog = ref(null)
const loading = ref(true)

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
  { id: 'env', label: '.env Defaults', icon: KeyIcon },
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

// Reactive refs for custom directory repeaters
const newInputDirectories = ref([])
const newWorkspaceDirectories = ref([])
const newOutputDirectories = ref([])

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
  env: {
    variables: {},
    rawContent: `# Framework environment defaults
# Populate these values before running scaffold() or publishing.

# PostgreSQL connection
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_DB=postgres
POSTGRES_SCHEMA=public
POSTGRES_USER=postgres
POSTGRES_PASSWORD=

# S3-compatible storage (AWS S3, MinIO, etc.)
S3_ACCESS_KEY=
S3_SECRET_KEY=
S3_BUCKET=
S3_REGION=us-east-1
S3_ENDPOINT=`,
    viewMode: 'grouped',
    regroupOnSave: false,
    groups: {}
  },
  directories_enabled: {},
  directories: {},
  render_dirs: {}, // Quarto render output directories for renderable workspaces
  extra_directories: [],
  extra_directories_enabled: {}
})

// Initialize section from URL query
const initializeSection = () => {
  const sectionFromUrl = route.query.section
  const validSections = ['overview', 'author', 'scaffold', 'structure', 'connections', 'env', 'packages', 'ai', 'git']
  if (sectionFromUrl && validSections.includes(sectionFromUrl)) {
    activeSection.value = sectionFromUrl
  }
}

// Watch for URL changes (browser back/forward)
watch(() => route.query.section, (newSection) => {
  const validSections = ['overview', 'author', 'scaffold', 'structure', 'connections', 'env', 'packages', 'ai', 'git']
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

        // Load scaffold defaults (preserve existing defaults, then override with API values)
        if (globalSettings.value.defaults?.scaffold) {
          project.value.scaffold = {
            ...project.value.scaffold,
            ...globalSettings.value.defaults.scaffold
          }
        }

        // Load notebook_format from top-level defaults (current SettingsView format)
        if (globalSettings.value.defaults?.notebook_format) {
          project.value.scaffold.notebook_format = globalSettings.value.defaults.notebook_format
        }

        // Ensure notebook_format always has a value (fallback to quarto)
        if (!project.value.scaffold.notebook_format) {
          project.value.scaffold.notebook_format = 'quarto'
        }

        // Load positron setting (stored at defaults.positron, not defaults.scaffold.positron)
        if (globalSettings.value.defaults?.positron !== undefined) {
          project.value.scaffold.positron = globalSettings.value.defaults.positron
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

        // Load .env defaults from Framework Project Defaults
        if (globalSettings.value.defaults?.env) {
          const envConfig = globalSettings.value.defaults.env
          if (typeof envConfig === 'string') {
            project.value.env.rawContent = envConfig
          } else if (envConfig?.raw) {
            project.value.env.rawContent = envConfig.raw
          }
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

    // Initialize env variables from default template
    initializeEnvVariables()
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

// DEBUG: Removed debug watcher that was adding console noise
// watch(() => project.value.packages.default_packages, (newVal, oldVal) => {
//   console.log('[DEBUG PACKAGES WATCH] Packages changed!')
// }, { deep: true })

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

  // Initialize directories_enabled from user's global settings, falling back to catalog enabled_by_default
  project.value.directories_enabled = Object.entries(catalogType.directories).reduce((acc, [key, config]) => {
    // Prefer user's global settings, then catalog enabled_by_default
    if (userProjectType?.directories_enabled?.[key] !== undefined) {
      acc[key] = userProjectType.directories_enabled[key]
    } else {
      acc[key] = config.enabled_by_default !== false
    }
    return acc
  }, {})

  // Initialize directories with paths from user's global settings (if available), falling back to catalog defaults
  project.value.directories = Object.entries(catalogType.directories).reduce((acc, [key, config]) => {
    // Prefer user's global settings, then catalog default
    acc[key] = userProjectType?.directories?.[key] || config.default || ''
    return acc
  }, {})

  // Initialize render_dirs for directories that support Quarto rendering
  if (catalogType.render_dirs) {
    project.value.render_dirs = Object.entries(catalogType.render_dirs).reduce((acc, [key, config]) => {
      // Prefer user's global settings, then catalog default
      acc[key] = userProjectType?.render_dirs?.[key] || config.default || ''
      return acc
    }, {})
  } else {
    project.value.render_dirs = {}
  }

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

    // Populate repeater refs with global directories (without _source for easier editing)
    // Filter project-specific directories (not global) by type
    newInputDirectories.value = userProjectType.extra_directories
      .filter(dir => dir.type === 'input')
      .map(dir => {
        const { _source, ...rest } = dir
        return { ...rest, _id: Date.now() + Math.random() }
      })

    newWorkspaceDirectories.value = userProjectType.extra_directories
      .filter(dir => dir.type === 'workspace')
      .map(dir => {
        const { _source, ...rest } = dir
        return { ...rest, _id: Date.now() + Math.random() }
      })

    newOutputDirectories.value = userProjectType.extra_directories
      .filter(dir => dir.type === 'output')
      .map(dir => {
        const { _source, ...rest } = dir
        return { ...rest, _id: Date.now() + Math.random() }
      })
  } else {
    project.value.extra_directories = []
    project.value.extra_directories_enabled = {}
    newInputDirectories.value = []
    newWorkspaceDirectories.value = []
    newOutputDirectories.value = []
  }

  console.log('[DEBUG] loadProjectTypeDefaults() finished - packages still:', project.value.packages.default_packages)
}

const getProjectTypeLabel = (type) => {
  return settingsCatalog.value?.project_types?.[type]?.label || type
}

const getProjectTypeDescription = (type) => {
  return settingsCatalog.value?.project_types?.[type]?.description || ''
}

const parseEnvContent = (raw = '') => {
  const result = {}
  raw.split(/\r?\n/).forEach((line) => {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith('#') || !trimmed.includes('=')) return
    const [key, ...rest] = trimmed.split('=')
    result[key.trim()] = rest.join('=').replace(/^"|"$/g, '')
  })
  return result
}

const groupEnvByPrefix = (vars = {}) => {
  const entries = Object.entries(vars)
  if (!entries.length) return {}
  return entries.reduce((acc, [key, value]) => {
    const prefix = key.includes('_') ? key.split('_')[0] : 'Other'
    if (!acc[prefix]) acc[prefix] = {}
    acc[prefix][key] = {
      defined: !!value,
      used: false,
      used_in: [],
      value
    }
    return acc
  }, {})
}

watch(() => project.value.env.variables, (vars) => {
  project.value.env.groups = groupEnvByPrefix(vars || {})
}, { deep: true })

// Watch repeater refs and sync to project.extra_directories
watch(newInputDirectories, (items) => {
  updateProjectExtraDirectories('input', items)
}, { deep: true })

watch(newWorkspaceDirectories, (items) => {
  updateProjectExtraDirectories('workspace', items)
}, { deep: true })

watch(newOutputDirectories, (items) => {
  updateProjectExtraDirectories('output', items)
}, { deep: true })

// Initialize env variables from raw content
const initializeEnvVariables = () => {
  if (project.value.env.rawContent) {
    project.value.env.variables = parseEnvContent(project.value.env.rawContent)
    project.value.env.groups = groupEnvByPrefix(project.value.env.variables)
  }
}

const currentSectionTitle = computed(() => {
  const titles = {
    overview: 'Overview',
    basics: 'Basics',
    author: 'Author & Metadata',
    scaffold: 'Scaffold Behavior',
    structure: 'Project Structure',
    connections: 'Connections',
    env: '.env Defaults',
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
    env: 'Environment variables template for this project.',
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

const envVariableCount = computed(() => {
  const variables = project.value.env?.variables || {}
  return Object.keys(variables).length
})

// Overview data for OverviewSummary component
const overviewCards = computed(() => {
  const name = project.value.name || 'Untitled Project'
  const author = project.value.author?.name || ''
  const location = displayLocation.value
  const projectTypeLabel = getProjectTypeLabel(project.value.type)
  const workspaces = countDirectoriesByCategory('workspace')
  const inputs = countDirectoriesByCategory('input')
  const outputs = countDirectoriesByCategory('output')
  const packagesCount = project.value.packages?.default_packages?.length || 0
  const renvEnabled = project.value.packages?.use_renv || false
  const envCount = envVariableCount.value
  const aiEnabled = project.value.ai?.enabled || false
  const aiProvider = project.value.ai?.assistants?.[0] ? project.value.ai.assistants.map(a => a.charAt(0).toUpperCase() + a.slice(1)).join(', ') : ''
  const aiCanonical = project.value.ai?.canonical_file || ''
  const gitInit = project.value.git?.initialize || false
  const dbCount = connectionsSummary.value.databases
  const bucketCount = connectionsSummary.value.buckets
  const connectionsSummaryText = dbCount > 0 || bucketCount > 0
    ? `${dbCount} database${dbCount !== 1 ? 's' : ''}${bucketCount > 0 ? ` · ${bucketCount} bucket${bucketCount !== 1 ? 's' : ''}` : ''}`
    : 'framework_db only'

  return [
    {
      id: 'basics',
      title: 'Basics',
      section: 'basics',
      content: `<div>${name} · ${author} · ${projectTypeLabel}</div><div class="text-sm text-gray-600 dark:text-gray-400 mt-1">${location}</div>`
    },
    {
      id: 'structure',
      title: 'Project Structure',
      section: 'structure',
      content: `${projectTypeLabel} · ${workspaces} workspace · ${inputs} input · ${outputs} output`
    },
    {
      id: 'packages',
      title: 'Packages',
      section: 'packages',
      content: packagesCount > 0
        ? `${packagesCount} packages · renv ${renvEnabled ? 'enabled' : 'disabled'}`
        : `renv: ${renvEnabled ? 'enabled' : 'disabled'}`
    },
    {
      id: 'env',
      title: '.env Defaults',
      section: 'env',
      content: envCount > 0 ? `${envCount} variable${envCount === 1 ? '' : 's'}` : 'No variables defined'
    },
    {
      id: 'ai',
      title: 'AI Assistants',
      section: 'ai',
      content: aiEnabled
        ? `<span class="text-green-600 dark:text-green-400">${aiProvider} · ${aiCanonical}</span>`
        : '<span class="text-gray-600 dark:text-gray-400">Disabled</span>'
    },
    {
      id: 'git',
      title: 'Git & Hooks',
      section: 'git',
      content: `Git: ${gitInit ? 'enabled' : 'disabled'}`
    },
    {
      id: 'connections',
      title: 'Connections',
      section: 'connections',
      content: connectionsSummaryText
    },
    {
      id: 'scaffold',
      title: 'Scaffold Behavior',
      section: 'scaffold',
      content: `${project.value.scaffold?.source_all_functions ? 'Functions loaded from functions/' : 'Does not load functions'} · ${project.value.scaffold?.set_theme_on_scaffold ? `ggplot2: ${(project.value.scaffold.ggplot_theme || 'theme_minimal').replace('theme_', '')}` : 'No ggplot theme'} · ${project.value.scaffold?.set_seed ? `Seed: ${project.value.scaffold.seed}` : 'No random seed'}`
    }
  ]
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

const getGitignoreTemplateLabel = (template) => {
  const labels = {
    'gitignore-project': 'Standard Project',
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

// Get optional directories for current project type (enabled_by_default: false)
// This is dynamically read from the settings catalog, making it the source of truth.
// For presentation type, this filters to: inputs, outputs, scripts, functions
// SYNC NOTE: SettingsView hardcodes these in presentationOptions reactive object
// See src/constants/projectTypes.js for documentation of expected values
const currentProjectTypeOptionalDirectories = computed(() => {
  if (!settingsCatalog.value?.project_types) return []

  const catalogType = settingsCatalog.value.project_types[project.value.type]
  if (!catalogType?.directories) return []

  // Filter directories where enabled_by_default is false
  return Object.keys(catalogType.directories).filter(key => {
    const dir = catalogType.directories[key]
    return dir && dir.enabled_by_default === false
  })
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

// Fallback arrays for directory structure (matching SettingsView.vue)
const generalWorkspaceRenderableFallback = [
  {
    key: 'notebooks',
    label: 'Notebooks',
    hint: 'Quarto or R Markdown notebooks for analysis.',
    defaultRenderDir: 'outputs/notebooks'
  },
  {
    key: 'docs',
    label: 'Documentation',
    hint: 'Codebooks, documentation, and other reference materials.',
    defaultRenderDir: 'outputs/docs'
  }
]

const generalWorkspaceNonRenderableFallback = [
  {
    key: 'functions',
    label: 'Functions',
    hint: 'R files here are sourced by scaffold(), so helper functions are available in every project session.'
  },
  {
    key: 'scripts',
    label: 'Scripts',
    hint: 'Reusable R scripts, job runners, or automation tasks.'
  }
]

const generalInputFallback = [
  { key: 'inputs_raw', label: 'Raw data', hint: 'Read-only exports from source systems.' },
  { key: 'inputs_intermediate', label: 'Intermediate data', hint: 'Data after light cleaning or pre-processing steps.' },
  { key: 'inputs_final', label: 'Analysis-ready data', hint: 'Final inputs ready for modeling or reporting.' }
]

const generalOutputFallback = [
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
  { privateKey: 'outputs_private_reports', publicKey: 'outputs_public_reports', label: 'Reports', privateLabel: 'Reports (private)', publicLabel: 'Reports (public)' }
]

const getDirectoryMeta = (typeKey, dirKey) => settingsCatalog.value?.project_types?.[typeKey]?.directories?.[dirKey] || {}

const buildDirectoryFields = (typeKey, fallback) =>
  fallback.map((entry) => {
    const meta = getDirectoryMeta(typeKey, entry.key)
    return {
      key: entry.key,
      label: meta.label || entry.label,
      hint: meta.hint || entry.hint || ''
    }
  })

// Computed properties for Standard Project directory fields
const generalWorkspaceRenderableFields = computed(() => buildDirectoryFields('project', generalWorkspaceRenderableFallback).map(field => ({
  ...field,
  defaultRenderDir: generalWorkspaceRenderableFallback.find(f => f.key === field.key)?.defaultRenderDir || ''
})))

const generalWorkspaceNonRenderableFields = computed(() => buildDirectoryFields('project', generalWorkspaceNonRenderableFallback))
const generalInputFields = computed(() => buildDirectoryFields('project', generalInputFallback))
const generalOutputFields = computed(() => buildDirectoryFields('project', generalOutputFallback))
const generalUtilityFields = computed(() => buildDirectoryFields('project', generalUtilityFallback))

// Build sensitive pairs for Privacy Sensitive project type
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

    // Build directories object from enabled flags and user values
    const catalogType = settingsCatalog.value?.project_types?.[project.value.type]
    const directories = {}

    if (catalogType?.directories) {
      Object.entries(catalogType.directories).forEach(([key, config]) => {
        if (project.value.directories_enabled[key]) {
          directories[key] = project.value.directories[key] || config.default
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
      env: {
        raw: project.value.env.rawContent || ''
      },
      directories,
      render_dirs: project.value.render_dirs || {},
      // Filter out invalid extra_directories (missing key, label, or path)
      // AND filter out disabled directories
      extra_directories: (project.value.extra_directories || []).filter(dir => {
        const hasValidData = dir.key && dir.key.trim() &&
                             dir.label && dir.label.trim() &&
                             dir.path && dir.path.trim()
        const isEnabled = project.value.extra_directories_enabled?.[dir.key] !== false
        return hasValidData && isEnabled
      }),
      extra_directories_enabled: project.value.extra_directories_enabled || {}
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

    // Check if backend returned success: false
    if (result.success === false) {
      throw new Error(result.error || 'Project creation failed')
    }

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
