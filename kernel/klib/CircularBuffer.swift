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

class CircularBuffer<T> {
    private var buffer: Array<T>
    private let capacity: Int
    private var idxIn = 0, idxOut = 0, count = 0

    init(item: T, capacity: Int) {
        self.capacity = capacity
        buffer = Array(repeating: item, count: capacity)
    }

    func clear() {
        idxIn = 0
        idxOut = 0
        count = 0
    }

    func add(_ item: T) -> Bool {
        return noInterrupt {
            guard count < capacity else {
                return false
            }
            buffer[idxIn] = item
            count += 1
            idxIn += 1
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
