import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { chmod, mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { promisify } from "node:util";
import test from "node:test";

import {
  extensionIdFromManifest,
  extensionIdFromPublicKey
} from "../chrome-extension-id.mjs";

const execFileAsync = promisify(execFile);
const repoRoot = path.resolve(import.meta.dirname, "../..");
const expectedDevExtensionId = "nfcmelgclmhkneckkebppdnmbnjpjlho";

test("derives Chrome extension ID from a manifest public key", async () => {
  const manifestPath = path.join(repoRoot, "extensions/chrome/manifest.json");

  assert.equal(await extensionIdFromManifest(manifestPath), expectedDevExtensionId);
});

test("derives Chrome extension ID from raw public key bytes", () => {
  const docsExampleKey = [
    "ThisKeyIsGoingToBeVeryLong/go8GGC2u3UD9WI3MkmBgyiDPP2OreImEQhPvwpliioUMJmERZK3zPAx72z8MDvGp7Fx7ZlzuZpL4yyp4zXBI+MUhFGoqEh32oYnm4qkS4JpjWva5Ktn4YpAWxd4pSCVs8I4MZms20+yx5OlnlmWQEwQiiIwPPwG1e1jRw0Ak5duPpE3uysVGZXkGhC5FyOFM+oVXwc1kMqrrKnQiMJ3lgh59LjkX4z1cDNX3MomyUMJ+I+DaWC2VdHggB74BNANSd+zkPQeNKg3o7FetlDJya1bk8ofdNBARxHFMBtMXu/ONfCT3Q2kCY9gZDRktmNRiHG/1cXhkIcN1RWrbsCkwIDAQAB"
  ].join("");

  assert.match(extensionIdFromPublicKey(docsExampleKey), /^[a-p]{32}$/);
});

test("install-native-host infers extension ID from manifest key when omitted", async () => {
  const tempDir = await mkdtemp(path.join(tmpdir(), "zacksbar-native-host-install-"));
  const hostPath = path.join(tempDir, "zacksbar-native-host");
  const nativeHostDir = path.join(tempDir, "NativeMessagingHosts");
  await writeFile(hostPath, "#!/usr/bin/env bash\nexit 0\n", { mode: 0o755 });
  await chmod(hostPath, 0o755);

  await execFileAsync("bash", ["scripts/install-native-host.sh", hostPath], {
    cwd: repoRoot,
    env: {
      ...process.env,
      ZACKSBAR_CHROME_NATIVE_HOST_DIR: nativeHostDir
    }
  });

  const manifest = JSON.parse(
    await readFile(path.join(nativeHostDir, "com.zacksbar.native.json"), "utf8")
  );
  assert.deepEqual(manifest.allowed_origins, [`chrome-extension://${expectedDevExtensionId}/`]);
  assert.equal(manifest.path, hostPath);
});
