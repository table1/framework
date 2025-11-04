# Framework GUI Development Guide

Standards for developing the Framework GUI using Vue 3, Tailwind CSS, and component library.

## Development Workflow

### Quick Start

**Development Mode (Recommended)** - Run two servers with auto-reload:

**Terminal 1** - Vite dev server (hot reload for UI):
```bash
cd gui-dev
npm run dev
```
→ Access at **http://127.0.0.1:5173** (instant updates)

**Terminal 2** - R backend (auto-restarts on R file changes):
```bash
cd gui-dev
npm run dev:server
```
→ Runs on port 8080 (Vite proxies `/api/*` requests)
→ Auto-reloads when R/ or inst/plumber.R files change
→ **First time setup**: Run `npm install` to install nodemon

**Alternative** - Manual R server (if you prefer):
```bash
cd gui-dev
Rscript start-server.R
```
→ No auto-reload, must restart manually

**Production Mode** - Test what users will see:
```bash
cd gui-dev
npm run deploy   # Build + copy to inst/gui/
```

Then in R:
```r
devtools::load_all()
gui()  # Access at http://127.0.0.1:8080
```

### Deployment Process

After making UI changes:

1. **Develop** - Edit files in `gui-dev/src/`, test at port 5173
2. **Build** - Run `npm run deploy` (builds and copies to `inst/gui/`)
3. **Test** - Restart R server, test at port 8080
4. **Commit** - Include both `gui-dev/` and `inst/gui/` changes

### Scripts

- `npm run dev` - Start Vite dev server (port 5173, hot reload)
- `npm run build` - Build for production (outputs to `dist/`)
- `npm run deploy` - Build + copy to `inst/gui/` (use before committing!)
- `npm run preview` - Preview production build locally

### Important Notes

- **Production**: R package serves built files from `inst/gui/` (no Node.js required for users)
- **Development**: Vite dev server proxies API calls to R backend
- **Logo**: `public/framework-logo.png` is automatically copied during build
- **Always deploy before committing** to ensure `inst/gui/` stays in sync

## Important Constraints

**No Local File System Access:**
- The GUI runs in a browser - you **cannot** directly access the user's file system
- **Always rely on data sent from the server** about file names, paths, and project structure
- **Use copy buttons liberally** for paths and file names (not HTTPS, so use old-school `navigator.clipboard.writeText()`)
- Example: On a project page, provide a copy button next to the path to copy it to clipboard
- **Never** try to use file:// links or attempt to open files directly - instead provide copy functionality

**Copy Button Pattern:**
- Copy indicators are useful in many places (paths, commands, IDs, etc.)
- Create a reusable `CopyButton.vue` component that:
  - Takes a `value` prop (the text to copy to clipboard)
  - Copies to clipboard when clicked using `navigator.clipboard.writeText()`
  - Shows a toast notification on successful copy
  - Has visual feedback (icon changes or button state change)
- Use this component wherever users might want to copy text

**Navigation Architecture:**
- Left menu should list **all projects as first-order menu items**
- Let people click through projects directly from the sidebar
- Each project gets its own link in the main navigation (not nested in dropdowns)
- Keep navigation simple and direct - no deep nesting

## Design System

**Accent Color: Sky (Blue)**
- `sky-600` (light mode), `sky-500` (dark mode) for primary actions
- **NEVER use emerald/green** - replace with sky

**Neutral Colors:**
- Gray scale for backgrounds, borders, text
- `inset-ring` utility for borders (preferred over `border`)

### Page Layout Standards

**CRITICAL: Desktop-only UI - no mobile optimization needed**

All pages use a **consistent left sidebar + content area layout**:

```vue
<div class="flex min-h-screen">
  <!-- Left Sidebar (always 256px wide) -->
  <nav class="w-64 shrink-0 border-r border-gray-200 p-6 dark:border-gray-800">
    <h2 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">
      Page Title
    </h2>

    <div class="space-y-1">
      <!-- Navigation links -->
      <a :class="getSidebarLinkClasses('section-name')">
        <IconComponent class="h-4 w-4" />
        Section Name
      </a>
    </div>
  </nav>

  <!-- Main Content Area -->
  <div class="flex-1 p-10">
    <!-- Content sections here -->
  </div>
</div>
```

**Sidebar Link Styling:**
```javascript
const getSidebarLinkClasses = (section) => {
  const isActive = activeSection.value === section
  return [
    'flex items-center gap-2 px-3 py-2 rounded-md text-sm transition',
    isActive
      ? 'bg-sky-50 text-sky-700 font-medium dark:bg-sky-900/20 dark:text-sky-400'
      : 'text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-800'
  ]
}
```

### Content Section Styling ("Well" Backgrounds)

**Always use well backgrounds for content sections**:

```vue
<!-- Well background for form sections -->
<div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
  <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">
    Section Title
  </h3>
  <!-- Content here -->
</div>
```

