/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160108-64
 * Copyright (c) 2000 - 2016 Intel Corporation
 * 
 * Disassembly of APIC.aml, Sat Apr 29 16:39:43 2017
 *
 * ACPI Data Table [APIC]
 *
 * Format: [HexOffset DecimalOffset ByteLength]  FieldName : FieldValue
 */

[000h 0000   4]                    Signature : "APIC"    [Multiple APIC Description Table (MADT)]
[004h 0004   4]                 Table Length : 00000742
[008h 0008   1]                     Revision : 01
[009h 0009   1]                     Checksum : 8F
[00Ah 0010   6]                       Oem ID : "PTLTD "
[010h 0016   8]                 Oem Table ID : "  APIC  "
[018h 0024   4]                 Oem Revision : 06040000
[01Ch 0028   4]              Asl Compiler ID : " LTP"
[020h 0032   4]        Asl Compiler Revision : 00000000

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
[037h 0055   1]                Local Apic ID : 02
[038h 0056   4]        Flags (decoded below) : 00000001
                           Processor Enabled : 1

[03Ch 0060   1]                Subtable Type : 00 [Processor Local APIC]
[03Dh 0061   1]                       Length : 08
[03Eh 0062   1]                 Processor ID : 02
[03Fh 0063   1]                Local Apic ID : 04
[040h 0064   4]        Flags (decoded below) : 00000001
                           Processor Enabled : 1

[044h 0068   1]                Subtable Type : 00 [Processor Local APIC]
[045h 0069   1]                       Length : 08
[046h 0070   1]                 Processor ID : 03
[047h 0071   1]                Local Apic ID : 06
[048h 0072   4]        Flags (decoded below) : 00000001
                           Processor Enabled : 1

