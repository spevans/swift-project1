/*
 * kernel/devices/acpi/amldefopregion.swift
 *
 * Created by Simon Evans on 14/11/2025.
 * Copyright © 2025 Simon Evans. All rights reserved.
 *
 * ACPI Operation Region.
 *
 */


final class AMLDefOpRegion {
    // OpRegionOp NameString RegionSpace RegionOffset RegionLen
    private let fullname: AMLNameString
    private let regionType: AMLRegionSpace
    private let offsetArg: AMLTermArg
    private let lengthArg: AMLTermArg
    private var offset: AMLInteger = 0
    private var length: AMLInteger = 0


    var description: String {
        #sprintf("OpRegion: %s: %s offset: %0x08x-%0x08x",
                 fullname.value, regionType.description, offset, offset + length - 1)
    }

    init(fullname: AMLNameString, regionType: AMLRegionSpace, offset: AMLTermArg, length: AMLTermArg) throws (AMLError) {
        self.fullname = fullname
        self.regionType = regionType
        self.offsetArg = offset
        self.lengthArg = length
    }

    // TODO: This could probably be cached if the offsetArg and lengthArg are constants and dont need evaluation
    // TODO: Can invalid offset/length be passed at time of creation. I have seen a systemIO port
    // at offset/length 0xffff/0xffff when evaluating registers could this be a bug or just mean
    // its inaccessible?
    private func getRegionSpace(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> OpRegionSpace {
        guard let offset = try self.offsetArg.evaluate(context: &context).integerValue,
              let length = try self.lengthArg.evaluate(context: &context).integerValue else {
            throw AMLError.invalidData(reason: "OpRegion \(self.fullname) offset/length do not evaluate to integers")
        }
        self.offset = offset
        self.length = length
        let region = try OpRegionSpace(self.fullname, self.regionType, offset, length)
        if ACPIDebug {
            #kprintf("acpi: Setting up OpRegion %s, type: %s, offset: 0x%x length: 0x%x\n", fullname.value,
                     region.description, offset, length)
        }
        return region
    }


    private func read(_ regionSpace: borrowing OpRegionSpace, atIndex index: AMLInteger, _ flags: AMLFieldFlags) throws(AMLError) -> AMLInteger {

        let byteCount = AMLInteger(flags.fieldAccessType.accessWidth / 8)
        guard index < (self.length / byteCount) else {
            throw AMLError.invalidIndex(index: index, bound: self.length)
        }
        let index = Int(index)

        switch flags.fieldAccessType {
            case .ByteAcc, .AnyAcc, .BufferAcc: return AMLInteger(regionSpace.read(atIndex: index) as UInt8)
            case .WordAcc: return AMLInteger(regionSpace.read(atIndex: index) as UInt16)
            case .DWordAcc: return AMLInteger(regionSpace.read(atIndex: index) as UInt32)
            case .QWordAcc: return AMLInteger(regionSpace.read(atIndex: index) as UInt64)
        }
    }

    @inline(never)
    private func write(_ regionSpace: borrowing OpRegionSpace, atIndex index: AMLInteger,
                       value: AMLInteger, _ flags: AMLFieldFlags) throws(AMLError) {
        let byteCount = AMLInteger(flags.fieldAccessType.accessWidth / 8)
        guard index < (self.length / byteCount) else {
            throw AMLError.invalidIndex(index: index, bound: self.length)
        }
        let index = Int(index)

        switch flags.fieldAccessType {
            case .ByteAcc, .AnyAcc, .BufferAcc:
                regionSpace.write(atIndex: index, value: UInt8(truncatingIfNeeded: value))
            case .WordAcc:
                regionSpace.write(atIndex: index, value: UInt16(truncatingIfNeeded: value))
            case .DWordAcc:
                regionSpace.write(atIndex: index, value: UInt32(truncatingIfNeeded: value))
            case .QWordAcc:
                regionSpace.write(atIndex: index, value: UInt64(truncatingIfNeeded: value))
        }
    }


    // LittleEndian read
    func read(fieldSettings: AMLFieldSettings, context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {

        let flags = fieldSettings.fieldFlags
        let bitOffset = Int(fieldSettings.bitOffset)
        let fieldBitWidth = Int(fieldSettings.bitWidth)
        var bitsRemaining = fieldBitWidth // This is just a check

        let regionSpace = try self.getRegionSpace(context: &context)
        if ACPIDebug {
            #kprintf("acpi: OpRegionSpace.read(bitOffset: %d, fieldBitWidth: %d, flags: %s) %s\n",
                     bitOffset, fieldBitWidth, flags.description, regionSpace.description)
        }
        precondition(bitOffset >= 0)
        precondition(fieldBitWidth >= 1)

        let accessWidth = flags.fieldAccessType.accessWidth
        let totalWidth = self.length * AMLInteger(accessWidth)
        if ACPIDebug {
            #kprintf("acpi: accessWidth: %d region length: %d totalWidth: %d ",
                     accessWidth, self.length, totalWidth)
        }
        precondition((bitOffset + fieldBitWidth) <= totalWidth)
        var storage = AMLBitStorage()

        // Read an unaligned start if needed, upto accessWidth
        var index = AMLInteger(bitOffset / accessWidth)
        let initialBit = bitOffset % accessWidth
        if initialBit != 0 {
            let initialBitCount = min(accessWidth - initialBit, fieldBitWidth)
            if ACPIDebug {
                #kprintf("acpi: reading initial bits index: %d initialBit: %d initialBitCount: %d\n",
                         index, initialBit, initialBitCount)
            }
            let elementMask = createMask(initialBit, (initialBitCount + initialBit - 1))
            var value = try self.read(regionSpace, atIndex: index, flags) & elementMask
            value >>= initialBit

            storage.append(value, bitWidth: initialBitCount)
            index += 1
            bitsRemaining -= initialBitCount
        }

        // Now read aligned
        while bitsRemaining >= accessWidth {
            if ACPIDebug {
                #kprintf("acpi: Reading aligned bits index: %d\n", index)
            }
            let value = try self.read(regionSpace, atIndex: index, flags)
            storage.append(value, bitWidth: accessWidth)
            index += 1
            bitsRemaining -= accessWidth
        }

        // Now read remaining bits
        if bitsRemaining > 0 {
            if ACPIDebug {
                #kprintf("acpi: Reading trailing bits: %d\n", bitsRemaining)
            }
            let elementMask = AMLInteger(maskFromBitCount: bitsRemaining)

            let value = try self.read(regionSpace, atIndex: index, flags) & elementMask
            storage.append(value, bitWidth: bitsRemaining)
        }

        if ACPIDebug {
            #kprintf("acpi: read result: 0x%016x\n", storage.result().integerValue ?? 0)
        }
        return storage.result()
    }

    // LittleEndian write
    func write(value: AMLObject, fieldSettings: AMLFieldSettings,
               context: inout ACPI.AMLExecutionContext) throws(AMLError) {

        let flags = fieldSettings.fieldFlags
        let fieldBitWidth = Int(fieldSettings.bitWidth)
        let bitOffset = Int(fieldSettings.bitOffset)

        precondition(bitOffset >= 0)
        precondition(fieldBitWidth >= 1)

        let regionSpace = try self.getRegionSpace(context: &context)
        if ACPIDebug {
            #kprintf("acpi: OpRegionSpace.read(bitOffset: %d, field width: %d, flags: %s) %s\n",
                     bitOffset, fieldBitWidth, flags.description, regionSpace.description)
        }

        let accessWidth = flags.fieldAccessType.accessWidth

        // Number of bits up until the first accessWidth aligned write
        let initialBit = bitOffset % accessWidth
        var index = AMLInteger(bitOffset / accessWidth)

        var bitsRemaining = fieldBitWidth // This is just a check
        var iterator = try AMLByteIterator(value, totalBits: fieldBitWidth)
        // Possible non-access width head
        if initialBit > 0 {
            // bits in the firest non aligned field
            let initialBitCount = min(accessWidth - initialBit, fieldBitWidth)
            guard var head = iterator.nextBits(initialBitCount) else {
                throw AMLError.invalidData(reason: "Expected \(initialBitCount) bits but reached end of value")
            }
            head <<= initialBit
            bitsRemaining -= initialBitCount
            // Mask from the first bit to the last which may not end on an aligned boundary
            // eg if the width of the destination is only a few bits
            let elementMask = ~createMask(initialBit, (initialBitCount + initialBit - 1))
            let valueToWrite: AMLInteger
            switch flags.updateRule {
                case .Preserve:
                    let curValue = try self.read(regionSpace, atIndex: index, flags) & elementMask
                    valueToWrite = curValue | head

                case .WriteAsOnes:
                    valueToWrite = head | elementMask

                case .WriteAsZeros:
                    valueToWrite = head
            }
            try self.write(regionSpace, atIndex: index, value: valueToWrite, flags)
            index += 1
        }

        // Multiple access width parts
        while let nextValue = iterator.nextBits(accessWidth) {
            try self.write(regionSpace, atIndex: index, value: nextValue, flags)
            index += 1
            bitsRemaining -= accessWidth
        }

        // Checking
        if bitsRemaining != iterator.bitsRemaining {
            fatalError("Iterator has \(iterator.bitsRemaining) bits remaining, expected(\(bitsRemaining))")
        }

        // Possible non-access width tail
        if iterator.bitsRemaining > 0 {
            let elementMask = ~AMLInteger(maskFromBitCount: iterator.bitsRemaining)
            let lastValue = iterator.nextBits(bitsRemaining)!
            let valueToWrite: AMLInteger
            switch flags.updateRule {
                case .Preserve:
                    let curValue = try self.read(regionSpace, atIndex: index, flags) & elementMask
                    valueToWrite = curValue | lastValue

                case .WriteAsOnes:
                    valueToWrite = lastValue | elementMask

                case .WriteAsZeros:
                    valueToWrite = lastValue
            }
            try self.write(regionSpace, atIndex: index, value: valueToWrite, flags)
        }
    }

    private func createMask(_ startBit: Int, _ endBit: Int) -> AMLInteger {
        let bits = endBit - startBit + 1
        guard bits < AMLInteger.bitWidth else { return AMLInteger.max }
        let mask: AMLInteger = (1 << AMLInteger(bits)) - 1
        return mask << AMLInteger(startBit)
    }
}


