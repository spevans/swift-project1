/*
 *  i915tty.swift
 *  Kernel
 *
 *  Created by Simon Evans on 26/07/2025.
 */


class I915TTY {
    typealias GPUCoord = UInt16

    private let gpu: I915
    private let width: UInt
    private let height: UInt
    private let textColour: RGBA32
    private let backgroundColour: RGBA32
    private var charsPerLine: TextCoord = 0
    private var totalLines: TextCoord = 0
    private var _cursorX: TextCoord = 0
    private var _cursorY: TextCoord = 0
    private var fontWidth: GPUCoord = 0
    private var fontHeight: GPUCoord = 0
    private var fontAddress: UInt32 = 0


    init?(gpu: I915, frameBufferInfo: FrameBufferInfo) {
        self.gpu = gpu


        self.width = UInt(frameBufferInfo.width)
        self.height = UInt(frameBufferInfo.height)
        self.textColour = 0xffffffff
        self.backgroundColour = 0xff000000
        gpu.xy_setup_blt(bgColour: self.backgroundColour, fgColour: self.textColour)
        gpu.miFlush()

        guard self.setFont(Font.currentFont) else {
            #kprint("i915: Failed to set font")
            return nil
        }
    }

    func addTTYDriver() {
        let driver = TTY.Driver(
            name: "i915",
            charsPerLine: { self.charsPerLine },
            totalLines: { self.totalLines },
            printChar: { c, x, y in
                self.printChar(c, x: x, y: y)
            },
            clearScreen: { self.clearScreen() },
            scrollUp: { self.scrollUp() },
            getCursorX: { self.cursorX },
            getCursorY: { self.cursorY },
            setCursorX: { self.cursorX = $0 },
            setCursorY: { self.cursorY = $0 },
            doTimings: { self.doTimings() },
            setFont: { self.setFont($0) },
        )

        setTTYDriver(driver)
    }

    @discardableResult
    func setFont(_ font: Font) -> Bool {
        guard let address = gpu.mapFont(font, at: 0x3000000) else {
            #kprint("Failed to get physical address of font")
            return false
        }

        self.fontAddress = address
        self.fontWidth = GPUCoord(font.width)
        self.fontHeight = GPUCoord(font.height)
        self.charsPerLine = TextCoord(width / UInt(font.width))
        self.totalLines = TextCoord(height / UInt(font.height))
        return true
    }


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

    func clearScreen() {
        gpu.xy_color_blt(x1: 0, y1: 0, x2: UInt16(self.width), y2: UInt16(self.height), colour: backgroundColour)
        gpu.miFlush()
    }

    func scrollUp() {
        let x2 = GPUCoord(self.width)
        let y2 = GPUCoord(self.height)
        gpu.xy_src_copy_blt(x1: 0, y1: 0, x2: x2, y2: y2 - self.fontHeight, sourceX1: 0, sourceY1: self.fontHeight)
        gpu.xy_color_blt(x1: 0, y1: y2 - self.fontHeight - 1, x2: x2, y2: y2, colour: backgroundColour)
        gpu.miFlush()
    }

    func printChar(_ character: UInt8, x: TextCoord, y: TextCoord) {
        guard x < charsPerLine, y < totalLines else { return }
        let x1 = GPUCoord(x) * self.fontWidth
        let x2 = x1 + self.fontWidth
        let y1 = GPUCoord(y) * self.fontHeight
        let y2 = y1 + self.fontHeight

        let chOffset = UInt32(character) * UInt32(self.fontWidth / 8) * UInt32(self.fontHeight)
        let sourceAddress = self.fontAddress + chOffset
        gpu.xy_text_blt(x1: x1, y1: y1, x2: x2, y2: y2, sourceAddress: sourceAddress)
        gpu.miFlush()
    }

    private func doTimings() -> TTY.Timings {
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
                printChar(UInt8(ascii: "X"), x: x, y: 1)
            }
        }

        let oneCharTicks = benchmark {
            printChar(UInt8(ascii: "A"), x: 10, y: 2)
        }

        let scrollUpTicks = benchmark {
            scrollUp()
        }

        let clearScreenTicks = benchmark {
            clearScreen()
        }


        return TTY.Timings(
            charsPerLine: charsPerLine,
            totalLines: totalLines,
            fullscreenCharTicks: fullscreenCharTicks,
            oneLineCharTicks: oneLineCharTicks,
            oneCharTicks: oneCharTicks,
            scrollUpTicks: scrollUpTicks,
            clearScreenTicks: clearScreenTicks,
            clearScreen2Ticks: clearScreenTicks
        )
    }
}
