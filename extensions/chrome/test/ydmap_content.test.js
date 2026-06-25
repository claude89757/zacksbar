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
  buildParserDiagnosticsPayload,
  detectCaptchaFromText,
  extractYdmapAvailability,
  inspectCurrentPage,
  normalizeAvailability,
  selectContinuousRange
} = sandbox.ZacksBarContent;

function makeYdmapDocument() {
  const slot19 = {
    startTime: new Date(2026, 5, 26, 19, 0).getTime(),
    endTime: new Date(2026, 5, 26, 20, 0).getTime(),
    status: 'available'
  };
  const slot20 = {
    startTime: new Date(2026, 5, 26, 20, 0).getTime(),
    endTime: new Date(2026, 5, 26, 21, 0).getTime(),
    status: 'booked'
  };
  const table = {
    $options: { methods: { onSelect() {} } },
    _data: { rows: [[slot19], [slot20]] },
    rows: [[slot19], [slot20]],
    platformInColumns: [{ venueId: 'court-1', venueName: '1号场' }],
    isAvailableStatic(cell) {
      return cell.status === 'available';
    }
  };
  const parent = {
    $options: { methods: { sure() {}, agreementSure() {} } },
    _data: {
      curDate: '2026-06-26',
      serverData: {
        dateDataList: [{ day: '2026-06-26', dayName: '6-26' }]
      }
    }
  };
  const root = { $children: [parent, table] };
  return {
    title: '宝安网球馆',
    body: { innerText: '普通订场页面' },
    querySelectorAll(selector) {
      assert.equal(selector, 'body *');
      return [{ __vue__: { $root: root } }];
    }
  };
}

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

test('extractYdmapAvailability reads ydmap vue table state', () => {
  const payload = JSON.parse(JSON.stringify(extractYdmapAvailability(makeYdmapDocument(), {
    href: 'https://bawtt.ydmap.cn/booking/schedule/example?token=secret'
  })));

  assert.equal(payload.venue, '宝安网球馆');
  assert.equal(payload.pageUrl, 'https://bawtt.ydmap.cn/booking/schedule/example');
  assert.equal(payload.dateLabel, '6-26');
  assert.deepEqual(payload.courts, [{ id: 'court-1', name: '1号场' }]);
  assert.deepEqual(payload.slots, [
    { courtId: 'court-1', start: '19:00', end: '20:00', available: true },
    { courtId: 'court-1', start: '20:00', end: '21:00', available: false }
  ]);
});

test('buildParserDiagnosticsPayload reports missing vue state', () => {
  const document = {
    title: 'empty',
    body: { innerText: '' },
    querySelectorAll() {
      return [];
    }
  };

  const diagnostics = buildParserDiagnosticsPayload(document, {
    href: 'https://bawtt.ydmap.cn/booking/schedule/example?token=secret'
  });

  assert.equal(diagnostics.pageUrl, 'https://bawtt.ydmap.cn/booking/schedule/example');
  assert.equal(diagnostics.vueRootFound, false);
  assert.equal(diagnostics.componentCount, 0);
  assert.equal(diagnostics.scheduleParentFound, false);
  assert.equal(diagnostics.scheduleTableFound, false);
  assert.equal(diagnostics.rowCount, 0);
  assert.equal(diagnostics.slotCount, 0);
});

test('buildParserDiagnosticsPayload reports vue table counts', () => {
  const diagnostics = buildParserDiagnosticsPayload(makeYdmapDocument(), {
    href: 'https://bawtt.ydmap.cn/booking/schedule/example?token=secret'
  });

  assert.equal(diagnostics.vueRootFound, true);
  assert.equal(diagnostics.componentCount, 3);
  assert.equal(diagnostics.scheduleParentFound, true);
  assert.equal(diagnostics.scheduleTableFound, true);
  assert.equal(diagnostics.rowCount, 2);
  assert.equal(diagnostics.columnCount, 1);
  assert.equal(diagnostics.courtCount, 1);
  assert.equal(diagnostics.slotCount, 2);
  assert.equal(diagnostics.availableSlotCount, 1);
});

test('inspectCurrentPage sends one availability update for unchanged snapshot', () => {
  const messages = [];
  sandbox.document = makeYdmapDocument();
  sandbox.location = {
    href: 'https://bawtt.ydmap.cn/booking/schedule/example?token=secret'
  };
  sandbox.chrome = {
    runtime: {
      sendMessage(message) {
        messages.push(JSON.parse(JSON.stringify(message)));
      }
    }
  };

  inspectCurrentPage();
  inspectCurrentPage();

  assert.equal(messages.length, 2);
  assert.equal(messages[0].type, 'parser.diagnostics');
  assert.equal(messages[0].payload.slotCount, 2);
  assert.equal(messages[1].type, 'availability.updated');
  assert.equal(messages[1].payload.slots.length, 2);
});
