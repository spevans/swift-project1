/*
 * kernel/devices/tty.swift
 *
 * Created by Simon Evans on 16/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * TTY driver with three screen drivers:
 *   EarlyTTY           calls  early_tty.c functions
 *   TextTTY            drives a PC text mode display
 *   FrameBufferTTY     drives a multiple byte per pixel framebuffer
 */


private let TAB: CUnsignedChar = 0x09
private let NEWLINE: CUnsignedChar = 0x0A
private let SPACE: CUnsignedChar = 0x20
typealias TextCoord = text_coord


// printf via the Swift TTY driver (print() is also routed to here)
func printf(_ format: String, _ arguments: CVarArg...) {
    TTY.sharedInstance.printString(String.sprintf(format, arguments))
}


// kprint via the C early_tty.c driver
func kprint(_ string: StaticString) {
    TTY.sharedInstance.earlyTTY.printString(string)
}


// kprintf via the C early_tty.c driver
func kprintf(_ format: StaticString, _ arguments: CVarArg...) {
    _ = withVaList(arguments) {
        kvlprintf(UnsafePointer<Int8>(format.utf8Start),
            format.utf8CodeUnitCount, $0)
    }
}


// print to the Bochs console via the E9 port
func bprint(_ string: StaticString) {
    bochs_print_string(UnsafePointer<Int8>(string.utf8Start),
        string.utf8CodeUnitCount)
}


protocol ScreenDriver {
    var charsPerLine: TextCoord { get }
    var totalLines:   TextCoord { get }
    var cursorX:      TextCoord { get set }
    var cursorY:      TextCoord { get set }

    func printChar(_ character: CUnsignedChar, x: TextCoord, y: TextCoord)
    func clearScreen()
    func scrollUp()
}


class TTY {

    // singleton
    static let sharedInstance = TTY()

    private let earlyTTY = EarlyTTY()
    private var driver: ScreenDriver


    // The cursorX and cursorY and managed by early_tty.c so they
    // can be kept in sync
    private var cursorX: TextCoord {
        get { return earlyTTY.cursorX }
        set(newX) {
            earlyTTY.cursorX = newX
            driver.cursorX = newX
        }
    }


    private var cursorY: TextCoord {
        get { return earlyTTY.cursorY }
        set(newY) {
            earlyTTY.cursorY = newY
            driver.cursorY = newY
        }
    }


    private init() {
        driver = earlyTTY
    }


    func setTTY(frameBufferInfo: FrameBufferInfo?) {
        if (frameBufferInfo != nil) {
            driver = FrameBufferTTY(frameBufferInfo: frameBufferInfo!)
        } else {
            driver = TextTTY()
        }
        testTTY()
        clearScreen()
        print("Switching to Swift TTY driver")
        set_print_functions_to_swift()
        print("Swift TTY driver initialised: \(driver.charsPerLine)x\(driver.totalLines)")
    }


    func clearScreen() {
        driver.clearScreen()
        cursorX = 0
        cursorY = 0
    }


    func scrollUp() {
        driver.scrollUp()
    }


    func printString(_ string: String) {
        for ch in string.utf8 {
            printChar(CChar(ch))
        }
    }


    func printString(_ string: StaticString) {
        if string.hasPointerRepresentation {
            for ch in UnsafeBufferPointer(start: string.utf8Start,
                count: Int(string.utf8CodeUnitCount)) {
                printChar(CChar(ch))
            }
        }
    }


    func printCStringLen(string: UnsafePointer<CChar>, length: Int) {
        let buffer = UnsafeBufferPointer(start: string, count: length)
        for ch in buffer {
            printChar(ch)
        }
    }


    func printCString(string: UnsafePointer<CChar>) {
        let maxLength = 2000; // hard limit
        let buffer = UnsafeBufferPointer(start: string, count: maxLength)
        for idx in 0..<maxLength {
            let ch = buffer[idx]
            if (ch == 0) {
                break
            }
            printChar(ch)
        }
    }


    func printChar(_ character: Character) {
        printString(String(character))
    }


