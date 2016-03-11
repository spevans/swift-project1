# Issues with Swift

Random issues I have found with Swift


## Swift error messages

Sometimes the error messages produced by the compiler can be a bit misleading.
When writing the above example I made a small mistake with the `#define ARRAY_SIZE`
which led to this error message:

```bash
test.swift:4:51: error: cannot convert value of type 'UnsafeMutablePointer<UInt8>' to expected argument type 'UnsafeMutablePointer<_>'
let testArray = UnsafeMutableBufferPointer(start: arrayPtr, count: ARRAY_SIZE)
                                                  ^~~~~~~~
```

which makes the error look like the `arrayPtr` assignment. Changing the line to:

```swift
let testArray = UnsafeMutableBufferPointer(start: UnsafeMutablePointer(arrayPtr), count: ARRAY_SIZE)
```

gives a new error message:

```bash
test.swift:4:90: error: cannot convert value of type 'Int32' to expected argument type 'Int'
let testArray = UnsafeMutableBufferPointer(start: UnsafeMutablePointer(arrayPtr), count: ARRAY_SIZE)
                                                                                         ^~~~~~~~~~
```

Which shows the actual error, that `#define ARRAY_SIZE  8` should have been
`#define ARRAY_SIZE  8L` so that it is an `Int` instead of an `Int32`. Fixing
this now shows that the previous change is also actually an error:

```bash
test.swift:4:17: error: cannot invoke initializer for type 'UnsafeMutableBufferPointer<_>' with an argument list of type '(start: UnsafeMutablePointer<_>, count: Int)'
let testArray = UnsafeMutableBufferPointer(start: UnsafeMutablePointer(arrayPtr), count: ARRAY_SIZE)
                ^
test.swift:4:17: note: expected an argument list of type '(start: UnsafeMutablePointer<Element>, count: Int)'
let testArray = UnsafeMutableBufferPointer(start: UnsafeMutablePointer(arrayPtr), count: ARRAY_SIZE)
                ^
```

The `UnsafeMutablePointer(arrayPtr)` should have been `UnsafeMutablePointer<UInt8>(arrayPtr)`
or simply not converted at all since it was already of the correct type. Quite
often Swift error messages dont quite pinpoint the actual error in a helpful way
although quite often the issue has been the wrong numeric type `Int` instead of
`Int32` or `UInt8` etc.


## Lack of bitfields
[FIXME]
- @noreturn
- Lack of bitfields
- malloc()
- varargs (print etc)
- throw v nil
- Other minor issues



## [Issues with Swift](swift-issues.md)
- Swift error messages
- @noreturn
- Lack of bitfields
- malloc()
- varargs (print etc)
- throw v nil
- Other minor issues
