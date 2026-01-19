// timer-view.swift
// main timer overlay view container

import SwiftUI

/// main timer overlay view
struct TimerView: View {
    @ObservedObject var timerModel: TimerModel
    @ObservedObject var settings: PomodoroSettings
    
    @State private var showingSettings = false
    
    var body: some View {
        GeometryReader { geometry in
            let isMicroMode = geometry.size.width < 420 || geometry.size.height < 470
            
            ZStack {
                // blur background with opacity
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .opacity(settings.validatedOpacity)
                
                if isMicroMode {
                    microModeContent
                } else {
                    normalModeContent
                }
            }
        }
        .frame(minWidth: 350, minHeight: 92)
        .sheet(isPresented: $showingSettings) {
            SettingsView(settings: settings)
        }
    }
    
    // MARK: - Normal Mode Layout
    
    private var normalModeContent: some View {
        VStack(spacing: 10) {
            // progress ring with embedded controls
            ProgressRingView(timerModel: timerModel, settings: settings)
                .frame(maxWidth: 380, maxHeight: 380)
                .padding(.horizontal, 10)
            
            // settings button with task type label
            Button {
                showingSettings = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape")
                    Text("Settings")
                    Text("•")
                    Text(settings.currentTaskType.displayName.lowercased())
                }
                .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(10)
    }
    
    // MARK: - Micro Mode Layout
    
    private var microModeContent: some View {
        HStack(spacing: 12) {
            // mini progress circle
            MiniProgressRing(timerModel: timerModel)
                .frame(width: 50, height: 50)
                .padding(.bottom, 10)
            
            // countdown timer
            Text(timerModel.timeRemainingFormatted)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
                .padding(.bottom, 10)
            
            Spacer()
                .frame(maxWidth: 20)
            
            // play/pause button
            Button(action: { primaryAction() }) {
                Image(systemName: primaryIcon)
                    .font(.system(size: 14))
            }
            .frame(width: 32, height: 32)
            .buttonStyle(.borderedProminent)
            .tint(primaryTint)
            .help(primaryTooltip)
            .padding(.bottom, 10)
            
            // stop button
            if timerModel.currentState != .idle {
                Button(action: { timerModel.stop() }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 12))
                }
                .frame(width: 32, height: 32)
                .buttonStyle(.bordered)
                .help("Stop")
                .padding(.bottom, 10)
            }
            
            // reset menu
            Menu {
                Button("Reset Session") {
                    timerModel.resetSession()
                }
                
                Divider()
                
                Button("Reset Pomodoro", role: .destructive) {
                    timerModel.resetPomodoro()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .frame(width: 43, height: 32)
            .buttonStyle(.bordered)
            .help("Reset")
            .padding(.bottom, 10)
            
            // settings button (icon only)
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 12))
            }
            .frame(width: 32, height: 32)
            .buttonStyle(.bordered)
            .help("Settings")
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    // MARK: - Button Helpers
    
    private func primaryAction() {
        switch timerModel.currentState {
        case .idle, .workComplete, .breakComplete, .paused:
            timerModel.start()
        case .working, .shortBreak, .longBreak:
            timerModel.pause()
        }
    }
    
    private var primaryIcon: String {
        switch timerModel.currentState {
        case .idle, .workComplete, .breakComplete, .paused:
            return "play.fill"
        case .working, .shortBreak, .longBreak:
            return "pause.fill"
        }
    }
    
    private var primaryTint: Color {
        switch timerModel.currentState {
        case .idle, .workComplete, .paused(_, .working):
            return .red
        case .breakComplete, .paused(_, .shortBreak), .paused(_, .longBreak):
            return .green
        case .working:
            return .orange
        case .shortBreak, .longBreak:
            return .mint
        }
    }
    
    private var primaryTooltip: String {
        switch timerModel.currentState {
        case .idle:
            return "Start work session"
        case .working:
            return "Pause timer"
        case .paused:
            return "Resume timer"
        case .workComplete:
            return "Start break"
        case .breakComplete:
            return "Start next work session"
        case .shortBreak, .longBreak:
            return "Pause break"
        }
    }
}

// MARK: - Mini Progress Ring

struct MiniProgressRing: View {
    @ObservedObject var timerModel: TimerModel
    
    private let lineWidth: CGFloat = 4
    
    private var progress: Double {
        timerModel.progress
    }
    
    private var ringColor: Color {
        switch timerModel.currentState {
        case .working, .paused(_, .working):
            return .red
        case .shortBreak, .longBreak, .paused(_, .shortBreak), .paused(_, .longBreak):
            return .green
        case .workComplete:
            return .orange
        case .breakComplete:
            return .blue
        case .idle:
            return .gray
        }
    }
    
    var body: some View {
        ZStack {
            // background track
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
            
            // progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
        }
    }
}
