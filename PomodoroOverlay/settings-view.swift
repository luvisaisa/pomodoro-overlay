// settings-view.swift
// preferences panel for task type and ui customization

import SwiftUI

/// settings and preferences view
struct SettingsView: View {
    @ObservedObject var settings: PomodoroSettings
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            // task type selection
            Section("Task Type") {
                Picker("Mode", selection: $settings.taskType) {
                    ForEach(TaskType.allCases) { taskType in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(taskType.displayName)
                                .font(.headline)
                            Text("\(taskType.workMinutes)m work / \(taskType.shortBreakMinutes)m break")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .tag(taskType.rawValue)
                    }
                }
                .pickerStyle(.inline)
                
                // task type details
                if let taskType = TaskType(rawValue: settings.taskType) {
                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(label: "Work Duration", value: "\(taskType.workMinutes) minutes")
                        DetailRow(label: "Short Break", value: "\(taskType.shortBreakMinutes) minutes")
                        DetailRow(label: "Long Break", value: "\(taskType.longBreakMinutes) minutes")
                        DetailRow(label: "Sessions Before Long", value: "\(taskType.sessionsBeforeLongBreak)")
                    }
                    .font(.caption)
                    .padding(.vertical, 8)
                }
            }
            
            // appearance settings
            Section("Appearance") {
                VStack(alignment: .leading) {
                    Text("Opacity: \(Int(settings.opacity * 100))%")
                        .font(.caption)
                    Slider(value: $settings.opacity, in: 0.5...1.0, step: 0.05)
                }
                
                VStack(alignment: .leading) {
                    Text("Font Size: \(Int(settings.fontSize))")
                        .font(.caption)
                    Slider(value: $settings.fontSize, in: 18...48, step: 2)
                }
            }
            
            // reset button
            Section {
                Button("Reset to Defaults", role: .destructive) {
                    settings.resetToDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 500)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

/// detail row for settings display
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
