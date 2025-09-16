/*
 * kernel/devices/usb/hcd-ehci.swift
 *
 * Created by Simon Evans on 05/10/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * EHCI HCD driver.
 *
 */


final class HCD_EHCI: PCIDeviceDriver {
    private let pciDevice: PCIDevice       // The device (upstream) side of the bridge
    let mmioRegion: MMIORegion


    init?(pciDevice: PCIDevice) {

        guard pciDevice.deviceFunction.deviceClass == PCIDeviceClass(classCode: .serialBusController,
                                                                    subClassCode: PCISerialBusControllerSubClass.usb.rawValue,
                                                                    progInterface: PCIUSBProgrammingInterface.ehci.rawValue) else {
            #kprint("EHCI: \(pciDevice) is not a EHCI Device")
            return nil
        }

        guard pciDevice.deviceFunction.generalDevice != nil else {
            #kprint("EHCI: Not a PCI generalDevice")
            return nil
        }

        guard let ioRegion = pciDevice.ioRegionFor(barIdx: 0) else {
            #kprint("EHCI: No valid BAR0")
            return nil
        }

        guard ioRegion.bar.isMemory else {
            #kprint("EHCI: BAR0 is not a memory region")
            return nil
        }

        self.pciDevice = pciDevice
        let region = PhysRegion(start: PhysAddress(RawAddress(ioRegion.baseAddress)), size: UInt(ioRegion.size))

        mmioRegion = mapIORegion(region: region)
        #kprint("EHCI: region:", region, "mmioRegion:", mmioRegion)
        super.init(driverName: "ehci", pciDevice: pciDevice)
        self.setInstanceName(to: "ehci0")
    }


    override func initialise() -> Bool {

        var deviceFunction = pciDevice.deviceFunction
        var pciCommand = deviceFunction.command
        pciCommand.memorySpace = true
        pciCommand.interruptDisable = true //false
        pciCommand.busMaster = true
        deviceFunction.command = pciCommand

        // Read Capability Registers
        let capLength: UInt8 = mmioRegion.read(fromByteOffset: 0)
        let hccParams: UInt32 = mmioRegion.read(fromByteOffset: 8)
        var eecp = UInt((hccParams >> 8) & 0xff)

        while eecp >= 0x40 {
            var eecpId: UInt8 = 0
            var count = 0
            while eecp != 0 {
                eecpId = pciDevice.deviceFunction.readConfigByte(atByteOffset: eecp)
                if eecpId == 1 {
                    break
                }
                eecp = UInt(pciDevice.deviceFunction.readConfigByte(atByteOffset: eecp + 1))
                count += 1
                if count > 3 {
                    eecp = 0
                    eecpId = 0
                    break
                }
            }

            if eecpId == 1 {
                var haveOwnership = false
                let capability = pciDevice.deviceFunction.readConfigByte(atByteOffset: eecp + 2)
                if capability & 1 != 0 {
                    pciDevice.deviceFunction.writeConfigByte(atByteOffset: eecp + 3, value: 1)
                    for _ in 1...10 {
                        sleep(milliseconds: 10)
                        if pciDevice.deviceFunction.readConfigByte(atByteOffset: eecp + 2) & 1 == 0 {
                            haveOwnership = true
                            break
                        }
                    }
                    if haveOwnership {
                    } else {
                        pciDevice.deviceFunction.writeConfigDword(atByteOffset: eecp + 4, value: 0)
                    }
                }
                break
            } else {
                eecp = UInt(pciDevice.deviceFunction.readConfigByte(atByteOffset: eecp + 1))
            }
        }

        // Now have ownership of EHCI controllers so reset and then disable, sending
        // everything to the UHCI controller

        let opBase = Int(capLength)
        mmioRegion.write(value: UInt32(2), toByteOffset: opBase)
        for _ in 1...100 {
            let state: UInt32 = mmioRegion.read(fromByteOffset: opBase)
            if state & 2 == 0 {
                break
            }
            sleep(milliseconds: 10)
        }

        // Clear the USBSTS - Write 1s to set 1s to 0
        let usbSts: UInt32 = mmioRegion.read(fromByteOffset: opBase + 4)
        mmioRegion.write(value: usbSts, toByteOffset: opBase + 4)

        // Set CTRLDSSEGMENT  Control Data Structure Segment Register to 0
        mmioRegion.write(value: UInt32(0), toByteOffset: opBase + 0x10)

        // Disable Interrupts
        mmioRegion.write(value: UInt32(0), toByteOffset: opBase + 0x8)

        // Set USB Command to default
        mmioRegion.write(value: UInt32(0x00080000), toByteOffset: opBase + 0x0)

        var configFlag: UInt32 = mmioRegion.read(fromByteOffset: opBase + 0x40)
        configFlag = 0
        mmioRegion.write(value: configFlag, toByteOffset: opBase + 0x40)
        #kprint("EHCI: ConfigFlag: \(configFlag & 1)")

        return true
    }

    func allocatePipe(endpointDescriptor: USB.EndpointDescriptor) -> USBPipe? {
        fatalError("ehci: allocatePipe not implemented")
    }

    func pollInterrupt() -> Bool {
        return false
    }
}
