/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160108-64
 * Copyright (c) 2000 - 2016 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of SSDT5.aml, Sun Apr 30 09:56:03 2017
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x000002FE (766)
 *     Revision         0x01
 *     Checksum         0xDD
 *     OEM ID           "APPLE"
 *     OEM Table ID     "Cpu0Ist"
 *     OEM Revision     0x00003000 (12288)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20061109 (537268489)
 */
DefinitionBlock ("SSDT5.aml", "SSDT", 1, "APPLE", "Cpu0Ist", 0x00003000)
{

    External (_PR_.CPU0, DeviceObj)
    External (CFGD, UnknownObj)
    External (NPSS, IntObj)
    External (PDC0, UnknownObj)

    Scope (\_PR.CPU0)
    {
        Name (_PPC, 0x00)  // _PPC: Performance Present Capabilities
        Method (_PCT, 0, NotSerialized)  // _PCT: Performance Control
        {
            If (((CFGD & 0x01) && (PDC0 & 0x01)))
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
                        0x10,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000000800, // Address
                        ,)
                }, 

                ResourceTemplate ()
                {
                    Register (SystemIO, 
                        0x08,               // Bit Width
                        0x00,               // Bit Offset
                        0x00000000000000B3, // Address
                        ,)
                }
            })
        }

        Method (XPSS, 0, NotSerialized)
        {
            If ((PDC0 & 0x01))
            {
                Return (NPSS) /* External reference */
            }

            Return (SPSS) /* \_PR_.CPU0.SPSS */
        }

        Name (SPSS, Package (0x07)
        {
            Package (0x06)
            {
                0x00000898, 
                0x000088B8, 
                0x0000006E, 
                0x0000000A, 
                0x00000083, 
                0x00000000
            }, 

            Package (0x06)
            {
                0x000007D0, 
                0x000079E0, 
                0x0000006E, 
                0x0000000A, 
                0x00000183, 
                0x00000001
            }, 

            Package (0x06)
            {
                0x00000708, 
                0x00006B08, 
                0x0000006E, 
                0x0000000A, 
                0x00000283, 
                0x00000002
            }, 

            Package (0x06)
            {
                0x00000640, 
                0x00005C30, 
                0x0000006E, 
                0x0000000A, 
                0x00000383, 
                0x00000003
            }, 

            Package (0x06)
            {
                0x00000578, 
                0x00004D58, 
                0x0000006E, 
                0x0000000A, 
                0x00000483, 
                0x00000004
            }, 

            Package (0x06)
            {
                0x000004B0, 
                0x00003E80, 
                0x0000006E, 
                0x0000000A, 
                0x00000583, 
                0x00000005
            }, 

            Package (0x06)
            {
                0x00000320, 
                0x000036B0, 
                0x0000006E, 
                0x0000000A, 
                0x00000683, 
                0x00000006
            }
        })
        Name (_PSS, Package (0x07)  // _PSS: Performance Supported States
        {
            Package (0x06)
            {
                0x00000898, 
                0x000088B8, 
                0x0000000A, 
                0x0000000A, 
                0x00000B2B, 
                0x00000B2B
            }, 

            Package (0x06)
            {
                0x000007D0, 
                0x000079E0, 
                0x0000000A, 
                0x0000000A, 
                0x00000A26, 
                0x00000A26
            }, 

            Package (0x06)
            {
                0x00000708, 
                0x00006B08, 
                0x0000000A, 
                0x0000000A, 
                0x00000921, 
                0x00000921
            }, 

            Package (0x06)
            {
                0x00000640, 
                0x00005C30, 
                0x0000000A, 
                0x0000000A, 
                0x0000081C, 
                0x0000081C
            }, 

            Package (0x06)
            {
                0x00000578, 
                0x00004D58, 
                0x0000000A, 
                0x0000000A, 
                0x00000717, 
                0x00000717
            }, 

            Package (0x06)
            {
                0x000004B0, 
                0x00003E80, 
                0x0000000A, 
                0x0000000A, 
                0x00000612, 
                0x00000612
            }, 

            Package (0x06)
            {
                0x00000320, 
                0x000036B0, 
                0x0000000A, 
                0x0000000A, 
                0x0000880B, 
                0x0000880B
            }
        })
        Method (_PSD, 0, NotSerialized)  // _PSD: Power State Dependencies
        {
            If ((CFGD & 0x01000000))
            {
                If ((PDC0 & 0x0800))
                {
                    Return (Package (0x01)
                    {
                        Package (0x05)
                        {
                            0x05, 
                            0x00, 
                            0x00, 
                            0xFE, 
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

