//
//  kernel/devices/acpi/amlresourcedata.swift
//
//  Created by Simon Evans on 02/12/2017.
//  Copyright © 2017 - 2019 Simon Evans. All rights reserved.
//
//  Current Resource Settings (_CRS) decoding.

enum AMLResourceSetting: CustomStringConvertible, Equatable {
    case irqSetting(AMLIrqSetting)
    case extendedIrqSetting(AMLIrqExtendedDescriptor)
    case dmaSetting(AMLDmaSetting)
    case ioPortSetting(AMLIOPortSetting)
    case memoryRangeDescriptor(AMLMemoryRangeDescriptor)
    case fixedMemoryRangeDescriptor(AMLFixedMemoryRangeDescriptor)
    case wordAddressSpaceDescriptor(AMLWordAddressSpaceDescriptor)
    case dwordAddressSpaceDescriptor(AMLDWordAddressSpaceDescriptor)
    case qwordAddressSpaceDescriptor(AMLQWordAddressSpaceDescriptor)

    var description: String {
        switch self {
        case let .irqSetting(irq): return irq.description
        case let .extendedIrqSetting(irq): return irq.description
        case let .dmaSetting(dma): return dma.description
        case let .ioPortSetting(ioPort): return ioPort.description
        case let .memoryRangeDescriptor(memoryRange): return memoryRange.description
        case let .fixedMemoryRangeDescriptor(memoryRange): return memoryRange.description
        case let .wordAddressSpaceDescriptor(descriptor): return descriptor.description
        case let .dwordAddressSpaceDescriptor(descriptor): return descriptor.description
        case let .qwordAddressSpaceDescriptor(descriptor): return descriptor.description
        }
    }

    static func == (lhs: AMLResourceSetting, rhs: AMLResourceSetting) -> Bool {
        switch (lhs, rhs) {
            case (.irqSetting(let irq1), .irqSetting(let irq2)): return irq1 == irq2
            case (.extendedIrqSetting(let irq1), .extendedIrqSetting(let irq2)): return irq1 == irq2
            case (.dmaSetting(let dma1), .dmaSetting(let dma2)): return dma1 == dma2
            case (.ioPortSetting(let ioPort1), .ioPortSetting(let ioPort2)): return ioPort1 == ioPort2
            case (.memoryRangeDescriptor(let mem1), .memoryRangeDescriptor(let mem2)): return mem1 == mem2
            case (.fixedMemoryRangeDescriptor(let mem1), .fixedMemoryRangeDescriptor(let mem2)): return mem1 == mem2
            case (.wordAddressSpaceDescriptor(let desc1), .wordAddressSpaceDescriptor(let desc2)): return desc1 == desc2
            case (.dwordAddressSpaceDescriptor(let desc1), .dwordAddressSpaceDescriptor(let desc2)): return desc1 == desc2
            case (.qwordAddressSpaceDescriptor(let desc1), .qwordAddressSpaceDescriptor(let desc2)): return desc1 == desc2
            default: return false

        }
    }
}


private enum AMLSmallItemName: UInt8 {
    // 0x00 - 0x03 reserved
    case irqFormatDescriptor               = 0x04
    case dmaFormatDescriptor               = 0x05
    case startDependentFunctionsDescriptor = 0x06
    case endDependentFunctionsDescriptor   = 0x07
    case ioPortDescriptor                  = 0x08
    case fixedLocationIOPortDescriptor     = 0x09
    case fixedDmaDescriptor                = 0x0A
    // 0x0B–0x0D reserved
    case vendorDefinedDescriptor           = 0x0E
    case endTagDescriptor                  = 0x0F
}

private enum AMLLargeItemName: UInt8 {
    // 0x00 - reserved
    case memoryRangeDescriptor24Bit              = 0x01
    case genericRegisterDescriptor               = 0x02
    // 0x03 - reserved
    case vendorDefinedDescriptor                 = 0x04
    case memoryRangeDescriptor32Bit              = 0x05
    case fixedLocationMemoryRangeDescriptor32Bit = 0x06
    case dwordAddressSpaceDescriptor             = 0x07
    case wordAddressSpaceDescriptor              = 0x08
    case extendedIRQDescriptor                   = 0x09
    case qwordAddressSpaceDescriptor             = 0x0A
    case extendedAddressSpaceDescriptor          = 0x0B
    case gpioConnectionDescriptor                = 0x0C
    // 0x0D - reserved
    case genericSerialBusConnectionDescriptor    = 0x0E
    // 0x0f - 0x7f - reserved
}


