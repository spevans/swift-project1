//
//  kernel/device/tty/Font.swift
//  Kernel
//
//  Created by Simon Evans on 03/08/2025.
//

struct Font: CustomStringConvertible {
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
