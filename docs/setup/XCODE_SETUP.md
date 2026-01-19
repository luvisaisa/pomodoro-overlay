# Xcode Project Setup Guide

> Instructions for creating and configuring the Xcode project

---

## Quick Start

### 1. Create New Xcode Project

1. Open Xcode
2. File → New → Project
3. Select **macOS** → **App**
4. Configure:
   - **Product Name**: `PomodoroOverlay`
   - **Team**: Your development team
   - **Organization Identifier**: `com.pomodoro` (or your reverse domain)
   - **Bundle Identifier**: `com.pomodoro.overlay`
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Use Core Data**: Unchecked
   - **Include Tests**: Checked
5. Save location: This directory (`pomodoro-overlay/`)

### 2. Add Source Files

1. In Xcode, delete the auto-generated files:
   - `PomodoroOverlayApp.swift` (we have our own)
   - `ContentView.swift` (not needed)
2. Drag all files from `PomodoroOverlay/` into the project navigator:
   - `pomodoro-settings.swift`
   - `timer-model.swift`
   - `window-manager.swift`
   - `notification-manager.swift`
   - `progress-ring-view.swift`
   - `control-buttons-view.swift`
   - `settings-view.swift`
   - `timer-view.swift`
   - `menu-bar-manager.swift`
   - `pomodoro-overlay-app.swift`
3. When prompted, select:
   - ✅ Copy items if needed
   - ✅ Create groups
   - ✅ Add to targets: PomodoroOverlay

### 3. Configure Build Settings

#### General Tab
- **Deployment Target**: macOS 13.0
- **Architectures**: `$(ARCHS_STANDARD)` (Universal Binary)

#### Signing & Capabilities
- **Signing**: Automatic or Manual (your choice)
- **Team**: Select your development team
- Add capability: **App Sandbox** (optional, recommended)
  - If sandboxed, enable: User Selected Files (Read Only)

#### Info Tab
Add these keys (or edit Info.plist):
```xml
<key>NSUserNotificationAlertStyle</key>
<string>alert</string>

<key>LSMinimumSystemVersion</key>
<string>13.0</string>

<!-- Optional: Hide from Dock (menu bar only) -->
<key>LSUIElement</key>
<false/>
```

### 4. Build and Run

1. Select scheme: **PomodoroOverlay**
2. Select target: **My Mac**
3. Press ⌘R to build and run
4. Grant notification permission when prompted
5. Window should appear as floating overlay

---

## Expected Build Warnings/Errors

### Common Issues

**Error: "Cannot find type 'NSPanel'"**
- Fix: Import AppKit in files that use NSWindow/NSPanel
- Already imported in `window-manager.swift`

**Warning: "Publishing changes from background threads"**
- Should not occur (Timer.publish runs on main thread)
- If it does, wrap Combine updates in `DispatchQueue.main.async`

**Error: "Cannot convert value of type 'String' to 'TaskType'"**
- Check `@AppStorage` property wrappers in `pomodoro-settings.swift`
- Should use `.rawValue` for enum storage

---

## Project Structure After Setup

```
PomodoroOverlay.xcodeproj/
PomodoroOverlay/
├── pomodoro-overlay-app.swift          # @main entry point
├── Models/
│   ├── pomodoro-settings.swift
│   ├── timer-model.swift
│   ├── window-manager.swift
│   └── notification-manager.swift
└── Views/
    ├── timer-view.swift
    ├── progress-ring-view.swift
    ├── control-buttons-view.swift
    ├── settings-view.swift
    └── menu-bar-manager.swift
Assets.xcassets/
├── AppIcon.appiconset/
└── AccentColor.colorset/
```

**Optional**: Organize files into Groups in Xcode navigator for cleaner structure.

---

## Verification Checklist

After project setup:

- [ ] Project builds without errors (⌘B)
- [ ] App runs and window appears
- [ ] Window floats above other apps
- [ ] Timer display shows "00:00"
- [ ] Start button responds to clicks
- [ ] Settings button opens preferences sheet
- [ ] Menu bar shows timer icon

If any fail, check [docs/planning/IMPLEMENTATION_PLAN.md](../planning/IMPLEMENTATION_PLAN.md) Unit 5 for troubleshooting.

---

## Next Steps

Once project builds successfully:

1. **Unit 5**: Run tests (see test files in PomodoroOverlayTests/)
2. **Manual Testing**: Work through test checklist
3. **Unit 6**: Configure release build settings

---

*Setup guide version 1.0*
