// touchbar-manager.swift
// touch bar integration with progress ring, controls, and quick settings

import AppKit
import SwiftUI
import Combine

@available(macOS 10.12.2, *)
class TouchBarManager: NSObject, NSTouchBarDelegate {
    
    // dependencies
    private let timerModel: TimerModel
    private let settings: PomodoroSettings
    private var cancellables = Set<AnyCancellable>()
    
    // touch bar items
    private var progressView: NSView?
    private var timerLabel: NSTextField?
    private var playPauseButton: NSButton?
    private var stopButton: NSButton?
    private var colorPickerDelegate: ColorPickerDelegate?
    
    init(timerModel: TimerModel, settings: PomodoroSettings) {
        self.timerModel = timerModel
        self.settings = settings
        super.init()
        
        observeTimerChanges()
    }
    
    // MARK: - touch bar setup
    
    func makeTouchBar() -> NSTouchBar {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .pomodoroTouchBar
        touchBar.defaultItemIdentifiers = [
            .progressRing,
            .timerCountdown,
            .flexibleSpace,
            .playPause,
            .stop,
            .flexibleSpace,
            .settings,
            .toggleOverlay
        ]
        touchBar.customizationAllowedItemIdentifiers = [
            .progressRing,
            .timerCountdown,
            .playPause,
            .stop,
            .settings,
            .toggleOverlay
        ]
        
        return touchBar
    }
    
