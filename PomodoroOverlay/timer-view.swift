// timer-view.swift
// main timer overlay view container

import SwiftUI

/// main timer overlay view
struct TimerView: View {
    @ObservedObject var timerModel: TimerModel
    @ObservedObject var settings: PomodoroSettings
    
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            // blur background with opacity
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .opacity(settings.validatedOpacity)
            
            // content
            VStack(spacing: 20) {
                // task type label
                Text(settings.currentTaskType.displayName)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                // progress ring
                ProgressRingView(timerModel: timerModel, settings: settings)
                    .frame(maxWidth: 300, maxHeight: 300)
                    .padding(.horizontal, 20)
                
                // control buttons
                ControlButtonsView(timerModel: timerModel)
                
                // settings button
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding()
        }
        .frame(minWidth: 200, minHeight: 200)
        .sheet(isPresented: $showingSettings) {
            SettingsView(settings: settings)
        }
    }
}
