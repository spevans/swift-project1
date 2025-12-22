/*
 *  i915.swift
 *  Kernel
 *
 *  Created by Simon Evans on 05/07/2025.
 *
 *  i915 Driver for Intel Integrated Graphics
 */


/**

Initial driver for Intel GPUs, the aim is to use it for text mode
and 2D graphics. Currently enables the ring buffer and sends comands
to the 2D Blitter engine to draw characters onto the screen.

The mode setting does not currently work, it assumes that the screen
has been setup using the EFI frame buffer and just retain the current
screen settings.

Currently one PCI device is supported, a GMA X3100 as found in a
MacBook3,1.

The driver needs to be loaded by running the 'i915' command.

**/


private let pciIds: InlineArray<_, PCIDeviceMatch> = [
    .init(vendor: 0x8086, deviceId: 0x2a02, function: 0),
    .init(vendor: 0x8086, deviceId: 0x0a2e, function: 0),
]

final class I915: DeviceDriver {
    private let pciDevice: PCIDevice       // The device (upstream) side of the bridge

    let mmioRegion: MMIORegion
    let fbBaseAddr: UInt64
    private let ioBaseAddress: UInt32
    let ringBufferMmioRegion: MMIORegion
    let baseOfStolenMemory: UInt32

    let gttaddr: UInt64
    let gttMmioRegion: MMIORegion    // GTT address from BAR
    var rbDebug = false
    private var fontAddress: UInt32 = 0
    var height = 0
    var width = 0


    // TODO, find current lines, width pitch bpp from video card
    init?(pciDevice: PCIDevice) {

        guard PCIDeviceMatch.matches(pciIds.span, device: pciDevice) else {
            #kprintf("i915: %s not an i915 device\n", pciDevice.description)
            return nil
        }

        guard pciDevice.deviceFunction.function == 0 else {
            #kprintf("i915: Only function 0 supported, not %d\n", pciDevice.deviceFunction.function)
            return nil
        }

        guard let generalDevice = pciDevice.deviceFunction.generalDevice else {
            #kprint("i915: Not a general PCI device")
            return nil
        }

        self.pciDevice = pciDevice
        baseOfStolenMemory = pciDevice.deviceFunction.readConfigDword(atByteOffset: 0x5c)

        // FIXME: use the PCI_IO_BAR for this
        let gttmmadr: UInt64 = UInt64(generalDevice.bar0) | UInt64(generalDevice.bar1) << 32
        #kprintf("i915: GTTMMADR: 0x%16.16x\n", gttmmadr)
        let mmioBase = gttmmadr & 0xf_fff0_fff0
        gttaddr = mmioBase + (512 * 1024)
        #kprintf("i915: GTTMMADR: 64bit: %s, iospace: %s, mmioBase: %p gttaddr: %p\n",
                 gttmmadr & 0b110 == 0b110, gttmmadr & 1 == 1, mmioBase, gttaddr)