struct AMLIrqSetting: CustomStringConvertible, Equatable {
    let irqMask: BitArray16
    let levelTriggered: Bool
    let activeHigh: Bool
    let interruptSharing: Bool
    let wakeCapable: Bool
    let longBuffer: Bool
    var description: String {
        "IRQ: mask: \(irqMask.rawValue.binary(separators: true))"
    }

    init(_ buffer: AMLBuffer) {
        precondition(buffer.count == 2 || buffer.count == 3)
        irqMask = BitArray16(UInt16(withBytes: buffer[0], buffer[1]))
        if buffer.count == 3 {
            let info = BitArray8(buffer[2])
            levelTriggered = (info[0] == 0)
            activeHigh = (info[3] == 0)
            interruptSharing = (info[4] != 0)
            wakeCapable = (info[5] != 0)
            longBuffer = true
        } else {
            levelTriggered = false // edge triggered
            activeHigh = true
            interruptSharing = false
            wakeCapable = false
            longBuffer = false
        }
    }

    init(irqMask: UInt16) {
        self.irqMask = BitArray16(irqMask)
        self.levelTriggered = false
        self.activeHigh = true
        self.interruptSharing = false
        self.wakeCapable = false
        self.longBuffer = false
    }

    init(irqMask: UInt16, levelTriggered: Bool, activeHigh: Bool, interruptSharing: Bool, wakeCapable: Bool) {
        self.irqMask = BitArray16(irqMask)
        self.levelTriggered = levelTriggered
        self.activeHigh = activeHigh
        self.interruptSharing = interruptSharing
        self.wakeCapable = wakeCapable
        self.longBuffer = true
    }

    func encode() -> AMLBuffer {
        var buffer: AMLBuffer = []
        buffer.append(UInt8(truncatingIfNeeded: irqMask.rawValue))
        buffer.append(UInt8(truncatingIfNeeded: irqMask.rawValue >> 8))
        if longBuffer {
            var bits = BitArray8(0)
            bits[0] = levelTriggered ? 0 : 1
            bits[3] = activeHigh ? 0 : 1
            bits[4] = Int(interruptSharing)
            bits[5] = Int(wakeCapable)
            buffer.append(bits.rawValue)
        }
        return buffer
    }

    func with(newIrq irq: Int) -> Self {
        let irqMask = UInt16(1 << irq)
        if longBuffer {
            return Self(irqMask: irqMask, levelTriggered: levelTriggered, activeHigh: activeHigh, interruptSharing: interruptSharing, wakeCapable: wakeCapable)
        } else {
            return Self(irqMask: irqMask)
        }
    }

    func interrupts() -> [IRQSetting] {
        var ints: [IRQSetting] = []
        for idx in 0..<16 {
            if irqMask[idx] != 0 {
                ints.append(IRQSetting(irq: UInt8(idx), activeHigh: activeHigh, levelTriggered: levelTriggered,
                                       shared: interruptSharing, wakeCapable: wakeCapable))
            }
        }
        return ints
    }
}

struct AMLDmaSetting: CustomStringConvertible, Equatable {
    let channelMask: BitArray8
    let flags: BitArray8
    var description: String {
        "DMA mask: \(channelMask.rawValue.binary(separators: true)) \(flags.rawValue.binary(separators: true))"
    }

    init(_ buffer: AMLBuffer) {
        precondition(buffer.count == 2)
        channelMask = BitArray8(buffer[0])
        flags = BitArray8(buffer[1])
    }

    init(channelMask: UInt8, flags: UInt8) {
        self.channelMask = BitArray8(channelMask)
        self.flags = BitArray8(flags)
    }

    func encode() -> AMLBuffer {
        var buffer: AMLBuffer = []
        buffer.append(channelMask.rawValue)
        buffer.append(flags.rawValue)
        return buffer
    }

