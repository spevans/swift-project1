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


// kprint via the C early_tty.c driver. This should avoid any memory allocation
// as the pointer to the string is being passed directly and the single unicode
// scalar case is explictly rejected.
@inline(__always)
func kprint(_ string: StaticString) {
    precondition(string.hasPointerRepresentation)
    precondition(string.isASCII)
    string.utf8Start.withMemoryRebound(to: Int8.self, capacity: string.utf8CodeUnitCount) {
        (ptr: UnsafePointer<Int8>) -> Void in
        early_print_string_len(ptr, string.utf8CodeUnitCount)
    }
}


@inline(never)
func print(_ items: CustomStringConvertible..., separator: String = " ",
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

func _kprint(_ string: String) {
    var output = _tty()
    output.write(string)
    output.write("\n")
}

func print(_ item: StaticString) {
    kprint(item)
}


internal struct _tty : UnicodeOutputStream {
    mutating func write(_ string: StaticString) {
        if string.utf8CodeUnitCount == 0 { return }
        string.withUTF8Buffer { buffer in
            for ch in buffer {
                tty.printChar(CChar(bitPattern: ch))
            }
        }
    }
    
    mutating func write(_ string: String) {
        // FIXME: Get precondition to work
        //precondition(string._guts.isASCII, "String must be ASCII")
        if string.isEmpty { return }
        for c in string.unicodeScalars {
            tty.printChar(CChar(truncatingIfNeeded: c.value))
        }
    }

    mutating func write(_ unicodeScalar: UnicodeScalar) {
        if let ch = Int32(exactly: unicodeScalar.value) {
            tty.printChar(CChar(ch))
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



private var earlyTTY = EarlyTTY()
private var textTTY = TextTTY()
private var framebufferTTY = FrameBufferTTY()
private(set)var tty = TTY.early


// This is called to remap the text screen or framebuffer after new page maps have been
// setup but before they are switched to. This
func setTTY(frameBufferInfo: FrameBufferInfo?) {
    print("TTY: Switching to Swift TTY driver")
    if let frameBufferInfo = frameBufferInfo {
        framebufferTTY.setFrameBuffer(frameBufferInfo)
        tty = .framebuffer
        print("TTY: Set to FrameBufferTTY")
    } else {
        textTTY.setActive()
        tty = .text
        print("TTY: Set to TextTTY")
    }
}


enum TTY {
    case early
    case text
    case framebuffer

    // The cursorX and cursorY and managed by early_tty.c so they
    // can be kept in sync
    var cursorX: TextCoord {
        get { earlyTTY.cursorX }
        set {
            earlyTTY.cursorX = newValue
            switch self {
                case .text: textTTY.cursorX = newValue
                case .framebuffer: framebufferTTY.cursorX = newValue
                case .early: break
            }
        }
    }


    var cursorY: TextCoord {
        get { earlyTTY.cursorY }
        set {
            earlyTTY.cursorY = newValue
            switch self {
                case .text: textTTY.cursorY = newValue
                case .framebuffer: framebufferTTY.cursorY = newValue
                case .early: break
            }
        }
    }


    func clearScreen() {
        switch self {
            case .early:
                earlyTTY.clearScreen()
            case .text:
                textTTY.clearScreen()
            case .framebuffer:
                framebufferTTY.clearScreen()
        }
        earlyTTY.cursorX = 0
        earlyTTY.cursorY = 0
    }


    func scrollUp() {
        switch self {
            case .early:
                earlyTTY.scrollUp()
            case .text:
                textTTY.scrollUp()
            case .framebuffer:
                framebufferTTY.scrollUp()
        }
    }

    private func printChar(_ character: CUnsignedChar, x: TextCoord, y: TextCoord) {
        switch self {
            case .early:
                earlyTTY.printChar(character, x: x, y: y)
            case .text:
                textTTY.printChar(character, x: x, y: y)
            case .framebuffer:
                framebufferTTY.printChar(character, x: x, y: y)
        }
    }

    private var charsPerLine: TextCoord {
        switch self {
            case .early: return earlyTTY.charsPerLine
            case .text:  return textTTY.charsPerLine
            case .framebuffer: return framebufferTTY.charsPerLine
        }
    }

    private var totalLines: TextCoord {
        switch self {
            case .early: return earlyTTY.totalLines
            case .text: return textTTY.totalLines
            case .framebuffer: return framebufferTTY.totalLines
        }
    }

    mutating func printChar(_ character: CChar) {
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
                while (x < newX && x < charsPerLine) {
                    printChar(SPACE, x: x, y: y)
                    x += 1
                }
                x = newX
            } else {
                printChar(ch, x: x, y: y)
                x += 1
            }

            if x >= charsPerLine {
                x = 0
                y += 1
            }

            while (y >= totalLines) {
                scrollUp()
                y -= 1
            }
            cursorX = x
            cursorY = y
        })
    }


    mutating func readLine(prompt: String, keyboard: Keyboard) -> String {
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
/** DISABLED for now due to SILgen error compiling this
        let earlyTicks = benchmark(earlyTTY.scrollUp)
        let swiftTicks = benchmark(tty.scrollUp)
        let ratio = swiftTicks / earlyTicks
        print("tty: EarlyTTY.scrollUp():", earlyTicks)
        print("tty: TTY.scrollUp():", swiftTicks)
        print("tty: Ratio: ", ratio)
**/
    }
}


private struct EarlyTTY {
    let charsPerLine: TextCoord
    let totalLines:   TextCoord


    var cursorX: TextCoord {
        get { etty_get_cursor_x() }
        set { etty_set_cursor_x(newValue) }
    }


    var cursorY: TextCoord {
        get { etty_get_cursor_y() }
        set { etty_set_cursor_y(newValue) }
    }


    init() {
        charsPerLine = etty_chars_per_line()
        totalLines = etty_total_lines()
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


private struct TextTTY {
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
    private var screen = UnsafeMutableBufferPointer<UInt16>(start: UnsafeMutablePointer<UInt16>(bitPattern: UInt(1)), count: 0)

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

    fileprivate mutating func setActive() {
        // This exists so that init() can be called as the instance is global and will be in the .bss
        // init() cannot be called directly.
        charsPerLine = 80
        totalLines = 25
        totalChars = Int(totalLines) * Int(charsPerLine)
        let physRegion = PhysRegion(start: PhysAddress(Self.SCREEN_BASE_ADDRESS), size: UInt(totalChars))
        let mmioRegion = mapIORegion(region: physRegion, cacheType: .writeCombining)
        let screenBase = UnsafeMutablePointer<UInt16>(bitPattern: mmioRegion.baseAddress.vaddr)
        screen = UnsafeMutableBufferPointer(start: screenBase, count: totalChars)
    }

    func printChar(_ character: CUnsignedChar, x: TextCoord, y: TextCoord) {
        guard x < charsPerLine && y < totalLines else {
            return
        }
        let offset = Int((y * charsPerLine) + x)
        screen[offset] = UInt16(withBytes: character, Self.textColour)
    }


    func clearScreen() {
        for i in 0..<screen.count {
            screen[i] = Self.blankChar
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
            screen[bottomLine + i] = Self.blankChar
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
}

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

    init() {
        self.width = 0
        self.height = 0
        self.data = UnsafePointer<UInt8>(bitPattern: 1)!
        self.bytesPerFontLine = 0
        self.bytesPerChar = 0
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

// Expose the font as a global for now to avoid a one time initialiser function on the Framebuffer
// This seems to be a bug as this whold structure should be a constant in .data
private let _font = Font(
    width: 8, height: 16, data: UnsafePointer<UInt8>(bitPattern: UInt(bitPattern: &fontdata_8x16))!
)

private struct FrameBufferTTY {
    private var font = Font()
    private var screen = UnsafeMutableBufferPointer<UInt8>(
        start: UnsafeMutablePointer<UInt8>(bitPattern: 0x1)!, count: 0
    )
    private var bytesPerChar: Int = 0
    private var depthInBytes: Int = 0
    private var bytesPerTextLine: Int = 0
    private var lastLineScrollArea: Int = 0

    private let textRed: UInt8 = 0x2f
    private let textGreen: UInt8 = 0xff
    private let textBlue: UInt8 = 0x12
    private var colourMask: UInt32 = 0
    private var frameBufferInfo =  FrameBufferInfo()

    private var _cursorX: TextCoord = 0
    private var _cursorY: TextCoord = 0
    private(set) var charsPerLine: TextCoord = 0
    private(set) var totalLines:   TextCoord = 0


    var cursorX: TextCoord {
        get { _cursorX }
        set {
            guard newValue < charsPerLine else {
                return
            }
            _cursorX = newValue
         }
    }

    var cursorY: TextCoord {
        get { _cursorY }
        set {
            guard newValue < totalLines else {
                return
            }
            _cursorY = newValue
         }
    }

    var description: String {
        return frameBufferInfo.description + font.description
    }

    // Empty initialiser avoids one time initialisation functions.
    init() {
    }

    mutating func setFrameBuffer(_ frameBufferInfo: FrameBufferInfo) {
        // TODO: Deinit the old settings?
        self.font = _font
        self.frameBufferInfo = frameBufferInfo
        charsPerLine = TextCoord(frameBufferInfo.width / font.width)
        totalLines = TextCoord(frameBufferInfo.height / font.height)
        depthInBytes = Int(frameBufferInfo.depth) / 8
        bytesPerChar = Int(font.bytesPerChar)
        bytesPerTextLine = Int(frameBufferInfo.pxPerScanline) * Int(font.height)
            * depthInBytes
        lastLineScrollArea = bytesPerTextLine * (Int(totalLines) - 1)
        let size = Int(frameBufferInfo.pxPerScanline)
            * Int(frameBufferInfo.height) * depthInBytes

        let physRegion = PhysRegion(start: frameBufferInfo.address, size: UInt(size))
        let mmioRegion = mapIORegion(region: physRegion, cacheType: .writeCombining)
        let screenBase = UnsafeMutablePointer<UInt8>(bitPattern: mmioRegion.baseAddress.vaddr)!
        screen = UnsafeMutableBufferPointer<UInt8>(start: screenBase,
            count: size)
        colourMask = computeColourMask()
    }


    func printChar(_ ch: CUnsignedChar, x: TextCoord, y: TextCoord) {
        guard x < charsPerLine && y < totalLines else {
            return
        }
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


    func clearScreen() {
        for i in 0..<screen.count {
            screen[i] = 0
        }
    }


    func scrollUp() {
        let screenBase = screen.baseAddress!
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


    func writeFontLine(data: UnsafeBufferPointer<UInt8>, mask: UInt32,
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

// TODO - Should be in a 'Console' type
func readLine(prompt: String, keyboard: Keyboard) -> String {
    tty.readLine(prompt: prompt, keyboard: keyboard)
}
