//
//  tests.swift
//  acpi
//
//  Created by Simon Evans on 08/05/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//

import Foundation

func checkObjects(_ acpi: ACPI) {

    acpi.globalObjects.dumpDevices()

    acpi.globalObjects.runBody(root: "\\") { (name, object) in
        if let method = object as? AMLMethod, method.flags.argCount == 0 {
            print(name, ":\t", type(of: object), "args: \(method.flags.argCount)")
            do {
                print("Invoking:", name)
                _ = try acpi.invokeMethod(name: name)
            } catch {
                print("Cant invoke:", error)
            }
        }
    }


    guard let gpic = acpi.globalObjects.get("\\GPIC") else {
        return
    }
    guard let value = gpic.object as? AMLDataRefObject else {
        return
    }
    print(gpic, value)
    let invocation = try? AMLMethodInvocation(method: AMLNameString(value: "\\_PIC"),
                                              args: [AMLIntegerData(value: 1)]) // APIC
    _ = try? acpi.invokeMethod(invocation: invocation!)
    guard let newValue = gpic.object as? AMLDataRefObject else {
        return
    }
    print(newValue)

}
