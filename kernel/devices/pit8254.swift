/*
 * kernel/devices/8254timer.swift
 *
 * Created by Simon Evans on 10/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * 8254 PIT Programmable Interval Timer
 *
 */


class PIT8254: CustomStringConvertible {

    private let interruptManager: InterruptManager
    private let oscillator = 1193182         // Base frequency
    private let commandPort: UInt16 = 0x43

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
        // Readback command, latch status, readback for channels 0,1,2
        let readBackCmd: UInt8 = ChannelSelect.READBACK.rawValue | 0b00101110
        outb(commandPort, readBackCmd)

        // Channel select isnt present in status readback
        var (_, access, mode, number) = fromCommandByte(inb(TimerChannel.CHANNEL_0.rawValue))
        var divider = (access.rawValue == AccessMode.LO_HI_BYTE.rawValue) ? getCount(TimerChannel.CHANNEL_0) : 0
        var result = "pit: Channel0: access: \(access), mode: \(mode), value: \(number), count: \(divider)\n"

        (_, access, mode, number) = fromCommandByte(inb(TimerChannel.CHANNEL_2.rawValue))
        divider = (access.rawValue == AccessMode.LO_HI_BYTE.rawValue) ? getCount(TimerChannel.CHANNEL_2) : 0
        result += "pit: Channel2: access: \(access), mode: \(mode), value: \(number), count: \(divider)"

        return result
    }


    init(interruptManager: InterruptManager) {
        self.interruptManager = interruptManager
        print("PIC8254: init")
    }


    private func toCommandByte(_ channel: ChannelSelect, _ access: AccessMode,
        _ mode: OperatingMode, _ number: NumberMode) -> UInt8 {
            return channel.rawValue | access.rawValue | mode.rawValue | number.rawValue
    }


    private func fromCommandByte(_ command: UInt8) ->
        (ChannelSelect, AccessMode, OperatingMode, NumberMode) {
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


    func setChannel(_ channel: TimerChannel, mode: OperatingMode,
        hz: Int) {
        let cmd = toCommandByte(mapChannelToSelect(channel),
            AccessMode.LO_HI_BYTE, mode, NumberMode.BINARY)
        outb(commandPort, cmd)
        setHz(channel, hz)
        interruptManager.setIrqHandler(0, handler: timerInterrupt)
    }


    private func getCount(_ channel: TimerChannel) -> UInt16 {
        let latchCmd = channel.channelSelect.rawValue
        outb(commandPort, latchCmd)
        let lsb = inb(channel.rawValue)
        let msb = inb(channel.rawValue)

        return UInt16.init(msb: msb, lsb: lsb)
    }


    private func setDivisor(_ channel: TimerChannel, _ value: UInt16) {
        let (msb, lsb) = value.toBytes()
        outb(channel.rawValue, lsb)
        outb(channel.rawValue, msb)
    }


    @discardableResult
    private func setHz(_ channel: TimerChannel, _ hz: Int) -> Int {
        let divisor = UInt16(oscillator / hz)
        setDivisor(channel, divisor)

        return Int(oscillator / Int(divisor))
    }

    // FIXME: This is unsafe, needs atomic read/write or some locking
    private var ticks: UInt64 = 0

    private func timerInterrupt(irq: Int) {
        ticks += 1
        if (ticks % 0x200) == 0 {
            kprint("\ntimerInterrupt:")
            kprint_qword(ticks)
            kprint("\n")
        }
        // Do nothing for now
    }
}