//#if !TEST
// FIXME: This should be in a containing struct that can hold all of the
// AMLFieldSettings except the bitOffset/bitWidth which are per field
private enum OpRegionSpace: ~Copyable {
    case systemMemory(SystemMemorySpace)
    case systemIO(SystemIO)
    case pciConfig(PCIConfigRegionSpace)
    case embeddedControl
    case smbus
    case systemCMOS
    case pciBarTarget
    case ipmi
    case generalPurposeIO
    case genericSerialBus
    case oemDefined(UInt8)

    init(_ fullname: AMLNameString, _ region: AMLRegionSpace, _ offset: AMLInteger, _ length: AMLInteger) throws (AMLError) {
        let rootIDs = ["PNP0A03", "PNP0A08"]

        func findPciRoot(for node: ACPI.ACPIObjectNode) throws(AMLError) -> ACPI.ACPIObjectNode {
            var parent: ACPI.ACPIObjectNode? = node
            while let p = parent {
                if let hid = try p.hardwareId(), rootIDs.contains(hid) {
                    return p
                }
                if let cids = try p.compatibleIds() {
                    for cid in cids {
                        if rootIDs.contains(cid) {
                            return p
                        }
                    }
                }
                parent = p.parent
            }
            throw AMLError.error(reason: "Failed to find containing Root PCI")
        }

        func isPCIRoot(node: ACPI.ACPIObjectNode) -> Bool {
            guard node.object.isDevice else { return false }
            if let hid = try? node.hardwareId(), rootIDs.contains(hid) {
                return true
            }
            if let cids = try? node.compatibleIds() {
                for cid in cids {
                    if rootIDs.contains(cid) {
                        return true
                    }
                }
            }
            return false
        }

        switch region {
            case .systemMemory:
                self = .systemMemory(try SystemMemorySpace(offset: offset, length: length))

            case .systemIO:
                self = .systemIO(try SystemIO(port: offset, length: length))

            case .pciConfig:
                var addressNode: ACPI.ACPIObjectNode? = nil
                guard let pciRoot = ACPI.globalObjects.findEnclosingObject(of: fullname, where: {
                    // Find the highest node below PCI root with an _ADR
                    if let node = $0.childNode(named: "_ADR") {
                        addressNode = node
                    }
                    if isPCIRoot(node: $0) { return true }
                    return false
                }) else {
                    throw AMLError.error(reason: "Cannot find Root PCI containing \(fullname)")
                }
                if ACPIDebug {
                    #kprintf("acpi: Enclosing PCI Root for %s is %s\n",
                             fullname.value, pciRoot.fullname())
                }

                let bbn = try pciRoot.baseBusNumber() ?? 0
                // Find the PCI address for the device
                guard let address = try addressNode?.amlObject().integerValue else {
                    throw AMLError.invalidSymbol(reason: "Failed to get _ADR for PCI_Config")
                }

                let configSpace = pciConfigSpace(busId: bbn,
                                                 device: UInt8(truncatingIfNeeded: address >> 16),
                                                 function: UInt8(truncatingIfNeeded: address))
                if ACPIDebug {
                    #kprintf("acpi: %s: Using %s for PCI_Region\n", fullname.value, configSpace.description)
                }
                self = .pciConfig(PCIConfigRegionSpace(config: configSpace, offset: offset, length: length))

            default:
                throw AMLError.unimplementedError(reason: "OpRegionSpace: \(region.description) not implemented")
        }
    }


    var regionType: UInt8 {
        switch self {
            case .systemMemory: return 0x00
            case .systemIO: return 0x01
            case .pciConfig: return 0x02
            case .embeddedControl: return 0x03
            case .smbus: return 0x04
            case .systemCMOS: return 0x05
            case .pciBarTarget: return 0x06
            case .ipmi: return 0x07
            case .generalPurposeIO: return 0x08
            case .genericSerialBus: return 0x09
            case let .oemDefined(region): return region // .. 0xff fixme
        }
    }

    var description: String {
        return switch self {
            case .systemMemory: "SystemMemory"
            case .systemIO: "SystemIO"
            case .pciConfig: "PCIConfig"
            case .embeddedControl: "EmbeddedControl"
            case .smbus: "SMBus"
            case .systemCMOS: "SystemCMOS"
            case .pciBarTarget: "PCIBarTarget"
            case .ipmi: "IPMI"
            case .generalPurposeIO: "GPIO"
            case .genericSerialBus: "GPSB"
            case .oemDefined: "OEMDefined"
        }
    }


    func read<T: FixedWidthInteger & UnsignedInteger>(atIndex index: Int) -> T {
        return switch self {
            case .systemMemory(let region): region.read(atIndex: index)
            case .systemIO(let region): region.read(atIndex: index)
            case .pciConfig(let region): region.read(atIndex: index)
            // This should never be reached as the OpRegionSpace will never be created
            default: fatalError("acpi: OpRegionSpace.read() not implemented for \(self.description)")
        }
    }


    func write<T: FixedWidthInteger & UnsignedInteger>(atIndex index: Int, value: T) {
        switch self {
            case .systemMemory(let region): region.write(atIndex: index, value: value)
            case .systemIO(let region): region.write(atIndex: index, value: value)
            case .pciConfig(let region): region.write(atIndex: index, value: value)
            // This should never be reached as the OpRegionSpace will never be created
            default: fatalError("acpi: OpRegionSpace.write() not implemented for \(self.description)")
        }
    }

}


