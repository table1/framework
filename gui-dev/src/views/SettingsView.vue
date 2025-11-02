<template>
  <div class="mx-auto max-w-3xl p-10">
    <PageHeader
      title="Global Settings"
      description="Configure Framework defaults that apply to all new projects."
    />

    <Card class="mt-8">
      <template #header>
        <h3 class="text-base font-semibold text-gray-900 dark:text-white">Author Information</h3>
      </template>

      <div class="space-y-6">
        <Input
          v-model="settings.author_name"
          label="Your Name"
          placeholder="Your Name"
        />

        <Input
          v-model="settings.author_email"
          type="email"
          label="Email"
          placeholder="your.email@example.com"
        />

        <Input
          v-model="settings.author_affiliation"
          label="Affiliation"
          placeholder="University or Organization"
        />
      </div>

      <template #footer>
        <div class="flex justify-end">
          <Button @click="saveSettings">
            Save Settings
          </Button>
        </div>
      </template>
    </Card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import PageHeader from '../components/ui/PageHeader.vue'
import Card from '../components/ui/Card.vue'
import Input from '../components/ui/Input.vue'
import Button from '../components/ui/Button.vue'

const settings = ref({
  author_name: '',
  author_email: '',
  author_affiliation: ''
})

const saveSettings = async () => {
  try {
    const response = await fetch('/api/settings/save', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(settings.value)
    })

    if (response.ok) {
      alert('Settings saved!')
    }
  } catch (error) {
    console.error('Failed to save settings:', error)
  }
}

const loadSettings = async () => {
  try {
    const response = await fetch('/api/settings/get')
    const data = await response.json()

    if (data.author) {
      settings.value = {
        author_name: data.author?.name || '',
        author_email: data.author?.email || '',
        author_affiliation: data.author?.affiliation || ''
      }
    } else {
      settings.value = {
        author_name: data.FW_AUTHOR_NAME || '',
        author_email: data.FW_AUTHOR_EMAIL || '',
        author_affiliation: data.FW_AUTHOR_AFFILIATION || ''
      }
    }
  } catch (error) {
    console.error('Failed to load settings:', error)
  }
}

onMounted(() => {
  loadSettings()
})
</script>
