/*
 * kernel/devices/usb/usb.swift
 *
 * Created by Simon Evans on 21/10/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * USB Stack.
 *
 */


enum USBHCD {
    case uhci(HCD_UHCI)
    case ehci(HCD_EHCI)
    case xhci(HCD_XHCI)

    func pollInterrupt() -> Bool {
        switch self {
        case let .uhci(hcd): return hcd.pollInterrupt()
        case let .ehci(hcd): return hcd.pollInterrupt()
        case let .xhci(hcd): return hcd.pollInterrupt()
        }
    }
}


enum USBHub: CustomStringConvertible {
    case uhci(HCD_UHCI)

    var description: String {
        switch self {
            case let .uhci(hub): hub.description
        }
    }

    var portCount: Int {
        switch self {
            case let .uhci(hub): hub.portCount
        }
    }

    func reset(port: Int) -> Bool {
        switch self {
            case let .uhci(hub): return hub.reset(port: port)
        }
    }

    func detectConnected(port: Int) -> USB.Speed? {
        switch self {
            case let .uhci(hub): return hub.detectConnected(port: port)
        }
    }

    func nextAddress() -> UInt8? {
        switch self {
            case let .uhci(hub): return hub.nextAddress()
        }
    }

    func allocatePipe(device: USBDevice, endpointDescriptor: USB.EndpointDescriptor) -> USBPipe? {
        switch self {
            case let .uhci(hub): return hub.allocatePipe(device: device, endpointDescriptor: endpointDescriptor)
        }
    }

    func dumpState() {
        switch self {
            case let .uhci(hcd):
                hcd.dumpAndCheckFrameList()
                hcd.registerDump()
        }
    }
}


class USBPipe {
    func allocateBuffer(length: Int) -> MMIOSubRegion { fatalError() }
    func freeBuffer(_ buffer: MMIOSubRegion) {}
    func send(request: USB.ControlRequest, withBuffer: MMIOSubRegion?) -> Bool { return false }
    func pollInterruptPipe(into buffer: inout [UInt8]) -> Bool { return false }
}


final class USB {

    let devices: [Device] = []
    var resources: [MotherBoardResource] = []
    private var hcds: [USBHCD] = []
    let description = "USB"

    init() {
    }

    func initialise() -> Bool { return true }

    func initialiseDevices(rootPCIBus: PCIBus) {

        var usbHcds: [(PCIDevice, PCIUSBProgrammingInterface)] = []
        rootPCIBus.devicesMatching(classCode: .serialBusController, subClassCode: PCISerialBusControllerSubClass.usb.rawValue) {
            let deviceClass = $1
            guard !$0.device.initialised else { return }
            if deviceClass.seriaBusSubClass == .usb, let progIf = PCIUSBProgrammingInterface(rawValue: deviceClass.progInterface) {
                #kprint("USB: Found a USB HCD", $0.device.fullName, " progIf:", progIf)
                // Add to the list of HCDs for later initialisation
                switch progIf {
                    case .uhci, .ehci, .xhci:
                        usbHcds.append(($0, progIf))

                    default:
                        #kprint("USB: unsupported HCD:", progIf)
                }
            }
        }

        usbHcds = usbHcds.sorted {
            let progIf0 = $0.1
            let progIf1 = $1.1

            switch (progIf0, progIf1) {
                case (.ehci, .uhci): return true
                case (.ehci, .xhci): return true
                case (.uhci, .xhci): return true
                default: return false
            }
        }
        usbHcds.forEach {
            let device = $0.0
            let progIf = $0.1
            switch progIf {

                case .uhci:
                    if device.initialise(), let driver = HCD_UHCI(pciDevice: device) {
                        if driver.initialise() {
                            let hcd = USBHCD.uhci(driver)
                            hcds.append(hcd)
                        }
                    }

                case .ehci:
                    if device.initialise(), let driver = HCD_EHCI(pciDevice: device) {
                        if driver.initialise() {
                            let hcd = USBHCD.ehci(driver)
                            hcds.append(hcd)
                        }
                    }

                case .xhci:
                    if device.initialise(), let driver = HCD_XHCI(pciDevice: device) {
                        if driver.initialise() {
                            let hcd = USBHCD.xhci(driver)
                            hcds.append(hcd)
                        }
                    }

                default: return
            }
        }
    }


