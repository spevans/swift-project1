//
//  ACPIDeviceConfig.swift
//
//  Created by Simon Evans on 17/10/2024.
//  Copyright © 2024 Simon Evans. All rights reserved.
//
//  All devices found by ACPI enumeration
//


final class ACPIDeviceConfig: CustomStringConvertible {
    let node: ACPI.ACPIObjectNode
    let hid: String?
    let cids: [String]?
    let adr: UInt64?
    let uid: AMLObject?
    let crs: [AMLResourceSetting]?
    let prs: [AMLResourceSetting]?
    let prt: PCIRoutingTable?


    init(node: ACPI.ACPIObjectNode) {
        guard node.object.isDevice else {
            fatalError("ACPI: \(node.fullname()) is not a AMLDefDevice")
        }
        do {
            self.node = node
            self.hid = try node.hardwareId()
            self.cids = try node.compatibleIds()
            self.adr = try node.addressResource()
            self.uid = try node.uniqueId()
            self.crs = try node.currentResourceSettings()
            self.prs = try node.possibleResourceSettings()
            self.prt = node.pciRoutingTable()
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
        return "hid:\(hid ?? "nil") cids:\(cidStr) adr:\(adrStr)" // uid"\(uid ?? "nil") crs:\(crs ?? "nil") prs:\(prs ?? "nil") prt:\(prt ?? "nil")"
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
}
