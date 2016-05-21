fakelibc is the interface between Swift's stdlib and the rest of the system.
It exports the functions that are needed in libc/libc++ and matches the glibc
versions since the stdlib is compiled on Linux. The functions fall into three
categories:

1. Unimplemented. Print a message and halt. These are not always needed or can
be fixed up later.

2. Bare minimum implementation. Sometimes these are written to provide just
enough for stdlib to work and expect specific parameters, eg `mmap` and
`munmap` which are only used in one place.

3. Full implementations. These often wrap functions provided in other parts
of the code, eg `putchar` or `vasprintf`.


Some functions are required by other parts of the kernel, eg `malloc/free` etc
so these are implemented elsewhere.

Since a special build of Swift / stdlib is used, some functionality has been
removed eg Math functions `sin`, `cos` etc. This has been done by removing the
files from the Stdlib CMakeLists.txt. Some more files may be removed in the
future if the functionality isnt needed.


The eventual aim would be to export some header files directly to the stdlib
build process so that direct implementations can be used instead of the
Linux/glibc versions
