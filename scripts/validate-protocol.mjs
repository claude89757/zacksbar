import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import assert from 'node:assert/strict';

const root = new URL('..', import.meta.url).pathname;
const fixturesDir = join(root, 'packages/protocol/fixtures');
const requiredBaseKeys = ['schemaVersion', 'messageId', 'type', 'sentAt', 'source', 'payload'];
const allowedTypes = new Set([
  'page.snapshot',
  'availability.updated',
  'captcha.detected',
  'rule.createDraft',
  'rule.match',
  'tab.open',
  'tab.prefill',
  'health.ping',
  'parser.diagnostics',
  'diagnostics.export'
]);

function readJson(path) {
  return JSON.parse(readFileSync(path, 'utf8'));
}

function validateBaseMessage(message, file) {
  for (const key of requiredBaseKeys) {
    assert.ok(Object.hasOwn(message, key), `${file} missing ${key}`);
  }
  assert.equal(message.schemaVersion, 1, `${file} schemaVersion must be 1`);
  assert.equal(typeof message.messageId, 'string', `${file} messageId must be string`);
  assert.ok(allowedTypes.has(message.type), `${file} type ${message.type} is not allowed`);
  assert.doesNotThrow(() => new Date(message.sentAt).toISOString(), `${file} sentAt must be ISO date`);
  assert.equal(typeof message.payload, 'object', `${file} payload must be object`);
}

for (const file of readdirSync(fixturesDir).filter((name) => name.endsWith('.json'))) {
  validateBaseMessage(readJson(join(fixturesDir, file)), file);
}

console.log('Protocol fixtures valid');
