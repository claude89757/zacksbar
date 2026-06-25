import { createMessage } from '../lib/protocol.js';

const HOST_NAME = 'com.zacksbar.native';
let nativePort = null;

function connectNativeHost() {
  if (nativePort) return nativePort;
  nativePort = chrome.runtime.connectNative(HOST_NAME);
  nativePort.onDisconnect.addListener(() => {
    nativePort = null;
  });
  nativePort.onMessage.addListener((message) => {
    if (message.type === 'tab.open' && message.payload?.url) {
      chrome.tabs.create({ url: message.payload.url });
    }
  });
  nativePort.postMessage(createMessage('health.ping', {
    component: 'zacksbar-companion',
    version: chrome.runtime.getManifest().version
  }, 'service-worker'));
  return nativePort;
}

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  const port = connectNativeHost();
  port.postMessage({
    ...message,
    payload: {
      ...(message.payload || {}),
      tabId: sender.tab?.id || null
    }
  });
  sendResponse({ ok: true });
  return true;
});

chrome.runtime.onInstalled.addListener(() => {
  connectNativeHost();
});
