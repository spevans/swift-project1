/*
 * kernel/devices/8254timer.swift
 *
 * Created by Simon Evans on 10/01/2016.
 * Copyright © 2016, 2018 Simon Evans. All rights reserved.
 *
 * 8254 PIT Programmable Interval Timer.
 *
 */


final class PIT8254: Device, ISADevice, Timer, CustomStringConvertible {

    private let interruptManager: InterruptManager
    private let oscillator = 1193182         // Base frequency
    private let channel0Port: UInt16
    private let channel2Port: UInt16
    private let commandPort: UInt16
    private let irq: UInt8
    private var periodicTimerCallback: (() -> ())? = nil

    // Raw Value is the I/O port
    enum TimerChannel: UInt16 {
        case CHANNEL_0 = 0x40
        // CHANNEL_1 is not valid
        case CHANNEL_2 = 0x42

        var channelSelect: ChannelSelect {
            switch self {
            case .CHANNEL_0: return ChannelSelect.CHANNEL0
            case .CHANNEL_2: return ChannelSelect.CHANNEL2
            }
        }
    }


    // Mode / Command Register commands
    enum ChannelSelect: UInt8 {
        static let mask: UInt8 = 0b11000000

        case CHANNEL0 = 0b00000000
        case CHANNEL1 = 0b01000000
        case CHANNEL2 = 0b10000000
        case READBACK = 0b11000000

        init(channel: UInt8) {
            self.init(rawValue: channel & ChannelSelect.mask)!
        }
    }


    enum AccessMode: UInt8 {
        static let mask: UInt8 = 0b00110000

        case LATCH_COUNT  = 0b00000000
        case LO_BYTE_ONLY = 0b00010000
        case HI_BYTE_ONLY = 0b00100000
        case LO_HI_BYTE   = 0b00110000

        init(mode: UInt8) {
            self.init(rawValue: mode & AccessMode.mask)!
        }
    }


    enum OperatingMode: UInt8 {
        static let mask: UInt8 = 0b00001110

        case MODE_0 = 0b00000000
        case MODE_1 = 0b00000010
        case MODE_2 = 0b00000100
        case MODE_3 = 0b00000110
        case MODE_4 = 0b00001000
        case MODE_5 = 0b00001010
        case MODE_6 = 0b00001100    // Actually mode 2
        case MODE_7 = 0b00001110    // Actually mode 3

        init(mode: UInt8) {
            var value = UInt8(mode & OperatingMode.mask);
            if (value == OperatingMode.MODE_6.rawValue) {
                value = OperatingMode.MODE_2.rawValue
            } else if (value == OperatingMode.MODE_7.rawValue) {
                value = OperatingMode.MODE_3.rawValue
            }
            self.init(rawValue: value)!
        }
    }


    enum NumberMode: UInt8 {
        static let mask: UInt8 = 0b00000001

        case BINARY = 0b00000000
        case BCD    = 0b00000001    // This mode is not supported

        init(mode: UInt8) {
            self.init(rawValue: mode & NumberMode.mask)!
        }
    }

    var description: String {
        return String.sprintf("PIT8254: cmd: 0x%2.2x chan0: 0x%2.2x chan2: 0x%2.2x, irq: %u",
            commandPort, channel0Port, channel2Port, irq)
    }

    var status: String {
        // Readback command, latch status, readback for channels 0,1,2
        let readBackCmd: UInt8 = ChannelSelect.READBACK.rawValue | 0b00101110
        outb(commandPort, readBackCmd)

        // Channel select isnt present in status readback
        var (_, access, mode, number) = fromCommandByte(.CHANNEL_0)
        var divider = (access.rawValue == AccessMode.LO_HI_BYTE.rawValue) ? getCount(TimerChannel.CHANNEL_0) : 0
        var result = "pit: Channel0: access: \(access), mode: \(mode), value: \(number), count: \(divider)\n"

        (_, access, mode, number) = fromCommandByte(.CHANNEL_2)
        divider = (access.rawValue == AccessMode.LO_HI_BYTE.rawValue) ? getCount(TimerChannel.CHANNEL_2) : 0
        result += "pit: Channel2: access: \(access), mode: \(mode), value: \(number), count: \(divider)"

        return result
    }


    required init?(interruptManager: InterruptManager, pnpName: String,
        resources: ISABus.Resources, facp: FACP?) {
        print("PIT8254: init:", resources)

        guard let ports = resources.ioPorts.first, ports.count > 3
            && resources.interrupts.count > 0 else {
            print("PIT8254: Requires 4 IO ports and 1 IRQ")
            return nil
        }
        self.interruptManager = interruptManager
        let idx = ports.startIndex
        channel0Port = ports[ports.index(idx, offsetBy: 0)]
        channel2Port = ports[ports.index(idx, offsetBy: 2)]
        commandPort = ports[ports.index(idx, offsetBy: 3)]
        irq = resources.interrupts[0]
    }


    func enablePeriodicInterrupt(hz: Int, _ callback: @escaping () -> ()) -> Bool {
        setChannel(.CHANNEL_0, mode: .MODE_3, hz: hz)
        periodicTimerCallback = callback
        interruptManager.setIrqHandler(0, handler: timerInterrupt)
        return true
    }


    private func setChannel(_ channel: TimerChannel, mode: OperatingMode,
                            hz: Int) {
        let cmd = toCommandByte(mapChannelToSelect(channel),
                                AccessMode.LO_HI_BYTE, mode, NumberMode.BINARY)
        outb(commandPort, cmd)
        setHz(channel, hz)
    }


    private func toCommandByte(_ channel: ChannelSelect, _ access: AccessMode,
        _ mode: OperatingMode, _ number: NumberMode) -> UInt8 {
            return channel.rawValue | access.rawValue | mode.rawValue | number.rawValue
    }


    private func fromCommandByte(_ channel: TimerChannel) ->
        (ChannelSelect, AccessMode, OperatingMode, NumberMode) {
        let command = inb(mapChannelToPort(channel))
        return (ChannelSelect(channel: command),
                AccessMode(mode: command),
                OperatingMode(mode: command),
                NumberMode(mode: command)
        )
    }


    private func mapChannelToSelect(_ channel: TimerChannel) -> ChannelSelect {
        switch(channel) {
        case .CHANNEL_0: return ChannelSelect.CHANNEL0
        case .CHANNEL_2: return ChannelSelect.CHANNEL2
        }
    }


    private func mapChannelToPort(_ channel: TimerChannel) -> UInt16 {
        switch(channel) {
        case .CHANNEL_0: return channel0Port
        case .CHANNEL_2: return channel2Port
        }
    }


    private func getCount(_ channel: TimerChannel) -> UInt16 {
        let latchCmd = channel.channelSelect.rawValue
        outb(commandPort, latchCmd)
        let lsb = inb(channel.rawValue)
        let msb = inb(channel.rawValue)

        return UInt16.init(withBytes: lsb, msb)
    }


    private func setDivisor(_ channel: TimerChannel, _ value: UInt16) {
        let v = ByteArray2(value)
        outb(channel.rawValue, v[0])
        outb(channel.rawValue, v[1])
    }


    @discardableResult
    private func setHz(_ channel: TimerChannel, _ hz: Int) -> Int {
        let divisor = UInt16(oscillator / hz)
        setDivisor(channel, divisor)

        return Int(oscillator / Int(divisor))
    }


    private func timerInterrupt(irq: Int) {
        if let callback = periodicTimerCallback {
            callback()
        }
    }
}
