import test from 'node:test';
import assert from 'node:assert/strict';

async function loadServiceWorker() {
  const state = {
    nativeHostName: null,
    nativeMessageListener: null,
    runtimeMessageListener: null,
    installedListener: null,
    postedMessages: [],
    reloadCount: 0,
    openedTabs: []
  };
  const nativePort = {
    onDisconnect: {
      addListener() {}
    },
    onMessage: {
      addListener(listener) {
        state.nativeMessageListener = listener;
      }
    },
    postMessage(message) {
      state.postedMessages.push(message);
    }
  };
  globalThis.chrome = {
    runtime: {
      connectNative(hostName) {
        state.nativeHostName = hostName;
        return nativePort;
      },
      getManifest() {
        return { version: '0.1.0' };
      },
      onMessage: {
        addListener(listener) {
          state.runtimeMessageListener = listener;
        }
      },
      onInstalled: {
        addListener(listener) {
          state.installedListener = listener;
        }
      },
      reload() {
        state.reloadCount += 1;
      }
    },
    tabs: {
      create(tab) {
        state.openedTabs.push(tab);
      }
    }
  };

  const module = await import(new URL(`../src/background/service_worker.js?case=${crypto.randomUUID()}`, import.meta.url));
  return { module, state };
}

test('handleNativeMessage reloads the extension on command', async () => {
  const { module, state } = await loadServiceWorker();

  module.handleNativeMessage({ type: 'extension.reload' });

  assert.equal(state.reloadCount, 1);
});

test('handleNativeMessage still opens tabs for tab.open commands', async () => {
  const { module, state } = await loadServiceWorker();

  module.handleNativeMessage({
    type: 'tab.open',
    payload: { url: 'https://bawtt.ydmap.cn/booking/schedule/example' }
  });

  assert.deepEqual(state.openedTabs, [
    { url: 'https://bawtt.ydmap.cn/booking/schedule/example' }
  ]);
});
