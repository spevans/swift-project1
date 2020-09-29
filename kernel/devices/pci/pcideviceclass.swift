/*
 * kernel/devices/pci/pcideviceclass.swift
 *
 * Created by Simon Evans on 24/09/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * PCI Class and subclass codes.
 *
 */


struct PCIDeviceClass {
    let deviceClass: PCIClassCode
    private let subClassCode: UInt8
    private let progInterface: UInt8

    init?(classCode: UInt8, subClassCode: UInt8, progInterface: UInt8) {
        guard let _classCode = PCIClassCode(rawValue: classCode) else {
            return nil
        }
        self.deviceClass = _classCode
        self.subClassCode = subClassCode
        self.progInterface = progInterface
    }

    var bridgeSubClass: PCIBridgeControllerSubClass? {
        guard deviceClass == .bridgeDevice else {
            return nil
        }
        return PCIBridgeControllerSubClass(rawValue: subClassCode)
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
