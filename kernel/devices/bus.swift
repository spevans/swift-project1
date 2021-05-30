//
//  bus.swift
//  project1
//
//  Created by Simon Evans on 25/09/2020.
//  Copyright © 2020 Simon Evans. All rights reserved.
//

protocol Bus: AnyObject {

    var devices: [Device] { get }
    var resources: [MotherBoardResource] { get set }
    func initialiseDevices(acpiDevice: AMLDefDevice?)
    func initialise() -> Bool
    func device(acpiDevice: AMLDefDevice) -> Device?
    func addDevice(_ device: Device)
    func addResource(_ resource: MotherBoardResource)
}


// PNP0C02 device
final class MotherBoardResource: CustomStringConvertible {
    private let resources: [AMLResourceSetting]
    let acpiDevice: AMLDefDevice

    var description: String { "\(acpiDevice.fullname()): \(resources)" }


    init?(acpiDevice: AMLDefDevice) {
        guard let crs = acpiDevice.currentResourceSettings() else {
            print("\(acpiDevice.fullname()): No valid resources found")
            return nil
        }
        self.acpiDevice = acpiDevice
        self.resources = crs
    }
}


extension Bus {

    func initialiseDevices(acpiDevice: AMLDefDevice?) {
        guard let acpi = acpiDevice else {
            print(self, "No ACPI node, not calling initialiseDevices")
            return
        }
        for value in acpi.childNodes {
            if let device = value as? AMLDefDevice {
                ACPI.processNode(parentBus: self, device)
            }
        }
    }

    func addResource(_ resource: MotherBoardResource) {
        resources.append(resource)
    }
}


final class MasterBus: Bus {
    private var pciHostBus: PCIHostBus?     // PCI Host Bus
    private (set) var devices: [Device] = []

    var resources: [MotherBoardResource] = []
    let acpiSystemBus: ACPI.ACPIObjectNode      // \_SB node


    init(acpiSystemBus: ACPI.ACPIObjectNode) {
        self.acpiSystemBus = acpiSystemBus
    }

    func device(acpiDevice: AMLDefDevice) -> Device? {
        guard let pnpName = acpiDevice.deviceId else {
            print("MasterBus: cant add device \(acpiDevice.fullname()) with no pnpName")
            return nil
        }
        return PNPDevice(parentBus: self, acpiDevice: acpiDevice, pnpName: pnpName)
    }

    func addDevice(_ device: Device) {
        devices.append(device)
    }

    func rootPCIBus() -> PCIBus? {
        if pciHostBus == nil {
            for device in devices {
                if let bus = device as? PCIHostBus {
                    pciHostBus = bus
                    break
                }
            }
        }
        return pciHostBus?.pciBus
    }


  //  func initialiseDevices(acpiDevice: AMLDefDevice?) {
    func initialise() -> Bool {
        // Run \\_SB.INI() before initialising devices.
        do {
            try ACPI.invoke(method: "\\_SB._INI")
        } catch {
            print("ACPI: Error running \\_SB.INI:", error)
        }

        for value in acpiSystemBus.childNodes {
            if let device = value as? AMLDefDevice {
                ACPI.processNode(parentBus: self, device)
            }
        }
        devices.sort {
            let bus0 = $0.deviceDriver as? Bus
            let bus1 = $1.deviceDriver as? Bus

            if bus0 != nil && bus1 == nil { return true }
            else if bus0 == nil && bus1 != nil { return false }
            else { return $0.fullName < $1.fullName }
        }
        return true
    }
}


extension ACPI {
    // Scan an ACPI Node for devices and add them to the parentBus

    static func processNode(parentBus: Bus, _ node: AMLDefDevice) {
        var foundDevice: Device? = nil
        let deviceId = node.hardwareId() ?? node.pnpName()

        if let pnpName = deviceId {
            switch pnpName {

                case "PNP0A00", // ISABus
                     "PNP0A08" // PCIBus, PCI Express
                        where parentBus is PCIBus:

                    guard let address = node.addressResource() else {
                        print("Cant get addressResource for \(node.fullname())")
                        return
                    }

                    if let pciBus = parentBus as? PCIBus,
                       let deviceFunction = PCIBus.pciDeviceFunctionFor(address: address, withBusId: pciBus.busId),
                       deviceFunction.deviceClass?.classCode == .bridgeDevice {

                        foundDevice = pciBus.device(deviceFunction: deviceFunction, acpiDevice: node)
                    }

                case "PNP0A03", // PCI Host bridge
                     "PNP0A08": // PCIBus, PCI Express
                    print("Found a PCI bridge")
                    guard let address = node.addressResource() else {
                        print("Cant get addressResource for \(node.fullname())")
                        return
                    }

                    // Get the Bus number
                    // FIXME: _BBN should be a method 'busNumbers()' on a DefDevice
                    // FIXME: Add method to walk up the tree finding a given node by name
                    var busId: UInt8 = 0
                    var p: ACPI.ACPIObjectNode? = node
                    while let _node = p {
                        if let bbnNode = _node.childNode(named: "_BBN") as? AMLNamedValue {
                            print("Found _BBN node on parent:", _node.fullname())
                            let bbnValue = bbnNode.value.integerValue!
                            busId = UInt8(truncatingIfNeeded: bbnValue)
                            break
                        }
                        p = _node.parent
                    }
                    print("Creating deviceFunction for address: \(address), busId: \(busId)")
                    let dev = PCIHostBus(parentBus: parentBus, busId: busId, acpiDevice: node)
                    dev.addBus()
                    //_ = foundDevice?.initialiseDevice()
                    print("Found a PCIHostBus:", dev)
                    foundDevice = dev

                    #if false

                case "PNP0C01", "PNP0C02":
                    break
//                   if let resource = MotherBoardResource(acpiDevice: node) {
//                        parentBus.addResource(resource)
//                    }

                case "PNP0A05", "PNP0A06", "ACPI0004":  // Generic Container
                    // FIXME: Add this into the device initialisation
                    //if let resource = MotherBoardResource(acpiDevice: node) {
                    //    parentBus.addResource(resource)
                    //}



                    // Look for subdevices
                    for value in node.childNodes {
                        if let device = value as? AMLDefDevice {
                            ACPI.processNode(parentBus: parentBus, device)
                        }
                    }
                    #endif

                default:
                    foundDevice = parentBus.device(acpiDevice: node)
            }
        } else {
            if let device = parentBus.device(acpiDevice: node) {
                foundDevice = device
            }
        }

        if let device = foundDevice {
            node.setDevice(device)
            parentBus.addDevice(device)

            if let driver = device.deviceDriver as? Bus {
                print("\(driver) \(node.fullname()) driver is a Bus")
                driver.initialiseDevices(acpiDevice: node)
            }
        }
    }
}