    // MARK: - NSTouchBarDelegate
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case .progressRing:
            return makeProgressRingItem()
        case .timerCountdown:
            return makeTimerCountdownItem()
        case .playPause:
            return makePlayPauseItem()
        case .stop:
            return makeStopItem()
        case .settings:
            return makeSettingsItem()
        case .toggleOverlay:
            return makeToggleOverlayItem()
        case .taskTypeSegment:
            return makeTaskTypeSegmentItem()
        case .colorPicker:
            return makeColorPickerItem()
        default:
            return nil
        }
    }
    
    // MARK: - item creation
    
    private func makeProgressRingItem() -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: .progressRing)
        
        let progressView = ProgressRingTouchBarView(frame: NSRect(x: 0, y: 0, width: 44, height: 30))
        progressView.progress = timerModel.progress
        progressView.ringColor = NSColor(settings.timerColor)
        
        self.progressView = progressView
        item.view = progressView
        
        return item
    }
    
    private func makeTimerCountdownItem() -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: .timerCountdown)
        
        let label = NSTextField(labelWithString: timerModel.timeRemainingFormatted)
        label.alignment = .center
        label.font = NSFont.monospacedDigitSystemFont(ofSize: 15, weight: .medium)
        label.textColor = .labelColor
        
        self.timerLabel = label
        item.view = label
        
        return item
    }
    
    private func makePlayPauseItem() -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: .playPause)
        
        let button = NSButton(
            image: getPlayPauseImage(),
            target: self,
            action: #selector(playPauseTapped)
        )
        button.bezelColor = .controlAccentColor
        
        self.playPauseButton = button
        item.view = button
        
        return item
    }
    
    private func makeStopItem() -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: .stop)
        
        let button = NSButton(
            image: NSImage(systemSymbolName: "stop.fill", accessibilityDescription: "Stop")!,
            target: self,
            action: #selector(stopTapped)
        )
        button.bezelColor = .systemRed
        
        self.stopButton = button
        item.view = button
        
        return item
    }
    
    private func makeSettingsItem() -> NSTouchBarItem {
        let item = NSPopoverTouchBarItem(identifier: .settings)
        item.collapsedRepresentationImage = NSImage(
            systemSymbolName: "gear",
            accessibilityDescription: "Settings"
        )
        item.popoverTouchBar = makeSettingsPopover()
        item.pressAndHoldTouchBar = makeSettingsPopover()
        
        return item
    }
    
    private func makeToggleOverlayItem() -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: .toggleOverlay)
        
        let button = NSButton(
            image: getOverlayImage(),
            target: self,
            action: #selector(toggleOverlayTapped)
        )
        
        item.view = button
        
        return item
    }
    
    // MARK: - settings popover
    
    private func makeSettingsPopover() -> NSTouchBar {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [
            .taskTypeSegment,
            .colorPicker,
            .fixedSpaceLarge
        ]
        
        return touchBar
    }
    
    private func makeTaskTypeSegmentItem() -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: .taskTypeSegment)
        
        let segmentedControl = NSSegmentedControl(
            labels: TaskType.allCases.map { $0.displayName },
            trackingMode: .selectOne,
            target: self,
            action: #selector(taskTypeChanged(_:))
        )
        
        // select current task type
        if let currentIndex = TaskType.allCases.firstIndex(of: settings.currentTaskType) {
            segmentedControl.selectedSegment = currentIndex
        }
        
        item.view = segmentedControl
        
        return item
    }
    
    private func makeColorPickerItem() -> NSTouchBarItem {
        let item = NSPopoverTouchBarItem(identifier: .colorPicker)
        item.collapsedRepresentationImage = NSImage(
            systemSymbolName: "paintpalette",
            accessibilityDescription: "Colors"
        )
        
        let delegate = ColorPickerDelegate(parent: self)
        self.colorPickerDelegate = delegate
        
        let colorBar = NSTouchBar()
        colorBar.delegate = delegate
        colorBar.defaultItemIdentifiers = [
            .colorOption1,
            .colorOption2,
            .colorOption3,
            .colorOption4,
            .colorOption5,
            .colorOption6
        ]
        
        item.popoverTouchBar = colorBar
        
        return item
    }
    
    // MARK: - color picker items
    
    fileprivate let colorOptions: [(Color, String)] = [
        (.blue, "Blue"),
        (.green, "Green"),
        (.orange, "Orange"),
        (.red, "Red"),
        (.purple, "Purple"),
        (.pink, "Pink")
    ]
    
    fileprivate func makeColorOptionItem(color: Color, name: String, identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: identifier)
        
        let button = NSButton(
            title: name,
            target: self,
            action: #selector(colorSelected(_:))
        )
        button.bezelColor = NSColor(color)
        button.tag = colorOptions.firstIndex(where: { $0.0 == color }) ?? 0
        
        item.view = button
        
        return item
    }
    
    // MARK: - actions
    
    @objc private func playPauseTapped() {
        if timerModel.currentState.isRunning {
            timerModel.pause()
        } else {
            timerModel.start()
        }
    }
    
    @objc private func stopTapped() {
        timerModel.stop()
    }
    
    @objc private func toggleOverlayTapped() {
        settings.overlayVisible.toggle()
    }
    
    @objc private func taskTypeChanged(_ sender: NSSegmentedControl) {
        let selectedIndex = sender.selectedSegment
        guard selectedIndex >= 0, selectedIndex < TaskType.allCases.count else { return }
        
        settings.currentTaskType = TaskType.allCases[selectedIndex]
    }
    
    @objc private func colorSelected(_ sender: NSButton) {
        let index = sender.tag
        guard index >= 0, index < colorOptions.count else { return }
        
        let selectedColor = colorOptions[index].0
        settings.timerColor = selectedColor
        
        // update progress ring color
        if let progressView = progressView as? ProgressRingTouchBarView {
            progressView.ringColor = NSColor(selectedColor)
        }
    }
    
    // MARK: - updates
    
    private func observeTimerChanges() {
        // observe timer updates
        timerModel.$timeRemaining
            .sink { [weak self] _ in
                self?.updateTimerDisplay()
            }
            .store(in: &cancellables)
        
        timerModel.$currentState
            .sink { [weak self] _ in
                self?.updateControls()
            }
            .store(in: &cancellables)
        
        // observe timer color changes manually since it uses AppStorage
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if let progressView = self.progressView as? ProgressRingTouchBarView {
                    progressView.ringColor = NSColor(self.settings.timerColor)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateTimerDisplay() {
        timerLabel?.stringValue = timerModel.timeRemainingFormatted
        
        if let progressView = progressView as? ProgressRingTouchBarView {
            progressView.progress = timerModel.progress
        }
    }
    
    private func updateControls() {
        playPauseButton?.image = getPlayPauseImage()
    }
    
    // MARK: - helpers
    
    private func getPlayPauseImage() -> NSImage {
        if timerModel.currentState.isRunning {
            return NSImage(systemSymbolName: "pause.fill", accessibilityDescription: "Pause")!
        } else {
            return NSImage(systemSymbolName: "play.fill", accessibilityDescription: "Play")!
        }
    }
    
    private func getOverlayImage() -> NSImage {
        if settings.overlayVisible {
            return NSImage(systemSymbolName: "eye.slash", accessibilityDescription: "Hide Overlay")!
        } else {
            return NSImage(systemSymbolName: "eye", accessibilityDescription: "Show Overlay")!
        }
    }
}

// MARK: - color picker delegate

@available(macOS 10.12.2, *)
class ColorPickerDelegate: NSObject, NSTouchBarDelegate {
    weak var parent: TouchBarManager?
    
    init(parent: TouchBarManager) {
        self.parent = parent
        super.init()
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        let colorIdentifiers: [NSTouchBarItem.Identifier] = [
            .colorOption1, .colorOption2, .colorOption3,
            .colorOption4, .colorOption5, .colorOption6
        ]
        
        guard let parent = parent,
              let index = colorIdentifiers.firstIndex(of: identifier),
              index < parent.colorOptions.count else {
            return nil
        }
        
        let colorOption = parent.colorOptions[index]
        return parent.makeColorOptionItem(color: colorOption.0, name: colorOption.1, identifier: identifier)
    }
}

// MARK: - custom progress ring view for touch bar

@available(macOS 10.12.2, *)
class ProgressRingTouchBarView: NSView {
    
    var progress: Double = 0 {
        didSet {
            needsDisplay = true
        }
    }
    
    var ringColor: NSColor = .systemBlue {
        didSet {
            needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius: CGFloat = min(bounds.width, bounds.height) / 2 - 2
        let lineWidth: CGFloat = 3
        
        // background circle
        context.setStrokeColor(NSColor.systemGray.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(lineWidth)
        context.addArc(
            center: center,
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: false
        )
        context.strokePath()
        
        // progress arc
        let startAngle = -CGFloat.pi / 2 // start at top
        let endAngle = startAngle + CGFloat(progress * 2 * .pi)
        
        context.setStrokeColor(ringColor.cgColor)
        context.setLineWidth(lineWidth)
        context.setLineCap(.round)
        context.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        context.strokePath()
    }
}

// MARK: - touch bar identifiers

@available(macOS 10.12.2, *)
extension NSTouchBar.CustomizationIdentifier {
    static let pomodoroTouchBar = NSTouchBar.CustomizationIdentifier("com.pomodoro.touchbar")
}

@available(macOS 10.12.2, *)
extension NSTouchBarItem.Identifier {
    static let progressRing = NSTouchBarItem.Identifier("com.pomodoro.progressRing")
    static let timerCountdown = NSTouchBarItem.Identifier("com.pomodoro.timerCountdown")
    static let playPause = NSTouchBarItem.Identifier("com.pomodoro.playPause")
    static let stop = NSTouchBarItem.Identifier("com.pomodoro.stop")
    static let settings = NSTouchBarItem.Identifier("com.pomodoro.settings")
    static let toggleOverlay = NSTouchBarItem.Identifier("com.pomodoro.toggleOverlay")
    static let taskTypeSegment = NSTouchBarItem.Identifier("com.pomodoro.taskTypeSegment")
    static let colorPicker = NSTouchBarItem.Identifier("com.pomodoro.colorPicker")
    static let colorOption1 = NSTouchBarItem.Identifier("com.pomodoro.colorOption1")
    static let colorOption2 = NSTouchBarItem.Identifier("com.pomodoro.colorOption2")
    static let colorOption3 = NSTouchBarItem.Identifier("com.pomodoro.colorOption3")
    static let colorOption4 = NSTouchBarItem.Identifier("com.pomodoro.colorOption4")
    static let colorOption5 = NSTouchBarItem.Identifier("com.pomodoro.colorOption5")
    static let colorOption6 = NSTouchBarItem.Identifier("com.pomodoro.colorOption6")
}
