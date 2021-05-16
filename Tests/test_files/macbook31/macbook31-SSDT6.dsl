/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160108-64
 * Copyright (c) 2000 - 2016 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of SSDT6.aml, Sun Apr 30 09:56:03 2017
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00000222 (546)
 *     Revision         0x01
 *     Checksum         0xE0
 *     OEM ID           "APPLE"
 *     OEM Table ID     "Cpu0Cst"
 *     OEM Revision     0x00003001 (12289)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20061109 (537268489)
 */
DefinitionBlock ("SSDT6.aml", "SSDT", 1, "APPLE", "Cpu0Cst", 0x00003001)
{

    External (_PR_.CPU0, DeviceObj)
    External (CFGD, UnknownObj)
    External (PDC0, UnknownObj)

    Scope (\_PR.CPU0)
    {
        Method (_CST, 0, NotSerialized)  // _CST: C-States
        {
            If (((CFGD & 0x01000000) && !(PDC0 & 0x10)))
            {
                Return (Package (0x02)
                {
                    0x01, 
                    Package (0x04)
                    {
                        ResourceTemplate ()
                        {
                            Register (FFixedHW, 
                                0x00,               // Bit Width
                                0x00,               // Bit Offset
                                0x0000000000000000, // Address
                                ,)
                        }, 

                        0x01, 
                        0x9D, 
                        0x03E8
                    }
                })
            }

            If ((PDC0 & 0x0300))
            {
                If ((CFGD & 0x80))
                {
                    Return (Package (0x04)
                    {
                        0x03, 
                        Package (0x04)
                        {
                            ResourceTemplate ()
                            {
                                Register (FFixedHW, 
                                    0x01,               // Bit Width
                                    0x02,               // Bit Offset
                                    0x0000000000000000, // Address
                                    ,)
                            }, 

                            0x01, 
                            0x01, 
                            0x03E8
                        }, 

                        Package (0x04)
                        {
                            ResourceTemplate ()
                            {
                                Register (FFixedHW, 
                                    0x01,               // Bit Width
                                    0x02,               // Bit Offset
                                    0x0000000000000010, // Address
                                    ,)
                            }, 

                            0x02, 
                            0x01, 
                            0x01F4
                        }, 

                        Package (0x04)
                        {
                            ResourceTemplate ()
                            {
                                Register (FFixedHW, 
                                    0x01,               // Bit Width
                                    0x02,               // Bit Offset
                                    0x0000000000000031, // Address
                                    0x03,               // Access Size
                                    )
                            }, 

                            0x03, 
                            0x39, 
                            0x64
                        }
                    })
                }

                If ((CFGD & 0x20))
                {
                    Return (Package (0x03)
                    {
                        0x02, 
                        Package (0x04)
                        {
                            ResourceTemplate ()
                            {
                                Register (FFixedHW, 
                                    0x01,               // Bit Width
                                    0x02,               // Bit Offset
                                    0x0000000000000000, // Address
                                    ,)
                            }, 

                            0x01, 
                            0x01, 
                            0x03E8
                        }, 

                        Package (0x04)
                        {
                            ResourceTemplate ()
                            {
                                Register (FFixedHW, 
                                    0x01,               // Bit Width
                                    0x02,               // Bit Offset
                                    0x0000000000000010, // Address
                                    ,)
                            }, 

                            0x02, 
                            0x01, 
                            0x01F4
                        }
                    })
                }
            }

            If ((CFGD & 0x80))
            {
                Return (Package (0x04)
                {
                    0x03, 
                    Package (0x04)
                    {
                        ResourceTemplate ()
                        {
                            Register (FFixedHW, 
                                0x00,               // Bit Width
                                0x00,               // Bit Offset
                                0x0000000000000000, // Address
                                ,)
                        }, 

                        0x01, 
                        0x01, 
                        0x03E8
                    }, 

                    Package (0x04)
                    {
                        ResourceTemplate ()
                        {
                            Register (SystemIO, 
                                0x08,               // Bit Width
                                0x00,               // Bit Offset
                                0x0000000000000414, // Address
                                ,)
                        }, 

                        0x02, 
                        0x01, 
                        0x01F4
                    }, 

                    Package (0x04)
                    {
                        ResourceTemplate ()
                        {
                            Register (SystemIO, 
                                0x08,               // Bit Width
                                0x00,               // Bit Offset
                                0x0000000000000416, // Address
                                ,)
                        }, 

                        0x03, 
                        0x39, 
                        0x64
                    }
                })
            }

            If ((CFGD & 0x20))
            {
                Return (Package (0x03)
                {
                    0x02, 
                    Package (0x04)
                    {
                        ResourceTemplate ()
                        {
                            Register (FFixedHW, 
                                0x00,               // Bit Width
                                0x00,               // Bit Offset
                                0x0000000000000000, // Address
                                ,)
                        }, 

                        0x01, 
                        0x01, 
                        0x03E8
                    }, 

                    Package (0x04)
                    {
                        ResourceTemplate ()
                        {
                            Register (SystemIO, 
                                0x08,               // Bit Width
                                0x00,               // Bit Offset
                                0x0000000000000414, // Address
                                ,)
                        }, 

                        0x02, 
                        0x01, 
                        0x01F4
                    }
                })
            }

            Return (Package (0x02)
            {
                0x01, 
                Package (0x04)
                {
                    ResourceTemplate ()
                    {
                        Register (FFixedHW, 
                            0x00,               // Bit Width
                            0x00,               // Bit Offset
                            0x0000000000000000, // Address
                            ,)
                    }, 

                    0x01, 
                    0x01, 
                    0x03E8
                }
            })
        }
    }
}

