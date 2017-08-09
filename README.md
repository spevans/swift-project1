# project1 - Implementing a minimal bare metal kernel in Swift

## What is it?

A project to write a kernel in Swift that can boot on a Mac or PC.
The main aim is to get a simple kernel booting up with a CLI with full
concurrency/thread support.

There is a short writeup about it [here](http://si.org/projects/project1).

## Current status

- Boots up under QEMU, Bochs and VMWare. Also boots on Macbook 3,1 (13inch Late 2007)
- Installs interrupts and exception/fault handlers
- Sets up paging
- Scans ACPI/SMBIOS tables
- Parses ACPI tables
- Initialises the APIC and IO/APIC (or PIC)
- Scans PCI bus (MMIO or PIO) to show vendor/device IDs
- Initialises the PIT and PS/2 keyboard controller
- Sets up an APIC and PIT timers and shows a test message with interrupt counts.
- Runs a simple task reading keyboard scan codes from a circular buffer and
  translates them to ASCII codes to show on the screen. The Macbook doesn't
  have an i8042 PS/2 keyboard controller so the keyboard will not work.

Currently working on an ACPI AML parser and bytecode interpreter to allow more
devices to be setup correctly including the Realtime Clock and PCI interrupts.

The next major tasks are:

- ACPI parser and bytecode interpreter to find the full device tree
- USB controller and USB keyboard driver


## How to build it

_The Xcode project is only used to build unit tests for some of the libraries and the ACPI
TDD. It cannot build the kernel._

Currently it only builds on Linux. It requires:

* clang
* nasm (known to work with 2.11.09rc1 but earlier should be ok)

To build a .iso for a usbkey also requires:
* xorriso
* mtools


A special version of the Swift compiler is required with options to disable red zone and
set the x86_64 memory model to *kernel*. A Swift stdlib compiled with these options is also
required. A suitable compiler/library can be obtained
[here](https://github.com/spevans/swift-kstdlib/). A snapshot can be downloaded from
(https://github.com/spevans/swift-kstdlib/releases). Normally the latest one with the highest
date is required.

The version required is listed in the `Makedefs` file in the `KSWIFTDIR` variable eg:
```
KSWIFTDIR := $(shell readlink -f ~/swift-kernel-20170730)
```

A normal Swift [snapshot](https://swift.org/download/#snapshots) is required to build the
utilities that patch the image for booting.

You should now have 2 compilers installed, one in `~/swift-kernel-<YYYYMMDD>`
and the other wherever you installed the snapshot (I install it and symlink `~/swift` to it).

Edit the `Makedefs` file and alter the `SWIFTDIR` and `KSWIFTDIR` variables as appropriate.

then:
```
$ make
```

To run under qemu with a copy of the console output being sent to a virtual
serial port use:
```
$ qemu-system-x86_64 -hda output/boot-hd.img -serial stdio -D log -d cpu_reset,guest_errors,unimp -no-reboot
```

There is a bochsrc to specify the HD image so it can be run with:
```
$ bochs -q  (then press 'c' to run)
```

To build a .ISO image suitable for booting one from a USB stick, use the `iso`
target. This will also create a `kernel.efi` file that can be booted in GRUB
```
$ make iso
```


![Screenshot](doc/screenshot.png)


Copyright (c) 2015 - 2017 Simon Evans

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