private struct SystemMemorySpace: ~Copyable {
    private let mmioRegion: MMIORegion

    init(offset: AMLInteger, length: AMLInteger) throws(AMLError) {
        precondition(length > 0)
        let offset = UInt(offset)
        let length = Int(length)
        let size = UInt(length)
        let physAddress = PhysAddress(offset)
        let region = PhysRegion(start: physAddress, size: size)

        if ACPIDebug {
            #kprintf("acpi: Adding system memory space: %s\n", region.description)
        }

        let memoryRange: MemoryRange
        if let _memoryRange = findMemoryRangeContaining(physAddress: physAddress),
           _memoryRange.type != .Hole {
            memoryRange = _memoryRange
        } else {
            #kprint("acpi: No memory range covering \(region), adding one")
            // Need to add in memory range to cover the region
            let region = PhysPageAlignedRegion(start: physAddress, size: size)
            #kprintf("acpi: Adding system memory space: %s\n", region.description)
            memoryRange = MemoryRange(type: .MemoryMappedIO, start: region.baseAddress,
                                      size: region.size, attributes: [.uncacheable])
            #kprint("acpi: Adding new memory range:", memoryRange)
            addMemoryRange(memoryRange)
        }
        guard let (readWrite, cacheType) = memoryRange.pageSettings() else {
            throw AMLError.error(reason: "Failed to get page settings for memory range \(memoryRange)")
        }

        if ACPIDebug {
            #kprintf("acpi: mapping region: %s as rw: %s cache: %s\n",
                     region.description, readWrite, cacheType.description)
        }
        self.mmioRegion = mapRegion(region: region, readWrite: readWrite, cacheType: cacheType)
    }

    deinit {
        // TODO: either via MMIORegion unmap or IOmemory manager defer { unmape(mmioRegion) }
        // unmapMMIORegion(mmioRegion)
    }

    func read<T: FixedWidthInteger & UnsignedInteger>(atIndex index: Int) -> T {
        let bytes = T.bitWidth / 8
        return mmioRegion.read(fromByteOffset: index * bytes) as T
    }

    func write<T: FixedWidthInteger & UnsignedInteger>(atIndex index: Int, value: T) {
        let bytes = T.bitWidth / 8
        mmioRegion.write(value: value, toByteOffset: index * bytes)
    }
}