    func channels() -> [UInt8] {
        var _channels: [UInt8] = []
        for idx in 0...7 {
            if channelMask[idx] != 0 {
                _channels.append(UInt8(idx))
            }
        }
        return _channels
    }
}


struct AMLIOPortSetting: CustomStringConvertible, Equatable {
    let decodes16Bit: Bool
    let minimumBaseAddress: UInt16
    let maximumBaseAddress: UInt16
    let baseAlignment: UInt8
    let rangeLength: UInt8
    var description: String {
        "IOPort: 0x\(minimumBaseAddress.hex())"
    }

    init(_ buffer: AMLBuffer) {
        precondition(buffer.count == 7)

        if buffer[0] == 0 {
            decodes16Bit = false
        } else if buffer[0] == 1 {
            decodes16Bit = true
        } else {
            fatalError("Invalid byte0 for IOPort: \(buffer[0])")
        }
        minimumBaseAddress = UInt16(withBytes: buffer[1], buffer[2])
        maximumBaseAddress = UInt16(withBytes: buffer[3], buffer[4])
        baseAlignment = buffer[5]
        rangeLength = buffer[6]
    }

    func encode() -> AMLBuffer {
        var buffer: AMLBuffer = []
        buffer.append(decodes16Bit ? 1 : 0)
        buffer.append(UInt8(truncatingIfNeeded: minimumBaseAddress))
        buffer.append(UInt8(truncatingIfNeeded: minimumBaseAddress >> 8))
        buffer.append(UInt8(truncatingIfNeeded: maximumBaseAddress))
        buffer.append(UInt8(truncatingIfNeeded: maximumBaseAddress >> 8))
        buffer.append(baseAlignment)
        buffer.append(rangeLength)
        return buffer
    }

    func ioPorts() -> ClosedRange<UInt16> {
        let mask: UInt16 = decodes16Bit ? 0xffff : 0x03ff
        let start = minimumBaseAddress & mask
        let end = (minimumBaseAddress + UInt16(rangeLength - 1)) & mask
        return start...end
    }
}


struct AMLMemoryRangeDescriptor: CustomStringConvertible, Equatable {
    let writeable: Bool
    let minimumBaseAddress: UInt32
    let maximumBaseAddress: UInt32
    let baseAlignment: UInt32
    let rangeLength: UInt32
    var description: String {
        "MemoryRange: 0x\(minimumBaseAddress.hex())"
    }

    init(_ buffer: AMLBuffer) {
        guard buffer.count == 17 else {
            fatalError("AMLMemoryRangeDescriptor count (\(buffer.count)) != 17")
        }
        writeable = (buffer[0] == 1)
        minimumBaseAddress = UInt32(withBytes: buffer[1], buffer[2], buffer[3], buffer[4])
        maximumBaseAddress = UInt32(withBytes: buffer[5], buffer[6], buffer[7], buffer[8])
        baseAlignment = UInt32(withBytes: buffer[9], buffer[10], buffer[11], buffer[12])
        rangeLength = UInt32(withBytes: buffer[13], buffer[14], buffer[15], buffer[16])
    }

    func encode() -> AMLBuffer {
        var buffer: AMLBuffer = []
        buffer.reserveCapacity(17)
        buffer.append(writeable ? 1 : 0)
        let minAddress = ByteArray4(minimumBaseAddress)
        buffer.append(minAddress[0])
        buffer.append(minAddress[1])
        buffer.append(minAddress[2])
        buffer.append(minAddress[3])

        let maxAddress = ByteArray4(maximumBaseAddress)
        buffer.append(maxAddress[0])
        buffer.append(maxAddress[1])
        buffer.append(maxAddress[2])
        buffer.append(maxAddress[3])

        let alignment = ByteArray4(baseAlignment)
        buffer.append(alignment[0])
        buffer.append(alignment[1])
        buffer.append(alignment[2])
        buffer.append(alignment[3])

        let rLength = ByteArray4(rangeLength)
        buffer.append(rLength[0])
        buffer.append(rLength[1])
        buffer.append(rLength[2])
        buffer.append(rLength[3])
        return buffer
    }

}


struct AMLFixedMemoryRangeDescriptor: CustomStringConvertible, Equatable {
    let writeable: Bool
    let baseAddress: UInt32
    let rangeLength: UInt32
    var description: String {
        "FixedMemory: 0x\(baseAddress.hex())"
    }

