# Install ZacksBar Development Build

1. Build the macOS package:

   ```bash
   cd apps/macos
   swift build
   ```

2. Load `extensions/chrome` as an unpacked extension in `chrome://extensions`.

3. Copy the unpacked extension ID from Chrome.

4. Run the app:

   ```bash
   cd apps/macos
   swift run ZacksBarApp
   ```

5. Open `Setup Assistant...` from the ZacksBar menu.

6. Paste the Chrome extension ID and choose `Install Native Host`.

7. Refresh the setup assistant. The checklist should show:

   - Chrome Extension ID: the pasted extension ID.
   - Native Host Executable: `ready`.
   - Native Host Manifest: `installed`.

8. Open a supported ydmap booking page and reload it.

9. Refresh the setup assistant again. `Latest Browser State` should show `health.ping`, `availability.updated`, or `captcha.detected`.

## Script Fallback

Install the native host manifest directly:

```bash
./scripts/install-native-host.sh "$(pwd)/apps/macos/.build/debug/zacksbar-native-host" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
```
