/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160108-64
 * Copyright (c) 2000 - 2016 Intel Corporation
 * 
 * Disassembly of MCFG.aml, Sat Apr 29 16:39:43 2017
 *
 * ACPI Data Table [MCFG]
 *
 * Format: [HexOffset DecimalOffset ByteLength]  FieldName : FieldValue
 */

[000h 0000   4]                    Signature : "MCFG"    [Memory Mapped Configuration table]
[004h 0004   4]                 Table Length : 0000003C
[008h 0008   1]                     Revision : 01
[009h 0009   1]                     Checksum : 6E
[00Ah 0010   6]                       Oem ID : "PTLTD "
[010h 0016   8]                 Oem Table ID : "$PCITBL$"
[018h 0024   4]                 Oem Revision : 06040000
[01Ch 0028   4]              Asl Compiler ID : " LTP"
[020h 0032   4]        Asl Compiler Revision : 00000001

[024h 0036   8]                     Reserved : 0000000000000000

[02Ch 0044   8]                 Base Address : 00000000F0000000
[034h 0052   2]         Segment Group Number : 0000
[036h 0054   1]             Start Bus Number : 00
[037h 0055   1]               End Bus Number : 7F
[038h 0056   4]                     Reserved : 00000000

Raw Table Data: Length 60 (0x3C)

  0000: 4D 43 46 47 3C 00 00 00 01 6E 50 54 4C 54 44 20  // MCFG<....nPTLTD 
  0010: 24 50 43 49 54 42 4C 24 00 00 04 06 20 4C 54 50  // $PCITBL$.... LTP
  0020: 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 F0  // ................
  0030: 00 00 00 00 00 00 00 7F 00 00 00 00              // ............