        let gmadr = UInt64(generalDevice.bar2) | UInt64(generalDevice.bar3) << 32
        fbBaseAddr = gmadr & 0xf_ffff_fff0
        #kprintf("i915: GMADR: 0x%16.16x\n", gmadr)
        #kprintf("i915: GMADR: 64bit: %s iospace: %s, fbBaseAddr: %p\n",
                 gmadr & 0b110 == 0b110, gmadr & 1 == 1, fbBaseAddr)


        let ioBar = generalDevice.bar4
        ioBaseAddress = ioBar & 0xffff_fff8
        #kprintf("i915: ioBar: 0x%8.8x, ioBaseAddress: 0x%8.8x, is32bit: %s, ioSpace: %s\n",
                 ioBar, ioBaseAddress, ioBar & 0b110 == 0b110, ioBar & 1 == 1)

        let physRegion = PhysRegion(start: PhysAddress(UInt(mmioBase)), size: 512 * 1024)
        mmioRegion = mapIORegion(region: physRegion, cacheType: .uncacheable)

        let gttRegion = PhysRegion(start: PhysAddress(UInt(gttaddr)), size: 512 * 1024)
        gttMmioRegion = mapIORegion(region: gttRegion, cacheType: .writeCombining)

        // Map the ringbuffer
        let prb0Start: UInt32 = mmioRegion.read(fromByteOffset: 0x2038)
        let rbPhysAddress = PhysAddress(RawAddress(UInt64(prb0Start & 0xffff_f000) + fbBaseAddr))
        let prb0Ctl: UInt32 = mmioRegion.read(fromByteOffset: 0x203c)
        let rbPageCount = ((prb0Ctl >> 12) & 0x1ff) + 1
        let rbLength = UInt(rbPageCount) * 4096
        #kprintf("i915: RingBuffer @: %p  pages: %d  size: 0x%x\n",
                 rbPhysAddress.value, rbPageCount, rbLength)

        let ringBufferPhysRegion = PhysRegion(start: rbPhysAddress, size: rbLength)
        ringBufferMmioRegion = mapIORegion(region: ringBufferPhysRegion, cacheType: .uncacheable)

        super.init(driverName: "i915", device: pciDevice.device)
        if let frameBufferInfo = system.frameBufferInfo {
            #kprintf("EFI Frame buffer baseAddress: %p size: 0x%x\n", frameBufferInfo.address, frameBufferInfo.size)
            height = Int(frameBufferInfo.height)
            width = Int(frameBufferInfo.width)
            if let tty = I915TTY(gpu: self, frameBufferInfo: frameBufferInfo) {
                tty.addTTYDriver()
                #kprint("Added i915 TTY driver")
            } else {
                #kprint("Failed to add i915 TTY driver")
            }
        }
        device.setDriver(self)
        self.setInstanceName(to: "intel-gpu0")
    }

    override func initialise() -> Bool {
        return true
    }


    private func showInfo() {

        let vgaCntrl: UInt32 = mmioRegion.read(fromByteOffset: 0x71400)
        #kprintf("i915: vgaCNTRL: 0x%8.8x vga disabled: %s\n", vgaCntrl, (vgaCntrl & 1 << 31 != 0))

        #kprintf("Stolen Memory base: 0x%8.8x\n", baseOfStolenMemory)

        let msac = self.pciDevice.deviceFunction.readConfigByte(atByteOffset: 0x62)
        #kprintf("MSAC: %x\n", msac)
        let apertureSize: UInt32 = switch msac & 0b110 {
            case 0b110: 512 * 1024 * 1024
            case 0b010: 256 * 1024 * 1024
            case 0b000: 128 * 1024 * 1024
            default: 0
        }
        #kprintf("FB BaseAddress: %p  Aperture Size: 0x%8.8x\n", fbBaseAddr, apertureSize)
        #kprintf("Aperture from %p - %p\n", fbBaseAddr, fbBaseAddr + UInt64(apertureSize) - 1)

        #kprint("Display A Plane Control")
        let dspacntr: UInt32 = mmioRegion.read(fromByteOffset: 0x70180)
        #kprintf("DSPACNTR: 0x%8.8x  enabled: %s Pixel Format 0b%4.4b  px mult: %u  tiled: %s\n",
                 dspacntr, dspacntr.bit(31), (dspacntr >> 26) & 0xf, (dspacntr >> 20) & 3, dspacntr.bit(10))
        let dspalinoff: UInt32 = mmioRegion.read(fromByteOffset: 0x70184)
        #kprintf("DSPALINOFF: 0x%8.8x\n", dspalinoff)
        let dspastride: UInt32 = mmioRegion.read(fromByteOffset: 0x70188)
        #kprintf("DSPASTRIDE: 0x%8.8x\n", dspastride)
        let dspasurf: UInt32 = mmioRegion.read(fromByteOffset: 0x7019c)
        #kprintf("DSPASURF: 0x%8.8x\n", dspasurf)
        let dspatileoff: UInt32 = mmioRegion.read(fromByteOffset: 0x701a4)
        #kprintf("DPSATILEOFF: 0x%8.8x  startY: %u  startX: %u\n", dspatileoff, (dspatileoff >> 16) & 0xfff, dspalinoff & 0xfff)

        #kprint("Display B Plane Control")
        let dspbcntr: UInt32 = mmioRegion.read(fromByteOffset: 0x71180)
        #kprintf("DSPBCNTR: 0x%8.8x  enabled: %s Pixel Format 0b%4.4b  px mult: %u  tiled: %s\n",
                 dspbcntr, dspbcntr.bit(31), (dspbcntr >> 26) & 0xf, (dspbcntr >> 20) & 3, dspbcntr.bit(10))
        let dspblinoff: UInt32 = mmioRegion.read(fromByteOffset: 0x71184)
        #kprintf("DSPBLINOFF: 0x%8.8x\n", dspblinoff)
        let dspbstride: UInt32 = mmioRegion.read(fromByteOffset: 0x71188)
        #kprintf("DSPBSTRIDE: 0x%8.8x\n", dspbstride)
        let dspbsurf: UInt32 = mmioRegion.read(fromByteOffset: 0x7119c)
        #kprintf("DSPBSURF: 0x%8.8x\n", dspbsurf)
        let dspbtileoff: UInt32 = mmioRegion.read(fromByteOffset: 0x711a4)
        #kprintf("DPSBTILEOFF: 0x%8.8x  startY: %u  startX: %u\n", dspbtileoff, (dspbtileoff >> 16) & 0xfff, dspblinoff & 0xfff)

        let displaySurfaceAddr: UInt32?
        if dspacntr.bit(31) {
            #kprint("Display A Surface enabled")
            displaySurfaceAddr = dspasurf
        } else if dspbcntr.bit(31) {
            #kprint("Display B Surface enabled")
            displaySurfaceAddr = dspbsurf
        } else {
            #kprint("No display surface enabled")
            displaySurfaceAddr = nil
        }
        guard let displaySurfaceAddr else {
            #kprint("No active display")
            return
        }

        #kprintf("Display Surface Address: 0x%8.8x\n", displaySurfaceAddr)
    }


    override func debug(arguments: [String]) {
        guard let command = arguments.first else {
            return
        }
        let arguments = arguments[1...]

        switch command {
            case "rb":
                var commands: [UInt32] = []
                for rbCmd in arguments {
                    if let val = UInt32(rbCmd) {
                        commands.append(val)
                    } else {
                        #kprintf("Invalid number string %s\n", rbCmd)
                        return
                    }
                }
                writeToRingBuffer(commands.span)

            case "rdmm":
                guard let address = arguments.first, let offset = UInt32(address) else {
                    #kprint("error: missing/invalid address")
                    return
                }
                let value: UInt32 = mmioRegion.read(fromByteOffset: Int(offset))
                #kprintf("%8.8x: 0x%8.8x   0b%32.32b\n", offset, value, value)

            case "wrmm":
                guard arguments.count == 2, let offset = UInt32(arguments[1]), let value = UInt32(arguments[2]) else {
                    #kprint("error: missing/invalid address or value")
                    return
                }
                mmioRegion.write(value: value, toByteOffset: Int(offset))
                let value2: UInt32 = mmioRegion.read(fromByteOffset: Int(offset))
                #kprintf("%8.8x: 0x%8.8x   0b%32.32b\n", offset, value2, value2)

            case "fences":
                for idx in 0..<16 {
                    let fence: UInt64 = mmioRegion.read(fromByteOffset: 0x3000 + idx * 8)
                    guard fence.bit(0) else { continue } // Ignore invalid FENCEs
                    let lower = UInt32(truncatingIfNeeded: fence & 0xffff_f000)
                    let upper = UInt32(truncatingIfNeeded: (fence >> 32) & 0xffff_f000)
                    #kprintf("%2d: bounds: 0x%8.8x - 0x%8.8x  size: 0x%x   pitch: %u Tile: %s\n",
                             idx, lower, upper, (upper - lower) + 4096,
                             128 * ((fence >> 2 & 0x3ff) + 1), fence.bit(1) ? "Y" : "X"
                    )
                }

            case "info":
                showInfo()

            case "rbreset":
                rbReset()
                fallthrough

            case "rbinfo":
                rbInfo()

            case "rbdebug":
                if arguments.count == 1 {
                    if arguments[1] == "on" { rbDebug = true }
                    if arguments[1] == "off" { rbDebug = false }
                }
                #kprintf("rbDebug: %s\n", rbDebug)

            case "miflush":
                miFlush()

            case "xy_color_blt":
                guard arguments.count == 5,
                      let x1 = UInt16(arguments[1]), let y1 = UInt16(arguments[2]),
                      let x2 = UInt16(arguments[3]), let y2 = UInt16(arguments[4]),
                      let colour = UInt32(arguments[5]) else {
                    #kprint("xy_color_blt x1 y1 x2 y2 colour")
                    return
                }
                xy_color_blt(x1: x1, y1: y1, x2: x2, y2: y2, colour: colour)

            case "xy_src_copy_blt":
                guard arguments.count == 6,
                      let x1 = UInt16(arguments[1]), let y1 = UInt16(arguments[2]),
                      let x2 = UInt16(arguments[3]), let y2 = UInt16(arguments[4]),
                      let sx1 = UInt16(arguments[5]), let sy1 = UInt16(arguments[6])
                else {
                    #kprint("xy_src_copy_blt x1 y1 x2 y2 sx1 sy1")
                    return
                }
                xy_src_copy_blt(x1: x1, y1: y1, x2: x2, y2: y2, sourceX1: sx1, sourceY1: sy1)

            case "xy_setup_blt":
                guard arguments.count == 2, let bgColour = UInt32(arguments[1]), let fgColour = UInt32(arguments[2]) else {
                    #kprint("xy_setup_blt bgColour fgColour")
                    return
                }
                xy_setup_blt(bgColour: bgColour, fgColour: fgColour)

            case "xy_text_blt":
                guard arguments.count == 5,
                      let x1 = UInt16(arguments[1]), let y1 = UInt16(arguments[2]),
                      let x2 = UInt16(arguments[3]), let y2 = UInt16(arguments[4]),
                      arguments[5].count == 1 else {
                    #kprint("xy_text_blt x1 y1 x2 y2 character")
                    return
                }

                guard let character = arguments[5].first?.asciiValue else {
                    #kprintf("Invalid character '%s'\n", arguments[5])
                    return
                }
                let chOffset = UInt32(character) * 16
                guard fontAddress > 0 else {
                    #kprint("Font Address not set")
                    return
                }
                let sourceAddress = fontAddress + chOffset
                #kprintf("characterAddress: 0x%x\n", sourceAddress)
                xy_text_blt(x1: x1, y1: y1, x2: x2, y2: y2, sourceAddress: sourceAddress)


            case "xy_text_immediate_blt":
                guard arguments.count == 5, let x1 = UInt16(arguments[1]), let y1 = UInt16(arguments[2]),
                      let x2 = UInt16(arguments[3]), let y2 = UInt16(arguments[4]),
                      arguments[5].count == 1 else {
                    #kprint("xy_text_immediate_blt x1 y1 x2 y2 character")
                    return
                }
                guard let character = arguments[5].first?.asciiValue else {
                    #kprintf("Invalid character '%s'\n", arguments[5])
                    return
                }
                let font = Font(
                    width: 8, height: 16, data: UnsafePointer<UInt8>(bitPattern: UInt(bitPattern: &fontdata_8x16))!
                )
                let characterData = font.characterData(Int(character))
                xy_text_immediate_blt(x1: x1, y1: y1, x2: x2, y2: y2, characterData: characterData)

            case "dumpgtt":
                dumpGTTRanges()

            case "gttaddr":
                guard arguments.count == 1, let virtAddress = UInt32(arguments[1]) else {
                    #kprint("gttaddr <virtAddress>")
                    return
                }
                if let pte = gttVirtToPTE(virtAddress) {
                    #kprintf("0x%8.8x -> %s\n", virtAddress, pte.description)
                } else {
                    #kprintf("Invalid virtual address 0x%8.8x\n", virtAddress)
                }

            case "copyfont":
                guard arguments.count == 2, let address = UInt32(arguments[1]), let physAddress = RawAddress(arguments[2]) else {
                    #kprint("copyfont <virtAddress> <physAddress>")
                    return
                }
                if let newAddress = copyFont(to: address, physAddress: physAddress) {
                    self.fontAddress = newAddress
                    #kprintf("New font address: %p\n", self.fontAddress)
                } else {
                    #kprint("Failed to copy font data")
                }

            case "fonttest":
                guard fontAddress > 0 else {
                    #kprint("Font Address not set")
                    return
                }
                xy_setup_blt(bgColour: 0xff000000, fgColour: 0xffffffff)


                for line in 0..<20 {
                    var sourceAddress = fontAddress
                    for ch in 0..<256 {
                        let x1 = UInt16(ch % 128) * 10
                        let y1 = UInt16(line * 40) + (UInt16(ch / 128) * 20)
                        let x2 = x1 + 8
                        let y2 = y1 + 16
                        xy_text_blt(x1: x1, y1: y1, x2: x2, y2: y2, sourceAddress: sourceAddress)
                        sourceAddress += 16
                    }
                    miFlush()
                }

            case "edid":
                guard arguments.count == 1, let pin = Int(arguments[1]) else {
                    #kprint("edid <pin>")
                    return
                }
                readEdid(pin: pin)

            default:
                #kprintf("Invalid command '%s'\n", command)
        }
    }


    func miFlush() {
        let commands: InlineArray<_, UInt32> = [0x2000000, 0]
        writeToRingBuffer(commands.span)
    }
}


func testi915(arguments: [String]) {
    #kprint("Looking for an i915")
    if system.deviceManager.getDeviceByName("i915") != nil {
        #kprint("i915 already initialised")
        return
    }
    guard let rootPCIBus = pciHostBus else {
        #kprint("No PCI bus found")
        return
    }
    rootPCIBus.devicesMatching(pciIds.span) { pciDevice in
        #kprint("Found a device at ", pciDevice.description)
        guard let driver = I915(pciDevice: pciDevice), driver.initialise() else {
            #kprint("Failed to initialise driver")
            return
        }
    }
    #kprint("Finished looking for an i915")
}
