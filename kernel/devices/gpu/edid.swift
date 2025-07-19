//
//  edid.swift
//  Kernel
//
//  Created by Simon Evans on 07/07/2025.
//
//  Monitor EDID decode - Extended Display Identification Data
//


struct EDID {
    struct StandardTiming {
        let horizontalPixels: Int
        let verticalLines: Int
        let refreshRate: Int
        let aspectRatio: (Int, Int)
    }


    struct DetailedTiming {
        let pixelClock: Int
        let horizontalPixels: UInt16
        let horizontalBlankingPixels: UInt16
        let verticalLines: UInt16
        let verticalBlankingLines: UInt16
        let horizontalSyncOffset: UInt16
        let horizontalSyncPulseWidth: UInt16
        let verticalSyncOffset: UInt16
        let verticalSyncPulseWidth: UInt16
        let horizontalImageSizeInMM: UInt16
        let verticalImageSizeInMM: UInt16
        let horizontalBorderPixels: UInt16
        let verticalBorderPixels: UInt16

        let featuresBitmap: UInt8
        let interleaced: Bool
        let stereoMode: StereoMode

        let analogSync: Bool
        var digitalSync: Bool { !analogSync }
        let digitalSyncComposite: Bool
        var digitalSyncSeparate: Bool { !digitalSyncComposite }
        let biPolarAnalogComposite: Bool
        let withSerrations: Bool
        let syncOnGreenOnly: Bool
        let hSyncPolarityPositive: Bool
        let vSyncPolarityPositive: Bool


        enum StereoMode {
            case none
            case fieldSeqRightDuringSync
            case fieldSeqLeftDuringSync
            case twoWayInterleavedRightOnEven
            case twoWayInterleavedLeftOnEven
            case fourWayInterleaved
            case sideBySideInterleaved

            init(rawValue: Int) {
                switch rawValue {
                    case 2: self = .fieldSeqRightDuringSync
                    case 3: self = .twoWayInterleavedRightOnEven
                    case 4: self = .fieldSeqLeftDuringSync
                    case 5: self = .twoWayInterleavedLeftOnEven
                    case 6: self = .fourWayInterleaved
                    case 7: self = .sideBySideInterleaved
                    default: self = .none
                }
            }
        }


        var vRefreshRate: Int {
            let hPixels = Int(horizontalPixels) + Int(horizontalBlankingPixels)
            let vPixels = Int(verticalLines) + Int(verticalBlankingLines)
            return pixelClock / (hPixels * vPixels)
        }

        var hRefreshRate: Int {
            let hPixels = Int(horizontalPixels) + Int(horizontalBlankingPixels)
            return pixelClock / hPixels
        }


        init(data: ArraySlice<UInt8>) {
            let data = data.span
            precondition(data.count == 18)
            self.pixelClock = 10_000 * (Int(data[0]) | (Int(data[1]) << 8))
            self.horizontalPixels = UInt16(data[2]) | UInt16(data[4].bits(4...7) << 8)
            self.horizontalBlankingPixels = UInt16(data[3]) | UInt16(data[4].bits(0...3) << 8)
            self.verticalLines = UInt16(data[5]) | UInt16(data[7].bits(4...7) << 8)
            self.verticalBlankingLines = UInt16(data[6]) | UInt16(data[7].bits(0...3) << 8)
            self.horizontalSyncOffset = UInt16(data[8]) | UInt16(data[11].bits(6...7) << 8)
            self.horizontalSyncPulseWidth = UInt16(data[9]) | UInt16(data[11].bits(4...5) << 8)
            self.verticalSyncOffset = UInt16(data[10].bits(4...7)) | UInt16(data[11].bits(2...3) << 4)
            self.verticalSyncPulseWidth = UInt16(data[10].bits(0...3)) | UInt16(data[11].bits(0...1) << 4)
            self.horizontalImageSizeInMM = UInt16(data[12]) | UInt16(data[14].bits(4...7) << 8)
            self.verticalImageSizeInMM = UInt16(data[13]) | UInt16(data[14].bits(0...3) << 8)
            self.horizontalBorderPixels = UInt16(data[15])
            self.verticalBorderPixels = UInt16(data[16])
            // TODO, decode this somehow
            self.featuresBitmap = data[17]

            self.interleaced = featuresBitmap.bit(7)

            // Bits 6-5,0
            let smode = (featuresBitmap.bits(5...6) << 1) | featuresBitmap.bits(0...0)
            stereoMode = StereoMode(rawValue: smode)


            // Bits 4-1
            if !featuresBitmap.bit(4) {
                analogSync = true
                biPolarAnalogComposite = featuresBitmap.bit(3)
                withSerrations = featuresBitmap.bit(2)
                syncOnGreenOnly = featuresBitmap.bit(1)

                // Does not apply
                digitalSyncComposite = false
                hSyncPolarityPositive = false
                vSyncPolarityPositive = false
            } else {
                hSyncPolarityPositive = featuresBitmap.bit(1)
                if featuresBitmap.bit(3) {
                    digitalSyncComposite = false
                    vSyncPolarityPositive = featuresBitmap.bit(2)
                    withSerrations = false
                } else {
                    digitalSyncComposite = true
                    withSerrations = featuresBitmap.bit(2)
                    vSyncPolarityPositive = false
                }

                // Does not apply
                analogSync = false
                biPolarAnalogComposite = false
                syncOnGreenOnly = false
            }
        }
    }

