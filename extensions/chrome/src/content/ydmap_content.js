(function installZacksBarContent(global) {
  const CAPTCHA_PATTERN = /拖动滑块|向右滑动|请完成.{0,6}验证|完成验证|滑动验证|按住左边滑块/;
  const SCHEMA_VERSION = 1;

  function redactUrl(rawUrl) {
    try {
      const url = new URL(rawUrl);
      url.search = '';
      url.hash = '';
      return url.toString();
    } catch {
      return String(rawUrl).split('?')[0].split('#')[0];
    }
  }

  function createMessage(type, payload, source = 'content-script') {
    return {
      schemaVersion: SCHEMA_VERSION,
      messageId: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
      type,
      sentAt: new Date().toISOString(),
      source,
      payload
    };
  }

  function detectCaptchaFromText(text) {
    return CAPTCHA_PATTERN.test(text || '');
  }

  function methodsOf(vm) {
    return vm?.$options?.methods || {};
  }

  function findVueRoot(documentRef = global.document) {
    const nodes = documentRef?.querySelectorAll?.('body *') || [];
    for (const node of nodes) {
      if (node.__vue__) return node.__vue__.$root || node.__vue__;
    }
    return null;
  }

  function walkVueComponents(root) {
    const components = [];
    const seen = new Set();
    function visit(vm, depth) {
      if (!vm || depth > 20 || seen.has(vm)) return;
      seen.add(vm);
      components.push(vm);
      for (const child of vm.$children || []) visit(child, depth + 1);
    }
    visit(root, 0);
    return components;
  }

  function allVueComponents(documentRef = global.document) {
    return walkVueComponents(findVueRoot(documentRef));
  }

  function findScheduleTable(documentRef = global.document) {
    return allVueComponents(documentRef).find((vm) => (
      methodsOf(vm).onSelect && (vm._data?.rows || vm.rows)
    )) || null;
  }

  function findScheduleParent(documentRef = global.document) {
    return allVueComponents(documentRef).find((vm) => (
      methodsOf(vm).sure && methodsOf(vm).agreementSure
    )) || null;
  }

  function pad2(value) {
    return String(value).padStart(2, '0');
  }

  function formatYdmapTime(value) {
    if (typeof value === 'string') {
      const match = value.match(/\b(\d{1,2}):(\d{2})\b/);
      if (match) return `${pad2(match[1])}:${match[2]}`;
      const parsed = Date.parse(value);
      if (Number.isFinite(parsed)) return formatYdmapTime(parsed);
    }
    if (typeof value === 'number' && Number.isFinite(value)) {
      const date = new Date(value);
      return `${pad2(date.getHours())}:${pad2(date.getMinutes())}`;
    }
    return null;
  }

  function currentDateLabel(parent) {
    const data = parent?._data || {};
    const current = data.curDate || parent?.curDate;
    const list = data.serverData?.dateDataList || parent?.serverData?.dateDataList || [];
    const matched = Array.isArray(list)
      ? list.find((date) => date.day === current || date.dayName === current)
      : null;
    return String(matched?.dayName || current || 'latest');
  }

  function courtFromPlatform(platform, col) {
    const name = String(platform?.venueName || platform?.name || `列${col + 1}`);
    const id = String(
      platform?.venueId ||
      platform?.id ||
      platform?.platformId ||
      platform?.resourceId ||
      name ||
      `court-${col + 1}`
    );
    return { id, name };
  }

  function cellAvailable(table, cell) {
    if (!cell) return false;
    try {
      if (typeof table.isAvailableStatic === 'function') return Boolean(table.isAvailableStatic(cell));
    } catch {
      return false;
    }
    if (typeof cell.available === 'boolean') return cell.available;
    if (typeof cell.status === 'string') return /available|可订|空闲/.test(cell.status);
    if (typeof cell.className === 'string') return /available|可订|empty|free/.test(cell.className);
    return false;
  }

  function normalizeAvailability({ venue, pageUrl, dateLabel, courts, rows }) {
    return {
      venue: venue || 'unknown ydmap venue',
      pageUrl: redactUrl(pageUrl || global.location?.href || ''),
      dateLabel: dateLabel || 'latest',
      courts: Array.isArray(courts) ? courts.map((court) => ({
        id: String(court.id),
        name: String(court.name)
      })) : [],
      slots: Array.isArray(rows)
        ? rows.flat().filter(Boolean).map((slot) => ({
            courtId: String(slot.courtId),
            start: String(slot.start),
            end: String(slot.end),
            available: Boolean(slot.available)
          }))
        : []
    };
  }

  function selectContinuousRange(slots, start, end) {
    const byCourt = new Map();
    for (const slot of slots.filter((candidate) => candidate.available)) {
      const group = byCourt.get(slot.courtId) || [];
      group.push(slot);
      byCourt.set(slot.courtId, group);
    }

    for (const group of byCourt.values()) {
      const sorted = group.slice().sort((a, b) => a.start.localeCompare(b.start));
      const selected = [];
      let cursor = start;
      for (const slot of sorted) {
        if (slot.start === cursor) {
          selected.push(slot);
          cursor = slot.end;
        }
        if (cursor === end) return selected;
      }
    }

    return [];
  }

  function buildAvailabilityMessage(snapshot) {
    return createMessage('availability.updated', normalizeAvailability(snapshot), 'content-script');
  }

  function buildCaptchaMessage(pageUrl, textEvidence) {
    return createMessage('captcha.detected', {
      pageUrl: redactUrl(pageUrl),
      reason: 'captcha-text-match',
      textEvidence: String(textEvidence || '').slice(0, 80)
    }, 'content-script');
  }

  function inspectCurrentPage() {
    const bodyText = global.document?.body?.innerText || '';
    if (detectCaptchaFromText(bodyText)) {
      global.chrome.runtime.sendMessage(buildCaptchaMessage(global.location.href, bodyText));
    }
  }

  function extractYdmapAvailability(documentRef = global.document, locationRef = global.location) {
    const table = findScheduleTable(documentRef);
    if (!table) return null;
    const parent = findScheduleParent(documentRef);
    const rows = table._data?.rows || table.rows || [];
    if (!Array.isArray(rows) || rows.length === 0) return null;

    const columnCount = Math.max(
      table.platformInColumns?.length || 0,
      ...rows.map((row) => Array.isArray(row) ? row.length : 0)
    );
    if (columnCount === 0) return null;

    const courts = Array.from({ length: columnCount }, (_, col) => (
      courtFromPlatform((table.platformInColumns || [])[col], col)
    ));

    const slotRows = rows.map((row) => Array.isArray(row)
      ? row.map((cell, col) => {
          if (!cell) return null;
          const start = formatYdmapTime(cell.startTime || cell.start || cell.beginTime);
          const end = formatYdmapTime(cell.endTime || cell.end || cell.finishTime);
          if (!start || !end) return null;
          return {
            courtId: courts[col]?.id || `court-${col + 1}`,
            start,
            end,
            available: cellAvailable(table, cell)
          };
        })
      : []
    );

    return normalizeAvailability({
      venue: documentRef?.title?.trim() || locationRef?.hostname || 'ydmap venue',
      pageUrl: locationRef?.href || '',
      dateLabel: currentDateLabel(parent),
      courts,
      rows: slotRows
    });
  }

  global.ZacksBarContent = {
    detectCaptchaFromText,
    extractYdmapAvailability,
    findScheduleParent,
    findScheduleTable,
    formatYdmapTime,
    normalizeAvailability,
    selectContinuousRange,
    buildAvailabilityMessage,
    buildCaptchaMessage,
    inspectCurrentPage
  };

  if (global.chrome?.runtime && global.document) {
    global.setInterval(inspectCurrentPage, 1500);
    inspectCurrentPage();
  }
})(globalThis);
