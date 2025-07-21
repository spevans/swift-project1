# project1 - Implementing a minimal bare metal x86-64 kernel in Swift

## What is it?

A project to write a kernel in Swift that can run on x86_64 hardware.
The main aim is to get a simple kernel booting up with a CLI with full
concurrency/thread support on multiple CPUs.

The code has been rewritten to work on Embedded Swift, originally it used
a version of Swift with a modified runtime and standard library. Some small
additions to Embedded Swift needed to be made, currently a separate toolchain
is required. See [swift-kstdlib](https://github.com/spevans/swift-kstdlib/blob/kstdlib-20250720/KERNEL_LIB.md)
for more details. Hopefully the changes will be upstreamed into the main Swift
project at some point.

## Current status

21/07/2025

- Rewritten ACPI intepreter, required due to heavy use of [existentials](https://docs.swift.org/embedded/documentation/embedded/existentials/)
  which are not supported in Embedded Swift. This also fixed a lot of ACPI bugs.
- Improved EFI Framebuffer driver to speed up the text console. This reduces boot
  time significantly.
- UHCI host controller driver and basic hub enumeration now works although
  hot-plug does not.
- Support for USB keyboards and mice using Boot protocol. This allows the keyboard
  on some hardware to work.

The next major tasks are:

- XHCI USB host controller to use USB devices on newer hardware.
- GPU driver for Intel GPUs to speed up the text console on high resolution screens.

## Previous status

- Boots up under QEMU, Bochs and VMWare. Also boots on Macbook 3,1 (13inch Late 2007)
- Installs interrupts and exception/fault handlers
- Sets up paging
- Scans ACPI/SMBIOS tables
- Parses ACPI tables including AML bytecode in DSDT, SSDT tables
- Initialises the APIC and IO/APIC (or PIC)
- Traverses the ACPI device tree adding known devices according to topology.
- Scans PCI bus (MMIO or PIO) to show vendor/device IDs
- Initialises the PIT and PS/2 keyboard controller
- Sets up an APIC and PIT timers and shows a test message with interrupt counts.
- Runs a simple task reading keyboard scan codes from a circular buffer and
  translates them to ASCII codes to show on the screen. The Macbook doesn't
  have an i8042 PS/2 keyboard controller so the keyboard will not work.

Currently working on enabling ACPI to process ACPI events and setting up more
devices including the Realtime Clock and PCI interrupts.


## How to build it

A custom Swift toolchain is currently required to build the kernel as it contains
a modififed version of the Embedded Swift runtime for x86-64. For more details see
[swift-kstdlib](https://github.com/spevans/swift-kstdlib/blob/kstdlib-20250720/KERNEL_LIB.md)

The project has a `Package.swift` but this is only used for building and running the tests,
the kernel itself is built using Makefiles and `make`.

### On Linux

Use Docker to build a container that downloads the Swift compiler with the modified stdlib using
the Dockerfile in `Docker/Dockerfile`.

```
# Build the docker container
$ docker build --tag=swift-kstdlib Docker
# Build the kernel and disk images
$ docker run --rm -v `pwd`:`pwd` -w `pwd` -t swift-kstdlib make
```

### On macOS

Download the [toolchain](https://github.com/spevans/swift-kstdlib/releases/download/v20250720/swift-LOCAL-2025-07-20-a-osx.tar.gz)
and untar it in the home directory, the toolchain will be installed under `Library/Developer/Toolchains/`.
Some extra tools need to be installed as well.

```
brew install nasm x86_64-elf-binutils qemu xorriso mtools
make
```


## How to run it

To run under qemu with a copy of the console output being sent to a virtual
serial port use:

`./run_qemu.sh`

or to use with UEFI/OVMF BIOS
`./run_qemu.sh --efi`

![Screenshot](doc/screenshot-2.png)


Copyright (c) 2015 - 2025 Simon Evans

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
