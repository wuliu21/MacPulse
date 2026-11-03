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
        let menu = NSMenu()
        menu.delegate = self

        let titleItem = NSMenuItem(title: "MacPulse 桌面性能监控", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(.separator())

        // 1. Show / Hide HUD
        let visibleItem = NSMenuItem(
            title: panel.isVisible ? "隐藏桌面悬浮窗" : "显示桌面悬浮窗",
            action: #selector(togglePanelVisibility),
            keyEquivalent: "h"
        )
        visibleItem.target = self
        menu.addItem(visibleItem)

        // 2. Lock / Unlock Click-through
        let lockItem = NSMenuItem(
            title: "锁定鼠标穿透 (按住 ⌥ 可临时拖拽)",
            action: #selector(toggleClickThroughLock),
            keyEquivalent: "l"
        )
        lockItem.target = self
        lockItem.state = settings.isClickThroughLocked ? .on : .off
        menu.addItem(lockItem)

        let resetPosItem = NSMenuItem(
            title: "重置悬浮窗到右上角默认位置",
            action: #selector(resetPosition),
            keyEquivalent: "r"
        )
        resetPosItem.target = self
        menu.addItem(resetPosItem)

        menu.addItem(.separator())

        // 3. Display Mode
        let modeHeader = NSMenuItem(title: "视图模式", action: nil, keyEquivalent: "")
        modeHeader.isEnabled = false
        menu.addItem(modeHeader)

        for mode in HUDDisplayMode.allCases {
            let item = NSMenuItem(title: mode.title, action: #selector(selectDisplayMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            item.state = (settings.displayMode == mode) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // 4. Window Layer
        let layerHeader = NSMenuItem(title: "桌面层级", action: nil, keyEquivalent: "")
        layerHeader.isEnabled = false
        menu.addItem(layerHeader)

        for layer in HUDWindowLayer.allCases {
            let item = NSMenuItem(title: layer.title, action: #selector(selectWindowLayer(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = layer.rawValue
            item.state = (settings.windowLayer == layer) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // 5. Background Opacity Submenu & Slider
        let opacityMenu = NSMenu()
        let presets: [(String, Double)] = [
            ("0% · 纯全透明 (仅发光文字)", 0.0),
            ("22% · 极高通透玻璃", 0.22),
            ("42% · 标准极客熏黑 (推荐)", 0.42),
            ("65% · 深邃磨砂卡片", 0.65),
            ("88% · 高对比不透明", 0.88)
        ]
        for (label, val) in presets {
            let item = NSMenuItem(title: label, action: #selector(selectOpacityPreset(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = val
            item.state = abs(settings.backgroundOpacity - val) < 0.05 ? .on : .off
            opacityMenu.addItem(item)
        }
        let opacityParent = NSMenuItem(
            title: String(format: "背景透明度 (当前 %.0f%%)", settings.backgroundOpacity * 100),
            action: nil,
            keyEquivalent: ""
        )
        opacityParent.submenu = opacityMenu
        menu.addItem(opacityParent)

        // 6. Modules Submenu
        let modulesMenu = NSMenu()
        let perCoreItem = NSMenuItem(title: "CPU 单核负载柱状条", action: #selector(togglePerCoreBars), keyEquivalent: "")
        perCoreItem.target = self
        perCoreItem.state = settings.showPerCoreBars ? .on : .off
        modulesMenu.addItem(perCoreItem)

        let thermalItem = NSMenuItem(title: "风扇转速与 SSD 温度模块", action: #selector(toggleThermalAndPower), keyEquivalent: "")
        thermalItem.target = self
        thermalItem.state = settings.showThermalAndPower ? .on : .off
        modulesMenu.addItem(thermalItem)

        let netDiskItem = NSMenuItem(title: "实时网速与磁盘读写模块", action: #selector(toggleNetworkAndDisk), keyEquivalent: "")
        netDiskItem.target = self
        netDiskItem.state = settings.showNetworkAndDisk ? .on : .off
        modulesMenu.addItem(netDiskItem)

        let topProcItem = NSMenuItem(title: "Top 3 高占用进程模块", action: #selector(toggleTopProcesses), keyEquivalent: "")
        topProcItem.target = self
        topProcItem.state = settings.showTopProcesses ? .on : .off
        modulesMenu.addItem(topProcItem)

        let menuBarTextItem = NSMenuItem(title: "顶部菜单栏显示 CPU/GPU 百分比", action: #selector(toggleMenuBarText), keyEquivalent: "")
        menuBarTextItem.target = self
        menuBarTextItem.state = settings.showMenuBarLiveText ? .on : .off
        modulesMenu.addItem(menuBarTextItem)

        let modulesParent = NSMenuItem(title: "显示指标模块开关", action: nil, keyEquivalent: "")
        modulesParent.submenu = modulesMenu
        menu.addItem(modulesParent)

        // 7. Refresh Interval Submenu
        let refreshMenu = NSMenu()
        let intervals: [(String, Double)] = [
            ("0.5 秒 (极速刷新)", 0.5),
            ("1.0 秒 (标准平衡 · 推荐)", 1.0),
            ("2.0 秒 (省电低功耗)", 2.0)
        ]
        for (label, sec) in intervals {
            let item = NSMenuItem(title: label, action: #selector(selectRefreshInterval(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = sec
            item.state = abs(settings.refreshInterval - sec) < 0.05 ? .on : .off
            refreshMenu.addItem(item)
        }
        let refreshParent = NSMenuItem(
            title: String(format: "采样频率 (%.1f 秒)", settings.refreshInterval),
            action: nil,
            keyEquivalent: ""
        )
        refreshParent.submenu = refreshMenu
        menu.addItem(refreshParent)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出 MacPulse", action: #selector(quitApp), keyEquivalent: "q")
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

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
