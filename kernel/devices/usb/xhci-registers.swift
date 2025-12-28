/*
 *  kernel/devices/usb/xhci-registers.swift
 *  Kernel
 *
 *  Created by Simon Evans on 18/08/2025.
 */


extension HCD_XHCI {

    struct CapabilityRegisters: ~Copyable {
        let capVersion: UInt32
        let hcsParams1: UInt32
        let hcsParams2: UInt32
        let hcsParams3: UInt32
        let hccParams1: UInt32
        let doorbellOffset: UInt32
        let rtsOff: UInt32
        let hccParams2: UInt32?
        let vtiosoffset: UInt32?
        var legacySupport: ExtendedCapability.LegacySupport?
        let portMap: [ClosedRange<UInt8> : ExtendedCapability.SupportedProtocol]

        var capLength: Int { Int(capVersion & 0xff) }
        var maxSlots: Int { Int(hcsParams1 & 0xff) }
        var maxIntrs: Int { Int((hcsParams1 >> 8) & 0x3ff) }
        var maxPorts: Int { Int((hcsParams1 >> 24) & 0xff) }
        var runtimeRegisterSize: Int { 0x20 + (maxIntrs * 32) }

        var maxEventRingSegmentTable: Int { hcsParams2.bits(4...7) }
        var scratchPadRestore: Bool { hcsParams2.bit(26) }
        var maxScratchPadBuffers: Int {
            let lo = (hcsParams2 >> 27) & 0b00000_11111
            let hi = (hcsParams2 >> 16) & 0b11111_00000
            return Int(lo | hi)
        }
        var has64BitAddressing: Bool { hccParams1.bit(0) }
        var contextSize: Int { hccParams1.bit(2) ? 64 : 32 }


        init(_ mmioRegion: MMIORegion) {
            capVersion = mmioRegion.read(fromByteOffset: 0x00)
            let capLength = Int(capVersion & 0xff)
            let hciVersion = UInt16(capVersion >> 16)

            hcsParams1 = mmioRegion.read(fromByteOffset: 0x04)
            hcsParams2 = mmioRegion.read(fromByteOffset: 0x08)
            hcsParams3 = mmioRegion.read(fromByteOffset: 0x0c)


            hccParams1 = mmioRegion.read(fromByteOffset: 0x10)
            doorbellOffset = mmioRegion.read(fromByteOffset: 0x14)
            rtsOff = mmioRegion.read(fromByteOffset: 0x18)

            if XHCIDebug {
                #kprintf("xhci: hcsParams: %8.8x %8.8x %8.8x\n", hcsParams1, hcsParams2, hcsParams3)
                #kprintf("xhci: Capabilities length: %d bytes  HCI Version: 0x%x %d.%d\n",
                         capVersion & 0xff,
                         hciVersion, hciVersion >> 8, hciVersion & 0xff)
            }

            var _hccParams2: UInt32? = nil
            var _hccDesc = "not supported"
            if hciVersion >= 0x110 {  // Version 1.1 BCD
                if capLength < 0x1c {
                    #kprintf("xhci: warning: hciVersion: %x.%x but capLength = %x\n",
                             hciVersion >> 8, hciVersion & 0xff, capLength)
                } else {
                    _hccParams2 = mmioRegion.read(fromByteOffset: 0x1c)
                    _hccDesc = "0x\(_hccParams2!.hex())"
                }
            }
            hccParams2 = _hccParams2

