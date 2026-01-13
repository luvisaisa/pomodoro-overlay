// pomodoro-settings.swift
// data model for user preferences and task type configurations

import Foundation
import SwiftUI

/// task type with pre-configured pomodoro durations
enum TaskType: String, CaseIterable, Identifiable {
    case admin
    case study
    case deep
    case creative
    
    var id: String { rawValue }
    
    /// work session duration in minutes
    var workMinutes: Int {
        switch self {
        case .admin: return 20
        case .study: return 25
        case .deep: return 45
        case .creative: return 60
        }
    }
    
    /// short break duration in minutes
    var shortBreakMinutes: Int {
        switch self {
        case .admin: return 5
        case .study: return 5
        case .deep: return 10
        case .creative: return 15
        }
    }
    
    /// long break duration in minutes
    var longBreakMinutes: Int {
        switch self {
        case .admin: return 15
        case .study: return 25
        case .deep: return 40
        case .creative: return 60
        }
    }
    
    /// number of work sessions before long break
    var sessionsBeforeLongBreak: Int {
        switch self {
        case .admin: return 3
        case .study: return 4
        case .deep: return 3
        case .creative: return 2
        }
    }
    
    /// display name for ui
    var displayName: String {
        rawValue.capitalized
    }
}

/// user preferences and settings model
class PomodoroSettings: ObservableObject {
    
    // task configuration
    @AppStorage("selectedTaskType") var taskType: String = TaskType.study.rawValue
    
    // ui preferences
    @AppStorage("windowOpacity") var opacity: Double = 0.9
    @AppStorage("fontSize") var fontSize: Double = 24.0
    
    // window position (encoded as json)
    @AppStorage("windowFrame") var windowFrameData: Data?
    
    // session tracking (for recovery)
    @AppStorage("lastCompletedSessions") var lastCompletedSessions: Int = 0
    
    /// current task type (computed from stored string)
    var currentTaskType: TaskType {
        get { TaskType(rawValue: taskType) ?? .study }
        set { taskType = newValue.rawValue }
    }
    
    /// validate and clamp opacity to safe range
    var validatedOpacity: Double {
        min(max(opacity, 0.5), 1.0)
    }
    
    /// validate and clamp font size to readable range
    var validatedFontSize: Double {
        min(max(fontSize, 18.0), 48.0)
    }
    
    /// reset to default values
    func resetToDefaults() {
        taskType = TaskType.study.rawValue
        opacity = 0.9
        fontSize = 24.0
        windowFrameData = nil
        lastCompletedSessions = 0
    }
}

/// window frame persistence helper
struct WindowFrame: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    
    init(rect: CGRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.size.width
        self.height = rect.size.height
    }
    
    func toCGRect() -> CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}
