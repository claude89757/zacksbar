import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { chmod, mkdir, mkdtemp, readFile, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { promisify } from "node:util";
import test from "node:test";

const execFileAsync = promisify(execFile);

test("build-macos-app packages app and native host into a launchable bundle", async () => {
  const tempDir = await mkdtemp(path.join(tmpdir(), "zacksbar-app-bundle-"));
  const productsDir = path.join(tempDir, "products");
  const appBundle = path.join(tempDir, "ZacksBar.app");
  await mkdir(productsDir, { recursive: true });
  await writeExecutable(path.join(productsDir, "ZacksBarApp"));
  await writeExecutable(path.join(productsDir, "zacksbar-native-host"));

  const { stdout } = await execFileAsync("bash", ["scripts/build-macos-app.sh"], {
    cwd: path.resolve(import.meta.dirname, "../.."),
    env: {
      ...process.env,
      ZACKSBAR_SKIP_SWIFT_BUILD: "1",
      ZACKSBAR_BUILD_PRODUCTS_DIR: productsDir,
      ZACKSBAR_APP_BUNDLE_PATH: appBundle
    }
  });

  const appExecutable = path.join(appBundle, "Contents/MacOS/ZacksBarApp");
  const nativeHostExecutable = path.join(appBundle, "Contents/MacOS/zacksbar-native-host");
  const plistPath = path.join(appBundle, "Contents/Info.plist");

  assert.match(stdout, /Built .*ZacksBar\.app/);
  assert.equal((await stat(appExecutable)).mode & 0o111, 0o111);
  assert.equal((await stat(nativeHostExecutable)).mode & 0o111, 0o111);

  const plist = await readFile(plistPath, "utf8");
  assert.match(plist, /<key>CFBundleExecutable<\/key>\s*<string>ZacksBarApp<\/string>/);
  assert.match(plist, /<key>CFBundleIdentifier<\/key>\s*<string>com\.zacksbar\.app<\/string>/);
  assert.match(plist, /<key>LSUIElement<\/key>\s*<true\/>/);
});

async function writeExecutable(filePath) {
  await writeFile(filePath, "#!/usr/bin/env bash\nexit 0\n", { mode: 0o755 });
  await chmod(filePath, 0o755);
}
