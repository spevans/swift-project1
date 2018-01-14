
let constant1 = { return  0x123 } ()

struct MyMagicNumbers {
    static let constant1 = 0x123
}

public func func1() -> Int {
    return 0x123
}


public func func1a() -> Int {
    return MyMagicNumbers.constant1
}



public func func2() -> Int {
    return constant1
}


private enum MagicNumbers: Int {
    case constant1 = 0x123
}


public func func3() -> Int {
    return MagicNumbers.constant1.rawValue
}


public func func4() -> Int {
    let constant = 0x123

    return constant
}

