/*
 * kernel/devices/acpi/acpipower.swift
 *
 * Created by Simon Evans on 28/03/2026.
 * Copyright © 2026 Simon Evans. All rights reserved.
 *
 * ACPI system power management: reboot and shutdown.
 * Reboot uses the FADT Reset Register (ACPI 6.5 4.8.3.6).
 * Shutdown transitions to S5 soft-off (ACPI 6.5 7.4.1).
 *
 */


#if !TEST
extension ACPI {

    // SLP_TYPx field position in PM1x_CNT register (ACPI 6.5 4.8.3.2)
    private static let SLP_TYP_SHIFT: UInt16 = 10
    private static let SLP_TYP_MASK: UInt16  = 0x7
    private static let SLP_EN_BIT: UInt16    = 1 << 13


    /// Reboot the system using the ACPI FADT Reset Register.
    /// Falls back to PCI reset via port 0xCF9 if the reset
    /// register is not supported.
    static func reboot() -> Never {
        if let fadt = ACPI.fadt, fadt.supportsResetRegister {
            let gas = fadt.resetRegister
            let value = fadt.resetValue

            #kprintf("acpi: Rebooting via FADT reset register, address spaceID: %s\n",
                     gas.description)
            if gas.registerBitOffset == 0, gas.registerBitWidth == 8 {
                switch gas.addressSpaceID {
                    case .systemIO:
                        #kprintf("acpi:Rebooting via systemIO port: 0x%x value: %x\n", gas.baseAddress, value)
                        outb(UInt16(gas.baseAddress), value)

                    case .systemMemory:
                        #kprintf("acpi: Rebooting via systemMemory, baseAddress: %p  physicalAddress: %s value: %x\n",
                                 gas.baseAddress, gas.physicalAddress.description, value)
                        let ptr = gas.rawPointer
                        ptr.storeBytes(of: value, as: UInt8.self)

                    case .pciConfig:
                        // PCI config space: bus 0, device 0, function 0,
                        // register offset from low 16 bits of address.
                        // Use legacy PCI config mechanism (CF8h/CFCh).
                        #kprintf("acpi: Rebooting via PCIConfig, baseAddress: %x value: %x\n", gas.baseAddress, value)
                        let offset = UInt32(gas.baseAddress & 0xFFFF)
                        let address: UInt32 = 0x8000_0000 | offset
                        #kprintf("acpi: address: %x offset: %x\n", address, UInt16(offset & 0x3))
                        outl(0xCF8, address)
                        outb(0xCFC + UInt16(offset & 0x3), value)

                    default:
                        #kprint("acpi: Reset Register has invalid addressSpaceID")
                        break
                }
            }
        }
        // Fallback: standard PCI reset via port 0xCF9
        #kprint("acpi: Rebooting via PCI reset (0xCF9)")
        outb(0xCF9, 0x06)
        stop()
    }


    /// Shut down the system by transitioning to ACPI S5 (soft-off).
    /// Looks up \_S5 in the ACPI namespace to obtain the SLP_TYPx
    /// values, then writes PM1a_CNT and PM1b_CNT control registers.
    static func shutdown() -> Never {
        guard let fadt = ACPI.fadt else {
            #kprint("acpi: shutdown: no FADT available")
            stop()
        }

        // Look up \_S5 in the ACPI namespace
        guard let s5Node = ACPI.globalObjects.getObject("\\_S5_") ??
              ACPI.globalObjects.getObject("\\_S5") else {
            #kprint("acpi: shutdown: \\_S5 object not found")
            stop()
        }

        // Evaluate the \_S5 object to get the package
        var context = ACPI.AMLExecutionContext(
            scope: AMLNameString("\\"))
        guard let s5Obj = try? s5Node.readValue(context: &context),
              let pkg = s5Obj.packageValue,
              pkg.count >= 1 else {
            #kprint("acpi: shutdown: \\_S5 is not a valid package")
            stop()
        }

        // \_S5 package: element[0] = SLP_TYPa, element[1] = SLP_TYPb
        // (ACPI 6.5 7.4.2)
        let slpTypA = UInt16(
            (pkg.elements[0].integerValue ?? 0) & UInt64(ACPI.SLP_TYP_MASK))
        let slpTypB: UInt16
        if pkg.count >= 2 {
            slpTypB = UInt16(
                (pkg.elements[1].integerValue ?? 0)
                    & UInt64(ACPI.SLP_TYP_MASK))
        } else {
            slpTypB = slpTypA
        }

        #kprint("acpi: Shutting down (S5)")

        // Disable interrupts before transitioning to S5
        cli()

        // Write PM1a_CNT: SLP_TYPa | SLP_EN
        let pm1aValue: UInt16 = (slpTypA << ACPI.SLP_TYP_SHIFT)
            | ACPI.SLP_EN_BIT
        outw(fadt.pm1aCntBlk, pm1aValue)

        // Write PM1b_CNT if present
        if fadt.pm1bCntBlk != 0 {
            let pm1bValue: UInt16 = (slpTypB << ACPI.SLP_TYP_SHIFT)
                | ACPI.SLP_EN_BIT
            outw(fadt.pm1bCntBlk, pm1bValue)
        }

        // Should not return from S5 transition
        stop()
    }
}
#endif
