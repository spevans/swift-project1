//
//  kernel/device/tty/Font.swift
//  Kernel
//
//  Created by Simon Evans on 03/08/2025.
//

public struct Font: CustomStringConvertible {
    let width:  UInt32
    let height: UInt32
    let data: UnsafePointer<UInt8>
    let bytesPerFontLine: Int
    let bytesPerChar: Int

    var fontData: UnsafeBufferPointer<UInt8> {
        let size = bytesPerChar * 256
        return UnsafeBufferPointer(start: data, count: size)
    }

    var count: UInt {
        return UInt(bytesPerChar) * 256
    }

    public var description: String {
        return #sprintf("%ux%u data @ %p", width, height, data)
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
private let font8x16 = Font(
    width: 8, height: 16, data: UnsafePointer<UInt8>(bitPattern: UInt(bitPattern: &fontdata_8x16))!
)

private let font16x32 = Font(
    width: 16, height: 32, data: UnsafePointer<UInt8>(bitPattern: UInt(bitPattern: &fontdata_16x32))!
)

private let fontVga8x16 = Font(
    width: 8, height: 16, data: UnsafePointer<UInt8>(bitPattern: UInt(bitPattern: &fontdata_vga8x16))!
)

extension Font {
    static private(set) var currentFont: Font = font8x16
    static func fonts() -> [String] {
        ["8x16", "16x32", "vga8x16"]
    }

    // Set a reasonable default font based on the screen resolution
    // For High resolution displays, use a larger font.
    static func setCurrentFont(screenWidth: UInt32, screenHeight: UInt32) -> Font {
        if screenWidth / font8x16.width <= 160 {
            Self.currentFont = font8x16
        } else {
            Self.currentFont = font16x32
        }
        return Self.currentFont
    }

    static func setCurrentFont(_ font: Font) {
        Self.currentFont = font
    }


    static func setCurrentFont(to name: String) -> Bool {
        switch name {
            case "8x16":
                Self.setCurrentFont(font8x16)
                return true

            case "16x32":
                Self.setCurrentFont(font16x32)
                return true

            case "vga8x16":
                Self.setCurrentFont(fontVga8x16)
                return true

            default:
                return false
        }
    }
}
