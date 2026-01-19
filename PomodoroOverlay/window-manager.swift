// window-manager.swift
// window configuration and position persistence

import Foundation
import AppKit

/// manages overlay window configuration and persistence
class WindowManager {
    
    private let settings: PomodoroSettings
    
    init(settings: PomodoroSettings) {
        self.settings = settings
    }
    
    /// configure window as floating overlay panel
    func configureOverlayWindow(_ window: NSWindow) {
        // always on top
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // non-activating (doesn't steal focus)
        if let panel = window as? NSPanel {
            panel.isFloatingPanel = true
            panel.becomesKeyOnlyIfNeeded = true
        }
        
        // visual style
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        
        // standard controls
        window.styleMask = [.titled, .closable, .resizable]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        
        // sizing constraints
        window.minSize = CGSize(width: 350, height: 92)
        window.maxSize = CGSize(width: 800, height: 800)
        
        // restore position if saved
        if let frame = restoreWindowFrame() {
            window.setFrame(frame, display: true)
        } else {
            // set initial size and center on main screen
            let initialSize = CGSize(width: 420, height: 470)
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let origin = CGPoint(
                    x: screenFrame.midX - initialSize.width / 2,
                    y: screenFrame.midY - initialSize.height / 2
                )
                window.setFrame(CGRect(origin: origin, size: initialSize), display: true)
            } else {
                window.setContentSize(initialSize)
                window.center()
            }
        }
        
        // observe position changes
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? NSWindow else { return }
            self?.saveWindowFrame(window.frame)
        }
        
        // observe resize
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: window,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? NSWindow else { return }
            self?.saveWindowFrame(window.frame)
        }
    }
    
    /// save window frame to user defaults
    func saveWindowFrame(_ frame: CGRect) {
        let windowFrame = WindowFrame(rect: frame)
        if let encoded = try? JSONEncoder().encode(windowFrame) {
            settings.windowFrameData = encoded
        }
    }
    
    /// restore window frame from user defaults
    func restoreWindowFrame() -> CGRect? {
        guard let data = settings.windowFrameData,
              let windowFrame = try? JSONDecoder().decode(WindowFrame.self, from: data) else {
            return nil
        }
        
        let frame = windowFrame.toCGRect()
        
        // validate frame is on screen
        guard isFrameOnScreen(frame) else {
            return nil
        }
        
        return frame
    }
    
    /// check if frame intersects any visible screen
    private func isFrameOnScreen(_ frame: CGRect) -> Bool {
        NSScreen.screens.contains { screen in
            screen.visibleFrame.intersects(frame)
        }
    }
}
