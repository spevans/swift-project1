//
//  devices/kernel/tty/TextTTY.swift
//  project1
//
//  Created by Simon Evans on 03/08/2025.
//


struct TextTTY {
    // VGA Text Mode Hardware constants
    static private let SCREEN_BASE_ADDRESS: UInt = 0xB8000
    // Motorola 6845 CRT Controller registers
    static private let CRT_IDX_REG: UInt16 = 0x3d4
    static private let CRT_DATA_REG: UInt16 = 0x3d5
    static private let CURSOR_MSB_IDX: UInt8 = 0xE
    static private let CURSOR_LSB_IDX: UInt8 = 0xF
    // bright green characters on a black background
    static private let textColour: CUnsignedChar = 0xA
    // black space on black background
    static private let blankChar = UInt16(withBytes: SPACE, 0)

    private var totalChars: Int = 0
    private(set) var charsPerLine: TextCoord = 0
    private(set) var totalLines:   TextCoord = 0
    private var physRegion = PhysRegion(start: PhysAddress(0), size: 1)
    private var mmioRegion = MMIORegion.invalidRegion()

    private var _cursorX: TextCoord = 0
    private var _cursorY: TextCoord = 0


    var cursorX: TextCoord {
        get { _cursorX }
        set {
            guard newValue < charsPerLine else {
                return
            }
            _cursorX = newValue
            writeCursor(_cursorX, cursorY)
        }
    }

    var cursorY: TextCoord {
        get { _cursorY }
        set {
            guard newValue < totalLines else {
                return
            }
            _cursorY = newValue
            writeCursor(_cursorX, _cursorY)
        }
    }


    init() {
    }

    mutating func setActive() {
        // This exists so that init() can be called as the instance is global and will be in the .bss
        // init() cannot be called directly.
        charsPerLine = 80
        totalLines = 25
        totalChars = Int(totalLines) * Int(charsPerLine)

        physRegion = PhysRegion(start: PhysAddress(Self.SCREEN_BASE_ADDRESS), size: UInt(totalChars * MemoryLayout<UInt16>.size))
        mmioRegion = MMIORegion(physRegion)
    }

    mutating func updateMapping() {
        mmioRegion = mapIORegion(region: physRegion, cacheType: .writeCombining)
    }


    @inline(never)
    func printChar(_ character: UInt8, x: TextCoord, y: TextCoord) {
        guard x < charsPerLine && y < totalLines else {
            return
        }
        let offset = Int((y * charsPerLine) + x)
        let value = UInt16(withBytes: character, Self.textColour)
        mmioRegion.write(value: value, toByteOffset: offset * MemoryLayout<UInt16>.size)
    }


    func clearScreen() {
        for i in 0..<totalChars {
            mmioRegion.write(value: Self.blankChar, toByteOffset: i * MemoryLayout<UInt16>.size)
        }
    }


    func scrollUp() {
        // Scroll screen up by one line
        let charCount = Int((totalLines - 1) * charsPerLine)

        for i in 0..<charCount {
            let value: UInt16 = mmioRegion.read(fromByteOffset: (Int(charsPerLine) &+ i) &* MemoryLayout<UInt16>.size)
            mmioRegion.write(value: value, toByteOffset: i &* MemoryLayout<UInt16>.size)
        }

        // Clear new bottom line with blank characters
        let bottomLine = Int((totalLines - 1) * charsPerLine)
        for i in 0..<Int(charsPerLine) {
            mmioRegion.write(value: Self.blankChar, toByteOffset: (bottomLine &+ i) &* MemoryLayout<UInt16>.size)
        }
    }


    // FIXME: I/O Access to CRT Registers should be behind a lock
    // Return hardware cursor x, y from video card
    private func readCursor() -> (TextCoord, TextCoord) {
        outb(Self.CRT_IDX_REG, Self.CURSOR_MSB_IDX)
        let msb = inb(Self.CRT_DATA_REG)
        outb(Self.CRT_IDX_REG, Self.CURSOR_LSB_IDX)
        let lsb = inb(Self.CRT_DATA_REG)
        let address = UInt16(withBytes: lsb, msb)
        let x = address % UInt16(charsPerLine)
        let y = address / UInt16(charsPerLine)
        return fixCursor(TextCoord(x), TextCoord(y))
    }


    // Set hardware cursor x, y on video card
    private func writeCursor(_ x: TextCoord, _ y: TextCoord) {
        let (x, y) = fixCursor(x, y)
        let address = ByteArray2(y * charsPerLine + x)
        let addressLSB = address[0]
        let addressMSB = address[1]
        outb(Self.CRT_IDX_REG, Self.CURSOR_MSB_IDX)
        outb(Self.CRT_DATA_REG, addressMSB)
        outb(Self.CRT_IDX_REG, Self.CURSOR_MSB_IDX)
        outb(Self.CRT_DATA_REG, addressLSB)
    }


    // Dont let the HW cursor off the screen
    private func fixCursor(_ x: TextCoord, _ y: TextCoord) -> (TextCoord, TextCoord) {
        return (min(x, charsPerLine - 1), min(y, totalLines - 1))
    }

    mutating func doTimings() -> TTY.Timings {
        let fullscreenCharTicks = benchmark {
            var char: CUnsignedChar = 0
            for y in 0..<totalLines {
                for x in 0..<charsPerLine {
                    printChar(char, x: x, y: y)
                    char &+= 1
                }
            }
        }

        let oneLineCharTicks = benchmark {
            for x in 0..<charsPerLine {
                printChar(UInt8(ascii: "X"), x: x, y: 30)
            }
        }

        let oneCharTicks = benchmark {
            printChar(UInt8(ascii: "A"), x: 10, y: 31)
        }

        let earlyScrollUpTicks = benchmark {
            scrollUp()
        }

        let clearScreenTicks = benchmark {
            clearScreen()
        }
        let clearScreen2Ticks = benchmark {
            clearScreen()
        }

        return TTY.Timings(
            charsPerLine: charsPerLine,
            totalLines: totalLines,
            fullscreenCharTicks: fullscreenCharTicks,
            oneLineCharTicks: oneLineCharTicks,
            oneCharTicks: oneCharTicks,
            scrollUpTicks: earlyScrollUpTicks,
            clearScreenTicks: clearScreenTicks,
            clearScreen2Ticks: clearScreen2Ticks
        )
    }
}
