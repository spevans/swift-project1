//
//  kernel/device/tty/FrameBufferTTY.swift
//  project1
//
//  Created by Simon Evans on 03/08/2025.
//


struct FrameBufferTTY: ~Copyable {
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

    // Green characters on black
#if true
    private let textRed: UInt8 = 0x2f
    private let textGreen: UInt8 = 0xff
    private let textBlue: UInt8 = 0x12
    private let backgroundColour: UInt32 = 0x0000_0000
#else
    // Black characters on white, usefule for screen recording.
    private let textRed: UInt8 = 0x22
    private let textGreen: UInt8 = 0x22
    private let textBlue: UInt8 = 0x22
    private let backgroundColour: UInt32 = 0xffff_ffff
#endif
    private var colourMask: UInt32 = 0
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

    deinit {
      textMemory?.deallocate()
    }

    @inline(never)
    mutating func setFrameBuffer(_ frameBufferInfo: FrameBufferInfo) {
        // TODO: Deinit the old settings?

        self.frameBufferInfo = frameBufferInfo
        self.depthInBytes = Int(frameBufferInfo.depth) / 8
        self.totalBytesPerScanLine = Int(frameBufferInfo.pxPerScanline) * depthInBytes
        self.visibleBytesPerScanLine = Int(frameBufferInfo.width) * self.depthInBytes
        self.colourMask = computeColourMask()

        let font = Font.setCurrentFont(screenWidth: self.frameBufferInfo.width,
                                       screenHeight: self.frameBufferInfo.height)
        setFont(font)

        let size = UInt(frameBufferInfo.pxPerScanline)
            * UInt(frameBufferInfo.height) * UInt(depthInBytes)

        let physRegion = PhysRegion(start: frameBufferInfo.address, size: size)
        let mmioRegion = mapIORegion(region: physRegion, cacheType: .writeCombining)
        let screenBase = UnsafeMutablePointer<UInt8>(bitPattern: mmioRegion.baseAddress.vaddr)!
        screen = UnsafeMutableBufferPointer<UInt8>(start: screenBase, count: Int(size))

    }

    mutating func setFont(_ font: Font) {
        self.font = font
        self.charsPerLine = TextCoord(frameBufferInfo.width / font.width)
        self.totalLines = TextCoord(frameBufferInfo.height / font.height)

        self.bytesPerTextLine = Int(frameBufferInfo.pxPerScanline) * Int(font.height) * self.depthInBytes
        self.lastLineScrollArea = self.bytesPerTextLine * (Int(self.totalLines) - 1)
        self.fontBytesPerLineDepth = Int(font.width) * depthInBytes

        // Text memory is based on the total text characters so may need to be resized up
        // Free the old memory and reallocate the buffer for now
        self.textMemory?.deallocate()
        self.textMemory = UnsafeMutableRawBufferPointer.allocate(byteCount: Int(charsPerLine * totalLines), alignment: 8)
        self.textMemory?.initializeMemory(as: UInt8.self, repeating: blankChar)
    }

    mutating func updateMapping(_ frameBufferInfo: FrameBufferInfo) {
        // Remap the frambuffer now that the new page tables have been setup
        let size = Int(frameBufferInfo.pxPerScanline)
            * Int(frameBufferInfo.height) * depthInBytes
        let physRegion = PhysRegion(start: frameBufferInfo.address, size: UInt(size))
        #kprintf("tty: Remapping framebuffer @ %s\n", physRegion.description)
        let mmioRegion = mapIORegion(region: physRegion, cacheType: .writeCombining)
        let screenBase = UnsafeMutablePointer<UInt8>(bitPattern: mmioRegion.baseAddress.vaddr)!
        screen = UnsafeMutableBufferPointer<UInt8>(start: screenBase,
            count: size)
    }


    @inline(never)
    mutating func printChar(_ ch: UInt8, x: TextCoord, y: TextCoord) {
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
        let bytesPer8Pixels = self.depthInBytes &* 8

        while count > 0 {
            var screenLine = base.advanced(by: pixelOffset)
            for _ in 0..<self.font.bytesPerFontLine {
                // Write 8pixels of one line of the font
                let charByte = data[unchecked: fontByteOffset]
                switch depthInBytes {
                    case 4: writeFontLine4(charByte, screenLine)
                    case 3: writeFontLine3(charByte, screenLine)
                    case 2: writeFontLine2(charByte, screenLine)
                    case 1: writeFontLine1(charByte, screenLine)
                    default: break
                }
                fontByteOffset &+= 1
                screenLine = screenLine.advanced(by: bytesPer8Pixels)
            }
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


    mutating func doTimings() -> TTY.Timings {
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

        let earlyScrollUpTicks = benchmark {
            scrollUp()
        }

        let clearScreenTicks = benchmark {
            clearScreen()
        }
        let clearScreen2Ticks = benchmark {
            clearScreen2()
        }

        return TTY.Timings(
            charsPerLine: charsPerLine,
            totalLines: totalLines,
            fullscreenCharTicks: fullscreenCharTicks,
            oneLineCharTicks: oneLineCharTicks,
            oneCharTicks: oneCharTicks,
            scrollUpTicks: earlyScrollUpTicks,
            clearScreenTicks: clearScreenTicks,
            clearScreen2Ticks: clearScreen2Ticks
        )
    }



    private func computeColourMask() -> UInt32 {
        var mask = UInt32(textRed & frameBufferInfo.redMask) << UInt32(frameBufferInfo.redShift)
        mask |= UInt32(textGreen & frameBufferInfo.greenMask) << UInt32(frameBufferInfo.greenShift)
        mask |= UInt32(textBlue & frameBufferInfo.blueMask) << UInt32(frameBufferInfo.blueShift)

        return mask
    }
}
