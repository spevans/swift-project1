# Development environment and compiler

Use Linux instead of OSX as the tooling for ELF files is more complete than for
Mach-O on OSX. Also Swift libraries on OSX have have extra code for Objective-C
integration which just causes more issues.

I currently use the swift-2.2-stable branch to reduce the amount of compiler
issues caused by tracking the latest and greatest however there is one issue
stopping the use of the Swift releases that can be downloaded from swift.org.

## Red zone

Because we are writing kernel code that has to run interrupt and exception
handlers in kernel mode we need to make sure that the Swift compiler and
libraries do not use the [redzone](https://en.wikipedia.org/wiki/Red_zone_(computing)).
Currently there isn't a `-mno-red-zone` option for swiftc but there is for clang
so swift and stdlib need to be recompiled to disable its use.

The following two patches are a quick and dirty way of disabling red zone in the
llvm that gets built and also for any clang subprocesses that get called. At
some point in the future Swift will hopefully have support for a `-mno-red-zone`
compiler option.


Patch for llvm

```
diff --git a/lib/Target/X86/X86FrameLowering.cpp b/lib/Target/X86/X86FrameLowering.cpp
index 5bf2fbf..aac0042 100644
--- a/lib/Target/X86/X86FrameLowering.cpp
+++ b/lib/Target/X86/X86FrameLowering.cpp
@@ -693,7 +693,7 @@ void X86FrameLowering::emitPrologue(MachineFunction &MF,
   // pointer, calls, or dynamic alloca then we do not need to adjust the
   // stack pointer (we fit in the Red Zone). We also check that we don't
   // push and pop from the stack.
-  if (Is64Bit && !Fn->hasFnAttribute(Attribute::NoRedZone) &&
+  if (0 && Is64Bit && !Fn->hasFnAttribute(Attribute::NoRedZone) &&
       !TRI->needsStackRealignment(MF) &&
       !MFI->hasVarSizedObjects() && // No dynamic alloca.
       !MFI->adjustsStack() &&       // No calls.
```

Patch for swift

```
diff --git a/CMakeLists.txt b/CMakeLists.txt
index 4435e1d..bae0179 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -176,7 +176,7 @@ option(SWIFT_RUNTIME_CLOBBER_FREED_OBJECTS
 # User-configurable experimental options.  Do not use in production builds.
 #

-set(SWIFT_EXPERIMENTAL_EXTRA_FLAGS "" CACHE STRING
set(SWIFT_EXPERIMENTAL_EXTRA_FLAGS "-Xcc;-mno-red-zone" CACHE STRING
     "Extra flags to pass when compiling swift files.  Use this option *only* for one-off experiments")

 set(SWIFT_EXPERIMENTAL_EXTRA_REGEXP_FLAGS "" CACHE STRING
diff --git a/stdlib/public/CMakeLists.txt b/stdlib/public/CMakeLists.txt
index 29aae6e..b19accf 100644
--- a/stdlib/public/CMakeLists.txt
+++ b/stdlib/public/CMakeLists.txt
@@ -1,6 +1,7 @@
 # C++ code in the runtime and standard library should generally avoid
 # introducing static constructors or destructors.
 set(SWIFT_CORE_CXX_FLAGS)
+list(APPEND SWIFT_CORE_CXX_FLAGS "-mno-red-zone")

 check_cxx_compiler_flag("-Werror -Wglobal-constructors" CXX_SUPPORTS_GLOBAL_CONSTRUCTORS_WARNING)
 if(CXX_SUPPORTS_GLOBAL_CONSTRUCTORS_WARNING)
```

Run:
```
mkdir -p ~/swift/build
SWIFT_BUILD_ROOT=~/swift/build ./utils/build-script --preset=buildbot_linux lldb=0 test-installable-package=0 install_destdir=~ installable_package=~/swift/swift-`date '+%F-%X'`.tar.gz jobs=2 2>&1|tee buildbot.log
```

This will build and install swift in `~/usr/bin`. Adjust `jobs=2` as required.

Note that Foundation is not built here as it cant be used in any code because it
requires a lot of operating system and libc support.

I also install a 2.2 snapshot from https://swift.org/download/#linux for Swift
programs running on the local linux host since this includes Foundation.


## Using the compiler

When compiling you can compile related source files into a module and then link
the modules together or compile all source files at once and produce one .o file.
Obviously with lots of files it will eventually become slow recompiling them
every time but currently its useful since the `-whole-module-optimization` flag
can be used.

Compilation command looks something like:

```
swiftc -gnone -O -Xcc -mno-red-zone -parse-as-library -import-objc-header <file.h> -whole-module-optimization -module-name MyModule -emit-object -o <output.o> <file1.swift> <file2.swift>
```

`-gnone` disables debug information which probably isn't very useful until you
have some sort of debugger support

`-O` is for optimisation, the other options being `-Onone` which turns it off
but produces a larger amount of code and `-Ounchecked` which is `-O` but without
extra checks after certain operations. `-O` produces good code but does tend to
inline everything into one big function which can make it hard to workout what
went wrong when an exception handler simply gives the instruction pointer as the
source of an error.

`-Xcc -mno-red-zone` tells the `clang` compiler not to use the red zone on any
files it compiles. `clang` is used if there is any code in the header file you
use which will probably be the case as will be shown.

`-parse-as-library` means that the code is not a script.

`-import-objc-header`
allows a .h header file to be imported that allows access to C function and type
definitions.

`-module-name` is required although is only used in fully qualifying the method
and function names. However actual module files are not created with this option.

## Libraries

Now that a .o ELF file has been produced it needs to be linked to a final
executable. Swift requires that its stdlib is linked in as this provides some
qbasic functions that are needed by Swift at runtime.

The library name is `libswiftCore.a` and should be in `lib/swift_static/linux`
under the install directory.

`libswiftCore.a` relies on libc, libcpp and a few other system libraries
however they wont be available so the missing functions need to be emulated. The
full list of symbols that need to be implemented is [here](https://github.com/spevans/swift-project1/blob/master/doc/symbols.txt)

## C & assembly required to get binary starting up

The libcpp functions consist of the usual `new()`, `delete()` and a few
`std::_throw_*` functions however the bulk of them are `std::string*`. Note
that not every function needs to be implemented but require at least a
function declaration. An example libcpp, written in C to simplify building
can be seen [here](https://github.com/spevans/swift-project1/blob/master/fakelib/linux_libcpp.c).

The libc functions include the  usual `malloc`, `free` and `malloc_usable_size`
(although there is no need for `realloc`), `mem*`, `str*` and various versions
of `putchar`.

These all need to be written, example versions can be seen [here](https://github.com/spevans/swift-project1/tree/master/fakelib). These functions will form the C
interface between your Swift code and the machine it is running on.

Note that using debug versions of swift and libswiftCore.a will increase the
number of undefined symbols because some of the  C++ string functions are not
inlined anymore and so must be implemented. Currently I have found no benefit to
using the debug versions since they also increase the size of the binary and in
addition require more stack space.

A list of library calls made for the following simple 'Hello World' can be seen
[here](https://github.com/spevans/swift-project1/blob/master/doc/startup_calls.txt)
```swift
@_silgen_name("startup")
public func startup() {
    print("Hello World!")
}
```


## Stdlib

It would be possible to alter the stdlib code to remove a lot of the functions
that ar erequired for linking but not actually needed by the kernel (eg the maths
functions) however I decided against doing any alterations to stdlib as I didnt
want to have to maintain a patch against it. Given the number of changes made to
stdlib since Swift went open source, I also didnt want to keep maintaining an
extra patch that could just diverge too much. Adding stub functions for the
unused parts wasnt a big problem.


## Swift modules

I originally use Swift modules when building the project, making each
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


## Why is there so much C in the code?

The fakelib directory contains all the symbols required to satisfy the
linker even though a lot of them are left unimplemented and simply print
a message and then halt. Most of the functions do the bare minimum to
satisfy the Swift startup or pretend to (eg the pthread functions dont
actually do any locking or unlocking etc).

When a Swift function is first called there is some global
initialisation performed in the libraries (wrapped in a `pthread_once()/
dispatch_once()`). This calls `malloc()/free()` and some C++ string
functions so all of the C code is required to perform this basic
initialisation. The TTY driver in C is requred for any debugging / oops
messages until Swift is initialised and can take over the display.

Originally I had planned to add more functionality in Swift but it took
longer than I expected to get this far although I hope to add more
memory management and some simple device drivers to see how easy it is
to do in Swift.


## Will it build on OSX?

Currently it will not build on OSX. I originally started developing on OSX
against the libswiftCore.dylib shipped with the latest Xcode including writing
a static linker to link the .dylib with the stub C functions to produce a
binary. This was working however I got stuck doing the stubs for the Obj-C
functions. Then Swift went open source and since the linux libary is not
compiled with Obj-C support it removed a whole slew of functions and symbols
that would need to be supported.

The linux version also has the advantage that it builds a more efficient binary
since it is using proper ELF files and the standard ld linker. The static linker
I wrote just dumps the .dylib and relocates it in place but it suffers from the
fact that ZEROFILL sections have to be stored as blocks of zeros in the binary
and there is no optimisation of cstring sections etc. Also, changes in the
latest .dylib built from the Swift repo seem to add some new header flags which
I have yet to support. It may be possible to build against the static stdlib on
OSX but at the moment its not that interesting for me to do. As of now the OSX
fakelib support has been removed.