    func printChar(_ character: CChar) {
        /* FIXME: Disable interrupts for exclusive access to screen memory
         * and instance vars but this function takes far too long because of
         * scrollUp() and so lots of timer interrupts are currently missed
         */
        noInterrupt({
                let ch = CUnsignedChar(character)
                var (x, y) = (cursorX, cursorY)

                if ch == NEWLINE {
                    x = 0
                    y += 1
                } else if ch == TAB {
                    let newX = (x + 8) & ~7
                    while (x < newX && x < driver.charsPerLine) {
                        driver.printChar(SPACE, x: x, y: y)
                        x += 1
                    }
                    x = newX
                } else {
                    driver.printChar(ch, x: x, y: y)
                    x += 1
                }

                if x >= driver.charsPerLine {
                    x = 0
                    y += 1
                }

                while (y >= driver.totalLines) {
                    driver.scrollUp()
                    y -= 1
                }
                cursorX = x
                cursorY = y
            })
    }


    func testTTY() {
        print("cursorX = \(cursorX) cursorY = \(cursorY)")
        printChar(0x0A)
        printChar(65)
        printChar(66)
        printChar(67)
        printChar(68)
        printChar(Character("\n"))
        printChar(Character("E"))
        printChar(Character("F"))
        printChar(Character("G"))
        printChar(Character("H"))
        printString("\n12\t12345678\t12345\t123456789\t12\t12\t0\n")
        printString("12345678123456781234567812345678123456781234567812345678123456780")
        printString("12345678123456781234567812345678123456781234567812345678123456781234567812345678")
        let x = cursorX
        print("\n   x = \(x) cursorX = \(cursorX) cursorY = \(cursorY)")
        printString("\n\n\nNewLine")
        print(" cursorX = \(cursorX) cursorY = \(cursorY)")
    }


    func scrollTimingTest() {
        let earlyTicks = benchmark(TTY.sharedInstance.earlyTTY.scrollUp)
        let swiftTicks = benchmark(TTY.sharedInstance.scrollUp)
        let ratio = swiftTicks / earlyTicks
        print("EarlyTTY.scrollUp():", earlyTicks)
        print("TTY.scrollUp():", swiftTicks)
        print("Ratio: ", ratio)
    }

}


private class EarlyTTY: ScreenDriver {

    var charsPerLine: TextCoord { return etty_chars_per_line() }
    var totalLines:   TextCoord { return etty_total_lines() }

    var cursorX:      TextCoord {
        get { return etty_get_cursor_x() }
        set(newX) { etty_set_cursor_x(newX) }
    }

    var cursorY:      TextCoord {
        get { return etty_get_cursor_y(); }
        set(newY) { etty_set_cursor_y(newY) }
    }


    func printChar(_ character: CUnsignedChar, x: TextCoord, y: TextCoord) {
        etty_print_char(x, y, character)
    }


    func printString(_ string: StaticString) {
        early_print_string_len(UnsafePointer<Int8>(string.utf8Start),
            string.utf8CodeUnitCount)
    }


    func clearScreen() {
        etty_clear_screen()
    }


    func scrollUp() {
        etty_scroll_up()
    }
}


private class TextTTY: ScreenDriver {
    // VGA Text Mode Hardware constants
    private let SCREEN_BASE_ADDRESS: UInt = 0xB8000
    // Motorola 6845 CRT Controller registers
    private let CRT_IDX_REG: UInt16 = 0x3d4
    private let CRT_DATA_REG: UInt16 = 0x3d5
    private let CURSOR_MSB_IDX: UInt8 = 0xE
    private let CURSOR_LSB_IDX: UInt8 = 0xF

    private let totalLines: TextCoord = 25
    private let charsPerLine: TextCoord = 80
    private let bytesPerLine: TextCoord = 160
    private let totalChars: Int
    private let screenBase: UnsafeMutablePointer<UInt16>
    private let screen: UnsafeMutableBufferPointer<UInt16>

    // bright green characters on a black background
    private let textColour: CUnsignedChar = 0xA

    // black space on black background
    private let blankChar = UInt16(msb: 0, lsb: SPACE)


    private var _cursorX: TextCoord = 0
    private var _cursorY: TextCoord = 0

    var cursorX: TextCoord {
        get { return _cursorX }
        set(newX) {
            guard newX < charsPerLine else {
                return
            }
            _cursorX = newX
            writeCursor(_cursorX, cursorY)
        }
    }

    var cursorY: TextCoord {
        get { return _cursorY }
        set(newY) {
            guard newY < totalLines else {
                return
            }
            _cursorY = newY
            writeCursor(_cursorX, _cursorY)
        }
    }


