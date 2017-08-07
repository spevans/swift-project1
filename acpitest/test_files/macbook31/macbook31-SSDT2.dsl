/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160108-64
 * Copyright (c) 2000 - 2016 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of SSDT2.aml, Sun Apr 30 09:56:03 2017
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x000004DC (1244)
 *     Revision         0x01
 *     Checksum         0xBE
 *     OEM ID           "APPLE"
 *     OEM Table ID     "CpuPm"
 *     OEM Revision     0x00003000 (12288)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20061109 (537268489)
 */
DefinitionBlock ("SSDT2.aml", "SSDT", 1, "APPLE", "CpuPm", 0x00003000)
{

    External (_PR_.CPU0, DeviceObj)
    External (_PR_.CPU1, DeviceObj)

    Scope (\)
    {
        Name (SSDT, Package (0x0C)
        {
            "CPU0IST ", 
            0xBEEC9A98, 
            0x000002FE, 
            "CPU1IST ", 
            0xBEEC8F18, 
            0x000000C8, 
            "CPU0CST ", 
            0xBEEC7C98, 
            0x00000222, 
            "CPU1CST ", 
            0xBEEC7F18, 
            0x00000085
        })
        Name (CFGD, 0x1D3B69F1)
        Name (\PDC0, 0x80000000)
        Name (\PDC1, 0x80000000)
        Name (\SDTL, 0x00)
    }

    Scope (\_PR.CPU0)
    {
        Name (HI0, 0x00)
        Name (HC0, 0x00)
        Method (_PDC, 1, NotSerialized)  // _PDC: Processor Driver Capabilities
        {
            CreateDWordField (Arg0, 0x00, REVS)
            CreateDWordField (Arg0, 0x04, SIZE)
            Local0 = SizeOf (Arg0)
            Local1 = (Local0 - 0x08)
            CreateField (Arg0, 0x40, (Local1 * 0x08), TEMP)
            Name (STS0, Buffer (0x04)
            {
                 0x00, 0x00, 0x00, 0x00                           /* .... */
            })
            Concatenate (STS0, TEMP, Local2)
            _OSC (ToUUID ("4077a616-290c-47be-9ebd-d87058713953"), REVS, SIZE, Local2)
        }

        Method (_OSC, 4, NotSerialized)  // _OSC: Operating System Capabilities
        {
            CreateDWordField (Arg3, 0x00, STS0)
            CreateDWordField (Arg3, 0x04, CAP0)
            CreateDWordField (Arg0, 0x00, IID0)
            CreateDWordField (Arg0, 0x04, IID1)
            CreateDWordField (Arg0, 0x08, IID2)
            CreateDWordField (Arg0, 0x0C, IID3)
            Name (UID0, ToUUID ("4077a616-290c-47be-9ebd-d87058713953"))
            CreateDWordField (UID0, 0x00, EID0)
            CreateDWordField (UID0, 0x04, EID1)
            CreateDWordField (UID0, 0x08, EID2)
            CreateDWordField (UID0, 0x0C, EID3)
            If (!(((IID0 == EID0) && (IID1 == EID1)) && ((
                IID2 == EID2) && (IID3 == EID3))))
            {
                STS0 [0x00] = 0x06
                Return (Arg3)
            }

            If ((Arg1 != 0x01))
            {
                STS0 [0x00] = 0x0A
                Return (Arg3)
            }

            PDC0 = ((PDC0 & 0x7FFFFFFF) | CAP0) /* \_PR_.CPU0._OSC.CAP0 */
            If ((CFGD & 0x01))
            {
                If ((((CFGD & 0x01000000) && ((PDC0 & 0x09) == 
                    0x09)) && !(SDTL & 0x01)))
                {
                    SDTL |= 0x01
                    OperationRegion (IST0, SystemMemory, DerefOf (SSDT [0x01]), DerefOf (SSDT [0x02]))
                    Load (IST0, HI0) /* \_PR_.CPU0.HI0_ */
                }
            }

            If ((CFGD & 0xF0))
            {
                If ((((CFGD & 0x01000000) && (PDC0 & 0x18)) && !
                    (SDTL & 0x02)))
                {
                    SDTL |= 0x02
                    OperationRegion (CST0, SystemMemory, DerefOf (SSDT [0x07]), DerefOf (SSDT [0x08]))
                    Load (CST0, HC0) /* \_PR_.CPU0.HC0_ */
                }
            }

            Return (Arg3)
        }
    }

    Scope (\_PR.CPU1)
    {
        Name (HI1, 0x00)
        Name (HC1, 0x00)
        Method (_PDC, 1, NotSerialized)  // _PDC: Processor Driver Capabilities
        {
            CreateDWordField (Arg0, 0x00, REVS)
            CreateDWordField (Arg0, 0x04, SIZE)
            Local0 = SizeOf (Arg0)
            Local1 = (Local0 - 0x08)
            CreateField (Arg0, 0x40, (Local1 * 0x08), TEMP)
            Name (STS1, Buffer (0x04)
            {
                 0x00, 0x00, 0x00, 0x00                           /* .... */
            })
            Concatenate (STS1, TEMP, Local2)
            _OSC (ToUUID ("4077a616-290c-47be-9ebd-d87058713953"), REVS, SIZE, Local2)
        }

        Method (_OSC, 4, NotSerialized)  // _OSC: Operating System Capabilities
        {
            CreateDWordField (Arg3, 0x00, STS1)
            CreateDWordField (Arg3, 0x04, CAP1)
            CreateDWordField (Arg0, 0x00, IID0)
            CreateDWordField (Arg0, 0x04, IID1)
            CreateDWordField (Arg0, 0x08, IID2)
            CreateDWordField (Arg0, 0x0C, IID3)
            Name (UID1, ToUUID ("4077a616-290c-47be-9ebd-d87058713953"))
            CreateDWordField (UID1, 0x00, EID0)
            CreateDWordField (UID1, 0x04, EID1)
            CreateDWordField (UID1, 0x08, EID2)
            CreateDWordField (UID1, 0x0C, EID3)
            If (!(((IID0 == EID0) && (IID1 == EID1)) && ((
                IID2 == EID2) && (IID3 == EID3))))
            {
                STS1 [0x00] = 0x06
                Return (Arg3)
            }

            If ((Arg1 != 0x01))
            {
                STS1 [0x00] = 0x0A
                Return (Arg3)
            }

            PDC1 = ((PDC1 & 0x7FFFFFFF) | CAP1) /* \_PR_.CPU1._OSC.CAP1 */
            If ((CFGD & 0x01))
            {
                If ((((CFGD & 0x01000000) && ((PDC1 & 0x09) == 
                    0x09)) && !(SDTL & 0x10)))
                {
                    SDTL |= 0x10
                    OperationRegion (IST1, SystemMemory, DerefOf (SSDT [0x04]), DerefOf (SSDT [0x05]))
                    Load (IST1, HI1) /* \_PR_.CPU1.HI1_ */
                }
            }

            If ((CFGD & 0xF0))
            {
                If ((((CFGD & 0x01000000) && (PDC1 & 0x18)) && !
                    (SDTL & 0x20)))
                {
                    SDTL |= 0x20
                    OperationRegion (CST1, SystemMemory, DerefOf (SSDT [0x0A]), DerefOf (SSDT [0x0B]))
                    Load (CST1, HC1) /* \_PR_.CPU1.HC1_ */
                }
            }

            Return (Arg3)
        }
    }
}

