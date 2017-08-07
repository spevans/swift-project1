/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160108-64
 * Copyright (c) 2000 - 2016 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of SSDT4.aml, Sun Apr 30 09:56:03 2017
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x000000A6 (166)
 *     Revision         0x01
 *     Checksum         0xE4
 *     OEM ID           "APPLE"
 *     OEM Table ID     "Cpu1Tst"
 *     OEM Revision     0x00003000 (12288)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20061109 (537268489)
 */
DefinitionBlock ("SSDT4.aml", "SSDT", 1, "APPLE", "Cpu1Tst", 0x00003000)
{

    External (_PR_.CPU0._PTC, IntObj)
    External (_PR_.CPU0._TSS, IntObj)
    External (_PR_.CPU1, DeviceObj)
    External (CFGD, UnknownObj)
    External (PDC1, UnknownObj)

    Scope (\_PR.CPU1)
    {
        Name (_TPC, 0x00)  // _TPC: Throttling Present Capabilities
        Method (_PTC, 0, NotSerialized)  // _PTC: Processor Throttling Control
        {
            Return (\_PR.CPU0._PTC) /* External reference */
        }

        Method (_TSS, 0, NotSerialized)  // _TSS: Throttling Supported States
        {
            Return (\_PR.CPU0._TSS) /* External reference */
        }

        Method (_TSD, 0, NotSerialized)  // _TSD: Throttling State Dependencies
        {
            If (((CFGD & 0x01000000) && !(PDC1 & 0x04)))
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
                    0x01, 
                    0xFC, 
                    0x01
                }
            })
        }
    }
}

