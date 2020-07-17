#!/bin/bash

BOOT="-hda output/boot-hd.img"
DEBUG=""
ARGS=""

ACCEL=kvm
if [ `uname -s` == "Darwin" ]; then
    ACCEL=hvf
fi

for arg in "$@"
do
    case $arg in
    --efi)
        BOOT="-bios ovmf.bios -cdrom output/boot-cd.iso"
	ACCEL=""
        ;;

    -d)
        DEBUG="-s -S"
        ACCEL=""
        ;;

    *)
        ARGS="$ARGS $arg"
    esac
done

if [ "$ACCEL" != "" ]; then
    echo Using Acceleration $ACCEL
    qemu-system-x86_64 $DEBUG -accel $ACCEL -cpu host -m 256M $BOOT -serial stdio -D log -d int,cpu_reset,guest_errors,unimp -no-reboot $ARGS
else
    qemu-system-x86_64 $DEBUG  -m 256M $BOOT -serial stdio -D log -d int,cpu_reset,guest_errors,unimp -no-reboot $ARGS
fi

