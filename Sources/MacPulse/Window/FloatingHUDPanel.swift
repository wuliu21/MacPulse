import AppKit
import SwiftUI
import Combine

@MainActor
public final class FloatingHUDPanel: NSPanel {
    private let settings: HUDSettings
    private var cancellables = Set<AnyCancellable>()
    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var hostingView: NSHostingView<HUDRootView>?

    public init(coordinator: TelemetryCoordinator, settings: HUDSettings) {
        self.settings = settings
        let initialRect = NSRect(x: 0, y: 0, width: 322, height: 460)

        super.init(
            contentRect: initialRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.hidesOnDeactivate = false
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]

        let rootView = HUDRootView(coordinator: coordinator, settings: settings)
        let hosting = FirstMouseHostingView(rootView: rootView)
        hosting.frame = initialRect
        self.contentView = hosting
        self.hostingView = hosting

        applyWindowLayer(settings.windowLayer)
        applyClickThroughState()
        updateContentSizePreservingTopRight(initialPlacement: true)

        setupBindings()
        setupModifierMonitors()
        setupScreenAndMoveNotifications()
    }

    override public var canBecomeKey: Bool {
        return !settings.effectiveClickThrough
    }

    override public var canBecomeMain: Bool {
        return false
    }

    private func setupBindings() {
        settings.$windowLayer
            .sink { [weak self] layer in
                self?.applyWindowLayer(layer)
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(settings.$isClickThroughLocked, settings.$isOptionKeyTemporarilyHeld)
            .sink { [weak self] _, _ in
                self?.applyClickThroughState()
            }
            .store(in: &cancellables)

        Publishers.CombineLatest4(
            settings.$displayMode,
            settings.$showPerCoreBars,
            settings.$showThermalAndPower,
            Publishers.CombineLatest(settings.$showNetworkAndDisk, settings.$showTopProcesses)
        )
        .sink { [weak self] _, _, _, _ in
            DispatchQueue.main.async {
                self?.updateContentSizePreservingTopRight(initialPlacement: false)
            }
        }
        .store(in: &cancellables)
    }

    private func applyWindowLayer(_ layer: HUDWindowLayer) {
        switch layer {
        case .floatingTop:
            self.level = .statusBar
        case .desktopWallpaper:
            let desktopLevel = Int(CGWindowLevelForKey(.desktopWindow)) + 1
            self.level = NSWindow.Level(rawValue: desktopLevel)
        }
    }

    private func applyClickThroughState() {
        let shouldIgnore = settings.effectiveClickThrough
        self.ignoresMouseEvents = shouldIgnore
    }

    private func setupModifierMonitors() {
        let handleFlags: (NSEvent) -> Void = { [weak self] event in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let optionPressed = event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.option)
                if self.settings.isOptionKeyTemporarilyHeld != optionPressed {
                    self.settings.isOptionKeyTemporarilyHeld = optionPressed
                    if !optionPressed {
                        self.saveWindowOrigin()
                    }
                }
            }
        }

        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: handleFlags)
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            handleFlags(event)
            return event
        }
    }

    private func setupScreenAndMoveNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.saveWindowOrigin()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.clampToVisibleScreenBounds()
            }
        }
    }

    public func updateContentSizePreservingTopRight(initialPlacement: Bool) {
        guard let hosting = hostingView else { return }
        hosting.layoutSubtreeIfNeeded()
        let fitting = hosting.fittingSize
        let newSize = NSSize(width: max(220, fitting.width), height: max(36, fitting.height))

        if initialPlacement {
            let defaults = UserDefaults.standard
            if defaults.object(forKey: "hud.windowOriginX") != nil,
               defaults.object(forKey: "hud.windowOriginY") != nil {
                let savedX = defaults.double(forKey: "hud.windowOriginX")
                let savedY = defaults.double(forKey: "hud.windowOriginY")
                self.setFrame(NSRect(origin: NSPoint(x: savedX, y: savedY), size: newSize), display: true)
                clampToVisibleScreenBounds()
            } else {
                resetToDefaultTopRightPosition(size: newSize)
            }
        } else {
            let oldFrame = self.frame
            let topRightX = oldFrame.maxX
            let topRightY = oldFrame.maxY
            let newOrigin = NSPoint(x: topRightX - newSize.width, y: topRightY - newSize.height)
            self.setFrame(NSRect(origin: newOrigin, size: newSize), display: true, animate: false)
            clampToVisibleScreenBounds()
        }
    }

    public func resetToDefaultTopRightPosition(size: NSSize? = nil) {
        let targetSize = size ?? self.frame.size
        let screenFrame = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(
            x: screenFrame.maxX - targetSize.width - 20,
            y: screenFrame.maxY - targetSize.height - 16
        )
        self.setFrame(NSRect(origin: origin, size: targetSize), display: true, animate: true)
        saveWindowOrigin()
    }

    public func clampToVisibleScreenBounds() {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }

        let currentFrame = self.frame
        let isVisibleOnAnyScreen = screens.contains { screen in
            screen.visibleFrame.intersects(currentFrame.insetBy(dx: 24, dy: 24))
        }

        if !isVisibleOnAnyScreen, let primary = NSScreen.main ?? screens.first {
            let vf = primary.visibleFrame
            let clampedX = min(max(vf.minX + 12, currentFrame.origin.x), vf.maxX - currentFrame.width - 12)
            let clampedY = min(max(vf.minY + 12, currentFrame.origin.y), vf.maxY - currentFrame.height - 12)
            self.setFrameOrigin(NSPoint(x: clampedX, y: clampedY))
            saveWindowOrigin()
        }
    }

    private func saveWindowOrigin() {
        let origin = self.frame.origin
        UserDefaults.standard.set(origin.x, forKey: "hud.windowOriginX")
        UserDefaults.standard.set(origin.y, forKey: "hud.windowOriginY")
    }
}

private final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override var mouseDownCanMoveWindow: Bool {
        return true
    }

    override func mouseDown(with event: NSEvent) {
        self.window?.performDrag(with: event)
    }
}
