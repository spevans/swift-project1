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

    static let screenBase = UnsafeMutablePointer<CUnsignedChar>(bitPattern: 0xB8000);
    static let screen = UnsafeMutableBufferPointer(start: screenBase, count: totalBytes);

    static var cursorX = 0
    static var cursorY = 0


    public static func initTTY() {
        clearScreen()
        set_print_functions_to_swift();
        print("Swift TTY driver initialised");
    }


    public static func clearScreen() {
        var idx = 0
        while idx < totalBytes {
            screen[idx] = 0x20  // space
            screen[idx + 1] = whiteOnBlack
            idx += 2
        }
    }


    public static func printString(string: String) {
        for ch in string.utf8 {
            printChar(CChar(ch))
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
        let ch = CUnsignedChar(character)
        let offset = (cursorY * 80 * 2) + (cursorX * 2)
        let tab: CUnsignedChar = 0x09
        let newline: CUnsignedChar = 0x0A

        if (ch == newline || cursorX >= 80) {
            cursorX = 0
            cursorY += 1
            if (cursorY >= totalLines) {
                // Scroll screen up by one line
                let byteCount = (totalLines - 1) * bytesPerLine
                for idx in 0..<byteCount {
                    screen[idx] = screen[bytesPerLine + idx]
                }

                // Clear new bottom line with blank cha
                let bottomLine = (totalLines - 1) * bytesPerLine
                var idx = 0
                while idx < bytesPerLine {
                    screen[bottomLine + idx] = 0x20  // space
                    screen[bottomLine + idx + 1] = whiteOnBlack
                    idx += 2
                }

                cursorY -= 1
            }
        }
        else if ch == tab {
            let newX = (cursorX + 8) & ~7
            let spaces = 2 * (newX - cursorX)
            var idx = 0
            while idx < spaces {
                screen[offset + idx] = 0x20
                screen[offset + idx + 1] = 0x7
                idx += 2
            }
            cursorX = newX
        } else {
            screen[offset] = ch
            screen[offset + 1] = 0x7
            cursorX += 1
        }
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
        printString("\n\n\n\n\n\n\n\n\n\nNewLine\n\n\n")
    }
}
