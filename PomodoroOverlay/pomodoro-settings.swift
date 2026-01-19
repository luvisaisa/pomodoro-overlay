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
    
    // window color (stored as hex string)
    @AppStorage("windowColor") private var windowColorHex: String = "#1E1E1E"
    
    // timer color (for progress ring and timer UI)
    @AppStorage("timerColorHex") private var timerColorHex: String = "#007AFF"
    
    // overlay visibility
    @AppStorage("overlayVisible") var overlayVisible: Bool = true
    
    // color swatches (stored as json array of hex strings)
    @AppStorage("colorSwatches") var colorSwatchesData: Data = Data()
    
    /// current window color
    var windowColor: Color {
        get { Color(hex: windowColorHex) ?? Color(red: 0.12, green: 0.12, blue: 0.12) }
        set { windowColorHex = newValue.toHex() }
    }
    
    /// timer color for progress ring
    var timerColor: Color {
        get { Color(hex: timerColorHex) ?? Color.blue }
        set { 
            objectWillChange.send()
            timerColorHex = newValue.toHex() 
        }
    }
    
    /// saved color swatches
    var colorSwatches: [String] {
        get {
            if let decoded = try? JSONDecoder().decode([String].self, from: colorSwatchesData) {
                return decoded
            }
            return []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                colorSwatchesData = encoded
            }
        }
    }
    
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
    
    /// add current color to swatches
    func saveCurrentColorToSwatches() {
        let hex = windowColorHex
        var swatches = colorSwatches
        if !swatches.contains(hex) {
            swatches.append(hex)
            colorSwatches = swatches
        }
    }
    
    /// remove color from swatches
    func removeColorFromSwatches(_ hex: String) {
        var swatches = colorSwatches
        swatches.removeAll { $0 == hex }
        colorSwatches = swatches
    }
    
    /// reset to default values
    func resetToDefaults() {
        taskType = TaskType.study.rawValue
        opacity = 0.9
        fontSize = 24.0
        windowColorHex = "#1E1E1E"
        colorSwatchesData = Data()
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

/// color hex conversion extension
extension Color {
    /// initialize color from hex string
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    /// convert color to hex string
    func toHex() -> String {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return "#1E1E1E"
        }
        
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
