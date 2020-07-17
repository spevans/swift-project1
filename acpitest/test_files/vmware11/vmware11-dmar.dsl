/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20180105 (64-bit version)
 * Copyright (c) 2000 - 2018 Intel Corporation
 * 
 * Disassembly of dmar.dat, Fri Jul 17 14:13:23 2020
 *
 * ACPI Data Table [DMAR]
 *
 * Format: [HexOffset DecimalOffset ByteLength]  FieldName : FieldValue
 */

[000h 0000   4]                    Signature : "DMAR"    [DMA Remapping table]
[004h 0004   4]                 Table Length : 00000050
[008h 0008   1]                     Revision : 01
[009h 0009   1]                     Checksum : B5
[00Ah 0010   6]                       Oem ID : "VMWARE"
[010h 0016   8]                 Oem Table ID : "VMW DMAR"
[018h 0024   4]                 Oem Revision : 06040001
[01Ch 0028   4]              Asl Compiler ID : "VMW "
[020h 0032   4]        Asl Compiler Revision : 00000001

[024h 0036   1]           Host Address Width : 2A
[025h 0037   1]                        Flags : 01
[026h 0038  10]                     Reserved : 00 00 00 00 00 00 00 00 00 00

[030h 0048   2]                Subtable Type : 0000 [Hardware Unit Definition]
[032h 0050   2]                       Length : 0018

[034h 0052   1]                        Flags : 01
[035h 0053   1]                     Reserved : 00
[036h 0054   2]           PCI Segment Number : 0000
[038h 0056   8]        Register Base Address : 00000000FEC10000

[040h 0064   1]            Device Scope Type : 03 [IOAPIC Device]
[041h 0065   1]                 Entry Length : 08
[042h 0066   2]                     Reserved : 0000
[044h 0068   1]               Enumeration ID : 80
[045h 0069   1]               PCI Bus Number : 00

[046h 0070   2]                     PCI Path : 00,07


[048h 0072   2]                Subtable Type : 0002 [Root Port ATS Capability]
[04Ah 0074   2]                       Length : 0008

[04Ch 0076   1]                        Flags : 01
[04Dh 0077   1]                     Reserved : 00
[04Eh 0078   2]           PCI Segment Number : 0000

Raw Table Data: Length 80 (0x50)

  0000: 44 4D 41 52 50 00 00 00 01 B5 56 4D 57 41 52 45  // DMARP.....VMWARE
  0010: 56 4D 57 20 44 4D 41 52 01 00 04 06 56 4D 57 20  // VMW DMAR....VMW 
  0020: 01 00 00 00 2A 01 00 00 00 00 00 00 00 00 00 00  // ....*...........
  0030: 00 00 18 00 01 00 00 00 00 00 C1 FE 00 00 00 00  // ................
  0040: 03 08 00 00 80 00 00 07 02 00 08 00 01 00 00 00  // ................
