/*
 * kernel/devices/acpi/ACPIDeviceConfig.swift
 *
 * Created by Simon Evans on 17/10/2024.
 * Copyright © 2024 Simon Evans. All rights reserved.
 *
 * All devices found by ACPI enumeration
 *
 */

struct ACPIDeviceConfig: CustomStringConvertible {
    let node: ACPI.ACPIObjectNode
    let hid: String?
    let cids: [String]?
    let adr: UInt64?
    let uid: AMLObject?

    init?(node: ACPI.ACPIObjectNode) {
        guard node.object.isDevice else {
            fatalError("ACPI: \(node.fullname()) is not a AMLDefDevice")
        }
        do {
            guard let _hid = try node.hardwareId() else {
                return nil
            }
            self.node = node
            self.hid = _hid
            self.cids = try node.compatibleIds()
            self.adr = try node.addressResource()
            self.uid = try node.uniqueId()
        } catch {
            fatalError("ACPI: \(node.fullname()): error getting device config")
        }
    }

    var description: String {
        var cidStr = "nil"
        if let _cids = cids {
            cidStr = "[" + _cids.joined(separator: ", ") + "]"
        }
        let adrStr = (adr == nil) ? "nil" : "\(adr!.hex())"
        return "hid:\(hid ?? "nil") cids:\(cidStr) adr:\(adrStr)"
    }

    var isPCIHost: Bool {
        return matches(hidOrCid: "PNP0A03") || matches(hidOrCid: "PNP0A08")
    }

    var pnpName: String? {
        return hid ?? cids?.first
    }

    func matches(hidOrCid: String) -> Bool {
        if let hid = self.hid, hidOrCid == hid { return true }
        if let cids = self.cids {
            return cids.contains(where: { $0 == hidOrCid})
        }
        return false
    }

    func matches(hidOrCids: Set<String>) -> String? {
        if let hid = self.hid, hidOrCids.contains(where: { $0 == hid}) {
            return hid
        }
        if let cids = self.cids {
            for cid in cids {
                if hidOrCids.contains(where: { $0 == cid }) {
                    return cid
                }
            }
        }
        return nil
    }

    func crs() -> [AMLResourceSetting]? {
        try? node.currentResourceSettings()
    }

    func prs() -> [AMLResourceSetting]? {
        try? node.possibleResourceSettings()
    }
}
