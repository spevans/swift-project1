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


internal struct _TTY: UnicodeOutputStream {

    init() {}

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

    mutating func write(_ character: Character) {
        if let ch = character.asciiValue {
            tty.printChar(CChar(ch))
        }
    }
}


internal struct _Serial: UnicodeOutputStream {
    mutating func write(_ string: StaticString) {
        if string.utf8CodeUnitCount == 0 { return }
        string.withUTF8Buffer { buffer in
            for ch in buffer {
                serial_print_char(CChar(bitPattern: ch))
            }
        }
    }

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

    mutating func write(_ character: Character) {
        if let ch = character.asciiValue {
            serial_print_char(CChar(ch))
        }
    }
}


private var earlyTTY = EarlyTTY()
private var textTTY = TextTTY()
private var framebufferTTY = FrameBufferTTY()
private(set)var tty = TTY.early
private var history: [String] = []


// This is called to remap the text screen or framebuffer after new page maps have been
// setup but before they are switched to. This
func setTTY(frameBufferInfo: FrameBufferInfo?) {
    #kprint("TTY: Switching to Swift TTY driver")
    if let frameBufferInfo {
        framebufferTTY.setFrameBuffer(frameBufferInfo)
        tty = .framebuffer
        #kprint("TTY: Set to FrameBufferTTY")
    } else {
        textTTY.setActive()
        tty = .text
        #kprint("TTY: Set to TextTTY")
    }
}


