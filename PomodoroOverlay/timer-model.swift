// timer-model.swift
// core timer state machine and business logic

import Foundation
import Combine

/// timer state representing current phase of pomodoro cycle
enum TimerState: Equatable {
    case idle
    case working(startTime: Date, totalDuration: TimeInterval)
    case paused(remainingTime: TimeInterval, fromState: PausedFromState)
    case workComplete
    case shortBreak(startTime: Date, totalDuration: TimeInterval)
    case longBreak(startTime: Date, totalDuration: TimeInterval)
    case breakComplete
    
    /// whether timer is actively counting down
    var isRunning: Bool {
        switch self {
        case .working, .shortBreak, .longBreak:
            return true
        default:
            return false
        }
    }
    
    /// whether currently in work session
    var isWorking: Bool {
        if case .working = self { return true }
        return false
    }
    
    /// whether currently in any break
    var isOnBreak: Bool {
        switch self {
        case .shortBreak, .longBreak:
            return true
        default:
            return false
        }
    }
}

/// tracks what state the timer was in before pausing
enum PausedFromState: Equatable {
    case working
    case shortBreak
    case longBreak
}

/// session type for notifications
enum SessionType {
    case work
    case shortBreak
    case longBreak
    
    var displayName: String {
        switch self {
        case .work: return "Work"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
}

/// main timer model managing pomodoro state machine
class TimerModel: ObservableObject {
    
    // published state
    @Published var currentState: TimerState = .idle
    @Published var timeRemaining: TimeInterval = 0
    @Published var completedSessions: Int = 0
    
    // dependencies
    private let settings: PomodoroSettings
    private var timerCancellable: AnyCancellable?
    
    // callbacks
    var onSessionComplete: ((SessionType) -> Void)?
    
    init(settings: PomodoroSettings) {
        self.settings = settings
        self.completedSessions = settings.lastCompletedSessions
    }
    
    // MARK: - computed properties
    
    /// total duration for current phase
    var totalDuration: TimeInterval {
        switch currentState {
        case .working(_, let duration), .shortBreak(_, let duration), .longBreak(_, let duration):
            return duration
        default:
            return 0
        }
    }
    
    /// progress percentage (0.0 to 1.0)
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (timeRemaining / totalDuration)
    }
    
    /// formatted time remaining as mm:ss
    var timeRemainingFormatted: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// total sessions in current cycle before long break
    var totalSessionsInCycle: Int {
        settings.currentTaskType.sessionsBeforeLongBreak
    }
    
    // MARK: - commands
    
    /// start timer based on current state
    func start() {
        switch currentState {
        case .idle:
            startWorkSession()
            
        case .workComplete:
            if completedSessions >= settings.currentTaskType.sessionsBeforeLongBreak {
                startLongBreak()
            } else {
                startShortBreak()
            }
            
        case .breakComplete:
            startWorkSession()
            
        case .paused(let remaining, let fromState):
            resumeFromPause(remaining: remaining, fromState: fromState)
            
        default:
            break
        }
    }
    
    /// pause active timer
    func pause() {
        guard currentState.isRunning else { return }
        
        let pausedState: PausedFromState
        switch currentState {
        case .working:
            pausedState = .working
        case .shortBreak:
            pausedState = .shortBreak
        case .longBreak:
            pausedState = .longBreak
        default:
            return
        }
        
        stopTimer()
        currentState = .paused(remainingTime: timeRemaining, fromState: pausedState)
    }
    
    /// stop current session and return to idle
    func stop() {
        stopTimer()
        currentState = .idle
        timeRemaining = 0
    }
    
    /// reset current session to full duration
    func resetSession() {
        switch currentState {
        case .working:
            startWorkSession()
        case .shortBreak:
            startShortBreak()
        case .longBreak:
            startLongBreak()
        case .paused(_, let fromState):
            switch fromState {
            case .working:
                startWorkSession()
            case .shortBreak:
                startShortBreak()
            case .longBreak:
                startLongBreak()
            }
        default:
            break
        }
    }
    
    /// reset entire pomodoro cycle
    func resetPomodoro() {
        stopTimer()
        currentState = .idle
        timeRemaining = 0
        completedSessions = 0
        settings.lastCompletedSessions = 0
    }
    
    // MARK: - private helpers
    
    private func startWorkSession() {
        let duration = TimeInterval(settings.currentTaskType.workMinutes * 60)
        timeRemaining = duration
        currentState = .working(startTime: Date(), totalDuration: duration)
        startTimer()
    }
    
    private func startShortBreak() {
        let duration = TimeInterval(settings.currentTaskType.shortBreakMinutes * 60)
        timeRemaining = duration
        currentState = .shortBreak(startTime: Date(), totalDuration: duration)
        startTimer()
    }
    
    private func startLongBreak() {
        let duration = TimeInterval(settings.currentTaskType.longBreakMinutes * 60)
        timeRemaining = duration
        currentState = .longBreak(startTime: Date(), totalDuration: duration)
        startTimer()
    }
    
    private func resumeFromPause(remaining: TimeInterval, fromState: PausedFromState) {
        timeRemaining = remaining
        
        switch fromState {
        case .working:
            currentState = .working(startTime: Date(), totalDuration: remaining)
        case .shortBreak:
            currentState = .shortBreak(startTime: Date(), totalDuration: remaining)
        case .longBreak:
            currentState = .longBreak(startTime: Date(), totalDuration: remaining)
        }
        
        startTimer()
    }
    
    private func startTimer() {
        stopTimer() // clear any existing timer
        
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func tick() {
        guard timeRemaining > 0 else {
            handleTimerComplete()
            return
        }
        
        timeRemaining -= 1
    }
    
    private func handleTimerComplete() {
        stopTimer()
        
        switch currentState {
        case .working:
            completedSessions += 1
            settings.lastCompletedSessions = completedSessions
            currentState = .workComplete
            onSessionComplete?(.work)
            
        case .shortBreak:
            currentState = .breakComplete
            onSessionComplete?(.shortBreak)
            
        case .longBreak:
            completedSessions = 0 // reset cycle after long break
            settings.lastCompletedSessions = 0
            currentState = .breakComplete
            onSessionComplete?(.longBreak)
            
        default:
            break
        }
    }
}