    init(_ buffer: AMLBuffer) {
        guard buffer.count == 9 else {
            fatalError("AMLFixedMemoryRangeDescriptor count (\(buffer.count)) != 9")
        }
        writeable = (buffer[0] == 1)
        baseAddress = UInt32(withBytes: buffer[1], buffer[2], buffer[3], buffer[4])
        rangeLength = UInt32(withBytes: buffer[5], buffer[6], buffer[7], buffer[8])
    }

    func encode() -> AMLBuffer {
        var buffer: AMLBuffer = []
        buffer.reserveCapacity(9)
        buffer.append(writeable ? 1 : 0)
        let base = ByteArray4(baseAddress)
        buffer.append(base[0])
        buffer.append(base[1])
        buffer.append(base[2])
        buffer.append(base[3])

        let rLength = ByteArray4(rangeLength)
        buffer.append(rLength[0])
        buffer.append(rLength[1])
        buffer.append(rLength[2])
        buffer.append(rLength[3])
        return buffer
    }
}

struct AMLIrqExtendedDescriptor: CustomStringConvertible, Equatable {
    private let flags: BitArray8
    private let intNumbers: [UInt8]
    var description: String {
        let ints = intNumbers.map { "0x\($0.hex())" }.joined(separator: ",")
        return "IRQ: \(ints) level: (levelTriggered): activeHigh: \(activeHigh) sharing: \(interruptSharing)"
    }

    var isResourceProducer: Bool { return flags[0] == 0 }
    var levelTriggered:     Bool { return flags[1] == 0 }
    var activeHigh:         Bool { return flags[2] == 0 }
    var interruptSharing:   Bool { return flags[3] == 1 }
    var wakeCapable:        Bool { return flags[4] == 1 }


    init(_ buffer: AMLBuffer) {
        precondition(buffer.count >= 6)
        flags = BitArray8(buffer[0])
        let intCount = Int(buffer[1])
        precondition(intCount > 0)
        precondition(buffer.count >= (intCount * 4) + 2)

        var _intNumbers: [UInt8] = []
        _intNumbers.reserveCapacity(intCount)
        for int in 0..<intCount {
            let idx = (int * 4) + 2
            let irq = UInt32(withBytes: buffer[idx], buffer[idx + 1], buffer[idx + 2], buffer[idx + 3])
            _intNumbers.append(UInt8(irq))
        }
        intNumbers = _intNumbers
    }

    func encode() -> AMLBuffer {
        var buffer: AMLBuffer = []
        buffer.append(flags.rawValue)
        buffer.append(UInt8(intNumbers.count))
        for interrupt in intNumbers {
            buffer.append(interrupt)
            buffer.append(0)
            buffer.append(0)
            buffer.append(0)
        }
        return buffer
    }

    func interrupts() -> [IRQSetting] {
        var ints: [IRQSetting] = []
        for int in intNumbers {
            ints.append(IRQSetting(irq: int, activeHigh: activeHigh, levelTriggered: levelTriggered,
                                   shared: interruptSharing, wakeCapable: wakeCapable))
        }
        return ints
    }
}


struct AMLWordAddressSpaceDescriptor: CustomStringConvertible, Equatable {
    enum ResourceType: UInt8 {
        case memoryRange    = 0
        case ioRange        = 1
        case busNumberRange = 2
        //   3-191 reserved
        // 192-255 hardware vendor defined
    }

    var description: String {
        switch self.resourceType {
        case .memoryRange:
            return "Word Memory [0x\(addressRangeMinimum.hex())-0x\(addressRangeMaximum.hex())]"
        case .ioRange:
            return "Word IO [0x\(addressRangeMinimum.hex())-0x\(addressRangeMaximum.hex())]"
        case .busNumberRange:
            return "Word Bus [0x\(addressRangeMinimum.hex())-0x\(addressRangeMaximum.hex())]"
        }
    }

    let resourceType: ResourceType
    let generalFlags: BitArray8
    let typeSpecificFlags: BitArray8
    let addressSpaceGranularity: UInt16     // _GRA
    let addressRangeMinimum: UInt16         // _MIN
    let addressRangeMaximum: UInt16         // _MAX
    let addressTranslationOffset: UInt16    // _TRA
    let addressLength: UInt16               // _LEN
    let resourceSourceIndex: UInt8?
    let resourceSource: AMLNameString?

