/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20180105 (64-bit version)
 * Copyright (c) 2000 - 2018 Intel Corporation
 * 
 * Disassembly of hpet.dat, Fri Jul 17 14:13:23 2020
 *
 * ACPI Data Table [HPET]
 *
 * Format: [HexOffset DecimalOffset ByteLength]  FieldName : FieldValue
 */

[000h 0000   4]                    Signature : "HPET"    [High Precision Event Timer table]
[004h 0004   4]                 Table Length : 00000038
[008h 0008   1]                     Revision : 01
[009h 0009   1]                     Checksum : B5
[00Ah 0010   6]                       Oem ID : "VMWARE"
[010h 0016   8]                 Oem Table ID : "VMW HPET"
[018h 0024   4]                 Oem Revision : 00000000
[01Ch 0028   4]              Asl Compiler ID : "VMW "
[020h 0032   4]        Asl Compiler Revision : 00000000

[024h 0036   4]            Hardware Block ID : 8086AF01

[028h 0040  12]         Timer Block Register : [Generic Address Structure]
[028h 0040   1]                     Space ID : 00 [SystemMemory]
[029h 0041   1]                    Bit Width : 00
[02Ah 0042   1]                   Bit Offset : 00
[02Bh 0043   1]         Encoded Access Width : 00 [Undefined/Legacy]
[02Ch 0044   8]                      Address : 00000000FED00000

[034h 0052   1]              Sequence Number : 00
[035h 0053   2]          Minimum Clock Ticks : 37EE
[037h 0055   1]        Flags (decoded below) : 01
                             4K Page Protect : 1
                            64K Page Protect : 0

Raw Table Data: Length 56 (0x38)

  0000: 48 50 45 54 38 00 00 00 01 B5 56 4D 57 41 52 45  // HPET8.....VMWARE
  0010: 56 4D 57 20 48 50 45 54 00 00 00 00 56 4D 57 20  // VMW HPET....VMW 
  0020: 00 00 00 00 01 AF 86 80 00 00 00 00 00 00 D0 FE  // ................
  0030: 00 00 00 00 00 EE 37 01                          // ......7.
