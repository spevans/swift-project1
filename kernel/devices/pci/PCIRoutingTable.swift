/*
 * kernel/devices/pci/PCIRoutingTable.swift
 *
 * Created by Simon Evans on 02/05/2021.
 * Copyright © 2021 Simon Evans. All rights reserved.
 *
 * PCI Routing table, ACPI _PRT data.
 *
 */


// INTA - INTD
enum PCIInterruptPin: Equatable, CustomStringConvertible {
    case intA
    case intB
    case intC
    case intD

    private var rawValue: UInt8 {
        switch self {
            case .intA: return 1
            case .intB: return 2
            case .intC: return 3
            case .intD: return 4
        }
    }

    // The Interrupt Pin from offset 0x3D of the PCI config area. 0 = No interrupt, 1-4 => A-D
    init?(pin: UInt8) {
        switch pin {
            case 0: return nil
            case 1: self = .intA
            case 2: self = .intB
            case 3: self = .intC
            case 4: self = .intD
            default:
                #kprint("PRT: Invalid interrupt PIN value: \(pin)")
                return nil
        }
    }


    // The pin value from the _PRT PCI Routing Table: 0-3 -> A-D
    init?(routingTablePin pin: UInt8) {
        switch pin {
            case 0: self = .intA
            case 1: self = .intB
            case 2: self = .intC
            case 3: self = .intD
            default: return nil
        }
    }

    var description: String {
        switch self {
            case .intA: return "INT #A"
            case .intB: return "INT #B"
            case .intC: return "INT #C"
            case .intD: return "INT #D"
        }
    }


    // Swizzle according to 'System Interrupt Mapping' in PCI Express spec section 2.2.8.1.
    func swizzle(slot: UInt8, ariEnabled: Bool = false) -> Self {
        let _slot = ariEnabled ? 0 : slot
        let newPin = ((self.rawValue - 1) + _slot) % 4
        let result = Self(pin: newPin + 1)!
        #kprint("PRT: SWIZZLE: slot: \(slot) _slot: \(_slot) pin: \(self) newPin: \(result)")
        return result
    }
}

extension PCIRoutingTable {
    struct Entry: Equatable, CustomStringConvertible {
        enum Source: Equatable, CustomStringConvertible {
            case namePath(AMLNameString, UInt32)
            case globalSystemInterrupt(UInt32)

            var description: String {
                switch self {
                    case .globalSystemInterrupt(let irq): return "GSIRQ \(irq)"
                    case .namePath(let name, let index): return "\(name.value) [\(index)]"
                }
            }
        }

        let pciDevice: UInt16
        let pin: PCIInterruptPin
        let source: Source

        var description: String {
            #sprintf("DEV: %2.2x PIN: %s source: %s", pciDevice, pin.description, source.description)
        }
    }
}


struct PCIRoutingTable: CustomStringConvertible {

    let prtAcpiNode: ACPI.ACPIObjectNode
    let table: [PCIRoutingTable.Entry]

    var description: String {
        var result = prtAcpiNode.description + "[" + table.reduce(into: "[") { $0 += $1.description + ", " }
        result.removeLast(2)
        result.append("]")
        return result
    }

    init?(prtNode: ACPI.ACPIObjectNode) {

        guard let _prt = try? prtNode.amlObject() else {
            #kprint("PRT: \(prtNode.fullname()) is not an AMLDataObject")
            return nil
        }

        guard let routingTable = _prt.packageValue else {
            #kprint("_PRT is not a package but a:", _prt)
            return nil
        }

        prtAcpiNode = prtNode
        var _table: [PCIRoutingTable.Entry] = []
        _table.reserveCapacity(routingTable.count)

        for packageEntry in routingTable.elements {
            guard let entry = packageEntry.packageValue else {
                fatalError("_PTR entry is not the correct format")
            }

            guard let address = entry[0].integerValue, address <= UInt32.max else {
                fatalError("PCI Interrupt: address value is too large")
            }

            guard address & 0xffff == 0xffff else {
                fatalError("PCI Interrupt: address should match to all PCI functions")
            }

            guard let _pin = entry[1].integerValue,
                  let pin = PCIInterruptPin(routingTablePin: UInt8(_pin)) else {
                fatalError("PCI Interrupt: pin value is too large")
            }

            guard let sourceIndex = entry[3].integerValue, sourceIndex <= UInt32.max else {
                fatalError("PCI Interrupt: Source index is invalid: \(entry[3])")
            }

            let source: Entry.Source
            if let sourceName = entry[2].stringValue {
                // Determine the full name
                source = .namePath(AMLNameString(sourceName.asString()), UInt32(sourceIndex))
            } else if let byteValue = entry[2].integerValue, byteValue == 0 {
                source = .globalSystemInterrupt(UInt32(sourceIndex))
            } else {
                fatalError("PCI Interrupt: Source is not a String or 0: \(entry[2])")
            }

            _table.append(Entry(pciDevice: UInt16(address >> 16), pin: pin, source: source))
        }
        table = _table
    }

    func findEntryByDevice(slot: UInt8, pin: PCIInterruptPin) -> PCIRoutingTable.Entry? {
        let entry = table.first { $0.pciDevice == slot && $0.pin == pin }
        if entry != nil {
            return entry
        }
        table.forEach { #kprint($0) }
        fatalError("Cant find entry")
    }
}

