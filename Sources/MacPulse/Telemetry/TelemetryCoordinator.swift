import Foundation
import AppKit
import Combine

@MainActor
public final class TelemetryCoordinator: ObservableObject {
    @Published public private(set) var snapshot = SystemSnapshot()
    public var onSnapshotUpdated: ((SystemSnapshot) -> Void)?

    private let settings: HUDSettings
    private let workerQueue = DispatchQueue(label: "com.macpulse.telemetry.worker", qos: .utility)
    nonisolated(unsafe) private let cpuMonitor = CPUMonitor()
    nonisolated(unsafe) private let gpuMonitor = GPUMonitor()
    nonisolated(unsafe) private let memDiskNetMonitor = MemoryDiskNetMonitor()
    nonisolated(unsafe) private let thermalFanSensor = ThermalFanSensor()
    nonisolated(unsafe) private let processMonitor = ProcessMonitor()

    private var timer: DispatchSourceTimer?
    private var cancellables = Set<AnyCancellable>()
    private var isScreenAsleep = false
    private var tickCounter: Int = 0

    public init(settings: HUDSettings) {
        self.settings = settings
        setupNotifications()
        setupSettingsBinding()
        startTimer(interval: settings.refreshInterval)
    }

    private func setupNotifications() {
        let wsCenter = NSWorkspace.shared.notificationCenter
        wsCenter.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isScreenAsleep = true
                self?.stopTimer()
            }
        }

        wsCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isScreenAsleep = false
                self.startTimer(interval: self.settings.refreshInterval)
            }
        }
    }

    private func setupSettingsBinding() {
        settings.$refreshInterval
            .removeDuplicates()
            .sink { [weak self] newInterval in
                guard let self, !self.isScreenAsleep else { return }
                self.startTimer(interval: newInterval)
            }
            .store(in: &cancellables)
    }

    public func startTimer(interval: Double) {
        stopTimer()
        let safeInterval = max(0.25, min(5.0, interval))

        let source = DispatchSource.makeTimerSource(queue: workerQueue)
        source.schedule(
            deadline: .now(),
            repeating: .milliseconds(Int(safeInterval * 1000)),
            leeway: .milliseconds(50)
        )

        source.setEventHandler { [weak self] in
            self?.performBackgroundSample()
        }
        self.timer = source
        source.resume()
    }

    public func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private nonisolated func performBackgroundSample() {
        let cpu = cpuMonitor.sample()
        let gpu = gpuMonitor.sample()
        let mdn = memDiskNetMonitor.sample()

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.tickCounter &+= 1
            let currentTick = self.tickCounter
            let wantThermal = self.settings.showThermalAndPower
            let wantProcesses = self.settings.showTopProcesses && self.settings.displayMode == .dashboard
            let processCadence = max(1, Int((3.0 / max(0.5, self.settings.refreshInterval)).rounded()))
            let shouldSampleProcesses = wantProcesses && (currentTick == 1 || currentTick % processCadence == 0)
            let shouldSampleThermal = wantThermal && (currentTick == 1 || currentTick % 2 == 0)

            self.workerQueue.async { [weak self] in
                guard let self else { return }
                let thermal = shouldSampleThermal ? self.thermalFanSensor.sample() : nil
                let topProcs = shouldSampleProcesses ? self.processMonitor.sampleTopProcesses(limit: 3) : nil

                Task { @MainActor [weak self] in
                    guard let self else { return }
                    var next = self.snapshot

                    next.cpuTotalUsage = cpu.totalUsage
                    next.pCoreUsage = cpu.pCoreUsage
                    next.eCoreUsage = cpu.eCoreUsage
                    next.pCoreCount = cpu.pCoreCount
                    next.eCoreCount = cpu.eCoreCount
                    next.perCoreUsages = cpu.perCoreUsages
                    Self.appendRingBuffer(&next.cpuHistory, value: cpu.totalUsage)

                    next.gpuUsage = gpu.deviceUtilization
                    next.gpuRenderUsage = gpu.rendererUtilization
                    next.gpuTilerUsage = gpu.tilerUtilization
                    next.gpuMemoryMB = gpu.inUseMemoryMB
                    next.gpuAllocMemoryMB = gpu.allocMemoryMB
                    Self.appendRingBuffer(&next.gpuHistory, value: gpu.deviceUtilization)

                    next.memoryUsedGB = mdn.memoryUsedGB
                    next.memoryTotalGB = mdn.memoryTotalGB
                    next.memoryWiredGB = mdn.memoryWiredGB
                    next.memoryCompressedGB = mdn.memoryCompressedGB
                    next.memoryUsagePercent = mdn.memoryUsagePercent
                    next.memoryPressure = mdn.memoryPressure
                    next.swapUsedMB = mdn.swapUsedMB
                    Self.appendRingBuffer(&next.memoryHistory, value: mdn.memoryUsagePercent)

                    next.netUploadBytesPerSec = mdn.netUploadBytesPerSec
                    next.netDownloadBytesPerSec = mdn.netDownloadBytesPerSec
                    next.diskReadBytesPerSec = mdn.diskReadBytesPerSec
                    next.diskWriteBytesPerSec = mdn.diskWriteBytesPerSec
                    next.diskFreeGB = mdn.diskFreeGB

                    if let thermal {
                        next.cpuTempCelsius = thermal.cpuTempCelsius
                        next.gpuTempCelsius = thermal.gpuTempCelsius
                        next.nandTempCelsius = thermal.nandTempCelsius
                        next.fans = thermal.fans
                        next.systemPowerWatts = thermal.systemPowerWatts
                    }

                    if let topProcs {
                        next.topProcesses = topProcs
                    }

                    self.snapshot = next
                    self.onSnapshotUpdated?(next)
                }
            }
        }
    }

    private static func appendRingBuffer(_ buffer: inout [Double], value: Double, capacity: Int = 60) {
        if buffer.count >= capacity {
            buffer.removeFirst(buffer.count - capacity + 1)
        }
        buffer.append(value)
    }
}
