/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160108-64
 * Copyright (c) 2000 - 2016 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of QEMU-DSDT.aml, Sat Apr 29 16:39:43 2017
 *
 * Original Table Header:
 *     Signature        "DSDT"
 *     Length           0x00001135 (4405)
 *     Revision         0x01 **** 32-bit table (V1), no 64-bit math support
 *     Checksum         0x92
 *     OEM ID           "BXPC"
 *     OEM Table ID     "BXDSDT"
 *     OEM Revision     0x00000001 (1)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20120913 (538052883)
 */
DefinitionBlock ("QEMU-DSDT.aml", "DSDT", 1, "BXPC", "BXDSDT", 0x00000001)
{
    /*
     * iASL Warning: There were 2 external control methods found during
     * disassembly, but additional ACPI tables to resolve these externals
     * were not specified. This resulting disassembler output file may not
     * compile because the disassembler did not know how many arguments
     * to assign to these methods. To specify the tables needed to resolve
     * external control method references, the -e option can be used to
     * specify the filenames. Note: SSDTs can be dynamically loaded at
     * runtime and may or may not be available via the host OS.
     * Example iASL invocations:
     *     iasl -e ssdt1.aml ssdt2.aml ssdt3.aml -d dsdt.aml
     *     iasl -e dsdt.aml ssdt2.aml -d ssdt1.aml
     *     iasl -e ssdt*.aml -d dsdt.aml
     *
     * In addition, the -fe option can be used to specify a file containing
     * control method external declarations with the associated method
     * argument counts. Each line of the file must be of the form:
     *     External (<method pathname>, MethodObj, <argument count>)
     * Invocation:
     *     iasl -fe refs.txt -d dsdt.aml
     *
     * The following methods were unresolved and many not compile properly
     * because the disassembler had to guess at the number of arguments
     * required for each:
     */
    External (NTFY, MethodObj)    // Warning: Unresolved method, guessing 2 arguments
    External (PCNT, MethodObj)    // Warning: Unresolved method, guessing 2 arguments

    External (CPON, UnknownObj)
    External (P0E_, IntObj)
    External (P0S_, IntObj)
    External (P1E_, IntObj)
    External (P1L_, IntObj)
    External (P1S_, IntObj)
    External (P1V_, UnknownObj)

    Scope (\)
    {
        OperationRegion (DBG, SystemIO, 0x0402, One)
        Field (DBG, ByteAcc, NoLock, Preserve)
        {
            DBGB,   8
        }

        Method (DBUG, 1, NotSerialized)
        {
            ToHexString (Arg0, Local0)
            ToBuffer (Local0, Local0)
            Local1 = (SizeOf (Local0) - One)
            Local2 = Zero
            While ((Local2 < Local1))
            {
                DBGB = DerefOf (Local0 [Local2])
                Local2++
            }

            DBGB = 0x0A
        }
    }

    Scope (_SB)
    {
        Device (PCI0)
        {
            Name (_HID, EisaId ("PNP0A03") /* PCI Bus */)  // _HID: Hardware ID
            Name (_ADR, Zero)  // _ADR: Address
            Name (_UID, One)  // _UID: Unique ID
        }
    }

    Scope (_SB.PCI0)
    {
        Name (CRES, ResourceTemplate ()
        {
            WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                0x0000,             // Granularity
                0x0000,             // Range Minimum
                0x00FF,             // Range Maximum
                0x0000,             // Translation Offset
                0x0100,             // Length
                ,, )
            IO (Decode16,
                0x0CF8,             // Range Minimum
                0x0CF8,             // Range Maximum
                0x01,               // Alignment
                0x08,               // Length
                )
            WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                0x0000,             // Granularity
                0x0000,             // Range Minimum
                0x0CF7,             // Range Maximum
                0x0000,             // Translation Offset
                0x0CF8,             // Length
                ,, , TypeStatic)
            WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                0x0000,             // Granularity
                0x0D00,             // Range Minimum
                0xFFFF,             // Range Maximum
                0x0000,             // Translation Offset
                0xF300,             // Length
                ,, , TypeStatic)
            DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                0x00000000,         // Granularity
                0x000A0000,         // Range Minimum
                0x000BFFFF,         // Range Maximum
                0x00000000,         // Translation Offset
                0x00020000,         // Length
                ,, , AddressRangeMemory, TypeStatic)
            DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, NonCacheable, ReadWrite,
                0x00000000,         // Granularity
                0xE0000000,         // Range Minimum
                0xFEBFFFFF,         // Range Maximum
                0x00000000,         // Translation Offset
                0x1EC00000,         // Length
                ,, _Y00, AddressRangeMemory, TypeStatic)
        })
        Name (CR64, ResourceTemplate ()
        {
            QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                0x0000000000000000, // Granularity
                0x0000008000000000, // Range Minimum
                0x000000FFFFFFFFFF, // Range Maximum
                0x0000000000000000, // Translation Offset
                0x0000008000000000, // Length
                ,, _Y01, AddressRangeMemory, TypeStatic)
        })
        Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
        {
            CreateDWordField (CRES, \_SB.PCI0._Y00._MIN, PS32)  // _MIN: Minimum Base Address
            CreateDWordField (CRES, \_SB.PCI0._Y00._MAX, PE32)  // _MAX: Maximum Base Address
            CreateDWordField (CRES, \_SB.PCI0._Y00._LEN, PL32)  // _LEN: Length
            PS32 = P0S /* External reference */
            PE32 = P0E /* External reference */
            PL32 = ((P0E - P0S) + One)
            If ((P1V == Zero))
            {
                Return (CRES) /* \_SB_.PCI0.CRES */
            }

            CreateQWordField (CR64, \_SB.PCI0._Y01._MIN, PS64)  // _MIN: Minimum Base Address
            CreateQWordField (CR64, \_SB.PCI0._Y01._MAX, PE64)  // _MAX: Maximum Base Address
            CreateQWordField (CR64, \_SB.PCI0._Y01._LEN, PL64)  // _LEN: Length
            PS64 = P1S /* External reference */
            PE64 = P1E /* External reference */
            PL64 = P1L /* External reference */
            ConcatenateResTemplate (CRES, CR64, Local0)
            Return (Local0)
        }
    }

    Scope (_SB)
    {
        Device (HPET)
        {
            Name (_HID, EisaId ("PNP0103") /* HPET System Timer */)  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            OperationRegion (HPTM, SystemMemory, 0xFED00000, 0x0400)
            Field (HPTM, DWordAcc, Lock, Preserve)
            {
                VEND,   32, 
                PRD,    32
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Local0 = VEND /* \_SB_.HPET.VEND */
                Local1 = PRD /* \_SB_.HPET.PRD_ */
                Local0 >>= 0x10
                If (((Local0 == Zero) || (Local0 == 0xFFFF)))
                {
                    Return (Zero)
                }

                If (((Local1 == Zero) || (Local1 > 0x05F5E100)))
                {
                    Return (Zero)
                }

                Return (0x0F)
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadOnly,
                    0xFED00000,         // Address Base
                    0x00000400,         // Address Length
                    )
            })
        }
    }

    Scope (_SB.PCI0)
    {
        Device (VGA)
        {
            Name (_ADR, 0x00020000)  // _ADR: Address
            OperationRegion (PCIC, PCI_Config, Zero, 0x04)
            Field (PCIC, DWordAcc, NoLock, Preserve)
            {
                VEND,   32
            }

            Method (_S1D, 0, NotSerialized)  // _S1D: S1 Device State
            {
                Return (Zero)
            }

            Method (_S2D, 0, NotSerialized)  // _S2D: S2 Device State
            {
                Return (Zero)
            }

            Method (_S3D, 0, NotSerialized)  // _S3D: S3 Device State
            {
                If ((VEND == 0x01001B36))
                {
                    Return (0x03)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
    }

    Scope (_SB.PCI0)
    {
        Device (PX13)
        {
            Name (_ADR, 0x00010003)  // _ADR: Address
            OperationRegion (P13C, PCI_Config, Zero, 0xFF)
        }
    }

    Scope (_SB.PCI0)
    {
        Device (ISA)
        {
            Name (_ADR, 0x00010000)  // _ADR: Address
            OperationRegion (P40C, PCI_Config, 0x60, 0x04)
            Field (^PX13.P13C, AnyAcc, NoLock, Preserve)
            {
                Offset (0x5F), 
                    ,   7, 
                LPEN,   1, 
                Offset (0x67), 
                    ,   3, 
                CAEN,   1, 
                    ,   3, 
                CBEN,   1
            }

            Name (FDEN, One)
        }
    }

    Scope (_SB.PCI0.ISA)
    {
        Device (RTC)
        {
            Name (_HID, EisaId ("PNP0B00") /* AT Real-Time Clock */)  // _HID: Hardware ID
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                IO (Decode16,
                    0x0070,             // Range Minimum
                    0x0070,             // Range Maximum
                    0x10,               // Alignment
                    0x02,               // Length
                    )
                IRQNoFlags ()
                    {8}
                IO (Decode16,
                    0x0072,             // Range Minimum
                    0x0072,             // Range Maximum
                    0x02,               // Alignment
                    0x06,               // Length
                    )
            })
        }

        Device (KBD)
        {
            Name (_HID, EisaId ("PNP0303") /* IBM Enhanced Keyboard (101/102-key, PS/2 Mouse) */)  // _HID: Hardware ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                IO (Decode16,
                    0x0060,             // Range Minimum
                    0x0060,             // Range Maximum
                    0x01,               // Alignment
                    0x01,               // Length
                    )
                IO (Decode16,
                    0x0064,             // Range Minimum
                    0x0064,             // Range Maximum
                    0x01,               // Alignment
                    0x01,               // Length
                    )
                IRQNoFlags ()
                    {1}
            })
        }

        Device (MOU)
        {
            Name (_HID, EisaId ("PNP0F13") /* PS/2 Mouse */)  // _HID: Hardware ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                IRQNoFlags ()
                    {12}
            })
        }

        Device (FDC0)
        {
            Name (_HID, EisaId ("PNP0700"))  // _HID: Hardware ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Local0 = FDEN /* \_SB_.PCI0.ISA_.FDEN */
                If ((Local0 == Zero))
                {
                    Return (Zero)
                }
                Else
                {
                    Return (0x0F)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                IO (Decode16,
                    0x03F2,             // Range Minimum
                    0x03F2,             // Range Maximum
                    0x00,               // Alignment
                    0x04,               // Length
                    )
                IO (Decode16,
                    0x03F7,             // Range Minimum
                    0x03F7,             // Range Maximum
                    0x00,               // Alignment
                    0x01,               // Length
                    )
                IRQNoFlags ()
                    {6}
                DMA (Compatibility, NotBusMaster, Transfer8, )
                    {2}
            })
        }

        Device (LPT)
        {
            Name (_HID, EisaId ("PNP0400") /* Standard LPT Parallel Port */)  // _HID: Hardware ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Local0 = LPEN /* \_SB_.PCI0.ISA_.LPEN */
                If ((Local0 == Zero))
                {
                    Return (Zero)
                }
                Else
                {
                    Return (0x0F)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                IO (Decode16,
                    0x0378,             // Range Minimum
                    0x0378,             // Range Maximum
                    0x08,               // Alignment
                    0x08,               // Length
                    )
                IRQNoFlags ()
                    {7}
            })
        }

        Device (COM1)
        {
            Name (_HID, EisaId ("PNP0501") /* 16550A-compatible COM Serial Port */)  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Local0 = CAEN /* \_SB_.PCI0.ISA_.CAEN */
                If ((Local0 == Zero))
                {
                    Return (Zero)
                }
                Else
                {
                    Return (0x0F)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                IO (Decode16,
                    0x03F8,             // Range Minimum
                    0x03F8,             // Range Maximum
                    0x00,               // Alignment
                    0x08,               // Length
                    )
                IRQNoFlags ()
                    {4}
            })
        }

        Device (COM2)
        {
            Name (_HID, EisaId ("PNP0501") /* 16550A-compatible COM Serial Port */)  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Local0 = CBEN /* \_SB_.PCI0.ISA_.CBEN */
                If ((Local0 == Zero))
                {
                    Return (Zero)
                }
                Else
                {
                    Return (0x0F)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                IO (Decode16,
                    0x02F8,             // Range Minimum
                    0x02F8,             // Range Maximum
                    0x00,               // Alignment
                    0x08,               // Length
                    )
                IRQNoFlags ()
                    {3}
            })
        }
    }

    Scope (_SB.PCI0)
    {
        OperationRegion (PCST, SystemIO, 0xAE00, 0x08)
        Field (PCST, DWordAcc, NoLock, WriteAsZeros)
        {
            PCIU,   32, 
            PCID,   32
        }

        OperationRegion (SEJ, SystemIO, 0xAE08, 0x04)
        Field (SEJ, DWordAcc, NoLock, WriteAsZeros)
        {
            B0EJ,   32
        }

        Method (PCEJ, 1, NotSerialized)
        {
            B0EJ = (One << Arg0)
        }

        Method (PCNF, 0, NotSerialized)
        {
            Local0 = Zero
            While ((Local0 < 0x1F))
            {
                Local0++
                If ((PCIU & (One << Local0)))
                {
                    PCNT (Local0, One)
                }

                If ((PCID & (One << Local0)))
                {
                    PCNT (Local0, 0x03)
                }
            }
        }
    }

    Scope (_SB)
    {
        Scope (PCI0)
        {
            Name (_PRT, Package (0x80)  // _PRT: PCI Routing Table
            {
                Package (0x04)
                {
                    0xFFFF, 
                    Zero, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    One, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x02, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x03, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0001FFFF, 
                    Zero, 
                    LNKS, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0001FFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0001FFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0001FFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0002FFFF, 
                    Zero, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0002FFFF, 
                    One, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0002FFFF, 
                    0x02, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0002FFFF, 
                    0x03, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0003FFFF, 
                    Zero, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0003FFFF, 
                    One, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0003FFFF, 
                    0x02, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0003FFFF, 
                    0x03, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0004FFFF, 
                    Zero, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0004FFFF, 
                    One, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0004FFFF, 
                    0x02, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0004FFFF, 
                    0x03, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0005FFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0005FFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0005FFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0005FFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0006FFFF, 
                    Zero, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0006FFFF, 
                    One, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0006FFFF, 
                    0x02, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0006FFFF, 
                    0x03, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0007FFFF, 
                    Zero, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0007FFFF, 
                    One, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0007FFFF, 
                    0x02, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0007FFFF, 
                    0x03, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0008FFFF, 
                    Zero, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0008FFFF, 
                    One, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0008FFFF, 
                    0x02, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0008FFFF, 
                    0x03, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0009FFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0009FFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0009FFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0009FFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000AFFFF, 
                    Zero, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000AFFFF, 
                    One, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000AFFFF, 
                    0x02, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000AFFFF, 
                    0x03, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000BFFFF, 
                    Zero, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000BFFFF, 
                    One, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000BFFFF, 
                    0x02, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000BFFFF, 
                    0x03, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000CFFFF, 
                    Zero, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000CFFFF, 
                    One, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000CFFFF, 
                    0x02, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000CFFFF, 
                    0x03, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000DFFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000DFFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000DFFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000DFFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000EFFFF, 
                    Zero, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000EFFFF, 
                    One, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000EFFFF, 
                    0x02, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000EFFFF, 
                    0x03, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000FFFFF, 
                    Zero, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000FFFFF, 
                    One, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000FFFFF, 
                    0x02, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000FFFFF, 
                    0x03, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0010FFFF, 
                    Zero, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0010FFFF, 
                    One, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0010FFFF, 
                    0x02, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0010FFFF, 
                    0x03, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0011FFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0011FFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0011FFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0011FFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0012FFFF, 
                    Zero, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0012FFFF, 
                    One, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0012FFFF, 
                    0x02, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0012FFFF, 
                    0x03, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0013FFFF, 
                    Zero, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0013FFFF, 
                    One, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0013FFFF, 
                    0x02, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0013FFFF, 
                    0x03, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0014FFFF, 
                    Zero, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0014FFFF, 
                    One, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0014FFFF, 
                    0x02, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0014FFFF, 
                    0x03, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0015FFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0015FFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0015FFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0015FFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0016FFFF, 
                    Zero, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0016FFFF, 
                    One, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0016FFFF, 
                    0x02, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0016FFFF, 
                    0x03, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0017FFFF, 
                    Zero, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0017FFFF, 
                    One, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0017FFFF, 
                    0x02, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0017FFFF, 
                    0x03, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0018FFFF, 
                    Zero, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0018FFFF, 
                    One, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0018FFFF, 
                    0x02, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0018FFFF, 
                    0x03, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0019FFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0019FFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0019FFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0019FFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001AFFFF, 
                    Zero, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001AFFFF, 
                    One, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001AFFFF, 
                    0x02, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001AFFFF, 
                    0x03, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001BFFFF, 
                    Zero, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001BFFFF, 
                    One, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001BFFFF, 
                    0x02, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001BFFFF, 
                    0x03, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001CFFFF, 
                    Zero, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001CFFFF, 
                    One, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001CFFFF, 
                    0x02, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001CFFFF, 
                    0x03, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001DFFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001DFFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001DFFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001DFFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001EFFFF, 
                    Zero, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001EFFFF, 
                    One, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001EFFFF, 
                    0x02, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001EFFFF, 
                    0x03, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001FFFFF, 
                    Zero, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001FFFFF, 
                    One, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001FFFFF, 
                    0x02, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001FFFFF, 
                    0x03, 
                    LNKB, 
                    Zero
                }
            })
        }

        Field (PCI0.ISA.P40C, ByteAcc, NoLock, Preserve)
        {
            PRQ0,   8, 
            PRQ1,   8, 
            PRQ2,   8, 
            PRQ3,   8
        }

        Method (IQST, 1, NotSerialized)
        {
            If ((0x80 & Arg0))
            {
                Return (0x09)
            }

            Return (0x0B)
        }

        Method (IQCR, 1, Serialized)
        {
            Name (PRR0, ResourceTemplate ()
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, _Y02)
                {
                    0x00000000,
                }
            })
            CreateDWordField (PRR0, \_SB.IQCR._Y02._INT, PRRI)  // _INT: Interrupts
            If ((Arg0 < 0x80))
            {
                PRRI = Arg0
            }

            Return (PRR0) /* \_SB_.IQCR.PRR0 */
        }

        Device (LNKA)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000005,
                    0x0000000A,
                    0x0000000B,
                }
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (IQST (PRQ0))
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PRQ0 |= 0x80
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Return (IQCR (PRQ0))
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateDWordField (Arg0, 0x05, PRRI)
                PRQ0 = PRRI /* \_SB_.LNKA._SRS.PRRI */
            }
        }

        Device (LNKB)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000005,
                    0x0000000A,
                    0x0000000B,
                }
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (IQST (PRQ1))
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PRQ1 |= 0x80
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Return (IQCR (PRQ1))
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateDWordField (Arg0, 0x05, PRRI)
                PRQ1 = PRRI /* \_SB_.LNKB._SRS.PRRI */
            }
        }

        Device (LNKC)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000005,
                    0x0000000A,
                    0x0000000B,
                }
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (IQST (PRQ2))
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PRQ2 |= 0x80
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Return (IQCR (PRQ2))
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateDWordField (Arg0, 0x05, PRRI)
                PRQ2 = PRRI /* \_SB_.LNKC._SRS.PRRI */
            }
        }

        Device (LNKD)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000005,
                    0x0000000A,
                    0x0000000B,
                }
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (IQST (PRQ3))
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PRQ3 |= 0x80
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Return (IQCR (PRQ3))
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateDWordField (Arg0, 0x05, PRRI)
                PRQ3 = PRRI /* \_SB_.LNKD._SRS.PRRI */
            }
        }

        Device (LNKS)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000009,
                }
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0B)
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Return (_PRS) /* \_SB_.LNKS._PRS */
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
            }
        }
    }

    Scope (_SB)
    {
        Method (CPMA, 1, NotSerialized)
        {
            Local0 = DerefOf (CPON [Arg0])
            Local1 = Buffer (0x08)
                {
                     0x00, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   /* ........ */
                }
            Local1 [0x02] = Arg0
            Local1 [0x03] = Arg0
            Local1 [0x04] = Local0
            Return (Local1)
        }

        Method (CPST, 1, NotSerialized)
        {
            Local0 = DerefOf (CPON [Arg0])
            If (Local0)
            {
                Return (0x0F)
            }
            Else
            {
                Return (Zero)
            }
        }

        Method (CPEJ, 2, NotSerialized)
        {
            Sleep (0xC8)
        }

        OperationRegion (PRST, SystemIO, 0xAF00, 0x20)
        Field (PRST, ByteAcc, NoLock, Preserve)
        {
            PRS,    256
        }

        Method (PRSC, 0, NotSerialized)
        {
            Local5 = PRS /* \_SB_.PRS_ */
            Local2 = Zero
            Local0 = Zero
            While ((Local0 < SizeOf (CPON)))
            {
                Local1 = DerefOf (CPON [Local0])
                If ((Local0 & 0x07))
                {
                    Local2 >>= One
                }
                Else
                {
                    Local2 = DerefOf (Local5 [(Local0 >> 0x03)])
                }

                Local3 = (Local2 & One)
                If ((Local1 != Local3))
                {
                    CPON [Local0] = Local3
                    If ((Local3 == One))
                    {
                        NTFY (Local0, One)
                    }
                    Else
                    {
                        NTFY (Local0, 0x03)
                    }
                }

                Local0++
            }
        }
    }

    Scope (_GPE)
    {
        Name (_HID, "ACPI0006" /* GPE Block Device */)  // _HID: Hardware ID
        Method (_L00, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
        }

        Method (_E01, 0, NotSerialized)  // _Exx: Edge-Triggered GPE
        {
            \_SB.PCI0.PCNF ()
        }

        Method (_E02, 0, NotSerialized)  // _Exx: Edge-Triggered GPE
        {
            \_SB.PRSC ()
        }

        Method (_L03, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
        }

        Method (_L04, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
        }

        Method (_L05, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
        }

        Method (_L06, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
        }

        Method (_L07, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
        }

        Method (_L08, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
        }

        Method (_L09, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
        }

        Method (_L0A, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
        }

        Method (_L0B, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
        }

        Method (_L0C, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
        }

        Method (_L0D, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
        }

        Method (_L0E, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
        }

        Method (_L0F, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
        }
    }
}

