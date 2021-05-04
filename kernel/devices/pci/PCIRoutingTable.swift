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
enum PCIInterruptPin: CustomStringConvertible {
    case intA
    case intB
    case intC
    case intD

    // The Interrupt Pin from offset 0x3D of the PCI config area. 0 = No interrupt, 1-4 => A-D
    init?(pin: UInt8) {
        switch pin {
            case 0: return nil
            case 1: self = .intA
            case 2: self = .intB
            case 3: self = .intC
            case 4: self = .intD
            default:
                print("PCI: Invalid interrupt PIN value: \(pin)")
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
}

struct PCIRoutingTableEntry: CustomStringConvertible {
    enum Source: CustomStringConvertible {
        case value(UInt8)
        case string(AMLNameString)

        var description: String {
            switch self {
                case .value(let irq): return "IRQ \(irq)"
                case .string(let name): return name.value
            }
        }
    }

    let pciDevice: UInt16
    let pin: PCIInterruptPin
    let source: Source
    let sourceIndex: UInt32

    var description: String {
        "_PRT Entry: device: \(String(pciDevice, radix: 16)), pin: \(pin) source: \(source), sourceIndex: \(sourceIndex)"
    }
}


struct PCIRoutingTable {

    let prtAcpiNode: ACPI.ACPIObjectNode
    let table: [PCIRoutingTableEntry]

    init?(acpi: AMLDefDevice) {

        guard let prtNode = acpi.childNode(named: "_PRT") else {
            print("PCI: Cant find _PRT under \(acpi.fullname())")
            return nil
        }

        guard let _prt = prtNode.asTermArg() as? AMLDataObject else {
            print("PCI: \(prtNode.fullname()) is not an AMLDataObject")
            return nil
        }

        guard let routingTable = _prt.packageValue else {
            print("_PTR is not a package but a:", type(of: _prt))
            return nil
        }

        prtAcpiNode = prtNode
        var _table: [PCIRoutingTableEntry] = []
        _table.reserveCapacity(routingTable.count)

        for packageEntry in routingTable {
            guard let entry = packageEntry.dataRefObject?.dataObject?.packageValue else {
                fatalError("_PTR entry is not the correct format")
            }

            guard let address = entry[0].dataRefObject?.dataObject?.integerValue, address <= UInt32.max else {
                fatalError("PCI Interrupt: address value is too large")
            }

            guard address & 0xffff == 0xffff else {
                fatalError("PCI Interrupt: address should match to all PCI functions")
            }

            guard let _pin = entry[1].dataRefObject?.dataObject?.integerValue,
                  let pin = PCIInterruptPin(routingTablePin: UInt8(_pin)) else {
                fatalError("PCI Interrupt: pin value is too large")
            }

            let source: PCIRoutingTableEntry.Source
            if let sourceName = entry[2].nameString {
                // Determine the full name
                source = .string(sourceName)
            } else {
                guard let sourceValue = entry[2].dataRefObject?.dataObject?.integerValue, sourceValue <= UInt8.max else {
                    fatalError("PCI Interrupt: Source is not a String or Byte")
                }
                source = .value(UInt8(sourceValue))
            }

            guard let sourceIndex = entry[3].dataRefObject?.dataObject?.integerValue, sourceIndex <= UInt32.max else {
                fatalError("PCI Interrupt: Source index is too large")
            }

            _table.append(PCIRoutingTableEntry(pciDevice: UInt16(address >> 16), pin: pin,
                                               source: source, sourceIndex: UInt32(sourceIndex)))
        }
        table = _table
    }

#if !TEST
    func findEntryByDevice(pciDevice: PCIDevice) -> PCIRoutingTableEntry? {

        let device = pciDevice.deviceFunction.device
        guard let pin = pciDevice.deviceFunction.interruptPin else {
            print("PCI: \(pciDevice) has no valid interruptPin")
            return nil
        }
        print("PCI: findEntryByDevice, device:\(String(device, radix: 16)), pin: \(pin)")
        return table.first { $0.pciDevice == device && $0.pin == pin }
    }
#endif
}

