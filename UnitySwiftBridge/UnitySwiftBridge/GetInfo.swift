//
//  GetInfo.swift
//  GetInfo
//
//  Created by Dharmik Gorsiya on 17/06/24.
//

import Foundation
import UIKit
import Metal

// Host Info Constants
//private let HOST_BASIC_INFO_COUNT         : mach_msg_type_number_t =
//UInt32(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
private let HOST_LOAD_INFO_COUNT          : mach_msg_type_number_t =
UInt32(MemoryLayout<host_load_info_data_t>.size / MemoryLayout<integer_t>.size)
private let HOST_CPU_LOAD_INFO_COUNT      : mach_msg_type_number_t =
UInt32(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
private let HOST_VM_INFO64_COUNT          : mach_msg_type_number_t =
UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
//private let HOST_SCHED_INFO_COUNT         : mach_msg_type_number_t =
//UInt32(MemoryLayout<host_sched_info_data_t>.size / MemoryLayout<integer_t>.size)
//private let PROCESSOR_SET_LOAD_INFO_COUNT : mach_msg_type_number_t =
//UInt32(MemoryLayout<processor_set_load_info_data_t>.size / MemoryLayout<natural_t>.size)

public class GetInfo
{
    public static let instance = GetInfo()
    private var framesRendered = 0
    let machHost = mach_host_self()
    var loadPrevious = host_cpu_load_info()
    let mtlDevice: MTLDevice? = MTLCreateSystemDefaultDevice()
    let PAGE_SIZE = vm_kernel_page_size
    var timer: Timer?
    
    var trackedDataListX: [TrackedData] = []
    
    func startTracking() {
        print("Start Tracking swift")
        trackedDataListX = []
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(doTracking), userInfo: nil, repeats: true)
    }
    
    @objc func doTracking() {
        let cpuUsage = cpuUsage()
        let gpuUsage = gpuUsage()
        let ramUsage = ramUsage()
        
        var cpuUsage1 = CPUUsage(system: cpuUsage.system, user: cpuUsage.user, idle: cpuUsage.idle, nice: cpuUsage.nice)
        
        var gpuUsage1 = GPUUsage(max: Double(gpuUsage.max), allocated: Double(gpuUsage.curr));
        
        var ramUsage1 = RAMUsage(free: ramUsage.free, active: ramUsage.active, inactive: ramUsage.inactive, wired: ramUsage.wired, compressed: ramUsage.compressed)
        
        addTrackedDataX(to: &trackedDataListX, cpuUsage: cpuUsage1, gpuUsage: gpuUsage1, ramUsage: ramUsage1)
       // addTrackedData(trackedData: trackedData)
    }
    
    func stopTracking() -> String {
        
        print("Stop Tracking swift")
        self.timer?.invalidate()
        self.timer = nil
        return convertTrackedDataListToJsonString(trackedDataListX) ?? ""
    }
    
    // Function to convert the entire list of TrackedData to JSON and return as a single string
    func convertTrackedDataListToJsonString(_ list: [TrackedData]) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let jsonData = try encoder.encode(list)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Error encoding TrackedData list to JSON: \(error)")
            return nil
        }
    }
    
    func hostCPULoadInfo() -> host_cpu_load_info {
        var size     = HOST_CPU_LOAD_INFO_COUNT
        let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
        _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics(machHost, HOST_CPU_LOAD_INFO,
                            $0,
                            &size)
        }
        let data = hostInfo.move()
        hostInfo.deallocate()
        return data
    }
    
    func VMStatistics64() -> vm_statistics64 {
        var size     = HOST_VM_INFO64_COUNT
        let hostInfo = vm_statistics64_t.allocate(capacity: 1)
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics64(machHost,
                              HOST_VM_INFO64,
                              $0,
                              &size)
        }
        let data = hostInfo.move()
        hostInfo.deallocate()
        return data
    }
    
    // Get CPU usage by host_cpu_load_info_t
    private func cpuUsage() -> (
        system: Double,
        user: Double,
        idle: Double,
        nice: Double) {
            let load = hostCPULoadInfo()
            
            let userDiff = Double(load.cpu_ticks.0 - loadPrevious.cpu_ticks.0)
            let sysDiff  = Double(load.cpu_ticks.1 - loadPrevious.cpu_ticks.1)
            let idleDiff = Double(load.cpu_ticks.2 - loadPrevious.cpu_ticks.2)
            let niceDiff = Double(load.cpu_ticks.3 - loadPrevious.cpu_ticks.3)
            
            let totalTicks = sysDiff + userDiff + niceDiff + idleDiff
            
            let sys  = sysDiff  / totalTicks * 100.0
            let user = userDiff / totalTicks * 100.0
            let idle = idleDiff / totalTicks * 100.0
            let nice = niceDiff / totalTicks * 100.0
            
            loadPrevious = load
            
            return (sys, user, idle, nice)
        }
    
    // Get RAM usage
    private func ramUsage() -> (
        free: Double,
        active: Double,
        inactive: Double,
        wired: Double,
        compressed: Double) {
            let stats = VMStatistics64()
            
            let free     = Utils.convertByte(
                value: Double(stats.free_count) * Double(PAGE_SIZE),
                target: Utils.UnitType.GB)
            let active   = Utils.convertByte(
                value: Double(stats.active_count) * Double(PAGE_SIZE),
                target: Utils.UnitType.GB)
            let inactive = Utils.convertByte(
                value: Double(stats.inactive_count) * Double(PAGE_SIZE),
                target: Utils.UnitType.GB)
            let wired    = Utils.convertByte(
                value: Double(stats.wire_count) * Double(PAGE_SIZE),
                target: Utils.UnitType.GB)
            
            // Result of the compression. This is what you see in Activity Monitor
            let compressed = Utils.convertByte(
                value: Double(stats.compressor_page_count) * Double(PAGE_SIZE),
                target: Utils.UnitType.GB)
            
            return (free, active, inactive, wired, compressed)
        }
    
    // Get the GPU usage by Metal API
    private func gpuUsage() -> (max: UInt64, curr: Int) {
        let maxGPUMem = mtlDevice?.recommendedMaxWorkingSetSize
        let currAllocatedGPUMem = mtlDevice?.currentAllocatedSize
        return (Utils.convertByte(value: maxGPUMem!, target: Utils.UnitType.MB), Utils.convertByte(value: currAllocatedGPUMem!, target: Utils.UnitType.MB))
    }
    
    func addTrackedDataX(to list: inout [TrackedData], cpuUsage: CPUUsage, gpuUsage: GPUUsage, ramUsage: RAMUsage) {
        let newTrackedData = TrackedData(cpuUsage: cpuUsage, gpuUsage: gpuUsage, ramUsage: ramUsage, timestamp: generateCurrentTimeStamp())
        list.append(newTrackedData)
    }
    func generateCurrentTimeStamp () -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd_hh_mm_ss"
        return (formatter.string(from: Date()) as NSString) as String
    }
}
struct CPUUsage : Codable {
    var system: Double
    var user: Double
    var idle: Double
    var nice: Double
}

struct GPUUsage : Codable {
    var max: Double
    var allocated: Double
}

struct RAMUsage : Codable {
    var free: Double
    var active: Double
    var inactive: Double
    var wired: Double
    var compressed: Double
}

struct TrackedData : Codable {
    var cpuUsage: CPUUsage
    var gpuUsage: GPUUsage
    var ramUsage: RAMUsage
    var timestamp: String
    init(cpuUsage: CPUUsage, gpuUsage: GPUUsage, ramUsage: RAMUsage, timestamp : String ) {
        self.cpuUsage = cpuUsage
        self.gpuUsage = gpuUsage
        self.ramUsage = ramUsage
        self.timestamp=timestamp
    }
    
   
}

@_cdecl("startTracking")
public func startTracking() -> Void {
    GetInfo.instance.startTracking()
}

@_cdecl("stopTracking")
public func stopTracking() -> UnsafeMutablePointer<CChar> {
    return Utils.convertStringToCSString(text: GetInfo.instance.stopTracking())
}

