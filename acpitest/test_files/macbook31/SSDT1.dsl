/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160108-64
 * Copyright (c) 2000 - 2016 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of SSDT1.aml, Sun Apr 30 09:56:03 2017
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00000137 (311)
 *     Revision         0x01
 *     Checksum         0x89
 *     OEM ID           "APPLE "
 *     OEM Table ID     "SataAhci"
 *     OEM Revision     0x00001000 (4096)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20061109 (537268489)
 */
DefinitionBlock ("SSDT1.aml", "SSDT", 1, "APPLE ", "SataAhci", 0x00001000)
{

    External (_SB_.PCI0.SATA, DeviceObj)
    External (GP27, UnknownObj)
    External (GTF0, IntObj)

    Scope (\_SB.PCI0.SATA)
    {
        Device (PRT0)
        {
            Name (_ADR, 0xFFFF)  // _ADR: Address
            Method (_SDD, 1, NotSerialized)  // _SDD: Set Device Data
            {
                Name (GBU0, Buffer (0x07)
                {
                     0x00, 0x00, 0x00, 0x00, 0x00, 0xA0, 0x00         /* ....... */
                })
                CreateByteField (GBU0, 0x00, GB00)
                CreateByteField (GBU0, 0x01, GB01)
                CreateByteField (GBU0, 0x02, GB02)
                CreateByteField (GBU0, 0x03, GB03)
                CreateByteField (GBU0, 0x04, GB04)
                CreateByteField (GBU0, 0x05, GB05)
                CreateByteField (GBU0, 0x06, GB06)
                If ((SizeOf (Arg0) == 0x0200))
                {
                    CreateWordField (Arg0, 0x9C, W780)
                    If ((W780 & 0x08))
                    {
                        GB00 = 0x10
                        GB01 = 0x03
                        GB06 = 0xEF
                    }
                    Else
                    {
                        GB00 = 0x90
                        GB01 = 0x03
                        GB06 = 0xEF
                    }
                }

                GTF0 = GBU0 /* \_SB_.PCI0.SATA.PRT0._SDD.GBU0 */
            }

            Method (_GTF, 0, NotSerialized)  // _GTF: Get Task File
            {
                Return (GTF0) /* External reference */
            }

            Method (_PS0, 0, Serialized)  // _PS0: Power State 0
            {
                GP27 = 0x00
            }

            Method (_PS3, 0, Serialized)  // _PS3: Power State 3
            {
                GP27 = 0x01
            }

            Method (_PSC, 0, Serialized)  // _PSC: Power State Current
            {
                If (!GP27)
                {
                    Return (0x00)
                }

                Return (0x03)
            }
        }
    }
}

