/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160108-64
 * Copyright (c) 2000 - 2016 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of DSDT.aml, Sun Apr 30 09:56:03 2017
 *
 * Original Table Header:
 *     Signature        "DSDT"
 *     Length           0x000045B6 (17846)
 *     Revision         0x01 **** 32-bit table (V1), no 64-bit math support
 *     Checksum         0x3B
 *     OEM ID           "APPLE "
 *     OEM Table ID     "MacBook"
 *     OEM Revision     0x00030001 (196609)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20061109 (537268489)
 */
DefinitionBlock ("DSDT.aml", "DSDT", 1, "APPLE ", "MacBook", 0x00030001)
{

    External (PDC0, UnknownObj)
    External (PDC1, UnknownObj)

    OperationRegion (PRT0, SystemIO, 0x80, 0x04)
    Field (PRT0, DWordAcc, Lock, Preserve)
    {
        P80H,   32
    }

    OperationRegion (SPRT, SystemIO, 0xB2, 0x02)
    Field (SPRT, ByteAcc, Lock, Preserve)
    {
        SSMP,   8
    }

    OperationRegion (S_IO, SystemIO, 0x0680, 0x11)
    Field (S_IO, ByteAcc, NoLock, Preserve)
    {
        PMS0,   8, 
        PME0,   8, 
        PMS1,   8, 
        PMS2,   8, 
        PMS3,   8, 
        PME1,   8, 
        PME2,   8, 
        PME3,   8, 
        SMS1,   8, 
        SMS2,   8, 
        SME1,   8, 
        SME2,   8, 
        RT10,   1, 
        RT11,   1, 
            ,   1, 
        RT13,   1, 
        Offset (0x0E), 
        RT30,   1, 
        RT31,   1, 
        RT32,   1, 
        RT33,   1, 
        RT34,   1, 
        RT35,   1, 
        RT36,   1, 
        RT37,   1, 
        Offset (0x10), 
        DLPC,   1, 
        CK33,   1, 
        CK14,   1
    }

    OperationRegion (IO_T, SystemIO, 0x1000, 0x10)
    Field (IO_T, ByteAcc, NoLock, Preserve)
    {
        TRPI,   16, 
        Offset (0x04), 
        Offset (0x06), 
        Offset (0x08), 
        TRP0,   8, 
        TRPC,   8, 
        Offset (0x0B), 
        Offset (0x0C), 
        Offset (0x0D), 
        Offset (0x0E), 
        Offset (0x0F), 
        Offset (0x10)
    }

    OperationRegion (IO_D, SystemIO, 0x0810, 0x08)
    Field (IO_D, ByteAcc, NoLock, Preserve)
    {
        TRPD,   8
    }

    OperationRegion (PMIO, SystemIO, 0x0400, 0x80)
    Field (PMIO, ByteAcc, NoLock, Preserve)
    {
        Offset (0x28), 
            ,   2, 
        SPST,   1, 
        Offset (0x42), 
            ,   1, 
        GPEC,   1
    }

    OperationRegion (GNVS, SystemMemory, 0xBEED5A98, 0x0100)
    Field (GNVS, AnyAcc, Lock, Preserve)
    {
        OSYS,   16, 
        SMIF,   8, 
        PRM0,   8, 
        PRM1,   8, 
        SCIF,   8, 
        PRM2,   8, 
        PRM3,   8, 
        LCKF,   8, 
        PRM4,   8, 
        PRM5,   8, 
        P80D,   32, 
        LIDS,   8, 
        PWRS,   8, 
        DBGS,   8, 
        LINX,   8, 
        Offset (0x14), 
        ACTT,   8, 
        PSVT,   8, 
        TC1V,   8, 
        TC2V,   8, 
        TSPV,   8, 
        CRTT,   8, 
        DTSE,   8, 
        DTS1,   8, 
        DTS2,   8, 
        DTSF,   8, 
        BNUM,   8, 
        B0SC,   8, 
        B1SC,   8, 
        B2SC,   8, 
        B0SS,   8, 
        B1SS,   8, 
        B2SS,   8, 
        Offset (0x28), 
        APIC,   8, 
        MPEN,   8, 
        PCP0,   8, 
        PCP1,   8, 
        PPCM,   8, 
        PPMF,   32, 
        Offset (0x32), 
        NATP,   8, 
        CMAP,   8, 
        CMBP,   8, 
        LPTP,   8, 
        FDCP,   8, 
        CMCP,   8, 
        CIRP,   8, 
        Offset (0x3C), 
        IGDS,   8, 
        TLST,   8, 
        CADL,   8, 
        PADL,   8, 
        CSTE,   16, 
        NSTE,   16, 
        SSTE,   16, 
        NDID,   8, 
        DID1,   32, 
        DID2,   32, 
        DID3,   32, 
        DID4,   32, 
        DID5,   32, 
        BDSP,   8, 
        PTY1,   8, 
        PTY2,   8, 
        PSCL,   8, 
        TVF1,   8, 
        TVF2,   8, 
        Offset (0x63), 
        GOPB,   32, 
        BLCS,   8, 
        BRTL,   8, 
        ALSE,   8, 
        ALAF,   8, 
        LLOW,   8, 
        LHIH,   8, 
        Offset (0x6E), 
        EMAE,   8, 
        EMAP,   16, 
        EMAL,   16, 
        Offset (0x74), 
        MEFE,   8, 
        Offset (0x82), 
        GTF0,   56, 
        GTF2,   56, 
        IDEM,   8, 
        GTF1,   56
    }

    OperationRegion (RCRB, SystemMemory, 0xFED1C000, 0x4000)
    Field (RCRB, DWordAcc, Lock, Preserve)
    {
        Offset (0x1000), 
        Offset (0x3000), 
        Offset (0x3404), 
        HPAS,   2, 
            ,   5, 
        HPAE,   1, 
        Offset (0x3418), 
            ,   1, 
        PATD,   1, 
        SATD,   1, 
        SMBD,   1, 
        HDAD,   1, 
        Offset (0x341A), 
        RP1D,   1, 
        RP2D,   1, 
        RP3D,   1, 
        RP4D,   1, 
        RP5D,   1, 
        RP6D,   1
    }

    OperationRegion (GPIO, SystemIO, 0x0500, 0x3C)
    Field (GPIO, ByteAcc, NoLock, Preserve)
    {
        GU00,   8, 
        GU01,   8, 
        GU02,   8, 
        GU03,   8, 
        GIO0,   8, 
        GIO1,   8, 
        GIO2,   8, 
        GIO3,   8, 
        Offset (0x0C), 
            ,   4, 
        GP4,    1, 
        GP5,    1, 
        Offset (0x0D), 
            ,   1, 
        GP9,    1, 
            ,   7, 
        GP17,   1, 
            ,   5, 
        GP23,   1, 
            ,   3, 
        GP27,   1, 
            ,   1, 
        GP29,   1, 
        Offset (0x10), 
        Offset (0x18), 
        GB00,   8, 
        GB01,   8, 
        GB02,   8, 
        GB03,   8, 
        Offset (0x2C), 
            ,   4, 
        GPI4,   1, 
        Offset (0x2D), 
        GIV1,   8, 
        GIV2,   8, 
        GIV3,   8, 
        GU04,   8, 
        GU05,   8, 
        GU06,   8, 
        GU07,   8, 
        GIO4,   8, 
        GIO5,   8, 
            ,   6, 
        GD54,   1, 
        Offset (0x37), 
        GIO7,   8, 
            ,   5, 
        GP37,   1, 
        Offset (0x39), 
        GP40,   1, 
        GL05,   7, 
            ,   6, 
        GP54,   1, 
        Offset (0x3B), 
        GL07,   8
    }

    Mutex (MUTX, 0x00)
    Scope (\_PR)
    {
        Processor (CPU0, 0x00, 0x00000410, 0x06) {}
        Processor (CPU1, 0x01, 0x00000410, 0x06) {}
    }

    Name (\DSEN, 0x01)
    Name (\ECON, 0x00)
    Name (\GPIC, 0x00)
    Name (\CTYP, 0x00)
    Name (\VFN0, 0x00)
    Method (OSDW, 0, NotSerialized)
    {
        If ((OSYS == 0x2710))
        {
            Return (0x01)
        }
        Else
        {
            Return (0x00)
        }
    }

    Method (PINI, 0, NotSerialized)
    {
        If (CondRefOf (_OSI, Local0))
        {
            If (_OSI ("Darwin"))
            {
                OSYS = 0x2710
            }
            ElseIf (_OSI ("Linux"))
            {
                OSYS = 0x03E8
            }
            ElseIf (_OSI ("Windows 2001"))
            {
                OSYS = 0x07D1
            }
            ElseIf (_OSI ("Windows 2001 SP1"))
            {
                OSYS = 0x07D1
            }
            ElseIf (_OSI ("Windows 2001 SP2"))
            {
                OSYS = 0x07D2
            }
            ElseIf (_OSI ("Windows 2006"))
            {
                OSYS = 0x07D6
            }
        }
        Else
        {
            OSYS = 0x07D0
        }
    }

    Method (\_PIC, 1, NotSerialized)  // _PIC: Interrupt Model
    {
        GPIC = Arg0
    }

    Method (DTGP, 5, NotSerialized)
    {
        If ((Arg0 == ToUUID ("a0b5b7c6-1318-441c-b0c9-fe695eaf949b")))
        {
            If ((Arg1 == One))
            {
                If ((Arg2 == Zero))
                {
                    Arg4 = Buffer (0x01)
                        {
                             0x03                                             /* . */
                        }
                    Return (One)
                }

                If ((Arg2 == One))
                {
                    Return (One)
                }
            }
        }

        Arg4 = Buffer (0x01)
            {
                 0x00                                             /* . */
            }
        Return (Zero)
    }

    Name (_S0, Package (0x03)  // _S0_: S0 System State
    {
        0x00, 
        0x00, 
        0x00
    })
    Name (_S3, Package (0x03)  // _S3_: S3 System State
    {
        0x05, 
        0x05, 
        0x00
    })
    Name (_S4, Package (0x03)  // _S4_: S4 System State
    {
        0x06, 
        0x06, 
        0x00
    })
    Name (_S5, Package (0x03)  // _S5_: S5 System State
    {
        0x07, 
        0x07, 
        0x00
    })
    Method (_PTS, 1, NotSerialized)  // _PTS: Prepare To Sleep
    {
        P80D = 0x00
        P8XH (0x00, Arg0)
        \_SB.PCI0.LPCB.EC.ECSS = Arg0
        GD54 &= 0x00
        GP54 &= 0x00
        GP5 |= 0x01
    }

    Method (_WAK, 1, NotSerialized)  // _WAK: Wake
    {
        P8XH (0x00, 0x00)
        \_SB.PCI0.LPCB.EC.ECSS = 0x00
        If (OSDW ())
        {
            \_SB.PCI0.SBUS.ENAB ()
        }

        LIDS = \_SB.PCI0.LPCB.EC.LSTE
        PWRS = \_SB.PCI0.LPCB.EC.RPWR
        PNOT ()
        Return (Package (0x02)
        {
            0x00, 
            0x00
        })
    }

    Scope (\_GPE)
    {
        Method (_L01, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
            If (((RP5D == 0x00) && \_SB.PCI0.RP05.HPS5))
            {
                Sleep (0x64)
                If (\_SB.PCI0.RP05.PDC5)
                {
                    \_SB.PCI0.RP05.PDC5 = 0x01
                    \_SB.PCI0.RP05.HPS5 = 0x01
                    Notify (\_SB.PCI0.RP05, 0x00) // Bus Check
                }
                Else
                {
                    \_SB.PCI0.RP05.HPS5 = 0x01
                }
            }

            If (((RP6D == 0x00) && \_SB.PCI0.RP06.HPS6))
            {
                Sleep (0x64)
                If (\_SB.PCI0.RP06.PDC6)
                {
                    \_SB.PCI0.RP06.PDC6 = 0x01
                    \_SB.PCI0.RP06.HPS6 = 0x01
                    Notify (\_SB.PCI0.RP06, 0x00) // Bus Check
                }
                Else
                {
                    \_SB.PCI0.RP06.HPS6 = 0x01
                }
            }
        }

        Method (_L02, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
            GPEC = 0x00
        }

        Method (_L03, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
            Notify (\_SB.PCI0.UHC1, 0x02) // Device Wake
            Notify (\_SB.PWRB, 0x02) // Device Wake
        }

        Method (_L04, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
            Notify (\_SB.PCI0.UHC2, 0x02) // Device Wake
            Notify (\_SB.PWRB, 0x02) // Device Wake
        }

        Method (_L0C, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
            Notify (\_SB.PCI0.UHC3, 0x02) // Device Wake
            Notify (\_SB.PWRB, 0x02) // Device Wake
        }

        Method (_L0E, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
            Notify (\_SB.PCI0.UHC4, 0x02) // Device Wake
            Notify (\_SB.PWRB, 0x02) // Device Wake
        }

        Method (_L05, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
            Notify (\_SB.PCI0.UHC5, 0x02) // Device Wake
            Notify (\_SB.PWRB, 0x02) // Device Wake
        }

        Method (_L07, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
            \_SB.PCI0.SBUS.HSTS = 0x20
        }

        Method (_L09, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
            If (\_SB.PCI0.RP05.PSP5)
            {
                \_SB.PCI0.RP05.PSP5 = 0x01
                \_SB.PCI0.RP05.PMS5 = 0x01
                Notify (\_SB.PCI0.RP05, 0x02) // Device Wake
            }

            If (\_SB.PCI0.RP06.PSP6)
            {
                \_SB.PCI0.RP06.PSP6 = 0x01
                \_SB.PCI0.RP06.PMS6 = 0x01
                Notify (\_SB.PCI0.RP06, 0x02) // Device Wake
            }
        }

        Method (_L0B, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
            Notify (\_SB.PCI0.PCIB, 0x02) // Device Wake
        }

        Method (_L0D, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
            If (\_SB.PCI0.EHC1.PMES)
            {
                \_SB.PCI0.EHC1.PMES = 0x01
                Notify (\_SB.PCI0.EHC1, 0x02) // Device Wake
                Notify (\_SB.PWRB, 0x02) // Device Wake
            }

            If (\_SB.PCI0.EHC2.PMES)
            {
                \_SB.PCI0.EHC2.PMES = 0x01
                Notify (\_SB.PCI0.EHC2, 0x02) // Device Wake
                Notify (\_SB.PWRB, 0x02) // Device Wake
            }
        }

        Method (_L11, 0, NotSerialized)  // _Lxx: Level-Triggered GPE
        {
            Notify (\_SB.PCI0.PCIB.FRWR, 0x00) // Bus Check
        }
    }

    Method (P8XH, 2, Serialized)
    {
        If ((Arg0 == 0x00))
        {
            P80D = ((P80D & 0xFFFFFF00) | Arg1)
        }

        If ((Arg0 == 0x01))
        {
            P80D = ((P80D & 0xFFFF00FF) | (Arg1 << 0x08))
        }

        If ((Arg0 == 0x02))
        {
            P80D = ((P80D & 0xFF00FFFF) | (Arg1 << 0x10))
        }

        If ((Arg0 == 0x03))
        {
            P80D = ((P80D & 0x00FFFFFF) | (Arg1 << 0x18))
        }

        P80H = P80D /* \P80D */
    }

    Method (PNOT, 0, Serialized)
    {
        If (MPEN)
        {
            If ((PDC0 & 0x08))
            {
                Notify (\_PR.CPU0, 0x80) // Performance Capability Change
                If ((PDC0 & 0x10))
                {
                    Sleep (0x64)
                    Notify (\_PR.CPU0, 0x81) // C-State Change
                }
            }

            If ((PDC1 & 0x08))
            {
                Notify (\_PR.CPU1, 0x80) // Performance Capability Change
                If ((PDC1 & 0x10))
                {
                    Sleep (0x64)
                    Notify (\_PR.CPU1, 0x81) // C-State Change
                }
            }
        }
        Else
        {
            Notify (\_PR.CPU0, 0x80) // Performance Capability Change
            Sleep (0x64)
            Notify (\_PR.CPU0, 0x81) // C-State Change
        }
    }

    Method (TRAP, 2, Serialized)
    {
        SMIF = Arg1
        If ((Arg0 == 0x01))
        {
            TRP0 = 0x00
            Return (SMIF) /* \SMIF */
        }

        If ((Arg0 == 0x02))
        {
            TRPD = 0x00
            Return (SMIF) /* \SMIF */
        }

        Return (0x01)
    }

    Method (GETP, 1, Serialized)
    {
        If (((Arg0 & 0x09) == 0x00))
        {
            Return (0xFFFFFFFF)
        }

        If (((Arg0 & 0x09) == 0x08))
        {
            Return (0x0384)
        }

        Local0 = ((Arg0 & 0x0300) >> 0x08)
        Local1 = ((Arg0 & 0x3000) >> 0x0C)
        Return ((0x1E * (0x09 - (Local0 + Local1))))
    }

    Method (GDMA, 5, Serialized)
    {
        If (Arg0)
        {
            If ((Arg1 && Arg4))
            {
                Return (0x14)
            }

            If ((Arg2 && Arg4))
            {
                Return (((0x04 - Arg3) * 0x0F))
            }

            Return (((0x04 - Arg3) * 0x1E))
        }

        Return (0xFFFFFFFF)
    }

    Method (GETT, 1, Serialized)
    {
        Return ((0x1E * (0x09 - (((Arg0 >> 0x02) & 0x03
            ) + (Arg0 & 0x03)))))
    }

    Method (GETF, 3, Serialized)
    {
        Name (TMPF, 0x00)
        If (Arg0)
        {
            TMPF |= 0x01
        }

        If ((Arg2 & 0x02))
        {
            TMPF |= 0x02
        }

        If (Arg1)
        {
            TMPF |= 0x04
        }

        If ((Arg2 & 0x20))
        {
            TMPF |= 0x08
        }

        If ((Arg2 & 0x4000))
        {
            TMPF |= 0x10
        }

        Return (TMPF) /* \GETF.TMPF */
    }

    Method (SETP, 3, Serialized)
    {
        If ((Arg0 > 0xF0))
        {
            Return (0x08)
        }
        ElseIf ((Arg1 & 0x02))
        {
            If (((Arg0 <= 0x78) && (Arg2 & 0x02)))
            {
                Return (0x2301)
            }

            If (((Arg0 <= 0xB4) && (Arg2 & 0x01)))
            {
                Return (0x2101)
            }
        }
    }

    Method (SDMA, 1, Serialized)
    {
        If ((Arg0 <= 0x14))
        {
            Return (0x01)
        }

        If ((Arg0 <= 0x1E))
        {
            Return (0x02)
        }

        If ((Arg0 <= 0x2D))
        {
            Return (0x01)
        }

        If ((Arg0 <= 0x3C))
        {
            Return (0x02)
        }

        If ((Arg0 <= 0x5A))
        {
            Return (0x01)
        }

        Return (0x00)
    }

    Method (SETT, 3, Serialized)
    {
        If ((Arg1 & 0x02))
        {
            If (((Arg0 <= 0x78) && (Arg2 & 0x02)))
            {
                Return (0x0B)
            }

            If (((Arg0 <= 0xB4) && (Arg2 & 0x01)))
            {
                Return (0x09)
            }
        }

        Return (0x04)
    }

    Scope (\_SB)
    {
        Method (_INI, 0, NotSerialized)  // _INI: Initialize
        {
            PINI ()
        }

        Device (ADP1)
        {
            Name (_HID, "ACPI0003" /* Power Source Device */)  // _HID: Hardware ID
            Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
            {
                0x18, 
                0x03
            })
            Method (_PSR, 0, NotSerialized)  // _PSR: Power Source
            {
                Return (PWRS) /* \PWRS */
            }

            Method (_PCL, 0, NotSerialized)  // _PCL: Power Consumer List
            {
                Return (\_SB)
            }

            Method (_PSW, 1, NotSerialized)  // _PSW: Power State Wake
            {
                If (Arg0)
                {
                    \_SB.PCI0.LPCB.EC.ACWK = 0x01
                }
                Else
                {
                    \_SB.PCI0.LPCB.EC.ACWK = 0x00
                }
            }
        }

        Device (LID0)
        {
            Name (_HID, EisaId ("PNP0C0D") /* Lid Device */)  // _HID: Hardware ID
            Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
            {
                0x18, 
                0x03
            })
            Method (_LID, 0, NotSerialized)  // _LID: Lid Status
            {
                Return (LIDS) /* \LIDS */
            }

            Method (_PSW, 1, NotSerialized)  // _PSW: Power State Wake
            {
                If (Arg0)
                {
                    \_SB.PCI0.LPCB.EC.LWAK = 0x01
                }
                Else
                {
                    \_SB.PCI0.LPCB.EC.LWAK = 0x00
                }
            }
        }

        Device (PNLF)
        {
            Name (_HID, EisaId ("APP0002"))  // _HID: Hardware ID
            Name (_CID, "backlight")  // _CID: Compatible ID
            Name (_UID, 0x0C)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
        }

        Device (PWRB)
        {
            Name (_HID, EisaId ("PNP0C0C") /* Power Button Device */)  // _HID: Hardware ID
        }

        Device (SLPB)
        {
            Name (_HID, EisaId ("PNP0C0E") /* Sleep Button Device */)  // _HID: Hardware ID
            Name (_STA, 0x0B)  // _STA: Status
        }

        Device (PCI0)
        {
            Method (_INI, 0, NotSerialized)  // _INI: Initialize
            {
                If (OSDW ())
                {
                    \_SB.PCI0.SBUS.ENAB ()
                }
            }

            Method (_S3D, 0, NotSerialized)  // _S3D: S3 Device State
            {
                Return (0x03)
            }

            Method (_S4D, 0, NotSerialized)  // _S4D: S4 Device State
            {
                Return (0x03)
            }

            Name (_HID, EisaId ("PNP0A08") /* PCI Express Bus */)  // _HID: Hardware ID
            Name (_CID, EisaId ("PNP0A03") /* PCI Bus */)  // _CID: Compatible ID
            Device (MCHC)
            {
                Name (_ADR, 0x00)  // _ADR: Address
                OperationRegion (HBUS, PCI_Config, 0x40, 0xC0)
                Field (HBUS, DWordAcc, NoLock, Preserve)
                {
                    EPEN,   1, 
                        ,   11, 
                    EPBR,   20, 
                    Offset (0x08), 
                    MHEN,   1, 
                        ,   13, 
                    MHBR,   18, 
                    Offset (0x20), 
                    PXEN,   1, 
                    PXSZ,   2, 
                        ,   23, 
                    PXBR,   6, 
                    Offset (0x28), 
                    DIEN,   1, 
                        ,   11, 
                    DIBR,   20, 
                    Offset (0x30), 
                    IPEN,   1, 
                        ,   11, 
                    IPBR,   20, 
                    Offset (0x50), 
                        ,   4, 
                    PM0H,   2, 
                    Offset (0x51), 
                    PM1L,   2, 
                        ,   2, 
                    PM1H,   2, 
                    Offset (0x52), 
                    PM2L,   2, 
                        ,   2, 
                    PM2H,   2, 
                    Offset (0x53), 
                    PM3L,   2, 
                        ,   2, 
                    PM3H,   2, 
                    Offset (0x54), 
                    PM4L,   2, 
                        ,   2, 
                    PM4H,   2, 
                    Offset (0x55), 
                    PM5L,   2, 
                        ,   2, 
                    PM5H,   2, 
                    Offset (0x56), 
                    PM6L,   2, 
                        ,   2, 
                    PM6H,   2, 
                    Offset (0x57), 
                        ,   7, 
                    HENA,   1, 
                    Offset (0x62), 
                    TUUD,   16, 
                    Offset (0x70), 
                        ,   4, 
                    TLUD,   12
                }
            }

            Name (BUF0, ResourceTemplate ()
            {
                WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                    0x0000,             // Granularity
                    0x0000,             // Range Minimum
                    0x00FF,             // Range Maximum
                    0x0000,             // Translation Offset
                    0x0100,             // Length
                    ,, )
                DWordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x00000000,         // Granularity
                    0x00000000,         // Range Minimum
                    0x00000CF7,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00000CF8,         // Length
                    ,, , TypeStatic)
                IO (Decode16,
                    0x0CF8,             // Range Minimum
                    0x0CF8,             // Range Maximum
                    0x01,               // Alignment
                    0x08,               // Length
                    )
                DWordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x00000000,         // Granularity
                    0x00000D00,         // Range Minimum
                    0x0000FFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x0000F300,         // Length
                    ,, , TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x000A0000,         // Range Minimum
                    0x000BFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00020000,         // Length
                    ,, , AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x000C0000,         // Range Minimum
                    0x000C3FFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00004000,         // Length
                    ,, _Y00, AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x000C4000,         // Range Minimum
                    0x000C7FFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00004000,         // Length
                    ,, _Y01, AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x000C8000,         // Range Minimum
                    0x000CBFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00004000,         // Length
                    ,, _Y02, AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x000CC000,         // Range Minimum
                    0x000CFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00004000,         // Length
                    ,, _Y03, AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x000D0000,         // Range Minimum
                    0x000D3FFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00004000,         // Length
                    ,, _Y04, AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x000D4000,         // Range Minimum
                    0x000D7FFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00004000,         // Length
                    ,, _Y05, AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x000D8000,         // Range Minimum
                    0x000DBFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00004000,         // Length
                    ,, _Y06, AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x000DC000,         // Range Minimum
                    0x000DFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00004000,         // Length
                    ,, _Y07, AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x000E0000,         // Range Minimum
                    0x000E3FFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00004000,         // Length
                    ,, _Y08, AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x000E4000,         // Range Minimum
                    0x000E7FFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00004000,         // Length
                    ,, _Y09, AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x000E8000,         // Range Minimum
                    0x000EBFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00004000,         // Length
                    ,, _Y0A, AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x000EC000,         // Range Minimum
                    0x000EFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00004000,         // Length
                    ,, _Y0B, AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x000F0000,         // Range Minimum
                    0x000FFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00010000,         // Length
                    ,, _Y0C, AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x00000000,         // Range Minimum
                    0xFEBFFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00000000,         // Length
                    ,, _Y0D, AddressRangeMemory, TypeStatic)
            })
            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                If (^MCHC.PM1L)
                {
                    CreateDWordField (BUF0, \_SB.PCI0._Y00._LEN, C0LN)  // _LEN: Length
                    C0LN = Zero
                }

                If ((^MCHC.PM1L == 0x01))
                {
                    CreateBitField (BUF0, \_SB.PCI0._Y00._RW, C0RW)  // _RW_: Read-Write Status
                    C0RW = Zero
                }

                If (^MCHC.PM1H)
                {
                    CreateDWordField (BUF0, \_SB.PCI0._Y01._LEN, C4LN)  // _LEN: Length
                    C4LN = Zero
                }

                If ((^MCHC.PM1H == 0x01))
                {
                    CreateBitField (BUF0, \_SB.PCI0._Y01._RW, C4RW)  // _RW_: Read-Write Status
                    C4RW = Zero
                }

                If (^MCHC.PM2L)
                {
                    CreateDWordField (BUF0, \_SB.PCI0._Y02._LEN, C8LN)  // _LEN: Length
                    C8LN = Zero
                }

                If ((^MCHC.PM2L == 0x01))
                {
                    CreateBitField (BUF0, \_SB.PCI0._Y02._RW, C8RW)  // _RW_: Read-Write Status
                    C8RW = Zero
                }

                If (^MCHC.PM2H)
                {
                    CreateDWordField (BUF0, \_SB.PCI0._Y03._LEN, CCLN)  // _LEN: Length
                    CCLN = Zero
                }

                If ((^MCHC.PM2H == 0x01))
                {
                    CreateBitField (BUF0, \_SB.PCI0._Y03._RW, CCRW)  // _RW_: Read-Write Status
                    CCRW = Zero
                }

                If (^MCHC.PM3L)
                {
                    CreateDWordField (BUF0, \_SB.PCI0._Y04._LEN, D0LN)  // _LEN: Length
                    D0LN = Zero
                }

                If ((^MCHC.PM3L == 0x01))
                {
                    CreateBitField (BUF0, \_SB.PCI0._Y04._RW, D0RW)  // _RW_: Read-Write Status
                    D0RW = Zero
                }

                If (^MCHC.PM3H)
                {
                    CreateDWordField (BUF0, \_SB.PCI0._Y05._LEN, D4LN)  // _LEN: Length
                    D4LN = Zero
                }

                If ((^MCHC.PM3H == 0x01))
                {
                    CreateBitField (BUF0, \_SB.PCI0._Y05._RW, D4RW)  // _RW_: Read-Write Status
                    D4RW = Zero
                }

                If (^MCHC.PM4L)
                {
                    CreateDWordField (BUF0, \_SB.PCI0._Y06._LEN, D8LN)  // _LEN: Length
                    D8LN = Zero
                }

                If ((^MCHC.PM4L == 0x01))
                {
                    CreateBitField (BUF0, \_SB.PCI0._Y06._RW, D8RW)  // _RW_: Read-Write Status
                    D8RW = Zero
                }

                If (^MCHC.PM4H)
                {
                    CreateDWordField (BUF0, \_SB.PCI0._Y07._LEN, DCLN)  // _LEN: Length
                    DCLN = Zero
                }

                If ((^MCHC.PM4H == 0x01))
                {
                    CreateBitField (BUF0, \_SB.PCI0._Y07._RW, DCRW)  // _RW_: Read-Write Status
                    DCRW = Zero
                }

                If (^MCHC.PM5L)
                {
                    CreateDWordField (BUF0, \_SB.PCI0._Y08._LEN, E0LN)  // _LEN: Length
                    E0LN = Zero
                }

                If ((^MCHC.PM5L == 0x01))
                {
                    CreateBitField (BUF0, \_SB.PCI0._Y08._RW, E0RW)  // _RW_: Read-Write Status
                    E0RW = Zero
                }

                If (^MCHC.PM5H)
                {
                    CreateDWordField (BUF0, \_SB.PCI0._Y09._LEN, E4LN)  // _LEN: Length
                    E4LN = Zero
                }

                If ((^MCHC.PM5H == 0x01))
                {
                    CreateBitField (BUF0, \_SB.PCI0._Y09._RW, E4RW)  // _RW_: Read-Write Status
                    E4RW = Zero
                }

                If (^MCHC.PM6L)
                {
                    CreateDWordField (BUF0, \_SB.PCI0._Y0A._LEN, E8LN)  // _LEN: Length
                    E8LN = Zero
                }

                If ((^MCHC.PM6L == 0x01))
                {
                    CreateBitField (BUF0, \_SB.PCI0._Y0A._RW, E8RW)  // _RW_: Read-Write Status
                    E8RW = Zero
                }

                If (^MCHC.PM6H)
                {
                    CreateDWordField (BUF0, \_SB.PCI0._Y0B._LEN, ECLN)  // _LEN: Length
                    ECLN = Zero
                }

                If ((^MCHC.PM6H == 0x01))
                {
                    CreateBitField (BUF0, \_SB.PCI0._Y0B._RW, ECRW)  // _RW_: Read-Write Status
                    ECRW = Zero
                }

                If (^MCHC.PM0H)
                {
                    CreateDWordField (BUF0, \_SB.PCI0._Y0C._LEN, F0LN)  // _LEN: Length
                    F0LN = Zero
                }

                If ((^MCHC.PM0H == 0x01))
                {
                    CreateBitField (BUF0, \_SB.PCI0._Y0C._RW, F0RW)  // _RW_: Read-Write Status
                    F0RW = Zero
                }

                CreateDWordField (BUF0, \_SB.PCI0._Y0D._MIN, M1MN)  // _MIN: Minimum Base Address
                CreateDWordField (BUF0, \_SB.PCI0._Y0D._MAX, M1MX)  // _MAX: Maximum Base Address
                CreateDWordField (BUF0, \_SB.PCI0._Y0D._LEN, M1LN)  // _LEN: Length
                M1MN = (^MCHC.TLUD << 0x14)
                M1LN = ((M1MX - M1MN) + 0x01)
                Return (BUF0) /* \_SB_.PCI0.BUF0 */
            }

            Method (_OSC, 4, NotSerialized)  // _OSC: Operating System Capabilities
            {
                CreateDWordField (Arg3, 0x00, CDW1)
                If ((Arg0 == ToUUID ("33db4d5b-1ff7-401c-9657-7441c03dd766") /* PCI Host Bridge Device */))
                {
                    If ((Arg2 >= 0x03))
                    {
                        Name (SUPP, 0x00)
                        Name (CTRL, 0x00)
                        Local0 = 0x03
                        CreateDWordField (Arg3, 0x04, CDW2)
                        CreateDWordField (Arg3, 0x08, CDW3)
                        SUPP = CDW2 /* \_SB_.PCI0._OSC.CDW2 */
                        CTRL = CDW3 /* \_SB_.PCI0._OSC.CDW3 */
                        CTRL &= 0x1D
                        If (((SUPP & 0x16) != 0x16))
                        {
                            CTRL &= 0x1E
                        }

                        If (!(CDW1 & 0x01))
                        {
                            If ((CTRL & 0x01))
                            {
                                Local0 &= 0x0E
                            }

                            If ((CTRL & 0x04))
                            {
                                Local0 &= 0x0D
                                \_SB.PCI0.LPCB.GPMD (0x00)
                            }

                            If ((CTRL & 0x10))
                            {
                                Debug = "PCI0._OSC PCI-E cap bit set"
                            }

                            \_SB.PCI0.RP05.SMPC (Local0)
                            \_SB.PCI0.RP06.SMPC (Local0)
                        }

                        If ((Arg1 != One))
                        {
                            CDW1 |= 0x08
                        }

                        If ((CDW3 != CTRL))
                        {
                            CDW1 |= 0x10
                        }

                        CDW3 = CTRL /* \_SB_.PCI0._OSC.CTRL */
                    }
                    Else
                    {
                        CDW1 |= 0x02
                    }
                }
                Else
                {
                    CDW1 |= 0x04
                }

                Return (Arg3)
            }

            Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
            {
                If (GPIC)
                {
                    Return (Package (0x13)
                    {
                        Package (0x04)
                        {
                            0x0001FFFF, 
                            0x00, 
                            0x00, 
                            0x10
                        }, 

                        Package (0x04)
                        {
                            0x0002FFFF, 
                            0x00, 
                            0x00, 
                            0x10
                        }, 

                        Package (0x04)
                        {
                            0x0007FFFF, 
                            0x00, 
                            0x00, 
                            0x10
                        }, 

                        Package (0x04)
                        {
                            0x001AFFFF, 
                            0x00, 
                            0x00, 
                            0x14
                        }, 

                        Package (0x04)
                        {
                            0x001AFFFF, 
                            0x01, 
                            0x00, 
                            0x10
                        }, 

                        Package (0x04)
                        {
                            0x001AFFFF, 
                            0x02, 
                            0x00, 
                            0x15
                        }, 

                        Package (0x04)
                        {
                            0x001BFFFF, 
                            0x00, 
                            0x00, 
                            0x14
                        }, 

                        Package (0x04)
                        {
                            0x001CFFFF, 
                            0x00, 
                            0x00, 
                            0x10
                        }, 

                        Package (0x04)
                        {
                            0x001CFFFF, 
                            0x01, 
                            0x00, 
                            0x11
                        }, 

                        Package (0x04)
                        {
                            0x001CFFFF, 
                            0x02, 
                            0x00, 
                            0x12
                        }, 

                        Package (0x04)
                        {
                            0x001CFFFF, 
                            0x03, 
                            0x00, 
                            0x13
                        }, 

                        Package (0x04)
                        {
                            0x001DFFFF, 
                            0x00, 
                            0x00, 
                            0x10
                        }, 

                        Package (0x04)
                        {
                            0x001DFFFF, 
                            0x01, 
                            0x00, 
                            0x12
                        }, 

                        Package (0x04)
                        {
                            0x001DFFFF, 
                            0x02, 
                            0x00, 
                            0x15
                        }, 

                        Package (0x04)
                        {
                            0x001DFFFF, 
                            0x03, 
                            0x00, 
                            0x14
                        }, 

                        Package (0x04)
                        {
                            0x001FFFFF, 
                            0x00, 
                            0x00, 
                            0x15
                        }, 

                        Package (0x04)
                        {
                            0x001FFFFF, 
                            0x01, 
                            0x00, 
                            0x12
                        }, 

                        Package (0x04)
                        {
                            0x001FFFFF, 
                            0x02, 
                            0x00, 
                            0x14
                        }, 

                        Package (0x04)
                        {
                            0x001FFFFF, 
                            0x03, 
                            0x00, 
                            0x10
                        }
                    })
                }
                Else
                {
                    Return (Package (0x13)
                    {
                        Package (0x04)
                        {
                            0x0001FFFF, 
                            0x00, 
                            \_SB.PCI0.LPCB.LNKA, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x0002FFFF, 
                            0x00, 
                            \_SB.PCI0.LPCB.LNKA, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x0007FFFF, 
                            0x00, 
                            \_SB.PCI0.LPCB.LNKA, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x001AFFFF, 
                            0x00, 
                            \_SB.PCI0.LPCB.LNKE, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x001AFFFF, 
                            0x01, 
                            \_SB.PCI0.LPCB.LNKA, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x001AFFFF, 
                            0x02, 
                            \_SB.PCI0.LPCB.LNKF, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x001BFFFF, 
                            0x00, 
                            \_SB.PCI0.LPCB.LNKE, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x001CFFFF, 
                            0x00, 
                            \_SB.PCI0.LPCB.LNKA, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x001CFFFF, 
                            0x01, 
                            \_SB.PCI0.LPCB.LNKB, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x001CFFFF, 
                            0x02, 
                            \_SB.PCI0.LPCB.LNKC, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x001CFFFF, 
                            0x03, 
                            \_SB.PCI0.LPCB.LNKD, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x001DFFFF, 
                            0x00, 
                            \_SB.PCI0.LPCB.LNKA, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x001DFFFF, 
                            0x01, 
                            \_SB.PCI0.LPCB.LNKC, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x001DFFFF, 
                            0x02, 
                            \_SB.PCI0.LPCB.LNKF, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x001DFFFF, 
                            0x03, 
                            \_SB.PCI0.LPCB.LNKE, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x001FFFFF, 
                            0x00, 
                            \_SB.PCI0.LPCB.LNKF, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x001FFFFF, 
                            0x01, 
                            \_SB.PCI0.LPCB.LNKC, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x001FFFFF, 
                            0x02, 
                            \_SB.PCI0.LPCB.LNKE, 
                            0x00
                        }, 

                        Package (0x04)
                        {
                            0x001FFFFF, 
                            0x03, 
                            \_SB.PCI0.LPCB.LNKA, 
                            0x00
                        }
                    })
                }
            }

            Device (PDRC)
            {
                Name (_HID, EisaId ("PNP0C02") /* PNP Motherboard Resources */)  // _HID: Hardware ID
                Name (_UID, 0x01)  // _UID: Unique ID
                Name (BUF0, ResourceTemplate ()
                {
                    Memory32Fixed (ReadWrite,
                        0x00000000,         // Address Base
                        0x00004000,         // Address Length
                        _Y0E)
                    Memory32Fixed (ReadWrite,
                        0x00000000,         // Address Base
                        0x00004000,         // Address Length
                        _Y0F)
                    Memory32Fixed (ReadWrite,
                        0x00000000,         // Address Base
                        0x00001000,         // Address Length
                        _Y10)
                    Memory32Fixed (ReadWrite,
                        0x00000000,         // Address Base
                        0x00001000,         // Address Length
                        _Y11)
                    Memory32Fixed (ReadWrite,
                        0x00000000,         // Address Base
                        0x00000000,         // Address Length
                        _Y12)
                    Memory32Fixed (ReadWrite,
                        0xFED20000,         // Address Base
                        0x00020000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0xFED45000,         // Address Base
                        0x0004B000,         // Address Length
                        )
                })
                Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
                {
                    CreateDWordField (BUF0, \_SB.PCI0.PDRC._Y0E._BAS, RBR0)  // _BAS: Base Address
                    RBR0 = (\_SB.PCI0.LPCB.RCBA << 0x0E)
                    CreateDWordField (BUF0, \_SB.PCI0.PDRC._Y0F._BAS, MBR0)  // _BAS: Base Address
                    MBR0 = (\_SB.PCI0.MCHC.MHBR << 0x0E)
                    CreateDWordField (BUF0, \_SB.PCI0.PDRC._Y10._BAS, DBR0)  // _BAS: Base Address
                    DBR0 = (\_SB.PCI0.MCHC.DIBR << 0x0C)
                    CreateDWordField (BUF0, \_SB.PCI0.PDRC._Y11._BAS, EBR0)  // _BAS: Base Address
                    EBR0 = (\_SB.PCI0.MCHC.EPBR << 0x0C)
                    CreateDWordField (BUF0, \_SB.PCI0.PDRC._Y12._BAS, XBR0)  // _BAS: Base Address
                    XBR0 = (\_SB.PCI0.MCHC.PXBR << 0x1A)
                    CreateDWordField (BUF0, \_SB.PCI0.PDRC._Y12._LEN, XSZ0)  // _LEN: Length
                    XSZ0 = (0x10000000 >> \_SB.PCI0.MCHC.PXSZ)
                    Return (BUF0) /* \_SB_.PCI0.PDRC.BUF0 */
                }
            }

            Device (GFX0)
            {
                Name (_ADR, 0x00020000)  // _ADR: Address
                Method (DHLV, 0, NotSerialized)
                {
                    Return (GP4) /* \GP4_ */
                }

                Method (DHSP, 1, NotSerialized)
                {
                    If ((Arg0 <= 0x01))
                    {
                        GPI4 = Arg0
                    }
                }

                Name (DHGP, 0x14)
                Method (_DOS, 1, NotSerialized)  // _DOS: Disable Output Switching
                {
                    DSEN = (Arg0 & 0x03)
                }

                Method (_DOD, 0, NotSerialized)  // _DOD: Display Output Devices
                {
                    Return (Package (0x03)
                    {
                        0x80010400, 
                        0x80010200, 
                        0x80010300
                    })
                }

                Method (DSS, 1, NotSerialized)
                {
                    If (((Arg0 & 0xC0000000) == 0x80000000))
                    {
                        If ((NSTE & 0x03))
                        {
                            NSTE &= 0xFFFD /* \NSTE */
                        }

                        If ((NSTE & 0x01))
                        {
                            GP37 = 0x01
                        }
                        Else
                        {
                            GP37 = 0x00
                        }

                        CSTE = NSTE /* \NSTE */
                    }
                }

                Device (LCD)
                {
                    Method (_ADR, 0, Serialized)  // _ADR: Address
                    {
                        Return (0x0400)
                    }

                    Method (_DCS, 0, NotSerialized)  // _DCS: Display Current Status
                    {
                        Return (0x1F)
                    }

                    Method (_DGS, 0, NotSerialized)  // _DGS: Display Graphics State
                    {
                        Return (0x01)
                    }
                }

                Device (VGA)
                {
                    Method (_ADR, 0, Serialized)  // _ADR: Address
                    {
                        Return (0x0300)
                    }

                    Method (_DCS, 0, NotSerialized)  // _DCS: Display Current Status
                    {
                        If ((CSTE & 0x01))
                        {
                            Return (0x1F)
                        }

                        Return (0x1D)
                    }

                    Method (_DGS, 0, NotSerialized)  // _DGS: Display Graphics State
                    {
                        If ((NSTE & 0x01))
                        {
                            Return (0x01)
                        }

                        Return (0x00)
                    }

                    Method (_DSS, 1, NotSerialized)  // _DSS: Device Set State
                    {
                        If ((Arg0 & 0x01))
                        {
                            NSTE |= 0x01 /* \NSTE */
                        }
                        Else
                        {
                            NSTE &= 0xFFFE /* \NSTE */
                        }

                        DSS (Arg0)
                    }
                }

                Device (TV)
                {
                    Method (_ADR, 0, Serialized)  // _ADR: Address
                    {
                        Return (0x0200)
                    }

                    Method (_DCS, 0, NotSerialized)  // _DCS: Display Current Status
                    {
                        If ((CSTE & 0x02))
                        {
                            Return (0x1F)
                        }

                        Return (0x1D)
                    }

                    Method (_DGS, 0, NotSerialized)  // _DGS: Display Graphics State
                    {
                        If ((NSTE & 0x02))
                        {
                            Return (0x01)
                        }

                        Return (0x00)
                    }

                    Method (_DSS, 1, NotSerialized)  // _DSS: Device Set State
                    {
                        If ((Arg0 & 0x01))
                        {
                            NSTE |= 0x02 /* \NSTE */
                        }
                        Else
                        {
                            NSTE &= 0xFFFD /* \NSTE */
                        }

                        DSS (Arg0)
                    }
                }
            }

            Device (HDEF)
            {
                Name (_ADR, 0x001B0000)  // _ADR: Address
            }

            Device (RP05)
            {
                Name (_ADR, 0x001C0004)  // _ADR: Address
                OperationRegion (P5CS, PCI_Config, 0x40, 0x0100)
                Field (P5CS, AnyAcc, NoLock, WriteAsZeros)
                {
                    SBSR,   1, 
                    Offset (0x12), 
                        ,   13, 
                    LAS5,   1, 
                    Offset (0x1A), 
                    ABP5,   1, 
                        ,   2, 
                    PDC5,   1, 
                        ,   2, 
                    PDS5,   1, 
                    Offset (0x1B), 
                    LSC5,   1, 
                    Offset (0x20), 
                    Offset (0x22), 
                    PSP5,   1, 
                    Offset (0x9C), 
                        ,   30, 
                    HPS5,   1, 
                    PMS5,   1
                }

                OperationRegion (P5CE, PCI_Config, 0xD8, 0x04)
                Field (P5CE, AnyAcc, NoLock, Preserve)
                {
                        ,   30, 
                    MPCE,   2
                }

                Device (ARPT)
                {
                    Name (_ADR, 0x00)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x09, 
                        0x03
                    })
                    Name (_SUN, 0x05)  // _SUN: Slot User Number
                    Name (_EJD, "\\_SB.PCI0.EHC1.HUB1.PRT2")  // _EJD: Ejection Dependent Device
                }

                Method (SMPC, 1, NotSerialized)
                {
                    If ((RP5D == 0x00))
                    {
                        MPCE = (Arg0 & 0x03)
                        If (!(Arg0 & 0x01))
                        {
                            ABP5 = One
                            PDC5 = One
                        }
                    }
                }

                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (\GPIC)
                    {
                        Return (Package (0x04)
                        {
                            Package (0x04)
                            {
                                0xFFFF, 
                                0x00, 
                                0x00, 
                                0x10
                            }, 

                            Package (0x04)
                            {
                                0xFFFF, 
                                0x01, 
                                0x00, 
                                0x11
                            }, 

                            Package (0x04)
                            {
                                0xFFFF, 
                                0x02, 
                                0x00, 
                                0x12
                            }, 

                            Package (0x04)
                            {
                                0xFFFF, 
                                0x03, 
                                0x00, 
                                0x13
                            }
                        })
                    }
                    Else
                    {
                        Return (Package (0x04)
                        {
                            Package (0x04)
                            {
                                0xFFFF, 
                                0x00, 
                                \_SB.PCI0.LPCB.LNKA, 
                                0x00
                            }, 

                            Package (0x04)
                            {
                                0xFFFF, 
                                0x01, 
                                \_SB.PCI0.LPCB.LNKB, 
                                0x00
                            }, 

                            Package (0x04)
                            {
                                0xFFFF, 
                                0x02, 
                                \_SB.PCI0.LPCB.LNKC, 
                                0x00
                            }, 

                            Package (0x04)
                            {
                                0xFFFF, 
                                0x03, 
                                \_SB.PCI0.LPCB.LNKD, 
                                0x00
                            }
                        })
                    }
                }
            }

            Device (RP06)
            {
                Name (_ADR, 0x001C0005)  // _ADR: Address
                OperationRegion (P6CS, PCI_Config, 0x40, 0x0100)
                Field (P6CS, AnyAcc, NoLock, WriteAsZeros)
                {
                    Offset (0x12), 
                        ,   13, 
                    LAS6,   1, 
                    Offset (0x1A), 
                    ABP6,   1, 
                        ,   2, 
                    PDC6,   1, 
                        ,   2, 
                    PDS6,   1, 
                    Offset (0x1B), 
                    LSC6,   1, 
                    Offset (0x20), 
                    Offset (0x22), 
                    PSP6,   1, 
                    Offset (0x9C), 
                        ,   30, 
                    HPS6,   1, 
                    PMS6,   1
                }

                OperationRegion (P6CE, PCI_Config, 0xD8, 0x04)
                Field (P6CE, AnyAcc, NoLock, Preserve)
                {
                        ,   30, 
                    MPCE,   2
                }

                Device (GIGE)
                {
                    Name (_ADR, 0x00)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x09, 
                        0x03
                    })
                    Method (EWOL, 1, NotSerialized)
                    {
                        If ((Arg0 == 0x01))
                        {
                            GP9 |= 0x01
                        }
                        Else
                        {
                            GP9 &= 0x00
                        }

                        If ((Arg0 == GP9))
                        {
                            Return (0x00)
                        }
                        Else
                        {
                            Return (0x01)
                        }
                    }
                }

                Method (SMPC, 1, NotSerialized)
                {
                    If ((RP6D == 0x00))
                    {
                        MPCE = (Arg0 & 0x03)
                        If (!(Arg0 & 0x01))
                        {
                            ABP6 = One
                            PDC6 = One
                        }
                    }
                }

                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (\GPIC)
                    {
                        Return (Package (0x04)
                        {
                            Package (0x04)
                            {
                                0xFFFF, 
                                0x00, 
                                0x00, 
                                0x11
                            }, 

                            Package (0x04)
                            {
                                0xFFFF, 
                                0x01, 
                                0x00, 
                                0x12
                            }, 

                            Package (0x04)
                            {
                                0xFFFF, 
                                0x02, 
                                0x00, 
                                0x13
                            }, 

                            Package (0x04)
                            {
                                0xFFFF, 
                                0x03, 
                                0x00, 
                                0x10
                            }
                        })
                    }
                    Else
                    {
                        Return (Package (0x04)
                        {
                            Package (0x04)
                            {
                                0xFFFF, 
                                0x00, 
                                \_SB.PCI0.LPCB.LNKB, 
                                0x00
                            }, 

                            Package (0x04)
                            {
                                0xFFFF, 
                                0x01, 
                                \_SB.PCI0.LPCB.LNKC, 
                                0x00
                            }, 

                            Package (0x04)
                            {
                                0xFFFF, 
                                0x02, 
                                \_SB.PCI0.LPCB.LNKD, 
                                0x00
                            }, 

                            Package (0x04)
                            {
                                0xFFFF, 
                                0x03, 
                                \_SB.PCI0.LPCB.LNKA, 
                                0x00
                            }
                        })
                    }
                }
            }

            Device (UHC1)
            {
                Name (_ADR, 0x001D0000)  // _ADR: Address
                OperationRegion (U1CS, PCI_Config, 0xC4, 0x04)
                Field (U1CS, DWordAcc, NoLock, Preserve)
                {
                    U1EN,   2
                }

                Device (HUB1)
                {
                    Name (_ADR, 0x00)  // _ADR: Address
                    Device (PRT1)
                    {
                        Name (_ADR, 0x01)  // _ADR: Address
                    }

                    Device (PRT2)
                    {
                        Name (_ADR, 0x02)  // _ADR: Address
                        Name (_EJD, "\\_SB.PCI0.RP05.ARPT")  // _EJD: Ejection Dependent Device
                    }
                }

                Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                {
                    0x03, 
                    0x03
                })
                Method (_PSW, 1, NotSerialized)  // _PSW: Power State Wake
                {
                    If (Arg0)
                    {
                        U1EN = 0x03
                    }
                    Else
                    {
                        U1EN = 0x00
                    }
                }

                Method (_S3D, 0, NotSerialized)  // _S3D: S3 Device State
                {
                    Return (0x03)
                }

                Method (_S4D, 0, NotSerialized)  // _S4D: S4 Device State
                {
                    Return (0x03)
                }
            }

            Device (UHC2)
            {
                Name (_ADR, 0x001D0001)  // _ADR: Address
                OperationRegion (U2CS, PCI_Config, 0xC4, 0x04)
                Field (U2CS, DWordAcc, NoLock, Preserve)
                {
                    U2EN,   2
                }

                Device (HUB2)
                {
                    Name (_ADR, 0x00)  // _ADR: Address
                    Device (PRT1)
                    {
                        Name (_ADR, 0x01)  // _ADR: Address
                    }

                    Device (PRT2)
                    {
                        Name (_ADR, 0x02)  // _ADR: Address
                    }
                }

                Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                {
                    0x04, 
                    0x03
                })
                Method (_PSW, 1, NotSerialized)  // _PSW: Power State Wake
                {
                    If (Arg0)
                    {
                        U2EN = 0x03
                    }
                    Else
                    {
                        U2EN = 0x00
                    }
                }

                Method (_S3D, 0, NotSerialized)  // _S3D: S3 Device State
                {
                    Return (0x03)
                }

                Method (_S4D, 0, NotSerialized)  // _S4D: S4 Device State
                {
                    Return (0x03)
                }
            }

            Device (UHC3)
            {
                Name (_ADR, 0x001D0002)  // _ADR: Address
                OperationRegion (U2CS, PCI_Config, 0xC4, 0x04)
                Field (U2CS, DWordAcc, NoLock, Preserve)
                {
                    U3EN,   2
                }

                Device (HUB3)
                {
                    Name (_ADR, 0x00)  // _ADR: Address
                    Device (PRT1)
                    {
                        Name (_ADR, 0x01)  // _ADR: Address
                    }

                    Device (PRT2)
                    {
                        Name (_ADR, 0x02)  // _ADR: Address
                    }
                }

                Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                {
                    0x0C, 
                    0x03
                })
                Method (_PSW, 1, NotSerialized)  // _PSW: Power State Wake
                {
                    If (Arg0)
                    {
                        U3EN = 0x03
                    }
                    Else
                    {
                        U3EN = 0x00
                    }
                }

                Method (_S3D, 0, NotSerialized)  // _S3D: S3 Device State
                {
                    Return (0x03)
                }

                Method (_S4D, 0, NotSerialized)  // _S4D: S4 Device State
                {
                    Return (0x03)
                }
            }

            Device (UHC4)
            {
                Name (_ADR, 0x001A0000)  // _ADR: Address
                OperationRegion (U4CS, PCI_Config, 0xC4, 0x04)
                Field (U4CS, DWordAcc, NoLock, Preserve)
                {
                    U4EN,   2
                }

                Device (HUB4)
                {
                    Name (_ADR, 0x00)  // _ADR: Address
                    Device (PRT1)
                    {
                        Name (_ADR, 0x01)  // _ADR: Address
                    }

                    Device (PRT2)
                    {
                        Name (_ADR, 0x02)  // _ADR: Address
                    }
                }

                Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                {
                    0x0E, 
                    0x03
                })
                Method (_PSW, 1, NotSerialized)  // _PSW: Power State Wake
                {
                    If (Arg0)
                    {
                        U4EN = 0x03
                    }
                    Else
                    {
                        U4EN = 0x00
                    }
                }

                Method (_S3D, 0, NotSerialized)  // _S3D: S3 Device State
                {
                    Return (0x03)
                }

                Method (_S4D, 0, NotSerialized)  // _S4D: S4 Device State
                {
                    Return (0x03)
                }
            }

            Device (UHC5)
            {
                Name (_ADR, 0x001A0001)  // _ADR: Address
                OperationRegion (U5CS, PCI_Config, 0xC4, 0x04)
                Field (U5CS, DWordAcc, NoLock, Preserve)
                {
                    U5EN,   2
                }

                Device (HUB5)
                {
                    Name (_ADR, 0x00)  // _ADR: Address
                    Device (PRT1)
                    {
                        Name (_ADR, 0x01)  // _ADR: Address
                    }

                    Device (PRT2)
                    {
                        Name (_ADR, 0x02)  // _ADR: Address
                    }
                }

                Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                {
                    0x05, 
                    0x03
                })
                Method (_PSW, 1, NotSerialized)  // _PSW: Power State Wake
                {
                    If (Arg0)
                    {
                        U5EN = 0x03
                    }
                    Else
                    {
                        U5EN = 0x00
                    }
                }

                Method (_S3D, 0, NotSerialized)  // _S3D: S3 Device State
                {
                    Return (0x03)
                }

                Method (_S4D, 0, NotSerialized)  // _S4D: S4 Device State
                {
                    Return (0x03)
                }
            }

            Device (EHC1)
            {
                Name (_ADR, 0x001D0007)  // _ADR: Address
                OperationRegion (U7CS, PCI_Config, 0x54, 0x04)
                Field (U7CS, DWordAcc, NoLock, Preserve)
                {
                        ,   15, 
                    PMES,   1
                }

                Device (HUB1)
                {
                    Name (_ADR, 0x00)  // _ADR: Address
                    Device (PRT1)
                    {
                        Name (_ADR, 0x01)  // _ADR: Address
                    }

                    Device (PRT2)
                    {
                        Name (_ADR, 0x02)  // _ADR: Address
                        Name (_EJD, "\\_SB.PCI0.RP05.ARPT")  // _EJD: Ejection Dependent Device
                    }

                    Device (PRT3)
                    {
                        Name (_ADR, 0x03)  // _ADR: Address
                    }

                    Device (PRT4)
                    {
                        Name (_ADR, 0x04)  // _ADR: Address
                    }

                    Device (PRT5)
                    {
                        Name (_ADR, 0x05)  // _ADR: Address
                    }

                    Device (PRT6)
                    {
                        Name (_ADR, 0x06)  // _ADR: Address
                    }
                }

                Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                {
                    0x0D, 
                    0x03
                })
                Method (_S3D, 0, NotSerialized)  // _S3D: S3 Device State
                {
                    Return (0x03)
                }

                Method (_S4D, 0, NotSerialized)  // _S4D: S4 Device State
                {
                    Return (0x03)
                }

                Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
                {
                    Local0 = Package (0x07)
                        {
                            "AAPL,current-available", 
                            0x04B0, 
                            "AAPL,current-extra", 
                            0x02BC, 
                            "AAPL,current-in-sleep", 
                            0x03E8, 
                            Buffer (0x01)
                            {
                                 0x00                                             /* . */
                            }
                        }
                    DTGP (Arg0, Arg1, Arg2, Arg3, RefOf (Local0))
                    Return (Local0)
                }
            }

            Device (EHC2)
            {
                Name (_ADR, 0x001A0007)  // _ADR: Address
                OperationRegion (UFCS, PCI_Config, 0x54, 0x04)
                Field (UFCS, DWordAcc, NoLock, Preserve)
                {
                        ,   15, 
                    PMES,   1
                }

                Device (HUB2)
                {
                    Name (_ADR, 0x00)  // _ADR: Address
                    Device (PRT1)
                    {
                        Name (_ADR, 0x01)  // _ADR: Address
                    }

                    Device (PRT2)
                    {
                        Name (_ADR, 0x02)  // _ADR: Address
                    }

                    Device (PRT3)
                    {
                        Name (_ADR, 0x03)  // _ADR: Address
                    }

                    Device (PRT4)
                    {
                        Name (_ADR, 0x04)  // _ADR: Address
                    }
                }

                Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                {
                    0x0D, 
                    0x03
                })
                Method (_S3D, 0, NotSerialized)  // _S3D: S3 Device State
                {
                    Return (0x03)
                }

                Method (_S4D, 0, NotSerialized)  // _S4D: S4 Device State
                {
                    Return (0x03)
                }

                Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
                {
                    Local0 = Package (0x07)
                        {
                            "AAPL,current-available", 
                            0x04B0, 
                            "AAPL,current-extra", 
                            0x02BC, 
                            "AAPL,current-in-sleep", 
                            0x03E8, 
                            Buffer (0x01)
                            {
                                 0x00                                             /* . */
                            }
                        }
                    DTGP (Arg0, Arg1, Arg2, Arg3, RefOf (Local0))
                    Return (Local0)
                }
            }

            Device (PCIB)
            {
                Name (_ADR, 0x001E0000)  // _ADR: Address
                OperationRegion (SBRT, PCI_Config, 0x3E, 0x02)
                Field (SBRT, WordAcc, NoLock, Preserve)
                {
                        ,   6, 
                    PRST,   1, 
                    Offset (0x02)
                }

                Method (_PS0, 0, Serialized)  // _PS0: Power State 0
                {
                    If (OSDW ())
                    {
                        Debug = "PCIB D0 Entry"
                        Local0 = \_SB.PCI0.SBUS.SRDB (0xD2, 0x83)
                        If (((Local0 & 0x08) == 0x00))
                        {
                            PRST = 0x01
                            Local0 |= 0x08
                            If (!\_SB.PCI0.SBUS.SWRB (0xD2, 0x83, Local0))
                            {
                                Debug = "PCIB: Setting Clock Failed!"
                            }

                            Sleep (0x0A)
                            PRST = 0x00
                        }

                        Debug = "PCIB D0 Exit"
                    }
                }

                Method (_PS3, 0, Serialized)  // _PS3: Power State 3
                {
                    If (OSDW ())
                    {
                        Debug = "PCIB D3 Entry"
                        Local0 = \_SB.PCI0.SBUS.SRDB (0xD2, 0x83)
                        Local0 &= 0xF7
                        If (!\_SB.PCI0.SBUS.SWRB (0xD2, 0x83, Local0))
                        {
                            Debug = "PCIB: Setting Clock Failed!"
                        }

                        Debug = "PCIB D3 Exit"
                    }
                }

                Device (FRWR)
                {
                    Name (_ADR, 0x00030000)  // _ADR: Address
                    Name (_GPE, 0x11)  // _GPE: General Purpose Events
                }

                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (GPIC)
                    {
                        Return (Package (0x08)
                        {
                            Package (0x04)
                            {
                                0x0003FFFF, 
                                0x00, 
                                0x00, 
                                0x13
                            }, 

                            Package (0x04)
                            {
                                0x0003FFFF, 
                                0x01, 
                                0x00, 
                                0x13
                            }, 

                            Package (0x04)
                            {
                                0x0003FFFF, 
                                0x02, 
                                0x00, 
                                0x13
                            }, 

                            Package (0x04)
                            {
                                0x0003FFFF, 
                                0x03, 
                                0x00, 
                                0x13
                            }, 

                            Package (0x04)
                            {
                                0x0004FFFF, 
                                0x00, 
                                0x00, 
                                0x14
                            }, 

                            Package (0x04)
                            {
                                0x0004FFFF, 
                                0x01, 
                                0x00, 
                                0x14
                            }, 

                            Package (0x04)
                            {
                                0x0004FFFF, 
                                0x02, 
                                0x00, 
                                0x14
                            }, 

                            Package (0x04)
                            {
                                0x0004FFFF, 
                                0x03, 
                                0x00, 
                                0x14
                            }
                        })
                    }
                    Else
                    {
                        Return (Package (0x08)
                        {
                            Package (0x04)
                            {
                                0x0003FFFF, 
                                0x00, 
                                \_SB.PCI0.LPCB.LNKD, 
                                0x00
                            }, 

                            Package (0x04)
                            {
                                0x0003FFFF, 
                                0x01, 
                                \_SB.PCI0.LPCB.LNKD, 
                                0x00
                            }, 

                            Package (0x04)
                            {
                                0x0003FFFF, 
                                0x02, 
                                \_SB.PCI0.LPCB.LNKD, 
                                0x00
                            }, 

                            Package (0x04)
                            {
                                0x0003FFFF, 
                                0x03, 
                                \_SB.PCI0.LPCB.LNKD, 
                                0x00
                            }, 

                            Package (0x04)
                            {
                                0x0004FFFF, 
                                0x00, 
                                \_SB.PCI0.LPCB.LNKE, 
                                0x00
                            }, 

                            Package (0x04)
                            {
                                0x0004FFFF, 
                                0x01, 
                                \_SB.PCI0.LPCB.LNKE, 
                                0x00
                            }, 

                            Package (0x04)
                            {
                                0x0004FFFF, 
                                0x02, 
                                \_SB.PCI0.LPCB.LNKE, 
                                0x00
                            }, 

                            Package (0x04)
                            {
                                0x0004FFFF, 
                                0x03, 
                                \_SB.PCI0.LPCB.LNKE, 
                                0x00
                            }
                        })
                    }
                }
            }

            Device (LPCB)
            {
                Name (_ADR, 0x001F0000)  // _ADR: Address
                OperationRegion (LPC0, PCI_Config, 0x40, 0xC0)
                Field (LPC0, AnyAcc, NoLock, Preserve)
                {
                    Offset (0x20), 
                    PARC,   8, 
                    PBRC,   8, 
                    PCRC,   8, 
                    PDRC,   8, 
                    Offset (0x28), 
                    PERC,   8, 
                    PFRC,   8, 
                    PGRC,   8, 
                    PHRC,   8, 
                    Offset (0x40), 
                    IOD0,   8, 
                    IOD1,   8, 
                    Offset (0x60), 
                        ,   10, 
                    XPME,   1, 
                    Offset (0xB0), 
                    RAEN,   1, 
                        ,   13, 
                    RCBA,   18
                }

                Method (GPMD, 1, NotSerialized)
                {
                    XPME = Arg0
                }

                Device (LNKA)
                {
                    Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
                    Name (_UID, 0x01)  // _UID: Unique ID
                    Method (_DIS, 0, Serialized)  // _DIS: Disable Device
                    {
                        PARC = 0x80
                    }

                    Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
                    {
                        IRQ (Level, ActiveLow, Shared, )
                            {1,3,4,5,6,7,10,12,14,15}
                    })
                    Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
                    {
                        Name (RTLA, ResourceTemplate ()
                        {
                            IRQ (Level, ActiveLow, Shared, _Y13)
                                {}
                        })
                        CreateWordField (RTLA, \_SB.PCI0.LPCB.LNKA._CRS._Y13._INT, IRQ0)  // _INT: Interrupts
                        IRQ0 = Zero
                        IRQ0 = (0x01 << (PARC & 0x0F))
                        Return (RTLA) /* \_SB_.PCI0.LPCB.LNKA._CRS.RTLA */
                    }

                    Method (_SRS, 1, Serialized)  // _SRS: Set Resource Settings
                    {
                        CreateWordField (Arg0, 0x01, IRQ0)
                        FindSetRightBit (IRQ0, Local0)
                        Local0--
                        PARC = Local0
                    }

                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        If ((PARC & 0x80))
                        {
                            Return (0x09)
                        }
                        Else
                        {
                            Return (0x0B)
                        }
                    }
                }

                Device (LNKB)
                {
                    Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
                    Name (_UID, 0x02)  // _UID: Unique ID
                    Method (_DIS, 0, Serialized)  // _DIS: Disable Device
                    {
                        PBRC = 0x80
                    }

                    Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
                    {
                        IRQ (Level, ActiveLow, Shared, )
                            {1,3,4,5,6,7,11,12,14,15}
                    })
                    Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
                    {
                        Name (RTLB, ResourceTemplate ()
                        {
                            IRQ (Level, ActiveLow, Shared, _Y14)
                                {}
                        })
                        CreateWordField (RTLB, \_SB.PCI0.LPCB.LNKB._CRS._Y14._INT, IRQ0)  // _INT: Interrupts
                        IRQ0 = Zero
                        IRQ0 = (0x01 << (PBRC & 0x0F))
                        Return (RTLB) /* \_SB_.PCI0.LPCB.LNKB._CRS.RTLB */
                    }

                    Method (_SRS, 1, Serialized)  // _SRS: Set Resource Settings
                    {
                        CreateWordField (Arg0, 0x01, IRQ0)
                        FindSetRightBit (IRQ0, Local0)
                        Local0--
                        PBRC = Local0
                    }

                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        If ((PBRC & 0x80))
                        {
                            Return (0x09)
                        }
                        Else
                        {
                            Return (0x0B)
                        }
                    }
                }

                Device (LNKC)
                {
                    Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
                    Name (_UID, 0x03)  // _UID: Unique ID
                    Method (_DIS, 0, Serialized)  // _DIS: Disable Device
                    {
                        PCRC = 0x80
                    }

                    Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
                    {
                        IRQ (Level, ActiveLow, Shared, )
                            {1,3,4,5,6,7,10,12,14,15}
                    })
                    Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
                    {
                        Name (RTLC, ResourceTemplate ()
                        {
                            IRQ (Level, ActiveLow, Shared, _Y15)
                                {}
                        })
                        CreateWordField (RTLC, \_SB.PCI0.LPCB.LNKC._CRS._Y15._INT, IRQ0)  // _INT: Interrupts
                        IRQ0 = Zero
                        IRQ0 = (0x01 << (PCRC & 0x0F))
                        Return (RTLC) /* \_SB_.PCI0.LPCB.LNKC._CRS.RTLC */
                    }

                    Method (_SRS, 1, Serialized)  // _SRS: Set Resource Settings
                    {
                        CreateWordField (Arg0, 0x01, IRQ0)
                        FindSetRightBit (IRQ0, Local0)
                        Local0--
                        PCRC = Local0
                    }

                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        If ((PCRC & 0x80))
                        {
                            Return (0x09)
                        }
                        Else
                        {
                            Return (0x0B)
                        }
                    }
                }

                Device (LNKD)
                {
                    Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
                    Name (_UID, 0x04)  // _UID: Unique ID
                    Method (_DIS, 0, Serialized)  // _DIS: Disable Device
                    {
                        PDRC = 0x80
                    }

                    Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
                    {
                        IRQ (Level, ActiveLow, Shared, )
                            {1,3,4,5,6,7,11,12,14,15}
                    })
                    Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
                    {
                        Name (RTLD, ResourceTemplate ()
                        {
                            IRQ (Level, ActiveLow, Shared, _Y16)
                                {}
                        })
                        CreateWordField (RTLD, \_SB.PCI0.LPCB.LNKD._CRS._Y16._INT, IRQ0)  // _INT: Interrupts
                        IRQ0 = Zero
                        IRQ0 = (0x01 << (PDRC & 0x0F))
                        Return (RTLD) /* \_SB_.PCI0.LPCB.LNKD._CRS.RTLD */
                    }

                    Method (_SRS, 1, Serialized)  // _SRS: Set Resource Settings
                    {
                        CreateWordField (Arg0, 0x01, IRQ0)
                        FindSetRightBit (IRQ0, Local0)
                        Local0--
                        PDRC = Local0
                    }

                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        If ((PDRC & 0x80))
                        {
                            Return (0x09)
                        }
                        Else
                        {
                            Return (0x0B)
                        }
                    }
                }

                Device (LNKE)
                {
                    Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
                    Name (_UID, 0x05)  // _UID: Unique ID
                    Method (_DIS, 0, Serialized)  // _DIS: Disable Device
                    {
                        PERC = 0x80
                    }

                    Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
                    {
                        IRQ (Level, ActiveLow, Shared, )
                            {1,3,4,5,6,7,10,12,14,15}
                    })
                    Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
                    {
                        Name (RTLE, ResourceTemplate ()
                        {
                            IRQ (Level, ActiveLow, Shared, _Y17)
                                {}
                        })
                        CreateWordField (RTLE, \_SB.PCI0.LPCB.LNKE._CRS._Y17._INT, IRQ0)  // _INT: Interrupts
                        IRQ0 = Zero
                        IRQ0 = (0x01 << (PERC & 0x0F))
                        Return (RTLE) /* \_SB_.PCI0.LPCB.LNKE._CRS.RTLE */
                    }

                    Method (_SRS, 1, Serialized)  // _SRS: Set Resource Settings
                    {
                        CreateWordField (Arg0, 0x01, IRQ0)
                        FindSetRightBit (IRQ0, Local0)
                        Local0--
                        PERC = Local0
                    }

                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        If ((PERC & 0x80))
                        {
                            Return (0x09)
                        }
                        Else
                        {
                            Return (0x0B)
                        }
                    }
                }

                Device (LNKF)
                {
                    Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
                    Name (_UID, 0x06)  // _UID: Unique ID
                    Method (_DIS, 0, Serialized)  // _DIS: Disable Device
                    {
                        PFRC = 0x80
                    }

                    Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
                    {
                        IRQ (Level, ActiveLow, Shared, )
                            {1,3,4,5,6,7,11,12,14,15}
                    })
                    Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
                    {
                        Name (RTLF, ResourceTemplate ()
                        {
                            IRQ (Level, ActiveLow, Shared, _Y18)
                                {}
                        })
                        CreateWordField (RTLF, \_SB.PCI0.LPCB.LNKF._CRS._Y18._INT, IRQ0)  // _INT: Interrupts
                        IRQ0 = Zero
                        IRQ0 = (0x01 << (PFRC & 0x0F))
                        Return (RTLF) /* \_SB_.PCI0.LPCB.LNKF._CRS.RTLF */
                    }

                    Method (_SRS, 1, Serialized)  // _SRS: Set Resource Settings
                    {
                        CreateWordField (Arg0, 0x01, IRQ0)
                        FindSetRightBit (IRQ0, Local0)
                        Local0--
                        PFRC = Local0
                    }

                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        If ((PFRC & 0x80))
                        {
                            Return (0x09)
                        }
                        Else
                        {
                            Return (0x0B)
                        }
                    }
                }

                Device (LNKG)
                {
                    Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
                    Name (_UID, 0x07)  // _UID: Unique ID
                    Method (_DIS, 0, Serialized)  // _DIS: Disable Device
                    {
                        PGRC = 0x80
                    }

                    Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
                    {
                        IRQ (Level, ActiveLow, Shared, )
                            {1,3,4,5,6,7,10,12,14,15}
                    })
                    Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
                    {
                        Name (RTLG, ResourceTemplate ()
                        {
                            IRQ (Level, ActiveLow, Shared, _Y19)
                                {}
                        })
                        CreateWordField (RTLG, \_SB.PCI0.LPCB.LNKG._CRS._Y19._INT, IRQ0)  // _INT: Interrupts
                        IRQ0 = Zero
                        IRQ0 = (0x01 << (PGRC & 0x0F))
                        Return (RTLG) /* \_SB_.PCI0.LPCB.LNKG._CRS.RTLG */
                    }

                    Method (_SRS, 1, Serialized)  // _SRS: Set Resource Settings
                    {
                        CreateWordField (Arg0, 0x01, IRQ0)
                        FindSetRightBit (IRQ0, Local0)
                        Local0--
                        PGRC = Local0
                    }

                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        If ((PGRC & 0x80))
                        {
                            Return (0x09)
                        }
                        Else
                        {
                            Return (0x0B)
                        }
                    }
                }

                Device (LNKH)
                {
                    Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
                    Name (_UID, 0x08)  // _UID: Unique ID
                    Method (_DIS, 0, Serialized)  // _DIS: Disable Device
                    {
                        PHRC = 0x80
                    }

                    Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
                    {
                        IRQ (Level, ActiveLow, Shared, )
                            {1,3,4,5,6,7,11,12,14,15}
                    })
                    Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
                    {
                        Name (RTLH, ResourceTemplate ()
                        {
                            IRQ (Level, ActiveLow, Shared, _Y1A)
                                {}
                        })
                        CreateWordField (RTLH, \_SB.PCI0.LPCB.LNKH._CRS._Y1A._INT, IRQ0)  // _INT: Interrupts
                        IRQ0 = Zero
                        IRQ0 = (0x01 << (PHRC & 0x0F))
                        Return (RTLH) /* \_SB_.PCI0.LPCB.LNKH._CRS.RTLH */
                    }

                    Method (_SRS, 1, Serialized)  // _SRS: Set Resource Settings
                    {
                        CreateWordField (Arg0, 0x01, IRQ0)
                        FindSetRightBit (IRQ0, Local0)
                        Local0--
                        PHRC = Local0
                    }

                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        If ((PHRC & 0x80))
                        {
                            Return (0x09)
                        }
                        Else
                        {
                            Return (0x0B)
                        }
                    }
                }

                Device (SMC)
                {
                    Name (_HID, EisaId ("APP0001"))  // _HID: Hardware ID
                    Name (_CID, "smc-santarosa")  // _CID: Compatible ID
                    Name (_STA, 0x0B)  // _STA: Status
                    Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                    {
                        IO (Decode16,
                            0x0300,             // Range Minimum
                            0x0300,             // Range Maximum
                            0x01,               // Alignment
                            0x20,               // Length
                            )
                        IRQNoFlags ()
                            {6}
                    })
                    Device (SMS0)
                    {
                        Name (_HID, EisaId ("APP0003"))  // _HID: Hardware ID
                        Name (_CID, "smc-sms")  // _CID: Compatible ID
                    }
                }

                Device (EC)
                {
                    Name (_HID, EisaId ("PNP0C09") /* Embedded Controller Device */)  // _HID: Hardware ID
                    Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                    {
                        IO (Decode16,
                            0x0062,             // Range Minimum
                            0x0062,             // Range Maximum
                            0x00,               // Alignment
                            0x01,               // Length
                            )
                        IO (Decode16,
                            0x0066,             // Range Minimum
                            0x0066,             // Range Maximum
                            0x00,               // Alignment
                            0x01,               // Length
                            )
                    })
                    Name (_GPE, 0x17)  // _GPE: General Purpose Events
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x18, 
                        0x03
                    })
                    Name (ECOK, 0x00)
                    OperationRegion (ECOR, EmbeddedControl, 0x00, 0xFF)
                    Field (ECOR, ByteAcc, Lock, Preserve)
                    {
                        ECVS,   8, 
                        LSTE,   1, 
                        RPWR,   1, 
                        CDIN,   1, 
                        Offset (0x02), 
                        LWAK,   1, 
                        ACWK,   1, 
                        CDWK,   1, 
                        Offset (0x03), 
                        Offset (0x10), 
                        ECSS,   8, 
                        PLIM,   8, 
                        Offset (0x20), 
                        SPTR,   8, 
                        SSTS,   8, 
                        SADR,   8, 
                        SCMD,   8, 
                        SBFR,   256, 
                        SCNT,   8, 
                        SAAD,   8, 
                        SAD0,   8, 
                        SAD1,   8, 
                        SMUX,   8
                    }

                    Field (ECOR, ByteAcc, Lock, Preserve)
                    {
                        Offset (0x24), 
                        SBDW,   16, 
                        Offset (0x46), 
                        SADW,   16
                    }

                    Device (SMB0)
                    {
                        Name (_HID, "ACPI0001" /* SMBus 1.0 Host Controller */)  // _HID: Hardware ID
                        Name (_EC, 0x2010)  // _EC_: Embedded Controller
                        Mutex (SMTX, 0x00)
                        Method (_STA, 0, NotSerialized)  // _STA: Status
                        {
                            If (OSDW ())
                            {
                                Return (0x0F)
                            }
                            Else
                            {
                                Return (0x00)
                            }
                        }

                        Device (SBS0)
                        {
                            Name (_HID, "ACPI0002" /* Smart Battery Subsystem */)  // _HID: Hardware ID
                            Name (_SBS, 0x01)  // _SBS: Smart Battery Subsystem
                        }

                        Method (SBPC, 1, NotSerialized)
                        {
                            Local0 = Arg0
                            While (Local0)
                            {
                                If ((SPTR == 0x00))
                                {
                                    Return ((SSTS & 0x1F))
                                }

                                Sleep (0x01)
                                Local0--
                            }

                            Return (0x18)
                        }

                        Method (SBRW, 3, NotSerialized)
                        {
                            Local0 = One
                            If (!Acquire (\_SB.PCI0.LPCB.EC.SMB0.SMTX, 0xFFFF))
                            {
                                If ((SPTR == 0x00))
                                {
                                    SADR = (Arg0 << 0x01)
                                    SCMD = Arg1
                                    SPTR = 0x09
                                    Local0 = SBPC (0x03E8)
                                    If (!Local0)
                                    {
                                        Arg2 = SBDW /* \_SB_.PCI0.LPCB.EC__.SBDW */
                                    }
                                }

                                Release (\_SB.PCI0.LPCB.EC.SMB0.SMTX)
                            }

                            Return (Local0)
                        }

                        Method (SBRB, 3, NotSerialized)
                        {
                            Local0 = One
                            Local1 = Buffer (0x01)
                                {
                                     0x00                                             /* . */
                                }
                            If (!Acquire (\_SB.PCI0.LPCB.EC.SMB0.SMTX, 0xFFFF))
                            {
                                If ((SPTR == 0x00))
                                {
                                    SADR = (Arg0 << 0x01)
                                    SCMD = Arg1
                                    SPTR = 0x0B
                                    Local0 = SBPC (0x03E8)
                                    If (!Local0)
                                    {
                                        Arg2 = SBFR /* \_SB_.PCI0.LPCB.EC__.SBFR */
                                    }
                                }

                                Release (\_SB.PCI0.LPCB.EC.SMB0.SMTX)
                            }

                            Return (Local0)
                        }
                    }

                    Method (_Q10, 0, NotSerialized)  // _Qxx: EC Query
                    {
                        If (OSDW ())
                        {
                            Notify (\_SB.PCI0.LPCB.EC.SMB0, 0x80) // Status Change
                        }
                        ElseIf ((SSTS & 0x40))
                        {
                            If (!Acquire (\_SB.PCI0.LPCB.EC.SMB0.SMTX, 0xFFFF))
                            {
                                Local0 = (SAAD >> 0x01)
                                If ((Local0 == 0x0A))
                                {
                                    \_SB.BAT0.BNOT (SADW)
                                }

                                SSTS = 0x00
                                Release (\_SB.PCI0.LPCB.EC.SMB0.SMTX)
                            }
                        }
                    }

                    Method (_Q20, 0, NotSerialized)  // _Qxx: EC Query
                    {
                        LIDS = LSTE /* \_SB_.PCI0.LPCB.EC__.LSTE */
                        Notify (\_SB.LID0, 0x80) // Status Change
                    }

                    Method (_Q21, 0, NotSerialized)  // _Qxx: EC Query
                    {
                        If (RPWR)
                        {
                            PWRS = 0x01
                        }
                        Else
                        {
                            PWRS = 0x00
                        }

                        Notify (\_SB.ADP1, 0x80) // Status Change
                        PNOT ()
                    }

                    Method (_Q5A, 0, NotSerialized)  // _Qxx: EC Query
                    {
                        Notify (\_SB.SLPB, 0x80) // Status Change
                    }

                    Method (_Q80, 0, NotSerialized)  // _Qxx: EC Query
                    {
                        PNOT ()
                    }

                    Method (_QCD, 0, NotSerialized)  // _Qxx: EC Query
                    {
                        If (CDIN)
                        {
                            Notify (\_SB.PCI0.PATA, 0x81) // Information Change
                        }
                        Else
                        {
                            Notify (\_SB.PCI0.PATA, 0x82) // Device-Specific Change
                        }
                    }

                    Method (_REG, 2, NotSerialized)  // _REG: Region Availability
                    {
                        ECOK = Arg1
                        If ((Arg1 == 0x01))
                        {
                            LIDS = LSTE /* \_SB_.PCI0.LPCB.EC__.LSTE */
                            Notify (\_SB.LID0, 0x80) // Status Change
                            PWRS = RPWR /* \_SB_.PCI0.LPCB.EC__.RPWR */
                            Notify (\_SB.ADP1, 0x80) // Status Change
                        }

                        ECSS = 0x00
                    }
                }

                Scope (\_SB)
                {
                    Device (BAT0)
                    {
                        Name (_HID, EisaId ("PNP0C0A") /* Control Method Battery */)  // _HID: Hardware ID
                        Name (_UID, 0x00)  // _UID: Unique ID
                        Name (_PCL, Package (0x01)  // _PCL: Power Consumer List
                        {
                            \_SB
                        })
                        Name (BSSW, 0xFFFF)
                        Name (PBIF, Package (0x0D)
                        {
                            0x00, 
                            0xFFFFFFFF, 
                            0xFFFFFFFF, 
                            0x01, 
                            0xFFFFFFFF, 
                            0xFA, 
                            0x64, 
                            0x0A, 
                            0x0A, 
                            " ", 
                            " ", 
                            " ", 
                            " "
                        })
                        Name (PBST, Package (0x04)
                        {
                            0x00, 
                            0xFFFFFFFF, 
                            0xFFFFFFFF, 
                            0xFFFFFFFF
                        })
                        Method (_STA, 0, NotSerialized)  // _STA: Status
                        {
                            If (OSDW ())
                            {
                                Return (0x00)
                            }

                            If (\_SB.PCI0.LPCB.EC.ECOK)
                            {
                                UBSS ()
                                If ((BSSW & 0x01))
                                {
                                    Return (0x1F)
                                }
                                Else
                                {
                                    Return (0x0F)
                                }
                            }
                            Else
                            {
                                Return (0x0F)
                            }
                        }

                        Method (_BST, 0, NotSerialized)  // _BST: Battery Status
                        {
                            If ((BSSW & 0x01))
                            {
                                UBST ()
                            }
                            Else
                            {
                                PBST [0x00] = 0x00
                                PBST [0x01] = 0xFFFFFFFF
                                PBST [0x02] = 0xFFFFFFFF
                            }

                            Return (PBST) /* \_SB_.BAT0.PBST */
                        }

                        Method (_BIF, 0, NotSerialized)  // _BIF: Battery Information
                        {
                            If ((BSSW & 0x01))
                            {
                                UBIF ()
                            }

                            Return (PBIF) /* \_SB_.BAT0.PBIF */
                        }

                        Method (BNOT, 1, NotSerialized)
                        {
                            Local0 = BSSW /* \_SB_.BAT0.BSSW */
                            BSSW = Arg0
                            Notify (\_SB.BAT0, 0x80) // Status Change
                            If (((Local0 ^ Arg0) & 0x01))
                            {
                                Notify (\_SB.BAT0, 0x81) // Information Change
                            }
                        }

                        Method (UBSS, 0, NotSerialized)
                        {
                            \_SB.PCI0.LPCB.EC.SMB0.SBRW (0x0A, 0x01, RefOf (BSSW))
                        }

                        Method (UBIF, 0, NotSerialized)
                        {
                            \_SB.PCI0.LPCB.EC.SMB0.SBRW (0x0B, 0x18, RefOf (Local0))
                            PBIF [0x01] = (Local0 * 0x0A)
                            \_SB.PCI0.LPCB.EC.SMB0.SBRW (0x0B, 0x10, RefOf (Local0))
                            PBIF [0x02] = (Local0 * 0x0A)
                            \_SB.PCI0.LPCB.EC.SMB0.SBRW (0x0B, 0x19, RefOf (Local0))
                            PBIF [0x04] = Local0
                            \_SB.PCI0.LPCB.EC.SMB0.SBRB (0x0B, 0x21, RefOf (Local0))
                            PBIF [0x09] = Local0
                            PBIF [0x0A] = Buffer (0x01)
                                {
                                     0x00                                             /* . */
                                }
                            \_SB.PCI0.LPCB.EC.SMB0.SBRB (0x0B, 0x22, RefOf (Local0))
                            PBIF [0x0B] = Local0
                            \_SB.PCI0.LPCB.EC.SMB0.SBRB (0x0B, 0x20, RefOf (Local0))
                            PBIF [0x0C] = Local0
                        }

                        Method (UBST, 0, NotSerialized)
                        {
                            \_SB.PCI0.LPCB.EC.SMB0.SBRW (0x0B, 0x09, RefOf (Local2))
                            PBST [0x03] = Local2
                            \_SB.PCI0.LPCB.EC.SMB0.SBRW (0x0B, 0x0A, RefOf (Local0))
                            If ((Local0 & 0x8000))
                            {
                                Local0 = ~Local0
                                Local0 = (Local0++ & 0xFFFF)
                            }

                            Local0 *= Local2
                            PBST [0x01] = (Local0 / 0x03E8)
                            \_SB.PCI0.LPCB.EC.SMB0.SBRW (0x0B, 0x0F, RefOf (Local0))
                            PBST [0x02] = (Local0 * 0x0A)
                            Local1 = 0x00
                            If (PWRS)
                            {
                                \_SB.PCI0.LPCB.EC.SMB0.SBRW (0x0B, 0x16, RefOf (Local0))
                                If (!(Local0 & 0x40))
                                {
                                    Local1 = 0x02
                                }
                            }
                            Else
                            {
                                Local1 = 0x01
                            }

                            PBST [0x00] = Local1
                        }
                    }
                }

                Device (DMAC)
                {
                    Name (_HID, EisaId ("PNP0200") /* PC-class DMA Controller */)  // _HID: Hardware ID
                    Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                    {
                        IO (Decode16,
                            0x0000,             // Range Minimum
                            0x0000,             // Range Maximum
                            0x01,               // Alignment
                            0x20,               // Length
                            )
                        IO (Decode16,
                            0x0081,             // Range Minimum
                            0x0081,             // Range Maximum
                            0x01,               // Alignment
                            0x11,               // Length
                            )
                        IO (Decode16,
                            0x0093,             // Range Minimum
                            0x0093,             // Range Maximum
                            0x01,               // Alignment
                            0x0D,               // Length
                            )
                        IO (Decode16,
                            0x00C0,             // Range Minimum
                            0x00C0,             // Range Maximum
                            0x01,               // Alignment
                            0x20,               // Length
                            )
                        DMA (Compatibility, NotBusMaster, Transfer8_16, )
                            {4}
                    })
                }

                Device (FWHD)
                {
                    Name (_HID, EisaId ("INT0800") /* Intel 82802 Firmware Hub Device */)  // _HID: Hardware ID
                    Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                    {
                        Memory32Fixed (ReadOnly,
                            0xFF000000,         // Address Base
                            0x01000000,         // Address Length
                            )
                    })
                }

                Device (HPET)
                {
                    Name (_HID, EisaId ("PNP0103") /* HPET System Timer */)  // _HID: Hardware ID
                    Name (_CID, EisaId ("PNP0C01") /* System Board */)  // _CID: Compatible ID
                    Name (BUF0, ResourceTemplate ()
                    {
                        IRQNoFlags ()
                            {0}
                        IRQNoFlags ()
                            {8}
                        Memory32Fixed (ReadOnly,
                            0xFED00000,         // Address Base
                            0x00000400,         // Address Length
                            _Y1B)
                    })
                    Method (_STA, 0, NotSerialized)  // _STA: Status
                    {
                        If ((OSYS >= 0x07D1))
                        {
                            If (HPAE)
                            {
                                Return (0x0F)
                            }
                        }
                        ElseIf (HPAE)
                        {
                            Return (0x0B)
                        }

                        Return (0x00)
                    }

                    Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
                    {
                        If (HPAE)
                        {
                            CreateDWordField (BUF0, \_SB.PCI0.LPCB.HPET._Y1B._BAS, HPT0)  // _BAS: Base Address
                            If ((HPAS == 0x01))
                            {
                                HPT0 = 0xFED01000
                            }

                            If ((HPAS == 0x02))
                            {
                                HPT0 = 0xFED02000
                            }

                            If ((HPAS == 0x03))
                            {
                                HPT0 = 0xFED03000
                            }
                        }

                        Return (BUF0) /* \_SB_.PCI0.LPCB.HPET.BUF0 */
                    }
                }

                Device (IPIC)
                {
                    Name (_HID, EisaId ("PNP0000") /* 8259-compatible Programmable Interrupt Controller */)  // _HID: Hardware ID
                    Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                    {
                        IO (Decode16,
                            0x0020,             // Range Minimum
                            0x0020,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x0024,             // Range Minimum
                            0x0024,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x0028,             // Range Minimum
                            0x0028,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x002C,             // Range Minimum
                            0x002C,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x0030,             // Range Minimum
                            0x0030,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x0034,             // Range Minimum
                            0x0034,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x0038,             // Range Minimum
                            0x0038,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x003C,             // Range Minimum
                            0x003C,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x00A0,             // Range Minimum
                            0x00A0,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x00A4,             // Range Minimum
                            0x00A4,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x00A8,             // Range Minimum
                            0x00A8,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x00AC,             // Range Minimum
                            0x00AC,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x00B0,             // Range Minimum
                            0x00B0,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x00B4,             // Range Minimum
                            0x00B4,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x00B8,             // Range Minimum
                            0x00B8,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x00BC,             // Range Minimum
                            0x00BC,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x04D0,             // Range Minimum
                            0x04D0,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IRQNoFlags ()
                            {2}
                    })
                }

                Device (MATH)
                {
                    Name (_HID, EisaId ("PNP0C04") /* x87-compatible Floating Point Processing Unit */)  // _HID: Hardware ID
                    Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                    {
                        IO (Decode16,
                            0x00F0,             // Range Minimum
                            0x00F0,             // Range Maximum
                            0x01,               // Alignment
                            0x01,               // Length
                            )
                        IRQNoFlags ()
                            {13}
                    })
                }

                Device (LDRC)
                {
                    Name (_HID, EisaId ("PNP0C02") /* PNP Motherboard Resources */)  // _HID: Hardware ID
                    Name (_UID, 0x02)  // _UID: Unique ID
                    Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                    {
                        IO (Decode16,
                            0x002E,             // Range Minimum
                            0x002E,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x004E,             // Range Minimum
                            0x004E,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x0061,             // Range Minimum
                            0x0061,             // Range Maximum
                            0x01,               // Alignment
                            0x01,               // Length
                            )
                        IO (Decode16,
                            0x0063,             // Range Minimum
                            0x0063,             // Range Maximum
                            0x01,               // Alignment
                            0x01,               // Length
                            )
                        IO (Decode16,
                            0x0065,             // Range Minimum
                            0x0065,             // Range Maximum
                            0x01,               // Alignment
                            0x01,               // Length
                            )
                        IO (Decode16,
                            0x0067,             // Range Minimum
                            0x0067,             // Range Maximum
                            0x01,               // Alignment
                            0x01,               // Length
                            )
                        IO (Decode16,
                            0x0070,             // Range Minimum
                            0x0070,             // Range Maximum
                            0x01,               // Alignment
                            0x01,               // Length
                            )
                        IO (Decode16,
                            0x0080,             // Range Minimum
                            0x0080,             // Range Maximum
                            0x01,               // Alignment
                            0x01,               // Length
                            )
                        IO (Decode16,
                            0x0092,             // Range Minimum
                            0x0092,             // Range Maximum
                            0x01,               // Alignment
                            0x01,               // Length
                            )
                        IO (Decode16,
                            0x00B2,             // Range Minimum
                            0x00B2,             // Range Maximum
                            0x01,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x0680,             // Range Minimum
                            0x0680,             // Range Maximum
                            0x01,               // Alignment
                            0x20,               // Length
                            )
                        IO (Decode16,
                            0x0800,             // Range Minimum
                            0x0800,             // Range Maximum
                            0x01,               // Alignment
                            0x10,               // Length
                            )
                        IO (Decode16,
                            0x0810,             // Range Minimum
                            0x0810,             // Range Maximum
                            0x01,               // Alignment
                            0x08,               // Length
                            )
                        IO (Decode16,
                            0x0400,             // Range Minimum
                            0x0400,             // Range Maximum
                            0x01,               // Alignment
                            0x80,               // Length
                            )
                        IO (Decode16,
                            0x0500,             // Range Minimum
                            0x0500,             // Range Maximum
                            0x01,               // Alignment
                            0x40,               // Length
                            )
                        IO (Decode16,
                            0x1640,             // Range Minimum
                            0x1640,             // Range Maximum
                            0x01,               // Alignment
                            0x10,               // Length
                            )
                    })
                }

                Device (RTC)
                {
                    Name (_HID, EisaId ("PNP0B00") /* AT Real-Time Clock */)  // _HID: Hardware ID
                    Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                    {
                        IO (Decode16,
                            0x0070,             // Range Minimum
                            0x0070,             // Range Maximum
                            0x01,               // Alignment
                            0x08,               // Length
                            )
                    })
                }

                Device (TIMR)
                {
                    Name (_HID, EisaId ("PNP0100") /* PC-class System Timer */)  // _HID: Hardware ID
                    Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                    {
                        IO (Decode16,
                            0x0040,             // Range Minimum
                            0x0040,             // Range Maximum
                            0x01,               // Alignment
                            0x04,               // Length
                            )
                        IO (Decode16,
                            0x0050,             // Range Minimum
                            0x0050,             // Range Maximum
                            0x10,               // Alignment
                            0x04,               // Length
                            )
                    })
                }
            }

            Device (PATA)
            {
                Name (_ADR, 0x001F0001)  // _ADR: Address
                Name (_CID, "media-notify")  // _CID: Compatible ID
                Method (_PSC, 0, Serialized)  // _PSC: Power State Current
                {
                    If (GP5)
                    {
                        Return (0x03)
                    }
                    Else
                    {
                        Return (0x00)
                    }
                }

                Method (_PS0, 0, Serialized)  // _PS0: Power State 0
                {
                    If (GP5)
                    {
                        Debug = "PATA D0 Entry"
                        GD54 &= 0x00
                        GP54 &= 0x00
                        GP40 &= 0x00
                        GP5 &= 0x00
                        Sleep (0x14)
                        GP54 |= 0x01
                        GD54 &= 0x01
                        Debug = "PATA D0 Exit"
                    }
                }

                Method (_PS3, 0, Serialized)  // _PS3: Power State 3
                {
                    Debug = "PATA D3 Entry"
                    GD54 &= 0x00
                    GP54 &= 0x00
                    GP5 |= 0x01
                    GP40 |= 0x01
                    Debug = "PATA D3 Exit"
                }

                OperationRegion (PACS, PCI_Config, 0x40, 0xC0)
                Field (PACS, DWordAcc, NoLock, Preserve)
                {
                    PRIT,   16, 
                    Offset (0x04), 
                    PSIT,   4, 
                    Offset (0x08), 
                    SYNC,   4, 
                    Offset (0x0A), 
                    SDT0,   2, 
                        ,   2, 
                    SDT1,   2, 
                    Offset (0x14), 
                    ICR0,   4, 
                    ICR1,   4, 
                    ICR2,   4, 
                    ICR3,   4, 
                    ICR4,   4, 
                    ICR5,   4
                }

                Device (PRID)
                {
                    Name (_ADR, 0x00)  // _ADR: Address
                    Method (_GTM, 0, NotSerialized)  // _GTM: Get Timing Mode
                    {
                        Name (PBUF, Buffer (0x14)
                        {
                            /* 0000 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  /* ........ */
                            /* 0008 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  /* ........ */
                            /* 0010 */  0x00, 0x00, 0x00, 0x00                           /* .... */
                        })
                        CreateDWordField (PBUF, 0x00, PIO0)
                        CreateDWordField (PBUF, 0x04, DMA0)
                        CreateDWordField (PBUF, 0x08, PIO1)
                        CreateDWordField (PBUF, 0x0C, DMA1)
                        CreateDWordField (PBUF, 0x10, FLAG)
                        PIO0 = GETP (PRIT)
                        DMA0 = GDMA ((SYNC & 0x01), (ICR3 & 0x01), (
                            ICR0 & 0x01), SDT0, (ICR1 & 0x01))
                        If ((DMA0 == 0xFFFFFFFF))
                        {
                            DMA0 = PIO0 /* \_SB_.PCI0.PATA.PRID._GTM.PIO0 */
                        }

                        If ((PRIT & 0x4000))
                        {
                            If (((PRIT & 0x90) == 0x80))
                            {
                                PIO1 = 0x0384
                            }
                            Else
                            {
                                PIO1 = GETT (PSIT)
                            }
                        }
                        Else
                        {
                            PIO1 = 0xFFFFFFFF
                        }

                        DMA1 = GDMA ((SYNC & 0x02), (ICR3 & 0x02), (
                            ICR0 & 0x02), SDT1, (ICR1 & 0x02))
                        If ((DMA1 == 0xFFFFFFFF))
                        {
                            DMA1 = PIO1 /* \_SB_.PCI0.PATA.PRID._GTM.PIO1 */
                        }

                        FLAG = GETF ((SYNC & 0x01), (SYNC & 0x02), PRIT)
                        If (((PIO0 == 0xFFFFFFFF) & (DMA0 == 0xFFFFFFFF)))
                        {
                            PIO0 = 0x78
                            DMA0 = 0x14
                            FLAG = 0x03
                        }

                        Return (PBUF) /* \_SB_.PCI0.PATA.PRID._GTM.PBUF */
                    }

                    Method (_STM, 3, NotSerialized)  // _STM: Set Timing Mode
                    {
                        CreateDWordField (Arg0, 0x00, PIO0)
                        CreateDWordField (Arg0, 0x04, DMA0)
                        CreateDWordField (Arg0, 0x08, PIO1)
                        CreateDWordField (Arg0, 0x0C, DMA1)
                        CreateDWordField (Arg0, 0x10, FLAG)
                        If ((SizeOf (Arg1) == 0x0200))
                        {
                            PRIT &= 0xC0F0
                            SYNC &= 0x02
                            SDT0 = 0x00
                            ICR0 &= 0x02
                            ICR1 &= 0x02
                            ICR3 &= 0x02
                            ICR5 &= 0x02
                            CreateWordField (Arg1, 0x62, W490)
                            CreateWordField (Arg1, 0x6A, W530)
                            CreateWordField (Arg1, 0x7E, W630)
                            CreateWordField (Arg1, 0x80, W640)
                            CreateWordField (Arg1, 0xB0, W880)
                            CreateWordField (Arg1, 0xBA, W930)
                            PRIT |= 0x8004
                            If (((FLAG & 0x02) && (W490 & 0x0800)))
                            {
                                PRIT |= 0x02
                            }

                            PRIT |= SETP (PIO0, W530, W640)
                            If ((FLAG & 0x01))
                            {
                                SYNC |= 0x01
                                SDT0 = SDMA (DMA0)
                                If ((DMA0 < 0x1E))
                                {
                                    ICR3 |= 0x01
                                }

                                If ((DMA0 < 0x3C))
                                {
                                    ICR0 |= 0x01
                                }

                                If ((W930 & 0x2000))
                                {
                                    ICR1 |= 0x01
                                }
                            }
                        }

                        If ((SizeOf (Arg2) == 0x0200))
                        {
                            PRIT &= 0xBF0F
                            PSIT = 0x00
                            SYNC &= 0x01
                            SDT1 = 0x00
                            ICR0 &= 0x01
                            ICR1 &= 0x01
                            ICR3 &= 0x01
                            ICR5 &= 0x01
                            CreateWordField (Arg2, 0x62, W491)
                            CreateWordField (Arg2, 0x6A, W531)
                            CreateWordField (Arg2, 0x7E, W631)
                            CreateWordField (Arg2, 0x80, W641)
                            CreateWordField (Arg2, 0xB0, W881)
                            CreateWordField (Arg2, 0xBA, W931)
                            PRIT |= 0x8040
                            If (((FLAG & 0x08) && (W491 & 0x0800)))
                            {
                                PRIT |= 0x20
                            }

                            If ((FLAG & 0x10))
                            {
                                PRIT |= 0x4000
                                If ((PIO1 > 0xF0))
                                {
                                    PRIT |= 0x80
                                }
                                Else
                                {
                                    PRIT |= 0x10
                                    PSIT = SETT (PIO1, W531, W641)
                                }
                            }

                            If ((FLAG & 0x04))
                            {
                                SYNC |= 0x02
                                SDT1 = SDMA (DMA1)
                                If ((DMA1 < 0x1E))
                                {
                                    ICR3 |= 0x02
                                }

                                If ((DMA1 < 0x3C))
                                {
                                    ICR0 |= 0x02
                                }

                                If ((W931 & 0x2000))
                                {
                                    ICR1 |= 0x02
                                }
                            }
                        }
                    }

                    Device (P_D0)
                    {
                        Name (_ADR, 0x00)  // _ADR: Address
                        Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
                        {
                            Return ((SATD ^ 0x01))
                        }

                        Method (_GTF, 0, NotSerialized)  // _GTF: Get Task File
                        {
                            Name (PIB0, Buffer (0x0E)
                            {
                                /* 0000 */  0x03, 0x00, 0x00, 0x00, 0x00, 0xA0, 0xEF, 0x03,  /* ........ */
                                /* 0008 */  0x00, 0x00, 0x00, 0x00, 0xA0, 0xEF               /* ...... */
                            })
                            CreateByteField (PIB0, 0x01, PMD0)
                            CreateByteField (PIB0, 0x08, DMD0)
                            If ((PRIT & 0x02))
                            {
                                If (((PRIT & 0x09) == 0x08))
                                {
                                    PMD0 = 0x08
                                }
                                Else
                                {
                                    PMD0 = 0x0A
                                    Local0 = ((PRIT & 0x0300) >> 0x08)
                                    Local1 = ((PRIT & 0x3000) >> 0x0C)
                                    Local2 = (Local0 + Local1)
                                    If ((0x03 == Local2))
                                    {
                                        PMD0 = 0x0B
                                    }

                                    If ((0x05 == Local2))
                                    {
                                        PMD0 = 0x0C
                                    }
                                }
                            }
                            Else
                            {
                                PMD0 = 0x01
                            }

                            If ((SYNC & 0x01))
                            {
                                DMD0 = (SDT0 | 0x40)
                                If ((ICR1 & 0x01))
                                {
                                    If ((ICR0 & 0x01))
                                    {
                                        DMD0 += 0x02
                                    }

                                    If ((ICR3 & 0x01))
                                    {
                                        DMD0 = 0x45
                                    }
                                }
                            }
                            Else
                            {
                                DMD0 = (((PMD0 & 0x07) - 0x02) | 0x20)
                            }

                            Return (PIB0) /* \_SB_.PCI0.PATA.PRID.P_D0._GTF.PIB0 */
                        }
                    }

                    Device (P_D1)
                    {
                        Name (_ADR, 0x01)  // _ADR: Address
                        Method (_GTF, 0, NotSerialized)  // _GTF: Get Task File
                        {
                            Name (PIB1, Buffer (0x0E)
                            {
                                /* 0000 */  0x03, 0x00, 0x00, 0x00, 0x00, 0xB0, 0xEF, 0x03,  /* ........ */
                                /* 0008 */  0x00, 0x00, 0x00, 0x00, 0xB0, 0xEF               /* ...... */
                            })
                            CreateByteField (PIB1, 0x01, PMD1)
                            CreateByteField (PIB1, 0x08, DMD1)
                            If ((PRIT & 0x20))
                            {
                                If (((PRIT & 0x90) == 0x80))
                                {
                                    PMD1 = 0x08
                                }
                                Else
                                {
                                    Local0 = ((PSIT & 0x03) + ((PSIT & 0x0C) >> 0x02
                                        ))
                                    If ((0x05 == Local0))
                                    {
                                        PMD1 = 0x0C
                                    }
                                    ElseIf ((0x03 == Local0))
                                    {
                                        PMD1 = 0x0B
                                    }
                                    Else
                                    {
                                        PMD1 = 0x0A
                                    }
                                }
                            }
                            Else
                            {
                                PMD1 = 0x01
                            }

                            If ((SYNC & 0x02))
                            {
                                DMD1 = (SDT1 | 0x40)
                                If ((ICR1 & 0x02))
                                {
                                    If ((ICR0 & 0x02))
                                    {
                                        DMD1 += 0x02
                                    }

                                    If ((ICR3 & 0x02))
                                    {
                                        DMD1 = 0x45
                                    }
                                }
                            }
                            Else
                            {
                                DMD1 = (((PMD1 & 0x07) - 0x02) | 0x20)
                            }

                            Return (PIB1) /* \_SB_.PCI0.PATA.PRID.P_D1._GTF.PIB1 */
                        }
                    }
                }
            }

            Device (SATA)
            {
                Name (_ADR, 0x001F0002)  // _ADR: Address
                OperationRegion (SACS, PCI_Config, 0x40, 0xC0)
                Field (SACS, DWordAcc, NoLock, Preserve)
                {
                    PRIT,   16, 
                    SECT,   16, 
                    PSIT,   4, 
                    SSIT,   4, 
                    Offset (0x08), 
                    SYNC,   4, 
                    Offset (0x0A), 
                    SDT0,   2, 
                        ,   2, 
                    SDT1,   2, 
                    Offset (0x0B), 
                    SDT2,   2, 
                        ,   2, 
                    SDT3,   2, 
                    Offset (0x14), 
                    ICR0,   4, 
                    ICR1,   4, 
                    ICR2,   4, 
                    ICR3,   4, 
                    ICR4,   4, 
                    ICR5,   4, 
                    Offset (0x50), 
                    MAPV,   2
                }
            }

            Device (SBUS)
            {
                Name (_ADR, 0x001F0003)  // _ADR: Address
                OperationRegion (SMBP, PCI_Config, 0x40, 0xC0)
                Field (SMBP, DWordAcc, NoLock, Preserve)
                {
                        ,   2, 
                    I2CE,   1
                }

                OperationRegion (SMBE, PCI_Config, 0x04, 0x02)
                Field (SMBE, AnyAcc, NoLock, Preserve)
                {
                    IOSE,   1
                }

                OperationRegion (SMBI, SystemIO, 0xEFA0, 0x10)
                Field (SMBI, ByteAcc, NoLock, Preserve)
                {
                    HSTS,   8, 
                    Offset (0x02), 
                    HCON,   8, 
                    HCOM,   8, 
                    TXSA,   8, 
                    DAT0,   8, 
                    DAT1,   8, 
                    HBDR,   8, 
                    PECR,   8, 
                    RXSA,   8, 
                    SDAT,   16
                }

                Method (ENAB, 0, NotSerialized)
                {
                    IOSE = 0x01
                }

                Method (SSXB, 2, Serialized)
                {
                    If (STRT ())
                    {
                        Return (0x00)
                    }

                    I2CE = 0x00
                    HSTS = 0xBF
                    TXSA = Arg0
                    HCOM = Arg1
                    HCON = 0x48
                    If (COMP ())
                    {
                        HSTS |= 0xFF
                        Return (0x01)
                    }

                    Return (0x00)
                }

                Method (SRXB, 1, Serialized)
                {
                    If (STRT ())
                    {
                        Return (0xFFFF)
                    }

                    I2CE = 0x00
                    HSTS = 0xBF
                    TXSA = (Arg0 | 0x01)
                    HCON = 0x44
                    If (COMP ())
                    {
                        HSTS |= 0xFF
                        Return (DAT0) /* \_SB_.PCI0.SBUS.DAT0 */
                    }

                    Return (0xFFFF)
                }

                Method (SWRB, 3, Serialized)
                {
                    If (STRT ())
                    {
                        Return (0x00)
                    }

                    I2CE = 0x00
                    HSTS = 0xBF
                    TXSA = Arg0
                    HCOM = Arg1
                    DAT0 = Arg2
                    HCON = 0x48
                    If (COMP ())
                    {
                        HSTS |= 0xFF
                        Return (0x01)
                    }

                    Return (0x00)
                }

                Method (SRDB, 2, Serialized)
                {
                    If (STRT ())
                    {
                        Return (0xFFFF)
                    }

                    I2CE = 0x00
                    HSTS = 0xBF
                    TXSA = (Arg0 | 0x01)
                    HCOM = Arg1
                    HCON = 0x48
                    If (COMP ())
                    {
                        HSTS |= 0xFF
                        Return (DAT0) /* \_SB_.PCI0.SBUS.DAT0 */
                    }

                    Return (0xFFFF)
                }

                Method (SBLW, 4, Serialized)
                {
                    If (STRT ())
                    {
                        Return (0x00)
                    }

                    I2CE = Arg3
                    HSTS = 0xBF
                    TXSA = Arg0
                    HCOM = Arg1
                    DAT0 = SizeOf (Arg2)
                    Local1 = 0x00
                    HBDR = DerefOf (Arg2 [0x00])
                    HCON = 0x54
                    While ((SizeOf (Arg2) > Local1))
                    {
                        Local0 = 0x0FA0
                        While ((!(HSTS & 0x80) && Local0))
                        {
                            Local0--
                            Stall (0x32)
                        }

                        If (!Local0)
                        {
                            KILL ()
                            Return (0x00)
                        }

                        HSTS = 0x80
                        Local1++
                        If ((SizeOf (Arg2) > Local1))
                        {
                            HBDR = DerefOf (Arg2 [Local1])
                        }
                    }

                    If (COMP ())
                    {
                        HSTS |= 0xFF
                        Return (0x01)
                    }

                    Return (0x00)
                }

                Method (SBLR, 3, Serialized)
                {
                    Name (TBUF, Buffer (0x0100) {})
                    If (STRT ())
                    {
                        Return (0x00)
                    }

                    I2CE = Arg2
                    HSTS = 0xBF
                    TXSA = (Arg0 | 0x01)
                    HCOM = Arg1
                    HCON = 0x54
                    Local0 = 0x0FA0
                    While ((!(HSTS & 0x80) && Local0))
                    {
                        Local0--
                        Stall (0x32)
                    }

                    If (!Local0)
                    {
                        KILL ()
                        Return (0x00)
                    }

                    TBUF [0x00] = DAT0 /* \_SB_.PCI0.SBUS.DAT0 */
                    HSTS = 0x80
                    Local1 = 0x01
                    While ((Local1 < DerefOf (TBUF [0x00])))
                    {
                        Local0 = 0x0FA0
                        While ((!(HSTS & 0x80) && Local0))
                        {
                            Local0--
                            Stall (0x32)
                        }

                        If (!Local0)
                        {
                            KILL ()
                            Return (0x00)
                        }

                        TBUF [Local1] = HBDR /* \_SB_.PCI0.SBUS.HBDR */
                        HSTS = 0x80
                        Local1++
                    }

                    If (COMP ())
                    {
                        HSTS |= 0xFF
                        Return (TBUF) /* \_SB_.PCI0.SBUS.SBLR.TBUF */
                    }

                    Return (0x00)
                }

                Method (STRT, 0, Serialized)
                {
                    Local0 = 0xC8
                    While (Local0)
                    {
                        If ((HSTS & 0x40))
                        {
                            Local0--
                            Sleep (0x01)
                            If ((Local0 == 0x00))
                            {
                                Return (0x01)
                            }
                        }
                        Else
                        {
                            Local0 = 0x00
                        }
                    }

                    Local0 = 0x0FA0
                    While (Local0)
                    {
                        If ((HSTS & 0x01))
                        {
                            Local0--
                            Stall (0x32)
                            If ((Local0 == 0x00))
                            {
                                KILL ()
                            }
                        }
                        Else
                        {
                            Return (0x00)
                        }
                    }

                    Return (0x01)
                }

                Method (COMP, 0, Serialized)
                {
                    Local0 = 0x0FA0
                    While (Local0)
                    {
                        If ((HSTS & 0x02))
                        {
                            Return (0x01)
                        }
                        Else
                        {
                            Local0--
                            Stall (0x32)
                            If ((Local0 == 0x00))
                            {
                                KILL ()
                            }
                        }
                    }

                    Return (0x00)
                }

                Method (KILL, 0, Serialized)
                {
                    HCON |= 0x02
                    HSTS |= 0xFF
                }
            }
        }
    }
}