    struct DigitalInput {
        enum VideoInterface: Int, CustomStringConvertible {
            case undefined = 0
            case dvi = 1
            case hdmia = 2
            case hdmib = 3
            case mddi = 4
            case displayPort = 5

            var description: String {
                return switch self {
                    case .undefined: "Undefined"
                    case .dvi: "DVI"
                    case .hdmia: "HDMIA"
                    case .hdmib: "HDMIB"
                    case .mddi: "MDDI"
                    case .displayPort: "Display Port"

                }
            }
        }

        let bitDepth: Int?
        let interface: VideoInterface?
    }

    struct AnalogInput {
        let whiteAndSyncLevel: Int
        let blankToBlackSetup: Bool
        let separateSyncSupport: Bool
        let compositeSyncSupport: Bool
        let syncOnGreenSupport: Bool
        let vsyncPulseSerrated: Bool
    }

    enum DigitalDisplay: Int {
        case rgb444 = 0
        case rgb444_yCrCb444 = 1
        case rgb444_yCrCb422 = 2
        case rgb444_yCrCb444_yCrCb422 = 3
    }

    enum AnalogDisplay: Int {
        case monochrome = 0
        case rgb = 1
        case nonRgb = 2
        case undefined = 3
    }


    private let rawValue: edid_data

    let manufacturerID: String
    let productCode: UInt16
    let serialNumber: UInt32
    let manufactureWeek: Int
    let manufactureYear: Int
    let version: Int
    let revision: Int
    let standardTimings: [StandardTiming] // FIXME, make InlineArray = .init(repeating: nil, count: 8)
    let detailedTimings: [DetailedTiming]
    let serialNumberText: String?
    let monitorName: String?
    let extraMonitorText: String?


    var digitalInput: DigitalInput? {
        let value = BitArray8(rawValue.video_input_bitmap)
        guard value[7] == 1 else { return nil }
        let bitDepth = Int(value[4...6])

        return DigitalInput(bitDepth: bitDepth == 0 ? nil : (bitDepth * 2) + 4,
                            interface: DigitalInput.VideoInterface(rawValue: Int(value[0...3])))
    }

    var analogInput: AnalogInput? {
        let value = BitArray8(rawValue.video_input_bitmap)
        guard value[7] == 0 else { return nil }
        return AnalogInput(whiteAndSyncLevel: Int(value[5...6]),
                           blankToBlackSetup: value[4] != 0,
                           separateSyncSupport: value[3] != 0,
                           compositeSyncSupport: value[2] != 0,
                           syncOnGreenSupport: value[1] != 0,
                           vsyncPulseSerrated: value[0] != 0
        )
    }

    var horizontalScreenSizeInCM: Int? {
        rawValue.vertical_screen_size == 0 ? nil : Int(rawValue.horizontal_screen_size)
    }
    var verticalScreenSizeInCM: Int? {
        rawValue.horizontal_screen_size == 0 ? nil : Int(rawValue.vertical_screen_size)
    }
    var landscapeAspectRatio: (Int, Int)? {
        guard rawValue.vertical_screen_size == 0 else { return nil }
        let ratio = rawValue.horizontal_screen_size + 99
        return switch ratio {
            case 125: (5, 4)
            case 133: (4, 3)
            case 160: (16, 10)
            case 178: (16, 9)
            default: nil
        }
    }
    var portraitAspectRatio: (Int, Int)? {
        guard rawValue.horizontal_screen_size == 0 else { return nil }
        let ratio = Int(rawValue.vertical_screen_size) + 99
        return switch ratio {
            case 56: (10, 16)
            case 80: (4, 5)
            case 133: (3, 4)
            case 178: (9, 16)
            default: nil
        }
    }

