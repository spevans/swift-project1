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


struct FrameBufferInfo: CustomStringConvertible {
    let address:       UInt
    let size:          UInt
    let width:         UInt32
    let height:        UInt32
    let pxPerScanline: UInt32
    let depth:         UInt32
    let redShift:      UInt8
    let redMask:       UInt8
    let greenShift:    UInt8
    let greenMask:     UInt8
    let blueShift:     UInt8
    let blueMask:      UInt8

    var description: String {
        var str = String.sprintf("Framebuffer: %dx%d bpp: %d px per line: %d addr:%p size: %lx\n",
            width, height, depth, pxPerScanline, address,  size);
        str += String.sprintf("Red shift:   %2d Red mask:   %x\n", redShift, redMask);
        str += String.sprintf("Green shift: %2d Green mask: %x\n", greenShift, greenMask);
        str += String.sprintf("Blue shift:  %2d Blue mask:  %x\n", blueShift, blueMask);

        return str
    }
}


struct Font: CustomStringConvertible {
    let width:  Int
    let height: Int
    let data: UnsafePointer<UInt8>
    let bytesPerFontLine: Int
    let bytesPerChar: Int

    var fontData: UnsafeBufferPointer<UInt8> {
        let size = Int(width) * Int(height)
        return UnsafeBufferPointer(start: data, count: size / 8)
    }

    var description: String {
        return String.sprintf("width: %ld height: %ld data @ %p",
            width, height, data)
    }


    init(width: Int, height: Int, data: UInt) {
        self.width = width
        self.height = height
        self.data = UnsafePointer<UInt8>(bitPattern: data)
        self.bytesPerFontLine = ((width + 7) / 8)
        self.bytesPerChar = bytesPerFontLine * height
    }


    func characterData(ch: CUnsignedChar) -> UnsafeBufferPointer<UInt8> {
        let offset = Int(ch) * bytesPerChar
        return UnsafeBufferPointer(start: data.advancedBy(offset),
            count: bytesPerChar)
    }
}


protocol ScreenDriver {
    var charsPerLine: Int { get }
    var totalLines:   Int { get }
    var cursorX:      Int { get set }
    var cursorY:      Int { get set }

    func printChar(character: CUnsignedChar, x: Int, y: Int)
    func clearScreen()
    func scrollUp()
}


private var earlyTTY = EarlyTTY()

public struct TTY {
    private static var driver: ScreenDriver = earlyTTY
    private static let tab: CUnsignedChar = 0x09
    private static let newline: CUnsignedChar = 0x0A
    private static let space: CUnsignedChar = 0x20

    // The cursorX and cursorY and managed by early_tty.c so they
    // can be kept in sync
    private static var cursorX: Int {
        get { return earlyTTY.cursorX }
        set(newX) {
            earlyTTY.cursorX = newX
            driver.cursorX = newX
        }
    }

    private static var cursorY: Int {
        get { return earlyTTY.cursorY }
        set(newY) {
            earlyTTY.cursorY = newY
            driver.cursorY = newY
        }
    }


    static func initTTY(frameBufferInfo: UInt) {
        if (frameBufferInfo != 0) {
            driver = FrameBufferTTY(frameBufferInfo)
        } else {
            driver = TextTTY()
        }
        testTTY()
        clearScreen()
        print("Switching to Swift TTY driver")
        set_print_functions_to_swift()
        print("Swift TTY driver initialised: \(driver.charsPerLine)x\(driver.totalLines)")
    }


    public static func clearScreen() {
        driver.clearScreen()
        cursorX = 0
        cursorY = 0
    }


    public static func printString(string: String) {
        for ch in string.utf8 {
            printChar(CChar(ch))
        }
    }


    public static func printString(string: StaticString) {
        if string.hasPointerRepresentation {
            for ch in UnsafeBufferPointer(start: string.utf8Start, count: Int(string.byteSize)) {
                printChar(CChar(ch))
            }
        }
    }


    @_silgen_name("tty_print_cstring_len")
    public static func printCStringLen(string: UnsafePointer<CChar>, length: Int) {
        let buffer = UnsafeBufferPointer(start: string, count: length)
        for ch in buffer {
            printChar(ch)
        }
    }


