/*
 * kernel/arch/x86_64/cpu.swift
 *
 * Created by Simon Evans on 21/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * CPU feature detection and control
 *
 */


// Singleton that will be initialised by cpu.readCapabilities
private(set) var cpu = CPU()


struct CPU: ~Copyable {
    private var cpuId = CPUID()
    private(set) var microarchitecture = IntelMicroarchitecture.unknown
    private(set) var displayFamily: UInt8 = 0
    private(set) var displayModel: UInt8 = 0

    // Some of these frequencies can be determined via CPUID, otherwise
    // they are calibrated against an external timer (initially PIT)
    // FIXME: Add recalibration to increase the accuracy for the frequencies that are calibrated
    private(set) var baseFrequency: UInt64 = 0
    private(set) var cpuFrequency: UInt64 = 0
    private(set) var tscFrequency: UInt64 = 0
    private(set) var crystalFrequency: UInt64 = 0
    private(set) var stepping: UInt8 = 0

    // Processor type: 00=OEM, 01=OverDrive, 10=Dual, 11=reserved
    private(set) var processorType: UInt8 = 0

    init() {}   // Empty initialiser as stored at global scope to avoid
                // one-time initialisation

    static func readCapabilities() {
        #kprint("CPU: Reading Capabilities")
        cpu.initialise()
    }

    static func readFrequencies() {
        // Requires ACPI parsing to get PM timer
        cpu.getFrequencies()
    }

    static var cpuId: CPUID {
        return cpu.cpuId
    }

    static var capabilities: CPUID {
        return cpu.cpuId
    }

    mutating private func initialise() {
        self.cpuId.initialise()

        self.stepping = UInt8(self.cpuId.cpuid01.regs.eax & 0xF)
        // Processor type: 00=OEM, 01=OverDrive, 10=Dual, 11=reserved
        self.processorType = UInt8((self.cpuId.cpuid01.regs.eax >> 12) & 0x3)

        if self.cpuId.vendorName == "GenuineIntel" {
            let eax = self.cpuId.cpuid01.regs.eax

            // CPUID Leaf 01H EAX bit layout (SDM Vol. 3A 18.1):
            //   [3:0]   Stepping ID
            //   [7:4]   Model
            //   [11:8]  Family
            //   [13:12] Processor Type
            //   [19:16] Extended Model
            //   [27:20] Extended Family

            // Displayed family as defined by Intel:
            //   Family == 0xF -> Extended Family + 0xF
            //   otherwise     -> Family

            let family = UInt8((eax >> 8) & 0xF)
            let model  = UInt8((eax >> 4) & 0xF)

            if family == 0xF {
                self.displayFamily = UInt8((eax >> 20) & 0xFF) + 0xF
            } else {
                self.displayFamily = family
            }
            // Displayed model as defined by Intel:
            //   Family == 0x6 or 0xF -> (Extended Model << 4) | Model
            //   otherwise            -> Model
            if family == 0x6 || family == 0xF {
                let extModel = UInt8((eax >> 16) & 0xF)
                self.displayModel = (extModel << 4) | model
            } else {
                self.displayModel = model
            }

            self.microarchitecture = IntelMicroarchitecture(
                self.displayFamily, self.displayModel
            )
        }
    }


