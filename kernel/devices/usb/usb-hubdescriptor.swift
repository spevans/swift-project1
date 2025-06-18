//
//  usb-hubdescriptor.swift
//  Kernel
//
//  Created by Simon Evans on 07/06/2025.
//
//  USB Hub Descriptor



extension USB {

    struct HUBDescriptor: CustomStringConvertible {
        private let descriptor: usb_hub_descriptor

        var bDescLength: UInt8 { descriptor.bDescLength }
        var bDescriptorType: UInt8 { descriptor.bDescriptorType }
        var bNbrPorts: UInt8 { descriptor.bNbrPorts }
        var wHubCharacteristics: UInt16 { descriptor.wHubCharacteristics }
        var bPwrOn2PwrGood: UInt8 { descriptor.bPwrOn2PwrGood }
        var bHubContrCurrent: UInt8 { descriptor.bHubContrCurrent }
        let deviceRemovable: [Bool] // FIXME: Should be a BitArray
        // Ignore PortPwrCtrlMask has it should be all ones

        let description: String
        func descriptorAsBuffer(wLength: UInt16, into buffer: inout MMIOSubRegion) -> Int {
            let length = min(Int(descriptor.bDescLength), buffer.count)
            withUnsafeBytes(of: self.descriptor) {
                for idx in 0..<length {
                    buffer[idx] = $0[idx]
                }
            }
            return length
        }

        // Used by Root Hubs
        init(ports: UInt8) {
            precondition(ports < 8) // For simplicity
            descriptor = usb_hub_descriptor(
                bDescLength: 9,
                bDescriptorType: USB.DescriptorType.HUB.rawValue,
                bNbrPorts: ports,
                wHubCharacteristics: 0xa,
                bPwrOn2PwrGood: 10,
                bHubContrCurrent: 0,
                deviceRemoveable: 0,
                powerPwrCtrlMask: 0xff
            )
            deviceRemovable = .init(repeating: false, count: Int(ports))
            description = "Root Hub"
        }

        init(from buffer: MMIOSubRegion) throws(ParsingError) {
            var iterator = buffer.makeIterator()
            // Validate the initial bytes
            guard let lengthByte = iterator.next(), let descriptorByte = iterator.next() else { throw ParsingError.packetTooShort
            }
            guard Int(lengthByte) >= MemoryLayout<usb_standard_endpoint_descriptor>.size else { throw ParsingError.invalidLengthByte
            }
            guard descriptorByte == USB.DescriptorType.HUB.rawValue else {
                throw ParsingError.invalidDescriptor(descriptorByte)
            }

            var _descriptor = usb_hub_descriptor()
            try withUnsafeMutableBytes(of: &_descriptor) { (buffer: UnsafeMutableRawBufferPointer)
                throws(ParsingError) -> () in
                assert(MemoryLayout<usb_standard_endpoint_descriptor>.size == buffer.count)
                buffer[0] = lengthByte
                buffer[1] = descriptorByte

                for idx in 2..<(buffer.count-2) { // Exclude the last two bytes as they are variable lenggth
                    guard let byte = iterator.next() else { throw ParsingError.packetTooShort }
                    buffer[idx] = byte
                }
            }
            descriptor = _descriptor

            let variableByteCount = (descriptor.bNbrPorts + 8) / 8  // +8 not +7 as bit 0 is reserved so need to account for an extra bit
            var _deviceRemovable: [Bool] = []
            _deviceRemovable.reserveCapacity(Int(descriptor.bNbrPorts))
            // The DeviceRemovable and PortPwrCtrlMask should both be this many bytes long but
            // the PortPwrCtrlMask only needs to be checked for length, the value can be ignored
            var firstByte = true
            var portsRemaining = descriptor.bNbrPorts
            for _ in 0..<variableByteCount {
                guard var byte = iterator.next() else { throw ParsingError.packetTooShort }
                if firstByte { byte >>= 1 } // Bit 0 is reserved
                let maxBit = firstByte ? 7 : 8
                for _ in 1...maxBit {
                    if portsRemaining > 0 {
                        let bit = (byte & 1) == 1
                        _deviceRemovable.append(bit)
                        portsRemaining -= 1
                        byte >>= 1
                    }
                }
                firstByte = false
            }
            deviceRemovable = _deviceRemovable

            // Validate the size of the PortPwrCtrlMask
            for _ in 0..<variableByteCount {
                guard iterator.next() != nil else { throw ParsingError.packetTooShort }
            }
            description = "Normal Hub"
        }
    }
}
