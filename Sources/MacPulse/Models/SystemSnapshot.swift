import Foundation
import SwiftUI

public enum MemoryPressureState: String, Sendable {
    case normal = "正常"
    case warning = "偏高"
    case critical = "吃紧"
}

public struct ProcessEntry: Identifiable, Equatable, Sendable {
    public let id: Int32 // PID
    public let name: String
    public let cpuPercent: Double

    public init(id: Int32, name: String, cpuPercent: Double) {
        self.id = id
        self.name = name
        self.cpuPercent = cpuPercent
    }
}

public struct FanReading: Identifiable, Equatable, Sendable {
    public let id: Int
    public let currentRPM: Int
    public let maxRPM: Int

    public init(id: Int, currentRPM: Int, maxRPM: Int) {
        self.id = id
        self.currentRPM = currentRPM
        self.maxRPM = maxRPM
    }
}

public struct SystemSnapshot: Sendable {
    // CPU
    public var cpuTotalUsage: Double = 0
    public var pCoreUsage: Double = 0
    public var eCoreUsage: Double = 0
    public var pCoreCount: Int = 0
    public var eCoreCount: Int = 0
    public var perCoreUsages: [Double] = []
    public var cpuHistory: [Double] = Array(repeating: 0, count: 60)

    // GPU
    public var gpuUsage: Double = 0
    public var gpuRenderUsage: Double = 0
    public var gpuTilerUsage: Double = 0
    public var gpuMemoryMB: Double = 0
    public var gpuAllocMemoryMB: Double = 0
    public var gpuHistory: [Double] = Array(repeating: 0, count: 60)

    // Memory & Swap
    public var memoryUsedGB: Double = 0
    public var memoryTotalGB: Double = 16
    public var memoryWiredGB: Double = 0
    public var memoryCompressedGB: Double = 0
    public var memoryUsagePercent: Double = 0
    public var memoryPressure: MemoryPressureState = .normal
    public var swapUsedMB: Double = 0
    public var memoryHistory: [Double] = Array(repeating: 0, count: 60)

    // Thermal, Fan & Power
    public var cpuTempCelsius: Double? = nil
    public var gpuTempCelsius: Double? = nil
    public var nandTempCelsius: Double? = nil
    public var fans: [FanReading] = []
    public var systemPowerWatts: Double? = nil

    // Network & Disk IO
    public var netUploadBytesPerSec: Double = 0
    public var netDownloadBytesPerSec: Double = 0
    public var diskReadBytesPerSec: Double = 0
    public var diskWriteBytesPerSec: Double = 0
    public var diskFreeGB: Double = 0

    // Top Processes
    public var topProcesses: [ProcessEntry] = []

    public init() {}
}

public enum HUDDisplayMode: String, CaseIterable {
    case dashboard = "dashboard"
    case compact = "compact"

    public var title: String {
        switch self {
        case .dashboard: return "完整极客仪表盘 (Dashboard)"
        case .compact: return "极简胶囊状态条 (Compact Pill)"
        }
    }
}

public enum HUDWindowLayer: String, CaseIterable {
    case floatingTop = "floatingTop"
    case desktopWallpaper = "desktopWallpaper"

    public var title: String {
        switch self {
        case .floatingTop: return "全局置顶悬浮 (Always on Top)"
        case .desktopWallpaper: return "嵌入桌面壁纸层 (Desktop Layer)"
        }
    }
}

@MainActor
public final class HUDSettings: ObservableObject {
    @Published public var displayMode: HUDDisplayMode {
        didSet { UserDefaults.standard.set(displayMode.rawValue, forKey: "hud.displayMode") }
    }
    @Published public var windowLayer: HUDWindowLayer {
        didSet { UserDefaults.standard.set(windowLayer.rawValue, forKey: "hud.windowLayer") }
    }
    @Published public var isClickThroughLocked: Bool {
        didSet { UserDefaults.standard.set(isClickThroughLocked, forKey: "hud.isClickThroughLocked") }
    }
    @Published public var isOptionKeyTemporarilyHeld: Bool = false