    mutating private func getFrequencies() {
        if let cpuid16 = self.cpuId.cpuidLeaf(0x16), cpuid16.regs.eax > 0 {
            self.baseFrequency = UInt64(cpuid16.regs.eax) * 1_000_000   // eax = base MHZ
        }

        if baseFrequency > 0 {
            self.cpuFrequency = self.baseFrequency
        } else {
            var total = UInt64(0)
            var divisor = UInt64(0)

            for _ in 1...3 {
                if let frequency = quickPMTimerCalibrate() {
                    total += frequency
                    divisor += 1
                }
            }
            guard divisor > 0 else {
                fatalError("CPU: Failed to calibrate speed")
            }
            self.cpuFrequency = total / divisor
        }
        if let (tscFreq, crystalFreq) = readTSCFrequency() {
            self.tscFrequency = tscFreq
            self.crystalFrequency = crystalFreq
        }
        #kprintf("CPU: freq: %u.%uMHz TSC freq: %u.%uMHz crystal freq: %u.%uMHz\n",
                 self.cpuFrequency / 1_000_000, self.cpuFrequency % 1_000_000,
                 self.tscFrequency / 1_000_000, self.tscFrequency % 1_000_000,
                 self.crystalFrequency / 1_000_000, self.crystalFrequency % 1_000_000
        )
    }


    // These are the values stored in the PAT MSRs
    enum PATEntry: UInt8, CustomStringConvertible {
        case uncacheable = 0
        case writeCombining = 1
        case writeThrough = 4
        case writeProtected = 5
        case writeBack = 6
        case weakUncacheable = 7 // Uncacheable (UC-), Overrideable by MTRRs

        var description: String {
            return switch self {
                case .uncacheable:
                    "Uncacheable"
                case .writeCombining:
                    "WriteCombining"
                case .writeThrough:
                    "WriteThrough"
                case .writeProtected:
                    "WriteProtected"
                case .writeBack:
                    "WriteBack"
                case .weakUncacheable:
                    "WeakUncacheable"
            }
        }
    }

    // The Page Attribute Table (PAT) entries will be setup so that the cache type rawValues get setup to match the MTRR values.
    // weakUncacheable will be ignored here as it isnt useful at the moment
    // These are the indexes of the PAT MSRs. Not all are used, some are reserved
    enum CacheType: Int, CustomStringConvertible {
        case writeBack = 0
        case writeCombining = 1
        case weakUncacheable = 2
        case uncacheable = 3
        case reserved1 = 4 // WriteBack
        case writeProtected = 5
        case reserved2 = 6 // weakUncacheable
        case writeThrough = 7

        var description: String {
            switch self {
                case .writeBack:
                    "WB"
                case .writeCombining:
                    "WC"
                case .weakUncacheable:
                    "WU"
                case .uncacheable:
                    "UN"
                case .reserved1:
                    "R1"
                case .writeProtected:
                    "WP"
                case .reserved2:
                    "R2"
                case .writeThrough:
                    "WT"
            }
        }

        // This value is stored as three bits in a Page Table Entry mapping a page.
        var patEntry: Int { rawValue }
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


    static func enableWP(_ enable: Bool) {
        var cr0 = CPU.cr0
        cr0.writeProtect = enable
        CPU.cr0 = cr0
    }


    static func enableNXE(_ enable: Bool) -> Bool {
        if CPU.capabilities.nxe && CPU.capabilities.msr && CPU.capabilities.IA32_EFER {
            var (eax, edx) = CPU.readMSR(0xC0000080)
            eax |= 1 << 11
            writeMSR(0xC0000080, eax, edx)
            #kprint("CPU: NXE enabled")
            return true
        }
        #kprint("CPU: NXE cant be enabled")
        return false
    }


    // Setup the Page Attribute Table
    static func setupPAT() {

        guard CPU.capabilities.pat else {
            koops("CPU doesnt support PAT")
        }
        // Update PAT to add a WriteCombining and WriteProtected entry
        // New PAT
        // 0: WriteBack        (WB)
        // 1: WriteCombining   (WC)
        // 2: Weak Uncacheable (UC-)
        // 3: Uncacheable      (UC)
        // 4: WriteBack        (WB)
        // 5: WriteProtected   (WP)
        // 6: Weak Uncacheable (UC-)
        // 7: WriteThrough     (WT)

        #kprint("CPU: Setting up new PAT Array")
        var pats = ByteArray8(readMSR(0x277)).map { PATEntry(rawValue: $0)! }
#if false
        #kprint("CPU: Page Attribute Table:")
        for (idx, entry) in pats.enumerated() {
            #kprint("CPU: \(idx): \(entry)")
        }
#endif

        pats[CacheType.writeBack.patEntry] = PATEntry.writeBack
        pats[CacheType.writeCombining.patEntry] = PATEntry.writeCombining
        pats[CacheType.weakUncacheable.patEntry] = PATEntry.weakUncacheable
        pats[CacheType.uncacheable.patEntry] = PATEntry.uncacheable
        pats[CacheType.reserved1.patEntry] = PATEntry.writeBack
        pats[CacheType.writeProtected.patEntry] = PATEntry.writeProtected
        pats[CacheType.reserved2.patEntry] = PATEntry.weakUncacheable
        pats[CacheType.writeThrough.patEntry] = PATEntry.writeThrough

        writeMSR(0x277, UInt64(withBytes: pats.map { $0.rawValue }))
#if false
        let newPat = ByteArray8(readMSR(0x277)).map { PATEntry(rawValue: $0)! }
        #kprint("CPU: Page Attribute Table:")
        for (idx, entry) in newPat.enumerated() {
            #kprint("CPU: \(idx): \(entry)")
        }
        let msr: UInt64 = readMSR(0x277)
        #kprintf("PAT MSR: %16.16lx\n", msr)
#endif
        // Disable PCIDE in CR4
        var cr4 = CPU.cr4
        cr4.pcide = false
        CPU.cr4 = cr4
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
            result += " MP: " + (monitorCoprocessor ? "1" : "0")
            result += " EM: " + (fpuEmulation ? "1" : "0")
            result += " TS: " + (taskSwitched ? "1" : "0")
            result += " ET: " + (extensionType ? "1" : "0")
            result += " NE: " + (numericError ? "1" : "0")
            result += " WP: " + (writeProtect ? "1" : "0")
            result += " AM: " + (alignmentMask ? "1" : "0")
            result += " NW: " + (notWriteThrough ? "1" : "0")
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
            get { PhysAddress(PageSize().roundDown(UInt(value))) }
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

        var la57: Bool {
            get { Bool(bits[12]) }
            set { bits[12] = newValue ? 1 : 0 }
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

        var kl: Bool  {
            get { Bool(bits[19]) }
            set { bits[19] = newValue ? 1 : 0 }
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
            result += " LA57: " + (la57 ? "1" : "0")
            result += " VMXE: " + (vmxe ? "1" : "0")
            result += " SMXE: " + (smxe ? "1" : "0")
            result += " FSGSBASE: " + (fsgsbase ? "1" : "0")
            result += " PCIDE: " + (pcide ? "1" : "0")
            result += " OSXSAVE: " + (osxsave ? "1" : "0")
            result += " KL: " + (kl ? "1" : "0")
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

    static var cr3: CR3Register {
        get { CR3Register() }
        set { setCR3(newValue.value) }
    }

    static var cr4: CR4Register {
        get { CR4Register() }
        set { setCR4(newValue.value) }
    }

}
