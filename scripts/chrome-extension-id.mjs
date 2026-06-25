import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function extensionIdFromPublicKey(publicKey) {
  const rawKey = String(publicKey || "").replace(/\s+/g, "");
  if (!rawKey) {
    throw new Error("Chrome extension manifest is missing key");
  }

  const keyBytes = Buffer.from(rawKey, "base64");
  if (keyBytes.length === 0) {
    throw new Error("Chrome extension manifest key is empty");
  }

  const hash = createHash("sha256").update(keyBytes).digest();
  const alphabet = "abcdefghijklmnop";
  let extensionId = "";
  for (const byte of hash.subarray(0, 16)) {
    extensionId += alphabet[byte >> 4];
    extensionId += alphabet[byte & 0x0f];
  }
  return extensionId;
}

export async function extensionIdFromManifest(manifestPath) {
  const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
  return extensionIdFromPublicKey(manifest.key);
}

async function main() {
  const modulePath = fileURLToPath(import.meta.url);
  if (process.argv[1] && path.resolve(process.argv[1]) !== modulePath) {
    return;
  }

  const repoRoot = path.resolve(path.dirname(modulePath), "..");
  const manifestPath = process.argv[2] || path.join(repoRoot, "extensions/chrome/manifest.json");
  process.stdout.write(`${await extensionIdFromManifest(manifestPath)}\n`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
