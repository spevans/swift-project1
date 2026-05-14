/*
 * kernel/arch/x86_64/cpu/cpuid.swift
 *
 * Created by Simon Evans on 19/04/2026.
 * Copyright © 2026 Simon Evans. All rights reserved.
 *
 */


struct CPUID {
    private(set) var maxBasicInput: UInt32 = 0
    private(set) var maxExtendedInput: UInt32 = 0
    private(set) var cpuid01 = cpuid_result()
    private(set) var cpuid80000001 = cpuid_result()
    private(set) var cpuid80000008 = cpuid_result()


    init() {
    }

    var vendorName: String {
        var info = cpuid_result() //eax: 0, ebx: 0, ecx: 0, edx: 0)
        let ptr = UnsafePointer<CChar>(cpuid(0, &info) + 4)
        return String(cString: ptr)
    }

    var processorBrandString: String {
        if (self.maxExtendedInput >= 0x80000004) {
            var info = cpuid_result()
            var ptr = UnsafePointer<CChar>(cpuid(0x80000002, &info))
            var brand = String(cString: ptr)
            ptr = UnsafePointer<CChar>(cpuid(0x80000003, &info))
            brand += String(cString: ptr)
            ptr = UnsafePointer<CChar>(cpuid(0x80000004, &info))
            brand += String(cString: ptr)
            return brand
        } else {
            return ""
        }
    }

    mutating func initialise() {
        var info = cpuid_result() //eax: 0, ebx: 0, ecx: 0, edx: 0)
        var ptr = UnsafePointer<CChar>(cpuid(0, &info) + 4)
        self.maxBasicInput = info.regs.eax

        cpuid(0x80000000, &info)
        self.maxExtendedInput = info.regs.eax

        if (self.maxBasicInput >= 1) {
            cpuid(0x1, &info)
            self.cpuid01 = info
        } else {
            self.cpuid01 = cpuid_result()
        }

        if (self.maxExtendedInput >= 0x80000001) {
            cpuid(0x80000001, &info)
            self.cpuid80000001 = info
        } else {
            self.cpuid80000001 = cpuid_result()
        }

        // Physical & Virtual address size information
        if (self.maxExtendedInput >= 0x80000008) {
            cpuid(0x80000008, &info)
            self.cpuid80000008 = info
        } else {
            self.cpuid80000008 = cpuid_result()
        }
        #if false
        if (self.maxExtendedInput >= 0x80000004) {
            ptr = UnsafePointer<CChar>(cpuid(0x80000002, &info))
            var brand = String(cString: ptr)
            ptr = UnsafePointer<CChar>(cpuid(0x80000003, &info))
            brand += String(cString: ptr)
            ptr = UnsafePointer<CChar>(cpuid(0x80000004, &info))
            brand += String(cString: ptr)
            self.processorBrandString = brand
        } else {
            self.processorBrandString = ""
        }
        #endif
    }

    func cpuidLeaf(_ leaf: UInt32) -> cpuid_result? {
        guard self.maxBasicInput >= leaf else {
            return nil
        }
        var info = cpuid_result()
        cpuid(leaf, &info)
        return info
    }

    func cpuidExtended(for leaf: UInt32) -> cpuid_result? {
        guard self.maxExtendedInput >= leaf else {
            return nil
        }
        var info = cpuid_result()
        cpuid(leaf, &info)
        return info
    }
}
