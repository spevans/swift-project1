
import Foundation


typealias PhysAddress = UInt


func dumpData(_ data: NSData) {
    var str = "0000: "
    let x = UnsafePointer<UInt8>(data.bytes)
    let buffer = UnsafeBufferPointer<UInt8>(start: x, count: data.length)

    for idx in 0..<buffer.count {
        if (idx > 0) && (idx % 32) == 0 {
            print(str)
            str = String(format: "%04X: ", idx)
        }

        let data: UInt8 = buffer[idx]
        str += String(format: " %02X", data)
    }
    if !str.isEmpty {
        print(str)
    }
}


@_silgen_name("runTests")
public func runTests() {
    let args = Process.arguments
    guard args.count > 1 else {
        errorExit("usage: \(args[0]) <table1> [table2]...")
    }

    
    for table in args.dropFirst() {
        let data = openOrQuit(table)
        //dumpData(data)
        let ptr = SDTPtr(data.bytes)
        let header = ACPI_SDT(ptr: ptr)

        /*
        guard checksum(UnsafePointer<UInt8>(ptr), size: Int(ptr.pointee.length)) == 0 else {
            printf("ACPI: Entry @ %p has bad chksum\n", ptr)
            continue
        }
        */
        switch header.signature {

        case "MCFG":
            _ = MCFG(acpiHeader: header, ptr: SDTPtr(ptr))

        case "FACP":
            _ = FACP(acpiHeader: header, ptr: UnsafePointer<acpi_facp_table>(ptr))
            print("ACPI: found FACP")

        default:
            print("ACPI: Unknown table type: \(header.signature)")
        }
    }
}

@noreturn
func errorExit(_ message: String) {
    print(message)
    exit(1)
}


func openOrQuit(_ filename: String) -> NSData {
    guard let file = NSMutableData(contentsOfFile: filename) else {
        errorExit("Cant open \(filename)")
    }
    return file
}




func vaddrFromPaddr(_ address: UInt) -> UInt {
    return address
}

func printf(_ format: String, _ arguments: CVarArg...) {
    print(String.sprintf(format, arguments))
}


struct BootParams {
    static let vendor = "Foo"
    static let product = "Bar"
}
