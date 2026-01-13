// progress-ring-view.swift
// circular progress indicator with countdown display

import SwiftUI

/// circular progress ring showing timer countdown
struct ProgressRingView: View {
    @ObservedObject var timerModel: TimerModel
    let settings: PomodoroSettings
    
    private let lineWidth: CGFloat = 12
    
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
                    Text(timerModel.timeRemainingFormatted)
                        .font(.system(
                            size: settings.validatedFontSize,
                            weight: .bold,
                            design: .monospaced
                        ))
                        .foregroundColor(.primary)
                    
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
    
    /// human-readable state label
    private var stateLabel: String {
        switch timerModel.currentState {
        case .idle:
            return "Ready"
        case .working:
            return "Focus Time"
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
