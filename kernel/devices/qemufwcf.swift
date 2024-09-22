//
//  qemufwcf.swift
//  tests
//
//  Created by Simon Evans on 10/08/2019.
//  Copyright © 2019 Simon Evans. All rights reserved.
//
// QEMU Firmware Configuration (fw_cfg) Device
// https://github.com/qemu/qemu/blob/master/docs/specs/fw_cfg.txt

final class QEMUFWCFG: PNPDeviceDriver {
    let pnpName: String
    let baseIOPort: UInt16
    private(set) var hasDMAInterface = false
    let description = "QEMU_FWCFG"

    init?(pnpDevice: PNPDevice) {
        self.pnpName = pnpDevice.pnpName
        let resources = pnpDevice.resources
        print(pnpDevice.fullName, "Resources:", resources)
        guard let ioPorts = resources.ioPorts.first, ioPorts.count > 6,
              let basePort = ioPorts.first else {
            print("QEMU: port range is to small:", resources.ioPorts.count)
            return nil
        }
        baseIOPort = basePort
    }


    func initialise() -> Bool {
        let signature = readSignature()
        guard signature == "QEMU" else {
            print("QEMU: Invalid signature", signature)
            return false
        }

        let features = featureBitmap()
        print("Signature:", signature, "features", asHex(features))
        guard features & 1 == 1 else {
            print("QEMU device feature bit doesnt have IO access")
            return false
        }
        hasDMAInterface = (features & 2) != 0
        print("QEMU: DMA interface available")
        return true
    }


    func setIndex(_ index: UInt16) {
        let ioport = baseIOPort
        outw(ioport, index)
    }

    func readData() -> UInt8 {
        return inb(baseIOPort + 1)
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