    private init() {
        totalChars = Int(totalLines) * Int(charsPerLine)
        screenBase = UnsafeMutablePointer<UInt16>(bitPattern: PHYSICAL_MEM_BASE + SCREEN_BASE_ADDRESS)!
        screen = UnsafeMutableBufferPointer(start: screenBase, count: totalChars)
    }


    func printChar(_ character: CUnsignedChar, x: TextCoord, y: TextCoord) {
        guard x < charsPerLine && y < totalLines else {
            return
        }
        let offset = Int((y * charsPerLine) + x)
        screen[offset] = UInt16(msb: textColour, lsb: character)
    }


    func clearScreen() {
        for i in 0..<screen.count {
            screen[i] = blankChar
        }
    }


    func scrollUp() {
        // Scroll screen up by one line
        let charCount = Int((totalLines - 1) * charsPerLine)

        for i in 0..<charCount {
            screen[i] = screen[Int(charsPerLine) + i]
        }

        // Clear new bottom line with blank characters
        let bottomLine = Int((totalLines - 1) * charsPerLine)
        for i in 0..<Int(charsPerLine) {
            screen[bottomLine + i] = blankChar
        }
    }


    // FIXME: I/O Access to CRT Registers should be behind a lock
    // Return hardware cursor x, y from video card
    private func readCursor() -> (TextCoord, TextCoord) {
        outb(CRT_IDX_REG, CURSOR_MSB_IDX)
        let msb = inb(CRT_DATA_REG)
        outb(CRT_IDX_REG, CURSOR_LSB_IDX)
        let lsb = inb(CRT_DATA_REG)
        let address = UInt16(msb: msb, lsb: lsb)
        let x = address % UInt16(charsPerLine)
        let y = address / UInt16(charsPerLine)
        return fixCursor(TextCoord(x), TextCoord(y))
    }


    // Set hardware cursor x, y on video card
    private func writeCursor(_ x: TextCoord, _ y: TextCoord) {
        let (x, y) = fixCursor(x, y)
        let (addressMSB, addressLSB) = UInt16(y * charsPerLine + x).toBytes()
        outb(CRT_IDX_REG, CURSOR_MSB_IDX)
        outb(CRT_DATA_REG, addressMSB)
        outb(CRT_IDX_REG, CURSOR_MSB_IDX)
        outb(CRT_DATA_REG, addressLSB)
    }


    // Dont let the HW cursor off the screen
    private func fixCursor(_ x: TextCoord, _ y: TextCoord) -> (TextCoord, TextCoord) {
        return (min(x, charsPerLine - 1), min(y, totalLines - 1))
    }
}


private class FrameBufferTTY: ScreenDriver {
    struct Font: CustomStringConvertible {
        let width:  UInt32
        let height: UInt32
        let data: UnsafePointer<UInt8>
        let bytesPerFontLine: UInt32
        let bytesPerChar: UInt32

        var fontData: UnsafeBufferPointer<UInt8> {
            let size = Int(width) * Int(height)
            return UnsafeBufferPointer(start: data, count: size / 8)
        }

        var description: String {
            return String.sprintf("width: %ld height: %ld data @ %p",
                width, height, data)
        }


        init(width: UInt32, height: UInt32, data: UnsafePointer<UInt8>) {
            self.width = width
            self.height = height
            self.data = data
            self.bytesPerFontLine = ((width + 7) / 8)
            self.bytesPerChar = bytesPerFontLine * height
        }


        func characterData(_ ch: CUnsignedChar) -> UnsafeBufferPointer<UInt8> {
            let offset = Int(ch) * Int(bytesPerChar)
            return UnsafeBufferPointer(start: data.advancedBy(bytes: offset),
                count: Int(bytesPerChar))
        }
    }


    private let charsPerLine: TextCoord
    private let totalLines: TextCoord
    private let screenBase: UnsafeMutablePointer<UInt8>
    private let screen: UnsafeMutableBufferPointer<UInt8>
    private let font: Font
    private let bytesPerChar: Int
    private let depthInBytes: Int
    private let bytesPerTextLine: Int
    private let lastLineScrollArea: Int

    private var textRed: UInt8 = 0x2f
    private var textGreen: UInt8 = 0xff
    private var textBlue: UInt8 = 0x12
    private var frameBufferInfo: FrameBufferInfo

