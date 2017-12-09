//
//  ReservationManager.swift
//  acpi
//
//  Created by Simon Evans on 06/12/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//


struct ReservedSpace: CustomStringConvertible {
    let name: String
    let start: UInt
    let end: UInt

    var description: String {
        if start == end {
            return "\(name): 0x\(String(start, radix: 16))"
        } else {
            return "\(name): 0x\(String(start, radix: 16)) - 0x\(String(end, radix: 16))"
        }
    }
}

struct ReservationSpace {
    let name: String
    let start: UInt
    let end: UInt
    var reservedSpaces: [ReservedSpace]

    init(name: String, start: UInt, end: UInt) {
        self.name = name
        self.start = start
        self.end = end
        reservedSpaces = []
    }

    mutating func reserveSpace(name: String, start: UInt, end: UInt) -> Bool {
        precondition(end >= start)
        if start < self.start || end > self.end {
            return false
        }

        // Look through the ranges already reserved and check there is no overlap
        // FIXME: use a better lookup
        for idx in reservedSpaces.startIndex..<reservedSpaces.endIndex {
            if (start >= reservedSpaces[idx].start && start <= reservedSpaces[idx].end) ||
                (end >= reservedSpaces[idx].start && end <= reservedSpaces[idx].end) {
                    return false
            }
        }
        let newSpace = ReservedSpace(name: name, start: start, end: end)
        reservedSpaces.append(newSpace)
        return true
    }

    func showReservedSpaces() {
        for space in reservedSpaces.sorted(by: { $0.start < $1.start }) {
            print(space)
        }
    }
}
