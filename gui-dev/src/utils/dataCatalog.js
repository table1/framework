export const createDataAnchorId = (value = '') => {
  const raw = String(value ?? '').trim()
  const sanitized = raw
    .replace(/[^a-zA-Z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .toLowerCase()

  return sanitized ? `data-node-${sanitized}` : 'data-node-root'
}
