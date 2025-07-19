/*
 *  i915i2c.swift
 *  Kernel
 *
 *  Created by Simon Evans on 09/08/2025.
 *
 *  Intel GPU I2C functions using the GMBUS
 *
 */


extension I915 {

    func readEdid(pin: Int) {
        // Pin Pair Select: Integrated Digital Panel DDC pins
        #kprint("GMBus registers")
        for register in 0...4 {
            _ = readGmbus(register: register)

        }

        #kprintf("i915: Reading EDID for pin %d\n", pin)
        resetGmbus()
        let pinPairSelect = UInt32(pin)
        writeGmbus(register: 0, value: pinPairSelect)
        let edidAddress: UInt8 = 0x50
        guard let edidData = readI2C(address: edidAddress, offset: 0, count: 128) else {
            #kprint("Failed to read EDID")
            return
        }
        guard edidData.count == 128 else {
            #kprintf("i915: EDID only returned %d bytes\n", edidData.count)
            return
        }
        hexDump(buffer: edidData)
        let edid = EDID(from: edidData)
        #kprint("i915: EDID dump")
        edid.dump()

    }

    private func resetGmbus() {
        #kprint("Resetting GMBUS")
        writeGmbus(register: 1, value: 1 << 31)
        writeGmbus(register: 1, value: 0)
        writeGmbus(register: 0, value: 0)
        writeGmbus(register: 4, value: 0)
        sleep(milliseconds: 1)
        #kprint("Getting GMBUS2 status")
        _ = readGmbus(register: 2)
    }


    private func writeI2C(address: UInt8, data: [UInt8]) -> Int {

        guard data.count > 0 else { return 0 }
        var iterator = data.makeIterator()

        // Read upto 4 bytes from the buffer to create the next 32bit data block
        func write4Bytes() -> Int {
            guard let byte = iterator.next() else { return 0 }
            var count = 1
            var data = UInt32(byte)
            for idx in 1...3 {
                guard let byte = iterator.next() else { break }
                data |= UInt32(byte) << (idx * 8)
                count += 1
            }
            // Write DWord to GMBUS3 - GMBus Data Buffer
            writeGmbus(register: 3, value: data)
            #kprintf("writeI2C: write4byes wrote %d bytes, value: 0x%8.8x\n", count, data)
            return count
        }

        var totalBytesWritten = write4Bytes()
        // Software Ready, Bus Cycle Select = wait, Write
        let command: UInt32 = UInt32(1) << 30 | UInt32(1) << 25 |  UInt32(data.count) << 16 |  UInt32(address << 1) | 0 // Write
        #kprintf("writeI2C: Writing 0x%8.8x to GMBUS Command\n", command)
        writeGmbus(register: 1, value: command)
        guard waitForGmbusHWReady() else {
            #kprint("writeI2C: aborting, wrote 0 bytes")
            return 0
        }

        while true {
            let count = write4Bytes()
            if count == 0 { break }
            guard waitForGmbusHWReady() else {
                #kprintf("writeI2C: aborting, wrote %d bytes\n", totalBytesWritten)
                return totalBytesWritten
            }
            totalBytesWritten += count
        }
        guard waitForGmbusCompletion() else {
            #kprint("writeI2C: FMBus did not indicate completeion")
            return totalBytesWritten
        }
        #kprintf("writeI2C: successfully wrote %d bytes\n", totalBytesWritten)
        return totalBytesWritten
    }

    private func readI2C(address: UInt8, offset: Int, count: Int) -> [UInt8]? {
        var result: [UInt8] = []
        result.reserveCapacity(count)
        var bytesRead = 0

        func read4Bytes() -> Int {
            let toRead = min(count - bytesRead, 4)
            var value = readGmbus(register: 3)
            for _ in 1...toRead {
                result.append(UInt8(truncatingIfNeeded: value))
                value >>= 8
            }
            return toRead
        }

        // Software Ready, Bus Cycle Select = wait, Read
        let command: UInt32 = UInt32(1) << 30 | UInt32(3) << 25 |  UInt32(count) << 16 |  UInt32(address << 1) | 1 // Read + Index + Wait
        #kprintf("readI2C: Writing 0x%8.8x to GMBUS Command\n", command)
        writeGmbus(register: 1, value: command)

        while bytesRead < count {
            guard waitForGmbusHWReady() else {
                #kprintf("I2Cread: aborting, read %d bytes\n", bytesRead)
                return result
            }
            let read = read4Bytes()
            bytesRead += read
        }

        guard waitForGmbusCompletion() else {
            #kprint("readI2C: GMBus did not indicate completion")
            return result
        }
        #kprintf("readI2C: successfully read %d bytes\n", bytesRead)
        return result
    }

    private func waitForGmbusHWReady() -> Bool {
        var count = 0
        while count < 20 {
            sleep(milliseconds: 1)
            let status = readGmbus(register: 2)
            if status & (1 << 10) != 0 {
                #kprint("GMBUS returned NAK")
                return false
            }
            if status & (1 << 11) != 0 { break }
            count += 1
        }
        if count == 20 {
            #kprint("GMBUS timed out waiting for HW_RDY")
            return false
        }
        return true
    }

    private func waitForGmbusCompletion() -> Bool {
        var count = 0
        while count < 20 {
            sleep(milliseconds: 1)
            let status = readGmbus(register: 2)
            #kprintf("waitForGmbusHWReady: status: %8.8x\n", status)
            if status & (1 << 10) != 0 {
                #kprint("GMBUS returned NAK")
                return false
            }
            if status & (1 << 14) != 0 { break }
            count += 1
        }
        if count == 20 {
            #kprint("GMBUS timed out waiting for HW_RDY")
            return false
        }

        return true
    }

    private func writeGmbus(register: Int, value: UInt32) {
        mmioRegion.write(value: value, toByteOffset: 0x5100 + (4 * register))
    }

    private func readGmbus(register: Int) -> UInt32 {
        let value: UInt32 = mmioRegion.read(fromByteOffset: 0x5100 + (4 * register))
        return value
    }
}
