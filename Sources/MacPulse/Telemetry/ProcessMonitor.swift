import Foundation
import Darwin

public final class ProcessMonitor {
    private var previousCPUTimeByPID: [Int32: UInt64] = [:]
    private var previousSampleTimestamp: CFAbsoluteTime = 0
    private let timebaseNumer: UInt64
    private let timebaseDenom: UInt64

    public init() {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        self.timebaseNumer = UInt64(max(1, info.numer))
        self.timebaseDenom = UInt64(max(1, info.denom))
    }

    public func sampleTopProcesses(limit: Int = 3) -> [ProcessEntry] {
        let now = CFAbsoluteTimeGetCurrent()
        let dt = now - previousSampleTimestamp

        let estimatedCount = proc_listallpids(nil, 0)
        guard estimatedCount > 0 else { return [] }

        let capacity = Int(estimatedCount) + 64
        var pids = Array<Int32>(repeating: 0, count: capacity)
        let actualBytes = pids.withUnsafeMutableBufferPointer { buf -> Int32 in
            guard let base = buf.baseAddress else { return 0 }
            return proc_listallpids(base, Int32(capacity * MemoryLayout<Int32>.stride))
        }
        guard actualBytes > 0 else { return [] }

        let count = min(capacity, Int(actualBytes))
        var currentCPUTime: [Int32: UInt64] = [:]
        currentCPUTime.reserveCapacity(count)

        var deltas: [(pid: Int32, deltaNs: UInt64)] = []
        deltas.reserveCapacity(32)

        let taskInfoSize = Int32(MemoryLayout<proc_taskinfo>.stride)

        for i in 0..<count {
            let pid = pids[i]
            guard pid > 0 else { continue }

            var taskInfo = proc_taskinfo()
            let ret = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, taskInfoSize)
            guard ret == taskInfoSize else { continue }

            let totalMachTicks = taskInfo.pti_total_user &+ taskInfo.pti_total_system
            currentCPUTime[pid] = totalMachTicks

            if previousSampleTimestamp > 0, dt > 0.1, let prevTicks = previousCPUTimeByPID[pid], totalMachTicks > prevTicks {
                let diffTicks = totalMachTicks - prevTicks
                let diffNs = (diffTicks &* timebaseNumer) / timebaseDenom
                if diffNs > 0 {
                    deltas.append((pid: pid, deltaNs: diffNs))
                }
            }
        }

        previousCPUTimeByPID = currentCPUTime
        previousSampleTimestamp = now

        guard dt > 0.1, !deltas.isEmpty else { return [] }

        deltas.sort { $0.deltaNs > $1.deltaNs }
        let topSlice = deltas.prefix(limit)
        let elapsedNs = dt * 1_000_000_000.0

        var results: [ProcessEntry] = []
        results.reserveCapacity(limit)

        for item in topSlice {
            let pct = (Double(item.deltaNs) / elapsedNs) * 100.0
            let name = Self.resolveProcessName(pid: item.pid)
            results.append(ProcessEntry(id: item.pid, name: name, cpuPercent: min(999.9, max(0.0, pct))))
        }

        return results
    }

    private static func resolveProcessName(pid: Int32) -> String {
        var pathBuffer = Array<CChar>(repeating: 0, count: Int(MAXPATHLEN))
        let pathLen = proc_pidpath(pid, &pathBuffer, UInt32(pathBuffer.count))
        if pathLen > 0 {
            let fullPath = String(cString: pathBuffer)
            let lastComponent = (fullPath as NSString).lastPathComponent
            if !lastComponent.isEmpty {
                return lastComponent
            }
        }

        var nameBuffer = Array<CChar>(repeating: 0, count: 256)
        let nameLen = proc_name(pid, &nameBuffer, UInt32(nameBuffer.count))
        if nameLen > 0 {
            let name = String(cString: nameBuffer)
            if !name.isEmpty {
                return name
            }
        }
        return "PID \(pid)"
    }
}
