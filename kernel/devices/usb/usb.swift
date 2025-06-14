/*
 * kernel/devices/usb/usb.swift
 *
 * Created by Simon Evans on 21/10/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * USB Stack.
 *
 */


class USBPipe {
    func allocateBuffer(length: Int) -> MMIOSubRegion { fatalError() }
    func freeBuffer(_ buffer: MMIOSubRegion) {}
    func send(request: USB.ControlRequest, withBuffer: MMIOSubRegion?) -> Bool { return false }
    func pollInterruptPipe(into buffer: inout MutableSpan<UInt8>) -> Int { return 0 }
}


final class USB {

    let devices: [Device] = []
    private var usbBuses: [USBBus] = [] // Each HCD is a Bus and also a Root Hub
    let description = "USB"

    init() {
    }


    func initialiseDevices(rootPCIBus: PCIBus) {
        var nextBusId = 1
        // Initialse the Host controllers. EHCI needs to be initialised before UHCI due to the companion controller setup
        // So do the controllers in the order XHCI, EHCI, UHCI
        for progIf in [PCIUSBProgrammingInterface.xhci, .ehci, .uhci] {
            #kprint("Looking for progIf", progIf.description)
            rootPCIBus.devicesMatching(classCode: .serialBusController,
                                       subClassCode: PCISerialBusControllerSubClass.usb.rawValue,
                                       progInterface: progIf.rawValue) { (pciDevice, deviceClass) in
                #kprint("USB: Found a USB HCD", pciDevice, " progIf:", progIf)
                guard !pciDevice.device.initialised else { return }

                guard pciDevice.initialise() else { return }
                switch progIf {
                    case .uhci:
                        if let driver = HCD_UHCI(pciDevice: pciDevice), driver.initialise() {
                            // FIXME: Move busId to the HCD_UHCI
                            let usbBus = driver.usbBus(busId: nextBusId)
                            usbBuses.append(usbBus)
                            nextBusId += 1
                            let rootHubDevice = driver.rootHubDevice(bus: usbBus)
                            if let rootHubDriver = USBHubDriver(usbDevice: rootHubDevice), rootHubDriver.initialise() {
                                rootHubDriver.enumerate()
                            }
                        }

                    case .ehci:
                        if let driver = HCD_EHCI(pciDevice: pciDevice), driver.initialise() {
//                            let rootHub = USBHub.ehci(driver)
//                            #kprint("rootHub2: ", rootHub.description)
//                            rootHubs.append(rootHub)
                        }

                    case .xhci:
                        if let driver = HCD_XHCI(pciDevice: pciDevice), driver.initialise() {
 //                           let rootHub = USBHub.xhci(driver)
 //                           #kprint("rootHub3: ", rootHub.description)
 //                           rootHubs.append(rootHub)
                        }

                    default: break
                }
            }
        }
    }
}


extension USB {
    enum Speed: CustomStringConvertible {
        case lowSpeed
        case fullSpeed
        case highSpeed
        case superSpeed

        var description: String {
            return switch self {
                case .lowSpeed: "lowSpeed"
                case .fullSpeed: "fullSpeed"
                case .highSpeed: "highSpeed"
                case .superSpeed: "superSpeed"
            }
        }

        var controlSize: Int {
            switch self {
                case .lowSpeed, .fullSpeed: return 8
                case .highSpeed: return 64
                case .superSpeed: return 512
            }
        }
    }
}


// Every USB Host controller is both a Bus and a Root Hub. This deines the functions that a USBDevice
// can use via it's bus
struct USBBus: CustomStringConvertible {
    let busId: Int
    let allocatePipe: (USBDevice, USB.EndpointDescriptor) -> USBPipe?
    let nextAddress: () -> UInt8?
    let description: String


    init (busId: Int,
          allocatePipe: @escaping (USBDevice, USB.EndpointDescriptor) -> USBPipe?,
          nextAddress: @escaping () -> UInt8?
    ) {
        self.description = #sprintf("USBBUS: %d", busId)
        self.busId = busId
        self.allocatePipe = allocatePipe
        self.nextAddress = nextAddress
    }
}
