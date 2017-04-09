/*
 * kernel/devices/acpi/smbios.swift
 *
 * Created by Simon Evans on 02/03/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Parsing of ACPI FACP (Fixed ACPI Description Table). Bare minimum
 * of fields are looked at, just to see if IAPC flags held any information.
 */

struct FACP: ACPITable {

    private let tablePtr: UnsafePointer<acpi_facp_table>

    // IA-PC Boot Architecture Flags (bit)
    private let IAPC_LEGACY_DEVICES     = 0
    private let IAPC_8042               = 1
    private let IAPC_VGA_NOT_PRESENT    = 2
    private let IAPC_MSI_NOT_SUPPORTED  = 3
    private let IAPC_PCIE_ASPM          = 4
    private let IAPC_RTC_NOT_PRESENT    = 5


    var hasLegacyDevices: Bool {
        return tablePtr.pointee.iapc_boot_arch.bit(IAPC_LEGACY_DEVICES)
    }

    var has8042Controller: Bool {
        return tablePtr.pointee.iapc_boot_arch.bit(IAPC_8042)
    }

    var isVgaPresent: Bool {
        return tablePtr.pointee.iapc_boot_arch.bit(IAPC_VGA_NOT_PRESENT) == false
    }

    var isMsiSupported: Bool {
        return tablePtr.pointee.iapc_boot_arch.bit(IAPC_MSI_NOT_SUPPORTED) == false
    }

    var canEnablePcieAspmControls: Bool {
        return tablePtr.pointee.iapc_boot_arch.bit(IAPC_PCIE_ASPM) == false
    }

    var hasCmosRtc: Bool {
        return tablePtr.pointee.iapc_boot_arch.bit(IAPC_RTC_NOT_PRESENT) == false
    }

    var facsAddress: PhysAddress? {
        let table = tablePtr.pointee
        if table.header.length >= 140 {
            return physicalAddress(xAddr: table.x_firmware_ctrl,
                                   addr: table.firmware_ctrl)
        }
        if table.header.length >= 40 {
            return physicalAddress(xAddr: 0, addr: table.firmware_ctrl)
        }
        return nil
    }

    var dsdtAddress: PhysAddress? {
        let table = tablePtr.pointee
        if table.header.length >= 148 {
            return physicalAddress(xAddr: table.x_dsdt, addr: table.dsdt)
        }
        if table.header.length >= 44 {
            return physicalAddress(xAddr: 0, addr: table.dsdt)
        }
        return nil
    }


    init(_ ptr: UnsafeRawPointer) {
        tablePtr = ptr.bindMemory(to: acpi_facp_table.self, capacity: 1)
    }
}
