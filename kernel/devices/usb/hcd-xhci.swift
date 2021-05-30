/*
 * kernel/devices/usb/hcd-uhci.swift
 *
 * Created by Simon Evans on 05/10/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * XHCI HCD driver.
 *
 */


final class HCD_XHCI: PCIDeviceDriver, USBHCD, CustomStringConvertible {
    private let deviceFunction: PCIDeviceFunction       // The device (upstream) side of the bridge
    private let baseAddress: UInt32

    let acpiDevice: AMLDefDevice?
    var enabled = true

    var description: String { "XHCI driver @ 0x\(String(baseAddress, radix: 16))" }

    init?(pciDevice: PCIDevice) {
        print("XHCI init")
        guard pciDevice.deviceFunction.deviceClass == PCIDeviceClass(classCode: .serialBusController,
                                                                     subClassCode: PCISerialBusControllerSubClass.usb.rawValue,
                                                                     progInterface: PCIUSBProgrammingInterace.xhci.rawValue) else {
            print("XHCI: \(pciDevice) is not an XHCI Device")
            return nil
        }

        guard let generalDevice = pciDevice.deviceFunction.generalDevice else {
            print("XHCI: Not a PCI generalDevice")
            return nil
        }

        let base = generalDevice.bar0
        guard base & 1 == 0 else {
            print("XHCI: BAR0 address 0x\(String(base, radix: 16)) is not a memory resource")
            return nil
        }

        baseAddress = base & 0xffff_ff00
        print("XHCI: 0x\(String(baseAddress, radix: 16))")
        self.deviceFunction = pciDevice.deviceFunction
        self.acpiDevice = pciDevice.acpiDevice

        let sbrn = deviceFunction.readConfigByte(atByteOffset: 0x60)
        print("XHCI: bus release number 0x\(String(sbrn, radix: 16))")
    }


    func initialiseDevice() {
        print("XHCI driver")

    }

    func allocatePipe(device: USBDevice, endpointDescriptor: USB.EndpointDescriptor) -> USBPipe {
        fatalError("xhci: allocatePipe not implemented")
    }

    func pollInterrupt() -> Bool {
        return false
    }
}
