// pomodoro-overlay-app.swift
// main application entry point

import SwiftUI

@main
struct PomodoroOverlayApp: App {
    
    @StateObject private var settings = PomodoroSettings()
    @StateObject private var timerModel: TimerModel
    @StateObject private var menuBarManager: MenuBarManager
    
    private let windowManager: WindowManager
    private let notificationManager = NotificationManager.shared
    
    init() {
        let settings = PomodoroSettings()
        let timerModel = TimerModel(settings: settings)
        let menuBarManager = MenuBarManager(timerModel: timerModel)
        let windowManager = WindowManager(settings: settings)
        
        _settings = StateObject(wrappedValue: settings)
        _timerModel = StateObject(wrappedValue: timerModel)
        _menuBarManager = StateObject(wrappedValue: menuBarManager)
        self.windowManager = windowManager
        
        // setup notification callback
        timerModel.onSessionComplete = { sessionType in
            notificationManager.sendSessionComplete(type: sessionType)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            TimerView(timerModel: timerModel, settings: settings)
                .onAppear {
                    setupApp()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
    
    // MARK: - setup
    
    private func setupApp() {
        // configure overlay window
        if let window = NSApp.windows.first {
            windowManager.configureOverlayWindow(window)
        }
        
        // setup menu bar
        menuBarManager.setup()
        
        // request notification permission
        Task {
            let granted = await notificationManager.requestAuthorization()
            if !granted {
                print("notification permission denied")
            }
        }
    }
}
