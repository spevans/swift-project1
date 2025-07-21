#!/bin/bash

BOOT="-hda output/boot-hd.img"
DEBUG=""
ARGS=""
MEM=${MEM:=256m}

ACCEL=tcg
OS=$(uname -s)
ARCH=$(uname -m)

if [ "$ARCH" == "x86_64" ]; then
    ARGS="-cpu host"
    if [ "$OS" == "Linux" ]; then
        ACCEL=kvm
    elif [ "$OS" == "Darwin" ]; then
        ACCEL=hvf
    fi
fi

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

if [ "$ACCEL" != "" ]; then
    echo Using Acceleration $ACCEL
fi
CMD="qemu-system-x86_64 $DEBUG -accel $ACCEL -m $MEM $BOOT -usb  -D log -d int,cpu_reset,guest_errors,unimp -no-reboot $ARGS"
echo $CMD
$CMD

