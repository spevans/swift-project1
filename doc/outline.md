* Abstract


*** Target Host (x86_64) qemu/bochs macbook, EFI/bios, ELF/Macho


* Writing for PC, EFI v BIOS

* bochs, qemu etc

* why only linux, ELF v Mach-o

*** Compiler changes + Runtime


* Redzone, compiler patch, kernel negative space, change for pointer high bit
* Using the compiler

* Stuff Removed from the runtime, Float, Random numbers, Ascii/unicode (hacks for Hashable to run with collation), builtin maths, sin/cos etc, disable backtrace, libdl, compiling the runtime with the compiler changes , swift-compiler-rt  (libclang_rt.builtins-x86_64.a) for libatomic

* swift-kstdlib (Stdlib)
* Remove libswiftOnoneSupport (no -Onone) , Outputstream (less use of stdio an no need to redirect)

* klibc to support the runtime, list of symbols.txt. main areas of support:
- heap (malloc/free, no realloc) new/delete
- mem/str functions
- fprintf/fwrite (note about optimization of fprintf->fwrite) write()
- __cxa*
- pthread*
- std::__throw (just panic)
- std::__cx11:basic_string

- Implement own printf and early tty for text/frame buffer (incl serial port)

- C/asm required for start up


**** Initialisation

- From boot to swift startup()
- globalinit*()
- malloc() and free()
- Thread Local Storage (TLS)
- Streaming SIMD Extensions (SSE), floating point

***  Working With C
- Swift calling convention
- Pointers
- Swift function names
- Defines and constants
- Structs
- Arrays
- StaticString

- When C is required for Swift (structs/unions/constants)


*** Unsafe Swift
- When to use C or Assembly (interrupts, GDT, IDT) (lack of struct layout in swift)
- unsafeBitCast






* Using modules v One big module

* Functions that need to exist (malloc) before required for swift var/let init

* C Usage:
- inline for asm
- structs in C, alignment/packing
- UInt for addresses, exporting symboes from C to swift via _addr() fuctions
- Use struct in C to convert to struct in swift
- -Xcc -I<includedir>
- ULL, UL, L -> UInt64, UInt etc
- ptrToint
- @_silgen_name


* Other
- @noreturn breaks compiler
- lack of bitfields
- strideof() v sizeof()
- varargs and malloc/realloc/malloc_usable_size
- print(x,y,z) v print("\(x) \(y) \(z)"
- lack of struct packing / C structs with alignment and bit fields
- Foundation quite broken on linux
- lack of offset()
- StaticString
- non-use of realloc()
- fixed arrays V tuples
- lots of alloc() eg in throw
- Removing parts from the standard library
- throw v nil

* performance issues
- assignFrom() doesnt do memcpy()
- rdtsc() uint64_t held in 2 registers

