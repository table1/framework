<template>
  <div class="space-y-6">
    <!-- Databases -->
    <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
      <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">Databases</h3>

      <!-- Framework DB (system connection, read-only) -->
      <div class="mb-4 rounded-md border-2 border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-900 p-4">
        <div class="flex items-center justify-between mb-3">
          <div class="flex items-center gap-2">
            <Badge variant="gray" size="sm">System</Badge>
            <span class="text-sm font-medium text-gray-900 dark:text-gray-100 font-mono">framework_db</span>
          </div>
          <span class="text-xs text-gray-500 dark:text-gray-400">SQLite - Framework metadata</span>
        </div>
        <div class="text-sm text-gray-600 dark:text-gray-400 font-mono">
          framework.db
        </div>
      </div>

      <Repeater
        :model-value="databaseConnections"
        @update:model-value="$emit('update:databaseConnections', $event)"
        add-label="Add Database"
        :default-item="getDefaultDatabaseItem"
      >
        <template #default="{ item, index, update }">
          <div class="space-y-3">
            <div class="grid grid-cols-2 gap-3">
              <Input
                :model-value="item.name"
                @update:model-value="update('name', $event)"
                label="Connection Name"
                :error="getDatabaseNameError(item.name, index)"
                monospace
                size="sm"
              />

              <Select
                :model-value="item.driver"
                @update:model-value="update('driver', $event)"
                label="Driver"
                size="sm"
              >
                <option value="sqlite">SQLite</option>
                <option value="postgres">PostgreSQL</option>
                <option value="mysql">MySQL</option>
                <option value="sqlserver">SQL Server</option>
              </Select>
            </div>

            <!-- Default selection -->
            <div class="flex items-center gap-2">
              <input
                type="radio"
                :id="`default-db-${item._id}`"
                :checked="defaultDatabase === item.name"
                @change="$emit('update:defaultDatabase', item.name)"
                class="h-4 w-4 text-sky-600 focus:ring-sky-500"
              />
              <label
                :for="`default-db-${item._id}`"
                class="text-sm text-gray-700 dark:text-gray-300"
              >
                Default database
              </label>
            </div>

            <!-- SQLite fields -->
            <div v-if="item.driver === 'sqlite'">
              <Input
                :model-value="item.database"
                @update:model-value="update('database', $event)"
                label="Database Path"
                monospace
                size="sm"
              />
            </div>

            <!-- PostgreSQL fields (with schema) -->
            <div v-else-if="item.driver === 'postgres' || item.driver === 'postgresql'" class="space-y-3">
              <div class="grid grid-cols-2 gap-3">
                <Input
                  :model-value="item.host"
                  @update:model-value="update('host', $event)"
                  label="Host"
                  monospace
                  size="sm"
                />
                <Input
                  :model-value="item.port"
                  @update:model-value="update('port', $event)"
                  label="Port"
                  monospace
                  size="sm"
                />
              </div>
              <div class="grid grid-cols-2 gap-3">
                <Input
                  :model-value="item.database"
                  @update:model-value="update('database', $event)"
                  label="Database"
                  monospace
                  size="sm"
                />
                <Input
                  :model-value="item.schema"
                  @update:model-value="update('schema', $event)"
                  label="Schema"
                  monospace
                  size="sm"
                />
              </div>
              <div class="grid grid-cols-2 gap-3">
                <Input
                  :model-value="item.user"
                  @update:model-value="update('user', $event)"
                  label="User"
                  monospace
                  size="sm"
                />
                <Input
                  :model-value="item.password"
                  @update:model-value="update('password', $event)"
                  label="Password"
                  monospace
                  size="sm"
                />
              </div>
            </div>

            <!-- MySQL and SQL Server fields (no schema) -->
            <div v-else-if="item.driver === 'mysql' || item.driver === 'sqlserver'" class="space-y-3">
              <div class="grid grid-cols-2 gap-3">
                <Input
                  :model-value="item.host"
                  @update:model-value="update('host', $event)"
                  label="Host"
                  monospace
                  size="sm"
                />
                <Input
                  :model-value="item.port"
                  @update:model-value="update('port', $event)"
                  label="Port"
                  monospace
                  size="sm"
                />
              </div>
              <Input
                :model-value="item.database"
                @update:model-value="update('database', $event)"
                label="Database"
                monospace
                size="sm"
              />
              <div class="grid grid-cols-2 gap-3">
                <Input
                  :model-value="item.user"
                  @update:model-value="update('user', $event)"
                  label="User"
                  monospace
                  size="sm"
                />
                <Input
                  :model-value="item.password"
                  @update:model-value="update('password', $event)"
                  label="Password"
                  monospace
                  size="sm"
                />
              </div>
            </div>
          </div>
        </template>
      </Repeater>
    </div>

    <!-- S3-compatible Storage -->
    <div class="rounded-lg bg-gray-50 p-6 dark:bg-gray-800/50">
      <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">S3-compatible Storage</h3>

      <Repeater
        :model-value="s3Connections"
        @update:model-value="$emit('update:s3Connections', $event)"
        add-label="Add Bucket"
        :default-item="getDefaultS3Item"
      >
        <template #default="{ item, index, update }">
          <div class="space-y-3">
            <Input
              :model-value="item.name"
              @update:model-value="update('name', $event)"
              label="Connection Name"
              :error="getS3NameError(item.name, index)"
              monospace
              size="sm"
            />

            <!-- Default selection -->
            <div class="flex items-center gap-2">
              <input
                type="radio"
                :id="`default-s3-${item._id}`"
                :checked="defaultStorageBucket === item.name"
                @change="$emit('update:defaultStorageBucket', item.name)"
                class="h-4 w-4 text-sky-600 focus:ring-sky-500"
              />
              <label
                :for="`default-s3-${item._id}`"
                class="text-sm text-gray-700 dark:text-gray-300"
              >
                Default storage bucket
              </label>
            </div>

            <div class="grid grid-cols-2 gap-3">
              <Input
                :model-value="item.bucket"
                @update:model-value="update('bucket', $event)"
                label="Bucket"
                monospace
                size="sm"
              />
              <Input
                :model-value="item.region"
                @update:model-value="update('region', $event)"
                label="Region"
                monospace
                size="sm"
              />
            </div>

            <div class="grid grid-cols-2 gap-3">
              <Input
                :model-value="item.access_key"
                @update:model-value="update('access_key', $event)"
                label="Access Key"
                monospace
                size="sm"
              />
              <Input
                :model-value="item.secret_key"
                @update:model-value="update('secret_key', $event)"
                label="Secret Key"
                monospace
                size="sm"
              />
            </div>

            <Input
              :model-value="item.endpoint"
              @update:model-value="update('endpoint', $event)"
              label="Endpoint"
              hint="Leave empty for AWS S3, or specify custom endpoint for MinIO, etc."
              monospace
              size="sm"
            />

            <Checkbox
              :model-value="item.static_hosting"
              @update:model-value="update('static_hosting', $event)"
              id="static-hosting"
              description="Enable for S3 static website hosting, R2 public buckets, or CDN-fronted storage. Allows clean URLs like /report/ instead of /report.html"
            >
              Static website hosting
            </Checkbox>
          </div>
        </template>
      </Repeater>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import Repeater from '../ui/Repeater.vue'
