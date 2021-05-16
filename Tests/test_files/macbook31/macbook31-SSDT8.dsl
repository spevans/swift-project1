/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160108-64
 * Copyright (c) 2000 - 2016 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of SSDT8.aml, Sun Apr 30 09:56:03 2017
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00000085 (133)
 *     Revision         0x01
 *     Checksum         0xF1
 *     OEM ID           "APPLE"
 *     OEM Table ID     "Cpu1Cst"
 *     OEM Revision     0x00003000 (12288)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20061109 (537268489)
 */
DefinitionBlock ("SSDT8.aml", "SSDT", 1, "APPLE", "Cpu1Cst", 0x00003000)
{

    External (_PR_.CPU0._CST, IntObj)
    External (_PR_.CPU1, DeviceObj)
    External (CFGD, UnknownObj)
    External (PDC1, UnknownObj)

    Scope (\_PR.CPU1)
    {
        Method (_CST, 0, NotSerialized)  // _CST: C-States
        {
            If (((CFGD & 0x01000000) && !(PDC1 & 0x10)))
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

            Return (\_PR.CPU0._CST) /* External reference */
        }
    }
}

