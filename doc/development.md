# Development environment and compiler

Linux is used instead of OSX as the tooling for ELF files is more complete than for
Mach-O on OSX. GNU ld allows scripts to be written for linking the kernel and this
gives more control over layout of the text and data sections. Another consideration
is that the Swift libraries on OSX have been compiled to work with the
Objective-C runtime, which is not present in the Linux version so it is easy to
exclude it.

The main swift repo was forked swift into [swift-kstdlib](https://github.com/spevans/swift-kstdlib)
to allow changes to be made to the compiler and stdlib that are ready or wouldnt
be accepted back into the main master branch. These including compiling the
stdlib / libswiftCore.a to reside in the top 2 GB of address space and disabling
 the use of the red zone (see below).


### Additions to the swift compiler: Red zone and kernel address space

Because kernel code that has to run interrupt and exception handlers in Ring0
mode we need to make sure that the code from the Swift compiler and stdlib
libraries do not use the [redzone](https://en.wikipedia.org/wiki/Red_zone_(computing)).
The `-disable-red-zone` option was added (mirroring clang) which just enables the
functionality provided by the underlying LLVM.

By convention, x86_64 kernel code is compiled to use [canonical address space](https://en.wikipedia.org/wiki/X86-64#VIRTUAL-ADDRESS-SPACE) although it isnt a requirement. The
default [memory model](http://eli.thegreenplace.net/2012/01/03/understanding-the-x64-code-models)
is `small` which puts code into the first 2GB of memory using RIP-relative
addressing. To compile code to work with RIP-relative addressing in the highest
2GB (sometimes refereed to as `negative address space` as the top bit is set)
required adding an `-mcmodel` option (like clang). This allows code to be
compiled using `-mcmodel=kernel`. The only other compiler change was disabling
negative pointer values not needing to be refcounted and used as tagged pointers
for small values. In effect this needs to be swapped round since all pointers in
negative space will be valid but lower half pointers wont be valid kernel
pointers so are eligible for being used in this way. Currently there appears to
be an issue with tagged pointed since when the tagging is set the bits top bit
needs be inverted. The `swift-kstdib` needs to be updated to handle this.
[TODO: tagged pointers]


### Using the compiler

When compiling you can compile related source files into a module and then link
the modules together or compile all source files at once and produce one `.o`
file. Obviously with lots of files it will eventually become slow recompiling
them every time but currently its useful since the `-whole-module-optimization`
flag can be used.

Compilation command looks something like:

```
swiftc -gnone -Xfrontend -disable-red-zone -Xcc -mno-red-zone -Xfrontend -mcode-model=kernel -Xcc -mcmodel=kernel -parse-as-library -import-objc-header <header.h> -warnings-as-errors -Xcc -Wall -Xcc -Wextra -Xcc -std=gnu11 -Xfrontend -warn-long-function-bodies=60000 -DKERNEL -Osize -Xcc -O3 -whole-module-optimization -module-name SwiftKernel -emit-object -o  <output.o> <file1.swift> <file2.swift>
```
```

`-gnone` disables debug information which probably isn't very useful until you
have some sort of debugger support

`-Osize` is for optimising for size, the other options being `-O` which is
default optimisations, `-Onone` which turns it off but produces a larger amount
of code and `-Ounchecked` which is `-O` but without
extra checks after certain operations. `-O` produces good code but does tend to
inline everything into one big function which can make it hard to workout what
went wrong when an exception handler simply gives the instruction pointer as the
source of an error. the swift-kstdlib and runtime removes most of the code
support needed for `-Onone` (`libswiftOnoneSupport` does not get built) so this
cant actually be used.

`-Xfrontend -disable-red-zone` ensures that code generated from the swiftc
doesn't generate red zone code.

`-Xcc -mno-red-zone` tells the `clang` compiler not to use the red zone on any
files it compiles. `clang` is used if there is any code in the header file you
use which will probably be the case as will be shown.

`-Xcc -mno-mmx -Xcc -mno-sse -Xcc -mno-sse2` uses clang options to tell swiftc
not to use MMX/SSE/SSE2.

`-parse-as-library` means that the code is not a script.

`-import-objc-header` allows a .h header file to be imported that allows access
to C function and type definitions.

`-module-name` is required although is only used in fully qualifying the method
and function names. Actual module files are not created with this option.


### Libraries

Now that a `.o` ELF file has been produced it needs to be linked to a final
executable. Swift requires that its stdlib is linked in as this provides some
basic functions that are needed by Swift at runtime.

The 2 libraries that need to be linked in are
```
lib/swift_static/linux/libswiftCore.a
lib/swift_static/linux/libclang_rt.builtins-x86_64.a
```
And also `lib/swift/linux/x86_64/swiftrt.o` which is used for section start/end
markers for the `.swift2_protocol_conformances` and `.swift2_type_metadata`
sections.


### Swift modules

Swift modules where originally used when building the kernel, making each
subdirectory (kernel/devices, kernel/init, kernel/traps etc) into its own
module and then all linked afterwards. However there were two problems with
this:

1. Circular dependencies between modules. If module A needed to use a function
in module B and vice versa they couldn't as module A would require module B to
built first so that it could then be imported however this would fail as B also
needed A to be built.

2. `-whole-module-optimization` cannot be used to active the best code output.

However the downside of not using modules is that build time is increased as
everything is compiled together. For a small project this is not such an issue
but for a large kernel it could be.

This decision may be revisisted in the future as the situation may have changed
since swift-2 when using modules was first attempted.
The main problem was that the core was split up into modules when it should have
just been one module. If there are eventually multiple device drivers and other
parts that dont have interdependencies on each other then it should be possible
to do it this way.
Swift modules compile to 2 files, the object file and a binary header file that
is used by the `import` statement so it should not be a problem in the future to
take the ELF object file and load it dynamically into the kernel in some way.
