#if !TEST
public func fatalError(
  _ message: @autoclosure () -> String,
  file: StaticString = #file, line: UInt = #line
) -> Never {
    let messageStr = message()
    #kprintf("%s:%u:%s\n", file, line, messageStr)
    stop()
}
#endif

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
