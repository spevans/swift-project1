# Target host and test environment

I decided to target x86_64 64bit Longmode as when I started I wasnt sure if the
swift compiler correctly targeted 32bit. Recently I read that 32bit is fine for
non Apple hosts, the restriction is that the 32bit Objective-C runtime on Darwin
is the problem. I had thought about targeting Arm64 on something like a
Raspberry Pi but am more familiar with x86 so that made for a faster start.


QEMU, Bochs and VMware Fusion are used for testing inside VMs. A MacBook 3,1
is used for testing on actual hardware.

[QEMU](http://wiki.qemu.org/Main_Page) has a wide range of startup options and
makes it easy to test booting from both a hard drive image and a CDROM ISO. It
also provides a lot of CPU state in the logs when a fault occurs.
It was also useful for developing the EFI booting using the
[OVMF](https://wiki.ubuntu.com/UEFI/OVMF) firmware.

Although QEMU supports GDB for debugging I never really got it to work easily as
I found the breakpoints often seemed to breakpoint into QEMU rather than the
code running inside it. However the simple startup and ability to boot it either
from a hard disk image file to test BIOS booting or an ISO image file containing
an EFI image made it a good choice for EFI testing. It also allows output over
a virtual serial port to go straight to stdio which allows for having a large
console log which helps when the text mode is only 25 lines and has no
scrollback.

[Bochs](http://bochs.sourceforge.net) was the primary VM used for testing and
debugging the BIOS chain loader, switching to Long mode and Swift kernel
startup. Its builtin debugger is pretty good and made examination of the CPU
state very easy. Its ability to walk the page tables made it useful for testing
page table setup. The only downside of Bochs is that it is quite slow if left to
run the code (slower than QEMU), however this is not a major issue when testing.
The ability to step through and debug the CPU state and the code made Bochs the
best VM to use for debugging booting and startup.

The only downside of Bochs was that it cannot run the OVMF firmware so couldn't
be used for EFI debugging. This wasn't a major downside since the kernel startup
was already working and the EFI statrtup just required from printf() debugging.

VMWare provides the best level of emulation but crashes are restricted to a log
file entry with one line describing what happened to the CPU. In the case of a
triple fault which causes a CPU reset the information on the screen is lost.
However once the code was more complete and exception handlers had been added it
is a good way to check the device drivers, PCI and ACPI parsing was stable as the
hardware emulation is the most advanced of the 3 VMs.

MacBook 3,1 and MacBookPro 11,1. These were the only two test machines available
and were the reason to get EFI booting working as they do not have a PC BIOS.
The MacBook was running Linux and GRUB so just required adding the `kernel.efi`
file to GRUB and booted from there. The MacBookPro was booted off of a USB
drive which had `boot-cd.iso` written to it. These both booted without issues
except for the lack of keyboard - Macs dont support the i8042 PS/2 controller,
the builtin keyboards are USB devices and no emulation is provided by the
firmaware.

