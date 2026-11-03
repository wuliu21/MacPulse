import AppKit
import SwiftUI
import Combine

@MainActor
public final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let coordinator: TelemetryCoordinator
    private let settings: HUDSettings
    private let panel: FloatingHUDPanel
    private var cancellables = Set<AnyCancellable>()

    public init(coordinator: TelemetryCoordinator, settings: HUDSettings, panel: FloatingHUDPanel) {
        self.coordinator = coordinator
        self.settings = settings
        self.panel = panel
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureStatusButton()
        rebuildMenu()
        setupBindings()
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "waveform.path.ecg.rectangle", accessibilityDescription: "MacPulse")
        button.imagePosition = .imageLeading
        updateStatusButtonTitle(snapshot: coordinator.snapshot)
    }

    private func setupBindings() {
        coordinator.onSnapshotUpdated = { [weak self] snap in
            self?.updateStatusButtonTitle(snapshot: snap)
        }

        settings.$showMenuBarLiveText
            .sink { [weak self] _ in
                guard let self else { return }
                self.updateStatusButtonTitle(snapshot: self.coordinator.snapshot)
            }
            .store(in: &cancellables)
    }

    private func updateStatusButtonTitle(snapshot: SystemSnapshot) {
        guard let button = statusItem.button else { return }
        if settings.showMenuBarLiveText {
            let text = String(format: " %2.0f%% · %2.0f%%", snapshot.cpuTotalUsage, snapshot.gpuUsage)
            let font = NSFont.monospacedDigitSystemFont(ofSize: 11.5, weight: .medium)
            button.attributedTitle = NSAttributedString(
                string: text,
                attributes: [.font: font]
            )
        } else {
            button.title = ""
        }
    }

    public func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        let t = settings.l10n
        let menu = NSMenu()
        menu.delegate = self

        let titleItem = NSMenuItem(title: t.menuAppTitle, action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(.separator())

        // 1. Show / Hide HUD
        let visibleItem = NSMenuItem(
            title: panel.isVisible ? t.menuHideHUD : t.menuShowHUD,
            action: #selector(togglePanelVisibility),
            keyEquivalent: "h"
        )
        visibleItem.target = self
        menu.addItem(visibleItem)

        // 2. Lock / Unlock Click-through
        let lockItem = NSMenuItem(
            title: t.menuLockClickThrough,
            action: #selector(toggleClickThroughLock),
            keyEquivalent: "l"
        )
        lockItem.target = self
        lockItem.state = settings.isClickThroughLocked ? .on : .off
        menu.addItem(lockItem)

        let resetPosItem = NSMenuItem(
            title: t.menuResetPosition,
            action: #selector(resetPosition),
            keyEquivalent: "r"
        )
        resetPosItem.target = self
        menu.addItem(resetPosItem)

        menu.addItem(.separator())

        // 3. Display Mode
        let modeHeader = NSMenuItem(title: t.menuSectionViewMode, action: nil, keyEquivalent: "")
        modeHeader.isEnabled = false
        menu.addItem(modeHeader)

        let modes: [(HUDDisplayMode, String)] = [
            (.dashboard, t.modeDashboard),
            (.compact, t.modeCompact)
        ]
        for (mode, modeTitle) in modes {
            let item = NSMenuItem(title: modeTitle, action: #selector(selectDisplayMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            item.state = (settings.displayMode == mode) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // 4. Window Layer
        let layerHeader = NSMenuItem(title: t.menuSectionWindowLayer, action: nil, keyEquivalent: "")
        layerHeader.isEnabled = false
        menu.addItem(layerHeader)

        let layers: [(HUDWindowLayer, String)] = [
            (.floatingTop, t.layerFloatingTop),
            (.desktopWallpaper, t.layerDesktopWallpaper)
        ]
        for (layer, layerTitle) in layers {
            let item = NSMenuItem(title: layerTitle, action: #selector(selectWindowLayer(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = layer.rawValue
            item.state = (settings.windowLayer == layer) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // 5. Background Opacity Submenu
        let opacityMenu = NSMenu()
        let presets: [(String, Double)] = [
            (t.opacityPreset0, 0.0),
            (t.opacityPreset22, 0.22),
            (t.opacityPreset42, 0.42),
            (t.opacityPreset65, 0.65),
            (t.opacityPreset88, 0.88)
        ]
        for (label, val) in presets {
            let item = NSMenuItem(title: label, action: #selector(selectOpacityPreset(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = val
            item.state = abs(settings.backgroundOpacity - val) < 0.05 ? .on : .off
            opacityMenu.addItem(item)
        }
        let opacityParent = NSMenuItem(
            title: String(format: t.menuOpacityTitleFormat, settings.backgroundOpacity * 100),
            action: nil,
            keyEquivalent: ""
        )
        opacityParent.submenu = opacityMenu
        menu.addItem(opacityParent)

        // 6. Modules Submenu
        let modulesMenu = NSMenu()
        let perCoreItem = NSMenuItem(title: t.modulePerCoreBars, action: #selector(togglePerCoreBars), keyEquivalent: "")
        perCoreItem.target = self
        perCoreItem.state = settings.showPerCoreBars ? .on : .off
        modulesMenu.addItem(perCoreItem)

        let thermalItem = NSMenuItem(title: t.moduleThermalFan, action: #selector(toggleThermalAndPower), keyEquivalent: "")
        thermalItem.target = self
        thermalItem.state = settings.showThermalAndPower ? .on : .off
        modulesMenu.addItem(thermalItem)

        let netDiskItem = NSMenuItem(title: t.moduleNetworkDisk, action: #selector(toggleNetworkAndDisk), keyEquivalent: "")
        netDiskItem.target = self
        netDiskItem.state = settings.showNetworkAndDisk ? .on : .off
        modulesMenu.addItem(netDiskItem)

        let topProcItem = NSMenuItem(title: t.moduleTopProcesses, action: #selector(toggleTopProcesses), keyEquivalent: "")
        topProcItem.target = self
        topProcItem.state = settings.showTopProcesses ? .on : .off
        modulesMenu.addItem(topProcItem)

        let menuBarTextItem = NSMenuItem(title: t.moduleMenuBarText, action: #selector(toggleMenuBarText), keyEquivalent: "")
        menuBarTextItem.target = self
        menuBarTextItem.state = settings.showMenuBarLiveText ? .on : .off
        modulesMenu.addItem(menuBarTextItem)

        let modulesParent = NSMenuItem(title: t.menuModulesTitle, action: nil, keyEquivalent: "")
        modulesParent.submenu = modulesMenu
        menu.addItem(modulesParent)

        // 7. Refresh Interval Submenu
        let refreshMenu = NSMenu()
        let intervals: [(String, Double)] = [
            (t.refresh05s, 0.5),
            (t.refresh10s, 1.0),
            (t.refresh20s, 2.0)
        ]
        for (label, sec) in intervals {
            let item = NSMenuItem(title: label, action: #selector(selectRefreshInterval(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = sec
            item.state = abs(settings.refreshInterval - sec) < 0.05 ? .on : .off
            refreshMenu.addItem(item)
        }
        let refreshParent = NSMenuItem(
            title: String(format: t.menuRefreshTitleFormat, settings.refreshInterval),
            action: nil,
            keyEquivalent: ""
        )
        refreshParent.submenu = refreshMenu
        menu.addItem(refreshParent)

        // 8. Language Submenu
        let langMenu = NSMenu()
        for lang in AppLanguage.allCases {
            let item = NSMenuItem(title: lang.displayName, action: #selector(selectLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = lang.rawValue
            item.state = (settings.language == lang) ? .on : .off
            langMenu.addItem(item)
        }
        let langParent = NSMenuItem(title: t.menuLanguageTitle, action: nil, keyEquivalent: "")
        langParent.submenu = langMenu
        menu.addItem(langParent)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: t.menuQuit, action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        self.statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func togglePanelVisibility() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.orderFrontRegardless()
        }
    }

    @objc private func toggleClickThroughLock() {
        settings.isClickThroughLocked.toggle()
    }

    @objc private func resetPosition() {
        panel.orderFrontRegardless()
        panel.resetToDefaultTopRightPosition()
    }

    @objc private func selectDisplayMode(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let mode = HUDDisplayMode(rawValue: raw) else { return }
        settings.displayMode = mode
    }

    @objc private func selectWindowLayer(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let layer = HUDWindowLayer(rawValue: raw) else { return }
        settings.windowLayer = layer
    }

    @objc private func selectOpacityPreset(_ sender: NSMenuItem) {
        guard let val = sender.representedObject as? Double else { return }
        settings.backgroundOpacity = val
    }

    @objc private func togglePerCoreBars() {
        settings.showPerCoreBars.toggle()
    }

    @objc private func toggleThermalAndPower() {
        settings.showThermalAndPower.toggle()
    }

    @objc private func toggleNetworkAndDisk() {
        settings.showNetworkAndDisk.toggle()
    }

    @objc private func toggleTopProcesses() {
        settings.showTopProcesses.toggle()
    }

    @objc private func toggleMenuBarText() {
        settings.showMenuBarLiveText.toggle()
    }

    @objc private func selectRefreshInterval(_ sender: NSMenuItem) {
        guard let sec = sender.representedObject as? Double else { return }
        settings.refreshInterval = sec
    }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let lang = AppLanguage(rawValue: raw) else { return }
        settings.language = lang
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
