/*
 * kernel/devices/acpi/fadt.swift
 *
 * Created by Simon Evans on 02/03/2016.
 * Copyright © 2016 - 2026 Simon Evans. All rights reserved.
 *
 * Parsing of Fixed ACPI Description Table. Signature is FACP. Bare minimum
 * of fields are looked at, just to see if IAPC flags hold any information
 * and for reboot/shutdown values.
 *
 */


struct FADT: CustomStringConvertible {

    private let table: acpi_facp_table

    // IA-PC Boot Architecture Flags (bit) (5.2.9.3)
    private let IAPC_LEGACY_DEVICES     = 0
    private let IAPC_8042               = 1
    private let IAPC_VGA_NOT_PRESENT    = 2
    private let IAPC_MSI_NOT_SUPPORTED  = 3
    private let IAPC_PCIE_ASPM          = 4
    private let IAPC_RTC_NOT_PRESENT    = 5


    var hasLegacyDevices: Bool { table.iapc_boot_arch.bit(IAPC_LEGACY_DEVICES) }
    var has8042Controller: Bool { table.iapc_boot_arch.bit(IAPC_8042)   }
    var isVgaPresent: Bool { table.iapc_boot_arch.bit(IAPC_VGA_NOT_PRESENT) == false }
    var isMsiSupported: Bool { table.iapc_boot_arch.bit(IAPC_MSI_NOT_SUPPORTED) == false }
    var canEnablePcieAspmControls: Bool { table.iapc_boot_arch.bit(IAPC_PCIE_ASPM) == false }
    var hasCmosRtc: Bool { table.iapc_boot_arch.bit(IAPC_RTC_NOT_PRESENT) == false  }
    var rtcCenturyIndex: UInt8 { return table.century }

    var facsAddress: PhysAddress? {
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
        if table.header.length >= 148 {
            return physicalAddress(xAddr: table.x_dsdt, addr: table.dsdt)
        }
        if table.header.length >= 44 {
            return physicalAddress(xAddr: 0, addr: table.dsdt)
        }
        return nil
    }


    // FADT Fixed Feature Flags (Table 5.10)
    private let FADT_FLAG_RESET_REG_SUP = 10

    var supportsResetRegister: Bool {
        table.feature_flags.bit(FADT_FLAG_RESET_REG_SUP)
    }

    var resetRegister: ACPIGenericAddressStrucure {
        ACPIGenericAddressStrucure(table.reset_reg)
    }

    var resetValue: UInt8 { table.reset_value }

    // PM1 Control Block addresses (4.8.3.2)
    var pm1aCntBlk: UInt16 { UInt16(table.pm1a_cnt_blk) }
    var pm1bCntBlk: UInt16 { UInt16(table.pm1b_cnt_blk) }

    // PM Timer (4.8.3.3)
    // Prefer x_pm_tmr_blk (ACPI 2.0 GAS, requires table length >= 220)
    // over the legacy 32-bit I/O port in pm_tmr_blk.
    var pmTimerPort: UInt32? {
        if table.header.length >= 220 {
            let gas = ACPIGenericAddressStrucure(table.x_pm_tmr_blk)
            if case .systemIO = gas.addressSpaceID, gas.baseAddress != 0 {
                return UInt32(gas.baseAddress)
            }
        }
        if table.pm_tmr_blk != 0 {
            return table.pm_tmr_blk
        }
        return nil
    }

    // true = 32-bit counter; false = 24-bit counter (wraps at 0xFFFFFF)
    var pmTimerIs32Bit: Bool { table.pm_tmr_len == 4 }

    var description: String {
        "FADT: hasLegacyDev: \(hasLegacyDevices) has8042: \(has8042Controller) hasVga: \(isVgaPresent) " +
            "hasMSI: \(isMsiSupported) hasRTC: \(hasCmosRtc)"
    }

    init(_ ptr: UnsafeRawPointer) {
        table = ptr.load(as: acpi_facp_table.self)
        FADT.pmTimerPort = UInt16(self.pmTimerPort ?? 0)
    }

    static var pmTimerPort: UInt16 = 0
    private func physicalAddress(xAddr: UInt64, addr: UInt32) -> PhysAddress? {
        if xAddr != 0 {
            return PhysAddress(RawAddress(xAddr))
        } else if addr != 0 {
            return PhysAddress(RawAddress(addr))
        } else {
            return nil
        }
    }
}
