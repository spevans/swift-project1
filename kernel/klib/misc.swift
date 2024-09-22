public func fatalError(
  _ message: @autoclosure () -> String,
  file: StaticString = #file, line: UInt = #line
) -> Never {
    print(file, terminator: ":")
    print(line, terminator: ": ")
//    print(prefix, terminator: "")
    let messageStr = message()
    if messageStr.count > 0 {
        print(": ", terminator: "")
    }
    print(messageStr)
    stop()
}

extension String {
    @inlinable
    public init<Subject: CustomStringConvertible>(describing instance: Subject) {
        self = instance.description
    }
}

#if false
extension Bool: @retroactive CustomStringConvertible {
  /// A textual representation of the Boolean value.
  @inlinable
  public var description: String {
    return self ? "true" : "false"
  }
}
#endif
