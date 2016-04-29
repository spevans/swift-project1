# project1 - Using Swift for lowlevel kernel programming

## What is it?

A test to see how easy it is to write lowlevel code in Swift. There is short
writeup about it [here](http://si.org/projects/project1).

## What does it do?

- Boots up (Under QEMU, Bochs or VMWare)
- Scans ACPI/SMBIOS tables
- Installs interrupts and exception/fault handlers
- Sets up paging
- Scans PCI bus
- Initialises timer and keyboard

Currently working on implementing pthread functions and getting simple tasks up
and running.


## How to build it

Currently it only builds on linux. It requires:

* clang
* xorriso
* mtools
* nasm (known to work with 2.11.09rc1 but earlier should be ok)

A normal Swift 3.0 [snapshot](https://swift.org/download/#snapshots) is also
required along with a special version to disable the red zone.
See [here](doc/development.md#red-zone) to build a swift compiler and stdlib
with red-zone disabled.


You should now have 2 compilers installed, one in `~/swift-kernel` and the other
where ever you installed the snapshot (I install it and symlink `~/swift-3`)

Edit the `Makedefs` file and alter the `SWIFT3` and `SWIFTDIR` as appropriate


then:
```
$ make kernel iso
$ qemu-system-x86_64 -hda disk_image

There is a bochsrc to specify the HD image so it can be run with:
$ bochs -q  (then press 'c' to run)
```

![Screenshot](doc/screenshot.png)


Copyright (c) 2015 Simon Evans

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
