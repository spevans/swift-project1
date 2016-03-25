/*
 * kernel/devices/cpu.swift
 *
 * Created by Simon Evans on 21/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * CPU feature detection and control
 *
 */


struct CPUID: CustomStringConvertible {
    let maxBasicInput: UInt32
    let maxExtendedInput: UInt32
    let vendorName: String
    let processorBrandString: String
    let hasMSR: Bool
    let IA32_EFER: Bool
    let pages1G: Bool
    let nxe: Bool

    var description: String {
        var str = String.sprintf("CPU: maxBI: %#x maxEI: %#x\n", maxBasicInput, maxExtendedInput)
        str += "CPU: [\(vendorName)] [\(processorBrandString)]\n"
        str += "CPU: "
        str += pages1G ? "1GPages " : ""
        str += hasMSR ? "msr " : ""
        str += IA32_EFER ? "IA32_EFER " : ""
        str += nxe ? "nxe " : ""

        return str
    }


    init() {
        func testBit(v: UInt32, _ bit: Int) -> Bool {
            if (v & UInt32(1 << bit)) != 0 {
                return true
            } else {
                return false
            }
        }

        var info = cpuid_result() //eax: 0, ebx: 0, ecx: 0, edx: 0)
        var ptr = UnsafePointer<CChar>(cpuid(0, &info) + 4)
        vendorName = String(cString: ptr)
        maxBasicInput = info.u.regs.eax

        cpuid(0x80000000, &info)
        maxExtendedInput = info.u.regs.eax

        if (maxBasicInput >= 1) {
            cpuid(0x1, &info)
            let edx = info.u.regs.edx
            hasMSR = testBit(edx, 5)
        } else {
            hasMSR = false
        }

        if (maxExtendedInput >= 0x80000001) {
            cpuid(0x80000001, &info)
            let edx = info.u.regs.edx
            pages1G = testBit(edx, 26)
            nxe = testBit(edx, 20)
            IA32_EFER = testBit(edx, 29)
        } else {
            pages1G = false
            nxe = false
            IA32_EFER = false
        }

        if (maxExtendedInput >= 0x80000004) {
            ptr = UnsafePointer<CChar>(cpuid(0x80000002, &info))
            var brand = String(cString: ptr)
            ptr = UnsafePointer<CChar>(cpuid(0x80000003, &info))
            brand += String(cString: ptr)
            ptr = UnsafePointer<CChar>(cpuid(0x80000004, &info))
            brand += String(cString: ptr)
            processorBrandString = brand
        } else {
            processorBrandString = ""
        }
    }
}


// Singleton that will be initialised by CPU.getInfo() or CPU.capabilities
private let cpuId = CPUID()


struct CPU {

    static func getInfo() {
        print(cpuId)
    }


    static var capabilities: CPUID {
        return cpuId
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
        if cpuId.nxe && cpuId.hasMSR && cpuId.IA32_EFER {
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
}
