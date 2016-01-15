/*
 * kernel/devices/tty.swift
 *
 * Created by Simon Evans on 16/12/2015.
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * TTY output only driver - assumes a PC style video card with
 * fixed buffer @ 0xB8000
 *
 */

public class TTY {
    static let totalLines = 25;
    static let charsPerLine = 80
    static let totalChars = totalLines * charsPerLine
    static let bytesPerChar = 2;   // Character and colour
    static let totalBytes = totalChars * bytesPerChar
    static let bytesPerLine = charsPerLine * bytesPerChar;
    static let whiteOnBlack: CUnsignedChar = 0x7  // black background white characters

    static let screenBase = UnsafeMutablePointer<CUnsignedChar>(bitPattern: 0xB8000)
    static let screen = UnsafeMutableBufferPointer(start: screenBase, count: totalBytes)

    // Motorola 6845 CRT Controller registers
    static let crtIdxReg: UInt16 = 0x3d4
    static let crtDataReg: UInt16 = 0x3d5
    static let cursorMSB: UInt8 = 0xE;
    static let cursorLSB: UInt8 = 0xF;

    // return hardware cursor x, y from video card
    static func readCursor() -> (Int, Int) {
        outb(crtIdxReg, cursorMSB)
        let msb = inb(crtDataReg)
        outb(crtIdxReg, cursorLSB)
        let lsb = inb(crtDataReg)
        let address = Int(UInt16(msb: msb, lsb: lsb))
        return (Int(address % charsPerLine), Int(address / charsPerLine))
    }


    // set hardware cursor x, y on video card
    static func writeCursor(x: Int, _ y: Int) {
        let (addressMSB, addressLSB) = UInt16(y * charsPerLine + x).toBytes()
        outb(crtIdxReg, cursorMSB)
        outb(crtDataReg, addressMSB)
        outb(crtIdxReg, cursorLSB)
        outb(crtDataReg, addressLSB)
    }


    static var cursorX: Int {
        get { return readCursor().0 }
        set(newX) { writeCursor(newX, readCursor().1) }
    }


    static var cursorY: Int {
        get { return readCursor().1 }
        set(newY) { writeCursor(readCursor().0, newY) }
    }


    public static func initTTY() {
        clearScreen()
        set_print_functions_to_swift()
        print("Swift TTY driver initialised")
    }


    public static func clearScreen() {
        var idx = 0
        while idx < totalBytes {
            screen[idx] = 0x20  // space
            screen[idx + 1] = whiteOnBlack
            idx += 2
        }
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


    public static func printCStringLen(string: UnsafePointer<CChar>, length: Int) {
        let buffer = UnsafeBufferPointer(start: string, count: length)
        for ch in buffer {
            printChar(ch)
        }
    }


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


    public static func printChar(character: CChar) {
        let tab: CUnsignedChar = 0x09
        let newline: CUnsignedChar = 0x0A
        let space: CUnsignedChar = 0x20

        var x = cursorX
        var y = cursorY

        let ch = CUnsignedChar(character)
        if ch == newline {
            x = 0
            y += 1
        } else if ch == tab {
            let newX = (x + 8) & ~7
            let spaces = bytesPerChar * (newX - x)
            let offset = bytesPerChar * ((y * 80) + x)
            var idx = 0
            while idx < spaces {
                screen[offset + idx] = space
                screen[offset + idx + 1] = whiteOnBlack
                idx += bytesPerChar
            }
            x = newX
        } else {
            let offset = bytesPerChar * ((y * 80) + x)
            screen[offset] = ch
            screen[offset + 1] = whiteOnBlack
            x += 1
        }

        if x >= 80 {
            x = 0
            y += 1
        }

        if (y >= totalLines) {
            // Scroll screen up by one line
            let byteCount = (totalLines - 1) * bytesPerLine
            for idx in 0..<byteCount {
                screen[idx] = screen[bytesPerLine + idx]
            }

            // Clear new bottom line with blank characters
            let bottomLine = (totalLines - 1) * bytesPerLine
            var idx = 0
            while idx < bytesPerLine {
                screen[bottomLine + idx] = space
                screen[bottomLine + idx + 1] = whiteOnBlack
                idx += bytesPerChar
            }
            y -= 1
        }

        cursorX = x
        cursorY = y
    }


    public static func testTTY() {
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
        printString("\n\n\nNewLine\n\n\n")
    }
}


public func kprint(string: StaticString) {
    early_print_string_len(UnsafePointer<Int8>(string.utf8Start), string.byteSize)
}


public func kprintf(format: StaticString, _ arguments: CVarArgType...) {
    withVaList(arguments) {
        kvlprintf(UnsafePointer<Int8>(format.utf8Start), format.byteSize, $0)
    }
}


public func printf(format: String, _ arguments: CVarArgType...) {
    TTY.printString(String.sprintf(format, arguments))
}