    // flags
    var isMaxAddressFixed: Bool { return generalFlags[3] == 1 } // _MAF
    var isMinAddressFixed: Bool { return generalFlags[2] == 1 } // _MIF
    var bridgeSubtractivelyDecodesAddress: Bool { return generalFlags[1] == 1 } // _DEC

    init(_ buffer: AMLBuffer) {
        precondition(buffer.count >= 13)
        resourceType = ResourceType(rawValue: buffer[0])!
        generalFlags = BitArray8(buffer[1])
        typeSpecificFlags = BitArray8(buffer[2])
        addressSpaceGranularity = UInt16(withBytes: buffer[3], buffer[4])
        addressRangeMinimum = UInt16(withBytes: buffer[5], buffer[6])
        addressRangeMaximum = UInt16(withBytes: buffer[7], buffer[8])
        addressTranslationOffset = UInt16(withBytes: buffer[9], buffer[10])
        addressLength = UInt16(withBytes: buffer[11], buffer[12])
        if buffer.count > 17 { // buffer may have extra data or be incomplete so check there is enough
            resourceSourceIndex = buffer[13]
            resourceSource = AMLNameString(buffer: buffer[14...17])
        } else {
            resourceSourceIndex = nil
            resourceSource = nil
        }
    }

    func encode() -> AMLBuffer {
        var buffer: AMLBuffer = []
        buffer.reserveCapacity(18)
        buffer.append(resourceType.rawValue)
        buffer.append(generalFlags.rawValue)
        buffer.append(typeSpecificFlags.rawValue)
        buffer.append(UInt8(truncatingIfNeeded: addressSpaceGranularity))
        buffer.append(UInt8(truncatingIfNeeded: addressSpaceGranularity >> 8))
        buffer.append(UInt8(truncatingIfNeeded: addressRangeMinimum))
        buffer.append(UInt8(truncatingIfNeeded: addressRangeMinimum >> 8))
        buffer.append(UInt8(truncatingIfNeeded: addressRangeMaximum))
        buffer.append(UInt8(truncatingIfNeeded: addressRangeMaximum >> 8))
        buffer.append(UInt8(truncatingIfNeeded: addressTranslationOffset))
        buffer.append(UInt8(truncatingIfNeeded: addressTranslationOffset >> 8))
        buffer.append(UInt8(truncatingIfNeeded: addressLength))
        buffer.append(UInt8(truncatingIfNeeded: addressLength >> 8))
        if let resourceSourceIndex, let resourceSource {
            buffer.append(resourceSourceIndex)
            guard let string = resourceSource.stringValue?.asAMLBuffer(), string.count == 4 else {
                fatalError("resourceSource is not a string of 4 characters")
            }
            buffer.append(contentsOf: string)
        }
        return buffer
    }
}

struct AMLDWordAddressSpaceDescriptor: CustomStringConvertible, Equatable {
    enum ResourceType: UInt8 {
        case memoryRange    = 0
        case ioRange        = 1
        case busNumberRange = 2
        //   3-191 reserved
        // 192-255 hardware vendor defined
    }

    var description: String {
        switch self.resourceType {
        case .memoryRange:
            return "DWord Memory [0x\(addressRangeMinimum.hex())-0x\(addressRangeMaximum.hex())]"
        case .ioRange:
            return "DWord IO [0x\(addressRangeMinimum.hex())-0x\(addressRangeMaximum.hex())]"
        case .busNumberRange:
            return "DWord Bus [0x\(addressRangeMinimum.hex())-0x\(addressRangeMaximum.hex())]"
        }
    }

    let resourceType: ResourceType
    let generalFlags: BitArray8
    let typeSpecificFlags: BitArray8
    let addressSpaceGranularity: UInt32     // _GRA
    let addressRangeMinimum: UInt32         // _MIN
    let addressRangeMaximum: UInt32         // _MAX
    let addressTranslationOffset: UInt32    // _TRA
    let addressLength: UInt32               // _LEN
    let resourceSourceIndex: UInt8?
    let resourceSource: AMLNameString?

