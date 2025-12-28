/*
 * kernel/devices/acpi/acpi-ps2.swift
 *
 * Created by Simon Evans on 04/04/2026.
 * Copyright © 2026 Simon Evans. All rights reserved.
 *
 * ACPI PS/2 Keyboard and Mouse device drivers
 *
 * The PNP ACPI device nodes represents the PS/2 keyboard and
 * mouse ports on the i8042 controller. These nodes store the
 * i8042 IO Ports (data and command) and the keyboard and
 * mouse IRQs. The settings may be split between the 2 devices
 * and often the keyboard node holds the IO ports and keyboard
 * IRQ and the mouse node only holds the mouse IRQ.
 * In practice the i8042 Keyboard controller is hardcoded at
 * ports 0x61 and 0x64 and the IRQs are 1 and 12. Also there
 * is only 1 keyboard controller in a system and it is a legacy
 * platform device, only really seen on emulators (QEMU etc),
 * modern hardwre is mostly USB.
 *
 * Actual hardware initialisation (enabling the keyboard and
 * mouse ports, setting sample rate, enabling IRQ 12) is handled
 * by the KBD8042 driver which owns the controller. This driver
 * exists solely to claim the ACPI device nodes so they are not
 * left unregistered and to provide a name visible in the device
 * tree 'dumppnp' command.
 *
 */


private var dataPort: UInt16 = 0x60
private var statusPort: UInt16 = 0x64
private var keyboardIrq = IRQSetting(isaIrq: 1)
private var mouseIrq = IRQSetting(isaIrq: 12)

private var keyboardDevice: PNPDevice? = nil
private var mouseDevice: PNPDevice? = nil

final class ACPIMouse: DeviceDriver {

    init?(pnpDevice: PNPDevice) {
        mouseDevice = pnpDevice
        guard let resources = pnpDevice.getResources() else {
            return nil
        }
        if let ports = resources.ioPorts.first, ports.count == 2 {
            let idx = ports.startIndex
            dataPort = ports[ports.index(idx, offsetBy: 0)]
            statusPort = ports[ports.index(idx, offsetBy: 1)]
        }
        if let irq = resources.interrupts.first {
            mouseIrq = irq
        }
        #kprintf("PS2: mouse port registered (%s)\n", pnpDevice.acpiName())
        return nil
    }
}

final class ACPIKeyboard: DeviceDriver {

    init?(pnpDevice: PNPDevice) {
        keyboardDevice = pnpDevice
        guard let resources = pnpDevice.getResources() else {
            return nil
        }
        if let ports = resources.ioPorts.first, ports.count == 2 {
            let idx = ports.startIndex
            dataPort = ports[ports.index(idx, offsetBy: 0)]
            statusPort = ports[ports.index(idx, offsetBy: 1)]
        }
        if let irq = resources.interrupts.first {
            keyboardIrq = irq
        }
        #kprintf("PS2: keyboard port registered (%s)\n", pnpDevice.acpiName())
        return nil
    }
}


func init8042() {
    system.deviceManager.registerPNPDriver(
        pnpIds: [ "PNP0303", "PNP030B"],
        initialiser: { ACPIKeyboard(pnpDevice: $0) }
    )

    system.deviceManager.registerPNPDriver(
        pnpIds: [ "PNP0F03", "PNP0F13"],
        initialiser: { ACPIMouse(pnpDevice: $0) }
    )
    #kprintf("init8042, drivers registered haveKeyboard: %s haveMouse: %s\n",
             keyboardDevice != nil, mouseDevice != nil)

    if let parent = keyboardDevice?.parent ?? mouseDevice?.parent {
        if let driver = KBD8042(parent: parent,
                    dataPort: dataPort, statusPort: statusPort,
                    keyboardIrq: keyboardIrq, mouseIrq: mouseIrq
        ) {
            if let keyboardDriver = driver.busDevice.devices?[0].deviceDriver {
                keyboardDevice?.setDriver(keyboardDriver)
            }
            if let mouseDriver = driver.busDevice.devices?[1].deviceDriver {
                mouseDevice?.setDriver(mouseDriver)
            }
        }
    }
}
