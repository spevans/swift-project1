/*
 * kernel/devices/cpu.swift
 *
 * Created by Simon Evans on 21/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * CPU feature detection and control
 *
 */


class CPU {
    static var maxBasicInput :UInt32 = 0
    static var maxExtendedInput: UInt32 = 0
    static var vendorName = ""
    static var processorBrandString = ""
    static var hasMSR = false
    static var IA32_EFER = false
    static var pages1G = false
    static var nxe = false


    static func getInfo() {
        var info = cpuid_result() //eax: 0, ebx: 0, ecx: 0, edx: 0)
        var ptr = UnsafePointer<CChar>(cpuid(0, &info) + 4)
        vendorName = String.fromCString(ptr)!
        maxBasicInput = info.u.regs.eax

        cpuid(0x80000000, &info)
        maxExtendedInput = info.u.regs.eax

        if (maxBasicInput >= 1) {
            cpuid(0x1, &info)
            let edx = info.u.regs.edx
            hasMSR = testBit(edx, 5)
        }


        if (maxExtendedInput >= 0x80000001) {
            cpuid(0x80000001, &info)
            let edx = info.u.regs.edx
            pages1G = testBit(edx, 26)
            nxe = testBit(edx, 20)
            IA32_EFER = testBit(edx, 29)
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


    private static func testBit(v: UInt32, _ bit: Int) -> Bool {
        if (v & UInt32(1 << bit)) != 0 {
            return true
        } else {
            return false
        }
    }


    static func enableWP(enable: Bool) {
        let WPbit: UInt64 = 1 << 16

        var cr0 = getCR0()
        if enable {
            cr0 |= WPbit
        } else {
            cr0 &= ~WPbit
        }
        setCR0(cr0)
    }


    static func enableNXE(enable: Bool) -> Bool {
        if nxe && hasMSR && IA32_EFER {
            var (eax, edx) = readMSR(0xC0000080)
            eax |= 1 << 11
            writeMSR(0xC0000080, eax, edx)
            return true
        }
        return false
    }


    static func readMSR(msr: UInt32) -> (UInt32, UInt32) {
        let result = rdmsr(msr)
        return (result.eax, result.edx)
    }

    static func writeMSR(msr: UInt32, _ eax: UInt32, _ edx: UInt32) {
        wrmsr(msr, eax, edx)
    }


    static var description: String {
        var str = String.sprintf("maxBasicInput: %#x maxExtendedInput: %#x\n[\(vendorName)] [\(processorBrandString)]\n",
            maxBasicInput, maxExtendedInput);
        str += String.sprintf("1GPages = \(pages1G) hasMSR = \(hasMSR) IA32_EFER = \(IA32_EFER) nxe = \(nxe)")
        return str
    }
}
