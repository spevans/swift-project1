/*
 * kernel/devices/acpi/smbios.swift
 *
 * Created by Simon Evans on 02/03/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Parsing of ACPI FACP (Fixed ACPI Description Table). Bare minimum
 * of fields are looked at, just to see if IAPC flags held any information
 */

struct FACP: ACPITable {

    // IA-PC Boot Architecture Flags (bit)
    private let IAPC_LEGACY_DEVICES:    UInt16 = 0
    private let IAPC_8042:              UInt16 = 1
    private let IAPC_VGA_NOT_PRESENT:   UInt16 = 2
    private let IAPC_MSI_NOT_SUPPORTED: UInt16 = 3
    private let IAPC_PCIE_ASPM:         UInt16 = 4
    private let IAPC_RTC_NOT_PRESENT:   UInt16 = 5


    let header: ACPI_SDT
    let iapcLegacyDevices: Bool
    let iapc8042: Bool
    let iapcVgaNotPresent: Bool
    let iapcMsiNotSupported: Bool
    let iapcPcieAspmControls: Bool
    let iapcCmosRtcNotPresent: Bool


    init(acpiHeader: ACPI_SDT, ptr: UnsafePointer<acpi_facp_table>) {
        header = acpiHeader
        let iapc = ptr.pointee.iapc_boot_arch
        iapcLegacyDevices = iapc.bitSet(IAPC_LEGACY_DEVICES)
        iapc8042 = iapc.bitSet(IAPC_8042)
        iapcVgaNotPresent = iapc.bitSet(IAPC_VGA_NOT_PRESENT)
        iapcMsiNotSupported = iapc.bitSet(IAPC_MSI_NOT_SUPPORTED)
        iapcPcieAspmControls = iapc.bitSet(IAPC_PCIE_ASPM)
        iapcCmosRtcNotPresent = iapc.bitSet(IAPC_RTC_NOT_PRESENT)
    }
}
