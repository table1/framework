# Framework GUI Components Library

Complete component library built with Vue 3 + Tailwind CSS using **sky (green)** as the primary accent color.

## ✅ Completed Components

### Layout & Containers
- **Card.vue** - Flexible container with header/body/footer slots
- **Modal.vue** - Full-featured dialog with backdrop, transitions, icons
  - Variants: centered, side-icon
  - Sizes: sm, md, lg, xl
  - Built-in icon support for success/error/warning/info

### Buttons & Actions
- **Button.vue** - Primary, secondary, soft variants
  - All sizes (xs to xl)
  - Icon positioning support
  - Disabled states

### Form Inputs
- **Input.vue** - Text inputs with label, hint, error states
- **Checkbox.vue** - Checkboxes with optional descriptions
- **Select.vue** - Select dropdowns
- **Textarea.vue** - Multi-line text inputs
- **Radio.vue** & **RadioGroup.vue** - Radio button groups

### Feedback & Notifications
- **Alert.vue** - Inline alerts (success, error, warning, info)
  - Optional dismissible
  - Slot support for custom content
- **Toast.vue** - Toast notification (part of ToastContainer system)
  - Auto-dismiss with configurable duration
  - Regular and condensed variants
  - Action button support
- **ToastContainer.vue** - Global toast manager
  - Stacks multiple toasts
  - Automatic positioning
  - Smooth transitions

### Display
- **Badge.vue** - Status badges and tags
  - 9 color variants (sky, gray, red, yellow, etc.)
  - Pill and dot modifiers

### Navigation & Menus
- **Dropdown.vue** - Menu dropdown with click-outside and escape key handling
  - Align left or right
  - Configurable width
  - Optional dividers
- **DropdownItem.vue** - Menu items (default and danger variants)
- **DropdownSection.vue** - Grouped menu items
- **DropdownDivider.vue** - Visual separator

### Empty States
- **EmptyState.vue** - No data states
  - Built-in icons (database, folder, document, users, inbox, photo)
  - Clickable action variant
  - Custom action buttons via slot

### Tabs
- **Tabs.vue** - Tabbed navigation
  - Variants: pills (default), underline
  - Sizes: sm, md, lg
  - Badge and icon support
- **TabPanel.vue** - Tab content panels

### Other
- **Toggle.vue** - Switch/toggle input with label and description
- **PageHeader.vue** - Page titles and navigation

## 🔧 Composables

- **useDarkMode.js** - Dark mode toggle
- **useToast.js** - Toast notification API
  ```js
  const toast = useToast()
  toast.success('Title', 'Description')
  toast.error('Error!', 'Something failed')
  ```

## 📋 Usage Examples

### Modal Dialog
```vue
<script setup>
import { ref } from 'vue'
import Modal from '@/components/ui/Modal.vue'
import Button from '@/components/ui/Button.vue'

const showModal = ref(false)
</script>

<template>
  <Button @click="showModal = true">Open</Button>

  <Modal
    v-model="showModal"
    title="Confirm deletion"
    icon="warning"
    size="md"
  >
    Are you sure you want to delete this item?

    <template #actions>
      <div class="flex gap-3 justify-end">
        <Button variant="secondary" @click="showModal = false">
          Cancel
        </Button>
        <Button variant="primary" @click="handleDelete">
          Delete
        </Button>
      </div>
    </template>
  </Modal>
</template>
```

### Toast Notifications
```vue
<script setup>
import { useToast } from '@/composables/useToast'

const toast = useToast()

const save = async () => {
  try {
    await saveData()
    toast.success('Saved!', 'Your changes have been saved')
  } catch (err) {
    toast.error('Error', err.message)
  }
}
</script>
```

### Alert Messages
```vue
<template>
  <Alert
    type="success"
    title="Success!"
    description="Project created successfully"
    dismissible
    @dismiss="handleDismiss"
  />

  <Alert type="error">
    <strong>Error:</strong> Failed to save changes.
    <a href="#" class="underline">Try again</a>
  </Alert>
</template>
```

### Form with Validation
```vue
<template>
  <form @submit.prevent="handleSubmit">
    <div class="space-y-6">
      <Input
        v-model="form.name"
        label="Project Name"
        hint="Choose a descriptive name"
        :error="errors.name"
      />

      <Checkbox
        v-model="form.useGit"
        id="use-git"
        description="Initialize a git repository"
      >
        Use Git
      </Checkbox>

      <div class="flex gap-3 justify-end">
        <Button variant="secondary" type="button" @click="cancel">
          Cancel
        </Button>
        <Button variant="primary" type="submit">
          Create Project
        </Button>
      </div>
    </div>
  </form>
</template>
```

