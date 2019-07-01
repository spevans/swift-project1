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

    let cpuid01: cpuid_result
    let cpuid80000001: cpuid_result
    let cpuid80000008: cpuid_result

    var APICId:      UInt8 { return UInt8(cpuid01.regs.ebx >> 24) }
    var sse3:        Bool { return cpuid01.regs.ecx.bit(0) }
    var pclmulqdq:   Bool { return cpuid01.regs.ecx.bit(1) }
    var dtes64:      Bool { return cpuid01.regs.ecx.bit(2) }
    var monitor:     Bool { return cpuid01.regs.ecx.bit(3) }
    var dscpl:       Bool { return cpuid01.regs.ecx.bit(4) }
    var vmx:         Bool { return cpuid01.regs.ecx.bit(5) }
    var smx:         Bool { return cpuid01.regs.ecx.bit(6) }
    var eist:        Bool { return cpuid01.regs.ecx.bit(7) }
    var tm2:         Bool { return cpuid01.regs.ecx.bit(8) }
    var ssse3:       Bool { return cpuid01.regs.ecx.bit(9) }
    var cnxtid:      Bool { return cpuid01.regs.ecx.bit(10) }
    var sdbg:        Bool { return cpuid01.regs.ecx.bit(11) }
    var fma:         Bool { return cpuid01.regs.ecx.bit(12) }
    var cmpxchg16b:  Bool { return cpuid01.regs.ecx.bit(13) }
    var xptr:        Bool { return cpuid01.regs.ecx.bit(14) }
    var pdcm:        Bool { return cpuid01.regs.ecx.bit(15) }
    var pcid:        Bool { return cpuid01.regs.ecx.bit(17) }
    var dca:         Bool { return cpuid01.regs.ecx.bit(18) }
    var sse4_1:      Bool { return cpuid01.regs.ecx.bit(19) }
    var sse4_2:      Bool { return cpuid01.regs.ecx.bit(20) }
    var x2apic:      Bool { return cpuid01.regs.ecx.bit(21) }
    var movbe:       Bool { return cpuid01.regs.ecx.bit(22) }
    var popcnt:      Bool { return cpuid01.regs.ecx.bit(23) }
    var tscDeadline: Bool { return cpuid01.regs.ecx.bit(24) }
    var aesni:       Bool { return cpuid01.regs.ecx.bit(25) }
    var xsave:       Bool { return cpuid01.regs.ecx.bit(26) }
    var osxsave:     Bool { return cpuid01.regs.ecx.bit(27) }
    var avx:         Bool { return cpuid01.regs.ecx.bit(28) }
    var f16c:        Bool { return cpuid01.regs.ecx.bit(29) }
    var rdrand:      Bool { return cpuid01.regs.ecx.bit(30) }

    var fpu:         Bool { return cpuid01.regs.edx.bit(0) }
    var vme:         Bool { return cpuid01.regs.edx.bit(1) }
    var de:          Bool { return cpuid01.regs.edx.bit(2) }
    var pse:         Bool { return cpuid01.regs.edx.bit(3) }
    var tsc:         Bool { return cpuid01.regs.edx.bit(4) }
    var msr:         Bool { return cpuid01.regs.edx.bit(5) }
    var pae:         Bool { return cpuid01.regs.edx.bit(6) }
    var mce:         Bool { return cpuid01.regs.edx.bit(7) }
    var cx8:         Bool { return cpuid01.regs.edx.bit(8) }
    var apic:        Bool { return cpuid01.regs.edx.bit(9) }
    var sysenter:    Bool { return cpuid01.regs.edx.bit(11) }
    var mtrr:        Bool { return cpuid01.regs.edx.bit(12) }
    var pge:         Bool { return cpuid01.regs.edx.bit(13) }
    var mca:         Bool { return cpuid01.regs.edx.bit(14) }
    var cmov:        Bool { return cpuid01.regs.edx.bit(15) }
    var pat:         Bool { return cpuid01.regs.edx.bit(16) }
    var pse36:       Bool { return cpuid01.regs.edx.bit(17) }
    var psn:         Bool { return cpuid01.regs.edx.bit(18) }
    var clfsh:       Bool { return cpuid01.regs.edx.bit(19) }
    var ds:          Bool { return cpuid01.regs.edx.bit(21) }
    var acpi:        Bool { return cpuid01.regs.edx.bit(22) }
    var mmx:         Bool { return cpuid01.regs.edx.bit(23) }
    var fxsr:        Bool { return cpuid01.regs.edx.bit(24) }
    var sse:         Bool { return cpuid01.regs.edx.bit(25) }
    var sse2:        Bool { return cpuid01.regs.edx.bit(26) }
    var ss:          Bool { return cpuid01.regs.edx.bit(27) }
    var htt:         Bool { return cpuid01.regs.edx.bit(28) }
    var tm:          Bool { return cpuid01.regs.edx.bit(29) }
    var pbe:         Bool { return cpuid01.regs.edx.bit(31) }

    var lahfsahf:    Bool { return cpuid80000001.regs.ecx.bit(0) }
    var lzcnt:       Bool { return cpuid80000001.regs.ecx.bit(5) }
    var prefetchw:   Bool { return cpuid80000001.regs.ecx.bit(8) }

    var syscall:     Bool { return cpuid80000001.regs.edx.bit(11) }
    var nxe:         Bool { return cpuid80000001.regs.edx.bit(20) }

    // FIXME: 1G Pages seem to break using qemu on macos with hypervisor framework.
    // Not sure where bug is atm.
    //var pages1G:     Bool { return cpuid80000001.regs.edx.bit(26) }
    var pages1G: Bool { return false }
    var IA32_EFER:   Bool { return cpuid80000001.regs.edx.bit(29) }

    var maxPhyAddrBits: UInt {
        let max = UInt(cpuid80000008.regs.eax & 0xff)
        if max > 0 {
            return max
        } else {
            return 36
        }
    }

    var description: String {
        var str = String.sprintf("CPU: maxBI: %#x maxEI: %#x\n", maxBasicInput,
            maxExtendedInput)
        str += "CPU: [\(vendorName)] [\(processorBrandString)]\nCPU: "
        if pages1G     { str += "1GPages "     }
        if msr         { str += "msr "         }
        if IA32_EFER   { str += "IA32_EFER "   }
        if nxe         { str += "nxe "         }
        if apic        { str += "apic "        }
        if x2apic      { str += "x2apic "      }
        if rdrand      { str += "rdrand "      }
        if tsc         { str += "tsc "         }
        if tscDeadline { str += "tscDeadline " }
        if sysenter    { str += "sysenter "    }
        if syscall     { str += "syscall "     }
        if mtrr        { str += "mtrr "        }
        if pat         { str += "pat "         }
        if vmx         { str += "vmx "         }
        str += "\nCPU: APIDId: \(APICId)"

        return str
    }


    init() {
        var info = cpuid_result() //eax: 0, ebx: 0, ecx: 0, edx: 0)
        var ptr = UnsafePointer<CChar>(cpuid(0, &info) + 4)
        vendorName = String(cString: ptr)
        maxBasicInput = info.regs.eax

        cpuid(0x80000000, &info)
        maxExtendedInput = info.regs.eax

        if (maxBasicInput >= 1) {
            cpuid(0x1, &info)
            cpuid01 = info
        } else {
            cpuid01 = cpuid_result()
        }

        if (maxExtendedInput >= 0x80000001) {
            cpuid(0x80000001, &info)
            cpuid80000001 = info
        } else {
            cpuid80000001 = cpuid_result()
        }

        // Physical & Virtual address size information
        if (maxExtendedInput >= 0x80000008) {
            cpuid(0x80000008, &info)
            cpuid80000008 = info
        } else {
            cpuid80000008 = cpuid_result()
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

    enum PATEntry: UInt8 {
        case Uncacheable = 0
        case WriteCombining = 1
        case WriteThrough = 4
        case WriteProtected = 5
        case WriteBack = 6
        case Uncached = 7
    }


    struct IA32FeatureControl {
        private var value: BitArray64


        init() {
            value = BitArray64(readMSR(0x3A))
        }


        func update() -> Bool {
            // Check if lock bit is set clear to avoid GP fault
            guard BitArray64(readMSR(0x3A))[0] == 0 else {
                return false
            }
            writeMSR(0x3A, value.toUInt64())
            return true
        }


        var lock: Bool {
            get { Bool(value[0]) }
            set { value[0] = newValue ? 1 : 0 }
        }

        var enableVMXInsideSMX: Bool {
            get { Bool(value[1]) }
            set { value[1] = newValue ? 1 : 0 }
        }

        var enableVMXOutsideSMX: Bool {
            get { Bool(value[2]) }
            set { value[2] = newValue ? 1 : 0 }
        }

        var senterLocalFunctionsEnable: UInt16 {
            get { UInt16(value[8...14]) }
            set { value[8...14] = UInt64(newValue) }
        }

        var senterGlobalFunctionsEnable: Bool {
            get { Bool(value[15]) }
            set { value[15] = newValue ? 1 : 0 }
        }

        var sgxGlobalFunctionsEnable: Bool {
            get { Bool(value[18]) }
            set { value[18] = newValue ? 1 : 0 }
        }

        var lmceOn: Bool {
            get { Bool(value[20]) }
            set { value[20] = newValue ? 1 : 0 }
        }
    }


    static func getInfo() {
        print(cpuId)
    }


    static var capabilities: CPUID {
        return cpuId
    }


    static func enableWP(_ enable: Bool) {
        var cr0 = CPU.cr0
        cr0.wp = enable
        CPU.cr0 = cr0
    }


    static func enableNXE(_ enable: Bool) -> Bool {
        if cpuId.nxe && cpuId.msr && cpuId.IA32_EFER {
            var (eax, edx) = readMSR(0xC0000080)
            eax |= 1 << 11
            writeMSR(0xC0000080, eax, edx)
            print("CPU: NXE enabled")
            return true
        }
        print("CPU: NXE cant be enabled")
        return false
    }


    // Setup the Page Attribute Table
    static func setupPAT() {

        guard cpuId.pat else {
            koops("CPU doesnt support PAT")
        }
        // Update PAT to add a WriteCombining and WriteProtected entry
        var pats = ByteArray8(readMSR(0x277)).map { PATEntry(rawValue: $0)! }
        pats[2] = PATEntry.WriteCombining
        pats[3] = PATEntry.WriteProtected

        // New PAT
        // 0: WriteBack
        // 1: WriteThrough
        // 2: WriteCombining
        // 3: WriteProtected
        // 4: WriteBack
        // 5: WriteThrough
        // 6: Uncached
        // 7: Uncacheable

        writeMSR(0x277, UInt64(withBytes: pats.map { $0.rawValue }))
        let newPat = ByteArray8(readMSR(0x277)).map { PATEntry(rawValue: $0)! }
        print("CPU: Page Attribute Table:")
        for (idx, entry) in newPat.enumerated() {
            print("CPU: \(idx): \(entry)")
        }
    }

    static func readMSR(_ msr: UInt32) -> (UInt32, UInt32) {
        let result = rdmsr(msr)
        return (result.eax, result.edx)
    }

    static func readMSR(_ msr: UInt32) -> UInt64 {
        let result = rdmsr(msr)
        return UInt64(withDWords: result.eax, result.edx)
    }

    static func writeMSR(_ msr: UInt32, _ eax: UInt32, _ edx: UInt32) {
        wrmsr(msr, eax, edx)
    }

    static func writeMSR(_ msr: UInt32, _ value: UInt64) {
        let v = DWordArray2(value)
        wrmsr(msr, v[0], v[1])
    }


    struct CR0Register {
        private(set) var bits: BitArray64
        var value: UInt64 { bits.toUInt64() }

        var ne: Bool {
            get { Bool(bits[5]) }
            set { bits[5] = newValue ? 1 : 0 }
        }

        var wp: Bool {
            get { Bool(bits[16]) }
            set { bits[16] = newValue ? 1 : 0 }
        }

        init(_ value: UInt64) {
            bits = BitArray64(value)
        }

        init() {
            bits = BitArray64(getCR0())
        }
    }


    struct CR4Register {
        private(set) var bits: BitArray64
        var value: UInt64 { bits.toUInt64() }

        var vmxe: Bool {
            get { Bool(bits[13]) }
            set { bits[13] = newValue ? 1 : 0 }
        }

        init(_ value: UInt64) {
            bits = BitArray64(value)
        }

        init() {
            bits = BitArray64(getCR4())
        }
    }


    static var cr0: CR0Register {
        get { CR0Register() }
        set { setCR0(newValue.value) }
    }


    static var cr4: CR4Register {
        get { CR4Register() }
        set { setCR4(newValue.value) }
    }

}


struct VMXFixedBits {
    let cr0Fixed0Bits: UInt64 = CPU.readMSR(0x486)
    let cr0Fixed1Bits: UInt64 = CPU.readMSR(0x487)
    let cr4Fixed0Bits: UInt64 = CPU.readMSR(0x488)
    let cr4Fixed1Bits: UInt64 = CPU.readMSR(0x489)


    func updateCR0(bits: CPU.CR0Register) -> CPU.CR0Register {
        var result = bits.value | cr0Fixed0Bits
        result &= cr0Fixed1Bits
        return CPU.CR0Register(result)
    }

    func updateCR4(bits: CPU.CR4Register) -> CPU.CR4Register {
        var result = bits.value | cr4Fixed0Bits
        result &= cr4Fixed1Bits
        return CPU.CR4Register(result)
    }
}


struct VMXBasicInfo: CustomStringConvertible {

    private let bits: BitArray64

    let recommendedMemoryType: CPU.PATEntry

    var vmcsRevisionId: UInt32 { UInt32(bits[0...30]) }
    var vmxRegionSize: Int { Int(bits[32...44]) }
    var physAddressWidthMaxBits: UInt {
        Bool(bits[48]) ? 32 : cpuId.maxPhyAddrBits
    }
    var supportsDualMonitorOfSMM: Bool { Bool(bits[48]) }
    var vmExitsDueToInOut: Bool { Bool(bits[54]) }
    var vmxControlsCanBeCleared: Bool { Bool(bits[55]) }

    var description: String {
        var str = "VMX: Basic Info: revision ID: \(vmcsRevisionId) \(String(vmcsRevisionId, radix: 16))\n"
        str += "VMX: region size: \(vmxRegionSize) bytes "
        str += "max address bits: \(physAddressWidthMaxBits)\n"
        str += "VMX: supportsDualMonitor: \(supportsDualMonitorOfSMM) "
        str += "recommendedMemoryType: \(recommendedMemoryType) "
        return str
    }

    init() {
        bits = BitArray64(CPU.readMSR(0x480))
        guard bits[31] == 0 else {
            fatalError("Bit31 of IA32_VMX_BASIC is not 0")
        }

        let memTypeVal = UInt8(bits[50...53])
        guard let memoryType = CPU.PATEntry(rawValue: memTypeVal) else {
            fatalError("Invalid memoryType: \(memTypeVal)")
        }
        recommendedMemoryType = memoryType

        guard vmxRegionSize > 0 && vmxRegionSize <= 4096 else {
            fatalError("vmxRegionSize: \(vmxRegionSize) should be 1-4096")
        }
    }
}