import Input from '../ui/Input.vue'
import Select from '../ui/Select.vue'
import Badge from '../ui/Badge.vue'
import Checkbox from '../ui/Checkbox.vue'

const props = defineProps({
  databaseConnections: {
    type: Array,
    required: true
  },
  s3Connections: {
    type: Array,
    required: true
  },
  defaultDatabase: {
    type: String,
    default: null
  },
  defaultStorageBucket: {
    type: String,
    default: null
  }
})

defineEmits(['update:databaseConnections', 'update:s3Connections', 'update:defaultDatabase', 'update:defaultStorageBucket'])

// Validation: check for duplicate database connection names
const getDatabaseNameError = (name, currentIndex) => {
  if (!name || name.trim() === '') {
    return 'Connection name is required'
  }

  if (name === 'framework_db') {
    return 'framework_db is reserved for system use'
  }

  // Check for duplicates in database connections
  const duplicate = props.databaseConnections.findIndex((conn, idx) =>
    idx !== currentIndex && conn.name === name
  )
  if (duplicate !== -1) {
    return 'Connection name must be unique'
  }

  // Check for duplicates in S3 connections (connections share namespace)
  const s3Duplicate = props.s3Connections.findIndex((conn) => conn.name === name)
  if (s3Duplicate !== -1) {
    return 'Connection name must be unique across all connections'
  }

  return null
}

