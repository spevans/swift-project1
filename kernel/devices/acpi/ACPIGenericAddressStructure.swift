//
// kernel/devices/acpi/ACPIGenericAddressStructure.swift
//
// Created by Simon Evans on 17/04/2021.
// Copyright © 2021 Simon Evans. All rights reserved.
//
// ACPI Generic Address Structure.
//


struct ACPIGenericAddressStrucure {
    enum AddressSpaceID: UInt8 {
        case systemMemory = 0
        case systemIO = 1
    }

    private let gas: acpi_gas

    init(_ gas: acpi_gas) {
        self.gas = gas
    }

    var addressSpaceID: AddressSpaceID {
        return AddressSpaceID(rawValue: gas.address_space_id)!
    }

    var registerBitWidth: Int { Int(gas.register_bit_width) }
    var registerBitOffset: Int { Int(gas.register_bit_offset) }
    var access_size: Int { Int(gas.access_size) }
    var baseAddress: UInt64 { gas.address }
    var physicalAddress: PhysAddress { PhysAddress(RawAddress(baseAddress)) }
    var rawPointer: UnsafeMutableRawPointer { physicalAddress.rawPointer }
}
