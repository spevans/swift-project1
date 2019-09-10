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


// kprint via the C early_tty.c driver
@inline(__always)
func kprint(_ string: StaticString) {
    precondition(string.isASCII)
    string.utf8Start.withMemoryRebound(to: Int8.self, capacity: string.utf8CodeUnitCount) {
        (ptr: UnsafePointer<Int8>) -> Void in
        kprint(ptr)
    }
}


@inline(never)
func print(_ items: Any..., separator: String = " ",
    terminator: String = "\n") {

    var output = _tty()
    var prefix = ""
    for item in items {
        // Print the items one at a time as varargs will be passed as an array
        output.write(prefix)
        print(item, separator: "", terminator: "", to: &output)
        prefix = separator
    }
    output.write(terminator)
}


@inline(never)
func print(_ item: String) {
    var output = _tty()
    output.write(item)
    output.write("\n")
}


func print(_ item: StaticString) {
    kprint(item)
}


internal struct _tty : UnicodeOutputStream {
    mutating func write(_ string: String) {
        // FIXME: Get precondition to work
        //precondition(string._guts.isASCII, "String must be ASCII")
        if string.isEmpty { return }
        for c in string.unicodeScalars {
            TTY.sharedInstance.printChar(CChar(truncatingIfNeeded: c.value))
        }
    }

    mutating func write(_ unicodeScalar: UnicodeScalar) {
        if let ch = Int32(exactly: unicodeScalar.value) {
            TTY.sharedInstance.printChar(CChar(ch))
        }
    }
}


internal struct _serial: UnicodeOutputStream {
    mutating func write(_ string: String) {
        if string.isEmpty { return }
        for c in string.unicodeScalars {
            if c.isASCII {
                serial_print_char(CChar(truncatingIfNeeded: c.value))
            }
        }
    }

    mutating func write(_ unicodeScalar: UnicodeScalar) {
        if unicodeScalar.isASCII, let ch = Int32(exactly: unicodeScalar.value) {
            serial_print_char(CChar(ch))
        }
    }
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


final class TTY {

    // singleton
    static let sharedInstance = TTY()

    fileprivate let earlyTTY = EarlyTTY()
    private var driver: ScreenDriver


    // The cursorX and cursorY and managed by early_tty.c so they
    // can be kept in sync
    var cursorX: TextCoord {
        get { return earlyTTY.cursorX }
        set(newX) {
            earlyTTY.cursorX = newX
            driver.cursorX = newX
        }
    }


    var cursorY: TextCoord {
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
        clearScreen()
        print("tty: Switching to Swift TTY driver")
        if (frameBufferInfo != nil) {
            driver = FrameBufferTTY(frameBufferInfo: frameBufferInfo!)
        } else {
            driver = TextTTY()
        }
        print("tty: Swift TTY driver initialised: \(driver.charsPerLine)x\(driver.totalLines)")
    }


    func clearScreen() {
        driver.clearScreen()
        cursorX = 0
        cursorY = 0
    }


    func scrollUp() {
        driver.scrollUp()
    }


    func printChar(_ character: CChar) {
        /* FIXME: Disable interrupts for exclusive access to screen memory
         * and instance vars but this function takes far too long because of
         * scrollUp() and so lots of timer interrupts are currently missed
         */
        serial_print_char(character)
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


    func readLine(prompt: String, keyboard: Keyboard) -> String {
        var cmdString: [CChar] = []
        var clipboard: [CChar] = []

        print(prompt, terminator: "")
        var initialCursorX = cursorX
        var initialCursorY = cursorY
        var idx = 0 // index in current string
        var line: String?

        while line == nil {
            while let char = keyboard.readKeyboard() {
                var clearSpaces = 0
                if !char.isASCII {
                    continue
                }
                let ch = CChar(truncatingIfNeeded: char.value)

                if ch == 1 { // ctrl-a
                    idx = 0
                }
                else if ch == 2 { // ctrl-b
                    if idx > 0 {
                        idx -= 1
                    }
                }
                else if ch == 5 { // ctrl-e
                    idx = cmdString.count
                }
                else if ch == 6 { // ctrl-f
                    if idx < cmdString.count {
                        idx += 1
                    }
                }

                else if ch == 8 { // ctrl-h DEL
                    if idx > 0 {
                        idx -= 1
                        cmdString.remove(at: idx)
                        clearSpaces = 1
                    }
                }
                else if ch == 10 || ch == 13 { // ctrl-j, ctrl-m NL, CR
                    cmdString.append(0)
                    line = cmdString.withUnsafeBufferPointer {
                        return String(validatingUTF8: $0.baseAddress!)
                    }
                    if line == nil {
                        print("\nCant convert to a String");
                        line = ""
                    }
                    cmdString.removeLast()
                    cmdString.append(10)
                } else if ch == 11 { // ctrl-k cut to clipboard
                    if idx < cmdString.count {
                        let r = idx..<cmdString.count
                        clipboard = Array(cmdString[r])
                        cmdString.removeSubrange(r)
                        clearSpaces = clipboard.count
                    }
                } else if ch == 25 { // ctrl-y yank back
                    cmdString.insert(contentsOf: clipboard, at: idx)
                    idx += clipboard.count
                } else if ch == 12 { // ctrl-l
                    clearScreen()
                    print(prompt, terminator: "")
                    initialCursorX = cursorX
                    initialCursorY = cursorY
                }

                else if ch >= 32 {
                    cmdString.insert(ch, at: idx)
                    idx += 1
                }
                // Draw the current string
                cursorX = initialCursorX
                cursorY = initialCursorY

                cmdString.forEach {
                    printChar($0)
                }
                while clearSpaces > 0 {
                    printChar(32)
                    clearSpaces -= 1
                }
            }
        }

        return line!
    }


    func scrollTimingTest() {
        let earlyTicks = benchmark(TTY.sharedInstance.earlyTTY.scrollUp)
        let swiftTicks = benchmark(TTY.sharedInstance.scrollUp)
        let ratio = swiftTicks / earlyTicks
        print("tty: EarlyTTY.scrollUp():", earlyTicks)
        print("tty: TTY.scrollUp():", swiftTicks)
        print("tty: Ratio: ", ratio)
    }

}


private final class EarlyTTY: ScreenDriver {

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


