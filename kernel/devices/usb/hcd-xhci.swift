/*
 * kernel/devices/usb/hcd-uhci.swift
 *
 * Created by Simon Evans on 05/10/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * XHCI HCD driver.
 *
 */


final class HCD_XHCI: PCIDeviceDriver {
    private let baseAddress: UInt32

    override var description: String { "XHCI driver @ 0x\(String(baseAddress, radix: 16))" }


    override init?(pciDevice: PCIDevice) {
        #kprint("XHCI init")
        guard pciDevice.deviceFunction.deviceClass == PCIDeviceClass(classCode: .serialBusController,
                                                                     subClassCode: PCISerialBusControllerSubClass.usb.rawValue,
                                                                     progInterface: PCIUSBProgrammingInterface.xhci.rawValue) else {
            #kprint("XHCI: \(pciDevice) is not an XHCI Device")
            return nil
        }

        guard let generalDevice = pciDevice.deviceFunction.generalDevice else {
            #kprint("XHCI: Not a PCI generalDevice")
            return nil
        }

        let base = generalDevice.bar0
        guard base & 1 == 0 else {
            #kprint("XHCI: BAR0 address 0x\(String(base, radix: 16)) is not a memory resource")
            return nil
        }

        baseAddress = base & 0xffff_ff00
        super.init(pciDevice: pciDevice)
        pciDevice.device.setDriver(self)
        #kprint("XHCI: 0x\(String(baseAddress, radix: 16))")
    }


    override func initialise() -> Bool {
        #kprint("XHCI driver")
        guard let pciDevice = device.busDevice as? PCIDevice else { return false }
        let sbrn = pciDevice.deviceFunction.readConfigByte(atByteOffset: 0x60)
        #kprint("XHCI: bus release number 0x\(String(sbrn, radix: 16))")
        return false
    }


    func allocatePipe(device: USBDevice, endpointDescriptor: USB.EndpointDescriptor) -> USBPipe? {
        fatalError("xhci: allocatePipe not implemented")
    }

    func pollInterrupt() -> Bool {
        return false
    }
}
