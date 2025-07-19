/*
 *  i915tty.swift
 *  Kernel
 *
 *  Created by Simon Evans on 26/07/2025.
 */


class I915TTY {
    typealias GPUCoord = UInt16

    private let gpu: I915
    private var font: Font

    private let width: UInt
    private let height: UInt
    private let charsPerLine: TextCoord
    private let totalLines: TextCoord
    private let textColour: RGBA32
    private let backgroundColour: RGBA32
    private var _cursorX: TextCoord = 0
    private var _cursorY: TextCoord = 0
    private let fontAddress: UInt32


    init?(gpu: I915, frameBufferInfo: FrameBufferInfo) {
        self.gpu = gpu
        self.font = Font(
            width: 8, height: 16, data: UnsafePointer<UInt8>(bitPattern: UInt(bitPattern: &fontdata_8x16))!
        )
        self.width = UInt(frameBufferInfo.width)
        self.height = UInt(frameBufferInfo.height)
        self.charsPerLine = TextCoord(width / UInt(font.width))
        self.totalLines = TextCoord(height / UInt(font.height))
        self.textColour = 0xffffffff
        self.backgroundColour = 0xff000000

        // FIXME: dont hardcode these values
        guard let address = gpu.mapFont(at: 0x3000000) else {
            #kprint("Failed to map font")
            return nil
        }
        self.fontAddress = address
        gpu.xy_setup_blt(bgColour: self.backgroundColour, fgColour: self.textColour)
        gpu.miFlush()
    }

    func addTTYDriver() {
        let driver = TTY.Driver(
            charsPerLine: charsPerLine,
            totalLines: totalLines,
            printChar: { c, x, y in
                self.printChar(c, x: x, y: y)
            },
            clearScreen: { self.clearScreen() },
            scrollUp: { self.scrollUp() },
            getCursorX: { self.cursorX },
            getCursorY: { self.cursorY },
            setCursorX: { self.cursorX = $0 },
            setCursorY: { self.cursorY = $0 },
            doTimings: { self.doTimings() }
        )

        setTTYDriver(driver)
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
        gpu.xy_src_copy_blt(x1: 0, y1: 0, x2: x2, y2: y2 - GPUCoord(font.height), sourceX1: 0, sourceY1: GPUCoord(font.height))
        gpu.xy_color_blt(x1: 0, y1: y2 - GPUCoord(font.height) - 1, x2: x2, y2: y2, colour: backgroundColour)
        gpu.miFlush()
    }

    func printChar(_ character: CUnsignedChar, x: TextCoord, y: TextCoord) {
        let x1 = GPUCoord(x) * GPUCoord(font.width)
        let x2 = x1 + GPUCoord(font.width)
        let y1 = GPUCoord(y) * GPUCoord(font.height)
        let y2 = y1 + GPUCoord(font.height)

        let chOffset = UInt32(character) * 16
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
                printChar(UInt8(ascii: "X"), x: x, y: 30)
            }
        }

        let oneCharTicks = benchmark {
            printChar(UInt8(ascii: "A"), x: 10, y: 31)
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
