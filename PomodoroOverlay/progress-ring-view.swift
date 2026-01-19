// progress-ring-view.swift
// circular progress indicator with countdown display

import SwiftUI

/// circular progress ring showing timer countdown
struct ProgressRingView: View {
    @ObservedObject var timerModel: TimerModel
    let settings: PomodoroSettings
    
    private let lineWidth: CGFloat = 10
    
    /// progress from 0.0 (start) to 1.0 (complete)
    private var progress: Double {
        timerModel.progress
    }
    
    /// ring color based on current state
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
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                // background track
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
                    .frame(width: size, height: size)
                
                // progress arc
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        ringColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                
                // center content
                VStack(spacing: 8) {
                    // pause/play button above countdown
                    Button(action: primaryAction) {
                        Image(systemName: primaryIcon)
                            .font(.system(size: 18))
                    }
                    .frame(width: 50, height: 54)
                    .buttonStyle(.borderedProminent)
                    .tint(primaryTint)
                    .help(primaryTooltip)
                    
                    Text(timerModel.timeRemainingFormatted)
                        .font(.system(
                            size: settings.validatedFontSize,
                            weight: .bold,
                            design: .monospaced
                        ))
                        .foregroundColor(.primary)
                    
                    // stop and reset buttons side by side below countdown
                    HStack(spacing: 12) {
                        if timerModel.currentState != .idle {
                            Button(action: { timerModel.stop() }) {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 14))
                            }
                            .frame(width: 40, height: 44)
                            .buttonStyle(.bordered)
                            .help("Stop and reset to idle")
                        }
                        
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
                                .font(.system(size: 14))
                        }
                        .frame(width: 43, height: 40)
                        .buttonStyle(.bordered)
                        .help("Reset options")
                    }
                    
                    if timerModel.currentState.isRunning || timerModel.currentState.isWorking {
                        Text("\(timerModel.completedSessions)/\(timerModel.totalSessionsInCycle)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // state label
                    Text(stateLabel)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .opacity(0.8)
                }
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    // MARK: - button helpers
    
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
    
    
    /// human-readable state label
    private var stateLabel: String {
        let taskName = settings.currentTaskType.displayName
        
        switch timerModel.currentState {
        case .idle:
            return "Ready"
        case .working:
            return "\(taskName) Focus Time"
        case .paused:
            return "Paused"
        case .workComplete:
            return "Work Complete!"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        case .breakComplete:
            return "Break Complete!"
        }
    }
}
