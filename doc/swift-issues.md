# Issues with Swift

Random issues I have found with Swift


## Swift error messages

Sometimes the error messages produced by the compiler can be a bit misleading.
When writing the above example I made a small mistake with the `#define ARRAY_SIZE`
which led to this error message:

```swift
// test.swift
let arrayPtr = UnsafeMutablePointer<UInt8>(test_array_addr())
let testArray = UnsafeMutableBufferPointer(start: arrayPtr, count: ARRAY_SIZE)
print("testArray:", testArray)
testArray.forEach({ print("\($0) ", terminator: "") })
print("")

for x in 4..<ARRAY_SIZE {
    testArray[x] = UInt8(x)
}
print_array()



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


Unoptimized memcpy in public UnsafePointer.swift.gyb
func assign(from source: UnsafePointer<Pointee>, count: Int) {
(used for frame buffer scrolling)

Lazy globals that initialise to 0 (or a siumple type) not just being
allocated in the bss/rodata and still needing swift_once()

Cant do array of Enum values
Cant do index of C array via variables eg, idt.0 ok, x= 0. idt.x or idt[x] not ok
Need to alias swift funcs with a fixed name
C access to public static class methods



DONT use C var args as it allocs memory for the output

Optimisations required for interrupt handlers since var's
call global_init / swift_once otherwise. But optomisation
is borken with VMWare!


Accessing raw pointer values is not allowed so need to
store them somewhere. 3. options:

1. Just keep using C
2.


Using thread local via %fs restricts data access to first 4G
linear

Initialising anoyumouse uniones (see cpuid) not needed v
normal structs


ULL => UInt64
UL => UInt


need to override _swift_stdlib_putchar_unlocked since it accesses the
STDIO buffer directly (putchar_unlocked is a macro not a libc func)


forward declarations needed in scripts? (eg foverride.swift calling parseArgs)

putting stop() (ie @noreturn) in random places can cause the compile to fail


strideof() v sizeof() when reading packed/unpacked structs in memory

use -Xcc -I<includeidr> to access own include dir

bitfields are annoying

print(a,b,c) v print("\(a) \(b) \(c)") and malloc

for x: UInt8 in 0...UInt8.max


- ELF requires calls to be made with aligned stack so it always add extra * to the rsp somewhere, as does EFI
- Mac is UEFI firmware with EFI (UGA) graphics


- If I was to write anoteher low level swift programs I would do it directly as a UEIF app and not as an booting kernel


- RIP in data or bss space could be stack overflow / underflow
