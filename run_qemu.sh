#!/bin/bash

BOOT="-hda output/boot-hd.img"
DEBUG=""
ARGS=""

for arg in "$@"
do
    case $arg in
    --efi)
        BOOT="-bios ovmf.bios -cdrom output/boot-cd.iso"
        ;;

    -d)
        DEBUG="-s -S"
        ;;

    *)
        ARGS="$ARGS $arg"
    esac
done

ACCEL=kvm
if [ `uname -s` == "Darwin" ]; then
    ACCEL=hvf
fi

qemu-system-x86_64 -accel $ACCEL -cpu host -m 256M $BOOT -serial stdio -D log -d int,cpu_reset,guest_errors,unimp -no-reboot $ARGS

