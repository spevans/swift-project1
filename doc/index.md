# Overview

project1 is a technical exercise to evaluate Swift as a systems language by
writing some low level code using it. It is not an operating system or
even a kernel although as an ongoing project it may develop into one.

[project1 on github](https://github.com/spevans/swift-project1)


Current status:

- Boots up (Under QEMU, Bochs or VMWare)
- Scans ACPI/SMBIOS tables
- Installs interrupts and exception/fault handlers
- Sets up paging
- Scans PCI bus
- Initialises timer and keyboard


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
- Thread Local Storage (TLS)
- Streaming SIMD Extensions (SSE)
- Reading data tables in swift


## [Working with C](working-with-c.md)
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
