import { describe, it, expect } from 'vitest'
import { mapConnectionsToArrays, mapConnectionsToPayload } from '../src/utils/connectionHelpers'

describe('connectionHelpers', () => {
  it('maps config objects to arrays (filters framework_db) and preserves defaults', () => {
    const config = {
      default_database: 'warehouse',
      default_storage_bucket: 's3_bucket',
      databases: {
        framework_db: { driver: 'sqlite', database: 'framework.db' },
        warehouse: { driver: 'postgres', host: 'localhost', port: '5432' }
      },
      storage_buckets: {
        s3_bucket: { bucket: 'my-bucket', region: 'us-east-1' }
      }
    }

    const mapped = mapConnectionsToArrays(config)
    expect(mapped.databaseConnections).toHaveLength(1)
    expect(mapped.databaseConnections[0].name).toBe('warehouse')
    expect(mapped.s3Connections).toHaveLength(1)
    expect(mapped.s3Connections[0].name).toBe('s3_bucket')
    expect(mapped.defaultDatabase).toBe('warehouse')
    expect(mapped.defaultStorageBucket).toBe('s3_bucket')
  })

  it('maps arrays to payload objects and omits unnamed entries', () => {
    const payload = mapConnectionsToPayload({
      defaultDatabase: 'warehouse',
      defaultStorageBucket: 's3_bucket',
      databaseConnections: [
        { _id: '1', name: 'warehouse', driver: 'postgres', host: 'localhost' },
        { _id: '2', driver: 'mysql' } // no name, should be skipped
      ],
      s3Connections: [
        { _id: 's1', name: 's3_bucket', bucket: 'my-bucket' },
        { _id: 's2', bucket: 'missing-name' } // skip
      ]
    })

    expect(payload.default_database).toBe('warehouse')
    expect(payload.default_storage_bucket).toBe('s3_bucket')
    expect(Object.keys(payload.databases)).toEqual(['warehouse'])
    expect(payload.databases.warehouse.driver).toBe('postgres')
    expect(Object.keys(payload.storage_buckets)).toEqual(['s3_bucket'])
    expect(payload.storage_buckets.s3_bucket.bucket).toBe('my-bucket')
  })
})