enum TTY: ~Copyable {
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
        return switch self {
            case .early: earlyTTY.charsPerLine
            case .text: textTTY.charsPerLine
            case .framebuffer: framebufferTTY.charsPerLine
        }
    }

    private var totalLines: TextCoord {
        return switch self {
            case .early: earlyTTY.totalLines
            case .text: textTTY.totalLines
            case .framebuffer: framebufferTTY.totalLines
        }
    }

    @inline(never)
    mutating func printChar(_ character: CChar) {
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
    }


    mutating func readLine(prompt: String, keyboard: Keyboard) -> String {
        var currentLine = ""
        currentLine.reserveCapacity(64)

        #kprintf("%s", prompt)
        var initialCursorX = cursorX
        var initialCursorY = cursorY
        var idx = currentLine.startIndex // index in current string
        var clipboard = currentLine[..<idx]
        var historyIndex = history.endIndex

        while true {
            guard let us = keyboard.readKeyboard() else {
                continue
            }
            let character = Character(us)
            guard let asciiValue = character.asciiValue else {
                continue
            }
            var clearSpaces = 0
            switch asciiValue {
                case 1: // ctrl-a Start of line
                    idx = currentLine.startIndex

                case 2: // ctrl-b Left arrow
                    if idx > currentLine.startIndex {
                        idx = currentLine.index(before: idx)
                    }

                case 4: // ctrl-d Delete character at cursor
                    if idx < currentLine.endIndex {
                        currentLine.remove(at: idx)
                        if idx > currentLine.endIndex {
                            idx = currentLine.endIndex
                        }
                        clearSpaces = 1
                    }

                case 5: // ctrl-e End of line
                    idx = currentLine.endIndex

                case 6: // ctrl-f Right Arrow
                    if idx < currentLine.endIndex {
                        idx = currentLine.index(after: idx)
                    }

                case 8: // ctrl-h DEL
                    if idx > currentLine.startIndex {
                        idx = currentLine.index(before: idx)
                        currentLine.remove(at: idx)
                        clearSpaces = 1
                    }

                case 10, 13:    // ctrl-j, ctrl-m NL, CR
                    printChar(10)
                    if history.last != currentLine {
                        history.append(currentLine)
                    }
                    return currentLine


                case 11: // ctrl-k cut to clipboard
                    if idx < currentLine.endIndex {
                        let r = idx..<currentLine.endIndex
                        clipboard = currentLine[r]
                        currentLine.removeSubrange(r)
                        clearSpaces = clipboard.count
                    }

                case 12: // ctrl-l
                    clearScreen()
                    #kprintf("%s", prompt)
                    initialCursorX = cursorX
                    initialCursorY = cursorY

                case 14: // ctrl-n, next line in history
                    if historyIndex < history.endIndex - 1 {
                        historyIndex = history.index(after: historyIndex)
                        clearSpaces = max(currentLine.count, history[historyIndex].count) - currentLine.count
                        currentLine = history[historyIndex]
                        idx = currentLine.endIndex
                        initialCursorX = TextCoord(prompt.count)
                    }

                case 16: // ctrl-p, previous line in history
                    if historyIndex > history.startIndex {
                        historyIndex = history.index(before: historyIndex)
                        clearSpaces = max(currentLine.count, history[historyIndex].count) - history[historyIndex].count
                        currentLine = history[historyIndex]
                        idx = currentLine.endIndex
                        initialCursorX = TextCoord(prompt.count)
                    }

                case 23: // ctrl-w delete word backwards
                    guard !currentLine.isEmpty else {
                        continue
                    }
                    // Search backwards to find a non-space, then keep search until a space in front of it is found
                    while idx > currentLine.startIndex, currentLine[currentLine.index(before: idx)].isWhitespace {
                        idx = currentLine.index(before: idx)
                        clearSpaces += 1
                    }
                    while idx > currentLine.startIndex, !currentLine[currentLine.index(before: idx)].isWhitespace {
                        idx = currentLine.index(before: idx)
                        clearSpaces += 1
                    }
                    currentLine.removeSubrange(idx..<currentLine.endIndex)

                case 25: // ctrl-y yank back
                    currentLine.insert(contentsOf: clipboard, at: idx)
                    idx = currentLine.endIndex

                case 32...:
                    currentLine.insert(character, at: idx)
                    idx = currentLine.index(after: idx)

                default:
                    continue
            }
            // Draw the current string
            cursorX = initialCursorX
            cursorY = initialCursorY

            for ch in currentLine {
                if let ch = ch.asciiValue {
                    printChar(CChar(ch))
                }
            }
            while clearSpaces > 0 {
                printChar(32)
                clearSpaces -= 1
            }
        }
    }


    func scrollTimingTest() {
        framebufferTTY.speedTests()
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

    @inline(never)
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
    let bytesPerFontLine: Int
    let bytesPerChar: Int

    var fontData: UnsafeBufferPointer<UInt8> {
        let size = Int(width) * Int(height)
        return UnsafeBufferPointer(start: data, count: size / 8)
    }

    var description: String {
        return #sprintf("width: %ld height: %ld data @ %p",
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
        self.bytesPerFontLine = Int((width + 7) / 8)
        self.bytesPerChar = bytesPerFontLine * Int(height)
    }

    @inline(__always)
    func characterData(_ ch: Int) -> UnsafeBufferPointer<UInt8> {
        let offset = ch &* bytesPerChar
        return UnsafeBufferPointer(start: data.advanced(by: offset),
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
    private var bytesPerChar = 0
    private var depthInBytes = 0
    private var bytesPerTextLine = 0
    private var lastLineScrollArea = 0
    private var visibleBytesPerScanLine = 0
    private var totalBytesPerScanLine = 0
    private var fontBytesPerLineDepth = 0

    private let textRed: UInt8 = 0x2f
    private let textGreen: UInt8 = 0xff
    private let textBlue: UInt8 = 0x12
    private var colourMask: UInt32 = 0
    private let backgroundColour: UInt32 = 0x0000_0000
    private let blankChar: UInt8 = 32   // Space character is used when clearing text
    private var frameBufferInfo = FrameBufferInfo()

    private var _cursorX: TextCoord = 0
    private var _cursorY: TextCoord = 0
    private(set) var charsPerLine: TextCoord = 0
    private(set) var totalLines:   TextCoord = 0
    private var textMemory: UnsafeMutableRawBufferPointer?


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

    // FIXME: FrameBufferTTY should be ~Copyable but this currently has compiler errors
//    deinit {
//        textMemory?.deallocate()
//    }

    mutating func setFrameBuffer(_ frameBufferInfo: FrameBufferInfo) {
        // TODO: Deinit the old settings?
        self.font = _font
        self.frameBufferInfo = frameBufferInfo
        charsPerLine = TextCoord(frameBufferInfo.width / font.width)
        totalLines = TextCoord(frameBufferInfo.height / font.height)
        depthInBytes = Int(frameBufferInfo.depth) / 8
        bytesPerTextLine = Int(frameBufferInfo.pxPerScanline) * Int(font.height) * depthInBytes
        lastLineScrollArea = bytesPerTextLine * (Int(totalLines) - 1)

        visibleBytesPerScanLine = Int(frameBufferInfo.width) * depthInBytes
        totalBytesPerScanLine = Int(frameBufferInfo.pxPerScanline) * depthInBytes
        fontBytesPerLineDepth = Int(font.width) * depthInBytes

        let size = Int(frameBufferInfo.pxPerScanline)
            * Int(frameBufferInfo.height) * depthInBytes

        let physRegion = PhysRegion(start: frameBufferInfo.address, size: UInt(size))
        let mmioRegion = mapIORegion(region: physRegion, cacheType: .writeCombining)
        let screenBase = UnsafeMutablePointer<UInt8>(bitPattern: mmioRegion.baseAddress.vaddr)!
        screen = UnsafeMutableBufferPointer<UInt8>(start: screenBase,
            count: size)
        colourMask = computeColourMask()

        textMemory = UnsafeMutableRawBufferPointer.allocate(byteCount: Int(charsPerLine * totalLines), alignment: 8)
        textMemory?.initializeMemory(as: UInt8.self, repeating: blankChar)
    }


    @inline(never)
    mutating func printChar(_ ch: CUnsignedChar, x: TextCoord, y: TextCoord) {
        guard x < charsPerLine && y < totalLines else {
            return
        }

        // Update textMemory buffer
        let textAddress = Int(y * charsPerLine + x)
        textMemory?[textAddress] = ch

        let ch = Int(ch)
        var pixelOffset: Int = (Int(y) &* bytesPerTextLine) &+ (Int(x) &* fontBytesPerLineDepth)

        var fontByteOffset = 0
        let screenBase = screen.baseAddress!
        var count = font.height

        let data = font.characterData(ch).span
        let base = UnsafeMutableRawPointer(bitPattern: screenBase.address)!
        while count > 0 {
            let screenLine = base.advanced(by: pixelOffset)
            let charByte = data[unchecked: fontByteOffset]
            switch depthInBytes {
                case 4: writeFontLine4(charByte, screenLine)
                case 3: writeFontLine3(charByte, screenLine)
                case 2: writeFontLine2(charByte, screenLine)
                case 1: writeFontLine1(charByte, screenLine)
                default: break
            }
            fontByteOffset &+= font.bytesPerFontLine
            pixelOffset &+= totalBytesPerScanLine
            count &-= 1
        }
    }


    // Write a line for a bitmap font to a line on the screen, 1 function for each supported depth
    private func writeFontLine4(_ fontLineByte: UInt8, _ screenLine: UnsafeMutableRawPointer) {

        var screenByte = 0
        var bit = 0
        while bit < 8 {
            let colour1 = fontLineByte.bit(7 - bit) ? colourMask : backgroundColour
            let colour2 = fontLineByte.bit(6 - bit) ? colourMask : backgroundColour
            let qword = UInt64(colour2) << 32 | UInt64(colour1)
            screenLine.storeBytes(of: qword, toByteOffset: screenByte, as: UInt64.self)
            screenByte &+= 8
            bit &+= 2
        }
    }


    private func writeFontLine3(_ fontLineByte: UInt8, _ screenLine: UnsafeMutableRawPointer) {

        var screenByte = 0
        for bit in 0...7 {
            let colour = fontLineByte.bit(7 - bit) ? colourMask : backgroundColour
            screenLine.storeBytes(of: UInt16(truncatingIfNeeded: colour), toByteOffset: screenByte, as: UInt16.self)
            screenLine.storeBytes(of: UInt8(truncatingIfNeeded: colour >> 16), toByteOffset: screenByte &+ 2, as: UInt8.self)
            screenByte &+= 3
        }
    }


    private func writeFontLine2(_ fontLineByte: UInt8, _ screenLine: UnsafeMutableRawPointer) {

        var screenByte = 0
        for bit in 0...7 {
            let colour = fontLineByte.bit(7 - bit) ? colourMask : backgroundColour
            screenLine.storeBytes(of: UInt16(truncatingIfNeeded: colour), toByteOffset: screenByte, as: UInt16.self)
            screenByte &+= 2
        }
    }

    private func writeFontLine1(_ fontLineByte: UInt8, _ screenLine: UnsafeMutableRawPointer) {

        var screenByte = 0
        for bit in 0...7 {
            let colour = fontLineByte.bit(7 - bit) ? colourMask : backgroundColour
            screenLine.storeBytes(of: UInt8(truncatingIfNeeded: colour), toByteOffset: screenByte, as: UInt8.self)
            screenByte &+= 1
        }
    }


    // Clear the screen by memsetting the frame buffer then clearing the textMemory
    mutating func clearScreen() {
        let blankData = UInt64(backgroundColour) << 32 | UInt64(backgroundColour)
        if visibleBytesPerScanLine == totalBytesPerScanLine {
            let totalBytes = Int(totalBytesPerScanLine) * Int(frameBufferInfo.height)
            // Just memset the whole screen as there is no extra memory at the end of each scanline
            inline_memset8(screen.baseAddress!, blankData, totalBytes / 8, totalBytes % 8)
        } else {
            let qwordsPerLine = visibleBytesPerScanLine / 8
            let extraBytes = visibleBytesPerScanLine % 8
            var offset = 0
            let increment = Int(frameBufferInfo.pxPerScanline) * depthInBytes
            for _ in 1...frameBufferInfo.height {
                inline_memset8(screen.baseAddress!.advanced(by: offset), blankData, qwordsPerLine, extraBytes)
                offset &+= increment
            }
        }
        cursorX = 0
        cursorY = 0
        guard let textMemory else { return }
        textMemory.initializeMemory(as: UInt8.self, repeating: blankChar)
    }


    mutating func clearScreen2() {
        guard let textMemory else { return }
        textMemory.initializeMemory(as: UInt8.self, repeating: blankChar)
        var textOffset = 0
        for y in 0..<totalLines {
            for x in 0..<charsPerLine {
                printChar(textMemory[textOffset], x: x, y: y)
                textOffset &+= 1
            }
        }
    }

    mutating func scrollUp() {
        scrollUpTxt()
    }

    private mutating func scrollUpTxt() {
        guard let textMemory else { return }
        var textOffset = 0
        for y in 0..<totalLines {
            for x in 0..<charsPerLine {
                let ch = textMemory[textOffset &+ Int(charsPerLine)]
                textMemory[textOffset] = ch
                printChar(ch, x: x, y: y)
                textOffset &+= 1
            }
        }
        // Clear the bottom row
        for x in 0..<charsPerLine {
            textMemory[textOffset] = blankChar
            printChar(blankChar, x: x, y: totalLines &- 1)
            textOffset &+= 1
        }
    }


    private func scrollUpFB() {
        let blankData = UInt64(backgroundColour) << 32 | UInt64(backgroundColour)
        if visibleBytesPerScanLine == totalBytesPerScanLine {
            // memcpy the whole screen - bottom row up
            let destination = screen.baseAddress!
            let source = destination.advanced(by: bytesPerTextLine)
            let totalBytes = lastLineScrollArea
            inline_memcpy8(destination, source, totalBytes / 8, totalBytes % 8)
            // Clear the bottom row
            inline_memset8(destination.advanced(by: lastLineScrollArea), blankData, bytesPerTextLine / 8, bytesPerTextLine % 8)
        } else {
            // Memcpy
            let destination = screen.baseAddress!
            let bytesPerLine = Int(frameBufferInfo.pxPerScanline) * depthInBytes
            let source = destination.advanced(by: bytesPerLine * Int(font.height))
            let qwordsPerLine = visibleBytesPerScanLine / 8
            let extraBytes = visibleBytesPerScanLine % 8
            var offset = 0
            for _ in 1...(frameBufferInfo.height - font.height) {
                inline_memcpy8(destination.advanced(by: offset), source.advanced(by: offset), qwordsPerLine, extraBytes)
                offset &+= bytesPerLine
            }
            for _ in 1...font.height {
                inline_memset8(destination.advanced(by: offset), blankData, qwordsPerLine, extraBytes)
                offset &+= bytesPerLine
            }
        }
    }


    private struct Timings {
        let fullscreenCharTicks: UInt64
        let oneLineCharTicks: UInt64
        let oneCharTicks: UInt64
    }


    private mutating func doTimings() -> Timings {
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
        return Timings(fullscreenCharTicks: fullscreenCharTicks, oneLineCharTicks: oneLineCharTicks, oneCharTicks: oneCharTicks)
    }


    private func printTimings(name: String, timings: Timings) {
        let totalChars = UInt64(charsPerLine) * UInt64(totalLines)

        #kprint("\nTimings for", name)
        #kprintf("print one character:         %u\n", timings.oneCharTicks)
        #kprintf("print one line:              %u\tperChar: %u\n", timings.oneLineCharTicks,
                 timings.oneLineCharTicks / UInt64(charsPerLine))
        #kprintf("print whole screen:          %u\tperLine: %u\tperChar: %u\n", timings.fullscreenCharTicks,
                 timings.fullscreenCharTicks / UInt64(totalLines), timings.fullscreenCharTicks / totalChars)
    }


    mutating func speedTests() {

        let writeFontLineTimings = doTimings()

        let clearScreenTicks = benchmark {
            clearScreen()
        }
        let clearScreen2Ticks = benchmark {
            clearScreen2()
        }

        let totalChars = UInt64(charsPerLine) * UInt64(totalLines)

        let earlyScrollUpTicks = benchmark(earlyTTY.scrollUp)
        let scrollUpFBTicks = benchmark(framebufferTTY.scrollUpFB)
        let scrollUpTxtTicks = benchmark({ framebufferTTY.scrollUpTxt() })

        clearScreen()
        #kprintf("\n\nFramebufferInfo: Address: %p Size: 0x%x\n", frameBufferInfo.address, frameBufferInfo.size)
        #kprintf("FramebufferInfo: width: %u height: %u pxPerScanLine: %u depth: %u\n",
                 frameBufferInfo.width, frameBufferInfo.height, frameBufferInfo.pxPerScanline, frameBufferInfo.depth)
        #kprintf("Columns: %d Lines: %d totalChars: %d bytesPerPixel: %d\n",
                charsPerLine, totalLines, totalChars, depthInBytes)

        printTimings(name: "writeFontLine", timings: writeFontLineTimings)

        #kprintf("clearScreen:                 %u\n", clearScreenTicks)
        #kprintf("clearScreen2:                %u\n", clearScreen2Ticks)
        #kprintf("tty: EarlyTTY.scrollUp():    %u\n", earlyScrollUpTicks)
        #kprintf("tty: scrollUpFB():           %u\n", scrollUpFBTicks)
        #kprintf("tty: scrollUpTxt():          %u\n", scrollUpTxtTicks)
    }


    private func computeColourMask() -> UInt32 {
        var mask = UInt32(textRed & frameBufferInfo.redMask) << UInt32(frameBufferInfo.redShift)
        mask |= UInt32(textGreen & frameBufferInfo.greenMask) << UInt32(frameBufferInfo.greenShift)
        mask |= UInt32(textBlue & frameBufferInfo.blueMask) << UInt32(frameBufferInfo.blueShift)

        return mask
    }
}

// TODO - Should be in a 'Console' type
func readLine(prompt: String, keyboard: Keyboard) -> String {
    tty.readLine(prompt: prompt, keyboard: keyboard)
}
