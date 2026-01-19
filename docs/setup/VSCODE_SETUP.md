# VS Code Swift Development Setup

> Develop Pomodoro Overlay in VS Code with Swift Package Manager

---

## Prerequisites

✅ Already have on macOS:
- Swift toolchain (comes with Xcode Command Line Tools)
- Swift Package Manager (bundled with Swift)

---

## VS Code Setup

### 1. Install Swift Extension

1. Open VS Code
2. Extensions (⌘⇧X)
3. Search: **Swift** by sswg
4. Install extension

### 2. Optional: CodeLLDB for Debugging

1. Extensions → Search: **CodeLLDB**
2. Install extension
3. Enables breakpoints and step debugging

---

## Building & Running

### Build the app
```bash
swift build
```

### Run the app
```bash
swift run
```

### Build for release (optimized)
```bash
swift build -c release
```

### Run tests
```bash
swift test
```

### Clean build artifacts
```bash
swift package clean
```

---

## Development Workflow

### Quick iteration loop:
```bash
# edit code in VS Code
swift run
# app launches, test changes
# Ctrl+C to quit
# repeat
```

### With live reload (manual):
```bash
# Terminal 1: watch for changes
fswatch -o PomodoroOverlay | xargs -n1 -I{} swift run

# Edit files in VS Code, app auto-rebuilds on save
```

---

## Project Structure

Swift Package Manager uses this structure:
```
pomodoro-overlay/
├── Package.swift              # SPM manifest
├── PomodoroOverlay/           # source files (already set up)
│   ├── pomodoro-overlay-app.swift
│   ├── timer-model.swift
│   └── ...
└── Tests/                     # test files (create when needed)
    └── PomodoroOverlayTests/
```

All your Swift files are already in `PomodoroOverlay/` directory ✅

---

## What Works in VS Code

✅ **Full development**:
- Code editing with syntax highlighting
- IntelliSense (autocomplete)
- Jump to definition
- Find references
- Build from terminal
- Run and debug
- Git integration
- GitHub Copilot

✅ **Command-line workflow**:
- `swift build` - compile
- `swift run` - launch app
- `swift test` - run tests
- Full access to all Swift features

---

## What Doesn't Work

❌ **Xcode-specific features**:
- Interface Builder (not needed, using SwiftUI code)
- SwiftUI Canvas/Preview (not needed, just run the app)
- Xcode Instruments (profiling)
- Asset catalog GUI (can edit files directly)
- Storyboards (not used in this project)

**None of these are needed for this project!** Everything is pure SwiftUI code.

---

## Building the App Bundle (.app)

To create a distributable `.app`:

```bash
# 1. Build release binary
swift build -c release

# 2. Create app bundle structure
mkdir -p PomodoroOverlay.app/Contents/MacOS
mkdir -p PomodoroOverlay.app/Contents/Resources

# 3. Copy binary
cp .build/release/PomodoroOverlay PomodoroOverlay.app/Contents/MacOS/

# 4. Create Info.plist
cp Info.plist PomodoroOverlay.app/Contents/

# 5. Run the app
open PomodoroOverlay.app
```

Or use the build script (coming in Unit 6).

---

## Debugging in VS Code

Create `.vscode/launch.json`:
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "lldb",
            "request": "launch",
            "name": "Debug PomodoroOverlay",
            "program": "${workspaceFolder}/.build/debug/PomodoroOverlay",
            "args": [],
            "cwd": "${workspaceFolder}",
            "preLaunchTask": "swift-build"
        }
    ]
}
```

Create `.vscode/tasks.json`:
```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "swift-build",
            "type": "shell",
            "command": "swift build",
            "group": {
                "kind": "build",
                "isDefault": true
            }
        }
    ]
}
```

Then press F5 to debug with breakpoints!

---

## First Build

Let's verify everything works:

```bash
# Navigate to project
cd /Users/isa/Desktop/python-projects/pomodoro-overlay

# Build
swift build

# If successful, run
swift run
```

Expected: App window appears as floating overlay.

---

## Advantages of VS Code + SPM

1. **Copilot works great** (your main reason!)
2. **Faster iteration** - `swift run` is quicker than Xcode build
3. **Lighter weight** - No Xcode bloat
4. **Better Git integration** - VS Code Git UI
5. **Portable** - Works on Linux too (for non-GUI code)
6. **Scriptable** - Easy CI/CD integration

---

## When You Need Xcode

Only for:
- **Final distribution** - Code signing and notarization (can use command line too)
- **Performance profiling** - Instruments (rarely needed)
- **Asset catalogs** - If you add complex assets later

For now, VS Code + SPM is perfect! 🎉

---

*VS Code setup guide version 1.0*
