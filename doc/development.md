# Development environment and compiler

Use Linux instead of OSX as the tooling for ELF files is more complete than for
Mach-O on OSX. Also Swift libraries on OSX have have extra code for the
Objective-C runtime, which is not present in the Linux version so it is easy to
exclude it.

~~I currently use the swift-2.2-stable branch to reduce the amount of compiler
issues caused by tracking the latest and greatest however there is one issue
stopping the use of the Swift releases that can be downloaded from swift.org.~~

Ive moved to tracking the master branch, currently on Swift-4.0, since it is
easier to just keep upto date rather than jumping from verion to version after
every major release.

Ive forked swift into [swift-kstdlib](https://github.com/spevans/swift-kstdlib)
as I needed to make some changes to the compiler and stdlib.


### Additions to the swift compiler: Red zone and kernel address space

Because we are writing kernel code that has to run interrupt and exception
handlers in Ring0 mode we need to make sure that the code from the Swift
compiler and Stdlib libraries do not use the [redzone](https://en.wikipedia.org/wiki/Red_zone_(computing)). I added a `-disable-red-zone` option (mirroring clang) which just
enables the functionality provided by the underlying LLVM.

By convention, x86_64 kernel code is compiled to use [canonical address space](https://en.wikipedia.org/wiki/X86-64#VIRTUAL-ADDRESS-SPACE) although it isnt a requirement. The
default [memory model](http://eli.thegreenplace.net/2012/01/03/understanding-the-x64-code-models)
is `small` which puts code into the first 2GB of memory using RIP-relative
addressing. To compile code to work with RIP-relative addressing in the highest
2GB (sometimes refereed to as `negative address space' as the top bit is set)
would require an `-mcmodel=kernel` option (like clang). Currently swift doesnt
have an `-mcmodel` option so I just changed the default model in [IRGen.cpp](https://github.com/spevans/swift-kstdlib/blob/swift-kernel-20170515/lib/IRGen/IRGen.cpp#L502) from
`Default` to `Kernel`. The only other compiler change was disabling negative
pointer values not needing to be refcounted and used as tagged pointers for
small values. In effect this needs to be swapped round since all pointers in
negative space will be valid but lower half pointers wont be valid kernel
pointers so are eligible for being used in this way.


### Using the compiler

When compiling you can compile related source files into a module and then link
the modules together or compile all source files at once and produce one `.o`
file. Obviously with lots of files it will eventually become slow recompiling
them every time but currently its useful since the `-whole-module-optimization`
flag can be used.

Compilation command looks something like:

```
swift -frontend -gnone -O -Xfrontend -disable-red-zone -Xcc -mno-red-zone -Xcc -mno-mmx -Xcc -mno-sse -Xcc -mno-sse2 -parse-as-library -import-objc-header <file.h> -whole-module-optimization -module-name MyModule -emit-object -o <output.o> <file1.swift> <file2.swift>
```

`-gnone` disables debug information which probably isn't very useful until you
have some sort of debugger support

`-O` is for optimisation, the other options being `-Onone` which turns it off
but produces a larger amount of code and `-Ounchecked` which is `-O` but without
extra checks after certain operations. `-O` produces good code but does tend to
inline everything into one big function which can make it hard to workout what
went wrong when an exception handler simply gives the instruction pointer as the
source of an error. the swift-kstdlib and runtime removes most of the code
supoprt needed for `-Onone` (`libswiftOnoneSupport` does not get built) so this
cant actually be used.

`-Xfrontend -disable-red-zone` ensures that code generated from the swiftc
doesn't generate red zone code.

`-Xcc -mno-red-zone` tells the `clang` compiler not to use the red zone on any
files it compiles. `clang` is used if there is any code in the header file you
use which will probably be the case as will be shown.

`-Xcc -mno-mmx -Xcc -mno-sse -Xcc -mno-sse2` uses clang options to tell swiftc
not to use MMX/SSE/SSE2

`-parse-as-library` means that the code is not a script.

`-import-objc-header`
allows a .h header file to be imported that allows access to C function and type
definitions.

`-module-name` is required although is only used in fully qualifying the method
and function names. However actual module files are not created with this option.


### Libraries

Now that a `.o` ELF file has been produced it needs to be linked to a final
executable. Swift requires that its stdlib is linked in as this provides some
basic functions that are needed by Swift at runtime.

The 2 libraries that need to be linked in are
```
libswiftCore.a
libclang_rt.builtins-x86_64.a
```

and should be in `lib/swift_static/linux` under the install directory.


### Swift modules

I originally used Swift modules when building the project, making each
subdirectory (kernel/devices, kernel/init, kernel/traps etc) into their own
module and then linked them all afterwards. However there were two problems with
this:

1. Circular dependencies between modules. If module A needed to use a function
in module B and vice versa they couldn't as module A would require module B to
built first so that it could then be imported however this would fail as B also
needed A to be built.

2. `-whole-module-optimization` cannot be used to active the best code output.

However the downside of not using modules is that build time is increased as
everything is compiled together. For a small project this is not such an issue
but for a large kernel it could be.

I may revisit this decision later I think the main problem was that I split the
core up into modules when they should have just been one in the first place.
If there are eventually multiple device drivers and other parts that dont have
interdependencies on each other then it should be possible to do it this way.
Swift modules compile to 2 files, the object file and a binary header file that
is used by the `import` statement so it should not be a problem in the future to
take the ELF object file and load it dynamically into the kernel in some way.