**When to use Wells vs Cards:**
- **Well background** (`bg-gray-50 dark:bg-gray-800/50`) - DEFAULT for all content sections
- **Card component** (white background) - ONLY for special cases where you need strong visual separation

**Section Header Pattern:**
```vue
<h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-2">
  Main Section Title
</h2>
<p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
  Description text
</p>
```

**Subsection Header Pattern:**
```vue
<h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">
  Subsection Title
</h3>
```

### URL-Based Section Navigation

**Always implement URL persistence for sections:**

```javascript
// Initialize from URL
const initializeSection = () => {
  const sectionFromUrl = route.query.section
  const validSections = ['overview', 'settings', 'data']
  if (sectionFromUrl && validSections.includes(sectionFromUrl)) {
    activeSection.value = sectionFromUrl
  } else {
    activeSection.value = 'overview'
  }
}

// Update URL when section changes
watch(activeSection, (newSection) => {
  router.replace({ query: { ...route.query, section: newSection } })
})

// Handle browser back/forward
watch(() => route.query.section, (newSection) => {
  const validSections = ['overview', 'settings', 'data']
  if (newSection && validSections.includes(newSection)) {
    activeSection.value = newSection
  }
})
```

This ensures:
- Refreshing the page keeps you on the same section
- Browser back/forward buttons work correctly
- URLs can be shared to specific sections

## Component Library

**Always use components from `src/components/ui/` instead of custom styles.**

### Available Components

**`Card.vue`** - Container with header/body/footer slots
```vue
<Card>
  <template #header>Header</template>
  Content
  <template #footer>Footer</template>
</Card>
```

**`Button.vue`** - Variants: `primary`, `secondary`, `soft`
- Sizes: xs, sm, md, lg, xl
- Icon support with `icon` and `iconPosition` props

**`Input.vue`** - Text inputs with label, hint, error
```vue
<Input v-model="value" label="Name" hint="Help text" :error="error" />
```

**`Checkbox.vue`** - With optional description
```vue
<Checkbox v-model="value" id="my-checkbox" description="Help text">
  Label
</Checkbox>
```

**`Badge.vue`** - Status badges
- Variants: sky, gray, red, yellow, green, blue
- Modifiers: `pill`, `dot`

**`CopyButton.vue`** - Copy to clipboard button
```vue
<!-- Icon only (default) -->
<CopyButton value="/path/to/copy" />

<!-- With label -->
<CopyButton value="/path/to/copy" showLabel />

<!-- Ghost variant (no background) -->
<CopyButton value="/path/to/copy" variant="ghost" />

<!-- Custom success message -->
<CopyButton value="/path/to/copy" successMessage="Path copied!" />

<!-- Custom slot for styling -->
<CopyButton value="/path/to/copy" v-slot="{ copied }">
  <span>{{ copied ? '✓' : 'Copy' }}</span>
</CopyButton>
```
- Automatically shows toast notification on copy
- Visual feedback with checkmark when copied
- Variants: `default` (with background), `ghost` (transparent)
- Optional label with `showLabel` prop

**`Select.vue`**, **`Textarea.vue`**, **`Radio.vue`**, **`RadioGroup.vue`** - Standard form inputs

**`Modal.vue`** - Flexible modal dialog
```vue
<Modal v-model="showModal" title="Confirm Action" icon="warning" size="md">
  Are you sure you want to continue?
  <template #actions>
    <Button variant="secondary" @click="showModal = false">Cancel</Button>
    <Button variant="primary" @click="confirm">Confirm</Button>
  </template>
</Modal>
```
- Icons: success, error, warning, info
- Sizes: sm, md, lg, xl
- Variants: centered, side-icon

**`Alert.vue`** - Inline alerts
```vue
<Alert type="success" title="Success!" description="Changes saved" dismissible />
```
- Types: success, error, warning, info
- Optional title and dismissible

**`Toast.vue`** + **`ToastContainer.vue`** - Toast notifications
```vue
<!-- In App.vue -->
<ToastContainer ref="toastContainer" />

<!-- In any component -->
<script setup>
import { useToast } from '@/composables/useToast'
const toast = useToast()

toast.success('Saved!', 'Your changes have been saved')
toast.error('Error', 'Something went wrong')
</script>
```

**`Toggle.vue`** - Switch/toggle input
```vue
<Toggle v-model="enabled" label="Enable notifications" description="Receive email updates" />
```

**`Dropdown.vue`** - Menu dropdowns
```vue
<Dropdown label="Options">
  <DropdownSection>
    <DropdownItem @click="edit">Edit</DropdownItem>
    <DropdownItem @click="duplicate">Duplicate</DropdownItem>
  </DropdownSection>
  <DropdownDivider />
  <DropdownSection>
    <DropdownItem variant="danger" @click="deleteItem">Delete</DropdownItem>
  </DropdownSection>
</Dropdown>
```
- With `DropdownItem`, `DropdownSection`, `DropdownDivider` helpers

