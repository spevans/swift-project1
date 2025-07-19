/*
 * kernel/devices/tty/tty.swift
 *
 * Created by Simon Evans on 16/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * TTY driver with three screen drivers:
 *   EarlyTTY           calls  early_tty.c functions
 *   TextTTY            drives a PC text mode display
 *   FrameBufferTTY     drives a multiple byte per pixel framebuffer
 */


// TODO: Add some for of ASCII table given all of the strings that need to be converted
let TAB: CUnsignedChar = 0x09
let NEWLINE: CUnsignedChar = 0x0A
let SPACE: CUnsignedChar = 0x20
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


private var textTTY = TextTTY()
private var framebufferTTY = FrameBufferTTY()
private(set)var tty = TTY.none
private var history: [String] = []


// This is called to remap the text screen or framebuffer after new page maps have been
// setup but before they are switched to. This
@_cdecl("init_early_tty")
func initTTY(_ frame_buffer: UnsafePointer<frame_buffer>?) {
    if let frame_buffer = frame_buffer {
        let frameBufferInfo = FrameBufferInfo(fb: frame_buffer.pointee)
        framebufferTTY.setFrameBuffer(frameBufferInfo)
        tty = .framebuffer
        #kprint("TTY: Set to FrameBufferTTY")
    } else {
        textTTY.setActive()
        tty = .text
        #kprint("TTY: Set to TextTTY")
    }
}

@_cdecl("early_print_char")
func printChar(_ ch: CChar) {
    tty.printChar(ch)
}

func remapTTY(_ frameBufferInfo: FrameBufferInfo?) {
    if let frameBufferInfo {
        framebufferTTY.updateMapping(frameBufferInfo)
    } else {
        textTTY.updateMapping()
    }
}

func setTTYDriver(_ driver: TTY.Driver) {
    tty = .driver(driver)
}

enum TTY: ~Copyable {

    struct Driver {
        let charsPerLine: TextCoord
        let totalLines: TextCoord
        let printChar: (_ ch: CUnsignedChar, _ x: TextCoord, _ y: TextCoord) -> ()
        let clearScreen: () -> ()
        let scrollUp: () -> ()
        let getCursorX: () -> TextCoord
        let getCursorY: () -> TextCoord
        let setCursorX: (_ x: TextCoord) -> ()
        let setCursorY: (_ x: TextCoord) -> ()
        let doTimings: () -> TTY.Timings
    }


    case none
    case text
    case framebuffer
    case driver(TTY.Driver)

    // The cursorX and cursorY and managed by early_tty.c so they
    // can be kept in sync
    var cursorX: TextCoord {
        get {
            switch self {
                case .none: return 0
                case .text: return textTTY.cursorX
                case .framebuffer: return framebufferTTY.cursorX
                case .driver(let driver): return driver.getCursorX()
            }
        }
        set {
            switch self {
                case .none: break
                case .text: textTTY.cursorX = newValue
                case .framebuffer: framebufferTTY.cursorX = newValue
                case .driver(let driver): return driver.setCursorX(newValue)
            }
        }
    }


    var cursorY: TextCoord {
        get {
            switch self {
                case .none: return 0
                case .text: return textTTY.cursorY
                case .framebuffer: return framebufferTTY.cursorY
                case .driver(let driver): return driver.getCursorY()
            }
        }
        set {
            switch self {
                case .none: break
                case .text: textTTY.cursorY = newValue
                case .framebuffer: framebufferTTY.cursorY = newValue
                case .driver(let driver): return driver.setCursorY(newValue)
            }
        }
    }


    func clearScreen() {
        switch self {
            case .none: return
            case .text:
                textTTY.clearScreen()
                textTTY.cursorX = 0
                textTTY.cursorY = 0
            case .framebuffer:
                framebufferTTY.clearScreen()
                framebufferTTY.cursorX = 0
                framebufferTTY.cursorY = 0
            case .driver(let driver):
                driver.clearScreen()
                driver.setCursorX(0)
                driver.setCursorY(0)
        }
    }


    @inline(never)
    func scrollUp() {
        switch self {
            case .none: return
            case .text:
                textTTY.scrollUp()
            case .framebuffer:
                framebufferTTY.scrollUp()
            case .driver(let driver):
                driver.scrollUp()
        }
    }

    @inline(never)
    private func printChar(_ character: CUnsignedChar, x: TextCoord, y: TextCoord) {
        switch self {
            case .none: return
            case .text:
                textTTY.printChar(character, x: x, y: y)
            case .framebuffer:
                framebufferTTY.printChar(character, x: x, y: y)
            case .driver(let driver):
                driver.printChar(character, x, y)
        }
    }

    private var charsPerLine: TextCoord {
        return switch self {
            case .none: 0
            case .text: textTTY.charsPerLine
            case .framebuffer: framebufferTTY.charsPerLine
            case .driver(let driver): driver.charsPerLine
        }
    }

    private var totalLines: TextCoord {
        return switch self {
            case .none: 0
            case .text: textTTY.totalLines
            case .framebuffer: framebufferTTY.totalLines
            case .driver(let driver): driver.totalLines
        }
    }

    @inline(never)
    mutating func printChar(_ character: CChar) {
        switch self {
            case .none:
                serial_print_char(character)
                return
            default: break
        }
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

    struct Timings {
        let charsPerLine: TextCoord
        let totalLines: TextCoord
        let fullscreenCharTicks: UInt64
        let oneLineCharTicks: UInt64
        let oneCharTicks: UInt64
        let scrollUpTicks: UInt64
        let clearScreenTicks: UInt64
        let clearScreen2Ticks: UInt64

        func printTimings(name: String, timings: Timings) {
            let totalChars = UInt64(charsPerLine) * UInt64(totalLines)

            #kprint("\nTimings for", name)
            #kprintf("print one character:         %u\n", timings.oneCharTicks)
            #kprintf("print one line:              %u\tperChar: %u\n", timings.oneLineCharTicks,
                     timings.oneLineCharTicks / UInt64(charsPerLine))
            #kprintf("scrollUp():                  %u\n", scrollUpTicks)
            #kprintf("clearScreen:                 %u\n", clearScreenTicks)
            #kprintf("clearScreen2:                %u\n", clearScreen2Ticks)

            #kprintf("print whole screen:          %u\tperLine: %u\tperChar: %u\n", timings.fullscreenCharTicks,
                     timings.fullscreenCharTicks / UInt64(totalLines), timings.fullscreenCharTicks / totalChars)

            #kprintf("Columns: %d Lines: %d totalChars: %d\n",
                    charsPerLine, totalLines, totalChars)

        }
    }

    func scrollTimingTest() {

        switch self {
            case .none: return
            case .text:
                let timings = textTTY.doTimings()
                clearScreen()
                timings.printTimings(name: "TextTTY", timings: timings)

            case .framebuffer:
                let timings = framebufferTTY.doTimings()
                clearScreen()
                timings.printTimings(name: "FrameBufferTTY", timings: timings)

            case .driver(let driver):
                let timings = driver.doTimings()
                clearScreen()
                timings.printTimings(name: "DriverTTY", timings: timings)

        }
    }
}


// TODO - Should be in a 'Console' type
func readLine(prompt: String, keyboard: Keyboard) -> String {
    tty.readLine(prompt: prompt, keyboard: keyboard)
}
