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

    --uhci-test)
        # Test with a keyboard, hub and mouse
        ARGS="$ARGS -usb -device usb-hub,bus=usb-bus.0,port=2 -device usb-kbd,bus=usb-bus.0,port=2.3 -device usb-mouse,bus=usb-bus.0,port=1"
        ;;
    --xhci-test)
        # Test with a keyboard, hub and mouse
        ARGS="$ARGS -device qemu-xhci,id=xhci -device usb-mouse,bus=xhci.0,port=1"
        #ARGS="$ARGS -device qemu-xhci -device usb-mouse"
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

