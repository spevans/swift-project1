/*
 * kernel/klib/Extensions.swift
 *
 * Created by Simon Evans on 28/12/2015.
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Misc extensions
 *
 */


extension String {
    public static func printf(format: String, _ arguments: CVarArgType...) {
        withVaList(arguments) {
            let len = format.utf8.count + 1
            let buffer = UnsafeMutablePointer<CChar>.alloc(len)
            var idx = 0
            for ch in format.utf8 {
                buffer[idx] = CChar(ch)
                idx += 1
            }
            buffer[idx] = CChar(0)
            kvprintf(buffer, $0)
            buffer.dealloc(len)
        }
    }
}
