import Foundation
import IOKit

public struct ThermalFanSampleResult: Sendable {
    public let cpuTempCelsius: Double?
    public let gpuTempCelsius: Double?
    public let nandTempCelsius: Double?
    public let fans: [FanReading]
    public let systemPowerWatts: Double?
}

public final class ThermalFanSensor {
    // Exact 80-byte C-compatible layout for AppleSMC kernel struct
    private struct SMCVersion {
        var major: UInt8 = 0
        var minor: UInt8 = 0
        var build: UInt8 = 0
        var reserved: UInt8 = 0
        var release: UInt16 = 0
    }

    private struct SMCPLimitData {
        var version: UInt16 = 0
        var length: UInt16 = 0
        var cpuPLimit: UInt32 = 0
        var gpuPLimit: UInt32 = 0
        var memPLimit: UInt32 = 0
    }

    private struct SMCKeyInfoData {
        var dataSize: UInt32 = 0
        var dataType: UInt32 = 0
        var dataAttributes: UInt8 = 0
        var pad0: UInt8 = 0
        var pad1: UInt8 = 0
        var pad2: UInt8 = 0
    }

    private struct SMCKeyData {
        var key: UInt32 = 0
        var vers = SMCVersion()
        var padVers: UInt16 = 0
        var pLimitData = SMCPLimitData()
        var keyInfo = SMCKeyInfoData()
        var result: UInt8 = 0
        var status: UInt8 = 0
        var data8: UInt8 = 0
        var padData8: UInt8 = 0
        var data32: UInt32 = 0
        var bytes: (
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
        ) = (
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0
        )
    }

    private var smcConnect: io_connect_t = 0
    private var keyInfoCache: [UInt32: (size: UInt32, type: UInt32)] = [:]

    // Dynamic IOHIDEventSystem function pointers
    private typealias CreateFn = @convention(c) (CFAllocator?) -> Unmanaged<CFTypeRef>?
    private typealias SetMatchingFn = @convention(c) (CFTypeRef, CFDictionary) -> Void
    private typealias CopyServicesFn = @convention(c) (CFTypeRef) -> Unmanaged<CFArray>?
    private typealias CopyPropFn = @convention(c) (CFTypeRef, CFString) -> Unmanaged<CFTypeRef>?
    private typealias CopyEventFn = @convention(c) (CFTypeRef, Int64, Int32, Int64) -> Unmanaged<CFTypeRef>?
    private typealias GetFloatFn = @convention(c) (CFTypeRef, Int32) -> Double

    private var iohidCreate: CreateFn?
    private var iohidSetMatching: SetMatchingFn?
    private var iohidCopyServices: CopyServicesFn?
    private var iohidCopyProp: CopyPropFn?
    private var iohidCopyEvent: CopyEventFn?
    private var iohidGetFloat: GetFloatFn?

