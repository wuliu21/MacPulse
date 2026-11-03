import Foundation
import IOKit

public struct GPUSampleResult: Sendable {
    public let deviceUtilization: Double
    public let rendererUtilization: Double
    public let tilerUtilization: Double
    public let inUseMemoryMB: Double
    public let allocMemoryMB: Double
}

public final class GPUMonitor {
    public init() {}

    public func sample() -> GPUSampleResult {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IOAccelerator")
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard result == KERN_SUCCESS else {
            return GPUSampleResult(deviceUtilization: 0, rendererUtilization: 0, tilerUtilization: 0, inUseMemoryMB: 0, allocMemoryMB: 0)
        }
        defer { IOObjectRelease(iterator) }

        var maxDeviceUtil: Double = 0
        var maxRendererUtil: Double = 0
        var maxTilerUtil: Double = 0
        var totalInUseBytes: Double = 0
        var totalAllocBytes: Double = 0

        var service = IOIteratorNext(iterator)
        while service != IO_OBJECT_NULL {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            var propsRef: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let props = propsRef?.takeRetainedValue() as? [String: Any],
                  let stats = props["PerformanceStatistics"] as? [String: Any] else {
                continue
            }

            let devUtil = Self.doubleValue(stats["Device Utilization %"])
                ?? Self.doubleValue(stats["GPU Activity(%)"])
                ?? 0
            let renUtil = Self.doubleValue(stats["Renderer Utilization %"]) ?? 0
            let tilUtil = Self.doubleValue(stats["Tiler Utilization %"]) ?? 0
            let inUse = Self.doubleValue(stats["In use system memory"]) ?? 0
            let alloc = Self.doubleValue(stats["Alloc system memory"]) ?? 0

            let effectiveDevice = max(devUtil, max(renUtil, tilUtil))
            if effectiveDevice >= maxDeviceUtil {
                maxDeviceUtil = effectiveDevice
                maxRendererUtil = renUtil
                maxTilerUtil = tilUtil
            }
            totalInUseBytes += inUse
            totalAllocBytes += alloc
        }

        return GPUSampleResult(
            deviceUtilization: min(100.0, max(0.0, maxDeviceUtil)),
            rendererUtilization: min(100.0, max(0.0, maxRendererUtil)),
            tilerUtilization: min(100.0, max(0.0, maxTilerUtil)),
            inUseMemoryMB: totalInUseBytes / (1024.0 * 1024.0),
            allocMemoryMB: totalAllocBytes / (1024.0 * 1024.0)
        )
    }

    private static func doubleValue(_ any: Any?) -> Double? {
        if let num = any as? NSNumber {
            return num.doubleValue
        } else if let d = any as? Double {
            return d
        } else if let i = any as? Int {
            return Double(i)
        }
        return nil
    }
}
