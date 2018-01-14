# Initialisation


## From boot to Swift startup()

- BIOS

Everything from the boot sector until startup() in [startup.swift](https://github.com/spevans/swift-project1/blob/master/kernel/init/startup.swift)
is written in x86 assembly.

Boot sectors are always written in ASM due to the small size (512 bytes) and
the need to put certain bytes in certain offsets. It may be possible to write
one in C but it would be composed almost entirely of inline assembly due to
segment and stack setup, and BIOS calls.

The bootsector loads the secondary loader which is responsible for:

1. Checking CPU is 64bit
2. Getting the E820 memory map
3. Opening the A20 address gate
4. Disabling all interrupts including NMI
5. Loading the kernel into memory above 1MB
6. Setting up the page tables
7. Entering Long mode (64 bit) and jumping to `main` in [main.asm](https://github.com/spevans/swift-project1/blob/master/kernel/init/main.asm)

Again this was all done in assembly because it has code to switch CPU modes
(switching between real and protected) to load the kernel into high memory and
also to enter 64bit. It might have been possible to do some parts in C but not
Swift due to the size of binaries that are created when stdlib is linked into a
binary. The code also has to be built for different cpu modes (16, 32 and 64)
which makes it hard to do for anything other than assembly.

The second stage loader was kept small at under 1.5K so that bootsector + loader
was never more than 2K. This simplified issues with ISO CD-ROM booting.

The conclusion is that writing the BIOS boot sequence in Swift would basically
be very difficult and if it was attempted would be largely a collection of
assembly routines. Swift's safety would offer very little advantage here.


- EFI

EFI booting was added so that I could test on my Macbook (3,1 Late 2007). The
EFI code is much simplified because the firmware already puts the cpu into 64bit
mode and loads the kernel (embedded in a .efi file) into memory. The EFI code
only needs to do the following:

1. Allocate memory for the kernel and BSS and copy the kernel to the new memory
2. Setup page tables for kernel
3. Set a graphics mode and determine the frame buffer properties
4. Obtain the memory map of the host and call ExitBootServices() exiting the EFI
firmware
5. Pivot to the new page tables and call `main`

The EFI loader code is written in C using some helper functions in [efi_entry.asm](https://github.com/spevans/swift-project1/blob/master/boot/efi_entry.asm).
It would be possible to write the EFI code in Swift using the same helper
functions that the C version uses but it would also need to be linked to the
extra undefined functions that the kernel is linked to. This would have the
disadvantage of making the .efi file very large.


## Thread Local Storage (TLS)

To support the use of `swift_once` via `pthread_once` in [linux_libc.c](https://github.com/spevans/swift-project1/blob/master/fakelib/linux_libc.c#L98)
thread local storage [TLS](https://uclibc.org/docs/tls.pdf) needs to be taken
into account. There are 2 methods for implementing it in ELF: by implementing
`__tls_get_addr()` or using the `%fs` segment register.

I opted to implement the `%fs` segment register which involved adding an extra
entry to the GDT. Its a bit of a hacked up solution as it just allocates a small
size for the region. In the future I may change it to the other method by
implementing  `__tls_get_addr()`.

One problem caused by using the `%fs` is that the addressing is RIP relative and
so addresses must be within 32bit (4GB) space. This causes a limitation on the
address the kernel can be linked to. Thats why in the [linker script](https://github.com/spevans/swift-project1/blob/master/linker.script#L10) the link address is
0x40100000 and not a more conventional 0x8000000000000000 (8EB) that is often
used where the kernel occupies the 'top half' of the address space (https://en.wikipedia.org/wiki/X86-64#VIRTUAL-ADDRESS-SPACE)


## Streaming SIMD Extensions (SSE)

Swift uses the SSE registers (xmm0 - xmm15) in stdlib which means that SSE
instructions need to be enabled in CR0/CR4 registers, this is done in [main.asm](https://github.com/spevans/swift-project1/blob/master/kernel/init/main.asm#L89).
Normally kernel code would not use these extra registers as it requires more
registers to be saved in a context switch however it was easier to support them
then to work out how to build the Swift compiler and stdlib to exclude their
use.

~~Since context switching is not currently implemented anyway it was easier to
just enable SSE and use the extra registers for now.~~

Since I removed floating point from [stdlib](development.md#stdlib) SSE is no
longer enabled in the kernel and the SSE register are not used or saved in
interrupt handlers.


## globalinit*()

[TODO]


## malloc() and free()

[TODO]


## Reading data tables in Swift

One of the main parts of the kernel startup was reading various system tables
(ACPI, SMBIOS etc). These can be represented by a struct and I came up with
three different ways of reading the data. In all cases the only inital parameter
I had was the memory address of the table.


#### 1. Directly reading into a Swift struct

The pointer can be cast to the struct and then accessed or copied using the
`.pointee` property


```
// test.h
#include <stdint.h>

static inline uintptr_t
ptr_to_uint(const void *ptr)
{
        return (uintptr_t)ptr;
}
```


```swift
// test.swift
struct Test {
    let data1: UInt64
    let data2: UInt8
}


var s = Test(data1: 1234, data2: 123)
let ptr = UnsafePointer<Test>(bitPattern: ptr_to_uint(&s))!
print("data1:", ptr.pointee.data1, "data2", ptr.pointee.data2)
let data = ptr.pointee
print("data1:", data.data1, "data2", data.data2)
```

```bash
$ swiftc -import-objc-header test.h -emit-executable test.swift
$ ./test
data1: 1234 data2 123
data1: 1234 data2 123
```

Whilst simple to use it has some drawbacks. The first is that because of the
lack of `__attribute__((packed))` a Swift struct cannot always accurately map to
a system structure [see working with C structs](working-with-c.md#structs).

Secondly, some data types most notably strings do not always have a good mapping
between a system table and Swift. The data may simply be a fixed length string
(eg 6 or 8 bytes) and may or may not be zero terminated. This can often only
be mapped to a tuple since Swift doesn't support fixed length arrays.

Finally, just pointing a struct to a memory address and directly reading values
skips any validation of the underlying data. Also, using `ptr_to_uint` to find
the address of a struct is a hack and not guaranteed to work. It is mostly
exploiting how Swift currently treats structs and could break in the future.


#### 2. Use a C struct and a Swift struct

This method uses a C struct to accurately represent the memory layout and a
Swift struct to represent a more useful view including using String etc for any
parsed strings. As struct members are copied from the C version to the Swift one
they can go through any required validation. [SMBios:init()](https://github.com/spevans/swift-project1/blob/master/kernel/init/smbios.swift#L73)
is an example of this converting a C `struct smbios_header` to a Swift
`struct SMBIOS`.


#### 3. Read individual elements from a buffer

An earlier method I had come up with was [MemoryBufferReader](https://github.com/spevans/swift-project1/blob/master/kernel/klib/MemoryBufferReader.swift).
This was used for reading from mmapped files or any `UnsafeBufferPointer`.
Individual items of different types can be sequentially read and it allows for
sub-buffers to be created and read. An example of its use can be seen [here](https://github.com/spevans/swift-project1/blob/master/kernel/init/bootparams.swift#L514).

Im still undecided about the best method for reading raw tables, however method
2 is currently my preferred one.
