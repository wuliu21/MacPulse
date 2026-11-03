import Foundation
import Darwin
import IOKit

public struct MemoryDiskNetSampleResult: Sendable {
    public let memoryUsedGB: Double
    public let memoryTotalGB: Double
    public let memoryWiredGB: Double
    public let memoryCompressedGB: Double
    public let memoryUsagePercent: Double
    public let memoryPressure: MemoryPressureState
    public let swapUsedMB: Double

    public let netUploadBytesPerSec: Double
    public let netDownloadBytesPerSec: Double
    public let diskReadBytesPerSec: Double
    public let diskWriteBytesPerSec: Double
    public let diskFreeGB: Double
}

public final class MemoryDiskNetMonitor {
    private let totalMemoryBytes: UInt64
    private var prevNetInBytes: UInt64 = 0
    private var prevNetOutBytes: UInt64 = 0
    private var prevNetTimestamp: CFAbsoluteTime = 0

    private var prevDiskReadBytes: UInt64 = 0
    private var prevDiskWriteBytes: UInt64 = 0
    private var prevDiskTimestamp: CFAbsoluteTime = 0

    public init() {
        self.totalMemoryBytes = ProcessInfo.processInfo.physicalMemory
    }

    public func sample() -> MemoryDiskNetSampleResult {
        let now = CFAbsoluteTimeGetCurrent()
        let mem = sampleMemory()
        let net = sampleNetwork(now: now)
        let disk = sampleDisk(now: now)

        return MemoryDiskNetSampleResult(
            memoryUsedGB: mem.usedGB,
            memoryTotalGB: mem.totalGB,
            memoryWiredGB: mem.wiredGB,
            memoryCompressedGB: mem.compressedGB,
            memoryUsagePercent: mem.percent,
            memoryPressure: mem.pressure,
            swapUsedMB: mem.swapMB,
            netUploadBytesPerSec: net.upBytesPerSec,
            netDownloadBytesPerSec: net.downBytesPerSec,
            diskReadBytesPerSec: disk.readBytesPerSec,
            diskWriteBytesPerSec: disk.writeBytesPerSec,
            diskFreeGB: disk.freeGB
        )
    }

