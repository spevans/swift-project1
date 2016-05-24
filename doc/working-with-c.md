# Working with C

[Note: This information applies to Swift3]

The [Swift calling convention](https://github.com/apple/swift/blob/master/docs/CallingConvention.rst#the-swift-calling-convention)
basically states that calls from Swift to C should follow the platform ABI and
that all the Swift compiler needs are correct headers with the C function
prototypes and other types.

Calling Swift from C is not currently guaranteed to work since Swift will
doesnt try to define an external calling convention for its functions so that
it has more flexibilty with internal Swift to Swift calls.

However currently only a few Swift functions are called from C/asm and these
either take no parameters or a few scalar values so its easy to abuse the
guarantee for the few functions need.

The easiest way to export C types and function prototypes is to have one main
header file which includes all others and then use the `-import-objc-header`
option to `swiftc` to use it.

Access to assembly is easy using static inline assembly declared in header
files eg:

```c
static inline uint64_t
getCR3()
{
        uint64_t res;
        asm volatile ("mov %%cr3, %0" : "=r" (res) : : );
        return res;
}


static inline void
setCR3(uint64_t value)
{
        asm volatile ("mov %0, %%cr3" : : "r" (value) : );
}
```

Allows the CR3 register to be get/set easily using `let addr = getCR3()` and
`setCR3(addr)` etc.


## Pointers

Pointers in Swift use the types `UnsafePointer` and `UnsafeMutablePointer` and
can be created from an address using the `init(bitPattern: UInt)?` method. It
returns an Optional which will be `nil` if the address was 0. 


Pointer values (uintptr_t) can be represented using `UInt`. A couple of macros
allow symbols to be exported from C to Swift:

```c
// Export as [symbol]_ptr of type UnsafePointer<Void>
#define EXPORTED_SYMBOL_AS_VOIDPTR(x) \
        static inline const void *x##_ptr() { extern uintptr_t x; return &x; }

// Export as [symbol]_ptr of type UnsafePointer<t>
#define EXPORTED_SYMBOL_AS_PTR(x, t) \
        static inline const t *x##_ptr() { extern t x; return &x; }

// Export as [symbol]_addr as a unitptr_t to be manipulated as a UInt
#define EXPORTED_SYMBOL_AS_UINTPTR(x) \
        static inline uintptr_t x##_addr() { extern uintptr_t x; return (uintptr_t)&x; }
```

`UnsafePointer` and `UnsafeMutablePointer` values can be converted to a
`UInt` if the address is needed using the `bitPattern` argument:

With a simple extension allowing it to be a property:


```swift
extension UnsafePointer {
    var address: UInt {
        return UInt(bitPattern: self)
    }
}

extension UnsafeMutablePointer {
    var address: UInt {
        return UInt(bitPattern: self)
    }
}
```

Although using functions to return the address of a symbol may look a bit
cumbersome, the use of inlined functions along with the linking creating a
binary with a specific start address (as in the case of a kernel etc) means
that the function gets converted to the absolute address of the symbol at link
time so there is no calling overhead or excess pollution of the name space with
lots of `*_ptr()` and `*_addr()` functions.


## Swift function names

Swift function names use name mangling to include the module name and method
signature. However when exporting to C or asm this can be inconvenient
especially if the function signature changes. `@_silgen_name` can be used to
provide an override for a function so that it has a consistent name:

```swift
func function1(a: Int) -> UInt {
    return UInt(a)
}

@_silgen_name("function2")
func function2(a: Int) -> UInt {
    return UInt(a)
}
```

converts to

```asm

Disassembly of section .text:

0000000000000000 <_TF4test9function1FSiSu>:
   0:	55                      push   %rbp
   1:	48 89 e5                mov    %rsp,%rbp
   4:	50                      push   %rax
   5:	48 83 ff 00             cmp    $0x0,%rdi
   9:	48 89 7d f8             mov    %rdi,-0x8(%rbp)
   d:	7c 0a                   jl     19 <_TF4test9function1FSiSu+0x19>
   f:	48 8b 45 f8             mov    -0x8(%rbp),%rax
  13:	48 83 c4 08             add    $0x8,%rsp
  17:	5d                      pop    %rbp
  18:	c3                      retq
  19:	0f 0b                   ud2
  1b:	0f 1f 44 00 00          nopl   0x0(%rax,%rax,1)

0000000000000020 <function2>:
  20:	55                      push   %rbp
  21:	48 89 e5                mov    %rsp,%rbp
  24:	50                      push   %rax
  25:	48 83 ff 00             cmp    $0x0,%rdi
  29:	48 89 7d f8             mov    %rdi,-0x8(%rbp)
  2d:	7c 0a                   jl     39 <function2+0x19>
  2f:	48 8b 45 f8             mov    -0x8(%rbp),%rax
  33:	48 83 c4 08             add    $0x8,%rsp
  37:	5d                      pop    %rbp
  38:	c3                      retq
  39:	0f 0b                   ud2
```

With function1's name decoding to:

```bash
$ swift-demangle _TF4test9function1FSiSu
_TF4test9function1FSiSu ---> test.function1 (Swift.Int) -> Swift.UInt
```


## Defines and constants

When using `#define` in .h files remember that C integer values actually have a
type and this needs to be taken into account when used in Swift. The values are
not simply substituted in to the code as they are in C. Consider:

```c
// test.h
#define ONE 1
#define TWO 2L
#define THREE 3LL
#define FOUR 4U
#define FIVE 5UL
#define SIX 6ULL
```

```swift
// test.swift
print("ONE\t", ONE, ONE.dynamicType)
print("TWO\t", TWO, TWO.dynamicType)
print("THREE\t", THREE, THREE.dynamicType)
print("FOUR\t", FOUR, FOUR.dynamicType)
print("FIVE\t", FIVE, FIVE.dynamicType)
print("SIX\t", SIX, SIX.dynamicType)
```

```bash
$ swiftc -import-objc-header test.h test.swift
$ ./test
ONE     1 Int32
TWO     2 Int
THREE	3 Int64
FOUR	4 UInt32
FIVE	5 UInt
SIX     6 UInt64
```


But if `test.swift` is modified:
```swift
func printInt(a: Int) {
    print(a)
}

printInt(ONE)
printInt(TWO)
printInt(THREE)

```

```bash
$ swiftc -import-objc-header test.h test.swift
test.swift:14:10: error: cannot convert value of type 'Int32' to expected argument type 'Int'
printInt(ONE)
         ^~~
test.swift:16:10: error: cannot convert value of type 'Int64' to expected argument type 'Int'
printInt(THREE)
         ^~~~~
```

`test.swift` would need to be modified as follows:
```swift
func printInt(a: Int) {
    print(a)
}

printInt(Int(ONE))
printInt(TWO)
printInt(Int(THREE))
```

```bash
$ swiftc -import-objc-header test.h test.swift
$ ./test
1
2
3
```

Which is something to remember when using constants in header files.


## Structs

A struct can be defined in a .h file and then easily used in Swift. The struct
can be addressed just be its name without `struct` eg:

```c
// test.h
struct register_set {
        unsigned long rax;
        unsigned long rbx;
        unsigned long rcx;
        unsigned long rdx;
};

static inline const struct register_set * _Nonnull
register_set_addr(struct register_set * _Nonnull set)
{
        return set;
}
```

```swift
// test.swift
var registers = register_set()

print("rax =", registers.rax)
print("rbx =", registers.rbx)
```

```bash
$ ./test
rax = 0
rbx = 0
```

This allows easy initialisation of empty structs where all of the elements are
set to zero. If data in a fixed memory table (eg ACPI tables) needs to be
parsed and only the address is known then this is also easy to accomplish using
the `pointee` property:

```swift
var registers = register_set()
registers.rax = 123
registers.rbx = 456

let addr = register_set_addr(&registers)
let r = UnsafePointer<register_set>(addr)
print("addr = ", addr, addr.dynamicType)
print("rax =", r.pointee.rax)
print("rbx =", r.pointee.rbx)
```
```bash
./test
addr =  0x000000010136c210 UnsafePointer<register_set>
rax = 123
rbx = 456
```

[Note: the use of `_Nonnull` in test.h. This makes the return type of
`register_set_addr()` be an `UnsafePointer<register_set>` instead of an
`Optional<UnsafePointer<register_set>>`. Of course you need to ensure that
the address passed to `register_set_addr()` is non-NULL]

There are two advantages of C structs over Swift struct:

1. Packed structures

If the data has a pre defined format that you dont control and the struct
requires packing using `__attribute__((packed))` then it can only be defined
in a .h file as Swift does not currently have a method of setting struct
attributes. Due to alignment padding it will add in extra space. Compare:


```c
// test.h

#include <stdint.h>
#include <stddef.h>

// Descriptor table info used for both GDT and IDT
struct dt_info {
        uint16_t limit;
        uint64_t address;
} __attribute__((packed));


static inline ptrdiff_t
offset_of(void * _Nonnull base, void * _Nonnull ptr)
{
        return ptr - base;
}
```

```swift
struct DTInfo {
    var limit: UInt16
    var address: UInt64
}

var info1 = DTInfo(limit: 31, address: 0xabcd)
let limitOffset1 = offset_of(&info1, &info1.limit)
let addrOffset1 = offset_of(&info1, &info1.address)
print("Swift: limitOffset:", limitOffset1, "addrOffset:", addrOffset1)

var info2 = dt_info(limit: 31, address: 0xabcd)
let limitOffset2 = offset_of(&info2, &info2.limit)
let addrOffset2 = offset_of(&info2, &info2.address)
print("C: limitOffset:", limitOffset2, "addrOffset:", addrOffset2)
```

[Note: due to the lack of an offsetOf() function a C function is used to
calculate the offset using some pointer arithmetic]

```bash
Swift: limitOffset: 0 addrOffset: 8
C: limitOffset: 0 addrOffset: 2
```

As we can see the Swift defined `SomeTable` aligns each field to its natural
size so the `data` field is placed on the next UInt64 boundary. C would
naturally do the same but the behaviour is overriden using the
`__attribute__((packed))` option.


2. Fixed Arrays

Swift does not currently support fixed size arrays and they must be represented
as a tuple. Although this does not stop you from defining the struct in Swift,
it can make the code quite unreadable if the array has a large number of
elements, eg:


```swift
struct Foo {
    var sz: UInt8[8]
}
```

gives the error:

```bash
$ swiftc -import-objc-header test.h test.swift
test.swift:1:18: error: array types are now written with the brackets around the element type
    var sz: UInt8[8]
                 ^~
```

However:

```c
struct foo {
        unsigned char x[8];
};
```

```swift
let y = foo()
print(y)
let x = foo(x: (1,2,3,4,5,6,7,8))
print(x)
```

Works and gives the following output, although x needs to be initialised using
a tuple:

```bash
foo(x: (0, 0, 0, 0, 0, 0, 0, 0))
foo(x: (1, 2, 3, 4, 5, 6, 7, 8))
```


## Arrays

Because fixed size arrays are seen as tuples by Swift, to treat them as
indexable arrays they need to be accessed using `UnsafeBufferPointer` and
`UnsafeMutableBufferPointer`.


```c
// test.h
#define ARRAY_SIZE  8L
extern unsigned char test_array[];
static inline void *test_array_addr() { return &test_array; };
void print_array();
```

```c
// array.c
#include <stdio.h>
#include "test.h"

unsigned char test_array[ARRAY_SIZE] = { 0, 1, 2, 3 };

void
print_array()
{
        for (int i = 0; i < ARRAY_SIZE; i++) {
                printf("%d ", test_array[i]);
        }
        puts("");
}
```

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
```

```bash
$ clang -c array.c
$ swiftc -Xlinker array.o  -import-objc-header test.h -emit-executable test.swift
$ ./test
testArray: UnsafeMutableBufferPointer(start: 0x000000010eb7d190, count: 8)
0 1 2 3 0 0 0 0
0 1 2 3 4 5 6 7
```


## StaticString

When passing strings to C especially if they are to be printed by a simple
low level text only console driver it can be useful to make use of
`StaticString`. It has a few advantages over `String` when it can be used:

1. It has an `isASCII` property which can be useful to `assert()` on. This
means that a console driver that may not understand unicode knows it wont be
getting any unicode characters.

2. The `utf8start` property returns a simple pointer to the string which can
be passed around, which is a lot simpler to use than `String`.

`StaticString` cannot be used in all circumstances but for `printf` style
functions it is often used for error or debug messages as the format string
is usually a constant string.
