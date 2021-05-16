/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160108-64
 * Copyright (c) 2000 - 2016 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of SSDT3.aml, Sun Apr 30 09:56:03 2017
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x0000025F (607)
 *     Revision         0x01
 *     Checksum         0x57
 *     OEM ID           "APPLE"
 *     OEM Table ID     "Cpu0Tst"
 *     OEM Revision     0x00003000 (12288)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20061109 (537268489)
 */
DefinitionBlock ("SSDT3.aml", "SSDT", 1, "APPLE", "Cpu0Tst", 0x00003000)
{

    External (_PR_.CPU0, DeviceObj)
    External (_PSS, IntObj)
    External (CFGD, UnknownObj)
    External (PDC0, UnknownObj)

    Scope (\_PR.CPU0)
    {
        Name (_TPC, 0x00)  // _TPC: Throttling Present Capabilities
        Method (_PTC, 0, NotSerialized)  // _PTC: Processor Throttling Control
        {
            If ((PDC0 & 0x04))
            {
                Return (Package (0x02)
                {
                    ResourceTemplate ()
                    {
                        Register (FFixedHW, 
                            0x00,               // Bit Width
                            0x00,               // Bit Offset
                            0x0000000000000000, // Address
                            ,)
                    }, 

                    ResourceTemplate ()
                    {
                        Register (FFixedHW, 
                            0x00,               // Bit Width
                            0x00,               // Bit Offset
                            0x0000000000000000, // Address
                            ,)
                    }
                })
            }

            Return (Package (0x02)
            {
                ResourceTemplate ()
                {
                    Register (SystemIO, 
                        0x04,               // Bit Width
                        0x01,               // Bit Offset
                        0x0000000000000410, // Address
                        ,)
                }, 

                ResourceTemplate ()
                {
                    Register (SystemIO, 
                        0x04,               // Bit Width
                        0x01,               // Bit Offset
                        0x0000000000000410, // Address
                        ,)
                }
            })
        }

        Name (TSSI, Package (0x08)
        {
            Package (0x05)
            {
                0x64, 
                0x03E8, 
                0x00, 
                0x00, 
                0x00
            }, 

            Package (0x05)
            {
                0x58, 
                0x036B, 
                0x00, 
                0x0F, 
                0x00
            }, 

            Package (0x05)
            {
                0x4B, 
                0x02EE, 
                0x00, 
                0x0E, 
                0x00
            }, 

            Package (0x05)
            {
                0x3F, 
                0x0271, 
                0x00, 
                0x0D, 
                0x00
            }, 

            Package (0x05)
            {
                0x32, 
                0x01F4, 
                0x00, 
                0x0C, 
                0x00
            }, 

            Package (0x05)
            {
                0x26, 
                0x0177, 
                0x00, 
                0x0B, 
                0x00
            }, 

            Package (0x05)
            {
                0x19, 
                0xFA, 
                0x00, 
                0x0A, 
                0x00
            }, 

            Package (0x05)
            {
                0x0D, 
                0x7D, 
                0x00, 
                0x09, 
                0x00
            }
        })
        Name (TSSM, Package (0x08)
        {
            Package (0x05)
            {
                0x64, 
                0x03E8, 
                0x00, 
                0x00, 
                0x00
            }, 

            Package (0x05)
            {
                0x58, 
                0x036B, 
                0x00, 
                0x1E, 
                0x00
            }, 

            Package (0x05)
            {
                0x4B, 
                0x02EE, 
                0x00, 
                0x1C, 
                0x00
            }, 

            Package (0x05)
            {
                0x3F, 
                0x0271, 
                0x00, 
                0x1A, 
                0x00
            }, 

            Package (0x05)
            {
                0x32, 
                0x01F4, 
                0x00, 
                0x18, 
                0x00
            }, 

            Package (0x05)
            {
                0x26, 
                0x0177, 
                0x00, 
                0x16, 
                0x00
            }, 

            Package (0x05)
            {
                0x19, 
                0xFA, 
                0x00, 
                0x14, 
                0x00
            }, 

            Package (0x05)
            {
                0x0D, 
                0x7D, 
                0x00, 
                0x12, 
                0x00
            }
        })
        Name (TSSF, 0x00)
        Method (_TSS, 0, NotSerialized)  // _TSS: Throttling Supported States
        {
            If ((!TSSF && CondRefOf (_PSS)))
            {
                Local0 = _PSS /* External reference */
                Local1 = SizeOf (Local0)
                Local1--
                Local2 = DerefOf (DerefOf (Local0 [Local1]) [0x01])
                Local3 = 0x00
                While ((Local3 < SizeOf (TSSI)))
                {
                    Local4 = ((Local2 * (0x08 - Local3)) / 0x08)
                    DerefOf (TSSI [Local3]) [0x01] = Local4
                    DerefOf (TSSM [Local3]) [0x01] = Local4
                    Local3++
                }

                TSSF = Ones
            }

            If ((PDC0 & 0x04))
            {
                Return (TSSM) /* \_PR_.CPU0.TSSM */
            }

            Return (TSSI) /* \_PR_.CPU0.TSSI */
        }

        Method (_TSD, 0, NotSerialized)  // _TSD: Throttling State Dependencies
        {
            If (((CFGD & 0x01000000) && !(PDC0 & 0x04)))
            {
                Return (Package (0x01)
                {
                    Package (0x05)
                    {
                        0x05, 
                        0x00, 
                        0x00, 
                        0xFD, 
                        0x02
                    }
                })
            }

            Return (Package (0x01)
            {
                Package (0x05)
                {
                    0x05, 
                    0x00, 
                    0x00, 
                    0xFC, 
                    0x01
                }
            })
        }
    }
}

