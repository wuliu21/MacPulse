import SwiftUI
import AppKit

public struct HUDRootView: View {
    @ObservedObject var coordinator: TelemetryCoordinator
    @ObservedObject var settings: HUDSettings

    public init(coordinator: TelemetryCoordinator, settings: HUDSettings) {
        self.coordinator = coordinator
        self.settings = settings
    }

    public var body: some View {
        Group {
            switch settings.displayMode {
            case .dashboard:
                dashboardCard
            case .compact:
                compactPill
            }
        }
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Compact Pill Mode

    private var compactPill: some View {
        let snap = coordinator.snapshot
        return HStack(spacing: 12) {
            // Status dot
            Circle()
                .fill(settings.effectiveClickThrough ? Color(red: 0.24, green: 0.92, blue: 0.75) : Color.orange)
                .frame(width: 7, height: 7)
                .shadow(color: (settings.effectiveClickThrough ? Color.mint : Color.orange).opacity(0.8), radius: 4)

            // CPU
            HStack(spacing: 4) {
                Text("CPU")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.65))
                Text(String(format: "%4.1f%%", snap.cpuTotalUsage))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Formatters.metricColor(percent: snap.cpuTotalUsage))
                if let temp = snap.cpuTempCelsius {
                    Text(String(format: "%.0f°", temp))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Formatters.tempColor(celsius: temp))
                }
            }

            dividerLine

            // GPU
            HStack(spacing: 4) {
                Text("GPU")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.65))
                Text(String(format: "%4.1f%%", snap.gpuUsage))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Formatters.metricColor(percent: snap.gpuUsage))
            }

            dividerLine

            // RAM
            HStack(spacing: 4) {
                Text("RAM")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.65))
                Text(String(format: "%.1fG", snap.memoryUsedGB))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Formatters.metricColor(percent: snap.memoryUsagePercent))
            }

            dividerLine

            // Net
            HStack(spacing: 6) {
                Text("↓" + Formatters.formatBytesRate(snap.netDownloadBytesPerSec))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(red: 0.38, green: 0.85, blue: 1.0))
                Text("↑" + Formatters.formatBytesRate(snap.netUploadBytesPerSec))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(red: 0.65, green: 0.55, blue: 1.0))
            }

            if let watts = snap.systemPowerWatts {
                dividerLine
                Text(String(format: "⚡%.1fW", watts))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.32))
            }
        }
        .monospacedDigit()
        .shadow(color: .black.opacity(0.9), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(hudBackground(cornerRadius: 20))
        .padding(4)
    }

    // MARK: - Full Dashboard Mode

    private var dashboardCard: some View {
        let snap = coordinator.snapshot
        return VStack(alignment: .leading, spacing: 10) {
            headerSection(snap: snap)

            sectionDivider

            cpuSection(snap: snap)

            sectionDivider

            gpuSection(snap: snap)

            sectionDivider

            memorySection(snap: snap)

            if settings.showThermalAndPower {
                sectionDivider
                thermalFanSection(snap: snap)
            }

            if settings.showNetworkAndDisk {
                sectionDivider
                networkDiskSection(snap: snap)
            }

            if settings.showTopProcesses {
                sectionDivider
                topProcessesSection(snap: snap)
            }
        }
        .monospacedDigit()
        .shadow(color: .black.opacity(0.88), radius: 2, x: 0, y: 1)
        .padding(14)
        .frame(width: 310)
        .background(hudBackground(cornerRadius: 16))
        .padding(6)
    }

    // MARK: - Sections

    private func headerSection(snap: SystemSnapshot) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(settings.effectiveClickThrough ? Color(red: 0.24, green: 0.92, blue: 0.75) : Color.orange)
                .frame(width: 7, height: 7)
                .shadow(color: (settings.effectiveClickThrough ? Color.mint : Color.orange).opacity(0.8), radius: 4)

            Text("MACPULSE")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .tracking(1.2)
                .foregroundColor(.white.opacity(0.92))

            if let watts = snap.systemPowerWatts {
                Text(String(format: "⚡ %.1fW", watts))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.32))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                    )
            }

            Spacer()

            if settings.effectiveClickThrough {
                Text("🔒穿透 · ⌥拖拽")
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.50))
            } else {
                Text("🔓可拖拽移动")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.orange.opacity(0.18)))
            }
        }
    }

    private func cpuSection(snap: SystemSnapshot) -> some View {
        let color = Formatters.metricColor(percent: snap.cpuTotalUsage)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Label {
                    Text("CPU")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "cpu")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(color)
                }

                Text("\(snap.pCoreCount)P+\(snap.eCoreCount)E")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.52))

                Spacer()

                if let temp = snap.cpuTempCelsius {
                    Text(String(format: "%.1f°C", temp))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Formatters.tempColor(celsius: temp))
                        .padding(.trailing, 4)
                }

                Text(String(format: "%5.1f%%", snap.cpuTotalUsage))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }

            SparklineView(values: snap.cpuHistory, accentColor: color, height: 32)

            // P-Core vs E-Core dual progress bars
            HStack(spacing: 10) {
                miniClusterBar(
                    label: "P核",
                    percent: snap.pCoreUsage,
                    color: Formatters.metricColor(percent: snap.pCoreUsage)
                )
                miniClusterBar(
                    label: "E核",
                    percent: snap.eCoreUsage,
                    color: Color(red: 0.35, green: 0.78, blue: 1.0)
                )
            }

            if settings.showPerCoreBars, !snap.perCoreUsages.isEmpty {
                PerCoreMiniBarsView(usages: snap.perCoreUsages, eCoreCount: snap.eCoreCount)
                    .padding(.top, 2)
            }
        }
    }

    private func gpuSection(snap: SystemSnapshot) -> some View {
        let color = Formatters.metricColor(percent: snap.gpuUsage)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Label {
                    Text("GPU")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "sparkles.tv")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(String(format: "显存 %.0fM", snap.gpuMemoryMB))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))

                Spacer()

                if let temp = snap.gpuTempCelsius {
                    Text(String(format: "%.1f°C", temp))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Formatters.tempColor(celsius: temp))
                        .padding(.trailing, 4)
                }

                Text(String(format: "%5.1f%%", snap.gpuUsage))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }

            SparklineView(values: snap.gpuHistory, accentColor: color, height: 30)

            HStack(spacing: 10) {
                miniClusterBar(
                    label: "渲染",
                    percent: snap.gpuRenderUsage,
                    color: Color(red: 0.72, green: 0.52, blue: 1.0)
                )
                miniClusterBar(
                    label: "Tiler",
                    percent: snap.gpuTilerUsage,
                    color: Color(red: 0.38, green: 0.85, blue: 1.0)
                )
            }
        }
    }

    private func memorySection(snap: SystemSnapshot) -> some View {
        let color = Formatters.metricColor(percent: snap.memoryUsagePercent)
        return VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Label {
                    Text("内存")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "memorychip")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(color)
                }

                Text("压力:\(snap.memoryPressure.rawValue)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(pressureColor(snap.memoryPressure))

                Spacer()

                Text(String(format: "%.1f / %.0f GB", snap.memoryUsedGB, snap.memoryTotalGB))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.82))

                Text(String(format: "%4.0f%%", snap.memoryUsagePercent))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.10))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.75), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(4, geo.size.width * CGFloat(min(100, max(0, snap.memoryUsagePercent)) / 100.0)))
                }
            }
            .frame(height: 6)

            HStack {
                Text(String(format: "联动:%.1fG", snap.memoryWiredGB))
                Spacer()
                Text(String(format: "压缩:%.1fG", snap.memoryCompressedGB))
                Spacer()
                Text(String(format: "Swap:%.0fM", snap.swapUsedMB))
                    .foregroundColor(snap.swapUsedMB > 512 ? Color.orange : .white.opacity(0.60))
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(.white.opacity(0.60))
        }
    }

    private func thermalFanSection(snap: SystemSnapshot) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "fanblades")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(red: 0.38, green: 0.85, blue: 1.0))

            if snap.fans.isEmpty {
                Text("风扇: 无风扇/被动散热")
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.72))
            } else {
                let allZero = snap.fans.allSatisfy { $0.currentRPM == 0 }
                if allZero {
                    Text("风扇(\(snap.fans.count)): 0 RPM (静音停转)")
                        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(red: 0.24, green: 0.92, blue: 0.75))
                } else {
                    let rpmText = snap.fans.map { "#\($0.id + 1):\($0.currentRPM)" }.joined(separator: " ")
                    Text("风扇 \(rpmText) RPM")
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(red: 0.38, green: 0.85, blue: 1.0))
                }
            }

            Spacer()

            if let nand = snap.nandTempCelsius {
                Text(String(format: "SSD %.0f°C", nand))
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.68))
            }
        }
    }

    private func networkDiskSection(snap: SystemSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "network")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(Color(red: 0.38, green: 0.85, blue: 1.0))
                Text("网络")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                Text("↓ " + Formatters.formatBytesRate(snap.netDownloadBytesPerSec))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(red: 0.38, green: 0.85, blue: 1.0))
                Text("↑ " + Formatters.formatBytesRate(snap.netUploadBytesPerSec))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(red: 0.72, green: 0.56, blue: 1.0))
            }

            HStack {
                Image(systemName: "internaldrive")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(Color(red: 0.24, green: 0.92, blue: 0.75))
                Text(String(format: "磁盘 (余%.0fG)", snap.diskFreeGB))
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.75))
                Spacer()
                Text("R " + Formatters.formatBytesRate(snap.diskReadBytesPerSec))
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.78))
                Text("W " + Formatters.formatBytesRate(snap.diskWriteBytesPerSec))
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.78))
            }
        }
    }

    private func topProcessesSection(snap: SystemSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("TOP 进程 (3s)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.52))
                Spacer()
                Text("CPU%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.52))
            }

            if snap.topProcesses.isEmpty {
                Text("采样计算中...")
                    .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.45))
            } else {
                ForEach(snap.topProcesses) { proc in
                    HStack {
                        Text(proc.name)
                            .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.86))
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        Text(String(format: "%5.1f%%", proc.cpuPercent))
                            .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(Formatters.metricColor(percent: min(100, proc.cpuPercent)))
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func miniClusterBar(label: String, percent: Double, color: Color) -> some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.68))
                .frame(width: 28, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.white.opacity(0.10))
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(color)
                        .frame(width: max(2, geo.size.width * CGFloat(min(100, max(0, percent)) / 100.0)))
                }
            }
            .frame(height: 5)

            Text(String(format: "%3.0f%%", percent))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.82))
                .frame(width: 30, alignment: .trailing)
        }
    }

    private func pressureColor(_ state: MemoryPressureState) -> Color {
        switch state {
        case .normal: return Color(red: 0.24, green: 0.92, blue: 0.75)
        case .warning: return Color(red: 1.0, green: 0.76, blue: 0.22)
        case .critical: return Color(red: 1.0, green: 0.35, blue: 0.38)
        }
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(height: 0.5)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.18))
            .frame(width: 1, height: 12)
    }

    private func hudBackground(cornerRadius: CGFloat) -> some View {
        let alpha = settings.backgroundOpacity
        return ZStack {
            if alpha > 0.03 {
                VisualEffectBlurView(material: .hudWindow, blendingMode: .behindWindow)
                    .opacity(min(1.0, alpha * 1.15))
            }
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(red: 0.05, green: 0.07, blue: 0.10).opacity(alpha))
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            settings.effectiveClickThrough
                                ? Color.white.opacity(max(0.12, alpha * 0.45))
                                : Color.orange.opacity(0.85),
                            settings.effectiveClickThrough
                                ? Color.white.opacity(max(0.04, alpha * 0.15))
                                : Color.orange.opacity(0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: settings.effectiveClickThrough ? 0.8 : 1.5
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

public struct VisualEffectBlurView: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
