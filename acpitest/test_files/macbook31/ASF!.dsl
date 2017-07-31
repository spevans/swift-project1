/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160108-64
 * Copyright (c) 2000 - 2016 Intel Corporation
 * 
 * Disassembly of ASF!.aml, Sun Apr 30 09:56:03 2017
 *
 * ACPI Data Table [ASF!]
 *
 * Format: [HexOffset DecimalOffset ByteLength]  FieldName : FieldValue
 */

[000h 0000   4]                    Signature : "ASF!"    [Alert Standard Format table]
[004h 0004   4]                 Table Length : 000000A5
[008h 0008   1]                     Revision : 20
[009h 0009   1]                     Checksum : B6
[00Ah 0010   6]                       Oem ID : "APPLE "
[010h 0016   8]                 Oem Table ID : "Apple00"
[018h 0024   4]                 Oem Revision : 00000001
[01Ch 0028   4]              Asl Compiler ID : "Loki"
[020h 0032   4]        Asl Compiler Revision : 0000005F

[024h 0036   1]                Subtable Type : 00 [ASF Information]
[025h 0037   1]                     Reserved : 00
[026h 0038   2]                       Length : 0010
[028h 0040   1]          Minimum Reset Value : 05
[029h 0041   1]     Minimum Polling Interval : FF
[02Ah 0042   2]                    System ID : 0001
[02Ch 0044   4]              Manufacturer ID : BE110000
[030h 0048   1]                        Flags : 00
[031h 0049   3]                     Reserved : 000000

[034h 0052   1]                Subtable Type : 01 [ASF Alerts]
[035h 0053   1]                     Reserved : 00
[036h 0054   2]                       Length : 002C
[038h 0056   1]                   AssertMask : 00
[039h 0057   1]                 DeassertMask : 00
[03Ah 0058   1]                  Alert Count : 03
[03Bh 0059   1]            Alert Data Length : 0C

[03Ch 0060   1]                      Address : 89
[03Dh 0061   1]                      Command : 04
[03Eh 0062   1]                         Mask : 01
[03Fh 0063   1]                        Value : 01
[040h 0064   1]                   SensorType : 05
[041h 0065   1]                         Type : 6F
[042h 0066   1]                       Offset : 00
[043h 0067   1]                   SourceType : 68
[044h 0068   1]                     Severity : 08
[045h 0069   1]                 SensorNumber : 88
[046h 0070   1]                       Entity : 17
[047h 0071   1]                     Instance : 00

[048h 0072   1]                      Address : 89
[049h 0073   1]                      Command : 04
[04Ah 0074   1]                         Mask : 04
[04Bh 0075   1]                        Value : 04
[04Ch 0076   1]                   SensorType : 07
[04Dh 0077   1]                         Type : 6F
[04Eh 0078   1]                       Offset : 00
[04Fh 0079   1]                   SourceType : 68
[050h 0080   1]                     Severity : 20
[051h 0081   1]                 SensorNumber : 88
[052h 0082   1]                       Entity : 03
[053h 0083   1]                     Instance : 00

[054h 0084   1]                      Address : 89
[055h 0085   1]                      Command : 05
[056h 0086   1]                         Mask : 01
[057h 0087   1]                        Value : 01
[058h 0088   1]                   SensorType : 19
[059h 0089   1]                         Type : 6F
[05Ah 0090   1]                       Offset : 00
[05Bh 0091   1]                   SourceType : 68
[05Ch 0092   1]                     Severity : 20
[05Dh 0093   1]                 SensorNumber : 88
[05Eh 0094   1]                       Entity : 22
[05Fh 0095   1]                     Instance : 00

[060h 0096   1]                Subtable Type : 02 [ASF Remote Control]
[061h 0097   1]                     Reserved : 00
[062h 0098   2]                       Length : 0018
[064h 0100   1]                Control Count : 04
[065h 0101   1]          Control Data Length : 04
[066h 0102   2]                     Reserved : 0000

[068h 0104   1]                     Function : 00
[069h 0105   1]                      Address : 88
[06Ah 0106   1]                      Command : 00
[06Bh 0107   1]                        Value : 03

[06Ch 0108   1]                     Function : 01
[06Dh 0109   1]                      Address : 88
[06Eh 0110   1]                      Command : 00
[06Fh 0111   1]                        Value : 02

[070h 0112   1]                     Function : 02
[071h 0113   1]                      Address : 88
[072h 0114   1]                      Command : 00
[073h 0115   1]                        Value : 01

[074h 0116   1]                     Function : 03
[075h 0117   1]                      Address : 88
[076h 0118   1]                      Command : 00
[077h 0119   1]                        Value : 04

[078h 0120   1]                Subtable Type : 03 [ASF RMCP Boot Options]
[079h 0121   1]                     Reserved : 00
[07Ah 0122   2]                       Length : 0017
[07Ch 0124   7]                 Capabilities : 20 F8 00 00 00 1F F0
[083h 0131   1]              Completion Code : 00
[084h 0132   4]                Enterprise ID : BE110000
[088h 0136   1]                      Command : 00
[089h 0137   2]                    Parameter : 0000
[08Bh 0139   2]                 Boot Options : 0100
[08Dh 0141   2]               Oem Parameters : 0000

[08Fh 0143   1]                Subtable Type : 84 [ASF Address]
[090h 0144   1]                     Reserved : 00
[091h 0145   2]                       Length : 0016
[093h 0147   1]                Eprom Address : 00
[094h 0148   1]                 Device Count : 10
[095h 0149   1]                    Addresses : 5C 68 88 C2 D2 DC A0 A2 A4 A6 C8 00 00 00 00 00 


Raw Table Data: Length 165 (0xA5)

  0000: 41 53 46 21 A5 00 00 00 20 B6 41 50 50 4C 45 20  // ASF!.... .APPLE 
  0010: 41 70 70 6C 65 30 30 00 01 00 00 00 4C 6F 6B 69  // Apple00.....Loki
  0020: 5F 00 00 00 00 00 10 00 05 FF 01 00 00 00 11 BE  // _...............
  0030: 00 00 00 00 01 00 2C 00 00 00 03 0C 89 04 01 01  // ......,.........
  0040: 05 6F 00 68 08 88 17 00 89 04 04 04 07 6F 00 68  // .o.h.........o.h
  0050: 20 88 03 00 89 05 01 01 19 6F 00 68 20 88 22 00  //  ........o.h .".
  0060: 02 00 18 00 04 04 00 00 00 88 00 03 01 88 00 02  // ................
  0070: 02 88 00 01 03 88 00 04 03 00 17 00 20 F8 00 00  // ............ ...
  0080: 00 1F F0 00 00 00 11 BE 00 00 00 00 01 00 00 84  // ................
  0090: 00 16 00 00 10 5C 68 88 C2 D2 DC A0 A2 A4 A6 C8  // .....\h.........
  00A0: 00 00 00 00 00                                   // .....
