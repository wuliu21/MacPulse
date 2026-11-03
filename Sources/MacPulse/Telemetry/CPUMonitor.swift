import Foundation
import Darwin
import IOKit

public struct CPUSampleResult: Sendable {
    public let totalUsage: Double
    public let pCoreUsage: Double
    public let eCoreUsage: Double
    public let pCoreCount: Int
    public let eCoreCount: Int
    public let perCoreUsages: [Double]
}

public final class CPUMonitor {
    private var previousTicks: [(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)] = []
    private let pCoreCount: Int
    private let eCoreCount: Int
    private let isECoreByIndex: [Bool]

    public init() {
        let pCount = Self.sysctlInt("hw.perflevel0.logicalcpu") ?? 0
        let eCount = Self.sysctlInt("hw.perflevel1.logicalcpu") ?? 0
        let total = Self.sysctlInt("hw.ncpu") ?? ProcessInfo.processInfo.processorCount

        self.pCoreCount = pCount > 0 ? pCount : total
        self.eCoreCount = eCount

        // Discover exact E-core vs P-core mapping from IODeviceTree:/cpus, fallback to 0..<eCount = E-core
        var map = Array(repeating: false, count: max(total, pCount + eCount))
        if eCount > 0 {
            for i in 0..<min(eCount, map.count) {
                map[i] = true
            }
        }
        Self.populateClusterTypesFromDeviceTree(&map)
        self.isECoreByIndex = map
    }

    public func sample() -> CPUSampleResult {
        var numCPUsU: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUsU,
            &cpuInfo,
            &numCpuInfo
        )

        guard result == KERN_SUCCESS, let info = cpuInfo else {
            return CPUSampleResult(
                totalUsage: 0,
                pCoreUsage: 0,
                eCoreUsage: 0,
                pCoreCount: pCoreCount,
                eCoreCount: eCoreCount,
                perCoreUsages: []
            )
        }

        // CRITICAL: Always deallocate Mach VM pages returned by host_processor_info
        defer {
            let allocSize = vm_size_t(Int(numCpuInfo) * MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), allocSize)
        }

        let numCPUs = Int(numCPUsU)
        var currentTicks: [(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)] = []
        currentTicks.reserveCapacity(numCPUs)

        var perCore: [Double] = []
        perCore.reserveCapacity(numCPUs)

        var pCoreSum: Double = 0
        var pCoreSeen: Int = 0
        var eCoreSum: Double = 0
        var eCoreSeen: Int = 0
        var totalSum: Double = 0

        for i in 0..<numCPUs {
            let base = Int(CPU_STATE_MAX) * i
            let user = UInt64(UInt32(bitPattern: info[base + Int(CPU_STATE_USER)]))
            let system = UInt64(UInt32(bitPattern: info[base + Int(CPU_STATE_SYSTEM)]))
            let idle = UInt64(UInt32(bitPattern: info[base + Int(CPU_STATE_IDLE)]))
            let nice = UInt64(UInt32(bitPattern: info[base + Int(CPU_STATE_NICE)]))

            currentTicks.append((user: user, system: system, idle: idle, nice: nice))

            let usage: Double
            if i < previousTicks.count {
                let prev = previousTicks[i]
                let dUser = user >= prev.user ? user - prev.user : 0
                let dSys = system >= prev.system ? system - prev.system : 0
                let dIdle = idle >= prev.idle ? idle - prev.idle : 0
                let dNice = nice >= prev.nice ? nice - prev.nice : 0

                let totalTicks = dUser + dSys + dIdle + dNice
                let activeTicks = dUser + dSys + dNice
                if totalTicks > 0 {
                    usage = min(100.0, max(0.0, (Double(activeTicks) / Double(totalTicks)) * 100.0))
                } else {
                    usage = 0.0
                }
            } else {
                usage = 0.0
            }

            perCore.append(usage)
            totalSum += usage

            let isECore = (i < isECoreByIndex.count) ? isECoreByIndex[i] : false
            if isECore {
                eCoreSum += usage
                eCoreSeen += 1
            } else {
                pCoreSum += usage
                pCoreSeen += 1
            }
        }

        previousTicks = currentTicks

        let avgTotal = numCPUs > 0 ? totalSum / Double(numCPUs) : 0
        let avgP = pCoreSeen > 0 ? pCoreSum / Double(pCoreSeen) : avgTotal
        let avgE = eCoreSeen > 0 ? eCoreSum / Double(eCoreSeen) : 0

        return CPUSampleResult(
            totalUsage: avgTotal,
            pCoreUsage: avgP,
            eCoreUsage: avgE,
            pCoreCount: pCoreSeen > 0 ? pCoreSeen : pCoreCount,
            eCoreCount: eCoreSeen > 0 ? eCoreSeen : eCoreCount,
            perCoreUsages: perCore
        )
    }

    private static func sysctlInt(_ name: String) -> Int? {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        if sysctlbyname(name, &value, &size, nil, 0) == 0 {
            return Int(value)
        }
        return nil
    }

    private static func populateClusterTypesFromDeviceTree(_ map: inout [Bool]) {
        let entry = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/cpus")
        guard entry != IO_OBJECT_NULL else { return }
        defer { IOObjectRelease(entry) }

        var iterator: io_iterator_t = 0
        guard IORegistryEntryGetChildIterator(entry, kIODeviceTreePlane, &iterator) == KERN_SUCCESS else { return }
        defer { IOObjectRelease(iterator) }

        var child = IOIteratorNext(iterator)
        while child != IO_OBJECT_NULL {
            defer {
                IOObjectRelease(child)
                child = IOIteratorNext(iterator)
            }

            var propsRef: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(child, &propsRef, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let dict = propsRef?.takeRetainedValue() as? [String: Any] else {
                continue
            }

            let logicalID: Int?
            if let num = dict["logical-cpu-id"] as? Int {
                logicalID = num
            } else if let data = dict["logical-cpu-id"] as? Data, data.count >= 4 {
                logicalID = Int(data.withUnsafeBytes { $0.load(as: UInt32.self) })
            } else {
                logicalID = nil
            }

            if let idx = logicalID, idx >= 0, idx < map.count,
               let clusterData = dict["cluster-type"] as? Data,
               let clusterStr = String(data: clusterData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters) {
                map[idx] = clusterStr.uppercased().hasPrefix("E")
            }
        }
    }
}
