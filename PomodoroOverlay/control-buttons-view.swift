// control-buttons-view.swift
// timer control buttons (start, pause, stop, reset)

import SwiftUI

/// control buttons for timer management
struct ControlButtonsView: View {
    @ObservedObject var timerModel: TimerModel
    
    var body: some View {
        HStack(spacing: 16) {
            // primary action button (start/pause)
            Button(action: primaryAction) {
                Image(systemName: primaryIcon)
                    .font(.system(size: 14))
            }
            .frame(width: 28, height: 28)
            .buttonStyle(.borderedProminent)
            .tint(primaryTint)
            .help(primaryTooltip)
            
            // stop button
            if timerModel.currentState != .idle {
                Button(action: { timerModel.stop() }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14))
                }
                .frame(width: 28, height: 28)
                .buttonStyle(.bordered)
                .help("Stop and reset to idle")
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
                    .font(.system(size: 14))
            }
            .frame(width: 28, height: 28)
            .buttonStyle(.bordered)
            .help("Reset options")
        }
    }
    
    // MARK: - primary button configuration
    
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
