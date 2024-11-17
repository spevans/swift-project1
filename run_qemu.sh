#!/bin/bash

BOOT="-hda output/boot-hd.img"
DEBUG=""
ARGS=""
MEM=${MEM:=256m}

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
    CMD="qemu-system-x86_64 $DEBUG -accel $ACCEL -cpu host -m $MEM $BOOT -usb  -D log -d int,cpu_reset,guest_errors,unimp -no-reboot $ARGS"
    echo $CMD
    $CMD
else
    CMD="qemu-system-x86_64 $DEBUG  -m $MEM $BOOT -usb  -D log -d int,cpu_reset,guest_errors,unimp -no-reboot $ARGS"
    echo $CMD
    $CMD
fi

