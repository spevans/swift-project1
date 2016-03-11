# Other Notes


## Testing environment

For testing I used VMware Fusion, QEMU, and Bochs

VMWare provides the best level of emulation but crashes are restricted to a log
file entry with one line describing what happened to the CPU. In the case of a
triple fault which causes a CPU reset the information on the screen is lost.
However once the code was more complete and exception handlers had been added it
was a good way to check the device drivers, PCI and ACPI parsing was stable.

[QEMU](http://wiki.qemu.org/Main_Page) is not quite as complete or fast an
emulation as VMware but does dump a lot of CPU state in the logs when a fault
occurs. It was also useful for developing the EFI booting using the
[OVMF](https://wiki.ubuntu.com/UEFI/OVMF) firmware.

Although QEMU supports GDB for debugging I never really got it to work easily as
I found the breakpoints often seemed to breakpoint into QEMU rather than the
code running inside it. However the simple startup and ability to boot it either
from a hard disk image file to test BIOS booting or an ISO image file containing
an EFI image made it a good choice for EFI testing.


[Bochs](http://bochs.sourceforge.net) was the primary VM I used for testing and
debugging the BIOS chain loader, Long mode startup and Swift kernel startup. Its
builtin debugger is pretty good and made examination of the CPU state very easy.
Its ability to walk the page tables made it useful for testing page table setup.
The only downside of Bochs is that it is quite slow if left to run the code
(slower than QEMU), however this was not a major issue when testing. The ability
to step through and debug the CPU state and the code made Bochs the best VM of
the ones I used for debugging.

The only downside of Bochs was that it cannot run the OVMF firmware so couldn't
be used for EFI debugging. This wasn't a major downside since I already had the
kernel startup working so I just had to add lots of debug statements to the EFI
startup. However, it could have been a pain if I had started with EFI booting as
it would s easy to debug the startup in QEMU as it was to do it in Bochs.

MacBook 3,1 and MacBookPro 11,1. These are the only two test machines I had and
were the reason I had to get EFI booting working as I didn't have any normal PCs
to test on. The MacBook was running Linux and GRUB so I added the `kernel.efi`
file to GRUB and booted it from there. The MacBookPro was booted off of a USB
drive which had `boot-cd.iso` written to it. These both booted without issues
except for the lack of keyboard - Macs dont support the i8042 PS/2 controller,
the builtin keyboards are USB devices.


## Future directions

The next few things I aim to investigate if I get the time are

### 1. Implementing libdispatch in Swift

Any threads and tasks done inside the kernel will need to use the same sort of
primitives as libdispatch so it will be interesting to see if this can be done
entirely in Swift (with some assembly) or whether C is still the best choice.
Also work to support SMP / multicore needs to be done from the start as trying
to bolt it on later is going to be much more work to change any systems that are
already written assuming there was only a single processor.


### 2. Porting libFoundation to EFI

Another interesting project I came up with, purely to see if it can be done
rather than being something useful, would be to port libFoundation to EFI. The
EFI booting I did for this project was the first time I had coded for EFI and in
reality it seems be basically be a 64bit MSDOS. It handles some disk I/O (loading
images), memory allocations (in multiples of a page) and keyboard input/text
output. Your EFI program runs in the supervisor mode of the CPU and the only
thing it needs to be aware of is a watchdog timer that reboots if your EFI app
hangs and this can be disabled if you need more than 5 minutes of runtime. There
are no exception handlers setup either so your code really has full control of
the machine.

Obviously you would still need the libc shim used for stdlib and most of the
functionality of libFoundation that relies on an underlying unix system would
need to be stubbed out but it would be interesting to see if the Swift repl can
be bought up under EFI


### 3. Linking directly with stdlib

To reduce the number of unused stub functions needed by stdlib it might be worth
trying to compile directly with the stdlib .swift files rather than linking to
the `ibSwiftcore.a library`. This should also give better chances for
optimisation using `-whole-module-optimization` although compile times would be
massively increased. I dont currently have enough understanding of the Swift
build system to easily work with this however.
