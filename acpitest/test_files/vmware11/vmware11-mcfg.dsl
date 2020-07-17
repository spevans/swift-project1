/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20180105 (64-bit version)
 * Copyright (c) 2000 - 2018 Intel Corporation
 * 
 * Disassembly of mcfg.dat, Fri Jul 17 14:13:23 2020
 *
 * ACPI Data Table [MCFG]
 *
 * Format: [HexOffset DecimalOffset ByteLength]  FieldName : FieldValue
 */

[000h 0000   4]                    Signature : "MCFG"    [Memory Mapped Configuration table]
[004h 0004   4]                 Table Length : 0000003C
[008h 0008   1]                     Revision : 01
[009h 0009   1]                     Checksum : 6A
[00Ah 0010   6]                       Oem ID : "VMWARE"
[010h 0016   8]                 Oem Table ID : "EFIMCFG "
[018h 0024   4]                 Oem Revision : 06040001
[01Ch 0028   4]              Asl Compiler ID : "VMW "
[020h 0032   4]        Asl Compiler Revision : 000007CE

[024h 0036   8]                     Reserved : 0000000000000000

[02Ch 0044   8]                 Base Address : 00000000E0000000
[034h 0052   2]         Segment Group Number : 0000
[036h 0054   1]             Start Bus Number : 00
[037h 0055   1]               End Bus Number : 7F
[038h 0056   4]                     Reserved : 00000000

Raw Table Data: Length 60 (0x3C)

  0000: 4D 43 46 47 3C 00 00 00 01 6A 56 4D 57 41 52 45  // MCFG<....jVMWARE
  0010: 45 46 49 4D 43 46 47 20 01 00 04 06 56 4D 57 20  // EFIMCFG ....VMW 
  0020: CE 07 00 00 00 00 00 00 00 00 00 00 00 00 00 E0  // ................
  0030: 00 00 00 00 00 00 00 7F 00 00 00 00              // ............
