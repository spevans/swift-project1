qemu-system-x86_64 -m 16G  -cdrom output/boot-cd.iso
qemu-system-x86_64 -M q35  -hda output/boot-hd.img
qemu-system-x86_64 -bios bios.bin -m 16G  -cdrom output/boot-cd.iso
qemu-system-x86_64 -m 16G  -usbdevice disk:output/boot-cd.iso
