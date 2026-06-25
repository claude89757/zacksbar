export const SCHEMA_VERSION = 1;

export function createMessage(type, payload, source = 'content-script') {
  return {
    schemaVersion: SCHEMA_VERSION,
    messageId: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
    type,
    sentAt: new Date().toISOString(),
    source,
    payload
  };
}

export function redactUrl(rawUrl) {
  try {
    const url = new URL(rawUrl);
    url.search = '';
    url.hash = '';
    return url.toString();
  } catch {
    return String(rawUrl).split('?')[0].split('#')[0];
  }
}
