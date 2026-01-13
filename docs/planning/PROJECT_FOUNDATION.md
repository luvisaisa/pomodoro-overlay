# PROJECT FOUNDATION — Pomodoro Overlay

> Last updated: 2026-01-13

---

## Project Overview

**Pomodoro Overlay** is a native macOS desktop utility that provides an always-visible, non-intrusive timer overlay for productivity sessions. Built with Swift and SwiftUI, it offers a transparent, floating window that stays on top of all applications without disrupting workflow.

The app implements the Pomodoro Technique with pre-configured task types, visual progress indication, and persistent customization across sessions.

---

## Goals and Objectives

### Primary Goals
1. **Zero-friction timer** — Start/stop sessions without leaving current work context
2. **Always visible** — Timer overlay remains on screen regardless of active application
3. **Non-intrusive** — Doesn't steal focus or interrupt workflow
4. **Persistent state** — Remembers position, settings, and preferences across restarts

### Success Criteria
- Timer visible at all times without covering critical workspace
- Window position persists between app launches
- No focus stealing or keyboard/mouse capture
- Notifications delivered reliably at session boundaries
- Settings changes apply immediately without restart

---

## Scope

### In Scope

**Core Functionality**
- Always-on-top floating window with semi-transparent background
- Progress ring with countdown timer display
- Four pre-configured task types (ADMIN, STUDY, DEEP, CREATIVE)
- Timer controls:
  - **Start**: Begin work session or break
  - **Pause**: Temporarily halt current timer
  - **Stop**: End current session early
  - **Reset**: Reset current session OR reset entire pomodoro sequence
- System notifications when sessions complete
- Menu bar integration with live countdown

**Customization**
- Resizable window with saved dimensions
- Adjustable font size with persistence
- Window position memory across launches and monitors
- Opacity/transparency controls

**Task Type Presets**
| Type | Work (min) | Short Break (min) | Sessions Before Long | Long Break (min) |
|------|-----------|-------------------|---------------------|------------------|
| ADMIN | 20 | 5 | 3 | 15 |
| STUDY | 25 | 5 | 4 | 25 |
| DEEP | 45 | 10 | 3 | 40 |
| CREATIVE | 60 | 15 | 2 | 60 |

### Out of Scope (v1.0)
- Statistics/analytics/history tracking
- Cloud sync or multi-device support
- Custom task types or timer configurations
- Integration with external tools (Slack, calendar, etc.)
- iOS/iPadOS companion app
- Themes or color customization

### Future Considerations
- **Idle detection system**:
  - Monitor system activity (active apps, mouse movement, typing)
  - Webcam-based phone detection (using existing ML models)
  - Auto-pause suggestions when idle detected
  - Notification every 20 seconds when idling without pause/break
- **Siri integration**: Voice commands for timer control
- Statistics dashboard with session history
- Customizable task types
- Keyboard shortcuts for all controls
- Sound effects library
- Focus mode integrations (Do Not Disturb, etc.)

---

## Constraints and Assumptions

### Technical Constraints
- **Platform**: macOS 13.0+ (Ventura or later)
- **Architecture**: Apple Silicon and Intel (universal binary)
- **Framework**: SwiftUI with AppKit interop for window management
- **Distribution**: Standalone .app bundle (no App Store initially)
- **Dependencies**: Minimal — native frameworks only

### Design Constraints
- Window must not interfere with system UI (menu bar, dock, mission control)
- Must respect system accessibility settings
- Transparency must remain readable in all scenarios
- Minimum window size must accommodate timer + controls

### Performance Constraints
- CPU usage < 1% when idle
- Memory footprint < 50MB
- Timer accuracy within 1 second over 60-minute session
- Notification delivery < 500ms after session end

### Assumptions
- User has macOS 13.0 or later
- User grants notification permissions
- Single monitor is primary use case (multi-monitor is bonus)
- English-only UI (v1.0)
- User wants standard Pomodoro ratios (defined task types)

---

## High-Level Architecture Vision

### Application Structure

```
┌─────────────────────────────────────┐
│         PomodoroOverlayApp          │
│  - AppDelegate configuration        │
│  - Window lifecycle management      │
│  - Notification registration        │
└─────────────────────────────────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
┌───▼────┐  ┌───▼────┐  ┌───▼────┐
│ Timer  │  │Settings│  │MenuBar │
│  View  │  │  View  │  │ Widget │
└────────┘  └────────┘  └────────┘
     │
┌────▼────────────────────────────┐
│       TimerModel                │
│  - State machine                │
│  - Countdown logic              │
│  - Session tracking             │
└─────────────────────────────────┘
     │
┌────▼────────────────────────────┐
│    PomodoroSettings             │
│  - Task type selection          │
│  - Duration configurations      │
│  - UI preferences               │
│  - Persistence (UserDefaults)   │
└─────────────────────────────────┘
```

### Core Components

**1. Overlay Window Manager**
- `NSPanel` configured as floating, non-activating panel
- Always-on-top window level (`.floating`)
- Custom frame with blur/transparency material
- Position persistence using `NSWindow.frame` → `UserDefaults`

**2. Timer State Machine**
```
IDLE → WORKING → [PAUSED] → WORK_COMPLETE → 
  SHORT_BREAK → [PAUSED] → BREAK_COMPLETE → 
  WORKING → ... → LONG_BREAK → IDLE
```

**3. Settings Model**
- Pre-configured task types with duration tables
- Window preferences (size, position, opacity, font size)
- Persisted via `@AppStorage` and `UserDefaults`

**4. Notification Service**
- `UNUserNotificationCenter` for session completion alerts
- Request permission on first launch
- Custom notification content per session type

**5. Menu Bar Integration**
- `NSStatusItem` with live countdown text
- Quick access to start/pause/reset
- Settings panel trigger

### Data Flow

```
User Action → TimerView → TimerModel → State Update
     ↓                                      ↓
Settings Change → PomodoroSettings → UserDefaults
     ↓                                      ↓
Timer Complete → NotificationService → System Alert
```

### Technology Stack

| Layer | Technology |
|-------|------------|
| UI Framework | SwiftUI |
| Window Management | AppKit (NSPanel, NSWindow) |
| State Management | Combine + ObservableObject |
| Persistence | UserDefaults, @AppStorage |
| Notifications | UserNotifications framework |
| Build System | Xcode 15+, Swift 5.9+ |
| Distribution | Standalone .app bundle |

---

## Development Approach

### Phase-Based Implementation
1. **Phase 1**: Core timer logic and state machine
2. **Phase 2**: Overlay window behavior (always-on-top, transparency)
3. **Phase 3**: Settings and customization
4. **Phase 4**: Position persistence and multi-monitor support
5. **Phase 5**: Menu bar, notifications, polish

### Testing Strategy
- Unit tests for timer state machine
- Integration tests for settings persistence
- Manual testing for window behavior (no easy automation)
- Multi-monitor testing on various configurations

### Distribution
- Build universal binary (Apple Silicon + Intel)
- Notarize for Gatekeeper
- Distribute as .dmg or .zip
- Document permission requirements (notifications)

---

## Open Questions

1. **Window controls**: Show native traffic lights (close/minimize/zoom) or custom controls?
2. **Mac sleep behavior**: Should timer auto-pause when Mac goes to sleep?
3. **Session interruption**: What happens if user force-quits during active session?
4. **Accessibility**: VoiceOver support required for v1.0?

**Deferred to Future**:
- Idle detection (system monitoring, webcam, notifications) — post-v1.0
- Siri integration — post-v1.0
- Auto-update mechanism — TBD based on distribution method

---

*End of foundation document.*
