# project1 - Implementing a minimal bare metal kernel in Swift

## What is it?

A project to write a kernel in Swift with that can boot on a Mac or PC.
The main aim is to get a simple kernel booting up with a CLI with full
concurrency/thread support.

There is a short writeup about it [here](http://si.org/projects/project1).
 
## What does it do?

- Boots up Under QEMU/Bochs or on a Macbook as a EFI image (via GRUB) or .iso
  on a usbkey
- Scans ACPI/SMBIOS tables
- Installs interrupts and exception/fault handlers
- Sets up paging
- Scans PCI bus
- Initialises PIC, PIT and PS/2 keyboard controller
- Runs two simple tasks, one printing 'A' and the other printing 'B' in a loop
  with a simple stack context switch

The next major tasks are:

- Bring all processor cores online
- Run a task on each core to show up concurrency issues
- Implement locking and mutexs etc to try and solve the concurrency issues


## How to build it

Currently it only builds on linux. It requires:

* clang
* nasm (known to work with 2.11.09rc1 but earlier should be ok)

To build a .iso for a usbkey also requires:
* xorriso
* mtools


A special version of the Swift compiler and stdlib is required to disable the
red zone and also remove floating point functions from the stdlib library.
See [here](doc/development.md#red-zone) to build this version.

A normal Swift 3.0 [snapshot](https://swift.org/download/#snapshots) is required
to build some build tools that patch the image for booting.

You should now have 2 compilers installed, one in `~/swift-kernel` and the other
where ever you installed the snapshot (I install it and symlink `~/swift-3`)

Edit the `Makedefs` file and alter the `SWIFT3` and `SWIFTDIR` as appropriate


then:
```
$ make kernel output/boot-hd.img
$ qemu-system-x86_64 -hda output/boot-hd.img

There is a bochsrc to specify the HD image so it can be run with:
$ bochs -q  (then press 'c' to run)
```

![Screenshot](doc/screenshot.png)


Copyright (c) 2015, 2016 Simon Evans

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
