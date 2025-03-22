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


enum USBHub {
    case uhci(HCD_UHCI)

    var portCount: Int {
        switch self {
        case let .uhci(hub): return hub.portCount
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
}


class USBPipe {
    func allocateBuffer(length: Int) -> MMIOSubRegion { fatalError() }
    func freeBuffer(_ buffer: MMIOSubRegion) {}
    func send(request: USB.ControlRequest, withBuffer: MMIOSubRegion?) -> Bool { return false }
    func pollInterruptPipe() -> [UInt8]? { return nil }
}


final class USB {

    let devices: [Device] = []
    var resources: [MotherBoardResource] = []
    private var hcds: [USBHCD] = []
    let description = "USB"

    init() {

    }

    func initialise() -> Bool { return true }

    func initialiseDevices(acpiDevice: AMLDefDevice? = nil) {

        guard let  rootPCIBus = system.deviceManager.masterBus.rootPCIBus() else {
            #kprint("USB: No Root PCI bus found, extiing USB initialisation")
            return
        }

        rootPCIBus.devicesMatching(classCode: .serialBusController, subClassCode: PCISerialBusControllerSubClass.usb.rawValue) {
            #kprint("USB: Found pcidevice: \($0) deviceClass: \($1)")
            let deviceClass = $1
            guard !$0.device.initialised else { return }
            if deviceClass.seriaBusSubClass == .usb, let progIf = PCIUSBProgrammingInterface(rawValue: deviceClass.progInterface) {
                #kprint("USB: Found a USB HCD, progIf:", progIf)
                switch progIf {
                    case .uhci:
                        if $0.initialise(), let driver = HCD_UHCI(pciDevice: $0) {
                            if driver.initialise() {
                                let hcd = USBHCD.uhci(driver)
                                hcds.append(hcd)
                            }
                        }

                    case .ehci:
                        if $0.initialise(), let driver = HCD_EHCI(pciDevice: $0) {
                            if driver.initialise() {
                                let hcd = USBHCD.ehci(driver)
                                hcds.append(hcd)
                            }
                        }

                    case .xhci:
                        if $0.initialise(), let driver = HCD_XHCI(pciDevice: $0) {
                            if driver.initialise() {
                                let hcd = USBHCD.xhci(driver)
                                hcds.append(hcd)
                            }
                        }

                    default: #kprint("USB: unsupported HCD:", progIf)
                }
            }
        }
    }

    // Bus Protocol
    func device(acpiDevice: AMLDefDevice) -> Device? { return nil }
    func addDevice(_ device: Device) {}
    func addResource(_ resource: MotherBoardResource) {}


    func enumerate(hub: USBHub) {
        for portIdx in 0..<hub.portCount {
            guard hub.reset(port: portIdx) else {
                #kprint("USB: Port \(portIdx) reset failed")
                continue
            }

            guard let connectedSpeed = hub.detectConnected(port: portIdx) else {
                #kprint("USB: Port \(portIdx) has no device")
                continue
            }

            #kprint("USB: port \(portIdx) speed: \(connectedSpeed)")
            #kprint("USB: Creating device")
            let device = USBDevice(hub: hub, port: portIdx, speed: connectedSpeed)

            var _deviceDescriptor: USB.DeviceDescriptor?
            #kprint("\nUSB: Getting device info8")
            for _ in 1...3 {
                // Configure device - get_device_info8
                if let descriptor = device.getDeviceConfig(length: 8) {
                    _deviceDescriptor = descriptor
                    break
                } else {
                    #kprint("USB: Couldnt get device descriptor of device on port: \(portIdx)")
                    sleep(milliseconds: 100)
                }
            }
            guard let deviceDescriptor = _deviceDescriptor else { continue }
            #kprint("USB: deviceDescriptor:", deviceDescriptor)
            guard deviceDescriptor.bLength != 0 else {
                fatalError("info8 returned zero length bLength")
            }

            // Set address of device
            guard let address = hub.nextAddress() else {
                fatalError("No more addresses!")
            }
            #kprint("\nUSB: Setting address of device on port \(portIdx) to \(address)")
            guard device.setAddress(address) else {
                #kprint("USB: Cant set address of device on port: \(portIdx) - ignoring device")
                continue
            }

            // Get full DeviceDescriptor
            #kprint("\nUSB: Getting full DeviceDescriptor of length:", deviceDescriptor.bLength)
            guard let _descriptor = device.getDeviceConfig(length: UInt16(deviceDescriptor.bLength)) else {
                #kprint("USB: Cant get full DeviceDescriptor")
                continue
            }
            let fullDeviceDescriptor = _descriptor
            #kprint("USB: fullDeviceDescriptor:", fullDeviceDescriptor)

            #kprint("\nUSB: Getting ConfigurationDescriptor")
            guard let configDescriptor = device.getConfigurationDescriptor() else {
                #kprint("USB: Cant get device ConfigurationDescriptor of device on port: \(portIdx) - ignoring device")
                continue
            }
            #kprint("USB: configDescriptor:", configDescriptor)

            // Configure device - set_configuration
            for interface in configDescriptor.interfaces {
                if case .hid = interface.interfaceClass {
                    #kprint("Found a HID Device, setting configuration")
                    guard device.setConfiguration(to: configDescriptor.bConfigurationValue) else {
                        #kprint("USB: Cant set configuration")
                        continue
                    }

                    guard let driver = USBHIDDriver(device: device, interface: interface), driver.initialise() else { continue }

                    while true {
                        driver.read()
                    }
                }
            }
        }
    }
}
