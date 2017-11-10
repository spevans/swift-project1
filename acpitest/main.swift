//
//  main.swift
//  acpi
//
//  Created by Simon Evans on 18/07/2016.
//  Copyright © 2016 Simon Evans. All rights reserved.
//

import Foundation
import Swift


private let files = [
    ["vmware-FACP.aml", "vmware-APIC.aml", "vmware-HPET.aml",
     "vmware-SRAT.aml", "vmware-BOOT.aml", "vmware-FACS1.aml",
     "vmware-MCFG.aml", "vmware-WAET.aml", "vmware-DSDT.aml",
     "vmware-FACS2.aml"],
    ["macbook31-APIC.aml",
     "macbook31-FACP.aml",
     "macbook31-MCFG.aml",
     "macbook31-ASF!.aml",
     "macbook31-FACS1.aml",
     "macbook31-SBST.aml",
     "macbook31-HPET.aml",
     "macbook31-FACS2.aml",
     "macbook31-ECDT.aml",
     "macbook31-DSDT.aml",
     "macbook31-SSDT1.aml",
     "macbook31-SSDT2.aml",
     "macbook31-SSDT3.aml",
     "macbook31-SSDT4.aml",
     "macbook31-SSDT5.aml",
     "macbook31-SSDT6.aml",
     "macbook31-SSDT7.aml",
     "macbook31-SSDT8.aml"
    ],
    [ "QEMU-DSDT.aml"]
]


func openOrQuit(filename: String) -> Data {
    guard let file = try? Data(contentsOf: URL(fileURLWithPath: filename)) else {
        fatalError("Cant open \(filename)")
    }
    return file
}


func main() {
    var acpis: [ACPI] = Array()
    for fileSet in 0...2 {
        print("Testing fileSet:", fileSet)
        let acpi = loadData(fileSet)
        acpis.append(acpi)
    }
    #if false
    for fileSet in 0...2 {
        print("Testing fileSet:", fileSet)
        let acpi = acpis[fileSet]
        checkObjects(acpi)
    }
    #endif
}


func loadData(_ fileSet: Int) -> ACPI {

    var testDir = Bundle.main.resourcePath!
    testDir.append("/acpitest.xctest/Contents/Resources/")

    var acpi = ACPI()
    for file in files[fileSet] {
        //print("Filename:", file)
        let data = openOrQuit(filename: testDir + "/" + file)
        data.withUnsafeBytes({
            acpi.parseEntry(rawSDTPtr: UnsafeRawPointer($0), vendor: "Foo", product: "Bar")
        })
    }
    _ = acpi.parseAMLTables()
    return acpi
}


// Mock functions and types
public func printk(_ format: String, _ arguments: CVarArg...) {
    print(String(format: format, arguments))
}


extension String {
    static func sprintf(_ format: String, _ arguments: CVarArg...) -> String {
            return String(format: format, arguments)
    }
}

func vaddrFromPaddr(_ addr: UInt) -> UInt {
    return addr
}

main()