    @Published public var backgroundOpacity: Double {
        didSet { UserDefaults.standard.set(backgroundOpacity, forKey: "hud.backgroundOpacity") }
    }
    @Published public var refreshInterval: Double {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: "hud.refreshInterval") }
    }
    @Published public var showPerCoreBars: Bool {
        didSet { UserDefaults.standard.set(showPerCoreBars, forKey: "hud.showPerCoreBars") }
    }
    @Published public var showThermalAndPower: Bool {
        didSet { UserDefaults.standard.set(showThermalAndPower, forKey: "hud.showThermalAndPower") }
    }
    @Published public var showNetworkAndDisk: Bool {
        didSet { UserDefaults.standard.set(showNetworkAndDisk, forKey: "hud.showNetworkAndDisk") }
    }
    @Published public var showTopProcesses: Bool {
        didSet { UserDefaults.standard.set(showTopProcesses, forKey: "hud.showTopProcesses") }
    }
    @Published public var showMenuBarLiveText: Bool {
        didSet { UserDefaults.standard.set(showMenuBarLiveText, forKey: "hud.showMenuBarLiveText") }
    }

    public var effectiveClickThrough: Bool {
        isClickThroughLocked && !isOptionKeyTemporarilyHeld
    }

    public init() {
        let defaults = UserDefaults.standard
        let modeStr = defaults.string(forKey: "hud.displayMode") ?? HUDDisplayMode.dashboard.rawValue
        self.displayMode = HUDDisplayMode(rawValue: modeStr) ?? .dashboard

        let layerStr = defaults.string(forKey: "hud.windowLayer") ?? HUDWindowLayer.floatingTop.rawValue
        self.windowLayer = HUDWindowLayer(rawValue: layerStr) ?? .floatingTop

        if defaults.object(forKey: "hud.isClickThroughLocked") == nil {
            self.isClickThroughLocked = true
        } else {
            self.isClickThroughLocked = defaults.bool(forKey: "hud.isClickThroughLocked")
        }

        if defaults.object(forKey: "hud.backgroundOpacity") == nil {
            self.backgroundOpacity = 0.42
        } else {
            self.backgroundOpacity = defaults.double(forKey: "hud.backgroundOpacity")
        }

        let interval = defaults.double(forKey: "hud.refreshInterval")
        self.refreshInterval = interval > 0 ? interval : 1.0

        self.showPerCoreBars = defaults.object(forKey: "hud.showPerCoreBars") == nil ? true : defaults.bool(forKey: "hud.showPerCoreBars")
        self.showThermalAndPower = defaults.object(forKey: "hud.showThermalAndPower") == nil ? true : defaults.bool(forKey: "hud.showThermalAndPower")
        self.showNetworkAndDisk = defaults.object(forKey: "hud.showNetworkAndDisk") == nil ? true : defaults.bool(forKey: "hud.showNetworkAndDisk")
        self.showTopProcesses = defaults.object(forKey: "hud.showTopProcesses") == nil ? true : defaults.bool(forKey: "hud.showTopProcesses")
        self.showMenuBarLiveText = defaults.object(forKey: "hud.showMenuBarLiveText") == nil ? true : defaults.bool(forKey: "hud.showMenuBarLiveText")
    }
}

public enum Formatters {
    public static func formatBytesRate(_ bytesPerSec: Double) -> String {
        if bytesPerSec < 1024 {
            return String(format: "%4.0f B/s", max(0, bytesPerSec))
        } else if bytesPerSec < 1024 * 1024 {
            return String(format: "%5.1f K/s", bytesPerSec / 1024.0)
        } else if bytesPerSec < 1024 * 1024 * 1024 {
            return String(format: "%5.1f M/s", bytesPerSec / (1024.0 * 1024.0))
        } else {
            return String(format: "%5.2f G/s", bytesPerSec / (1024.0 * 1024.0 * 1024.0))
        }
    }

    public static func metricColor(percent: Double) -> Color {
        if percent >= 88.0 {
            return Color(red: 1.0, green: 0.35, blue: 0.38) // Coral Red
        } else if percent >= 70.0 {
            return Color(red: 1.0, green: 0.76, blue: 0.22) // Amber Yellow
        } else {
            return Color(red: 0.24, green: 0.92, blue: 0.75) // Cyber Mint/Cyan
        }
    }

    public static func tempColor(celsius: Double) -> Color {
        if celsius >= 85.0 {
            return Color(red: 1.0, green: 0.35, blue: 0.38)
        } else if celsius >= 70.0 {
            return Color(red: 1.0, green: 0.76, blue: 0.22)
        } else {
            return Color(red: 0.38, green: 0.85, blue: 1.0)
        }
    }
}