    private func sampleMemory() -> (usedGB: Double, totalGB: Double, wiredGB: Double, compressedGB: Double, percent: Double, pressure: MemoryPressureState, swapMB: Double) {
        var pageSize: vm_size_t = 16384
        host_page_size(mach_host_self(), &pageSize)
        let pageBytes = UInt64(pageSize)

        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let res = withUnsafeMutablePointer(to: &vmStats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        let totalGB = Double(totalMemoryBytes) / (1024.0 * 1024.0 * 1024.0)
        guard res == KERN_SUCCESS else {
            return (0, totalGB, 0, 0, 0, .normal, 0)
        }

        // Activity Monitor "Memory Used" formula: App Memory (internal - purgeable) + Wired + Compressed
        let internalPages = UInt64(vmStats.internal_page_count)
        let purgeablePages = UInt64(vmStats.purgeable_count)
        let appPages = internalPages > purgeablePages ? (internalPages - purgeablePages) : UInt64(vmStats.active_count)
        let wiredPages = UInt64(vmStats.wire_count)
        let compressedPages = UInt64(vmStats.compressor_page_count)

        let usedBytes = min(totalMemoryBytes, (appPages + wiredPages + compressedPages) * pageBytes)
        let wiredBytes = wiredPages * pageBytes
        let compressedBytes = compressedPages * pageBytes

        let usedGB = Double(usedBytes) / (1024.0 * 1024.0 * 1024.0)
        let wiredGB = Double(wiredBytes) / (1024.0 * 1024.0 * 1024.0)
        let compressedGB = Double(compressedBytes) / (1024.0 * 1024.0 * 1024.0)
        let percent = totalGB > 0 ? min(100.0, max(0.0, (usedGB / totalGB) * 100.0)) : 0.0

        // Swap usage
        var swap = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        var swapMB: Double = 0
        if sysctlbyname("vm.swapusage", &swap, &swapSize, nil, 0) == 0 {
            swapMB = Double(swap.xsu_used) / (1024.0 * 1024.0)
        }

        let compressedRatio = totalGB > 0 ? (compressedGB / totalGB) : 0
        let pressure: MemoryPressureState
        if percent >= 90.0 || compressedRatio >= 0.30 || swapMB >= 4096 {
            pressure = .critical
        } else if percent >= 76.0 || compressedRatio >= 0.18 || swapMB >= 1024 {
            pressure = .warning
        } else {
            pressure = .normal
        }

        return (usedGB, totalGB, wiredGB, compressedGB, percent, pressure, swapMB)
    }

    private func sampleNetwork(now: CFAbsoluteTime) -> (upBytesPerSec: Double, downBytesPerSec: Double) {
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else {
            return (0, 0)
        }
        defer { freeifaddrs(ifaddrPtr) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = cursor {
            defer { cursor = addr.pointee.ifa_next }

            guard let sa = addr.pointee.ifa_addr, Int32(sa.pointee.sa_family) == AF_LINK else {
                continue
            }
            let flags = Int32(addr.pointee.ifa_flags)
            guard (flags & IFF_UP) != 0, (flags & IFF_LOOPBACK) == 0 else {
                continue
            }
            let name = String(cString: addr.pointee.ifa_name)
            // Only count physical network interfaces (en0, en1, pdp_ip, etc.) to avoid double counting tunnels/bridges
            guard name.hasPrefix("en") || name.hasPrefix("pdp_ip") else {
                continue
            }
            if let dataPtr = addr.pointee.ifa_data?.assumingMemoryBound(to: if_data.self) {
                totalIn &+= UInt64(dataPtr.pointee.ifi_ibytes)
                totalOut &+= UInt64(dataPtr.pointee.ifi_obytes)
            }
        }

        var upRate: Double = 0
        var downRate: Double = 0
        let dt = now - prevNetTimestamp
        if prevNetTimestamp > 0, dt > 0.05 {
            if totalOut >= prevNetOutBytes {
                upRate = Double(totalOut - prevNetOutBytes) / dt
            }
            if totalIn >= prevNetInBytes {
                downRate = Double(totalIn - prevNetInBytes) / dt
            }
        }
        prevNetInBytes = totalIn
        prevNetOutBytes = totalOut
        prevNetTimestamp = now

        return (upRate, downRate)
    }

    private func sampleDisk(now: CFAbsoluteTime) -> (readBytesPerSec: Double, writeBytesPerSec: Double, freeGB: Double) {
        var freeGB: Double = 0
        var sfs = statfs()
        if statfs("/", &sfs) == 0 {
            let freeBytes = UInt64(sfs.f_bavail) * UInt64(sfs.f_bsize)
            freeGB = Double(freeBytes) / (1024.0 * 1024.0 * 1024.0)
        }

        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOBlockStorageDriver"), &iterator) == KERN_SUCCESS else {
            return (0, 0, freeGB)
        }
        defer { IOObjectRelease(iterator) }

        var totalRead: UInt64 = 0
        var totalWrite: UInt64 = 0

        var drive = IOIteratorNext(iterator)
        while drive != IO_OBJECT_NULL {
            defer {
                IOObjectRelease(drive)
                drive = IOIteratorNext(iterator)
            }

            var propsRef: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(drive, &propsRef, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let props = propsRef?.takeRetainedValue() as? [String: Any],
               let stats = props["Statistics"] as? [String: Any] {
                if let r = stats["Bytes (Read)"] as? NSNumber {
                    totalRead &+= r.uint64Value
                }
                if let w = stats["Bytes (Write)"] as? NSNumber {
                    totalWrite &+= w.uint64Value
                }
            }
        }

        var readRate: Double = 0
        var writeRate: Double = 0
        let dt = now - prevDiskTimestamp
        if prevDiskTimestamp > 0, dt > 0.05 {
            if totalRead >= prevDiskReadBytes {
                readRate = Double(totalRead - prevDiskReadBytes) / dt
            }
            if totalWrite >= prevDiskWriteBytes {
                writeRate = Double(totalWrite - prevDiskWriteBytes) / dt
            }
        }
        prevDiskReadBytes = totalRead
        prevDiskWriteBytes = totalWrite
        prevDiskTimestamp = now

        return (readRate, writeRate, freeGB)
    }
}
