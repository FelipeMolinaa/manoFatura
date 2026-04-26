---
description: Help configure Godot project export settings
---

Help configure export settings for distributing a Godot game.

**Ask the user for:**
1. Target platform (Linux, Windows, macOS, Web, Android, iOS)
2. Build type (Debug or Release)
3. Export location/name

**Provide guidance on:**

1. **Export Presets** (Project → Export):
   - Create preset for target platform
   - Configure export settings
   - Set custom features if needed

2. **Export via command line:**
```bash
# Linux
godot --headless --export-release "Linux/X11" builds/game.x86_64

# Windows
godot --headless --export-release "Windows Desktop" builds/game.exe

# Web (HTML5)
godot --headless --export-release "Web" builds/index.html

# Android
godot --headless --export-release "Android" builds/game.apk
```

3. **Common export settings:**
   - Executable name
   - Icon and splash screen
   - Embed PCK (yes for single-file distribution)
   - Encryption key (for asset protection)
   - Custom features for conditional compilation

4. **Build script template** (tasks.json):
```json
{
  "label": "Export Game",
  "type": "shell",
  "command": "godot",
  "args": [
    "--headless",
    "--export-release",
    "Linux/X11",
    "${workspaceFolder}/builds/game_${command:pickString}.x86_64"
  ]
}
```

5. **Distribution checklist:**
   - [ ] Test on target platform
   - [ ] Include LICENSE.txt if needed
   - [ ] Package assets that can't be embedded
   - [ ] Create installer (optional)
   - [ ] Upload to itch.io, Steam, etc.

**Platform-specific notes:**
- **Linux:** May need to set executable permissions (`chmod +x`)
- **Windows:** May need Visual C++ redistributables
- **Web:** Requires HTTPS for some features, SharedArrayBuffer
- **Android:** Needs Android SDK, keystore for signing
- **iOS:** Requires macOS, Xcode, Apple Developer account
