// Shared helpers for .env handling across settings, new project, and project detail screens.
// Keep these pure and reuse everywhere to avoid drift in parsing/serialization logic.

export const DEFAULT_ENV_TEMPLATE = `# Framework environment defaults
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
S3_ENDPOINT=`

export const parseEnvContent = (raw = '') => {
  const result = {}
  raw.split(/\r?\n/).forEach((line) => {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith('#') || !trimmed.includes('=')) return
    const [key, ...rest] = trimmed.split('=')
    result[key.trim()] = rest.join('=').replace(/^"|"$/g, '')
  })
  return result
}

export const stringifyEnvVariables = (vars = {}) =>
  Object.entries(vars)
    .map(([key, value]) => `${key}=${value ?? ''}`)
    .join('\n')

export const groupEnvByPrefix = (vars = {}) => {
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

// Normalize any env config (raw string or { raw, variables }) into unified state for components.
export const normalizeEnvConfig = (envConfig, fallbackRaw = DEFAULT_ENV_TEMPLATE) => {
  let raw = fallbackRaw
  if (typeof envConfig === 'string') {
    raw = envConfig
  } else if (envConfig?.raw) {
    raw = envConfig.raw
  } else if (envConfig?.variables) {
    raw = stringifyEnvVariables(envConfig.variables)
  }

  const variables = parseEnvContent(raw)
  const groups = groupEnvByPrefix(variables)

  return {
    rawContent: raw,
    variables,
    groups,
    viewMode: 'grouped'
  }
}
