/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160108-64
 * Copyright (c) 2000 - 2016 Intel Corporation
 * 
 * Disassembly of APIC.aml, Sun Apr 30 09:56:03 2017
 *
 * ACPI Data Table [APIC]
 *
 * Format: [HexOffset DecimalOffset ByteLength]  FieldName : FieldValue
 */

[000h 0000   4]                    Signature : "APIC"    [Multiple APIC Description Table (MADT)]
[004h 0004   4]                 Table Length : 00000068
[008h 0008   1]                     Revision : 01
[009h 0009   1]                     Checksum : 8E
[00Ah 0010   6]                       Oem ID : "APPLE "
[010h 0016   8]                 Oem Table ID : "Apple00"
[018h 0024   4]                 Oem Revision : 00000001
[01Ch 0028   4]              Asl Compiler ID : "Loki"
[020h 0032   4]        Asl Compiler Revision : 0000005F

[024h 0036   4]           Local Apic Address : FEE00000
[028h 0040   4]        Flags (decoded below) : 00000001
                         PC-AT Compatibility : 1

[02Ch 0044   1]                Subtable Type : 00 [Processor Local APIC]
[02Dh 0045   1]                       Length : 08
[02Eh 0046   1]                 Processor ID : 00
[02Fh 0047   1]                Local Apic ID : 00
[030h 0048   4]        Flags (decoded below) : 00000001
                           Processor Enabled : 1

[034h 0052   1]                Subtable Type : 00 [Processor Local APIC]
[035h 0053   1]                       Length : 08
[036h 0054   1]                 Processor ID : 01
[037h 0055   1]                Local Apic ID : 01
[038h 0056   4]        Flags (decoded below) : 00000001
                           Processor Enabled : 1

[03Ch 0060   1]                Subtable Type : 01 [I/O APIC]
[03Dh 0061   1]                       Length : 0C
[03Eh 0062   1]                  I/O Apic ID : 01
[03Fh 0063   1]                     Reserved : 00
[040h 0064   4]                      Address : FEC00000
[044h 0068   4]                    Interrupt : 00000000

[048h 0072   1]                Subtable Type : 02 [Interrupt Source Override]
[049h 0073   1]                       Length : 0A
[04Ah 0074   1]                          Bus : 00
[04Bh 0075   1]                       Source : 00
[04Ch 0076   4]                    Interrupt : 00000002
[050h 0080   2]        Flags (decoded below) : 0000
                                    Polarity : 0
                                Trigger Mode : 0

[052h 0082   1]                Subtable Type : 02 [Interrupt Source Override]
[053h 0083   1]                       Length : 0A
[054h 0084   1]                          Bus : 00
[055h 0085   1]                       Source : 09
[056h 0086   4]                    Interrupt : 00000009
[05Ah 0090   2]        Flags (decoded below) : 000D
                                    Polarity : 1
                                Trigger Mode : 3

[05Ch 0092   1]                Subtable Type : 04 [Local APIC NMI]
[05Dh 0093   1]                       Length : 06
[05Eh 0094   1]                 Processor ID : 00
[05Fh 0095   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[061h 0097   1]         Interrupt Input LINT : 01

[062h 0098   1]                Subtable Type : 04 [Local APIC NMI]
[063h 0099   1]                       Length : 06
[064h 0100   1]                 Processor ID : 01
[065h 0101   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[067h 0103   1]         Interrupt Input LINT : 01

Raw Table Data: Length 104 (0x68)

  0000: 41 50 49 43 68 00 00 00 01 8E 41 50 50 4C 45 20  // APICh.....APPLE 
  0010: 41 70 70 6C 65 30 30 00 01 00 00 00 4C 6F 6B 69  // Apple00.....Loki
  0020: 5F 00 00 00 00 00 E0 FE 01 00 00 00 00 08 00 00  // _...............
  0030: 01 00 00 00 00 08 01 01 01 00 00 00 01 0C 01 00  // ................
  0040: 00 00 C0 FE 00 00 00 00 02 0A 00 00 02 00 00 00  // ................
  0050: 00 00 02 0A 00 09 09 00 00 00 0D 00 04 06 00 05  // ................
  0060: 00 01 04 06 01 05 00 01                          // ........