// Validation: check for duplicate S3 connection names
const getS3NameError = (name, currentIndex) => {
  if (!name || name.trim() === '') {
    return 'Connection name is required'
  }

  if (name === 'framework_db') {
    return 'framework_db is reserved for system use'
  }

  // Check for duplicates in S3 connections
  const duplicate = props.s3Connections.findIndex((conn, idx) =>
    idx !== currentIndex && conn.name === name
  )
  if (duplicate !== -1) {
    return 'Connection name must be unique'
  }

  // Check for duplicates in database connections (connections share namespace)
  const dbDuplicate = props.databaseConnections.findIndex((conn) => conn.name === name)
  if (dbDuplicate !== -1) {
    return 'Connection name must be unique across all connections'
  }

  return null
}

// Helper to get unique connection name (avoiding reserved names)
const generateUniqueConnectionName = (base, existingNames) => {
  let counter = 1
  let candidate = base
  // framework_db is reserved for system connection
  while (existingNames.includes(candidate) || candidate === 'framework_db') {
    counter += 1
    candidate = `${base}_${counter}`
  }
  return candidate
}

// Default item factories for repeaters
const getDefaultDatabaseItem = () => {
  const existingNames = props.databaseConnections.map(c => c.name)

  // Determine which driver to default to based on what's already been added
  let driver = 'postgres'
  let baseName = 'database'

  if (!existingNames.some(n => n.startsWith('postgres'))) {
    driver = 'postgres'
    baseName = 'postgres'
  } else if (!existingNames.some(n => n.startsWith('mysql'))) {
    driver = 'mysql'
    baseName = 'mysql'
  } else if (!existingNames.some(n => n.startsWith('sqlserver'))) {
    driver = 'sqlserver'
    baseName = 'sqlserver'
  }

  const name = generateUniqueConnectionName(baseName, existingNames)
  const item = {
    _id: Date.now(),
    name,
    driver
  }

  if (driver === 'postgres') {
    return {
      ...item,
      host: 'env("POSTGRES_HOST", "localhost")',
      port: 'env("POSTGRES_PORT", "5432")',
      database: 'env("POSTGRES_DB", "mydb")',
      schema: 'env("POSTGRES_SCHEMA", "public")',
      user: 'env("POSTGRES_USER", "postgres")',
      password: 'env("POSTGRES_PASSWORD", "")'
    }
  } else if (driver === 'mysql') {
    return {
      ...item,
      host: 'env("MYSQL_HOST", "localhost")',
      port: 'env("MYSQL_PORT", "3306")',
      database: 'env("MYSQL_DB", "mydb")',
      user: 'env("MYSQL_USER", "root")',
      password: 'env("MYSQL_PASSWORD", "")'
    }
  } else if (driver === 'sqlserver') {
    return {
      ...item,
      host: 'env("SQLSERVER_HOST", "localhost")',
      port: 'env("SQLSERVER_PORT", "1433")',
      database: 'env("SQLSERVER_DB", "mydb")',
      user: 'env("SQLSERVER_USER", "sa")',
      password: 'env("SQLSERVER_PASSWORD", "")'
    }
  }

  return item
}

const getDefaultS3Item = () => ({
  _id: Date.now(),
  name: generateUniqueConnectionName('s3_bucket', props.s3Connections.map(c => c.name)),
  bucket: 'env("S3_BUCKET", "my-bucket")',
  region: 'env("S3_REGION", "us-east-1")',
  endpoint: 'env("S3_ENDPOINT", "")',
  access_key: 'env("S3_ACCESS_KEY", "")',
  secret_key: 'env("S3_SECRET_KEY", "")',
  static_hosting: false
})
</script>
