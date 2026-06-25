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

  global.ZacksBarContent = {
    detectCaptchaFromText,
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
