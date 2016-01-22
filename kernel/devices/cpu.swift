/*
 * kernel/devices/cpu.swift
 *
 * Created by Simon Evans on 21/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * CPU feature detection and control
 *
 */


public class CPU {
    static var maxBasicInput :UInt32 = 0
    static var maxExtendedInput: UInt32 = 0
    static var vendorName = ""
    static var processorBrandString = ""
    static var pages1G = false


    static func getInfo() {
        var info = cpuid_result() //eax: 0, ebx: 0, ecx: 0, edx: 0)
        var ptr = UnsafePointer<CChar>(cpuid(0, &info) + 4)
        vendorName = String.fromCString(ptr)!
        maxBasicInput = info.u.regs.eax

        cpuid(0x80000000, &info)
        maxExtendedInput = info.u.regs.eax

        if (maxExtendedInput >= 0x80000001) {
            cpuid(0x80000001, &info)
            let edx = info.u.regs.edx
            if (edx & 0b100000000000000000000000000) != 0 {
                pages1G = true
            }
        }

        if (maxExtendedInput >= 0x80000004) {
            ptr = UnsafePointer<CChar>(cpuid(0x80000002, &info))
            processorBrandString = String.fromCString(ptr)!
            ptr = UnsafePointer<CChar>(cpuid(0x80000003, &info))
            processorBrandString += String.fromCString(ptr)!
            ptr = UnsafePointer<CChar>(cpuid(0x80000004, &info))
            processorBrandString += String.fromCString(ptr)!
        }

    }


    static func description() {
        getInfo()
        printf("maxBasicInput: %#x maxExtendedInput: %#x\n[\(vendorName)] [\(processorBrandString)]\n",
            maxBasicInput, maxExtendedInput);
        print("1GPages = \(pages1G)")
    }
}