    // Bus Protocol
    func device(acpiDevice: AMLDefDevice) -> Device? { return nil }
    func addDevice(_ device: Device) {}
    func addResource(_ resource: MotherBoardResource) {}


    func enumerate(hub: USBHub) {
        for portIdx in 0..<hub.portCount {
            guard let connectedSpeed = hub.detectConnected(port: portIdx) else {
                #kprint("USB: \(hub)/\(portIdx) has no device")
                continue
            }

            sleep(milliseconds: 100)
            guard hub.reset(port: portIdx) else {
                #kprint("USB: \(hub)/ \(portIdx) reset failed")
                continue
            }

            #kprint("USB: \(hub)/\(portIdx) speed: \(connectedSpeed)")
            let device = USBDevice(hub: hub, port: portIdx, speed: connectedSpeed)

            // Set address of device
            guard let address = hub.nextAddress() else {
                fatalError("No more addresses!")
            }

            var _deviceDescriptor: USB.DeviceDescriptor?
            for _ in 1...2 {
                _deviceDescriptor = setAddressAndGetDescriptor(device, address, portIdx)
                if _deviceDescriptor != nil { break }
            }

            guard let deviceDescriptor = _deviceDescriptor else { continue }
            // Get full DeviceDescriptor
            #kprint("USB: \(hub)/\(portIdx)-\(address) Getting full DeviceDescriptor of length:", deviceDescriptor.bLength)
            guard let _descriptor = device.getDeviceConfig(length: UInt16(deviceDescriptor.bLength)) else {
                #kprint("USB: \(hub)/\(portIdx)-\(address) Cant get full DeviceDescriptor")
                continue
            }
            let fullDeviceDescriptor = _descriptor
            #kprint("USB: \(device.description) fullDeviceDescriptor:", fullDeviceDescriptor)
            #kprintf("USB: %s vendor: %4.4x product: %4.4x manu: %2.2x product: %2.2x\n",
                     device.description,
                     fullDeviceDescriptor.idVendor, fullDeviceDescriptor.idProduct,
                     fullDeviceDescriptor.iManufacturer, fullDeviceDescriptor.iProduct)

            #kprint("\nUSB: \(device.description) Getting ConfigurationDescriptor")
            guard let configDescriptor = device.getConfigurationDescriptor() else {
                #kprint("USB: \(device.description) Cant get device ConfigurationDescriptor of device on port: \(portIdx) - ignoring device")
                continue
            }
            #kprint("USB: \(device.description) configDescriptor: \(configDescriptor)")

            guard device.setConfiguration(to: configDescriptor.bConfigurationValue) else {
                #kprint("USB: \(device.description) Cant set configuration")
                continue
            }
            // Configure device - set_configuration
            for interface in configDescriptor.interfaces {
                switch interface.interfaceClass {
                    case .hid:
                        #kprint("USB: \(device.description) Found a HID Device, interface: \(interface)")
                        guard let driver = USBHIDDriver(device: device, interface: interface), driver.initialise() else {
                            #kprint("USB: \(device.description) Cannot create HID Driver for device")
                            continue
                        }
                    default:
                        let iClass = interface.interfaceClass?.description ?? "nil"
                        #kprint("USB: \(device.description) ignoring non-HID device: \(iClass)")
                }
            }
        }
    }

    private func setAddressAndGetDescriptor(_ device: USBDevice, _ address: UInt8, _ portIdx: Int) -> USB.DeviceDescriptor?{
        #kprint("USB: \(device.hub)/\(portIdx) Setting address of device on to \(address)")


        guard let deviceDescriptor = device.getDeviceConfig(length: 8) else { return nil }
        #kprint("USB: \(device.hub)/\(portIdx) deviceDescriptor:", deviceDescriptor)
        guard deviceDescriptor.bLength != 0 else {
            fatalError("info8 returned zero length bLength")
        }

        guard device.setAddress(address) else {
            #kprint("USB: \(device.hub)/\(portIdx)  Cant set address of device - ignoring device")
            return nil
        }
        return deviceDescriptor
    }
}
