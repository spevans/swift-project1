# Overview

project1 - writing a simple bare metal kernel in Swift

A project to write a kernel in Swift with that can boot on a Mac or PC.
The main aim is to get a simple kernel booting up with a CLI with full
concurrency/thread support on multiple cores.

[project1 on github](https://github.com/spevans/swift-project1)


Current status:

- Boots up (Under QEMU, Bochs or VMWare)
- Scans ACPI/SMBIOS tables
- Installs interrupts and exception/fault handlers
- Sets up paging
- Scans PCI bus
- Initialises timer and keyboard
- Initialises PIC, PIT and PS/2 keyboard controller
- Runs two simple tasks, one printing 'A' and the other printing 'B' in a loop
  with a simple stack context switch

The next step is to get multi processor support working


The main aspects investigated were:

## [Development environment and compiler](development.md)
- Red zone
- Using the compiler
- Libraries
- C & assembly required to get binary starting up
- Stdlib
- Swift modules
- Why is there so much C in the code?
- Will it build on OSX?


## [Initialisation](initialisation.md)
- From boot to swift startup()
- globalinit*()
- malloc() and free()
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
- Testing environment (boches, qemu etc)
- What to do differently next time
- Future directions


## [Useful links](useful-links.md)