    public init() {
        // 1. Open AppleSMC connection if available
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        if service != IO_OBJECT_NULL {
            var conn: io_connect_t = 0
            if IOServiceOpen(service, mach_task_self_, 0, &conn) == kIOReturnSuccess {
                self.smcConnect = conn
            }
            IOObjectRelease(service)
        }

        // 2. Dynamically resolve IOHIDEventSystem symbols
        if let handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY) {
            if let s1 = dlsym(handle, "IOHIDEventSystemClientCreate"),
               let s2 = dlsym(handle, "IOHIDEventSystemClientSetMatching"),
               let s3 = dlsym(handle, "IOHIDEventSystemClientCopyServices"),
               let s4 = dlsym(handle, "IOHIDServiceClientCopyProperty"),
               let s5 = dlsym(handle, "IOHIDServiceClientCopyEvent"),
               let s6 = dlsym(handle, "IOHIDEventGetFloatValue") {
                self.iohidCreate = unsafeBitCast(s1, to: CreateFn.self)
                self.iohidSetMatching = unsafeBitCast(s2, to: SetMatchingFn.self)
                self.iohidCopyServices = unsafeBitCast(s3, to: CopyServicesFn.self)
                self.iohidCopyProp = unsafeBitCast(s4, to: CopyPropFn.self)
                self.iohidCopyEvent = unsafeBitCast(s5, to: CopyEventFn.self)
                self.iohidGetFloat = unsafeBitCast(s6, to: GetFloatFn.self)
            }
        }
    }

    deinit {
        if smcConnect != 0 {
            IOServiceClose(smcConnect)
            smcConnect = 0
        }
    }

    public func sample() -> ThermalFanSampleResult {
        var cpuTemps: [Double] = []
        var gpuTemps: [Double] = []
        var nandTemp: Double? = nil
        var fans: [FanReading] = []
        var powerWatts: Double? = nil

        // 1. Read SMC sensors (CPU, GPU, Fans, Power)
        if smcConnect != 0 {
            for key in ["Tp01", "Tp05", "Tp09", "Tp0D", "Tp0T", "Tc0a", "TC0P"] {
                if let val = readSMCDouble(key), val > 15.0 && val < 125.0 {
                    cpuTemps.append(val)
                }
            }
            for key in ["Tg05", "Tg0D", "Tg0P", "Tg0T", "TG0D"] {
                if let val = readSMCDouble(key), val > 15.0 && val < 125.0 {
                    gpuTemps.append(val)
                }
            }
            if let pstr = readSMCDouble("PSTR"), pstr > 0.1 && pstr < 300.0 {
                powerWatts = pstr
            }

            if let (_, bytes) = readSMCBytes("FNum"), let countByte = bytes.first {
                let fanCount = Int(countByte)
                if fanCount > 0 && fanCount <= 6 {
                    for idx in 0..<fanCount {
                        let current = Int((readSMCDouble("F\(idx)Ac") ?? 0).rounded())
                        let maxRPM = Int((readSMCDouble("F\(idx)Mx") ?? 6500).rounded())
                        fans.append(FanReading(id: idx, currentRPM: max(0, current), maxRPM: max(1000, maxRPM)))
                    }
                }
            }
        }

        // 2. Read IOHIDEventSystem thermal sensors (supplements or falls back for die & NAND temps)
        let hidReadings = readIOHIDTemperatures()
        if cpuTemps.isEmpty && !hidReadings.tdieTemps.isEmpty {
            cpuTemps = hidReadings.tdieTemps
        }
        if gpuTemps.isEmpty && !hidReadings.tdieTemps.isEmpty {
            gpuTemps = hidReadings.tdieTemps
        }
        nandTemp = hidReadings.nandTemp

        let finalCPUTemp = cpuTemps.isEmpty ? nil : (cpuTemps.reduce(0, +) / Double(cpuTemps.count))
        let finalGPUTemp = gpuTemps.isEmpty ? finalCPUTemp : (gpuTemps.reduce(0, +) / Double(gpuTemps.count))

        return ThermalFanSampleResult(
            cpuTempCelsius: finalCPUTemp,
            gpuTempCelsius: finalGPUTemp,
            nandTempCelsius: nandTemp,
            fans: fans,
            systemPowerWatts: powerWatts
        )
    }

    private func readIOHIDTemperatures() -> (tdieTemps: [Double], nandTemp: Double?) {
        guard let create = iohidCreate,
              let setMatch = iohidSetMatching,
              let copyServices = iohidCopyServices,
              let copyProp = iohidCopyProp,
              let copyEvent = iohidCopyEvent,
              let getFloat = iohidGetFloat,
              let client = create(kCFAllocatorDefault)?.takeRetainedValue() else {
            return ([], nil)
        }

        let match: [String: Any] = ["PrimaryUsagePage": 0xff00, "PrimaryUsage": 5]
        setMatch(client, match as CFDictionary)

        guard let services = copyServices(client)?.takeRetainedValue() as? [CFTypeRef] else {
            return ([], nil)
        }

        var tdie: [Double] = []
        var nand: Double? = nil

        for service in services {
            guard let name = copyProp(service, "Product" as CFString)?.takeRetainedValue() as? String,
                  let event = copyEvent(service, 15, 0, 0)?.takeRetainedValue() else {
                continue
            }
            let temp = getFloat(event, 15 << 16)
            guard temp > 15.0 && temp < 125.0 else { continue }

            let lower = name.lowercased()
            if lower.contains("tdie") || lower.contains("pacc") || lower.contains("eacc") {
                tdie.append(temp)
            } else if lower.contains("nand") && nand == nil {
                nand = temp
            }
        }

        return (tdie, nand)
    }

    private func fourCC(_ str: String) -> UInt32 {
        var r: UInt32 = 0
        for c in str.utf8.prefix(4) {
            r = (r << 8) | UInt32(c)
        }
        return r
    }

    private func readSMCBytes(_ key: String) -> (type: UInt32, bytes: [UInt8])? {
        guard smcConnect != 0, MemoryLayout<SMCKeyData>.size == 80 else { return nil }
        let code = fourCC(key)

        let info: (size: UInt32, type: UInt32)
        if let cached = keyInfoCache[code] {
            info = cached
        } else {
            var input = SMCKeyData()
            var output = SMCKeyData()
            input.key = code
            input.data8 = 9 // kSMCReadKeyInfo
            var outSize = MemoryLayout<SMCKeyData>.size
            let kr = IOConnectCallStructMethod(
                smcConnect,
                2,
                &input,
                MemoryLayout<SMCKeyData>.size,
                &output,
                &outSize
            )
            guard kr == kIOReturnSuccess, output.result == 0, output.keyInfo.dataSize > 0, output.keyInfo.dataSize <= 32 else {
                return nil
            }
            info = (output.keyInfo.dataSize, output.keyInfo.dataType)
            keyInfoCache[code] = info
        }

        var input = SMCKeyData()
        var output = SMCKeyData()
        input.key = code
        input.keyInfo.dataSize = info.size
        input.data8 = 5 // kSMCReadBytes
        var outSize = MemoryLayout<SMCKeyData>.size
        let kr = IOConnectCallStructMethod(
            smcConnect,
            2,
            &input,
            MemoryLayout<SMCKeyData>.size,
            &output,
            &outSize
        )
        guard kr == kIOReturnSuccess, output.result == 0 else {
            return nil
        }

        let rawBytes = withUnsafeBytes(of: output.bytes) { Array($0.prefix(Int(info.size))) }
        return (info.type, rawBytes)
    }

    private func readSMCDouble(_ key: String) -> Double? {
        guard let (type, bytes) = readSMCBytes(key) else { return nil }
        let fltType = fourCC("flt ")
        let sp78Type = fourCC("sp78")
        let fpe2Type = fourCC("fpe2")

        if type == fltType, bytes.count == 4 {
            let val = bytes.withUnsafeBytes { $0.load(as: Float.self) }
            return val.isFinite ? Double(val) : nil
        } else if type == sp78Type, bytes.count == 2 {
            let raw = (Int16(bitPattern: UInt16(bytes[0]) << 8 | UInt16(bytes[1])))
            return Double(raw) / 256.0
        } else if type == fpe2Type, bytes.count == 2 {
            let raw = (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
            return Double(raw) / 4.0
        }
        return nil
    }
}