    // flags
    var isMaxAddressFixed: Bool { return generalFlags[3] == 1 } // _MAF
    var isMinAddressFixed: Bool { return generalFlags[2] == 1 } // _MIF
    var bridgeSubtractivelyDecodesAddress: Bool { return generalFlags[1] == 1 } // _DEC

    init(_ buffer: AMLBuffer) {
        precondition(buffer.count >= 23)
        resourceType = ResourceType(rawValue: buffer[0])!
        generalFlags = BitArray8(buffer[1])
        typeSpecificFlags = BitArray8(buffer[2])
        addressSpaceGranularity = UInt32(withBytes: buffer[3], buffer[4], buffer[5], buffer[6])
        addressRangeMinimum = UInt32(withBytes: buffer[7], buffer[8], buffer[9], buffer[10])
        addressRangeMaximum = UInt32(withBytes: buffer[11], buffer[12], buffer[13], buffer[14])
        addressTranslationOffset = UInt32(withBytes: buffer[15], buffer[16], buffer[17], buffer[18])
        addressLength = UInt32(withBytes: buffer[19], buffer[20], buffer[21], buffer[22])
        if buffer.count > 27 {
            resourceSourceIndex = buffer[23]
            resourceSource = AMLNameString(buffer: buffer[24...27])
        } else {
            resourceSourceIndex = nil
            resourceSource = nil
        }
    }

    func encode() -> AMLBuffer {
        var buffer: AMLBuffer = []
        buffer.reserveCapacity(28)
        buffer.append(resourceType.rawValue)
        buffer.append(generalFlags.rawValue)
        buffer.append(typeSpecificFlags.rawValue)

        let asg = ByteArray4(addressSpaceGranularity)
        buffer.append(asg[0])
        buffer.append(asg[1])
        buffer.append(asg[2])
        buffer.append(asg[3])

        let armin = ByteArray4(addressRangeMinimum)
        buffer.append(armin[0])
        buffer.append(armin[1])
        buffer.append(armin[2])
        buffer.append(armin[3])

        let armax = ByteArray4(addressRangeMaximum)
        buffer.append(armax[0])
        buffer.append(armax[1])
        buffer.append(armax[2])
        buffer.append(armax[3])

        let ato = ByteArray4(addressTranslationOffset)
        buffer.append(ato[0])
        buffer.append(ato[1])
        buffer.append(ato[2])
        buffer.append(ato[3])

        let al = ByteArray4(addressLength)
        buffer.append(al[0])
        buffer.append(al[1])
        buffer.append(al[2])
        buffer.append(al[3])

        if let resourceSourceIndex, let resourceSource {
            buffer.append(resourceSourceIndex)
            guard let string = resourceSource.stringValue?.asAMLBuffer(), string.count == 4 else {
                fatalError("resourceSource is not a string of 4 characters")
            }
            buffer.append(contentsOf: string)
        }
        return buffer
    }
}


struct AMLQWordAddressSpaceDescriptor: CustomStringConvertible, Equatable {
    enum ResourceType: UInt8 {
        case memoryRange    = 0
        case ioRange        = 1
        case busNumberRange = 2
        //   3-191 reserved
        // 192-255 hardware vendor defined
    }

    var description: String {
        switch self.resourceType {
        case .memoryRange:
            return "QWord Memory [0x\(addressRangeMinimum.hex())-0x\(addressRangeMaximum.hex())]"
        case .ioRange:
            return "QWord IO [0x\(addressRangeMinimum.hex())-0x\(addressRangeMaximum.hex())]"
        case .busNumberRange:
            return "QWord Bus [0x\(addressRangeMinimum.hex())-0x\(addressRangeMaximum.hex())]"
        }
    }

    let resourceType: ResourceType
    let generalFlags: BitArray8
    let typeSpecificFlags: BitArray8
    let addressSpaceGranularity: UInt64     // _GRA
    let addressRangeMinimum: UInt64         // _MIN
    let addressRangeMaximum: UInt64         // _MAX
    let addressTranslationOffset: UInt64    // _TRA
    let addressLength: UInt64               // _LEN
    let resourceSourceIndex: UInt8?
    let resourceSource: AMLNameString?