    func clearScreen() {
        etty_clear_screen()
    }


    func scrollUp() {
        etty_scroll_up()
    }
}


private final class TextTTY: ScreenDriver {
    // VGA Text Mode Hardware constants
    private let SCREEN_BASE_ADDRESS: UInt = 0xB8000
    // Motorola 6845 CRT Controller registers
    private let CRT_IDX_REG: UInt16 = 0x3d4
    private let CRT_DATA_REG: UInt16 = 0x3d5
    private let CURSOR_MSB_IDX: UInt8 = 0xE
    private let CURSOR_LSB_IDX: UInt8 = 0xF

    let totalLines: TextCoord = 25
    let charsPerLine: TextCoord = 80
    private let bytesPerLine: TextCoord = 160
    private let totalChars: Int
    private let screen: UnsafeMutableBufferPointer<UInt16>

    // bright green characters on a black background
    private let textColour: CUnsignedChar = 0xA
    // black space on black background
    private let blankChar = UInt16(withBytes: SPACE, 0)

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


    init() {
        totalChars = Int(totalLines) * Int(charsPerLine)
        let vaddr = mapIORegion(physicalAddr: PhysAddress(SCREEN_BASE_ADDRESS),
            size: totalChars * 2, cacheType: 2 /* WriteCombining */)
        let screenBase = UnsafeMutablePointer<UInt16>(bitPattern: vaddr)
        screen = UnsafeMutableBufferPointer(start: screenBase,
            count: totalChars)
    }


    func printChar(_ character: CUnsignedChar, x: TextCoord, y: TextCoord) {
        guard x < charsPerLine && y < totalLines else {
            return
        }
        let offset = Int((y * charsPerLine) + x)
        screen[offset] = UInt16(withBytes: character, textColour)
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


private final class FrameBufferTTY: ScreenDriver {
    private struct Font: CustomStringConvertible {
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


    let charsPerLine: TextCoord
    let totalLines: TextCoord
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


    fileprivate init(frameBufferInfo: FrameBufferInfo) {
        self.frameBufferInfo = frameBufferInfo
        font = Font(width: 8, height: 16,
            data: UnsafePointer<UInt8>(bitPattern: fontdata_8x16_addr)!)
        charsPerLine = TextCoord(frameBufferInfo.width / font.width)
        totalLines = TextCoord(frameBufferInfo.height / font.height)
        depthInBytes = Int(frameBufferInfo.depth) / 8
        bytesPerChar = Int(font.bytesPerChar)
        bytesPerTextLine = Int(frameBufferInfo.pxPerScanline) * Int(font.height)
            * depthInBytes
        lastLineScrollArea = bytesPerTextLine * (Int(totalLines) - 1)
        let size = Int(frameBufferInfo.pxPerScanline)
            * Int(frameBufferInfo.height) * depthInBytes

        let vaddr = mapIORegion(physicalAddr: frameBufferInfo.address,
            size: size, cacheType: 2 /* WriteCombining */)
        screenBase = UnsafeMutablePointer<UInt8>(bitPattern: vaddr)!
        screen = UnsafeMutableBufferPointer<UInt8>(start: screenBase,
            count: size)
    }


    fileprivate func printChar(_ ch: CUnsignedChar, x: TextCoord, y: TextCoord) {
        guard x < charsPerLine && y < totalLines else {
            return
        }
        let colourMask = computeColourMask()
        let data = font.characterData(ch)
        var pixel = Int(UInt32(y) * font.height * frameBufferInfo.pxPerScanline)
            + Int(UInt32(x) * font.width)
        pixel *= depthInBytes

        for line in 0..<font.height {
            let offset = Int(line * font.bytesPerFontLine)
            let screenByte = screen.baseAddress!.advanced(by: pixel)
            let screenLine = UnsafeMutableBufferPointer(start: screenByte,
                count: 8 * depthInBytes)

            writeFontLine(data: data, mask: colourMask, offset: offset,
                screenLine: screenLine)
            pixel += Int(frameBufferInfo.pxPerScanline) * depthInBytes
        }
    }


    fileprivate func clearScreen() {
        for i in 0..<screen.count {
            screen[i] = 0
        }
    }


    fileprivate func scrollUp() {
        screenBase.assign(from: screenBase.advancedBy(bytes: bytesPerTextLine),
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


    private func writeFontLine(data: UnsafeBufferPointer<UInt8>, mask: UInt32,
        offset: Int, screenLine: UnsafeMutableBufferPointer<UInt8>) {

        var screenByte = 0
        for i in stride(from: 7, through: 0, by: -1) {
            let m = UInt8(1 << i)
            let bit = (data[offset] & m) != 0
            for x in 0..<depthInBytes {
                let shift = UInt32(x * 8)
                if (bit) {
                    let pixel = UInt8(truncatingIfNeeded: (mask >> shift))
                    screenLine[screenByte] = pixel
                } else {
                    screenLine[screenByte] = 0
                }
                screenByte += 1
            }
        }
    }
}
