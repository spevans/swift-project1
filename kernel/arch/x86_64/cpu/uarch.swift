/*
 * kernel/arch/x86_64/cpu/uarch.swift
 *
 * Created by Simon Evans on 19/04/2026.
 * Copyright © 2026 Simon Evans. All rights reserved.
 *
 */


// Intel processor microarchitecture families.
// Derived from CPUID Leaf 01H EAX DisplayFamily_DisplayModel (SDM Vol. 4, Table 2-1,
// Oct 2025). Use CPUID.microarchitecture to obtain the value at runtime.
enum IntelMicroarchitecture: CustomStringConvertible {
    // Family 5
    case pentiumP5          // 05_01H, 05_02H, 05_04H - Pentium, Pentium MMX
    case intelQuark         // 05_09H - Quark X1000 SoC (SteppingID = 0)

    // P6 family (Family 6, legacy models)
    case pentiumPro         // 06_01H
    case pentiumII          // 06_03H, 06_05H, 06_06H
    case pentiumIII         // 06_07H, 06_08H, 06_0AH, 06_0BH
    case pentiumM           // 06_09H (Banias), 06_0DH (Dothan)

    // Netburst (Family 15)
    case netburst           // 0F_00H–0F_06H - Pentium 4, Pentium D, Xeon

    // Core microarchitecture (Family 6)
    case core               // 06_0EH - Yonah (Core Solo/Duo)
    case core2              // 06_0FH, 06_16H - Merom/Conroe
    case penryn             // 06_17H, 06_1DH - Penryn/Dunnington

    // Atom - Bonnell/Saltwell
    case bonnell            // 06_1CH, 06_26H, 06_27H, 06_35H, 06_36H

    // Nehalem microarchitecture
    case nehalem            // 06_1AH, 06_1EH, 06_1FH, 06_2EH
    case westmere           // 06_25H, 06_2CH, 06_2FH

    // Sandy Bridge / Ivy Bridge
    case sandyBridge        // 06_2AH, 06_2DH
    case ivyBridge          // 06_3AH, 06_3EH

    // Atom - Silvermont / Airmont
    case silvermont         // 06_37H, 06_4AH, 06_4DH, 06_5AH, 06_5DH
    case airmont            // 06_4CH - Cherry Trail / Braswell

    // Haswell / Broadwell
    case haswell            // 06_3CH, 06_45H, 06_46H, 06_3FH
    case broadwell          // 06_3DH, 06_47H, 06_4FH, 06_56H

    // Atom - Goldmont / Goldmont Plus
    case goldmont           // 06_5CH (Apollo Lake), 06_5FH (Denverton)
    case goldmontPlus       // 06_7AH - Gemini Lake

    // Skylake
    case skylake            // 06_4EH, 06_5EH - client
    // 06_55H covers Skylake-X, Cascade Lake, and Cooper Lake - distinguished
    // within the family by stepping (SDM Vol. 4 2.17, Tables 2-50..2-52).
    case skylakeServer      // 06_55H

    // Kaby Lake era (includes Coffee Lake, Whiskey Lake, Amber Lake)
    // 06_8EH: Kaby Lake-Y/U, Whiskey Lake, Amber Lake, Comet Lake-U (ULT)
    // 06_9EH: Kaby Lake-S/H, Coffee Lake, Xeon E
    case kabyLake           // 06_8EH, 06_9EH

    // Cannon Lake
    case cannonLake         // 06_66H

    // Ice Lake
    // 06_7DH, 06_7EH: Ice Lake client
    // 06_6AH, 06_6CH: Ice Lake Xeon SP (3rd gen Scalable)
    case iceLake            // 06_6AH, 06_6CH, 06_7DH, 06_7EH

    // Comet Lake
    case cometLake          // 06_A5H, 06_A6H

    // Rocket Lake
    case rocketLake         // 06_A7H