    // flags
    var isMaxAddressFixed: Bool { return generalFlags[3] == 1 } // _MAF
    var isMinAddressFixed: Bool { return generalFlags[2] == 1 } // _MIF
    var bridgeSubtractivelyDecodesAddress: Bool { return generalFlags[1] == 1 } // _DEC

    init(_ buffer: AMLBuffer) {
        precondition(buffer.count >= 43)
        resourceType = ResourceType(rawValue: buffer[0])!
        generalFlags = BitArray8(buffer[1])
        typeSpecificFlags = BitArray8(buffer[2])
        addressSpaceGranularity = UInt64(withBytes: Array(buffer[3...10]))
        addressRangeMinimum = UInt64(withBytes: Array(buffer[11...18]))
        addressRangeMaximum = UInt64(withBytes: Array(buffer[19...26]))
        addressTranslationOffset = UInt64(withBytes: Array(buffer[27...34]))
        addressLength = UInt64(withBytes: Array(buffer[35...42]))
        if buffer.count > 47 {
            resourceSourceIndex = buffer[43]
            resourceSource = AMLNameString(buffer: buffer[44...47])
        } else {
            resourceSourceIndex = nil
            resourceSource = nil
        }
    }

    func encode() -> AMLBuffer {
        var buffer: AMLBuffer = []
        buffer.reserveCapacity(48)
        buffer.append(resourceType.rawValue)
        buffer.append(generalFlags.rawValue)
        buffer.append(typeSpecificFlags.rawValue)

        for data in ByteArray8(addressSpaceGranularity) {
            buffer.append(data)
        }

        for data in ByteArray8(addressRangeMinimum) {
            buffer.append(data)
        }

        for data in ByteArray8(addressRangeMaximum) {
            buffer.append(data)
        }

        for data in ByteArray8(addressTranslationOffset) {
            buffer.append(data)
        }

        for data in ByteArray8(addressLength) {
            buffer.append(data)
        }

        if let resourceSourceIndex, let resourceSource {
            buffer.append(resourceSourceIndex)
            guard let string = resourceSource.stringValue?.asAMLBuffer(), string.count == 4 else {
                fatalError("resourceSource is not a string of 4 characters")
            }
            buffer.append(contentsOf: string)
        }
        return buffer
    }
}


func decodeResourceData(_ buffer: AMLBuffer) -> [AMLResourceSetting] {
    precondition(buffer.count > 0)

    var settings: [AMLResourceSetting] = []

    var idx = 0
    while idx < buffer.count {
        let header = BitArray8(buffer[idx])
        idx += 1
        let setting: AMLResourceSetting
        let length: Int

        if header[7] == 1 {
            // Large Type
            let itemName = header[0...6]
            guard let type = AMLLargeItemName(rawValue: itemName) else {
                fatalError("Invalid AMLLargeItemName: \(itemName)")
            }

            assert(idx + 2 < buffer.count)
            length = Int(UInt16(withBytes: buffer[idx], buffer[idx+1]))
            idx += 2
            let buf = AMLBuffer(buffer[idx..<idx + length])

            switch type {
                case .memoryRangeDescriptor32Bit:
                    setting = .memoryRangeDescriptor(AMLMemoryRangeDescriptor(buf))

                case .fixedLocationMemoryRangeDescriptor32Bit:
                    setting = .fixedMemoryRangeDescriptor(AMLFixedMemoryRangeDescriptor(buf))

                case .extendedIRQDescriptor:
                    setting = .extendedIrqSetting(AMLIrqExtendedDescriptor(buf))

                case .wordAddressSpaceDescriptor:
                    setting = .wordAddressSpaceDescriptor(AMLWordAddressSpaceDescriptor(buf))

                case .dwordAddressSpaceDescriptor:
                    setting = .dwordAddressSpaceDescriptor(AMLDWordAddressSpaceDescriptor(buf))

                case .qwordAddressSpaceDescriptor:
                    setting = .qwordAddressSpaceDescriptor(AMLQWordAddressSpaceDescriptor(buf))

                default: fatalError("Cant decode type: \(type)")
            }
        } else {
            // Small Type
            let itemName = header[3...6]
            guard let type = AMLSmallItemName(rawValue: itemName) else {
                fatalError("Invalid AMLSmallItemnName: \(itemName)")
            }
            length = Int(header[0...2])
            let buf = AMLBuffer(buffer[idx..<idx + length])

            switch type {
                case .irqFormatDescriptor:  setting = .irqSetting(AMLIrqSetting(buf))
                case .dmaFormatDescriptor:  setting = .dmaSetting(AMLDmaSetting(buf))
                case .ioPortDescriptor:     setting = .ioPortSetting(AMLIOPortSetting(buf))
                case .endTagDescriptor:
                    let checksum = buffer[idx]
                    if checksum != 0 {
                        // checksum of 0 == ignore and assume its ok otherwise check it
                        let computedCSum = buffer[0..<idx].reduce(0, &+)
                        if checksum &+ computedCSum != 0 {
                            fatalError("Checksum does not compute")
                        }
                    }
                    let encodedSettings = encodeResourceData(settings)
                    //TODO: Remove, this is just for checking the encoding
                    if buffer[0..<buffer.count - 2] != encodedSettings[0..<encodedSettings.count - 2] {
                        fatalError("Encoded Settings do not match")
                    }
                    return settings

                default: fatalError("Cant decode type: \(type)")
            }
        }
        settings.append(setting)
        idx += length
    }
    #kprint("ACPI: Warning: no EndTagDescriptor")
    return settings
}