private struct SystemIO {
    let port: UInt16


    init(port: AMLInteger, length: AMLInteger) throws(AMLError) {
        guard length > 0, port + length <= UInt16.max else {
            let error = #sprintf("Invalid SystemIO region: 0x%x/0x%x",
                                 port, length)
            #kprint("acpi:", error)
            throw AMLError.invalidData(reason: error)
        }
        self.port = UInt16(port)
    }


    func read<T: FixedWidthInteger & UnsignedInteger>(atIndex index: Int) -> T {
        let bytes = T.bitWidth / 8
        let offset = UInt16(index * bytes)

        switch bytes {
            case 1: return T(truncatingIfNeeded: inb(port + offset))
            case 2: return T(truncatingIfNeeded: inw(port + offset))
            case 4: return T(truncatingIfNeeded: inl(port + offset))

            default: fatalError("acpi: Invalid bitWidth \(T.bitWidth) access not allowed in a SystemIO region")
        }
    }


    func write<T: FixedWidthInteger & UnsignedInteger>(atIndex index: Int, value: T) {
        let bytes = T.bitWidth / 8
        let offset = UInt16(index * bytes)

        switch bytes {
            case 1: outb(port + offset, UInt8(truncatingIfNeeded: value))
            case 2: outw(port + offset, UInt16(truncatingIfNeeded: value))
            case 4: outl(port + offset, UInt32(truncatingIfNeeded: value))
            default: fatalError("acpi: Invalid bitWidth \(T.bitWidth) access not allowed in a SystemIO region")
        }
    }
}