    @_silgen_name("tty_print_cstring")
    public static func printCString(string: UnsafePointer<CChar>) {
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


    public static func printChar(character: Character) {
        printString(String(character))
    }


    @_silgen_name("tty_print_char")
    public static func printChar(character: CChar) {
        let ch = CUnsignedChar(character)
        var (x, y) = (cursorX, cursorY)

        if ch == newline {
            x = 0
            y += 1
        } else if ch == tab {
            let newX = (x + 8) & ~7
            while (x < newX && x < driver.charsPerLine) {
                driver.printChar(space, x: x, y: y)
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
    }


    public static func testTTY() {
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
}


struct EarlyTTY: ScreenDriver {
    var charsPerLine: Int { return etty_chars_per_line() }
    var totalLines:   Int { return etty_total_lines() }

    var cursorX:      Int {
        get { return Int(etty_get_cursor_x()) }
        set(newX) { etty_set_cursor_x(newX) }
    }

    var cursorY:      Int {
        get { return etty_get_cursor_y(); }
        set(newY) { etty_set_cursor_y(newY) }
    }


    func printChar(character: CUnsignedChar, x: Int, y: Int) {
        etty_print_char(x, y, character)
    }


    func clearScreen() {
        etty_clear_screen()
    }


    func scrollUp() {
        etty_scroll_up()
    }
}


struct TextTTY: ScreenDriver {
    let totalLines: Int
    let charsPerLine: Int
    let totalChars: Int

    private let bytesPerChar = 2;   // Character and colour
    private let totalBytes: Int
    private let bytesPerLine: Int

    private let screenBase: UnsafeMutablePointer<CUnsignedChar>
    private let screen: UnsafeMutableBufferPointer<CUnsignedChar>

    // bright green characters on a black background
    private let textColour: CUnsignedChar = 0xA

    // Motorola 6845 CRT Controller registers
    private let crtIdxReg: UInt16 = 0x3d4
    private let crtDataReg: UInt16 = 0x3d5
    private let cursorMSB: UInt8 = 0xE
    private let cursorLSB: UInt8 = 0xF

    private var _cursorX = 0
    private var _cursorY = 0

    var cursorX: Int {
        get { return _cursorX }
        set(newX) {
            _cursorX = newX
            writeCursor(_cursorX, cursorY)
        }
    }

    var cursorY: Int {
        get { return _cursorY }
        set(newY) {
            _cursorY = newY
            writeCursor(_cursorX, _cursorY)
        }
    }


    init() {
        totalLines = 25
        charsPerLine = 80
        totalChars = (25 * 80) //totalLines * charsPerLine
        totalBytes = (2 * 25 * 80)
        bytesPerLine = 160
        screenBase = UnsafeMutablePointer<CUnsignedChar>(bitPattern: PHYSICAL_MEM_BASE + 0xB8000)
        screen = UnsafeMutableBufferPointer(start: screenBase, count: totalBytes)
    }



    func printChar(character: CUnsignedChar, x: Int, y: Int) {
        let offset = bytesPerChar * ((y * charsPerLine) + x)
        screen[offset] = character
        screen[offset + 1] = textColour
    }


    func clearScreen() {
        var idx = 0
        while idx < totalBytes {
            screen[idx] = 0x20  // space
            screen[idx + 1] = textColour
            idx += 2
        }
    }


    func scrollUp() {
        // Scroll screen up by one line
        let byteCount = (totalLines - 1) * bytesPerLine

        for idx in 0..<byteCount {
            screen[idx] = screen[bytesPerLine + idx]
        }

        // Clear new bottom line with blank characters
        let bottomLine = (totalLines - 1) * bytesPerLine
        var idx = 0
        while idx < bytesPerLine {
            screen[bottomLine + idx] = TTY.space
            screen[bottomLine + idx + 1] = textColour
            idx += bytesPerChar
        }
    }


    // Return hardware cursor x, y from video card
    private func readCursor() -> (Int, Int) {
        outb(crtIdxReg, cursorMSB)
        let msb = inb(crtDataReg)
        outb(crtIdxReg, cursorLSB)
        let lsb = inb(crtDataReg)
        let address = Int(UInt16(msb: msb, lsb: lsb))
        return (Int(address % charsPerLine), Int(address / charsPerLine))
    }


    // Set hardware cursor x, y on video card
    private func writeCursor(x: Int, _ y: Int) {
        let (addressMSB, addressLSB) = UInt16(y * charsPerLine + x).toBytes()
        outb(crtIdxReg, cursorMSB)
        outb(crtDataReg, addressMSB)
        outb(crtIdxReg, cursorLSB)
        outb(crtDataReg, addressLSB)
    }
}


struct FrameBufferTTY: ScreenDriver {
    let charsPerLine: Int
    let totalLines: Int
    var cursorX = 0
    var cursorY = 0
    private let screenBase: UnsafeMutablePointer<UInt8>
    private let screen: UnsafeMutableBufferPointer<UInt8>
    private let font: Font
    private let bytesPerChar: Int
    private let depthInBytes: Int
    private var textRed: UInt8 = 0x2f
    private var textGreen: UInt8 = 0xff
    private var textBlue: UInt8 = 0x12
    private var frameBufferInfo: FrameBufferInfo

    var description: String {
        return frameBufferInfo.description + font.description
    }


    init(_ frameBufferInfoAddr: UInt) {
        let buf = MemoryBufferReader(frameBufferInfoAddr, size: strideof(FrameBufferInfo))
        frameBufferInfo = try! buf.read()
        font = Font(width: 8, height: 16, data: fontdata_8x16_addr())
        charsPerLine = Int(frameBufferInfo.width) / font.width
        totalLines = Int(frameBufferInfo.height) / font.height
        depthInBytes = Int(frameBufferInfo.depth) / 8
        bytesPerChar = font.bytesPerChar

        let size = Int(frameBufferInfo.pxPerScanline) * Int(frameBufferInfo.height) * depthInBytes
        screenBase = UnsafeMutablePointer<UInt8>(bitPattern: PHYSICAL_MEM_BASE + frameBufferInfo.address)
        screen = UnsafeMutableBufferPointer<UInt8>(start: screenBase, count: size)
    }


    func printChar(ch: CUnsignedChar, x: Int, y: Int) {
        let colourMask = computeColourMask()
        let data = font.characterData(ch)
        var pixel = ((y * font.height * Int(frameBufferInfo.pxPerScanline)) + (x * font.width))
        pixel *= depthInBytes

        for line in 0..<font.height {
            var i = 0;
            for px in convertFontLine(data, colourMask, line * font.bytesPerFontLine) {
                screen[pixel + i] = px
                i += 1
            }
            pixel += Int(frameBufferInfo.pxPerScanline) * depthInBytes
        }
    }


    private func computeColourMask() -> UInt32 {
        var mask = UInt32(textRed & frameBufferInfo.redMask) << UInt32(frameBufferInfo.redShift)
        mask |= UInt32(textGreen & frameBufferInfo.greenMask) << UInt32(frameBufferInfo.greenShift)
        mask |= UInt32(textBlue & frameBufferInfo.blueMask) << UInt32(frameBufferInfo.blueShift)

        return mask
    }


    private func convertFontLine(data: UnsafeBufferPointer<UInt8>, _ mask: UInt32,
        _ offset: Int) -> Array<UInt8> {
        var array: [UInt8] = []

        for i in 7.stride(through:0, by: -1) {
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


    func clearScreen() {
        for i in 0..<screen.count {
            screen[i] = 0
        }
    }


    func scrollUp() {
        let bytesPerTextLine = Int(frameBufferInfo.pxPerScanline) * Int(font.height)
        let scrollArea = Int(frameBufferInfo.size) - bytesPerTextLine
        for i in 0..<scrollArea {
            screen[i] = screen[i + bytesPerTextLine]
        }
        // Clear the bottom line
        for i in 0..<bytesPerTextLine {
            screen[scrollArea + i] = 0
        }
    }
}


public func kprint(string: StaticString) {
    early_print_string_len(UnsafePointer<Int8>(string.utf8Start), string.byteSize)
}


public func bprint(string: StaticString) {
    bochs_print_string(UnsafePointer<Int8>(string.utf8Start), string.byteSize)
}


public func kprintf(format: StaticString, _ arguments: CVarArgType...) {
    withVaList(arguments) {
        kvlprintf(UnsafePointer<Int8>(format.utf8Start), format.byteSize, $0)
    }
}


public func printf(format: String, _ arguments: CVarArgType...) {
    TTY.printString(String.sprintf(format, arguments))
}