    var displayGamma: (Int, Int)? {
        if rawValue.display_gamma == 0xff { return nil }
        let gamma = Int(rawValue.display_gamma) + 100
        return (gamma / 100, gamma % 100)
    }

    var dpmsStandbySupported: Bool { rawValue.supported_features_bitmap.bit(7) }
    var dpmsSuspendSupported: Bool { rawValue.supported_features_bitmap.bit(6) }
    var dpmsActiveOffSupported: Bool { rawValue.supported_features_bitmap.bit(5) }

    var digitalDisplay: DigitalDisplay? {
        if rawValue.video_input_bitmap.bit(7) {
            return DigitalDisplay(rawValue: rawValue.supported_features_bitmap.bits(3...4))
        } else {
            return nil
        }
    }

    var analogDisplay: AnalogDisplay? {
        if rawValue.video_input_bitmap.bit(7) {
            return nil
        } else {
            return AnalogDisplay(rawValue: rawValue.supported_features_bitmap.bits(3...4))
        }
    }


    init(from buffer: [UInt8]) {
        // Ensure the data is at least 128 bytes long
        guard buffer.count >= MemoryLayout<edid_data>.size else {
            fatalError("EDID data is too short")
        }

        var _edid = edid_data()
        withUnsafeMutableBytes(of: &_edid) {
            for idx in 0..<MemoryLayout<edid_data>.size {
                $0[idx] = buffer[idx]
            }
        }
        self.rawValue = _edid
        #kprintf("EDID Header: %16.16x\n", _edid.header)
        guard _edid.header == 0x00ff_ffff_ffff_ff00 else {
            fatalError("Invalid header")
        }

        let manuId = rawValue.manufacturer_id.bigEndian
        let charOffset = UInt8(ascii: "A") - 1
        self.manufacturerID = #sprintf("%c%c%c",
                                       UInt8(manuId >> 10 & 0x1f) + charOffset,
                                       UInt8(manuId >> 5 & 0x1f) + charOffset,
                                       UInt8(manuId >> 0 & 0x1f) + charOffset)

        self.productCode = rawValue.product_code
        self.serialNumber = rawValue.serial_number
        self.manufactureWeek = Int(rawValue.manufacture_week)
        self.manufactureYear = Int(rawValue.manufacture_year) + 1990 // Year is offset from 1990
        self.version = Int(rawValue.version)
        self.revision = Int(rawValue.revision)

        // TOOD: Established timings bitmap
        if rawValue.established_timings.0 != 0 || rawValue.established_timings.1 != 0 || rawValue.established_timings.2 != 0 {
            #kprint("Established timings bitmap not yet supported")
        }
        // Extract standard timings
        var _timings: [StandardTiming] = []
        for idx in 0..<8 {
            let byte0 = buffer[38 + idx * 2]
            let byte1 = buffer[39 + idx * 2]
            if byte0 == 1, byte1 == 1 {
                continue
            }

            let xPixels = 8 * (Int(byte0) + 31)
            let aspectRatio = switch byte1.bits(6...7) {
                case 0: (version * 100 + revision) < 103 ? (1,1) : (16, 10)
                case 1: (4,3)
                case 2: (5,4)
                default: (16, 9)   // case 3
            }
            _timings.append(StandardTiming(horizontalPixels: xPixels,
                                           verticalLines: (xPixels * aspectRatio.1) / aspectRatio.0,
                                           refreshRate: byte1.bits(0...5) + 60,
                                           aspectRatio: aspectRatio))
        }
        self.standardTimings = _timings

        // Convert codepage 437 bytes to a String
        func textFromCP437(data: Span<UInt8>) -> String {
            var result = ""
            for index in data.indices {
                let byte = data[index]
                if byte == NEWLINE {
                    return result
                }
                if byte >= 0x20 && byte <= 0x7E {
                    result.append(Character(UnicodeScalar(byte)))
                } else {
                    result.append(" ")
                }
            }
            return result
        }


        var _detailedTimings: [DetailedTiming] = []
        var _monitorName: String?
        var _extraMonitorText: String?
        var _serialNumberText: String?

