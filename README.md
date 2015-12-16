# Hello World in Swift without an OS

## What is it?

Bare minimum implementation of a libc that supports a simple Hello World
written in Swift.


## What does it do?

It boots up, switches into x86-64 Long mode then jumps to a simple Swift
program that prints to the screen. It uses a screen driver written in
Swift to do the printing.


## How to build it

Curently it only builds on linux. It requires:

* clang or gcc
* nasm (known to work with 2.11.09rc1 but earlier should be ok)
* The linux snapshots from https://swift.org/download/#latest-development-snapshots
  - it might work with a version compiled from github but Swift is
  currently such a fast moving target it is not guaranteed to work with
  the very lastest as new libc calls may be required etc
* bochs or qemu-system-x86_64 for running it

1. Edit Makedefs and set CC if required and SWIFTDIR to where the
   untarred snapshot is

2. Run `make` this should compile everything and create the hard disk
   image as a file called `disk_image`. The file is padded upto 10MB as
   bochs likes the virutal hd to have a proper geometry.

There is a bochsrc to specify the HD image so it can be run with:

`bochs -q`  (then press 'c' to run)
or
`qemu-system-x86_64 -hda disk_image`

The screen should show 'Hello world' and the address of the text, data,
bss sections and then HLT


## Will it build on OSX?

Currently it will not build on OSX. I originally started developing on
OSX against the libswiftCore.dylib shipped with the latest Xcode
including writing a static linker to link the .dylib with the stub C
functions to produce a binary. This was working however I got stuck
doing the stubs for the Obj-C functions. Then Swift went open source and
the linux libary is obviously not compiled with Obj-C support so it
removed a whole slew of functions and symbols that would need to be
supported.

The linux version also has the advantage that it builds a more efficient
binary since it is using proper ELF files and the standard ld linker.
The static linker I wrote just dumps the .dylib and relocates it in
place but it suffers from the fact that ZEROFILLE sections have to be
stored as blocks of zeros in the binary and there is no optimisation of
cstring sections etc. Also, changes in the latest .dylib built from the
Swift repo seem to add some new header flags which I have yet to
support. I may finish it off for completeness but it will never produce
as good a binary as the ELF/ld version.

There is a flag called SWIFT_OBJC_INTEROP in include/swift/RunTime/Config.h
in the Swift repo and I tried compiling this with it defined to 0 on OSX
but I had issues building it, although there maybe some other issue I
overlooked to produce a Mach-O dylib without Obj-C.


## Why is there so much C in the code?

The fakelib directory contains all the symbols required to satisfy the
linker even though a lot of them are left unimplemented and simply print
a message and then halt. Most of the functions do the bare minimum to
satisfy the Swift startup or pretend to (eg the pthread functions dont
actually do any locking or unlocking etc).

When a Swift function is first called there is some global
initialisation performed in the libraries (wrapped in a pthread_once()/
dispatch_once()). This calls malloc()/free() and some C++ string
functions so all of the C code is required to perform this basic
initialisation. The TTY driver in C is requred for any debugging / oops
messages until Swift is initialised and can take over the display.

Originally I had planned to add more functionality in Swift but it took
longer than I expected to get this far although I hope to add more
memory management and some simple device drivers to see how easy it is
to do in Swift.


## Will it boot on a real PC?

In theory yes as it is fairly standard code to load the kernel (using
the BIOS) and then enter Long mode, and the tty driver just assumes a
normal PC text display at address 0xB8000. However it would probably
require changes to the bootsector / chain loader to boot off of a USB
key. It may boot in a VMware VM but again the issue is getting it onto
a virtual HD. There is no guarantee that it wont break anything so its
best to just use qemu or bochs. It obviously wont boot on a Mac as it
doesnt have any EFI code or understand the video hardware. It also
assumes there is at least 16MB of RAM as the boot code doesnt currently
do any probing to find the amount of free memory.



Copyright (c) 2015 Simon Evans

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
