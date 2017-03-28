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
    private let IAPC_LEGACY_DEVICES     = 0
    private let IAPC_8042               = 1
    private let IAPC_VGA_NOT_PRESENT    = 2
    private let IAPC_MSI_NOT_SUPPORTED  = 3
    private let IAPC_PCIE_ASPM          = 4
    private let IAPC_RTC_NOT_PRESENT    = 5


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
        iapcLegacyDevices = iapc.bit(IAPC_LEGACY_DEVICES)
        iapc8042 = iapc.bit(IAPC_8042)
        iapcVgaNotPresent = iapc.bit(IAPC_VGA_NOT_PRESENT)
        iapcMsiNotSupported = iapc.bit(IAPC_MSI_NOT_SUPPORTED)
        iapcPcieAspmControls = iapc.bit(IAPC_PCIE_ASPM)
        iapcCmosRtcNotPresent = iapc.bit(IAPC_RTC_NOT_PRESENT)
    }
}
