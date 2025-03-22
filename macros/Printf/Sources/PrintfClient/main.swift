import Printf

@freestanding(expression)
macro printf(_ item: StaticString, _ items: PrintfArg...) -> () = #externalMacro(module: "PrintfMacros", type: "PrintfMacro")

@freestanding(expression)
macro sprintf(_ item: StaticString, _ items: PrintfArg...) -> String = #externalMacro(module: "PrintfMacros", type: "PrintfMacro")

#printf("test", 1,2,3)

//let s: String = #sprintf("Using sprintf: %d", 1)
//print("s: ", s)

let s2 = #sprintf("Using sprintf: %d", 1)

//let s2 = String._sprintf("Using sprintf: %d", 1._printfArg)
print("s2: ", s2)



@freestanding(expression)
macro uhciDebug(_ item: CustomStringConvertible, _ items: CustomStringConvertible...) -> () = #externalMacro(module: "PrintfMacros", type: "DebugMacro")

#uhciDebug("test")

func _uhciDebug(_ items: String...) {
    for item in items {
        print("uhci", item)
    }
}

@freestanding(expression)
macro kprint(_ item: StaticString, _ items: CustomStringConvertible...) -> () = #externalMacro(module: "PrintfMacros", type: "KPrintStaticStringMacro")

@freestanding(expression)
macro kprint(_ item: String, _ items: CustomStringConvertible...) -> () = #externalMacro(module: "PrintfMacros", type: "KPrintStringMacro")


func _kprint(_ item: StaticString, _ items: String...) {
    print("_kprint[StaticString]", item, terminator: "")
    for x in items {
        print(", ", x, separator: "", terminator: "")
    }
    print("")
}

func _kprint(_ item: String, _ items: String...) {
    print("_kprint[String]", item, terminator: "")
    for x in items {
        print(", ", x, separator: "", terminator: "")
    }
    print("")
}

let ss: StaticString = "This is a Static String"
let s = "This is a String"

#kprint(ss)
#kprint(ss, 1,2,3)

#kprint(s)
#kprint(s, 1,2,3)
