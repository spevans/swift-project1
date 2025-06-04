/*
 * kernel/devices/usb/uhci-registers.swift
 *
 * Created by Simon Evans on 01/11/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * UHCI Register IO and definitions.
 *
 */


internal extension HCD_UHCI {

    struct Command: Equatable, CustomStringConvertible {
        private var bits: BitArray16
        var rawValue: UInt16 { bits.rawValue }

        init(rawValue: UInt16) {
            bits = BitArray16(rawValue & 0xff)  // Bits 15:8 reserved
        }

        init() {
            self.init(rawValue: 0)
        }

        var run: Bool {
            get { bits[0] == 1 }
            set { bits[0] = newValue ? 1 : 0 }
        }

        var stop: Bool {
            get { !run }
            set { run = !newValue }
        }

        var hostControllerReset: Bool {
            get { bits[1] == 1 }
            set { bits[1] = newValue ? 1 : 0 }
        }

        var globalReset: Bool {
            get { bits[2] == 1 }
            set { bits[2] = newValue ? 1 : 0 }
        }

        var enterGlobalSuspendMode: Bool {
            get { bits[3] == 1 }
            set { bits[3] = newValue ? 1 : 0 }
        }

        var forceGlobalResume: Bool {
            get { bits[4] == 1 }
            set { bits[4] = newValue ? 1 : 0 }
        }

        var debugMode: Bool {
            get { bits[5] == 1 }
            set { bits[5] = newValue ? 1 : 0 }
        }

        var configureFlag: Bool {
            get { bits[6] == 1 }
            set { bits[6] = newValue ? 1 : 0 }
        }

        var maxPacket64Bytes: Bool {
            get { bits[7] == 1 }
            set { bits[7] = newValue ? 1 : 0 }
        }

        var maxPacket32Bytes: Bool {
            get { !maxPacket64Bytes }
            set { maxPacket64Bytes = !newValue }
        }

        var description: String {
            return "USBCommand: 0x\(String(rawValue, radix: 16))"
                + " RS: \(run) HCRESET: \(hostControllerReset) GRESET: \(globalReset)"
                + " EGSM: \(enterGlobalSuspendMode) FGR: \(forceGlobalResume)"
                + " DBG: \(debugMode) CF: \(configureFlag) MAXP: \(maxPacket64Bytes ? 64: 32)"
        }
    }


    struct Status: CustomStringConvertible {
        private var bits: BitArray16
        var rawValue: UInt16 { bits.rawValue }

        init(rawValue: UInt16) {
            bits = BitArray16(rawValue & 0x3f)  // Bits 15:6 reserved
        }

        var interrupt: Bool { bits[0] == 1 }
        mutating func clearInterrupt() { bits[0] = 1 }

        var errorInterrupt: Bool { bits[1] == 1 }
        mutating func clearErrorInterrupt() { bits[1] = 1 }

        var resumeDetect: Bool { bits[2] == 1 }
        mutating func clearResumeDetect() { bits[2] = 1 }

        var hostSystemError: Bool { bits[3] == 1 }
        mutating func clearHostSystemError() { bits[3] = 1}

        var hostControllerProcessError: Bool { bits[4] == 1 }
        mutating func clearHostControllerProcessError() { bits[4] = 1 }

        var hostControllerHalted: Bool { bits[5] == 1 }
        mutating func clearHostControllerHalted() { bits[5] = 1 }

        var description: String {
            return "USBStatus: 0x\(String(rawValue, radix: 16))" +
                " USBINT: \(bits[0]) ErrInt: \(bits[1]) RD: \(bits[2])" +
                " SysErr: \(bits[3]) ProcErr: \(bits[4]) Halted: \(bits[5])"
        }
    }


    struct InterruptEnable: CustomStringConvertible {
        private var bits: BitArray16
        var rawValue: UInt16 { bits.rawValue }

        init(rawValue: UInt16) {
            bits = BitArray16(rawValue & 0x0f)  // Bits 15:4 reserved
        }

        static func all() -> InterruptEnable {
            return InterruptEnable(rawValue: 0x0f)
        }

        var timeoutCRCEnabled: Bool {
            get { bits[0] == 1 }
            set { bits[0] = newValue ? 1 : 0 }
        }

        var resumtEnabled: Bool {
            get { bits[1] == 1 }
            set { bits[1] = newValue ? 1 : 0 }
        }

        var onCompleteEnabled: Bool {
            get { bits[2] == 1 }
            set { bits[2] = newValue ? 1 : 0 }
        }

        var shortPacketEnabled: Bool {
            get { bits[3] == 1 }
            set { bits[3] = newValue ? 1 : 0 }
        }

        var description: String {
            return "USBINTR: 0x\(String(rawValue, radix: 16))" +
                " TOCRC: \(bits[0]) RES: \(bits[1]) OC: \(bits[2]) SP: \(bits[3])"
        }
    }


    struct PortStatusControl: CustomStringConvertible {
        private var bits: BitArray16
        var rawValue: UInt16 { bits.rawValue }

        init(rawValue: UInt16) {
            bits = BitArray16(rawValue)
            bits[7] = 1
        }

        var currentConnectStatus: Bool { bits[0] == 1 }

        var connectStatusChange: Bool { bits[1] == 1 }
        mutating func clearConnectStatusChange() { bits[1] = 1 }

        var portEnabled: Bool {
            get { bits[2] == 1 }
            set { bits[2] = newValue ? 1 : 0 }
        }
        var portDisabled: Bool {
            get { !portEnabled }
            set { portEnabled = !newValue }
        }

        var portEnabledChange: Bool { bits[3] == 1 }
        mutating func clearPortEnabledDisabledChange() { bits[3] = 1 }

        var lineStatus: Int { Int(bits[4...5]) }

        var resumeDetect: Bool {
            get { bits[6] == 1 }
            set { bits[6] = newValue ? 1 : 0 }
        }

        var lowSpeedDeviceAttached: Bool { bits[8] == 1 }

        var portReset: Bool {
            get { bits[9] == 1 }
            set { bits[9] = newValue ? 1 : 0 }
        }

        var overCurrentCondition: Bool {
            get { bits[10] == 1 }
        }

        var overCurrentConditionChange: Bool {
            get { bits[11] == 1}
        }
        mutating func clearOverCurrentConditionChange()  {
            bits[11] = 1
        }

        var suspend: Bool {
            get { bits[12] == 1 }
            set { bits[12] = newValue ? 1 : 0 }
        }

        var description: String {
            return "PORT: 0x\(String(rawValue, radix: 16))" +
                " Connected: \(bits[0]) ConnectChange: \(bits[1]) enb: \(bits[2]) enbChange: \(bits[4])" +
                " LnSts: \(lineStatus) Resume: \(bits[6]) LoSpd: \(bits[8]) Reset: \(bits[9]) Suspend: \(bits[12])"
        }
    }
}