    // Tiger Lake
    case tigerLake          // 06_8CH, 06_8DH

    // Atom - Tremont
    case tremont            // 06_86H, 06_96H, 06_9CH

    // Alder Lake - 12th gen, performance hybrid (P+E cores)
    case alderLake          // 06_97H (desktop/H), 06_9AH (P/H/U)

    // Atom - Gracemont (Alder Lake-N, Core i3-N, Core 3 N-Series, Atom x7000)
    case gracemont          // 06_BEH

    // Raptor Lake - 13th/14th gen, performance hybrid
    case raptorLake         // 06_B7H, 06_BAH, 06_BFH

    // Xeon Scalable 4th/5th gen
    case sapphireRapids     // 06_8FH - 4th gen Xeon Scalable
    case emeraldRapids      // 06_CFH - 5th gen Xeon Scalable

    // Meteor Lake - Core Ultra 1st gen, performance hybrid
    case meteorLake         // 06_AAH

    // Xeon 6
    case graniteRapids      // 06_ADH, 06_AEH - Xeon 6 P-core
    case sierraForest       // 06_AFH - Xeon 6 E-core

    // Lunar Lake - Core Ultra 2nd gen (Intel Series 2), performance hybrid
    case lunarLake          // 06_BDH

    // Xeon Phi
    case knightsLanding     // 06_57H - Xeon Phi 3200/5200/7200
    case knightsMill        // 06_85H - Xeon Phi 7215/7285/7295

    case unknown

    var description: String {
        switch self {
            case .pentiumP5:      return "Pentium P5"
            case .intelQuark:     return "Intel Quark"
            case .pentiumPro:     return "Pentium Pro"
            case .pentiumII:      return "Pentium II"
            case .pentiumIII:     return "Pentium III"
            case .pentiumM:       return "Pentium M"
            case .netburst:       return "Netburst"
            case .core:           return "Core"
            case .core2:          return "Core 2"
            case .penryn:         return "Penryn"
            case .bonnell:        return "Bonnell"
            case .nehalem:        return "Nehalem"
            case .westmere:       return "Westmere"
            case .sandyBridge:    return "Sandy Bridge"
            case .ivyBridge:      return "Ivy Bridge"
            case .silvermont:     return "Silvermont"
            case .airmont:        return "Airmont"
            case .haswell:        return "Haswell"
            case .broadwell:      return "Broadwell"
            case .goldmont:       return "Goldmont"
            case .goldmontPlus:   return "Goldmont Plus"
            case .skylake:        return "Skylake"
            case .skylakeServer:  return "Skylake Server"
            case .kabyLake:       return "Kaby Lake"
            case .cannonLake:     return "Cannon Lake"
            case .iceLake:        return "Ice Lake"
            case .cometLake:      return "Comet Lake"
            case .rocketLake:     return "Rocket Lake"
            case .tigerLake:      return "Tiger Lake"
            case .tremont:        return "Tremont"
            case .alderLake:      return "Alder Lake"
            case .gracemont:      return "Gracemont"
            case .raptorLake:     return "Raptor Lake"
            case .sapphireRapids: return "Sapphire Rapids"
            case .emeraldRapids:  return "Emerald Rapids"
            case .meteorLake:     return "Meteor Lake"
            case .graniteRapids:  return "Granite Rapids"
            case .sierraForest:   return "Sierra Forest"
            case .lunarLake:      return "Lunar Lake"
            case .knightsLanding: return "Knights Landing"
            case .knightsMill:    return "Knights Mill"
            case .unknown:        return "Unknown"
        }
    }

    // True for processors with a mix of Performance and Efficiency cores.
    // These CPUs require CPUID leaf 0x1F (V2 topology) for correct core
    // enumeration; leaf 0x0B alone reports only P-core topology.
    var isPerformanceHybrid: Bool {
        switch self {
            case .alderLake, .gracemont, .raptorLake,
                    .meteorLake, .lunarLake:
                return true
            default:
                return false
        }
    }

