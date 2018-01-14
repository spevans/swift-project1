# Other Notes


## Will it build on OSX?

Currently it will not build on OSX. Originally development was started on OSX
against the `libswiftCore.dylib` shipped with the latest Xcode including writing
a static linker to link the .dylib with the stub C functions to produce a
binary. This was working however stubs for the Objective-C functions were
required. Then Swift went open source and since the linux library is not
compiled with Objective-C support it removed a whole slew of functions and
symbols that would need to be supported.

The linux version also has the advantage that it builds a more efficient binary
since it is using proper ELF files and the standard ld linker. The static linker
just dumped the .dylib and relocates it in place but it suffered from the
fact that ZEROFILL sections have to be stored as blocks of zeros in the binary
and there is no optimisation of cstring sections etc. Also, changes in the
latest .dylib built from the Swift repo seem to add some new Mach-Oheader flags
which would  require more support. It may be possible to build against the
static stdlib on OSX but at the moment its not that interesting to do. As of now
support for building on OSX has been removed.


## Future directions

The next few things to investigate if time permits are:


### 1. Linking directly with stdlib

To reduce the number of unused stub functions needed by stdlib it might be worth
trying to compile directly with the stdlib .swift files rather than linking to
the `libSwiftcore.a` library. This should also give better chances for
optimisation using `-whole-module-optimization` although compile times would be
increased. However this would require more understanding of the Swift build
system.


### 2. Implementing on 64Bit ARM

ARM is another major architecture supported by Swift which was initially avoided
as I have more experience with x86. Getting the kernel working on a simple ARM
system such as a Raspberry Pi Zero (or a 64bit ARM board) would help avoid
hardcoding too many 64bit x86_64 assumptions into the current code. However
this would require a version of the compiler that can cross compile and QEMU
or equivalent that can emulate the specifc ARM board for initial testing.

Another advantage of porting to ARM is that the hardware should be simpler as
unlike the PC there should not be any legacy hardware to support. Another is not
requiring ACPI (although it has been partially implemented now so is not such a
problem).
