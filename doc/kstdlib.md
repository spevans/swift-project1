# Standard Library and Runtime

The swift runtime and standard library (stdlib) are built alongside the compiler
and form the `libswiftCore.a` library. Getting the C++ runtime to run directly
on the hardware without an underlying kernel required writing a small kernel
libc (klibc) to replace the functionality provided `libc` and `libc++`. The
relationship between the various libraries and the OS/hardware can be seen in
the following diagram:

![library-layers](swift-kernel-layers.001.png)


Some parts of the stdlib were removed since the functionality was not required
or have no relevance. This meant that about 80 functions were left that had to
be written although some are not used and are just declared via a simple
`UNIMPLMENTED` stub.  The full list of symbols that need to be implemented is
[here](symbols.txt).
This list changes over time as changes are made to the runtime and standard
library.

### Floating point and Maths functions

The x86_64 ABI requires that functions taking or returning `Float` or `Double`
values use the registers `xmm0` - `xmm7`, however when compiling the kernel the
MMX/SSE register usage is disabled. This reduced the number the number of
registers that need to be saved on the stack when an interrupt is serviced.

Because Swift defines `Float` and `Double` as regular value types in stdlib
rather than being built into the compiler its easy to remove them by simply
commenting out of the respective files. This also means that other functions
and types that use `Float` or `Double`must also be disabled. This includes
random numbers and the `Codable` protocol.


### Stdio and print()

`print` and `getline` use the libc stdio functions inclusing filelocking so
these the `OutputTextStream` and `getline` were removed. This reduced the
required functions to just `fprintf()` and `fwrite()` which are used by the
C++ runtime for errors and messageing. `fwrite()` isnt actually used directly
however clang will apply an optimisation to `fprintf()` if it is used to only
write out a string with no format specifiers, or the format string is a simple
`%s` ie, `fprintf(stderr, "a string\n")` is translated to
`fwrite("a string\n", 9, 1, stderr)` as `fprintf()` has to check each character
in the format string.

The normal `print()` function that writes directly to stdout was removed,
leaving only the version that takes an output stream. This breaks the
`libswiftOnoneSupport` library which is why the `-Onone` compiler option can
not be used. Comp


### klibc

To support the runtime, I wrote a minimal klibc to link to. It covers the
following functionality:

- Heap functions: `malloc()`, `free()`, `malloc_usable_size()`, and the C++
  operators `new()` and `delete()`. Note that `realloc()` isnt needed as it
  isnt used by Swift's heap code or the libc++ string library.

- The usual memory and string functions: `memchr()` `memcmp()` `memcpy()`
  `memmove()` `memset()` `strchr()` `strcmp()` `strdup()` `strlen()`
  `strncmp()`.

- libuiuc unicode functions

- pthread functions and std::once_call functions

- cxx11 string functions

- __cxa_atexit() __cxa_guard_acquire() __cxa_guard_release()

- std::__throw* / abort() - which just map to a kernel oops

- fprinf() / snprintf() / vasprintf() - these map to the kprintf() functionality

- Extra support functionality for text/framebuffer TTY output and serial port
  output.

- Support for ELF init_array and iplt relocation array.


Note that using debug versions of swift and libswiftCore.a will increase the
number of undefined symbols because some of the C++ string functions are not
inlined anymore and so must be implemented. Currently I have found no benefit to
using the debug versions since they also increase the size of the binary and in
addition require more stack space.


## Unicode and libICU
[TODO]
