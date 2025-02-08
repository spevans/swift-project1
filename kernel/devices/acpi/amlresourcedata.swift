//
//  kernel/devices/acpi/amlresourcedata.swift
//
//  Created by Simon Evans on 02/12/2017.
//  Copyright © 2017 - 2019 Simon Evans. All rights reserved.
//
//  Current Resource Settings (_CRS) decoding.

enum AMLResourceSetting: CustomStringConvertible {
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


struct AMLIrqSetting: CustomStringConvertible {
    let irqMask: BitArray16
    let levelTriggered: Bool
    let activeHigh: Bool
    let interruptSharing: Bool
    let wakeCapable: Bool
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
        } else {
            levelTriggered = false // edge triggered
            activeHigh = true
            interruptSharing = false
            wakeCapable = false
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

struct AMLDmaSetting: CustomStringConvertible {
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


struct AMLIOPortSetting: CustomStringConvertible {
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

    func ioPorts() -> ClosedRange<UInt16> {
        let mask: UInt16 = decodes16Bit ? 0xffff : 0x03ff
        let start = minimumBaseAddress & mask
        let end = (minimumBaseAddress + UInt16(rangeLength - 1)) & mask
        return start...end
    }
}


struct AMLMemoryRangeDescriptor: CustomStringConvertible {
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
}


struct AMLFixedMemoryRangeDescriptor: CustomStringConvertible {
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
}

struct AMLIrqExtendedDescriptor: CustomStringConvertible {
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

    func interrupts() -> [IRQSetting] {
        var ints: [IRQSetting] = []
        for int in intNumbers {
            ints.append(IRQSetting(irq: int, activeHigh: activeHigh, levelTriggered: levelTriggered,
                                   shared: interruptSharing, wakeCapable: wakeCapable))
        }
        return ints
    }
}


struct AMLWordAddressSpaceDescriptor: CustomStringConvertible {
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
    let addressTranslationOffet: UInt16     // _TRA
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
        addressTranslationOffet = UInt16(withBytes: buffer[9], buffer[10])
        addressLength = UInt16(withBytes: buffer[11], buffer[12])
        if buffer.count > 17 { // buffer may have extra data or be incomplete so check there is enough
            resourceSourceIndex = buffer[13]
            resourceSource = AMLNameString(buffer: buffer[14...17])
        } else {
            resourceSourceIndex = nil
            resourceSource = nil
        }
    }
}

struct AMLDWordAddressSpaceDescriptor: CustomStringConvertible {
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
    let addressTranslationOffet: UInt32     // _TRA
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
        addressTranslationOffet = UInt32(withBytes: buffer[15], buffer[16], buffer[17], buffer[18])
        addressLength = UInt32(withBytes: buffer[19], buffer[20], buffer[21], buffer[22])
        if buffer.count > 27 {
            resourceSourceIndex = buffer[23]
            resourceSource = AMLNameString(buffer: buffer[24...27])
        } else {
            resourceSourceIndex = nil
            resourceSource = nil
        }
    }
}


struct AMLQWordAddressSpaceDescriptor: CustomStringConvertible {
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
    let addressTranslationOffet: UInt64     // _TRA
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
        addressTranslationOffet = UInt64(withBytes: Array(buffer[27...34]))
        addressLength = UInt64(withBytes: Array(buffer[35...42]))
        if buffer.count > 47 {
            resourceSourceIndex = buffer[43]
            resourceSource = AMLNameString(buffer: buffer[44...47])
        } else {
            resourceSourceIndex = nil
            resourceSource = nil
        }
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
            case .endTagDescriptor:     return settings     // FIXME: Process the checksum

            default: fatalError("Cant decode type: \(type)")
            }
        }
        settings.append(setting)
        idx += length
    }
    print("Warning: no EndTagDescriptor")
    return settings
}
