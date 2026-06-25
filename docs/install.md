# Install ZacksBar Development Build

1. Build the macOS package:

   ```bash
   cd apps/macos
   swift build
   ```

2. Load `extensions/chrome` as an unpacked extension in `chrome://extensions`.

3. Copy the unpacked extension ID from Chrome.

4. Install the native host manifest:

   ```bash
   ./scripts/install-native-host.sh "$(pwd)/apps/macos/.build/debug/zacksbar-native-host" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
   ```

5. Open a supported ydmap booking page.

6. Run the app:

   ```bash
   cd apps/macos
   swift run ZacksBarApp
   ```
