//
//  kernel/devices/acpi/amlresourcedata.swift
//
//  Created by Simon Evans on 02/12/2017.
//  Copyright © 2017 - 2019 Simon Evans. All rights reserved.
//
//  Current Resource Settings (_CRS) decoding.


protocol AMLResourceSetting {
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


struct AMLIrqSetting: AMLResourceSetting {
    let irqMask: BitArray16
    let levelTriggered: Bool
    let activeHigh: Bool
    let interruptSharing: Bool
    let wakeCapable: Bool


    init(_ buffer: AMLByteList) {
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


    func interrupts() -> [UInt8] {
        var ints: [UInt8] = []
        for idx in 0..<16 {
            if irqMask[idx] != 0 {
                ints.append(UInt8(idx))
            }
        }
        return ints
    }
}

struct AMLDmaSetting: AMLResourceSetting {
    let channelMask: BitArray8
    let flags: BitArray8

    init(_ buffer: AMLByteList) {
        precondition(buffer.count == 2)
        channelMask = BitArray8(buffer[0])
        flags = BitArray8(buffer[1])
    }
}


struct AMLIOPortSetting: AMLResourceSetting {
    let decodes16Bit: Bool
    let minimumBaseAddress: UInt16
    let maximumBaseAddress: UInt16
    let baseAlignment: UInt8
    let rangeLength: UInt8

    init(_ buffer: AMLByteList) {
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


struct AMLMemoryRangeDescriptor: AMLResourceSetting {
    let writeable: Bool
    let minimumBaseAddress: UInt32
    let maximumBaseAddress: UInt32
    let baseAlignment: UInt32
    let rangeLength: UInt32

    init(_ buffer: AMLByteList) {
        precondition(buffer.count == 17)
        writeable = (buffer[0] == 1)
        minimumBaseAddress = UInt32(withBytes: buffer[1], buffer[2], buffer[3], buffer[4])
        maximumBaseAddress = UInt32(withBytes: buffer[5], buffer[6], buffer[7], buffer[8])
        baseAlignment = UInt32(withBytes: buffer[9], buffer[10], buffer[11], buffer[12])
        rangeLength = UInt32(withBytes: buffer[13], buffer[14], buffer[15], buffer[16])
    }
}


struct AMLFixedMemoryRangeDescriptor: AMLResourceSetting {
    let writeable: Bool
    let baseAddress: UInt32
    let rangeLength: UInt32

    init(_ buffer: AMLByteList) {
        precondition(buffer.count == 9)
        writeable = (buffer[0] == 1)
        baseAddress = UInt32(withBytes: buffer[1], buffer[2], buffer[3], buffer[4])
        rangeLength = UInt32(withBytes: buffer[5], buffer[6], buffer[7], buffer[8])
    }
}

struct AMLIrqExtendedDescriptor: AMLResourceSetting {
    let flags: BitArray8
    let intNumbers: [UInt32]

    var isResourceProducer: Bool { return flags[0] == 0 }
    var levelTriggered:     Bool { return flags[1] == 0 }
    var activeHigh:         Bool { return flags[2] == 0 }
    var interruptSharing:   Bool { return flags[3] == 1 }
    var wakeCapable:        Bool { return flags[4] == 1 }


    init(_ buffer: AMLByteList) {
        precondition(buffer.count >= 2)
        flags = BitArray8(buffer[0])
        let intCount = Int(buffer[1])
        var interrupts: [UInt32] = []
        interrupts.reserveCapacity(intCount)
        for int in 0..<intCount {
            let idx = (int * 4) + 2
            let irq = UInt32(withBytes: buffer[idx], buffer[idx + 1],
                             buffer[idx + 2], buffer[idx + 3])
            interrupts.append(irq)
        }
        intNumbers = interrupts
    }
}


struct AMLWordAddressSpaceDescriptor: AMLResourceSetting {
    enum ResourceType: UInt8 {
        case memoryRange    = 0
        case ioRange        = 1
        case busNumberRange = 2
        //   3-191 reserved
        // 192-255 hardware vendor defined
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

    init(_ buffer: AMLByteList) {
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

struct AMLDWordAddressSpaceDescriptor: AMLResourceSetting {
    enum ResourceType: UInt8 {
        case memoryRange    = 0
        case ioRange        = 1
        case busNumberRange = 2
        //   3-191 reserved
        // 192-255 hardware vendor defined
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

    init(_ buffer: AMLByteList) {
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


struct AMLQWordAddressSpaceDescriptor: AMLResourceSetting {
    enum ResourceType: UInt8 {
        case memoryRange    = 0
        case ioRange        = 1
        case busNumberRange = 2
        //   3-191 reserved
        // 192-255 hardware vendor defined
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

    init(_ buffer: AMLByteList) {
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
    guard let len = (buffer.size as? AMLIntegerData)?.value else {
        fatalError("Cant get buffer size")
    }
    precondition(len > 0)

    var settings: [AMLResourceSetting] = []

    var idx = 0
    while idx < buffer.data.count {
        let header = BitArray8(buffer.data[idx])
        idx += 1
        let setting: AMLResourceSetting
        let length: Int

        if header[7] == 1 {
            // Large Type
            let itemName = header[0...6]
            guard let type = AMLLargeItemName(rawValue: itemName) else {
                fatalError("Invalid AMLLargeItemName: \(itemName)")
            }

            assert(idx + 2 < buffer.data.count)
            length = Int(UInt16(withBytes: buffer.data[idx], buffer.data[idx+1]))
            idx += 2
            let buf = AMLByteList(buffer.data[idx..<idx + length])

            switch type {
            case .memoryRangeDescriptor32Bit:               setting = AMLMemoryRangeDescriptor(buf)
            case .fixedLocationMemoryRangeDescriptor32Bit:  setting = AMLFixedMemoryRangeDescriptor(buf)
            case .dwordAddressSpaceDescriptor:              setting = AMLDWordAddressSpaceDescriptor(buf)
            case .wordAddressSpaceDescriptor:               setting = AMLWordAddressSpaceDescriptor(buf)
            case .extendedIRQDescriptor:                    setting = AMLIrqExtendedDescriptor(buf)
            case .qwordAddressSpaceDescriptor:              setting = AMLQWordAddressSpaceDescriptor(buf)

            default: fatalError("Cant decode type: \(type)")
            }
        } else {
            // Small Type
            let itemName = header[3...6]
            guard let type = AMLSmallItemName(rawValue: itemName) else {
                fatalError("Invalid AMLSmallItemnName: \(itemName)")
            }
            length = Int(header[0...2])
            let buf = AMLByteList(buffer.data[idx..<idx + length])

            switch type {
            case .irqFormatDescriptor:  setting = AMLIrqSetting(buf)
            case .dmaFormatDescriptor:  setting = AMLDmaSetting(buf)
            case .ioPortDescriptor:     setting = AMLIOPortSetting(buf)
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

