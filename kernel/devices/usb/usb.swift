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
    enum Status: CustomStringConvertible {
        case inprogress
        case cancelled
        case stalled
        case nak
        case finished  // Count of bytes trans
        case timedout

        var description: String {
            switch self {
                case .inprogress:
                    "InProgress"
                case .cancelled:
                    "Cancelled"
                case .stalled:
                    "Stalled"
                case .nak:
                    "NAK"
                case .finished:
                    "Finished"
                case .timedout:
                    "TimedOut"
            }
        }
    }

    let endpointDescriptor: USB.EndpointDescriptor


    init(endpointDescriptor: USB.EndpointDescriptor) {
        self.endpointDescriptor = endpointDescriptor
    }


    func allocateBuffer(length: Int) -> MMIOSubRegion { fatalError() }
    func freeBuffer(_ buffer: MMIOSubRegion) {}
    func submitURB(_ urb: USB.Request) {}
    func pollPipe(_ error: Bool) -> Status { .cancelled }
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
                            nextBusId += 1
                            guard let rootHubDevice = driver.rootHubDevice(bus: usbBus),
                                  let rootHubDriver = USBHubDriver(usbDevice: rootHubDevice),
                                  rootHubDriver.initialise() else {
                                #kprint("USB: Failed to add roothub")
                                break
                            }
                            usbBuses.append(usbBus)
                            rootHubDriver.enumerate()
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
    let allocatePipe: (USB.EndpointDescriptor) -> USBPipe?
    let nextAddress: () -> UInt8?
    let submitURB: (USB.Request) -> Void
    let description: String

    init (busId: Int,
          allocatePipe: @escaping (USB.EndpointDescriptor) -> USBPipe?,
          nextAddress: @escaping () -> UInt8?,
          submitURB: @escaping (USB.Request) -> Void,
    ) {
        self.description = #sprintf("USBBUS: %d", busId)
        self.busId = busId
        self.allocatePipe = allocatePipe
        self.nextAddress = nextAddress
        self.submitURB = submitURB
    }
}

extension USB {
    struct Request {
        let usbDevice: USBDevice

// FIXME, might be better as .control(SetupRequest, direction, buffer?) .interrupt(buffer) ...

        let transferType: EndpointDescriptor.TransferType
//        let endpointDescriptor: EndpointDescriptor
        let direction: TransferDirection    // Control requests do not use the direction in the Endpoint Descriptor
        let pipe: USBPipe
        let completionHandler: (Request, Response) -> ()
        let setupRequest: MMIOSubRegion?    // Used for control requests
        let buffer: MMIOSubRegion?
        let bytesToTransfer: Int
    }

    struct Response {
        let status: USBPipe.Status
        let bytesTransferred: Int
    }
}