[04Ch 0076   1]                Subtable Type : 00 [Processor Local APIC]
[04Dh 0077   1]                       Length : 08
[04Eh 0078   1]                 Processor ID : 04
[04Fh 0079   1]                Local Apic ID : 08
[050h 0080   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[054h 0084   1]                Subtable Type : 00 [Processor Local APIC]
[055h 0085   1]                       Length : 08
[056h 0086   1]                 Processor ID : 05
[057h 0087   1]                Local Apic ID : 0A
[058h 0088   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[05Ch 0092   1]                Subtable Type : 00 [Processor Local APIC]
[05Dh 0093   1]                       Length : 08
[05Eh 0094   1]                 Processor ID : 06
[05Fh 0095   1]                Local Apic ID : 0C
[060h 0096   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[064h 0100   1]                Subtable Type : 00 [Processor Local APIC]
[065h 0101   1]                       Length : 08
[066h 0102   1]                 Processor ID : 07
[067h 0103   1]                Local Apic ID : 0E
[068h 0104   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[06Ch 0108   1]                Subtable Type : 00 [Processor Local APIC]
[06Dh 0109   1]                       Length : 08
[06Eh 0110   1]                 Processor ID : 08
[06Fh 0111   1]                Local Apic ID : 10
[070h 0112   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[074h 0116   1]                Subtable Type : 00 [Processor Local APIC]
[075h 0117   1]                       Length : 08
[076h 0118   1]                 Processor ID : 09
[077h 0119   1]                Local Apic ID : 12
[078h 0120   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[07Ch 0124   1]                Subtable Type : 00 [Processor Local APIC]
[07Dh 0125   1]                       Length : 08
[07Eh 0126   1]                 Processor ID : 0A
[07Fh 0127   1]                Local Apic ID : 14
[080h 0128   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[084h 0132   1]                Subtable Type : 00 [Processor Local APIC]
[085h 0133   1]                       Length : 08
[086h 0134   1]                 Processor ID : 0B
[087h 0135   1]                Local Apic ID : 16
[088h 0136   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[08Ch 0140   1]                Subtable Type : 00 [Processor Local APIC]
[08Dh 0141   1]                       Length : 08
[08Eh 0142   1]                 Processor ID : 0C
[08Fh 0143   1]                Local Apic ID : 18
[090h 0144   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[094h 0148   1]                Subtable Type : 00 [Processor Local APIC]
[095h 0149   1]                       Length : 08
[096h 0150   1]                 Processor ID : 0D
[097h 0151   1]                Local Apic ID : 1A
[098h 0152   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[09Ch 0156   1]                Subtable Type : 00 [Processor Local APIC]
[09Dh 0157   1]                       Length : 08
[09Eh 0158   1]                 Processor ID : 0E
[09Fh 0159   1]                Local Apic ID : 1C
[0A0h 0160   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0A4h 0164   1]                Subtable Type : 00 [Processor Local APIC]
[0A5h 0165   1]                       Length : 08
[0A6h 0166   1]                 Processor ID : 0F
[0A7h 0167   1]                Local Apic ID : 1E
[0A8h 0168   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0ACh 0172   1]                Subtable Type : 00 [Processor Local APIC]
[0ADh 0173   1]                       Length : 08
[0AEh 0174   1]                 Processor ID : 10
[0AFh 0175   1]                Local Apic ID : 20
[0B0h 0176   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0B4h 0180   1]                Subtable Type : 00 [Processor Local APIC]
[0B5h 0181   1]                       Length : 08
[0B6h 0182   1]                 Processor ID : 11
[0B7h 0183   1]                Local Apic ID : 22
[0B8h 0184   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0BCh 0188   1]                Subtable Type : 00 [Processor Local APIC]
[0BDh 0189   1]                       Length : 08
[0BEh 0190   1]                 Processor ID : 12
[0BFh 0191   1]                Local Apic ID : 24
[0C0h 0192   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0C4h 0196   1]                Subtable Type : 00 [Processor Local APIC]
[0C5h 0197   1]                       Length : 08
[0C6h 0198   1]                 Processor ID : 13
[0C7h 0199   1]                Local Apic ID : 26
[0C8h 0200   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0CCh 0204   1]                Subtable Type : 00 [Processor Local APIC]
[0CDh 0205   1]                       Length : 08
[0CEh 0206   1]                 Processor ID : 14
[0CFh 0207   1]                Local Apic ID : 28
[0D0h 0208   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0D4h 0212   1]                Subtable Type : 00 [Processor Local APIC]
[0D5h 0213   1]                       Length : 08
[0D6h 0214   1]                 Processor ID : 15
[0D7h 0215   1]                Local Apic ID : 2A
[0D8h 0216   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0DCh 0220   1]                Subtable Type : 00 [Processor Local APIC]
[0DDh 0221   1]                       Length : 08
[0DEh 0222   1]                 Processor ID : 16
[0DFh 0223   1]                Local Apic ID : 2C
[0E0h 0224   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0E4h 0228   1]                Subtable Type : 00 [Processor Local APIC]
[0E5h 0229   1]                       Length : 08
[0E6h 0230   1]                 Processor ID : 17
[0E7h 0231   1]                Local Apic ID : 2E
[0E8h 0232   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0ECh 0236   1]                Subtable Type : 00 [Processor Local APIC]
[0EDh 0237   1]                       Length : 08
[0EEh 0238   1]                 Processor ID : 18
[0EFh 0239   1]                Local Apic ID : 30
[0F0h 0240   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0F4h 0244   1]                Subtable Type : 00 [Processor Local APIC]
[0F5h 0245   1]                       Length : 08
[0F6h 0246   1]                 Processor ID : 19
[0F7h 0247   1]                Local Apic ID : 32
[0F8h 0248   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0FCh 0252   1]                Subtable Type : 00 [Processor Local APIC]
[0FDh 0253   1]                       Length : 08
[0FEh 0254   1]                 Processor ID : 1A
[0FFh 0255   1]                Local Apic ID : 34
[100h 0256   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[104h 0260   1]                Subtable Type : 00 [Processor Local APIC]
[105h 0261   1]                       Length : 08
[106h 0262   1]                 Processor ID : 1B
[107h 0263   1]                Local Apic ID : 36
[108h 0264   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[10Ch 0268   1]                Subtable Type : 00 [Processor Local APIC]
[10Dh 0269   1]                       Length : 08
[10Eh 0270   1]                 Processor ID : 1C
[10Fh 0271   1]                Local Apic ID : 38
[110h 0272   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[114h 0276   1]                Subtable Type : 00 [Processor Local APIC]
[115h 0277   1]                       Length : 08
[116h 0278   1]                 Processor ID : 1D
[117h 0279   1]                Local Apic ID : 3A
[118h 0280   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[11Ch 0284   1]                Subtable Type : 00 [Processor Local APIC]
[11Dh 0285   1]                       Length : 08
[11Eh 0286   1]                 Processor ID : 1E
[11Fh 0287   1]                Local Apic ID : 3C
[120h 0288   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[124h 0292   1]                Subtable Type : 00 [Processor Local APIC]
[125h 0293   1]                       Length : 08
[126h 0294   1]                 Processor ID : 1F
[127h 0295   1]                Local Apic ID : 3E
[128h 0296   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[12Ch 0300   1]                Subtable Type : 00 [Processor Local APIC]
[12Dh 0301   1]                       Length : 08
[12Eh 0302   1]                 Processor ID : 20
[12Fh 0303   1]                Local Apic ID : 40
[130h 0304   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[134h 0308   1]                Subtable Type : 00 [Processor Local APIC]
[135h 0309   1]                       Length : 08
[136h 0310   1]                 Processor ID : 21
[137h 0311   1]                Local Apic ID : 42
[138h 0312   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[13Ch 0316   1]                Subtable Type : 00 [Processor Local APIC]
[13Dh 0317   1]                       Length : 08
[13Eh 0318   1]                 Processor ID : 22
[13Fh 0319   1]                Local Apic ID : 44
[140h 0320   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[144h 0324   1]                Subtable Type : 00 [Processor Local APIC]
[145h 0325   1]                       Length : 08
[146h 0326   1]                 Processor ID : 23
[147h 0327   1]                Local Apic ID : 46
[148h 0328   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[14Ch 0332   1]                Subtable Type : 00 [Processor Local APIC]
[14Dh 0333   1]                       Length : 08
[14Eh 0334   1]                 Processor ID : 24
[14Fh 0335   1]                Local Apic ID : 48
[150h 0336   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[154h 0340   1]                Subtable Type : 00 [Processor Local APIC]
[155h 0341   1]                       Length : 08
[156h 0342   1]                 Processor ID : 25
[157h 0343   1]                Local Apic ID : 4A
[158h 0344   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[15Ch 0348   1]                Subtable Type : 00 [Processor Local APIC]
[15Dh 0349   1]                       Length : 08
[15Eh 0350   1]                 Processor ID : 26
[15Fh 0351   1]                Local Apic ID : 4C
[160h 0352   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[164h 0356   1]                Subtable Type : 00 [Processor Local APIC]
[165h 0357   1]                       Length : 08
[166h 0358   1]                 Processor ID : 27
[167h 0359   1]                Local Apic ID : 4E
[168h 0360   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[16Ch 0364   1]                Subtable Type : 00 [Processor Local APIC]
[16Dh 0365   1]                       Length : 08
[16Eh 0366   1]                 Processor ID : 28
[16Fh 0367   1]                Local Apic ID : 50
[170h 0368   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[174h 0372   1]                Subtable Type : 00 [Processor Local APIC]
[175h 0373   1]                       Length : 08
[176h 0374   1]                 Processor ID : 29
[177h 0375   1]                Local Apic ID : 52
[178h 0376   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[17Ch 0380   1]                Subtable Type : 00 [Processor Local APIC]
[17Dh 0381   1]                       Length : 08
[17Eh 0382   1]                 Processor ID : 2A
[17Fh 0383   1]                Local Apic ID : 54
[180h 0384   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[184h 0388   1]                Subtable Type : 00 [Processor Local APIC]
[185h 0389   1]                       Length : 08
[186h 0390   1]                 Processor ID : 2B
[187h 0391   1]                Local Apic ID : 56
[188h 0392   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[18Ch 0396   1]                Subtable Type : 00 [Processor Local APIC]
[18Dh 0397   1]                       Length : 08
[18Eh 0398   1]                 Processor ID : 2C
[18Fh 0399   1]                Local Apic ID : 58
[190h 0400   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[194h 0404   1]                Subtable Type : 00 [Processor Local APIC]
[195h 0405   1]                       Length : 08
[196h 0406   1]                 Processor ID : 2D
[197h 0407   1]                Local Apic ID : 5A
[198h 0408   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[19Ch 0412   1]                Subtable Type : 00 [Processor Local APIC]
[19Dh 0413   1]                       Length : 08
[19Eh 0414   1]                 Processor ID : 2E
[19Fh 0415   1]                Local Apic ID : 5C
[1A0h 0416   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1A4h 0420   1]                Subtable Type : 00 [Processor Local APIC]
[1A5h 0421   1]                       Length : 08
[1A6h 0422   1]                 Processor ID : 2F
[1A7h 0423   1]                Local Apic ID : 5E
[1A8h 0424   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1ACh 0428   1]                Subtable Type : 00 [Processor Local APIC]
[1ADh 0429   1]                       Length : 08
[1AEh 0430   1]                 Processor ID : 30
[1AFh 0431   1]                Local Apic ID : 60
[1B0h 0432   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1B4h 0436   1]                Subtable Type : 00 [Processor Local APIC]
[1B5h 0437   1]                       Length : 08
[1B6h 0438   1]                 Processor ID : 31
[1B7h 0439   1]                Local Apic ID : 62
[1B8h 0440   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1BCh 0444   1]                Subtable Type : 00 [Processor Local APIC]
[1BDh 0445   1]                       Length : 08
[1BEh 0446   1]                 Processor ID : 32
[1BFh 0447   1]                Local Apic ID : 64
[1C0h 0448   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1C4h 0452   1]                Subtable Type : 00 [Processor Local APIC]
[1C5h 0453   1]                       Length : 08
[1C6h 0454   1]                 Processor ID : 33
[1C7h 0455   1]                Local Apic ID : 66
[1C8h 0456   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1CCh 0460   1]                Subtable Type : 00 [Processor Local APIC]
[1CDh 0461   1]                       Length : 08
[1CEh 0462   1]                 Processor ID : 34
[1CFh 0463   1]                Local Apic ID : 68
[1D0h 0464   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1D4h 0468   1]                Subtable Type : 00 [Processor Local APIC]
[1D5h 0469   1]                       Length : 08
[1D6h 0470   1]                 Processor ID : 35
[1D7h 0471   1]                Local Apic ID : 6A
[1D8h 0472   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1DCh 0476   1]                Subtable Type : 00 [Processor Local APIC]
[1DDh 0477   1]                       Length : 08
[1DEh 0478   1]                 Processor ID : 36
[1DFh 0479   1]                Local Apic ID : 6C
[1E0h 0480   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1E4h 0484   1]                Subtable Type : 00 [Processor Local APIC]
[1E5h 0485   1]                       Length : 08
[1E6h 0486   1]                 Processor ID : 37
[1E7h 0487   1]                Local Apic ID : 6E
[1E8h 0488   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1ECh 0492   1]                Subtable Type : 00 [Processor Local APIC]
[1EDh 0493   1]                       Length : 08
[1EEh 0494   1]                 Processor ID : 38
[1EFh 0495   1]                Local Apic ID : 70
[1F0h 0496   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1F4h 0500   1]                Subtable Type : 00 [Processor Local APIC]
[1F5h 0501   1]                       Length : 08
[1F6h 0502   1]                 Processor ID : 39
[1F7h 0503   1]                Local Apic ID : 72
[1F8h 0504   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1FCh 0508   1]                Subtable Type : 00 [Processor Local APIC]
[1FDh 0509   1]                       Length : 08
[1FEh 0510   1]                 Processor ID : 3A
[1FFh 0511   1]                Local Apic ID : 74
[200h 0512   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[204h 0516   1]                Subtable Type : 00 [Processor Local APIC]
[205h 0517   1]                       Length : 08
[206h 0518   1]                 Processor ID : 3B
[207h 0519   1]                Local Apic ID : 76
[208h 0520   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[20Ch 0524   1]                Subtable Type : 00 [Processor Local APIC]
[20Dh 0525   1]                       Length : 08
[20Eh 0526   1]                 Processor ID : 3C
[20Fh 0527   1]                Local Apic ID : 78
[210h 0528   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[214h 0532   1]                Subtable Type : 00 [Processor Local APIC]
[215h 0533   1]                       Length : 08
[216h 0534   1]                 Processor ID : 3D
[217h 0535   1]                Local Apic ID : 7A
[218h 0536   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[21Ch 0540   1]                Subtable Type : 00 [Processor Local APIC]
[21Dh 0541   1]                       Length : 08
[21Eh 0542   1]                 Processor ID : 3E
[21Fh 0543   1]                Local Apic ID : 7C
[220h 0544   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[224h 0548   1]                Subtable Type : 00 [Processor Local APIC]
[225h 0549   1]                       Length : 08
[226h 0550   1]                 Processor ID : 3F
[227h 0551   1]                Local Apic ID : 7E
[228h 0552   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[22Ch 0556   1]                Subtable Type : 00 [Processor Local APIC]
[22Dh 0557   1]                       Length : 08
[22Eh 0558   1]                 Processor ID : 40
[22Fh 0559   1]                Local Apic ID : 80
[230h 0560   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[234h 0564   1]                Subtable Type : 00 [Processor Local APIC]
[235h 0565   1]                       Length : 08
[236h 0566   1]                 Processor ID : 41
[237h 0567   1]                Local Apic ID : 82
[238h 0568   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[23Ch 0572   1]                Subtable Type : 00 [Processor Local APIC]
[23Dh 0573   1]                       Length : 08
[23Eh 0574   1]                 Processor ID : 42
[23Fh 0575   1]                Local Apic ID : 84
[240h 0576   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[244h 0580   1]                Subtable Type : 00 [Processor Local APIC]
[245h 0581   1]                       Length : 08
[246h 0582   1]                 Processor ID : 43
[247h 0583   1]                Local Apic ID : 86
[248h 0584   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[24Ch 0588   1]                Subtable Type : 00 [Processor Local APIC]
[24Dh 0589   1]                       Length : 08
[24Eh 0590   1]                 Processor ID : 44
[24Fh 0591   1]                Local Apic ID : 88
[250h 0592   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[254h 0596   1]                Subtable Type : 00 [Processor Local APIC]
[255h 0597   1]                       Length : 08
[256h 0598   1]                 Processor ID : 45
[257h 0599   1]                Local Apic ID : 8A
[258h 0600   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[25Ch 0604   1]                Subtable Type : 00 [Processor Local APIC]
[25Dh 0605   1]                       Length : 08
[25Eh 0606   1]                 Processor ID : 46
[25Fh 0607   1]                Local Apic ID : 8C
[260h 0608   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[264h 0612   1]                Subtable Type : 00 [Processor Local APIC]
[265h 0613   1]                       Length : 08
[266h 0614   1]                 Processor ID : 47
[267h 0615   1]                Local Apic ID : 8E
[268h 0616   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[26Ch 0620   1]                Subtable Type : 00 [Processor Local APIC]
[26Dh 0621   1]                       Length : 08
[26Eh 0622   1]                 Processor ID : 48
[26Fh 0623   1]                Local Apic ID : 90
[270h 0624   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[274h 0628   1]                Subtable Type : 00 [Processor Local APIC]
[275h 0629   1]                       Length : 08
[276h 0630   1]                 Processor ID : 49
[277h 0631   1]                Local Apic ID : 92
[278h 0632   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[27Ch 0636   1]                Subtable Type : 00 [Processor Local APIC]
[27Dh 0637   1]                       Length : 08
[27Eh 0638   1]                 Processor ID : 4A
[27Fh 0639   1]                Local Apic ID : 94
[280h 0640   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[284h 0644   1]                Subtable Type : 00 [Processor Local APIC]
[285h 0645   1]                       Length : 08
[286h 0646   1]                 Processor ID : 4B
[287h 0647   1]                Local Apic ID : 96
[288h 0648   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[28Ch 0652   1]                Subtable Type : 00 [Processor Local APIC]
[28Dh 0653   1]                       Length : 08
[28Eh 0654   1]                 Processor ID : 4C
[28Fh 0655   1]                Local Apic ID : 98
[290h 0656   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[294h 0660   1]                Subtable Type : 00 [Processor Local APIC]
[295h 0661   1]                       Length : 08
[296h 0662   1]                 Processor ID : 4D
[297h 0663   1]                Local Apic ID : 9A
[298h 0664   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[29Ch 0668   1]                Subtable Type : 00 [Processor Local APIC]
[29Dh 0669   1]                       Length : 08
[29Eh 0670   1]                 Processor ID : 4E
[29Fh 0671   1]                Local Apic ID : 9C
[2A0h 0672   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2A4h 0676   1]                Subtable Type : 00 [Processor Local APIC]
[2A5h 0677   1]                       Length : 08
[2A6h 0678   1]                 Processor ID : 4F
[2A7h 0679   1]                Local Apic ID : 9E
[2A8h 0680   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2ACh 0684   1]                Subtable Type : 00 [Processor Local APIC]
[2ADh 0685   1]                       Length : 08
[2AEh 0686   1]                 Processor ID : 50
[2AFh 0687   1]                Local Apic ID : A0
[2B0h 0688   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2B4h 0692   1]                Subtable Type : 00 [Processor Local APIC]
[2B5h 0693   1]                       Length : 08
[2B6h 0694   1]                 Processor ID : 51
[2B7h 0695   1]                Local Apic ID : A2
[2B8h 0696   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2BCh 0700   1]                Subtable Type : 00 [Processor Local APIC]
[2BDh 0701   1]                       Length : 08
[2BEh 0702   1]                 Processor ID : 52
[2BFh 0703   1]                Local Apic ID : A4
[2C0h 0704   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2C4h 0708   1]                Subtable Type : 00 [Processor Local APIC]
[2C5h 0709   1]                       Length : 08
[2C6h 0710   1]                 Processor ID : 53
[2C7h 0711   1]                Local Apic ID : A6
[2C8h 0712   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2CCh 0716   1]                Subtable Type : 00 [Processor Local APIC]
[2CDh 0717   1]                       Length : 08
[2CEh 0718   1]                 Processor ID : 54
[2CFh 0719   1]                Local Apic ID : A8
[2D0h 0720   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2D4h 0724   1]                Subtable Type : 00 [Processor Local APIC]
[2D5h 0725   1]                       Length : 08
[2D6h 0726   1]                 Processor ID : 55
[2D7h 0727   1]                Local Apic ID : AA
[2D8h 0728   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2DCh 0732   1]                Subtable Type : 00 [Processor Local APIC]
[2DDh 0733   1]                       Length : 08
[2DEh 0734   1]                 Processor ID : 56
[2DFh 0735   1]                Local Apic ID : AC
[2E0h 0736   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2E4h 0740   1]                Subtable Type : 00 [Processor Local APIC]
[2E5h 0741   1]                       Length : 08
[2E6h 0742   1]                 Processor ID : 57
[2E7h 0743   1]                Local Apic ID : AE
[2E8h 0744   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2ECh 0748   1]                Subtable Type : 00 [Processor Local APIC]
[2EDh 0749   1]                       Length : 08
[2EEh 0750   1]                 Processor ID : 58
[2EFh 0751   1]                Local Apic ID : B0
[2F0h 0752   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2F4h 0756   1]                Subtable Type : 00 [Processor Local APIC]
[2F5h 0757   1]                       Length : 08
[2F6h 0758   1]                 Processor ID : 59
[2F7h 0759   1]                Local Apic ID : B2
[2F8h 0760   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2FCh 0764   1]                Subtable Type : 00 [Processor Local APIC]
[2FDh 0765   1]                       Length : 08
[2FEh 0766   1]                 Processor ID : 5A
[2FFh 0767   1]                Local Apic ID : B4
[300h 0768   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[304h 0772   1]                Subtable Type : 00 [Processor Local APIC]
[305h 0773   1]                       Length : 08
[306h 0774   1]                 Processor ID : 5B
[307h 0775   1]                Local Apic ID : B6
[308h 0776   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[30Ch 0780   1]                Subtable Type : 00 [Processor Local APIC]
[30Dh 0781   1]                       Length : 08
[30Eh 0782   1]                 Processor ID : 5C
[30Fh 0783   1]                Local Apic ID : B8
[310h 0784   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[314h 0788   1]                Subtable Type : 00 [Processor Local APIC]
[315h 0789   1]                       Length : 08
[316h 0790   1]                 Processor ID : 5D
[317h 0791   1]                Local Apic ID : BA
[318h 0792   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[31Ch 0796   1]                Subtable Type : 00 [Processor Local APIC]
[31Dh 0797   1]                       Length : 08
[31Eh 0798   1]                 Processor ID : 5E
[31Fh 0799   1]                Local Apic ID : BC
[320h 0800   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[324h 0804   1]                Subtable Type : 00 [Processor Local APIC]
[325h 0805   1]                       Length : 08
[326h 0806   1]                 Processor ID : 5F
[327h 0807   1]                Local Apic ID : BE
[328h 0808   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[32Ch 0812   1]                Subtable Type : 00 [Processor Local APIC]
[32Dh 0813   1]                       Length : 08
[32Eh 0814   1]                 Processor ID : 60
[32Fh 0815   1]                Local Apic ID : C0
[330h 0816   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[334h 0820   1]                Subtable Type : 00 [Processor Local APIC]
[335h 0821   1]                       Length : 08
[336h 0822   1]                 Processor ID : 61
[337h 0823   1]                Local Apic ID : C2
[338h 0824   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[33Ch 0828   1]                Subtable Type : 00 [Processor Local APIC]
[33Dh 0829   1]                       Length : 08
[33Eh 0830   1]                 Processor ID : 62
[33Fh 0831   1]                Local Apic ID : C4
[340h 0832   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[344h 0836   1]                Subtable Type : 00 [Processor Local APIC]
[345h 0837   1]                       Length : 08
[346h 0838   1]                 Processor ID : 63
[347h 0839   1]                Local Apic ID : C6
[348h 0840   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[34Ch 0844   1]                Subtable Type : 00 [Processor Local APIC]
[34Dh 0845   1]                       Length : 08
[34Eh 0846   1]                 Processor ID : 64
[34Fh 0847   1]                Local Apic ID : C8
[350h 0848   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[354h 0852   1]                Subtable Type : 00 [Processor Local APIC]
[355h 0853   1]                       Length : 08
[356h 0854   1]                 Processor ID : 65
[357h 0855   1]                Local Apic ID : CA
[358h 0856   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[35Ch 0860   1]                Subtable Type : 00 [Processor Local APIC]
[35Dh 0861   1]                       Length : 08
[35Eh 0862   1]                 Processor ID : 66
[35Fh 0863   1]                Local Apic ID : CC
[360h 0864   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[364h 0868   1]                Subtable Type : 00 [Processor Local APIC]
[365h 0869   1]                       Length : 08
[366h 0870   1]                 Processor ID : 67
[367h 0871   1]                Local Apic ID : CE
[368h 0872   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[36Ch 0876   1]                Subtable Type : 00 [Processor Local APIC]
[36Dh 0877   1]                       Length : 08
[36Eh 0878   1]                 Processor ID : 68
[36Fh 0879   1]                Local Apic ID : D0
[370h 0880   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[374h 0884   1]                Subtable Type : 00 [Processor Local APIC]
[375h 0885   1]                       Length : 08
[376h 0886   1]                 Processor ID : 69
[377h 0887   1]                Local Apic ID : D2
[378h 0888   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[37Ch 0892   1]                Subtable Type : 00 [Processor Local APIC]
[37Dh 0893   1]                       Length : 08
[37Eh 0894   1]                 Processor ID : 6A
[37Fh 0895   1]                Local Apic ID : D4
[380h 0896   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[384h 0900   1]                Subtable Type : 00 [Processor Local APIC]
[385h 0901   1]                       Length : 08
[386h 0902   1]                 Processor ID : 6B
[387h 0903   1]                Local Apic ID : D6
[388h 0904   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[38Ch 0908   1]                Subtable Type : 00 [Processor Local APIC]
[38Dh 0909   1]                       Length : 08
[38Eh 0910   1]                 Processor ID : 6C
[38Fh 0911   1]                Local Apic ID : D8
[390h 0912   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[394h 0916   1]                Subtable Type : 00 [Processor Local APIC]
[395h 0917   1]                       Length : 08
[396h 0918   1]                 Processor ID : 6D
[397h 0919   1]                Local Apic ID : DA
[398h 0920   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[39Ch 0924   1]                Subtable Type : 00 [Processor Local APIC]
[39Dh 0925   1]                       Length : 08
[39Eh 0926   1]                 Processor ID : 6E
[39Fh 0927   1]                Local Apic ID : DC
[3A0h 0928   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3A4h 0932   1]                Subtable Type : 00 [Processor Local APIC]
[3A5h 0933   1]                       Length : 08
[3A6h 0934   1]                 Processor ID : 6F
[3A7h 0935   1]                Local Apic ID : DE
[3A8h 0936   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3ACh 0940   1]                Subtable Type : 00 [Processor Local APIC]
[3ADh 0941   1]                       Length : 08
[3AEh 0942   1]                 Processor ID : 70
[3AFh 0943   1]                Local Apic ID : E0
[3B0h 0944   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3B4h 0948   1]                Subtable Type : 00 [Processor Local APIC]
[3B5h 0949   1]                       Length : 08
[3B6h 0950   1]                 Processor ID : 71
[3B7h 0951   1]                Local Apic ID : E2
[3B8h 0952   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3BCh 0956   1]                Subtable Type : 00 [Processor Local APIC]
[3BDh 0957   1]                       Length : 08
[3BEh 0958   1]                 Processor ID : 72
[3BFh 0959   1]                Local Apic ID : E4
[3C0h 0960   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3C4h 0964   1]                Subtable Type : 00 [Processor Local APIC]
[3C5h 0965   1]                       Length : 08
[3C6h 0966   1]                 Processor ID : 73
[3C7h 0967   1]                Local Apic ID : E6
[3C8h 0968   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3CCh 0972   1]                Subtable Type : 00 [Processor Local APIC]
[3CDh 0973   1]                       Length : 08
[3CEh 0974   1]                 Processor ID : 74
[3CFh 0975   1]                Local Apic ID : E8
[3D0h 0976   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3D4h 0980   1]                Subtable Type : 00 [Processor Local APIC]
[3D5h 0981   1]                       Length : 08
[3D6h 0982   1]                 Processor ID : 75
[3D7h 0983   1]                Local Apic ID : EA
[3D8h 0984   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3DCh 0988   1]                Subtable Type : 00 [Processor Local APIC]
[3DDh 0989   1]                       Length : 08
[3DEh 0990   1]                 Processor ID : 76
[3DFh 0991   1]                Local Apic ID : EC
[3E0h 0992   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3E4h 0996   1]                Subtable Type : 00 [Processor Local APIC]
[3E5h 0997   1]                       Length : 08
[3E6h 0998   1]                 Processor ID : 77
[3E7h 0999   1]                Local Apic ID : EE
[3E8h 1000   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3ECh 1004   1]                Subtable Type : 00 [Processor Local APIC]
[3EDh 1005   1]                       Length : 08
[3EEh 1006   1]                 Processor ID : 78
[3EFh 1007   1]                Local Apic ID : F0
[3F0h 1008   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3F4h 1012   1]                Subtable Type : 00 [Processor Local APIC]
[3F5h 1013   1]                       Length : 08
[3F6h 1014   1]                 Processor ID : 79
[3F7h 1015   1]                Local Apic ID : F2
[3F8h 1016   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3FCh 1020   1]                Subtable Type : 00 [Processor Local APIC]
[3FDh 1021   1]                       Length : 08
[3FEh 1022   1]                 Processor ID : 7A
[3FFh 1023   1]                Local Apic ID : F4
[400h 1024   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[404h 1028   1]                Subtable Type : 00 [Processor Local APIC]
[405h 1029   1]                       Length : 08
[406h 1030   1]                 Processor ID : 7B
[407h 1031   1]                Local Apic ID : F6
[408h 1032   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[40Ch 1036   1]                Subtable Type : 00 [Processor Local APIC]
[40Dh 1037   1]                       Length : 08
[40Eh 1038   1]                 Processor ID : 7C
[40Fh 1039   1]                Local Apic ID : F8
[410h 1040   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[414h 1044   1]                Subtable Type : 00 [Processor Local APIC]
[415h 1045   1]                       Length : 08
[416h 1046   1]                 Processor ID : 7D
[417h 1047   1]                Local Apic ID : FA
[418h 1048   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[41Ch 1052   1]                Subtable Type : 00 [Processor Local APIC]
[41Dh 1053   1]                       Length : 08
[41Eh 1054   1]                 Processor ID : 7E
[41Fh 1055   1]                Local Apic ID : FC
[420h 1056   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[424h 1060   1]                Subtable Type : 00 [Processor Local APIC]
[425h 1061   1]                       Length : 08
[426h 1062   1]                 Processor ID : 7F
[427h 1063   1]                Local Apic ID : FE
[428h 1064   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[42Ch 1068   1]                Subtable Type : 01 [I/O APIC]
[42Dh 1069   1]                       Length : 0C
[42Eh 1070   1]                  I/O Apic ID : 01
[42Fh 1071   1]                     Reserved : 00
[430h 1072   4]                      Address : FEC00000
[434h 1076   4]                    Interrupt : 00000000

[438h 1080   1]                Subtable Type : 02 [Interrupt Source Override]
[439h 1081   1]                       Length : 0A
[43Ah 1082   1]                          Bus : 00
[43Bh 1083   1]                       Source : 00
[43Ch 1084   4]                    Interrupt : 00000002
[440h 1088   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1

[442h 1090   1]                Subtable Type : 04 [Local APIC NMI]
[443h 1091   1]                       Length : 06
[444h 1092   1]                 Processor ID : 00
[445h 1093   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[447h 1095   1]         Interrupt Input LINT : 01

[448h 1096   1]                Subtable Type : 04 [Local APIC NMI]
[449h 1097   1]                       Length : 06
[44Ah 1098   1]                 Processor ID : 01
[44Bh 1099   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[44Dh 1101   1]         Interrupt Input LINT : 01

[44Eh 1102   1]                Subtable Type : 04 [Local APIC NMI]
[44Fh 1103   1]                       Length : 06
[450h 1104   1]                 Processor ID : 02
[451h 1105   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[453h 1107   1]         Interrupt Input LINT : 01

[454h 1108   1]                Subtable Type : 04 [Local APIC NMI]
[455h 1109   1]                       Length : 06
[456h 1110   1]                 Processor ID : 03
[457h 1111   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[459h 1113   1]         Interrupt Input LINT : 01

[45Ah 1114   1]                Subtable Type : 04 [Local APIC NMI]
[45Bh 1115   1]                       Length : 06
[45Ch 1116   1]                 Processor ID : 04
[45Dh 1117   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[45Fh 1119   1]         Interrupt Input LINT : 01

[460h 1120   1]                Subtable Type : 04 [Local APIC NMI]
[461h 1121   1]                       Length : 06
[462h 1122   1]                 Processor ID : 05
[463h 1123   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[465h 1125   1]         Interrupt Input LINT : 01

[466h 1126   1]                Subtable Type : 04 [Local APIC NMI]
[467h 1127   1]                       Length : 06
[468h 1128   1]                 Processor ID : 06
[469h 1129   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[46Bh 1131   1]         Interrupt Input LINT : 01

[46Ch 1132   1]                Subtable Type : 04 [Local APIC NMI]
[46Dh 1133   1]                       Length : 06
[46Eh 1134   1]                 Processor ID : 07
[46Fh 1135   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[471h 1137   1]         Interrupt Input LINT : 01

[472h 1138   1]                Subtable Type : 04 [Local APIC NMI]
[473h 1139   1]                       Length : 06
[474h 1140   1]                 Processor ID : 08
[475h 1141   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[477h 1143   1]         Interrupt Input LINT : 01

[478h 1144   1]                Subtable Type : 04 [Local APIC NMI]
[479h 1145   1]                       Length : 06
[47Ah 1146   1]                 Processor ID : 09
[47Bh 1147   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[47Dh 1149   1]         Interrupt Input LINT : 01

[47Eh 1150   1]                Subtable Type : 04 [Local APIC NMI]
[47Fh 1151   1]                       Length : 06
[480h 1152   1]                 Processor ID : 0A
[481h 1153   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[483h 1155   1]         Interrupt Input LINT : 01

[484h 1156   1]                Subtable Type : 04 [Local APIC NMI]
[485h 1157   1]                       Length : 06
[486h 1158   1]                 Processor ID : 0B
[487h 1159   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[489h 1161   1]         Interrupt Input LINT : 01

[48Ah 1162   1]                Subtable Type : 04 [Local APIC NMI]
[48Bh 1163   1]                       Length : 06
[48Ch 1164   1]                 Processor ID : 0C
[48Dh 1165   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[48Fh 1167   1]         Interrupt Input LINT : 01

[490h 1168   1]                Subtable Type : 04 [Local APIC NMI]
[491h 1169   1]                       Length : 06
[492h 1170   1]                 Processor ID : 0D
[493h 1171   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[495h 1173   1]         Interrupt Input LINT : 01

[496h 1174   1]                Subtable Type : 04 [Local APIC NMI]
[497h 1175   1]                       Length : 06
[498h 1176   1]                 Processor ID : 0E
[499h 1177   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[49Bh 1179   1]         Interrupt Input LINT : 01

[49Ch 1180   1]                Subtable Type : 04 [Local APIC NMI]
[49Dh 1181   1]                       Length : 06
[49Eh 1182   1]                 Processor ID : 0F
[49Fh 1183   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4A1h 1185   1]         Interrupt Input LINT : 01

[4A2h 1186   1]                Subtable Type : 04 [Local APIC NMI]
[4A3h 1187   1]                       Length : 06
[4A4h 1188   1]                 Processor ID : 10
[4A5h 1189   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4A7h 1191   1]         Interrupt Input LINT : 01

[4A8h 1192   1]                Subtable Type : 04 [Local APIC NMI]
[4A9h 1193   1]                       Length : 06
[4AAh 1194   1]                 Processor ID : 11
[4ABh 1195   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4ADh 1197   1]         Interrupt Input LINT : 01

[4AEh 1198   1]                Subtable Type : 04 [Local APIC NMI]
[4AFh 1199   1]                       Length : 06
[4B0h 1200   1]                 Processor ID : 12
[4B1h 1201   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4B3h 1203   1]         Interrupt Input LINT : 01

[4B4h 1204   1]                Subtable Type : 04 [Local APIC NMI]
[4B5h 1205   1]                       Length : 06
[4B6h 1206   1]                 Processor ID : 13
[4B7h 1207   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4B9h 1209   1]         Interrupt Input LINT : 01

[4BAh 1210   1]                Subtable Type : 04 [Local APIC NMI]
[4BBh 1211   1]                       Length : 06
[4BCh 1212   1]                 Processor ID : 14
[4BDh 1213   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4BFh 1215   1]         Interrupt Input LINT : 01

[4C0h 1216   1]                Subtable Type : 04 [Local APIC NMI]
[4C1h 1217   1]                       Length : 06
[4C2h 1218   1]                 Processor ID : 15
[4C3h 1219   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4C5h 1221   1]         Interrupt Input LINT : 01

[4C6h 1222   1]                Subtable Type : 04 [Local APIC NMI]
[4C7h 1223   1]                       Length : 06
[4C8h 1224   1]                 Processor ID : 16
[4C9h 1225   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4CBh 1227   1]         Interrupt Input LINT : 01

[4CCh 1228   1]                Subtable Type : 04 [Local APIC NMI]
[4CDh 1229   1]                       Length : 06
[4CEh 1230   1]                 Processor ID : 17
[4CFh 1231   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4D1h 1233   1]         Interrupt Input LINT : 01

[4D2h 1234   1]                Subtable Type : 04 [Local APIC NMI]
[4D3h 1235   1]                       Length : 06
[4D4h 1236   1]                 Processor ID : 18
[4D5h 1237   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4D7h 1239   1]         Interrupt Input LINT : 01

[4D8h 1240   1]                Subtable Type : 04 [Local APIC NMI]
[4D9h 1241   1]                       Length : 06
[4DAh 1242   1]                 Processor ID : 19
[4DBh 1243   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4DDh 1245   1]         Interrupt Input LINT : 01

[4DEh 1246   1]                Subtable Type : 04 [Local APIC NMI]
[4DFh 1247   1]                       Length : 06
[4E0h 1248   1]                 Processor ID : 1A
[4E1h 1249   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4E3h 1251   1]         Interrupt Input LINT : 01

[4E4h 1252   1]                Subtable Type : 04 [Local APIC NMI]
[4E5h 1253   1]                       Length : 06
[4E6h 1254   1]                 Processor ID : 1B
[4E7h 1255   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4E9h 1257   1]         Interrupt Input LINT : 01

[4EAh 1258   1]                Subtable Type : 04 [Local APIC NMI]
[4EBh 1259   1]                       Length : 06
[4ECh 1260   1]                 Processor ID : 1C
[4EDh 1261   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4EFh 1263   1]         Interrupt Input LINT : 01

[4F0h 1264   1]                Subtable Type : 04 [Local APIC NMI]
[4F1h 1265   1]                       Length : 06
[4F2h 1266   1]                 Processor ID : 1D
[4F3h 1267   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4F5h 1269   1]         Interrupt Input LINT : 01

[4F6h 1270   1]                Subtable Type : 04 [Local APIC NMI]
[4F7h 1271   1]                       Length : 06
[4F8h 1272   1]                 Processor ID : 1E
[4F9h 1273   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4FBh 1275   1]         Interrupt Input LINT : 01

[4FCh 1276   1]                Subtable Type : 04 [Local APIC NMI]
[4FDh 1277   1]                       Length : 06
[4FEh 1278   1]                 Processor ID : 1F
[4FFh 1279   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[501h 1281   1]         Interrupt Input LINT : 01

[502h 1282   1]                Subtable Type : 04 [Local APIC NMI]
[503h 1283   1]                       Length : 06
[504h 1284   1]                 Processor ID : 20
[505h 1285   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[507h 1287   1]         Interrupt Input LINT : 01

[508h 1288   1]                Subtable Type : 04 [Local APIC NMI]
[509h 1289   1]                       Length : 06
[50Ah 1290   1]                 Processor ID : 21
[50Bh 1291   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[50Dh 1293   1]         Interrupt Input LINT : 01

[50Eh 1294   1]                Subtable Type : 04 [Local APIC NMI]
[50Fh 1295   1]                       Length : 06
[510h 1296   1]                 Processor ID : 22
[511h 1297   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[513h 1299   1]         Interrupt Input LINT : 01

[514h 1300   1]                Subtable Type : 04 [Local APIC NMI]
[515h 1301   1]                       Length : 06
[516h 1302   1]                 Processor ID : 23
[517h 1303   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[519h 1305   1]         Interrupt Input LINT : 01

[51Ah 1306   1]                Subtable Type : 04 [Local APIC NMI]
[51Bh 1307   1]                       Length : 06
[51Ch 1308   1]                 Processor ID : 24
[51Dh 1309   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[51Fh 1311   1]         Interrupt Input LINT : 01

[520h 1312   1]                Subtable Type : 04 [Local APIC NMI]
[521h 1313   1]                       Length : 06
[522h 1314   1]                 Processor ID : 25
[523h 1315   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[525h 1317   1]         Interrupt Input LINT : 01

[526h 1318   1]                Subtable Type : 04 [Local APIC NMI]
[527h 1319   1]                       Length : 06
[528h 1320   1]                 Processor ID : 26
[529h 1321   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[52Bh 1323   1]         Interrupt Input LINT : 01

[52Ch 1324   1]                Subtable Type : 04 [Local APIC NMI]
[52Dh 1325   1]                       Length : 06
[52Eh 1326   1]                 Processor ID : 27
[52Fh 1327   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[531h 1329   1]         Interrupt Input LINT : 01

[532h 1330   1]                Subtable Type : 04 [Local APIC NMI]
[533h 1331   1]                       Length : 06
[534h 1332   1]                 Processor ID : 28
[535h 1333   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[537h 1335   1]         Interrupt Input LINT : 01

[538h 1336   1]                Subtable Type : 04 [Local APIC NMI]
[539h 1337   1]                       Length : 06
[53Ah 1338   1]                 Processor ID : 29
[53Bh 1339   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[53Dh 1341   1]         Interrupt Input LINT : 01

[53Eh 1342   1]                Subtable Type : 04 [Local APIC NMI]
[53Fh 1343   1]                       Length : 06
[540h 1344   1]                 Processor ID : 2A
[541h 1345   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[543h 1347   1]         Interrupt Input LINT : 01

[544h 1348   1]                Subtable Type : 04 [Local APIC NMI]
[545h 1349   1]                       Length : 06
[546h 1350   1]                 Processor ID : 2B
[547h 1351   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[549h 1353   1]         Interrupt Input LINT : 01

[54Ah 1354   1]                Subtable Type : 04 [Local APIC NMI]
[54Bh 1355   1]                       Length : 06
[54Ch 1356   1]                 Processor ID : 2C
[54Dh 1357   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[54Fh 1359   1]         Interrupt Input LINT : 01

[550h 1360   1]                Subtable Type : 04 [Local APIC NMI]
[551h 1361   1]                       Length : 06
[552h 1362   1]                 Processor ID : 2D
[553h 1363   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[555h 1365   1]         Interrupt Input LINT : 01

[556h 1366   1]                Subtable Type : 04 [Local APIC NMI]
[557h 1367   1]                       Length : 06
[558h 1368   1]                 Processor ID : 2E
[559h 1369   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[55Bh 1371   1]         Interrupt Input LINT : 01

[55Ch 1372   1]                Subtable Type : 04 [Local APIC NMI]
[55Dh 1373   1]                       Length : 06
[55Eh 1374   1]                 Processor ID : 2F
[55Fh 1375   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[561h 1377   1]         Interrupt Input LINT : 01

[562h 1378   1]                Subtable Type : 04 [Local APIC NMI]
[563h 1379   1]                       Length : 06
[564h 1380   1]                 Processor ID : 30
[565h 1381   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[567h 1383   1]         Interrupt Input LINT : 01

[568h 1384   1]                Subtable Type : 04 [Local APIC NMI]
[569h 1385   1]                       Length : 06
[56Ah 1386   1]                 Processor ID : 31
[56Bh 1387   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[56Dh 1389   1]         Interrupt Input LINT : 01

[56Eh 1390   1]                Subtable Type : 04 [Local APIC NMI]
[56Fh 1391   1]                       Length : 06
[570h 1392   1]                 Processor ID : 32
[571h 1393   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[573h 1395   1]         Interrupt Input LINT : 01

[574h 1396   1]                Subtable Type : 04 [Local APIC NMI]
[575h 1397   1]                       Length : 06
[576h 1398   1]                 Processor ID : 33
[577h 1399   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[579h 1401   1]         Interrupt Input LINT : 01

[57Ah 1402   1]                Subtable Type : 04 [Local APIC NMI]
[57Bh 1403   1]                       Length : 06
[57Ch 1404   1]                 Processor ID : 34
[57Dh 1405   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[57Fh 1407   1]         Interrupt Input LINT : 01

[580h 1408   1]                Subtable Type : 04 [Local APIC NMI]
[581h 1409   1]                       Length : 06
[582h 1410   1]                 Processor ID : 35
[583h 1411   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[585h 1413   1]         Interrupt Input LINT : 01

[586h 1414   1]                Subtable Type : 04 [Local APIC NMI]
[587h 1415   1]                       Length : 06
[588h 1416   1]                 Processor ID : 36
[589h 1417   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[58Bh 1419   1]         Interrupt Input LINT : 01

[58Ch 1420   1]                Subtable Type : 04 [Local APIC NMI]
[58Dh 1421   1]                       Length : 06
[58Eh 1422   1]                 Processor ID : 37
[58Fh 1423   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[591h 1425   1]         Interrupt Input LINT : 01

[592h 1426   1]                Subtable Type : 04 [Local APIC NMI]
[593h 1427   1]                       Length : 06
[594h 1428   1]                 Processor ID : 38
[595h 1429   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[597h 1431   1]         Interrupt Input LINT : 01

[598h 1432   1]                Subtable Type : 04 [Local APIC NMI]
[599h 1433   1]                       Length : 06
[59Ah 1434   1]                 Processor ID : 39
[59Bh 1435   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[59Dh 1437   1]         Interrupt Input LINT : 01

[59Eh 1438   1]                Subtable Type : 04 [Local APIC NMI]
[59Fh 1439   1]                       Length : 06
[5A0h 1440   1]                 Processor ID : 3A
[5A1h 1441   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5A3h 1443   1]         Interrupt Input LINT : 01

[5A4h 1444   1]                Subtable Type : 04 [Local APIC NMI]
[5A5h 1445   1]                       Length : 06
[5A6h 1446   1]                 Processor ID : 3B
[5A7h 1447   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5A9h 1449   1]         Interrupt Input LINT : 01

[5AAh 1450   1]                Subtable Type : 04 [Local APIC NMI]
[5ABh 1451   1]                       Length : 06
[5ACh 1452   1]                 Processor ID : 3C
[5ADh 1453   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5AFh 1455   1]         Interrupt Input LINT : 01

[5B0h 1456   1]                Subtable Type : 04 [Local APIC NMI]
[5B1h 1457   1]                       Length : 06
[5B2h 1458   1]                 Processor ID : 3D
[5B3h 1459   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5B5h 1461   1]         Interrupt Input LINT : 01

[5B6h 1462   1]                Subtable Type : 04 [Local APIC NMI]
[5B7h 1463   1]                       Length : 06
[5B8h 1464   1]                 Processor ID : 3E
[5B9h 1465   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5BBh 1467   1]         Interrupt Input LINT : 01

[5BCh 1468   1]                Subtable Type : 04 [Local APIC NMI]
[5BDh 1469   1]                       Length : 06
[5BEh 1470   1]                 Processor ID : 3F
[5BFh 1471   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5C1h 1473   1]         Interrupt Input LINT : 01

[5C2h 1474   1]                Subtable Type : 04 [Local APIC NMI]
[5C3h 1475   1]                       Length : 06
[5C4h 1476   1]                 Processor ID : 40
[5C5h 1477   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5C7h 1479   1]         Interrupt Input LINT : 01

[5C8h 1480   1]                Subtable Type : 04 [Local APIC NMI]
[5C9h 1481   1]                       Length : 06
[5CAh 1482   1]                 Processor ID : 41
[5CBh 1483   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5CDh 1485   1]         Interrupt Input LINT : 01

[5CEh 1486   1]                Subtable Type : 04 [Local APIC NMI]
[5CFh 1487   1]                       Length : 06
[5D0h 1488   1]                 Processor ID : 42
[5D1h 1489   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5D3h 1491   1]         Interrupt Input LINT : 01

[5D4h 1492   1]                Subtable Type : 04 [Local APIC NMI]
[5D5h 1493   1]                       Length : 06
[5D6h 1494   1]                 Processor ID : 43
[5D7h 1495   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5D9h 1497   1]         Interrupt Input LINT : 01

[5DAh 1498   1]                Subtable Type : 04 [Local APIC NMI]
[5DBh 1499   1]                       Length : 06
[5DCh 1500   1]                 Processor ID : 44
[5DDh 1501   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5DFh 1503   1]         Interrupt Input LINT : 01

[5E0h 1504   1]                Subtable Type : 04 [Local APIC NMI]
[5E1h 1505   1]                       Length : 06
[5E2h 1506   1]                 Processor ID : 45
[5E3h 1507   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5E5h 1509   1]         Interrupt Input LINT : 01

[5E6h 1510   1]                Subtable Type : 04 [Local APIC NMI]
[5E7h 1511   1]                       Length : 06
[5E8h 1512   1]                 Processor ID : 46
[5E9h 1513   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5EBh 1515   1]         Interrupt Input LINT : 01

[5ECh 1516   1]                Subtable Type : 04 [Local APIC NMI]
[5EDh 1517   1]                       Length : 06
[5EEh 1518   1]                 Processor ID : 47
[5EFh 1519   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5F1h 1521   1]         Interrupt Input LINT : 01

[5F2h 1522   1]                Subtable Type : 04 [Local APIC NMI]
[5F3h 1523   1]                       Length : 06
[5F4h 1524   1]                 Processor ID : 48
[5F5h 1525   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5F7h 1527   1]         Interrupt Input LINT : 01

[5F8h 1528   1]                Subtable Type : 04 [Local APIC NMI]
[5F9h 1529   1]                       Length : 06
[5FAh 1530   1]                 Processor ID : 49
[5FBh 1531   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5FDh 1533   1]         Interrupt Input LINT : 01

[5FEh 1534   1]                Subtable Type : 04 [Local APIC NMI]
[5FFh 1535   1]                       Length : 06
[600h 1536   1]                 Processor ID : 4A
[601h 1537   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[603h 1539   1]         Interrupt Input LINT : 01

[604h 1540   1]                Subtable Type : 04 [Local APIC NMI]
[605h 1541   1]                       Length : 06
[606h 1542   1]                 Processor ID : 4B
[607h 1543   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[609h 1545   1]         Interrupt Input LINT : 01

[60Ah 1546   1]                Subtable Type : 04 [Local APIC NMI]
[60Bh 1547   1]                       Length : 06
[60Ch 1548   1]                 Processor ID : 4C
[60Dh 1549   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[60Fh 1551   1]         Interrupt Input LINT : 01

[610h 1552   1]                Subtable Type : 04 [Local APIC NMI]
[611h 1553   1]                       Length : 06
[612h 1554   1]                 Processor ID : 4D
[613h 1555   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[615h 1557   1]         Interrupt Input LINT : 01

[616h 1558   1]                Subtable Type : 04 [Local APIC NMI]
[617h 1559   1]                       Length : 06
[618h 1560   1]                 Processor ID : 4E
[619h 1561   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[61Bh 1563   1]         Interrupt Input LINT : 01

[61Ch 1564   1]                Subtable Type : 04 [Local APIC NMI]
[61Dh 1565   1]                       Length : 06
[61Eh 1566   1]                 Processor ID : 4F
[61Fh 1567   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[621h 1569   1]         Interrupt Input LINT : 01

[622h 1570   1]                Subtable Type : 04 [Local APIC NMI]
[623h 1571   1]                       Length : 06
[624h 1572   1]                 Processor ID : 50
[625h 1573   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[627h 1575   1]         Interrupt Input LINT : 01

[628h 1576   1]                Subtable Type : 04 [Local APIC NMI]
[629h 1577   1]                       Length : 06
[62Ah 1578   1]                 Processor ID : 51
[62Bh 1579   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[62Dh 1581   1]         Interrupt Input LINT : 01

[62Eh 1582   1]                Subtable Type : 04 [Local APIC NMI]
[62Fh 1583   1]                       Length : 06
[630h 1584   1]                 Processor ID : 52
[631h 1585   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[633h 1587   1]         Interrupt Input LINT : 01

[634h 1588   1]                Subtable Type : 04 [Local APIC NMI]
[635h 1589   1]                       Length : 06
[636h 1590   1]                 Processor ID : 53
[637h 1591   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[639h 1593   1]         Interrupt Input LINT : 01

[63Ah 1594   1]                Subtable Type : 04 [Local APIC NMI]
[63Bh 1595   1]                       Length : 06
[63Ch 1596   1]                 Processor ID : 54
[63Dh 1597   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[63Fh 1599   1]         Interrupt Input LINT : 01

[640h 1600   1]                Subtable Type : 04 [Local APIC NMI]
[641h 1601   1]                       Length : 06
[642h 1602   1]                 Processor ID : 55
[643h 1603   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[645h 1605   1]         Interrupt Input LINT : 01

[646h 1606   1]                Subtable Type : 04 [Local APIC NMI]
[647h 1607   1]                       Length : 06
[648h 1608   1]                 Processor ID : 56
[649h 1609   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[64Bh 1611   1]         Interrupt Input LINT : 01

[64Ch 1612   1]                Subtable Type : 04 [Local APIC NMI]
[64Dh 1613   1]                       Length : 06
[64Eh 1614   1]                 Processor ID : 57
[64Fh 1615   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[651h 1617   1]         Interrupt Input LINT : 01

[652h 1618   1]                Subtable Type : 04 [Local APIC NMI]
[653h 1619   1]                       Length : 06
[654h 1620   1]                 Processor ID : 58
[655h 1621   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[657h 1623   1]         Interrupt Input LINT : 01

[658h 1624   1]                Subtable Type : 04 [Local APIC NMI]
[659h 1625   1]                       Length : 06
[65Ah 1626   1]                 Processor ID : 59
[65Bh 1627   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[65Dh 1629   1]         Interrupt Input LINT : 01

[65Eh 1630   1]                Subtable Type : 04 [Local APIC NMI]
[65Fh 1631   1]                       Length : 06
[660h 1632   1]                 Processor ID : 5A
[661h 1633   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[663h 1635   1]         Interrupt Input LINT : 01

[664h 1636   1]                Subtable Type : 04 [Local APIC NMI]
[665h 1637   1]                       Length : 06
[666h 1638   1]                 Processor ID : 5B
[667h 1639   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[669h 1641   1]         Interrupt Input LINT : 01

[66Ah 1642   1]                Subtable Type : 04 [Local APIC NMI]
[66Bh 1643   1]                       Length : 06
[66Ch 1644   1]                 Processor ID : 5C
[66Dh 1645   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[66Fh 1647   1]         Interrupt Input LINT : 01

[670h 1648   1]                Subtable Type : 04 [Local APIC NMI]
[671h 1649   1]                       Length : 06
[672h 1650   1]                 Processor ID : 5D
[673h 1651   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[675h 1653   1]         Interrupt Input LINT : 01

[676h 1654   1]                Subtable Type : 04 [Local APIC NMI]
[677h 1655   1]                       Length : 06
[678h 1656   1]                 Processor ID : 5E
[679h 1657   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[67Bh 1659   1]         Interrupt Input LINT : 01

[67Ch 1660   1]                Subtable Type : 04 [Local APIC NMI]
[67Dh 1661   1]                       Length : 06
[67Eh 1662   1]                 Processor ID : 5F
[67Fh 1663   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[681h 1665   1]         Interrupt Input LINT : 01

[682h 1666   1]                Subtable Type : 04 [Local APIC NMI]
[683h 1667   1]                       Length : 06
[684h 1668   1]                 Processor ID : 60
[685h 1669   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[687h 1671   1]         Interrupt Input LINT : 01

[688h 1672   1]                Subtable Type : 04 [Local APIC NMI]
[689h 1673   1]                       Length : 06
[68Ah 1674   1]                 Processor ID : 61
[68Bh 1675   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[68Dh 1677   1]         Interrupt Input LINT : 01

[68Eh 1678   1]                Subtable Type : 04 [Local APIC NMI]
[68Fh 1679   1]                       Length : 06
[690h 1680   1]                 Processor ID : 62
[691h 1681   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[693h 1683   1]         Interrupt Input LINT : 01

[694h 1684   1]                Subtable Type : 04 [Local APIC NMI]
[695h 1685   1]                       Length : 06
[696h 1686   1]                 Processor ID : 63
[697h 1687   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[699h 1689   1]         Interrupt Input LINT : 01

[69Ah 1690   1]                Subtable Type : 04 [Local APIC NMI]
[69Bh 1691   1]                       Length : 06
[69Ch 1692   1]                 Processor ID : 64
[69Dh 1693   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[69Fh 1695   1]         Interrupt Input LINT : 01

[6A0h 1696   1]                Subtable Type : 04 [Local APIC NMI]
[6A1h 1697   1]                       Length : 06
[6A2h 1698   1]                 Processor ID : 65
[6A3h 1699   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6A5h 1701   1]         Interrupt Input LINT : 01

[6A6h 1702   1]                Subtable Type : 04 [Local APIC NMI]
[6A7h 1703   1]                       Length : 06
[6A8h 1704   1]                 Processor ID : 66
[6A9h 1705   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6ABh 1707   1]         Interrupt Input LINT : 01

[6ACh 1708   1]                Subtable Type : 04 [Local APIC NMI]
[6ADh 1709   1]                       Length : 06
[6AEh 1710   1]                 Processor ID : 67
[6AFh 1711   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6B1h 1713   1]         Interrupt Input LINT : 01

[6B2h 1714   1]                Subtable Type : 04 [Local APIC NMI]
[6B3h 1715   1]                       Length : 06
[6B4h 1716   1]                 Processor ID : 68
[6B5h 1717   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6B7h 1719   1]         Interrupt Input LINT : 01

[6B8h 1720   1]                Subtable Type : 04 [Local APIC NMI]
[6B9h 1721   1]                       Length : 06
[6BAh 1722   1]                 Processor ID : 69
[6BBh 1723   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6BDh 1725   1]         Interrupt Input LINT : 01

[6BEh 1726   1]                Subtable Type : 04 [Local APIC NMI]
[6BFh 1727   1]                       Length : 06
[6C0h 1728   1]                 Processor ID : 6A
[6C1h 1729   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6C3h 1731   1]         Interrupt Input LINT : 01

[6C4h 1732   1]                Subtable Type : 04 [Local APIC NMI]
[6C5h 1733   1]                       Length : 06
[6C6h 1734   1]                 Processor ID : 6B
[6C7h 1735   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6C9h 1737   1]         Interrupt Input LINT : 01

[6CAh 1738   1]                Subtable Type : 04 [Local APIC NMI]
[6CBh 1739   1]                       Length : 06
[6CCh 1740   1]                 Processor ID : 6C
[6CDh 1741   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6CFh 1743   1]         Interrupt Input LINT : 01

[6D0h 1744   1]                Subtable Type : 04 [Local APIC NMI]
[6D1h 1745   1]                       Length : 06
[6D2h 1746   1]                 Processor ID : 6D
[6D3h 1747   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6D5h 1749   1]         Interrupt Input LINT : 01

[6D6h 1750   1]                Subtable Type : 04 [Local APIC NMI]
[6D7h 1751   1]                       Length : 06
[6D8h 1752   1]                 Processor ID : 6E
[6D9h 1753   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6DBh 1755   1]         Interrupt Input LINT : 01

[6DCh 1756   1]                Subtable Type : 04 [Local APIC NMI]
[6DDh 1757   1]                       Length : 06
[6DEh 1758   1]                 Processor ID : 6F
[6DFh 1759   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6E1h 1761   1]         Interrupt Input LINT : 01

[6E2h 1762   1]                Subtable Type : 04 [Local APIC NMI]
[6E3h 1763   1]                       Length : 06
[6E4h 1764   1]                 Processor ID : 70
[6E5h 1765   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6E7h 1767   1]         Interrupt Input LINT : 01

[6E8h 1768   1]                Subtable Type : 04 [Local APIC NMI]
[6E9h 1769   1]                       Length : 06
[6EAh 1770   1]                 Processor ID : 71
[6EBh 1771   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6EDh 1773   1]         Interrupt Input LINT : 01

[6EEh 1774   1]                Subtable Type : 04 [Local APIC NMI]
[6EFh 1775   1]                       Length : 06
[6F0h 1776   1]                 Processor ID : 72
[6F1h 1777   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6F3h 1779   1]         Interrupt Input LINT : 01

[6F4h 1780   1]                Subtable Type : 04 [Local APIC NMI]
[6F5h 1781   1]                       Length : 06
[6F6h 1782   1]                 Processor ID : 73
[6F7h 1783   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6F9h 1785   1]         Interrupt Input LINT : 01

[6FAh 1786   1]                Subtable Type : 04 [Local APIC NMI]
[6FBh 1787   1]                       Length : 06
[6FCh 1788   1]                 Processor ID : 74
[6FDh 1789   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6FFh 1791   1]         Interrupt Input LINT : 01

[700h 1792   1]                Subtable Type : 04 [Local APIC NMI]
[701h 1793   1]                       Length : 06
[702h 1794   1]                 Processor ID : 75
[703h 1795   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[705h 1797   1]         Interrupt Input LINT : 01

[706h 1798   1]                Subtable Type : 04 [Local APIC NMI]
[707h 1799   1]                       Length : 06
[708h 1800   1]                 Processor ID : 76
[709h 1801   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[70Bh 1803   1]         Interrupt Input LINT : 01

[70Ch 1804   1]                Subtable Type : 04 [Local APIC NMI]
[70Dh 1805   1]                       Length : 06
[70Eh 1806   1]                 Processor ID : 77
[70Fh 1807   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[711h 1809   1]         Interrupt Input LINT : 01

[712h 1810   1]                Subtable Type : 04 [Local APIC NMI]
[713h 1811   1]                       Length : 06
[714h 1812   1]                 Processor ID : 78
[715h 1813   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[717h 1815   1]         Interrupt Input LINT : 01

[718h 1816   1]                Subtable Type : 04 [Local APIC NMI]
[719h 1817   1]                       Length : 06
[71Ah 1818   1]                 Processor ID : 79
[71Bh 1819   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[71Dh 1821   1]         Interrupt Input LINT : 01

[71Eh 1822   1]                Subtable Type : 04 [Local APIC NMI]
[71Fh 1823   1]                       Length : 06
[720h 1824   1]                 Processor ID : 7A
[721h 1825   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[723h 1827   1]         Interrupt Input LINT : 01

[724h 1828   1]                Subtable Type : 04 [Local APIC NMI]
[725h 1829   1]                       Length : 06
[726h 1830   1]                 Processor ID : 7B
[727h 1831   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[729h 1833   1]         Interrupt Input LINT : 01

[72Ah 1834   1]                Subtable Type : 04 [Local APIC NMI]
[72Bh 1835   1]                       Length : 06
[72Ch 1836   1]                 Processor ID : 7C
[72Dh 1837   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[72Fh 1839   1]         Interrupt Input LINT : 01

[730h 1840   1]                Subtable Type : 04 [Local APIC NMI]
[731h 1841   1]                       Length : 06
[732h 1842   1]                 Processor ID : 7D
[733h 1843   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[735h 1845   1]         Interrupt Input LINT : 01

[736h 1846   1]                Subtable Type : 04 [Local APIC NMI]
[737h 1847   1]                       Length : 06
[738h 1848   1]                 Processor ID : 7E
[739h 1849   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[73Bh 1851   1]         Interrupt Input LINT : 01

[73Ch 1852   1]                Subtable Type : 04 [Local APIC NMI]
[73Dh 1853   1]                       Length : 06
[73Eh 1854   1]                 Processor ID : 7F
[73Fh 1855   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[741h 1857   1]         Interrupt Input LINT : 01

Raw Table Data: Length 1858 (0x742)

  0000: 41 50 49 43 42 07 00 00 01 8F 50 54 4C 54 44 20  // APICB.....PTLTD 
  0010: 09 20 41 50 49 43 20 20 00 00 04 06 20 4C 54 50  // . APIC  .... LTP
  0020: 00 00 00 00 00 00 E0 FE 01 00 00 00 00 08 00 00  // ................
  0030: 01 00 00 00 00 08 01 02 01 00 00 00 00 08 02 04  // ................
  0040: 01 00 00 00 00 08 03 06 01 00 00 00 00 08 04 08  // ................
  0050: 00 00 00 00 00 08 05 0A 00 00 00 00 00 08 06 0C  // ................
  0060: 00 00 00 00 00 08 07 0E 00 00 00 00 00 08 08 10  // ................
  0070: 00 00 00 00 00 08 09 12 00 00 00 00 00 08 0A 14  // ................
  0080: 00 00 00 00 00 08 0B 16 00 00 00 00 00 08 0C 18  // ................
  0090: 00 00 00 00 00 08 0D 1A 00 00 00 00 00 08 0E 1C  // ................
  00A0: 00 00 00 00 00 08 0F 1E 00 00 00 00 00 08 10 20  // ............... 
  00B0: 00 00 00 00 00 08 11 22 00 00 00 00 00 08 12 24  // .......".......$
  00C0: 00 00 00 00 00 08 13 26 00 00 00 00 00 08 14 28  // .......&.......(
  00D0: 00 00 00 00 00 08 15 2A 00 00 00 00 00 08 16 2C  // .......*.......,
  00E0: 00 00 00 00 00 08 17 2E 00 00 00 00 00 08 18 30  // ...............0
  00F0: 00 00 00 00 00 08 19 32 00 00 00 00 00 08 1A 34  // .......2.......4
  0100: 00 00 00 00 00 08 1B 36 00 00 00 00 00 08 1C 38  // .......6.......8
  0110: 00 00 00 00 00 08 1D 3A 00 00 00 00 00 08 1E 3C  // .......:.......<
  0120: 00 00 00 00 00 08 1F 3E 00 00 00 00 00 08 20 40  // .......>...... @
  0130: 00 00 00 00 00 08 21 42 00 00 00 00 00 08 22 44  // ......!B......"D
  0140: 00 00 00 00 00 08 23 46 00 00 00 00 00 08 24 48  // ......#F......$H
  0150: 00 00 00 00 00 08 25 4A 00 00 00 00 00 08 26 4C  // ......%J......&L
  0160: 00 00 00 00 00 08 27 4E 00 00 00 00 00 08 28 50  // ......'N......(P
  0170: 00 00 00 00 00 08 29 52 00 00 00 00 00 08 2A 54  // ......)R......*T
  0180: 00 00 00 00 00 08 2B 56 00 00 00 00 00 08 2C 58  // ......+V......,X
  0190: 00 00 00 00 00 08 2D 5A 00 00 00 00 00 08 2E 5C  // ......-Z.......\
  01A0: 00 00 00 00 00 08 2F 5E 00 00 00 00 00 08 30 60  // ....../^......0`
  01B0: 00 00 00 00 00 08 31 62 00 00 00 00 00 08 32 64  // ......1b......2d
  01C0: 00 00 00 00 00 08 33 66 00 00 00 00 00 08 34 68  // ......3f......4h
  01D0: 00 00 00 00 00 08 35 6A 00 00 00 00 00 08 36 6C  // ......5j......6l
  01E0: 00 00 00 00 00 08 37 6E 00 00 00 00 00 08 38 70  // ......7n......8p
  01F0: 00 00 00 00 00 08 39 72 00 00 00 00 00 08 3A 74  // ......9r......:t
  0200: 00 00 00 00 00 08 3B 76 00 00 00 00 00 08 3C 78  // ......;v......<x
  0210: 00 00 00 00 00 08 3D 7A 00 00 00 00 00 08 3E 7C  // ......=z......>|
  0220: 00 00 00 00 00 08 3F 7E 00 00 00 00 00 08 40 80  // ......?~......@.
  0230: 00 00 00 00 00 08 41 82 00 00 00 00 00 08 42 84  // ......A.......B.
  0240: 00 00 00 00 00 08 43 86 00 00 00 00 00 08 44 88  // ......C.......D.
  0250: 00 00 00 00 00 08 45 8A 00 00 00 00 00 08 46 8C  // ......E.......F.
  0260: 00 00 00 00 00 08 47 8E 00 00 00 00 00 08 48 90  // ......G.......H.
  0270: 00 00 00 00 00 08 49 92 00 00 00 00 00 08 4A 94  // ......I.......J.
  0280: 00 00 00 00 00 08 4B 96 00 00 00 00 00 08 4C 98  // ......K.......L.
  0290: 00 00 00 00 00 08 4D 9A 00 00 00 00 00 08 4E 9C  // ......M.......N.
  02A0: 00 00 00 00 00 08 4F 9E 00 00 00 00 00 08 50 A0  // ......O.......P.
  02B0: 00 00 00 00 00 08 51 A2 00 00 00 00 00 08 52 A4  // ......Q.......R.
  02C0: 00 00 00 00 00 08 53 A6 00 00 00 00 00 08 54 A8  // ......S.......T.
  02D0: 00 00 00 00 00 08 55 AA 00 00 00 00 00 08 56 AC  // ......U.......V.
  02E0: 00 00 00 00 00 08 57 AE 00 00 00 00 00 08 58 B0  // ......W.......X.
  02F0: 00 00 00 00 00 08 59 B2 00 00 00 00 00 08 5A B4  // ......Y.......Z.
  0300: 00 00 00 00 00 08 5B B6 00 00 00 00 00 08 5C B8  // ......[.......\.
  0310: 00 00 00 00 00 08 5D BA 00 00 00 00 00 08 5E BC  // ......].......^.
  0320: 00 00 00 00 00 08 5F BE 00 00 00 00 00 08 60 C0  // ......_.......`.
  0330: 00 00 00 00 00 08 61 C2 00 00 00 00 00 08 62 C4  // ......a.......b.
  0340: 00 00 00 00 00 08 63 C6 00 00 00 00 00 08 64 C8  // ......c.......d.
  0350: 00 00 00 00 00 08 65 CA 00 00 00 00 00 08 66 CC  // ......e.......f.
  0360: 00 00 00 00 00 08 67 CE 00 00 00 00 00 08 68 D0  // ......g.......h.
  0370: 00 00 00 00 00 08 69 D2 00 00 00 00 00 08 6A D4  // ......i.......j.
  0380: 00 00 00 00 00 08 6B D6 00 00 00 00 00 08 6C D8  // ......k.......l.
  0390: 00 00 00 00 00 08 6D DA 00 00 00 00 00 08 6E DC  // ......m.......n.
  03A0: 00 00 00 00 00 08 6F DE 00 00 00 00 00 08 70 E0  // ......o.......p.
  03B0: 00 00 00 00 00 08 71 E2 00 00 00 00 00 08 72 E4  // ......q.......r.
  03C0: 00 00 00 00 00 08 73 E6 00 00 00 00 00 08 74 E8  // ......s.......t.
  03D0: 00 00 00 00 00 08 75 EA 00 00 00 00 00 08 76 EC  // ......u.......v.
  03E0: 00 00 00 00 00 08 77 EE 00 00 00 00 00 08 78 F0  // ......w.......x.
  03F0: 00 00 00 00 00 08 79 F2 00 00 00 00 00 08 7A F4  // ......y.......z.
  0400: 00 00 00 00 00 08 7B F6 00 00 00 00 00 08 7C F8  // ......{.......|.
  0410: 00 00 00 00 00 08 7D FA 00 00 00 00 00 08 7E FC  // ......}.......~.
  0420: 00 00 00 00 00 08 7F FE 00 00 00 00 01 0C 01 00  // ................
  0430: 00 00 C0 FE 00 00 00 00 02 0A 00 00 02 00 00 00  // ................
  0440: 05 00 04 06 00 05 00 01 04 06 01 05 00 01 04 06  // ................
  0450: 02 05 00 01 04 06 03 05 00 01 04 06 04 05 00 01  // ................
  0460: 04 06 05 05 00 01 04 06 06 05 00 01 04 06 07 05  // ................
  0470: 00 01 04 06 08 05 00 01 04 06 09 05 00 01 04 06  // ................
  0480: 0A 05 00 01 04 06 0B 05 00 01 04 06 0C 05 00 01  // ................
  0490: 04 06 0D 05 00 01 04 06 0E 05 00 01 04 06 0F 05  // ................
  04A0: 00 01 04 06 10 05 00 01 04 06 11 05 00 01 04 06  // ................
  04B0: 12 05 00 01 04 06 13 05 00 01 04 06 14 05 00 01  // ................
  04C0: 04 06 15 05 00 01 04 06 16 05 00 01 04 06 17 05  // ................
  04D0: 00 01 04 06 18 05 00 01 04 06 19 05 00 01 04 06  // ................
  04E0: 1A 05 00 01 04 06 1B 05 00 01 04 06 1C 05 00 01  // ................
  04F0: 04 06 1D 05 00 01 04 06 1E 05 00 01 04 06 1F 05  // ................
  0500: 00 01 04 06 20 05 00 01 04 06 21 05 00 01 04 06  // .... .....!.....
  0510: 22 05 00 01 04 06 23 05 00 01 04 06 24 05 00 01  // ".....#.....$...
  0520: 04 06 25 05 00 01 04 06 26 05 00 01 04 06 27 05  // ..%.....&.....'.
  0530: 00 01 04 06 28 05 00 01 04 06 29 05 00 01 04 06  // ....(.....).....
  0540: 2A 05 00 01 04 06 2B 05 00 01 04 06 2C 05 00 01  // *.....+.....,...
  0550: 04 06 2D 05 00 01 04 06 2E 05 00 01 04 06 2F 05  // ..-.........../.
  0560: 00 01 04 06 30 05 00 01 04 06 31 05 00 01 04 06  // ....0.....1.....
  0570: 32 05 00 01 04 06 33 05 00 01 04 06 34 05 00 01  // 2.....3.....4...
  0580: 04 06 35 05 00 01 04 06 36 05 00 01 04 06 37 05  // ..5.....6.....7.
  0590: 00 01 04 06 38 05 00 01 04 06 39 05 00 01 04 06  // ....8.....9.....
  05A0: 3A 05 00 01 04 06 3B 05 00 01 04 06 3C 05 00 01  // :.....;.....<...
  05B0: 04 06 3D 05 00 01 04 06 3E 05 00 01 04 06 3F 05  // ..=.....>.....?.
  05C0: 00 01 04 06 40 05 00 01 04 06 41 05 00 01 04 06  // ....@.....A.....
  05D0: 42 05 00 01 04 06 43 05 00 01 04 06 44 05 00 01  // B.....C.....D...
  05E0: 04 06 45 05 00 01 04 06 46 05 00 01 04 06 47 05  // ..E.....F.....G.
  05F0: 00 01 04 06 48 05 00 01 04 06 49 05 00 01 04 06  // ....H.....I.....
  0600: 4A 05 00 01 04 06 4B 05 00 01 04 06 4C 05 00 01  // J.....K.....L...
  0610: 04 06 4D 05 00 01 04 06 4E 05 00 01 04 06 4F 05  // ..M.....N.....O.
  0620: 00 01 04 06 50 05 00 01 04 06 51 05 00 01 04 06  // ....P.....Q.....
  0630: 52 05 00 01 04 06 53 05 00 01 04 06 54 05 00 01  // R.....S.....T...
  0640: 04 06 55 05 00 01 04 06 56 05 00 01 04 06 57 05  // ..U.....V.....W.
  0650: 00 01 04 06 58 05 00 01 04 06 59 05 00 01 04 06  // ....X.....Y.....
  0660: 5A 05 00 01 04 06 5B 05 00 01 04 06 5C 05 00 01  // Z.....[.....\...
  0670: 04 06 5D 05 00 01 04 06 5E 05 00 01 04 06 5F 05  // ..].....^....._.
  0680: 00 01 04 06 60 05 00 01 04 06 61 05 00 01 04 06  // ....`.....a.....
  0690: 62 05 00 01 04 06 63 05 00 01 04 06 64 05 00 01  // b.....c.....d...
  06A0: 04 06 65 05 00 01 04 06 66 05 00 01 04 06 67 05  // ..e.....f.....g.
  06B0: 00 01 04 06 68 05 00 01 04 06 69 05 00 01 04 06  // ....h.....i.....
  06C0: 6A 05 00 01 04 06 6B 05 00 01 04 06 6C 05 00 01  // j.....k.....l...
  06D0: 04 06 6D 05 00 01 04 06 6E 05 00 01 04 06 6F 05  // ..m.....n.....o.
  06E0: 00 01 04 06 70 05 00 01 04 06 71 05 00 01 04 06  // ....p.....q.....
  06F0: 72 05 00 01 04 06 73 05 00 01 04 06 74 05 00 01  // r.....s.....t...
  0700: 04 06 75 05 00 01 04 06 76 05 00 01 04 06 77 05  // ..u.....v.....w.
  0710: 00 01 04 06 78 05 00 01 04 06 79 05 00 01 04 06  // ....x.....y.....
  0720: 7A 05 00 01 04 06 7B 05 00 01 04 06 7C 05 00 01  // z.....{.....|...
  0730: 04 06 7D 05 00 01 04 06 7E 05 00 01 04 06 7F 05  // ..}.....~.......
  0740: 00 01                                            // ..
