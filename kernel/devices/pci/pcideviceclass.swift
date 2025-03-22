/*
 * kernel/devices/pci/pcideviceclass.swift
 *
 * Created by Simon Evans on 24/09/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * PCI Class and subclass codes.
 *
 */


struct PCIDeviceClass: Equatable {
    let classCode: PCIClassCode
    let subClassCode: UInt8
    let progInterface: UInt8

    init?(classCode: UInt8, subClassCode: UInt8, progInterface: UInt8) {
        guard let _classCode = PCIClassCode(rawValue: classCode) else {
            return nil
        }
        self.classCode = _classCode
        self.subClassCode = subClassCode
        self.progInterface = progInterface
    }

    init(classCode: PCIClassCode, subClassCode: UInt8, progInterface: UInt8) {
        self.classCode = classCode
        self.subClassCode = subClassCode
        self.progInterface = progInterface
    }

    var bridgeSubClass: PCIBridgeControllerSubClass? {
        guard classCode == .bridgeDevice else {
            return nil
        }
        return PCIBridgeControllerSubClass(rawValue: subClassCode)
    }

    var seriaBusSubClass: PCISerialBusControllerSubClass? {
        classCode == .serialBusController ? PCISerialBusControllerSubClass(rawValue: subClassCode) : nil
    }
}

enum PCIClassCode: UInt8 {

    case unclassified = 0
    case massStorageController = 1
    case networkController = 2
    case displayController = 3
    case multimediaController = 4
    case memoryController = 5
    case bridgeDevice = 6
    case simpleCommunicationController = 7
    case baseSystemPeripheral = 8
    case inputDeviceController = 9
    case dockingStation = 0xA
    case processor = 0xB
    case serialBusController = 0xC
    case wirelessController = 0xD
    case intelligentController = 0xE
    case satelliteCommunicationController = 0xF
    case encryptionController = 0x10
    case signalProcessingController = 0x11
    case processingAccelerator = 0x12
    case nonEssentialInstrumentation = 0x13
    case coProcessor = 0x40
    case unassigned = 0xff
}


// .bridgeDevice
enum PCIBridgeControllerSubClass: UInt8 {
    case host = 0
    case isa = 1
    case eisa = 2
    case mca = 3
    case pci = 4
    case pcmcia = 5
    case nuBus = 6
    case cardBus = 7
    case raceway = 8
    case pciSemiTransparent = 9
    case infiniband = 0x0a
    case other = 0x80
}

// serialBusController
enum PCISerialBusControllerSubClass: UInt8 {
    case fireWire = 0
    case accessBus = 1
    case ssa = 2
    case usb = 3
    case fibreChannel = 4
    case smbus = 5
    case infiniband = 6
    case ipmiInterface = 7
    case sercos = 8
    case canbus = 9
    case other = 0x80
}


// USB Programming Interface
enum PCIUSBProgrammingInterface: UInt8, CustomStringConvertible {
    case uhci = 0x00
    case ohci = 0x10
    case ehci = 0x20
    case xhci = 0x30
    case other = 0x80
    case device = 0xfe

    var description: String {
        return switch self {
        case .uhci: "UHCI"
        case .ohci: "OHCI"
        case .ehci: "EHCI"
        case .xhci: "XHCI"
        case .other: "Other"
        case .device: "Device"
        }
    }
}