**`EmptyState.vue`** - No data states
```vue
<!-- Clickable -->
<EmptyState
  title="No projects"
  description="Get started by creating a new project"
  icon="folder"
  action
  @click="createProject"
/>

<!-- With action buttons -->
<EmptyState title="No files" icon="document">
  <template #actions>
    <Button variant="primary">Upload files</Button>
  </template>
</EmptyState>
```

**`Tabs.vue`** + **`TabPanel.vue`** - Tabbed interfaces
```vue
<Tabs v-model="activeTab" :tabs="tabs" variant="pills">
  <TabPanel id="general" :active="activeTab === 'general'">
    General settings content
  </TabPanel>
  <TabPanel id="security" :active="activeTab === 'security'">
    Security settings content
  </TabPanel>
</Tabs>
```
- Variants: pills, underline
- Sizes: sm, md, lg
- Badge support, icon support

### Patterns We Need

**High Priority:**
1. ✅ Modal/Dialog - DONE
2. ✅ Alert/Notification - DONE
3. ✅ Dropdown menus - DONE
4. ✅ Toggle switches - DONE
5. ✅ Empty states - DONE
6. ✅ Tabs - DONE

**Medium Priority:**
7. Loading spinners
8. Breadcrumbs

## Coding Standards

**Vue 3 Composition API:**
- Use `<script setup>`
- Two-way binding with `defineProps` + `defineEmits(['update:modelValue'])`

**Tailwind:**
- Utility classes only (no custom CSS)
- Dark mode: `bg-white dark:bg-gray-800`
- Responsive: `sm:`, `md:`, `lg:` prefixes

**Component Design:**
- Slots for flexibility
- Sensible defaults
- Dark mode support required
- Keyboard/screen reader accessible

**Keyboard Shortcuts:**
- **ALWAYS implement Cmd/Ctrl+S to save on forms/settings pages**
- Add cleanup on component unmount
- Pattern to use:

```javascript
import { onMounted, onUnmounted } from 'vue'

const handleKeydown = (e) => {
  // Cmd/Ctrl + S to save
  if ((e.metaKey || e.ctrlKey) && e.key === 's') {
    e.preventDefault()
    saveSettings() // or whatever your save function is
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
```

## Common Patterns

**Modal:**
```vue
<div class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
  <Card class="max-w-2xl w-full">
    <template #header>Title + close button</template>
    Content
    <template #footer>
      <Button variant="secondary">Cancel</Button>
      <Button variant="primary">Save</Button>
    </template>
  </Card>
</div>
```

**Card Selection (like project types):**
```vue
<div :class="[
  'border-2 rounded-lg p-4 cursor-pointer',
  selected ? 'border-sky-600 bg-sky-50 dark:bg-sky-900/20'
           : 'border-gray-200 dark:border-gray-700 hover:border-sky-300'
]">
```

**API Calls:**
```javascript
try {
  const response = await fetch('/api/endpoint', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  const result = await response.json()
  // Handle response
} catch (err) {
  error.value = 'Network error: ' + err.message
}
```

## Setup ToastContainer

Add to your main App.vue:

```vue
<template>
  <div id="app">
    <!-- Your app content -->
    <router-view />

    <!-- Toast container (global) -->
    <ToastContainer ref="toastContainer" />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import ToastContainer from '@/components/ui/ToastContainer.vue'
import { setToastContainer } from '@/composables/useToast'

const toastContainer = ref(null)

onMounted(() => {
  setToastContainer(toastContainer.value)
})
</script>
```

## File Structure

```
gui-dev/
├── src/
│   ├── components/
│   │   ├── ui/              # Reusable components
│   │   │   ├── Alert.vue
│   │   │   ├── Badge.vue
│   │   │   ├── Button.vue
│   │   │   ├── Card.vue
│   │   │   ├── Checkbox.vue
│   │   │   ├── CopyButton.vue
│   │   │   ├── Dropdown.vue
│   │   │   ├── DropdownDivider.vue
│   │   │   ├── DropdownItem.vue
│   │   │   ├── DropdownSection.vue
│   │   │   ├── EmptyState.vue
│   │   │   ├── Input.vue
│   │   │   ├── Modal.vue
│   │   │   ├── PageHeader.vue
│   │   │   ├── Radio.vue
│   │   │   ├── RadioGroup.vue
│   │   │   ├── Select.vue
│   │   │   ├── TabPanel.vue
│   │   │   ├── Tabs.vue
│   │   │   ├── Textarea.vue
│   │   │   ├── Toast.vue
│   │   │   ├── ToastContainer.vue
│   │   │   └── Toggle.vue
│   │   └── [features].vue   # Feature components
│   ├── views/               # Page components
│   ├── composables/         # Composition functions
│   │   ├── useDarkMode.js
│   │   └── useToast.js
│   └── main.js
```