        // Extract Detailed Timings or monitor descriptors
        for timing in 0...3 {
            let offset = (timing * 18) + 54
            let slice = buffer[offset...offset+17]
            let idx = slice.startIndex
            if slice[idx + 0] == 0, slice[idx + 1] == 0 {
                // Monitor descriptor
                switch slice[idx + 3] {
                    case 0xFC:
                        let text = slice[idx+5...idx+17]
                        _monitorName = textFromCP437(data: text.span)
                    case 0xFE:
                        let text = slice[idx+5...idx+17]
                        _extraMonitorText = textFromCP437(data: text.span)
                    case 0xFF:
                        let text = slice[idx+5...idx+17]
                        _serialNumberText = textFromCP437(data: text.span)
                    default:
                        #kprintf("EDID: unsupported Monitor Descriptor: %2.2x\n", slice[idx + 3])
                }
            } else {
                let detailedTiming = DetailedTiming(data: buffer[offset...offset+17])
                _detailedTimings.append(detailedTiming)
            }
        }
        self.detailedTimings = _detailedTimings
        self.monitorName = _monitorName
        self.extraMonitorText = _extraMonitorText
        self.serialNumberText = _serialNumberText
    }


    func dump() {
        #kprintf("EDID version: %d.%d\n", version, revision)
        #kprintf("Manufacturer: %s %4.4x serial number: %d\n", manufacturerID, productCode, serialNumber)
        if let monitorName {
            #kprintf("Monitor name: %s\n", monitorName)
        }
        if let serialNumberText {
            #kprintf("Serial number: %s\n", serialNumberText)
        }
        if let extraMonitorText {
            #kprintf("Extra monitor text: %s\n", extraMonitorText)
        }
        #kprintf("Made in week %d of %d\n", manufactureWeek, manufactureYear)
        if let digitalInput {
            #kprintf("Digital Display: %s bitDepth: %d\n",
                    digitalInput.interface?.description ?? "unknown",
                    digitalInput.bitDepth ?? 0)
        } else {
            #kprint("Analog Display")
        }
        if let width = horizontalScreenSizeInCM, let height = verticalScreenSizeInCM {
            #kprintf("Maximum image size: %d cm x %d cm\n", width, height)
        } else if let landscapeAspectRatio {
            #kprintf("Landscape aspect ratio: %d:%d\n", landscapeAspectRatio.0, landscapeAspectRatio.1)
        } else if let portraitAspectRatio {
            #kprintf("Portrait aspect ratio: %d:%d\n", portraitAspectRatio.0, portraitAspectRatio.1)
        }
        if let gamma = displayGamma {
            #kprintf("Gamma: %d.%d\n", gamma.0, gamma.1)
        }
        #kprint("Standard Timings:")
        for timing in standardTimings {
            #kprintf("  %dx%d@%dhz %d:%d\n", timing.horizontalPixels, timing.verticalLines, timing.refreshRate,
                     timing.aspectRatio.0, timing.aspectRatio.1)
        }
        #kprint("Detailed Timings:")
        for timing in detailedTimings {

            #kprintf("  %dx%d@%dhz\tClock: %d.%d MHz\t\t%u mm x %u mm\n",
                     timing.horizontalPixels, timing.verticalLines, timing.vRefreshRate,
                     timing.pixelClock / 1000_000, timing.pixelClock % 1000_000,
                     timing.horizontalImageSizeInMM, timing.verticalImageSizeInMM
            )

            #kprintf("    H: %4d %4d %4d %4d border: %d\n",
                     timing.horizontalPixels, timing.horizontalPixels + timing.horizontalSyncOffset,
                     timing.horizontalPixels + timing.horizontalSyncOffset + timing.horizontalSyncPulseWidth,
                     timing.horizontalPixels + timing.horizontalBlankingPixels, timing.horizontalBorderPixels
            )

            #kprintf("    V: %4d %4d %4d %4d border: %d\n",
                     timing.verticalLines, timing.verticalLines + timing.verticalSyncOffset,
                     timing.verticalLines + timing.verticalSyncOffset + timing.verticalSyncPulseWidth,
                     timing.verticalLines + timing.verticalBlankingLines, timing.verticalBorderPixels
            )

            #kprintf("    Vfreq: %dHz  Hfreq: %dHz  ", timing.vRefreshRate, timing.hRefreshRate)
            if timing.digitalSync {
                #kprintf("%chsync  %cvsync  ", timing.hSyncPolarityPositive ? Character("+") : Character("-"),
                         timing.vSyncPolarityPositive ? Character("+") : Character("-"))
            }
            #kprint("")
        }
        #kprintf("DPMS: Standby: %s  Suspend: %s  Active Off: %s\n",
                 dpmsStandbySupported, dpmsSuspendSupported, dpmsActiveOffSupported)
    }
}
