# Overview

swift-project1 - writing a simple bare metal kernel in Swift

A project to write a kernel in Swift with that can boot on a Mac or PC.
The eventual aim is to get a simple kernel booting up with a CLI and some
device drivers, to investigate using Swift for systems programming.


[project1 on github](https://github.com/spevans/swift-project1)


The main aspects being investigated are:


## [Target Host](target-host.md)
- 64bit x86_64, Qemu, Bochs, VMware and Macbooks


## [Development environment and compiler](development.md)
- Additions to the swift compiler: Red zone and kernel address space
- Using the compiler
- Libraries
- Swift modules


## [Standard library and runtime](kstdlib.md)
- Floating point and Maths functions
- Stdio and print()
- klibc
- Unicode and libICU (TODO)


## [Initialisation](initialisation.md)
- From boot to swift startup()
- globalinit*() (TODO)
- malloc() and free() (TODO)
- Thread Local Storage (TLS)
- Streaming SIMD Extensions (SSE)
- Reading data tables in swift


## [Working with C](working-with-c.md)
- Swift calling convention
- Pointers
- Swift function names
- Defines and constants
- Structs
- Arrays
- StaticString


## [Other Notes](other-notes.md)
- Will it build on OSX?
- Future directions


[TODO]
## Unsafe Swift
- When to use C or Assembly (interrupts, GDT, IDT)
- unsafeBitCast


## [Useful links](useful-links.md)
