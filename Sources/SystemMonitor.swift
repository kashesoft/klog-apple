/*
 * Copyright (C) 2016 Andrey Kashaed
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Darwin
import Dispatch

class SystemMonitor {
    
    fileprivate enum Unit : Double {
        case Byte     = 1
        case Kilobyte = 1024
        case Megabyte = 1048576
        case Gigabyte = 1073741824
    }
    
    private static var sources: Int = 0
    private static var dispatchSource: DispatchSourceTimer?
    
    static func monitor(sources: Int) {
        self.sources = sources
        if (self.sources & Source.cpu) == Source.cpu || (self.sources & Source.ram) == Source.ram {
            self.startMonitoringIfNeeded()
        } else {
            self.stopMonitoringIfNeeded()
        }
    }
    
    private static func startMonitoringIfNeeded() {
        if self.dispatchSource != nil {
            return
        }
        self.dispatchSource = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue(label: "LogSystemDispatchQueue"))
        self.dispatchSource?.scheduleRepeating(deadline: .now(), interval: 1.0)
        self.dispatchSource?.setEventHandler {
            if (self.sources & Source.cpu) == Source.cpu {
                Log.util(source: Source.cpu, message: self.cpuMessage())
            }
            if (self.sources & Source.ram) == Source.ram {
                Log.util(source: Source.ram, message: self.ramMessage())
                Log.util(source: Source.ram, message: self.memoryUsageMessage())
            }
        }
        self.dispatchSource?.resume()
    }
    
    private static func stopMonitoringIfNeeded() {
        if self.dispatchSource == nil {
            return
        }
        self.dispatchSource?.cancel()
        self.dispatchSource = nil
    }
    
}

extension SystemMonitor {
    
    private static var previousInfo = host_cpu_load_info()
    
    fileprivate static func cpuMessage() -> String {
        guard let cpuUsage = getCpuUsage() else {
            return ""
        }
        return "user: \(String(format: "%.2f", cpuUsage.0))%, system: \(String(format: "%.2f", cpuUsage.1))%, idle: \(String(format: "%.2f", cpuUsage.2))%, nice: \(String(format: "%.2f", cpuUsage.3))%"
    }
    
    private static func getCpuUsage() -> (user: Double, system: Double, idle: Double, nice: Double)? {
        var info = host_cpu_load_info()
        var bufferSize = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride/MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(bufferSize)) {
                host_statistics(mach_host_self(), Int32(HOST_CPU_LOAD_INFO), $0, &bufferSize)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return nil
        }
        
        let userDiff = Double(info.cpu_ticks.0 - previousInfo.cpu_ticks.0)
        let systemDiff = Double(info.cpu_ticks.1 - previousInfo.cpu_ticks.1)
        let idleDiff = Double(info.cpu_ticks.2 - previousInfo.cpu_ticks.2)
        let niceDiff = Double(info.cpu_ticks.3 - previousInfo.cpu_ticks.3)
            
        let totalTicks = userDiff + systemDiff + idleDiff + niceDiff
            
        let user = userDiff / totalTicks * 100.0
        let system = systemDiff / totalTicks * 100.0
        let idle = idleDiff / totalTicks * 100.0
        let nice = niceDiff / totalTicks * 100.0
        
        previousInfo = info
        
        return (user, system, idle, nice)
    }
    
}

extension SystemMonitor {
    
    fileprivate static func ramMessage() -> String {
        guard let ramSize = getRamSize() else {
            return ""
        }
        return "resident: \(String(format: "%.2f", ramSize.0)) MB, residentMax: \(String(format: "%.2f", ramSize.1)) MB, virtual: \(String(format: "%.2f", ramSize.2)) MB"
    }
    
    private static func getRamSize() -> (virtual: Float, resident: Float, residentMax: Float)? {
        var info = mach_task_basic_info()
        var bufferSize = mach_msg_type_number_t(MemoryLayout.size(ofValue: info) / MemoryLayout<integer_t>.size)
        let kernReturn = withUnsafeMutablePointer(to: &info) { infoPtr in
            return infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(bufferSize)) { (machPtr: UnsafeMutablePointer<integer_t>) in
                return task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    machPtr,
                    &bufferSize
                )
            }
        }
        
        guard kernReturn == KERN_SUCCESS else {
            return nil
        }
        
        let resident = Float(info.resident_size) / (1024 * 1024)
        let residentMax = Float(info.resident_size_max) / (1024 * 1024)
        let virtual = Float(info.virtual_size) / (1024 * 1024)
        
        return (resident, residentMax, virtual)
    }

}

extension SystemMonitor {
    
    /**
     System page size.
     
     - Can check this via pagesize shell command as well
     - C lib function getpagesize()
     - host_page_size()
     
     TODO: This should be static right?
     */
    public static let PAGE_SIZE = vm_kernel_page_size
    
    
    //--------------------------------------------------------------------------
    // MARK: PUBLIC ENUMS
    //--------------------------------------------------------------------------
    
    
    /**
     Unit options for method data returns.
     
     TODO: Pages?
     */
    
    
    fileprivate static func memoryUsageMessage() -> String {
        guard let memoryUsage = getMemoryUsage() else {
            return ""
        }
        return "free: \(String(format: "%.2f", memoryUsage.0)) MB, active: \(String(format: "%.2f", memoryUsage.1)) MB, inactive: \(String(format: "%.2f", memoryUsage.2)) MB, wired: \(String(format: "%.2f", memoryUsage.3)) MB, compressed: \(String(format: "%.2f", memoryUsage.4)) MB"
    }

    /**
     64-bit virtual memory statistics. This should apply to all Mac's that run
     10.9 and above. For iOS, iPhone 5S, iPad Air & iPad Mini 2 and on.
     
     Swift runs on 10.9 and above, and 10.9 is x86_64 only. On iOS though its 7
     and above, with both ARM & ARM64.
     */
    private static func getMemoryUsage() -> (free: Double, active: Double, inactive: Double, wired: Double, compressed: Double)? {
        var info = vm_statistics64()
        var bufferSize = UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(bufferSize)) {
                host_statistics64(mach_host_self(), Int32(HOST_VM_INFO64), $0, &bufferSize)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return nil
        }
        
        let free = Double(info.free_count) * Double(PAGE_SIZE) / Unit.Megabyte.rawValue
        let active = Double(info.active_count) * Double(PAGE_SIZE) / Unit.Megabyte.rawValue
        let inactive = Double(info.inactive_count) * Double(PAGE_SIZE) / Unit.Megabyte.rawValue
        let wired = Double(info.wire_count) * Double(PAGE_SIZE) / Unit.Megabyte.rawValue
        let compressed = Double(info.compressor_page_count) * Double(PAGE_SIZE) / Unit.Megabyte.rawValue
        
        return (free, active, inactive, wired, compressed)
    }
    
}
