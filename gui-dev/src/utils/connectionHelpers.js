// Helpers for converting connection payloads between API object shape and UI array shape.

const filterFrameworkDb = ([name]) => name !== 'framework_db'

export const mapConnectionsToArrays = (connectionsConfig = {}) => {
  const databasesObj = connectionsConfig.databases || {}
  const storageBucketsObj = connectionsConfig.storage_buckets || {}

  const databaseConnections = Object.entries(databasesObj)
    .filter(filterFrameworkDb)
    .map(([name, conn]) => ({
      _id: name,
      name,
      ...conn
    }))

  const s3Connections = Object.entries(storageBucketsObj).map(([name, conn]) => ({
    _id: name,
    name,
    ...conn
  }))

  // Ensure defaultDatabase/defaultStorageBucket are strings or null (API might return empty object)
  const defaultDb = connectionsConfig.default_database
  const defaultBucket = connectionsConfig.default_storage_bucket

  return {
    databaseConnections,
    s3Connections,
    defaultDatabase: typeof defaultDb === 'string' && defaultDb ? defaultDb : null,
    defaultStorageBucket: typeof defaultBucket === 'string' && defaultBucket ? defaultBucket : null
  }
}

export const mapConnectionsToPayload = ({
  databaseConnections = [],
  s3Connections = [],
  defaultDatabase = null,
  defaultStorageBucket = null
}) => {
  const databases = {}
  databaseConnections.forEach((conn) => {
    const { _id, name, ...fields } = conn || {}
    if (!name) return
    databases[name] = fields
  })

  const storage_buckets = {}
  s3Connections.forEach((conn) => {
    const { _id, name, ...fields } = conn || {}
    if (!name) return
    storage_buckets[name] = fields
  })

  return {
    default_database: defaultDatabase,
    default_storage_bucket: defaultStorageBucket,
    databases,
    storage_buckets
  }
}
