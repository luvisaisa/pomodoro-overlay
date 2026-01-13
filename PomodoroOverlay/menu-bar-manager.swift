// menu-bar-manager.swift
// menu bar status item with live countdown

import SwiftUI
import AppKit
import Combine

/// menu bar integration with live countdown
class MenuBarManager: ObservableObject {
    
    private var statusItem: NSStatusItem?
    private var timerModel: TimerModel
    private var cancellables = Set<AnyCancellable>()
    
    init(timerModel: TimerModel) {
        self.timerModel = timerModel
    }
    
    /// setup menu bar status item
    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // initial text
        updateStatusText()
        
        // subscribe to timer updates
        timerModel.$timeRemaining
            .sink { [weak self] _ in
                self?.updateStatusText()
            }
            .store(in: &cancellables)
        
        timerModel.$currentState
            .sink { [weak self] _ in
                self?.updateStatusText()
            }
            .store(in: &cancellables)
        
        // create menu
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(
            title: "Start",
            action: #selector(startTimer),
            keyEquivalent: "s"
        ))
        
        menu.addItem(NSMenuItem(
            title: "Pause",
            action: #selector(pauseTimer),
            keyEquivalent: "p"
        ))
        
        menu.addItem(NSMenuItem(
            title: "Stop",
            action: #selector(stopTimer),
            keyEquivalent: ""
        ))
        
        menu.addItem(.separator())
        
        menu.addItem(NSMenuItem(
            title: "Reset Session",
            action: #selector(resetSession),
            keyEquivalent: ""
        ))
        
        menu.addItem(NSMenuItem(
            title: "Reset Pomodoro",
            action: #selector(resetPomodoro),
            keyEquivalent: ""
        ))
        
        menu.addItem(.separator())
        
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        
        // set targets for actions
        for item in menu.items where item.action != #selector(NSApplication.terminate(_:)) {
            item.target = self
        }
        
        statusItem?.menu = menu
    }
    
    /// update status bar text with countdown
    private func updateStatusText() {
        guard let button = statusItem?.button else { return }
        
        let icon = statusIcon
        let time = timerModel.timeRemainingFormatted
        
        button.title = "\(icon) \(time)"
    }
    
    /// icon based on current state
    private var statusIcon: String {
        switch timerModel.currentState {
        case .idle:
            return "⏸"
        case .working:
            return "🔴"
        case .paused:
            return "⏸"
        case .workComplete:
            return "✅"
        case .shortBreak, .longBreak:
            return "🟢"
        case .breakComplete:
            return "✅"
        }
    }
    
    // MARK: - menu actions
    
    @objc private func startTimer() {
        timerModel.start()
    }
    
    @objc private func pauseTimer() {
        timerModel.pause()
    }
    
    @objc private func stopTimer() {
        timerModel.stop()
    }
    
    @objc private func resetSession() {
        timerModel.resetSession()
    }
    
    @objc private func resetPomodoro() {
        timerModel.resetPomodoro()
    }
}