    private var _cursorX: TextCoord = 0
    private var _cursorY: TextCoord = 0

    var cursorX: TextCoord {
        get { return _cursorX }
        set(newX) {
            guard newX < charsPerLine else {
                return
            }
            _cursorX = newX
         }
    }

    var cursorY: TextCoord {
        get { return _cursorY }
        set(newY) {
            guard newY < totalLines else {
                return
            }
            _cursorY = newY
         }
    }


    var description: String {
        return frameBufferInfo.description + font.description
    }


    private init(frameBufferInfo: FrameBufferInfo) {
        self.frameBufferInfo = frameBufferInfo
        font = Font(width: 8, height: 16, data: fontdata_8x16_ptr())
        charsPerLine = TextCoord(frameBufferInfo.width / font.width)
        totalLines = TextCoord(frameBufferInfo.height / font.height)
        depthInBytes = Int(frameBufferInfo.depth) / 8
        bytesPerChar = Int(font.bytesPerChar)
        bytesPerTextLine = Int(frameBufferInfo.pxPerScanline) * Int(font.height)
                * depthInBytes
        lastLineScrollArea = bytesPerTextLine * (Int(totalLines) - 1)
        let size = Int(frameBufferInfo.pxPerScanline) * Int(frameBufferInfo.height)
                * depthInBytes
        screenBase = UnsafeMutablePointer<UInt8>(bitPattern: PHYSICAL_MEM_BASE + frameBufferInfo.address)!
        screen = UnsafeMutableBufferPointer<UInt8>(start: screenBase, count: size)
    }


    func printChar(_ ch: CUnsignedChar, x: TextCoord, y: TextCoord) {
        guard x < charsPerLine && y < totalLines else {
            return
        }

        let colourMask = computeColourMask()
        let data = font.characterData(ch)
        var pixel = Int(UInt32(y) * font.height * frameBufferInfo.pxPerScanline)
            + Int(UInt32(x) * font.width)
        pixel *= depthInBytes

        for line in 0..<font.height {
            var i = 0;
            let offset = Int(line * font.bytesPerFontLine)
            for px in convertFontLine(data, colourMask, offset) {
                screen[pixel + i] = px
                i += 1
            }
            pixel += Int(frameBufferInfo.pxPerScanline) * depthInBytes
        }
    }


    func clearScreen() {
        for i in 0..<screen.count {
            screen[i] = 0
        }
    }


    func scrollUp() {
        screenBase.assignFrom(screenBase.advancedBy(bytes: bytesPerTextLine),
            count: lastLineScrollArea)

        // Clear the bottom line
        for i in 0..<bytesPerTextLine {
            screen[lastLineScrollArea + i] = 0
        }
    }


    private func computeColourMask() -> UInt32 {
        var mask = UInt32(textRed & frameBufferInfo.redMask) << UInt32(frameBufferInfo.redShift)
        mask |= UInt32(textGreen & frameBufferInfo.greenMask) << UInt32(frameBufferInfo.greenShift)
        mask |= UInt32(textBlue & frameBufferInfo.blueMask) << UInt32(frameBufferInfo.blueShift)

        return mask
    }


    private func convertFontLine(_ data: UnsafeBufferPointer<UInt8>, _ mask: UInt32,
        _ offset: Int) -> Array<UInt8> {
        var array: [UInt8] = []

        for i in stride(from: 7, through: 0, by: -1) {
            let m = UInt8(1 << i)
            let bit = (data[offset] & m) != 0
            for x in 0..<depthInBytes {
                let shift = UInt32(x * 8)
                if (bit) {
                    array.append(UInt8(truncatingBitPattern: (mask >> shift)))
                } else {
                    array.append(0)
                }
            }
        }

        return array
    }
}


// These are used by early_tty.c:set_print_functions_to_swift()
@_silgen_name("tty_print_cstring_len")
public func tty_print_cstring_len(string: UnsafePointer<CChar>, length: Int) {
    TTY.sharedInstance.printCStringLen(string: string, length: length)
}


@_silgen_name("tty_print_cstring")
public func printCString(string: UnsafePointer<CChar>) {
    TTY.sharedInstance.printCString(string: string)
}


@_silgen_name("tty_print_char")
public func printChar(_ character: CChar) {
    TTY.sharedInstance.printChar(character)
}
