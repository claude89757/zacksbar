import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const source = readFileSync(new URL('../src/content/ydmap_content.js', import.meta.url), 'utf8');
const sandbox = {
  console,
  setInterval() {},
  location: { href: 'https://bawtt.ydmap.cn/booking/schedule/example' },
  URL
};
sandbox.globalThis = sandbox;
vm.createContext(sandbox);
vm.runInContext(source, sandbox);

const {
  detectCaptchaFromText,
  normalizeAvailability,
  selectContinuousRange
} = sandbox.ZacksBarContent;

test('detectCaptchaFromText detects slider captcha copy', () => {
  assert.equal(detectCaptchaFromText('请完成滑动验证后继续'), true);
  assert.equal(detectCaptchaFromText('普通订场页面'), false);
});

test('normalizeAvailability converts grid data to protocol payload', () => {
  const payload = normalizeAvailability({
    venue: 'bawtt tennis',
    pageUrl: 'https://bawtt.ydmap.cn/booking/schedule/example?token=secret',
    dateLabel: 'latest',
    courts: [{ id: 'court-1', name: '1号场' }],
    rows: [
      [{ courtId: 'court-1', start: '19:00', end: '20:00', available: true }],
      [{ courtId: 'court-1', start: '20:00', end: '21:00', available: true }]
    ]
  });

  assert.equal(payload.pageUrl, 'https://bawtt.ydmap.cn/booking/schedule/example');
  assert.equal(payload.slots.length, 2);
  assert.equal(payload.slots[0].available, true);
});

test('selectContinuousRange finds adjacent available slots', () => {
  const slots = [
    { courtId: 'court-1', start: '19:00', end: '20:00', available: true },
    { courtId: 'court-1', start: '20:00', end: '21:00', available: true },
    { courtId: 'court-2', start: '19:00', end: '20:00', available: true }
  ];

  const result = JSON.parse(JSON.stringify(selectContinuousRange(slots, '19:00', '21:00')));
  assert.deepEqual(result, [
    { courtId: 'court-1', start: '19:00', end: '20:00', available: true },
    { courtId: 'court-1', start: '20:00', end: '21:00', available: true }
  ]);
});
