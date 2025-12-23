//
//  qemufwcf.swift
//  tests
//
//  Created by Simon Evans on 10/08/2019.
//  Copyright © 2019 Simon Evans. All rights reserved.
//
// QEMU Firmware Configuration (fw_cfg) Device
// https://github.com/qemu/qemu/blob/master/docs/specs/fw_cfg.txt

final class QEMUFWCFG: DeviceDriver {
    private let baseIOPort: UInt16
    private var hasDMAInterface = false

    init?(pnpDevice: PNPDevice) {
        guard let resources = pnpDevice.getResources() else {
            #kprint("QEMU: Cannot get ACPI resources")
            return nil
        }
        #kprint(pnpDevice, "Resources:", resources)
        guard let ioPorts = resources.ioPorts.first, ioPorts.count > 6,
              let basePort = ioPorts.first else {
            #kprint("QEMU: port range is to small:", resources.ioPorts.count)
            return nil
        }
        self.baseIOPort = basePort
        super.init(driverName: "QEMU_FWCFG", device: pnpDevice)
        guard self.initialise() else {
            return nil
        }
    }


    private func initialise() -> Bool {
        let signature = readSignature()
        guard signature == "QEMU" else {
            #kprint("QEMU: Invalid signature", signature)
            return false
        }

        let features = featureBitmap()
        #kprint("Signature:", signature, "features", asHex(features))
        guard features & 1 == 1 else {
            #kprint("QEMU device feature bit doesnt have IO access")
            return false
        }
        hasDMAInterface = (features & 2) != 0
        #kprint("QEMU: DMA interface available")
        return true
    }

    override func info() -> String {
        return #sprintf("baseIOPort: %x hasDMA: %s", baseIOPort, hasDMAInterface)
    }


    private func setIndex(_ index: UInt16) {
        let ioport = self.baseIOPort
        outw(ioport, index)
    }

    private func readData() -> UInt8 {
        return inb(self.baseIOPort + 1)
    }

    private func readSignature() -> String {
        setIndex(0)
        var signature = ""
        for _ in 1...4 {
            signature += String(UnicodeScalar(readData()))
        }
        return signature
    }

    private func featureBitmap() -> UInt32 {
        setIndex(1)
        var shift = UInt32(0)
        var result = UInt32(0)
        for _ in 1...4 {
            result |= (UInt32(readData()) << shift)
            shift += 8
        }
        return result
    }
}
