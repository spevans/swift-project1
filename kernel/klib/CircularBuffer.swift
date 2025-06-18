/*
 * kernel/klib/CircularBuffer.swift
 *
 * Created by Simon Evans on 05/03/2017.
 * Copyright © 2017 Simon Evans. All rights reserved.
 *
 * Simple circular buffer implementation.
 *
 */

// TODO: Add sleep/wask of consumer.

final class CircularBuffer<T> {
    private var buffer: Array<T>
    private let capacity: Int
    private let dropOldest: Bool
    private var idxIn = 0, idxOut = 0, count = 0

    init(item: T, capacity: Int, dropOldest: Bool = true) {
        self.capacity = capacity
        self.dropOldest = dropOldest
        buffer = Array(repeating: item, count: capacity)
    }

    func clear() {
        idxIn = 0
        idxOut = 0
        count = 0
    }

    @discardableResult
    func add(_ item: T) -> Bool {
        return noInterrupt {
            if count < capacity {
                buffer[idxIn] = item
                count += 1
                idxIn += 1
            } else if dropOldest {
                buffer[idxIn] = item
                idxIn += 1
                idxOut += 1
                if idxOut == capacity {
                    idxOut = 0
                }
            } else {
                return false
            }
            if idxIn == capacity {
                idxIn = 0
            }
            return true
        }
    }

    func remove() -> T? {
        return noInterrupt {
            guard count > 0 else {
                return nil
            }
            let result = buffer[idxOut]
            count -= 1
            idxOut += 1
            if idxOut == capacity {
                idxOut = 0
            }
            return result
        }
    }
}