            var _vtiosoffset: UInt32? = nil
            var _vtioDesc = "not supported"
            if hciVersion >= 0x120 { // Version 1.2 HCD
                if capLength < 0x20 {
                    #kprintf("xhci: warning: hciVersion: %x.%x but capLength = %x\n",
                             hciVersion >> 8, hciVersion & 0xff, capLength)
                } else {
                    _vtiosoffset = mmioRegion.read(fromByteOffset: 0x20)
                    _vtioDesc = "0x\(_vtiosoffset!.hex())"
                }
            }
            vtiosoffset = _vtiosoffset

            let xECPOffset = UInt32(hccParams1 >> 16 & 0xffff) * 4
            guard xECPOffset > 0 else {
                #kprint("xhci: No extended capabilities supported\n")
                self.portMap = [:]
                return
            }
            if XHCIDebug {
                #kprintf("xhci: Extended capabilities at 0x%x\n", xECPOffset)
            }


            // TODO: Look for overlapping port ranges
            // TODO: Create a HUB config for each SupportedProtocol

            var exOffset = Int(xECPOffset)
            var count = 1
            let _maxPorts = UInt8(truncatingIfNeeded: hcsParams1 >> 24)
            var portConfiguration: [Bool] = .init(repeating: false, count: Int(_maxPorts + 1))
            var _portMap: [ClosedRange<UInt8> : ExtendedCapability.SupportedProtocol] = [:]

            while true {
                let capReg: UInt32 = mmioRegion.read(fromByteOffset: exOffset)
                let capId = capReg.bits(0...7)
                let nextPtr = UInt(capReg.bits(8...15)) * 4
                let regionSize = mmioRegion.regionSize - exOffset

                if XHCIDebug {
                    #kprintf("xhci: Extended Capability: %d\t0x%8.8x ID: %d nextPtr: 0x%x\t capspecific: 0x%4.4x regionSize: 0x%x\n",
                             count, capReg, capId, nextPtr, UInt(capReg.bits(16...31)), UInt(regionSize))
                }

                let subRegion = mmioRegion.mmioSubRegion(offset: exOffset, count: regionSize)

            nextCapability:
                switch capId {
                    case 0x1:
                        let cap = ExtendedCapability.LegacySupport(from: subRegion)
                        self.legacySupport = cap
                        if XHCIDebug {
                            #kprint("xhci: Found Legacy Support:", cap.description)
                        }

                    case 0x2:
                        let cap = ExtendedCapability.SupportedProtocol(from: subRegion)
                        // Use wraparound to check overflow
                        guard cap.portOffset &+ cap.portCount > cap.portOffset else {
                            #kprintf("xhci: portOffset: %u + portCount: %u exceeds 255\n",
                                     cap.portOffset, cap.portCount)
                            break nextCapability
                        }
                        let portRange = cap.portOffset...(cap.portOffset + cap.portCount - 1)
                        #kprint("xhci: Found Supported Protocols")

                        for portIdx in portRange {
                            guard portIdx <= _maxPorts else {
                                #kprintf("xhci: Invalid port: %d maxPorts: %d\n", portIdx, _maxPorts)
                                break nextCapability
                            }
                            guard portConfiguration[Int(portIdx)] == false else {
                                #kprintf("xhci: Duplicate port configuration for port: %d\n", portIdx)
                                break nextCapability

                            }
                            portConfiguration[Int(portIdx)] = true
                        }
                        if XHCIDebug {
                            #kprintf("xhci: Adding to portmap %u-%u, %s\n", portRange.lowerBound,
                                     portRange.upperBound, cap.description)
                        }
                        _portMap[portRange] = cap


                    default:
                        #kprintf("xhci: Unhandled Extended Capability %d\n", capReg)

                }
                if nextPtr == 0 {
                    break
                }
                count += 1
                exOffset += Int(nextPtr)
            }
            self.portMap = _portMap
            if XHCIDebug {
                #kprintf("xhci: Have %d portMaps\n", portMap.count)
                #kprintf("xhci: ERST Max: %d has64Bit: %s\n", maxEventRingSegmentTable, has64BitAddressing)
                #kprintf("xhci: hccParams1: 0x%8.8x doorbell: 0x%8.8x rtsOffset: 0x%8.8x\n",
                         hccParams1, doorbellOffset, rtsOff)
                #kprintf("xhci: hccParams2: %s   vtiooffset: %s\n", _hccDesc, _vtioDesc)
            }
        }

        func supportedProtocol(port: UInt8) -> ExtendedCapability.SupportedProtocol? {
            for (portRange, value) in self.portMap {
                if portRange.contains(port) {
                    return value
                }
            }
            return nil
        }
    }

    enum ExtendedCapability {
        struct LegacySupport: CustomStringConvertible {
            let registers: MMIOSubRegion

            // USB Legacy Support
            var usbLegSupp: UInt32 {
                registers.read(fromByteOffset: 0x0)
            }

            // USB Legacy Support Control/Status - Used by BIOS
            var usbLegCtlSts: UInt32 {
                registers.read(fromByteOffset: 0x4)
            }

            var biosOwned: Bool {
                get { usbLegSupp.bit(16) }
                set {
                    var value = BitArray32(usbLegSupp)
                    value[16] = newValue ? 1 : 0
                    registers.write(value: value.rawValue, toByteOffset: 0x0)
                }
            }

            var osOwned: Bool {
                get { usbLegSupp.bit(24) }
                set {
                    var value = BitArray32(usbLegSupp)
                    value[24] = newValue ? 1 : 0
                    registers.write(value: value.rawValue, toByteOffset: 0x0)
                }
            }


            var description: String {
                let register = usbLegSupp
                return #sprintf("biosOwned: %s OS owned: %s", register.bit(16), register.bit(24))
            }


            init(from mmioRegion: MMIOSubRegion) {
                self.registers = mmioRegion
            }
        }


        struct SupportedProtocol: CustomStringConvertible {

            struct ProtocolSpeedID: CustomStringConvertible {
                let rawValue: UInt32

                // Protocol Speed ID Value
                var psiv: Int { Int(rawValue.bits(0...3)) }
                // Protocol Speed ID Exponent
                var psie: Int { Int(rawValue.bits(4...5)) }
                // PSI Type 0=Symmetric 1=Reserved 2=AsymmetricTX 3=AsymetricRX
                var plt: Int { Int(rawValue.bits(6...7)) }
                // PSI Full-duplex 1=Full 0=Half
                var pfd: Bool { rawValue.bit(8) }
                // Link Protocol (LP) 0=SuperSpeed 1=SuperSpeedPlus 2,3=Reserved
                var lp: Int { Int(rawValue.bits(14...15)) }
                // Protocol Speed ID Mantissa
                var psim: Int { Int(rawValue.bits(16...31)) }

                var maxBitRate: Int {
                    var exponent = 1
                    for _ in 0..<psie {
                        exponent *= 1000
                    }
                    return psim * exponent
                }

                var maxBitRateDesc: String {
                    let unit = switch psie {
                        case 1: "K"
                        case 2: "M"
                        case 3: "G"
                        default: ""
                    }
                    return #sprintf("%d %sb/s", psim, unit)
                }

                var description: String {
                    #sprintf("psiv: %d psie: %d plt: %d pfd: %s lp: %d psim: %d",
                             psiv, psie, plt, pfd, lp, psim)
                }


                init(rawValue: UInt32) {
                    self.rawValue = rawValue
                }

                fileprivate init(psiv: Int, psie: Int, plt: Int, pfd: Bool, lp: Int, psim: Int) {
                    rawValue = UInt32(psiv | (psie << 4) | (plt << 6) | (pfd ? 256 : 0) | (lp << 14) | (psim << 16))
                }

            }

            let header: UInt32
            let nameString: UInt32
            let portInfo: UInt32
            let protocolSlotType: UInt32
            private(set) var speedIds: [ProtocolSpeedID] = []

            var majorRevision: UInt { UInt((header >> 24) & 0xFF) }
            var minorRevision: UInt { UInt((header >> 16) & 0xFF) }

            var portOffset: UInt8 { UInt8(portInfo.bits(0...7)) }
            var portCount: UInt8 { UInt8(portInfo.bits(8...15)) }
            var protocolDefined: Int { Int(portInfo.bits(16...27)) }
            var psic: Int { Int(portInfo.bits(28...31)) }


            var description: String {
                var description = #sprintf("rev: %x.%x portOffset: %d portCount: %d protocolDefined: %d psic: %d protocolSlotType: %d\n",
                                           majorRevision, minorRevision,
                                           portOffset, portCount, protocolDefined, psic,
                                           protocolSlotType
                )

                for index in speedIds.indices {
                    description += #sprintf("  %d: %s\n", index, speedIds[index].description)
                }
                return description
            }


            init(from mmioRegion: MMIOSubRegion) {
                header = mmioRegion.read(fromByteOffset: 0x0)
                nameString = mmioRegion.read(fromByteOffset: 0x4)
                portInfo = mmioRegion.read(fromByteOffset: 0x8)
                protocolSlotType = mmioRegion.read(fromByteOffset: 0xC)

                guard nameString == 0x20425355, majorRevision == 2 || majorRevision == 3 else {
                    #kprint("xhci: SupportedProtocol with unsupported name or version")
                    return
                }

                let speedIdCount = psic
                if speedIdCount == 0 {
                    // No defined speeds, add in defaults per protocol
                    let usb_2_0: InlineArray<_, ProtocolSpeedID> = [
                        .init(psiv: 1, psie: 2, plt: 0, pfd: false, lp: 0, psim: 12),
                        .init(psiv: 2, psie: 1, plt: 0, pfd: false, lp: 0, psim: 1500),
                        .init(psiv: 3, psie: 2, plt: 0, pfd: false, lp: 0, psim: 480),
                    ]

                    let usb_3_0: InlineArray<_, ProtocolSpeedID> = [
                        .init(psiv: 4, psie: 3, plt: 0, pfd: true, lp: 0, psim: 5),
                    ]

                    let usb_3_1: InlineArray<_, ProtocolSpeedID> = [
                        .init(psiv: 5, psie: 3, plt: 0, pfd: true, lp: 0, psim: 10),
                    ]

                    let usb_3_2: InlineArray<_, ProtocolSpeedID> = [
                        .init(psiv: 6, psie: 3, plt: 0, pfd: true, lp: 0, psim: 10),
                        .init(psiv: 7, psie: 3, plt: 0, pfd: true, lp: 0, psim: 20),
                    ]


                    var span: Span<ProtocolSpeedID>? = nil
                    switch (majorRevision, minorRevision) {
                        case (2, 0): span = usb_2_0.span
                        case (3, 0): span = usb_3_0.span
                        case (3, 1): span = usb_3_1.span
                        case (3, 2): span = usb_3_2.span
                        default: break
                    }
                    if let span {
                        for idx in span.indices {
                            speedIds.append(span[idx])
                        }
                    }
                } else{
                    speedIds.reserveCapacity(speedIdCount)
                    var offset = 0x10
                    for _ in 0..<speedIdCount {
                        speedIds.append(ProtocolSpeedID(rawValue: mmioRegion.read(fromByteOffset: offset)))
                        offset += 4
                    }
                }
            }
        }

        struct ExtendedPM {

        }

        struct IOVirtulization {

        }
        struct MSI {

        }
        struct LocalMemory {

        }
        struct DebugCapability {

        }
        struct ExtendedMSI {

        }

        case legacySupport(LegacySupport)
        case supportedProtocols(SupportedProtocol)
        case extendedPM(ExtendedPM)
        case ioVirtulization(IOVirtulization)
        case msi(MSI)
        case localMemory(LocalMemory)
        case debugCapability(DebugCapability)
        case extendedMSI(ExtendedMSI)
    }

    struct OperationRegisters: ~Copyable {
        private let mmioRegion: MMIOSubRegion

        init(mmioRegion: MMIOSubRegion) {
            self.mmioRegion = mmioRegion
        }

        // USB Command
        var usbCmd: UInt32 {
            get { mmioRegion.read(fromByteOffset: 0x0) }
            set { mmioRegion.write(value: newValue, toByteOffset: 0x0) }
        }

        // USB Status
        var usbSts: UInt32 {
            get { mmioRegion.read(fromByteOffset: 0x4) }
            set { mmioRegion.write(value: newValue, toByteOffset: 0x4)}
        }

        var pageSize: Int {
            let value: UInt32 = mmioRegion.read(fromByteOffset: 0x8)
            return Int((value & 0xffff) << 12)
        }

        // Device Notification Control
        var dnCtrl: UInt32 {
            get { mmioRegion.read(fromByteOffset: 0x14) }
            set { mmioRegion.write(value: newValue, toByteOffset: 0x14)}

        }

        // Command Ring Control
        var crcr: UInt64 {
            get { mmioRegion.read(fromByteOffset: 0x18) }
            set { mmioRegion.write(value: newValue, toByteOffset: 0x18)}

        }

        // Device Content Base Address Array Pointer
        var dcbaap: UInt64 {
            get { mmioRegion.read(fromByteOffset: 0x30) }
            set { mmioRegion.write(value: newValue, toByteOffset: 0x30)}

        }

        var config: UInt32 {
            get { mmioRegion.read(fromByteOffset: 0x38) }
            set { mmioRegion.write(value: newValue, toByteOffset: 0x38)}
        }

        // Port registers
        // Port Status and Control Register (PORTSC)
        func portSC(port: UInt8) -> UInt32 {
            let offset = 0x400 + (0x10 * Int(port - 1))
            return mmioRegion.read(fromByteOffset: offset)
        }

        func portSC(port: UInt8, newValue: UInt32) {
            let offset = 0x400 + (0x10 * Int(port - 1))
            mmioRegion.write(value: newValue, toByteOffset: offset)
        }

        // Port PM Status and Control Register (PORTPMSC)
        func portPMSC(port: UInt8) -> UInt32 {
            let offset = 0x404 + (0x10 * Int(port - 1))
            return mmioRegion.read(fromByteOffset: offset)
        }

        func portPMSC(port: UInt8, newValue: UInt32) {
            let offset = 0x404 + (0x10 * Int(port - 1))
            mmioRegion.write(value: newValue, toByteOffset: offset)
        }

        // Port Link Info Register (PORTLI)
        func portLI(port: UInt8) -> UInt32 {
            let offset = 0x404 + (0x10 * Int(port - 1))
            return mmioRegion.read(fromByteOffset: offset)
        }

        func portLI(port: UInt8, newValue: UInt32) {
            let offset = 0x404 + (0x10 * Int(port - 1))
            mmioRegion.write(value: newValue, toByteOffset: offset)
        }

        // Port Hardware LPM Control Register (PORTHLPMC)
        func portHLPMC(port: UInt8) -> UInt32 {
            let offset = 0x404 + (0x10 * Int(port - 1))
            return mmioRegion.read(fromByteOffset: offset)
        }

        func portHLPMC(port: UInt8, newValue: UInt32) {
            let offset = 0x404 + (0x10 * Int(port - 1))
            mmioRegion.write(value: newValue, toByteOffset: offset)
        }
    }

    struct RuntimeRegisters: ~Copyable {


        private let mmioRegion: MMIOSubRegion

        init(mmioRegion: MMIOSubRegion) {
            self.mmioRegion = mmioRegion
        }

        func setInterrupter(_ interrupter: Int, eventRingTableSize: UInt32) {
            let offset = 0x28 + (32 * interrupter)
            mmioRegion.write(value: eventRingTableSize, toByteOffset: offset)
        }

        func setInterrupter(_ interrupter: Int, eventRingTableBaseAddr: UInt64) {
            let offset = 0x30 + (32 * interrupter)
            mmioRegion.write(value: eventRingTableBaseAddr, toByteOffset: offset)
        }

        func setInterrupter(_ interrupter: Int, eventRingDequeuePointer ptr: UInt64) {
            let offset = 0x38 + (32 * interrupter)
            mmioRegion.write(value: UInt32(truncatingIfNeeded: ptr), toByteOffset: offset + 0)
            mmioRegion.write(value: UInt32(truncatingIfNeeded: ptr >> 32), toByteOffset: offset + 4)
        }

        func getEventRingDequeuePointer(forInterrupter interrupter: Int) -> UInt64 {
            let offset = 0x38 + (32 * interrupter)
            return mmioRegion.read(fromByteOffset: offset)
        }

        func enableInterrupter(_ interrupter: Int, modInterval: UInt16, modCounter: UInt16) {
            let imodOffset = 0x24 + (32 * interrupter)
            let value = UInt32(modInterval) | (UInt32(modCounter) << 16)
            mmioRegion.write(value: value, toByteOffset: imodOffset)
            let imanOffset = 0x20 + (32 * interrupter)
            var imanValue: UInt32 = mmioRegion.read(fromByteOffset: imanOffset)
            imanValue |= 3  // set interrupt enable, bit0 is RW1C so will clear pending bit if set
            mmioRegion.write(value: imanValue, toByteOffset: imanOffset)
        }

        func clearInterrupterPending(_ interrupter: Int) {
            let imanOffset = 0x20 + (32 * interrupter)
            let value: UInt32 = mmioRegion.read(fromByteOffset: imanOffset)
            mmioRegion.write(value: value, toByteOffset: imanOffset)
        }

        func interrupterPending(_ interrupter: Int) -> Bool {
            let imanOffset = 0x20 + (32 * interrupter)
            let value: UInt32 = mmioRegion.read(fromByteOffset: imanOffset)
            if XHCIDebug {
                #kprintf("xhci: interrupterPending(%d) -> 0x%8.8x\n", interrupter, value)
            }
            return value.bit(0)
        }
    }


    struct DoorbellRegisters: ~Copyable {
        private let mmioRegion: MMIOSubRegion

        init(_ mmioRegion: MMIOSubRegion) {
            self.mmioRegion = mmioRegion
        }

        func ring(_ idx: Int, taskId: UInt16, target: UInt8) {
            let value = UInt32(taskId) << 16 | UInt32(target)
            mmioRegion.write(value: value, toByteOffset: idx * MemoryLayout<UInt32>.size)
        }
    }
}