func encodeResourceData(_ resources: [AMLResourceSetting]) -> AMLBuffer {

    var buffer: AMLBuffer = []

    for resource in resources {
        var largeItem: AMLLargeItemName?
        var smallItem: AMLSmallItemName?
        let encoding: AMLBuffer
        switch resource {
            case .irqSetting(let irqSetting):
                smallItem = .irqFormatDescriptor
                encoding = irqSetting.encode()

            case .extendedIrqSetting(let irqExtendedDescriptor):
                largeItem = .extendedIRQDescriptor
                encoding = irqExtendedDescriptor.encode()

            case .dmaSetting(let dmaSetting):
                smallItem = .dmaFormatDescriptor
                encoding = dmaSetting.encode()

            case .ioPortSetting(let ioPortSetting):
                smallItem = .ioPortDescriptor
                encoding = ioPortSetting.encode()

            case .memoryRangeDescriptor(let memoryRangeDescriptor):
                largeItem = .memoryRangeDescriptor32Bit
                encoding = memoryRangeDescriptor.encode()

            case .fixedMemoryRangeDescriptor(let fixedMemoryRangeDescriptor):
                largeItem = .fixedLocationMemoryRangeDescriptor32Bit
                encoding = fixedMemoryRangeDescriptor.encode()

            case .wordAddressSpaceDescriptor(let wordAddressSpaceDescriptor):
                largeItem = .wordAddressSpaceDescriptor
                encoding = wordAddressSpaceDescriptor.encode()

            case .dwordAddressSpaceDescriptor(let dwordAddressSpaceDescriptor):
                largeItem = .dwordAddressSpaceDescriptor
                encoding = dwordAddressSpaceDescriptor.encode()

            case .qwordAddressSpaceDescriptor(let qwordAddressSpaceDescriptor):
                largeItem = .qwordAddressSpaceDescriptor
                encoding = qwordAddressSpaceDescriptor.encode()
        }

        let encodingLength = encoding.count
        if let largeItem {
            var header = BitArray8()
            header[7] = 1
            header[0...6] = largeItem.rawValue
            buffer.append(header.rawValue)
            buffer.append(UInt8(truncatingIfNeeded: encodingLength))
            buffer.append(UInt8(truncatingIfNeeded: encodingLength >> 8))
        } else if let smallItem {
            var header = BitArray8()
            header[3...6] = smallItem.rawValue
            header[0...2] = UInt8(encodingLength)
            buffer.append(header.rawValue)
        }
        buffer.append(contentsOf: encoding)
    }

    // Append End Tag
    var checksum = buffer.reduce(0, &+)
    checksum = ~checksum &+ 1
    checksum = 0
    var header = BitArray8()
    header[3...6] = AMLSmallItemName.endTagDescriptor.rawValue
    header[0...2] = 1 // Length
    buffer.append(header.rawValue)
    buffer.append(checksum)
    return buffer
}