    // Identify the Intel microarchitecture from the CPUID DisplayFamily_DisplayModel
    // signature. Source: SDM Vol. 4, Table 2-1 (Oct 2025). Non-Intel vendors
    // and unrecognised signatures return .unknown.

    init(_ displayFamily: UInt8, _ displayModel: UInt8) {

        self = switch displayFamily {
            case 5:
                switch displayModel {
                    case 9:           .intelQuark  // Quark X1000 (SteppingID=0)
                    default:          .pentiumP5   // 01H, 02H, 04H
                }
            case 6:
                switch displayModel {
                        // P6 legacy
                    case 0x01:                            .pentiumPro
                    case 0x03, 0x05, 0x06:                .pentiumII
                    case 0x07, 0x08, 0x0A, 0x0B:          .pentiumIII
                    case 0x09, 0x0D:                      .pentiumM
                        // Core microarchitecture
                    case 0x0E:                            .core
                    case 0x0F, 0x16:                      .core2
                    case 0x17, 0x1D:                      .penryn
                        // Bonnell / Saltwell Atom
                    case 0x1C, 0x26, 0x27, 0x35, 0x36:    .bonnell
                        // Nehalem / Westmere
                    case 0x1A, 0x1E, 0x1F, 0x2E:          .nehalem
                    case 0x25, 0x2C, 0x2F:                .westmere
                        // Sandy Bridge / Ivy Bridge
                    case 0x2A, 0x2D:                      .sandyBridge
                    case 0x3A, 0x3E:                      .ivyBridge
                        // Silvermont / Airmont Atom
                    case 0x37, 0x4A, 0x4D, 0x5A, 0x5D:    .silvermont
                    case 0x4C:                            .airmont
                        // Haswell / Broadwell
                    case 0x3C, 0x3F, 0x45, 0x46:          .haswell
                    case 0x3D, 0x47, 0x4F, 0x56:          .broadwell
                        // Goldmont / Goldmont Plus Atom
                    case 0x5C, 0x5F:                      .goldmont
                    case 0x7A:                            .goldmontPlus
                        // Skylake
                    case 0x4E, 0x5E:                      .skylake
                    case 0x55:                            .skylakeServer
                        // Kaby Lake / Coffee Lake / Whiskey Lake
                    case 0x8E, 0x9E:                      .kabyLake
                        // Cannon Lake
                    case 0x66:                            .cannonLake
                        // Ice Lake (client + Xeon SP 3rd gen)
                    case 0x6A, 0x6C, 0x7D, 0x7E:          .iceLake
                        // Comet Lake / Rocket Lake
                    case 0xA5, 0xA6:                      .cometLake
                    case 0xA7:                            .rocketLake
                        // Tiger Lake
                    case 0x8C, 0x8D:                      .tigerLake
                        // Tremont Atom
                    case 0x86, 0x96, 0x9C:                .tremont
                        // Alder Lake / Gracemont
                    case 0x97, 0x9A:                      .alderLake
                    case 0xBE:                            .gracemont
                        // Raptor Lake (13th/14th gen)
                    case 0xB7, 0xBA, 0xBF:                .raptorLake
                        // Xeon Scalable 4th/5th gen
                    case 0x8F:                            .sapphireRapids
                    case 0xCF:                            .emeraldRapids
                        // Meteor Lake
                    case 0xAA:                            .meteorLake
                        // Xeon 6
                    case 0xAD, 0xAE:                      .graniteRapids
                    case 0xAF:                            .sierraForest
                        // Lunar Lake
                    case 0xBD:                            .lunarLake
                        // Xeon Phi
                    case 0x57:                            .knightsLanding
                    case 0x85:                            .knightsMill
                    default:                              .unknown
                }
            case 15:
                    .netburst
            default:
                    .unknown
        }
    }
}

