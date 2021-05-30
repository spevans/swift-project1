/*
 * kernel/devices/usb/hcd-ehci.swift
 *
 * Created by Simon Evans on 05/10/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * EHCI HCD driver.
 *
 */


final class HCD_EHCI: PCIDeviceDriver, USBHCD, CustomStringConvertible {
    private let deviceFunction: PCIDeviceFunction       // The device (upstream) side of the bridge
    private let baseAddress: UInt32
    private let allows64BitMapping: Bool

    let acpiDevice: AMLDefDevice?
    var enabled = true

    var description: String { "EHCI driver @ 0x\(String(baseAddress, radix: 16))" }

    init?(pciDevice: PCIDevice) {
        print("EHCI init:", pciDevice)
        guard pciDevice.deviceFunction.deviceClass == PCIDeviceClass(classCode: .serialBusController,
                                                                    subClassCode: PCISerialBusControllerSubClass.usb.rawValue,
                                                                    progInterface: PCIUSBProgrammingInterace.ehci.rawValue) else {
            print("EHCI: \(pciDevice) is not a EHCI Device")
            return nil
        }

        guard let generalDevice = pciDevice.deviceFunction.generalDevice else {
            print("EHCI: Not a PCI generalDevice")
            return nil
        }

        let base = generalDevice.bar0
        guard base & 1 == 0 else {
            print("EHCI: BAR0 address 0x\(String(base, radix: 16)) is not a memory resource")
            return nil
        }

        allows64BitMapping = base & 0b110 == 0b100
        baseAddress = base & 0xffff_ff00
        print("EHCI: 0x\(String(baseAddress, radix: 16)) allows64BitMapping: \(allows64BitMapping)")
        self.deviceFunction = pciDevice.deviceFunction
        self.acpiDevice = pciDevice.acpiDevice

        let sbrn = deviceFunction.readConfigByte(atByteOffset: 0x60)
        print("EHCI: bus release number 0x\(String(sbrn, radix: 16))")
    }


    func initialiseDevice() {
        print("EHCI driver")
    }

    func allocatePipe(device: USBDevice, endpointDescriptor: USB.EndpointDescriptor) -> USBPipe {
        fatalError("xhci: allocatePipe not implemented")
    }

    func pollInterrupt() -> Bool {
        return false
    }

}