private struct PCIConfigRegionSpace {
    let config: PCIConfigSpace
    let offset: UInt


    // PCI Config space should already be mapped for MMIO by the PCI subsystem
    init(config: PCIConfigSpace, offset: AMLInteger, length: AMLInteger) {
        precondition(length > 0)
        precondition(offset + length <= 4096)

        self.config = config
        self.offset = UInt(offset)
    }

    func read<T: FixedWidthInteger & UnsignedInteger>(atIndex index: Int) -> T {
        let bytes = T.bitWidth / 8
        let byteOffset = offset + UInt(index * bytes)

        switch bytes {
            case 1:
                return T(config.readConfigByte(atByteOffset: byteOffset))

            case 2:
                return T(config.readConfigWord(atByteOffset: byteOffset))

            case 4:
                return T(config.readConfigDword(atByteOffset: byteOffset))

            default:
                fatalError("acpi: bitWidth \(T.bitWidth) access not allowed in a PCIConfig region")
        }
    }


    func write<T: FixedWidthInteger & UnsignedInteger>(atIndex index: Int, value: T) {
        let bytes = T.bitWidth / 8
        let byteOffset = offset + UInt(index)

        switch bytes {
            case 1:
                config.writeConfigByte(atByteOffset: byteOffset, value: UInt8(truncatingIfNeeded: value))

            case 2:
                config.writeConfigWord(atByteOffset: byteOffset, value: UInt16(truncatingIfNeeded: value))

            case 4:
                config.writeConfigDword(atByteOffset: byteOffset, value: UInt32(truncatingIfNeeded: value))

            default:
                fatalError("acpi: bitWidth \(T.bitWidth) access not allowed in a PCIConfig region")
        }
    }
}