## 🎨 Color System

**Accent Color: Emerald**
- Light mode: `sky-600` for primary actions
- Dark mode: `sky-500` for primary actions
- Soft backgrounds: `sky-50` / `sky-400/10`

**Status Colors:**
- Success: sky/green
- Error: red
- Warning: yellow
- Info: blue

**Neutrals:**
- Gray scale for text, backgrounds, borders
- `inset-ring` utility for borders (preferred)

### Usage Examples - Dropdown

```vue
<template>
  <Dropdown label="Actions" align="right">
    <DropdownSection>
      <DropdownItem @click="handleEdit">Edit</DropdownItem>
      <DropdownItem @click="handleDuplicate">Duplicate</DropdownItem>
    </DropdownSection>

    <DropdownDivider />

    <DropdownSection>
      <DropdownItem @click="handleArchive">Archive</DropdownItem>
      <DropdownItem variant="danger" @click="handleDelete">Delete</DropdownItem>
    </DropdownSection>
  </Dropdown>
</template>
```

### Usage Examples - Toggle

```vue
<template>
  <div class="space-y-4">
    <Toggle
      v-model="notifications"
      label="Push notifications"
      description="Receive notifications about new messages"
    />

    <Toggle
      v-model="marketing"
      label="Marketing emails"
    />
  </div>
</template>
```

### Usage Examples - Empty State

```vue
<template>
  <!-- Clickable empty state -->
  <EmptyState
    title="Create your first project"
    description="Get started by creating a new data analysis project"
    icon="folder"
    action
    @click="openWizard"
  />

  <!-- With custom actions -->
  <EmptyState
    title="No files uploaded"
    description="Upload your data files to get started"
    icon="document"
  >
    <template #actions>
      <div class="flex gap-3 justify-center">
        <Button variant="primary">Upload file</Button>
        <Button variant="secondary">Learn more</Button>
      </div>
    </template>
  </EmptyState>
</template>
```

### Usage Examples - Tabs

```vue
<script setup>
import { ref } from 'vue'
import Tabs from '@/components/ui/Tabs.vue'
import TabPanel from '@/components/ui/TabPanel.vue'

const activeTab = ref('general')

const tabs = [
  { id: 'general', label: 'General' },
  { id: 'security', label: 'Security', badge: '3' },
  { id: 'notifications', label: 'Notifications' },
  { id: 'billing', label: 'Billing' }
]
</script>

<template>
  <!-- Pills variant (default) -->
  <Tabs v-model="activeTab" :tabs="tabs" variant="pills">
    <TabPanel id="general" :active="activeTab === 'general'">
      <h3 class="text-lg font-semibold mb-4">General Settings</h3>
      <!-- Content -->
    </TabPanel>

    <TabPanel id="security" :active="activeTab === 'security'">
      <h3 class="text-lg font-semibold mb-4">Security Settings</h3>
      <!-- Content -->
    </TabPanel>

    <TabPanel id="notifications" :active="activeTab === 'notifications'">
      <h3 class="text-lg font-semibold mb-4">Notification Preferences</h3>
      <!-- Content -->
    </TabPanel>

    <TabPanel id="billing" :active="activeTab === 'billing'">
      <h3 class="text-lg font-semibold mb-4">Billing Information</h3>
      <!-- Content -->
    </TabPanel>
  </Tabs>

  <!-- Underline variant -->
  <Tabs v-model="activeTab" :tabs="tabs" variant="underline" size="lg">
    <!-- Tab panels -->
  </Tabs>
</template>
```

## 🚀 Next Components to Build

**High Priority:**
1. ✅ Dropdown menus - DONE
2. ✅ Toggle switches - DONE
3. ✅ Empty states - DONE
4. ✅ Tabs - DONE
5. Loading spinner

**Medium Priority:**
6. Breadcrumbs
7. Pagination

## 📦 Installation

Components are ready to use. Just import and go:

```vue
<script setup>
import Button from '@/components/ui/Button.vue'
import Card from '@/components/ui/Card.vue'
// ... etc
</script>
```

Don't forget to setup ToastContainer in App.vue for global toasts!
