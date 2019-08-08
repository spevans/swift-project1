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

    var pageSizes: [UInt]

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
        pageSizes = [ 4096, 2 * mb ]
        if pages1G {
            pageSizes.append(1 * gb)
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
        cr0.writeProtect = enable
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


    struct CR0Register: CustomStringConvertible {
        private(set) var bits: BitArray64
        var value: UInt64 { bits.toUInt64() }

        init(_ value: UInt64) {
            bits = BitArray64(value)
        }

        init() {
            bits = BitArray64(getCR0())
        }

        var protectionEnable: Bool {
            get { Bool(bits[0]) }
            set { bits[0] = newValue ? 1 : 0 }
        }

        var monitorCoprocessor: Bool {
            get { Bool(bits[1]) }
            set { bits[1] = newValue ? 1 : 0 }
        }

        var fpuEmulation: Bool {
            get { Bool(bits[2]) }
            set { bits[2] = newValue ? 1 : 0 }
        }

        var taskSwitched: Bool {
            get { Bool(bits[3]) }
            set { bits[3] = newValue ? 1 : 0 }
        }

        var extensionType: Bool {
            get { Bool(bits[4]) }
            set { bits[4] = newValue ? 1 : 0 }
        }

        var numericError: Bool {
            get { Bool(bits[5]) }
            set { bits[5] = newValue ? 1 : 0 }
        }

        var writeProtect: Bool {
            get { Bool(bits[16]) }
            set { bits[16] = newValue ? 1 : 0 }
        }

        var alignmentMask: Bool {
            get { Bool(bits[18]) }
            set { bits[18] = newValue ? 1 : 0 }
        }

        var notWriteThrough: Bool {
            get { Bool(bits[29]) }
            set { bits[29] = newValue ? 1 : 0 }
        }

        var cacheDisable: Bool {
            get { Bool(bits[30]) }
            set { bits[30] = newValue ? 1 : 0 }
        }

        var paging: Bool {
            get { Bool(bits[31]) }
            set { bits[31] = newValue ? 1 : 0 }
        }

        var description: String {
            var result = "PE: " + (protectionEnable ? "1" : "0")
            result += " MC: " + (monitorCoprocessor ? "1" : "0")
            result += " FE: " + (fpuEmulation ? "1" : "0")
            result += " TS: " + (taskSwitched ? "1" : "0")
            result += " ET: " + (extensionType ? "1" : "0")
            result += " NE: " + (numericError ? "1" : "0")
            result += " WP: " + (writeProtect ? "1" : "0")
            result += " AM: " + (alignmentMask ? "1" : "0")
            result += " WT: " + (notWriteThrough ? "1" : "0")
            result += " CD: " + (cacheDisable ? "1" : "0")
            result += " PG: " + (paging ? "1" : "0")

            return result
        }
    }


    struct CR3Register {
        private(set) var bits: BitArray64
        var value: UInt64 { bits.toUInt64() }

        init(_ value: UInt64) {
            bits = BitArray64(value)
        }

        init() {
            bits = BitArray64(getCR3())
        }

        var pagelevelWriteThrough: Bool {
            get { Bool(bits[3]) }
            set { bits[3] = newValue ? 1 : 0 }
        }

        var pagelevelCacheDisable: Bool {
            get { Bool(bits[4]) }
            set { bits[4] = newValue ? 1 : 0 }
        }

        var pageDirectoryBase: PhysAddress {
            get { PhysAddress(UInt(value) & ~PAGE_MASK) }
            set {
                precondition(newValue.isPageAligned)
                bits[12...63] = 0  // clear current address
                bits = BitArray64(UInt64(newValue.value) | value)
            }
        }
    }


    struct CR4Register: CustomStringConvertible {
        private(set) var bits: BitArray64
        var value: UInt64 { bits.toUInt64() }

        init(_ value: UInt64) {
            bits = BitArray64(value)
        }

        init() {
            bits = BitArray64(getCR4())
        }

        var vme: Bool {
            get { Bool(bits[0]) }
            set { bits[0] = newValue ? 1 : 0 }
        }

        var pvi: Bool {
            get { Bool(bits[1]) }
            set { bits[1] = newValue ? 1 : 0 }
        }

        var tsd: Bool {
            get { Bool(bits[2]) }
            set { bits[2] = newValue ? 1 : 0 }
        }

        var de: Bool {
            get { Bool(bits[3]) }
            set { bits[3] = newValue ? 1 : 0 }
        }

        var pse: Bool {
            get { Bool(bits[4]) }
            set { bits[4] = newValue ? 1 : 0 }
        }

        var pae: Bool {
            get { Bool(bits[5]) }
            set { bits[5] = newValue ? 1 : 0 }
        }

        var mce: Bool {
            get { Bool(bits[6]) }
            set { bits[6] = newValue ? 1 : 0 }
        }

        var pge: Bool {
            get { Bool(bits[7]) }
            set { bits[7] = newValue ? 1 : 0 }
        }

        var pce: Bool {
            get { Bool(bits[8]) }
            set { bits[8] = newValue ? 1 : 0 }
        }

        var osfxsr: Bool {
            get { Bool(bits[9]) }
            set { bits[9] = newValue ? 1 : 0 }
        }

        var osxmmxcpt: Bool {
            get { Bool(bits[10]) }
            set { bits[10] = newValue ? 1 : 0 }
        }

        var umip: Bool {
            get { Bool(bits[11]) }
            set { bits[11] = newValue ? 1 : 0 }
        }

        var vmxe: Bool {
            get { Bool(bits[13]) }
            set { bits[13] = newValue ? 1 : 0 }
        }

        var smxe: Bool {
            get { Bool(bits[14]) }
            set { bits[14] = newValue ? 1 : 0 }
        }

        var fsgsbase: Bool {
            get { Bool(bits[16]) }
            set { bits[16] = newValue ? 1 : 0 }
        }

        var pcide: Bool {
            get { Bool(bits[17]) }
            set { bits[17] = newValue ? 1 : 0 }
        }

        var osxsave: Bool {
            get { Bool(bits[18]) }
            set { bits[18] = newValue ? 1 : 0 }
        }

        var smep: Bool {
            get { Bool(bits[20]) }
            set { bits[20] = newValue ? 1 : 0 }
        }

        var smap: Bool {
            get { Bool(bits[21]) }
            set { bits[21] = newValue ? 1 : 0 }
        }

        var pke: Bool {
            get { Bool(bits[22]) }
            set { bits[22] = newValue ? 1 : 0 }
        }

        var description: String {
            var result = "VME: " + (vme ? "1" : "0")
            result += " PVI: " + (pvi ? "1" : "0")
            result += " TSD: " + (tsd ? "1" : "0")
            result += " DE: " + (tsd ? "1" : "0")
            result += " PSE: " + (pse ? "1" : "0")
            result += " PAE: " + (pae ? "1" : "0")
            result += " MCE: " + (mce ? "1" : "0")
            result += " PGE: " + (pge ? "1" : "0")
            result += " PCE: " + (pce ? "1" : "0")
            result += " OSFXSR: " + (osfxsr ? "1" : "0")
            result += " OSXMMXCPT: " + (osxmmxcpt ? "1" : "0")
            result += " UMIP: " + (umip ? "1" : "0")
            result += " VMXE: " + (vmxe ? "1" : "0")
            result += " SMXE: " + (smxe ? "1" : "0")
            result += " FSGSBASE: " + (fsgsbase ? "1" : "0")
            result += " PCIDE: " + (pcide ? "1" : "0")
            result += " OSXSAVE: " + (osxsave ? "1" : "0")
            result += " SMEP: " + (smep ? "1" : "0")
            result += " SMAP: " + (smap ? "1" : "0")
            result += " PKE: " + (pke ? "1" : "0")

            return result
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


struct VMXPinBasedControls {
    let low: UInt32
    let high: UInt32

    init() {
        (low, high) = CPU.readMSR(0x481)
    }

    var defaultValue: UInt32 {
        var result: UInt32 = 0
        result &= high  // bits 32:63 contains allowed 1-settings. If bit is 0 it must be cleared
        result |= low   // bits 0:31 contains allowed 0-settings. If bit is 1 it must be set
        return result
    }
}


struct VMXPrimaryProcessorBasedControls {
    let bits: BitArray64

    init() {
        bits = BitArray64(CPU.readMSR(0x482))
    }

    var defaultValue: UInt32 {
        let a = DWordArray2(bits.toUInt64())
        let low = a[0]
        let high = a[1]

        var result: UInt32 = 0
        result &= high  // bits 32:63 contains allowed 1-settings. If bit is 0 it must be cleared
        result |= low   // bits 0:31 contains allowed 0-settings. If bit is 1 it must be set
        return result
    }

    var intWindowExiting:           VMXAllowedBits { VMXAllowedBits(bits, 2)  }
    var useTSCOffsetting:           VMXAllowedBits { VMXAllowedBits(bits, 3)  }
    var hltExiting:                 VMXAllowedBits { VMXAllowedBits(bits, 7)  }
    var invlpgExiting:              VMXAllowedBits { VMXAllowedBits(bits, 9)  }
    var mwaitExiting:               VMXAllowedBits { VMXAllowedBits(bits, 10) }
    var rdpmcExiting:               VMXAllowedBits { VMXAllowedBits(bits, 11) }
    var rdtscExiting:               VMXAllowedBits { VMXAllowedBits(bits, 12) }
    var cr3LoadExiting:             VMXAllowedBits { VMXAllowedBits(bits, 15) }
    var cr3StoreExiting:            VMXAllowedBits { VMXAllowedBits(bits, 16) }
    var cr8LoadExiting:             VMXAllowedBits { VMXAllowedBits(bits, 19) }
    var cr8StoreExiting:            VMXAllowedBits { VMXAllowedBits(bits, 20) }
    var useTPRShadow:               VMXAllowedBits { VMXAllowedBits(bits, 21) }
    var nmiWindowExiting:           VMXAllowedBits { VMXAllowedBits(bits, 22) }
    var movDRExiting:               VMXAllowedBits { VMXAllowedBits(bits, 23) }
    var unconditionalIOExiting:     VMXAllowedBits { VMXAllowedBits(bits, 24) }
    var useIOBitmaps:               VMXAllowedBits { VMXAllowedBits(bits, 25) }
    var monitorTrapFlag:            VMXAllowedBits { VMXAllowedBits(bits, 27) }
    var useMSRbitmaps:              VMXAllowedBits { VMXAllowedBits(bits, 28) }
    var monitorExiting:             VMXAllowedBits { VMXAllowedBits(bits, 29) }
    var pauseExiting:               VMXAllowedBits { VMXAllowedBits(bits, 30) }
    var activateSecondaryControls:  VMXAllowedBits { VMXAllowedBits(bits, 31) }
}

struct VMXExitControls {
    let low: UInt32
    let high: UInt32

    init() {
        (low, high) = CPU.readMSR(0x483)
    }

    var defaultValue: UInt32 {
        var result: UInt32 = 0
        result &= high  // bits 32:63 contains allowed 1-settings. If bit is 0 it must be cleared
        result |= low   // bits 0:31 contains allowed 0-settings. If bit is 1 it must be set
        return result
    }
}



struct VMXEntryControls {
    let low: UInt32
    let high: UInt32

    init() {
        (low, high) = CPU.readMSR(0x484)
    }

    var defaultValue: UInt32 {
        var result: UInt32 = 0
        result &= high  // bits 32:63 contains allowed 1-settings. If bit is 0 it must be cleared
        result |= low   // bits 0:31 contains allowed 0-settings. If bit is 1 it must be set
        return result
    }
}


struct VMXMiscInfo: CustomStringConvertible {
    private let bits: BitArray64

    init() {
        bits = BitArray64(CPU.readMSR(0x485))
    }

    var description: String {
        var result = "value: " + String(bits.toUInt64(), radix: 16)
        result += " timerRatio: \(self.timerRatio)"
        result += " storesLMA: \(self.storesLMA)"
        result += " maxCR3TargetValues: \(self.maxCR3TargetValues)"
        result += " maxMSRinLoadList: \(self.maxMSRinLoadList)"
        return result
    }

    var timerRatio: Int { Int(bits[0...4]) }
    var storesLMA: Bool { Bool(bits[5]) }
    var supportsActivityStateHLT: Bool { Bool(bits[6]) }
    var supportsActivityStateShutdown: Bool { Bool(bits[7]) }
    var supportsActivityStateWaitForSIPI: Bool { Bool(bits[8]) }
    var allowsIPTinVMX: Bool { Bool(bits[14]) }
    var allowsSMBASEReadInSMM: Bool { Bool(bits[15]) }
    var maxCR3TargetValues: Int { Int(bits[16...24]) }
    var maxMSRinLoadList: Int { (Int(bits[25...27]) + 1) * 512 }
    var allowSMIBlocksInVMXOFF: Bool { Bool(bits[28]) }
    var vmwriteCanModifyVMExitFields: Bool { Bool(bits[29]) }
    var allowZeroLengthInstructionInjection: Bool { Bool(bits[30]) }
    var msegRevision: UInt32 { UInt32(bits[32...63]) }
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

    // Unrestricted guest is true when the PG and PE bits in CR0
    // DO NOT need to be set, determined from the CR0 Fixed0 Bits MSR
    var allowsUnrestrictedGuest: Bool {
        let cr0 = CPU.CR0Register(cr0Fixed0Bits)
        return !(cr0.protectionEnable || cr0.paging)
    }
}

struct VMXAllowedBits {
    let allowedToBeZero: Bool
    let allowedToBeOne: Bool

    init(_ bits :BitArray64, _ index: Int) {
        // Note that bits allowed to be zero are set to 0 but these are flipped
        // to enable 'allowedToBeZero == true' if they are zero
        allowedToBeZero = !Bool(bits[index])
        allowedToBeOne = Bool(bits[index + 32])
    }
}

struct VMXVMCSEnumeration {
    let bits: BitArray64

    var highestIndex: Int {
        return Int(bits[1...9])
    }

    var description: String {
        let idx = String(highestIndex, radix: 16)
        return "VMCS Enumeration highest index: \(idx)"
    }

    init() {
        bits = BitArray64(CPU.readMSR(0x48A))
    }
}


struct VMXSecondaryProcessorBasedControls {
    let bits: BitArray64
    let low: UInt32
    let high: UInt32

    init() {
        bits = BitArray64(CPU.readMSR(0x48B))
        (low, high) = CPU.readMSR(0x48B)
    }

    var defaultValue: UInt32 {
        var result: UInt32 = 0
        result &= high  // bits 32:63 contains allowed 1-settings. If bit is 0 it must be cleared
        result |= low   // bits 0:31 contains allowed 0-settings. If bit is 1 it must be set
        return result
    }

    var vitualizeApicAccesses:      VMXAllowedBits { VMXAllowedBits(bits, 0)  }
    var enableEPT:                  VMXAllowedBits { VMXAllowedBits(bits, 1)  }
    var descriptorTableExiting:     VMXAllowedBits { VMXAllowedBits(bits, 2)  }
    var enableRDTSCP:               VMXAllowedBits { VMXAllowedBits(bits, 3)  }
    var virtualizeX2ApicMode:       VMXAllowedBits { VMXAllowedBits(bits, 4)  }
    var enableVPID:                 VMXAllowedBits { VMXAllowedBits(bits, 5)  }
    var wbinvdExiting:              VMXAllowedBits { VMXAllowedBits(bits, 6)  }
    var unrestrictedGuest:          VMXAllowedBits { VMXAllowedBits(bits, 7)  }
    var apicRegisterVirtualization: VMXAllowedBits { VMXAllowedBits(bits, 8)  }
    var virtualInterruptDelivery:   VMXAllowedBits { VMXAllowedBits(bits, 9)  }
    var pauseLoopExiting:           VMXAllowedBits { VMXAllowedBits(bits, 10) }
    var rdrandExiting:              VMXAllowedBits { VMXAllowedBits(bits, 11) }
    var enableInvpcid:              VMXAllowedBits { VMXAllowedBits(bits, 12) }
    var enableVMFunctions:          VMXAllowedBits { VMXAllowedBits(bits, 13) }
    var vmcsShadowing:              VMXAllowedBits { VMXAllowedBits(bits, 14) }
    var enableEnclsExiting:         VMXAllowedBits { VMXAllowedBits(bits, 15) }
    var rdseedExiting:              VMXAllowedBits { VMXAllowedBits(bits, 16) }
    var enablePML:                  VMXAllowedBits { VMXAllowedBits(bits, 17) }
    var eptViolation:               VMXAllowedBits { VMXAllowedBits(bits, 18) }
    var concealVMXFromPT:           VMXAllowedBits { VMXAllowedBits(bits, 19) }
    var enableXSAVES:               VMXAllowedBits { VMXAllowedBits(bits, 20) }
    var modeBasedExecCtrlForEPT:    VMXAllowedBits { VMXAllowedBits(bits, 22) }
    var subpageWritePermsForEPT:    VMXAllowedBits { VMXAllowedBits(bits, 23) }
    var iptUsesGuestPhysAddress:    VMXAllowedBits { VMXAllowedBits(bits, 24) }
    var useTSCScaling:              VMXAllowedBits { VMXAllowedBits(bits, 25) }
    var enableUserWaitAndPause:     VMXAllowedBits { VMXAllowedBits(bits, 26) }
    var enableENCLVExiting:         VMXAllowedBits { VMXAllowedBits(bits, 28) }
}


struct VMX_EPT_VPID_CAP {
    let bits: BitArray64

    var supportsExecOnlyEPT: Bool { Bool(bits[0]) }
    var supportsPageWalk4: Bool { Bool(bits[6]) }
    var allowsEPTUncacheableType: Bool { Bool(bits[8]) }
    var allowsEPTWriteBackType: Bool { Bool(bits[14]) }
    var allowsEPT2mbPages: Bool { Bool(bits[16]) }
    var allowsEPT1gbPages: Bool { Bool(bits[17]) }
    var supportsINVEPT: Bool { Bool(bits[20]) }
    var supportsSingleContextINVEPT: Bool { Bool(bits[25]) }
    var supportsAllContextINVEPT: Bool { Bool(bits[26]) }
    var supportsEPTDirtyAccessedFlags: Bool { Bool(bits[21]) }
    var reportsVMExitInfoForEPTViolations: Bool { Bool(bits[22]) }
    var supportsINVVIPD: Bool { Bool(bits[32]) }
    var supportsIndividualAddressINVVIPD: Bool { Bool(bits[40]) }
    var supportsSingleContextINVVIPD: Bool { Bool(bits[41]) }
    var supportsAllContextINVVIPD: Bool { Bool(bits[42]) }
    var supportsSingleContextRetainingGlobalsINVVIPD: Bool { Bool(bits[43]) }

    init() {
        bits = BitArray64(CPU.readMSR(0x48C))
    }
}

struct VMXTruePinBasedControls {
    let low: UInt32
    let high: UInt32

    init() {
        (low, high) = CPU.readMSR(0x48D)
    }

    var defaultValue: UInt32 {
        var result: UInt32 = 0
        result &= high  // bits 32:63 contains allowed 1-settings. If bit is 0 it must be cleared
        result |= low   // bits 0:31 contains allowed 0-settings. If bit is 1 it must be set
        return result
    }
}

struct VMXTruePrimaryProcessorBasedControls {
    let low: UInt32
    let high: UInt32

    init() {
        (low, high) = CPU.readMSR(0x48E)
    }

    var defaultValue: UInt32 {
        var result: UInt32 = 0
        result &= high  // bits 32:63 contains allowed 1-settings. If bit is 0 it must be cleared
        result |= low   // bits 0:31 contains allowed 0-settings. If bit is 1 it must be set
        return result
    }
}

struct VMXTrueExitControls {
    let low: UInt32
    let high: UInt32

    init() {
        (low, high) = CPU.readMSR(0x48f)
    }

    var defaultValue: UInt32 {
        var result: UInt32 = 0
        result &= high  // bits 32:63 contains allowed 1-settings. If bit is 0 it must be cleared
        result |= low   // bits 0:31 contains allowed 0-settings. If bit is 1 it must be set
        return result
    }
}


struct VMXTrueEntryControls {
    let low: UInt32
    let high: UInt32

    init() {
        (low, high) = CPU.readMSR(0x490)
    }

    var defaultValue: UInt32 {
        var result: UInt32 = 0
        result &= high  // bits 32:63 contains allowed 1-settings. If bit is 0 it must be cleared
        result |= low   // bits 0:31 contains allowed 0-settings. If bit is 1 it must be set
        return result
    }
}

struct VMXVMFunc {
    let bits: BitArray64

    var eptpSwitching: Bool { Bool(bits[0]) }

    init() {
            bits = BitArray64(CPU.readMSR(0x48C))
        }
}

