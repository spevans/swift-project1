/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20180105 (64-bit version)
 * Copyright (c) 2000 - 2018 Intel Corporation
 * 
 * Disassembly of apic.dat, Fri Jul 17 14:13:23 2020
 *
 * ACPI Data Table [APIC]
 *
 * Format: [HexOffset DecimalOffset ByteLength]  FieldName : FieldValue
 */

[000h 0000   4]                    Signature : "APIC"    [Multiple APIC Description Table (MADT)]
[004h 0004   4]                 Table Length : 00000742
[008h 0008   1]                     Revision : 03
[009h 0009   1]                     Checksum : 79
[00Ah 0010   6]                       Oem ID : "VMWARE"
[010h 0016   8]                 Oem Table ID : "EFIAPIC "
[018h 0024   4]                 Oem Revision : 06040001
[01Ch 0028   4]              Asl Compiler ID : "VMW "
[020h 0032   4]        Asl Compiler Revision : 000007CE

[024h 0036   4]           Local Apic Address : FEE00000
[028h 0040   4]        Flags (decoded below) : 00000001
                         PC-AT Compatibility : 1

[02Ch 0044   1]                Subtable Type : 00 [Processor Local APIC]
[02Dh 0045   1]                       Length : 08
[02Eh 0046   1]                 Processor ID : 00
[02Fh 0047   1]                Local Apic ID : 00
[030h 0048   4]        Flags (decoded below) : 00000001
                           Processor Enabled : 1

[034h 0052   1]                Subtable Type : 04 [Local APIC NMI]
[035h 0053   1]                       Length : 06
[036h 0054   1]                 Processor ID : 00
[037h 0055   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[039h 0057   1]         Interrupt Input LINT : 01

[03Ah 0058   1]                Subtable Type : 00 [Processor Local APIC]
[03Bh 0059   1]                       Length : 08
[03Ch 0060   1]                 Processor ID : 01
[03Dh 0061   1]                Local Apic ID : 02
[03Eh 0062   4]        Flags (decoded below) : 00000001
                           Processor Enabled : 1

[042h 0066   1]                Subtable Type : 04 [Local APIC NMI]
[043h 0067   1]                       Length : 06
[044h 0068   1]                 Processor ID : 01
[045h 0069   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[047h 0071   1]         Interrupt Input LINT : 01

[048h 0072   1]                Subtable Type : 00 [Processor Local APIC]
[049h 0073   1]                       Length : 08
[04Ah 0074   1]                 Processor ID : 02
[04Bh 0075   1]                Local Apic ID : 04
[04Ch 0076   4]        Flags (decoded below) : 00000001
                           Processor Enabled : 1

[050h 0080   1]                Subtable Type : 04 [Local APIC NMI]
[051h 0081   1]                       Length : 06
[052h 0082   1]                 Processor ID : 02
[053h 0083   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[055h 0085   1]         Interrupt Input LINT : 01

[056h 0086   1]                Subtable Type : 00 [Processor Local APIC]
[057h 0087   1]                       Length : 08
[058h 0088   1]                 Processor ID : 03
[059h 0089   1]                Local Apic ID : 06
[05Ah 0090   4]        Flags (decoded below) : 00000001
                           Processor Enabled : 1

[05Eh 0094   1]                Subtable Type : 04 [Local APIC NMI]
[05Fh 0095   1]                       Length : 06
[060h 0096   1]                 Processor ID : 03
[061h 0097   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[063h 0099   1]         Interrupt Input LINT : 01

[064h 0100   1]                Subtable Type : 00 [Processor Local APIC]
[065h 0101   1]                       Length : 08
[066h 0102   1]                 Processor ID : 04
[067h 0103   1]                Local Apic ID : 08
[068h 0104   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[06Ch 0108   1]                Subtable Type : 04 [Local APIC NMI]
[06Dh 0109   1]                       Length : 06
[06Eh 0110   1]                 Processor ID : 04
[06Fh 0111   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[071h 0113   1]         Interrupt Input LINT : 01

[072h 0114   1]                Subtable Type : 00 [Processor Local APIC]
[073h 0115   1]                       Length : 08
[074h 0116   1]                 Processor ID : 05
[075h 0117   1]                Local Apic ID : 0A
[076h 0118   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[07Ah 0122   1]                Subtable Type : 04 [Local APIC NMI]
[07Bh 0123   1]                       Length : 06
[07Ch 0124   1]                 Processor ID : 05
[07Dh 0125   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[07Fh 0127   1]         Interrupt Input LINT : 01

[080h 0128   1]                Subtable Type : 00 [Processor Local APIC]
[081h 0129   1]                       Length : 08
[082h 0130   1]                 Processor ID : 06
[083h 0131   1]                Local Apic ID : 0C
[084h 0132   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[088h 0136   1]                Subtable Type : 04 [Local APIC NMI]
[089h 0137   1]                       Length : 06
[08Ah 0138   1]                 Processor ID : 06
[08Bh 0139   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[08Dh 0141   1]         Interrupt Input LINT : 01

[08Eh 0142   1]                Subtable Type : 00 [Processor Local APIC]
[08Fh 0143   1]                       Length : 08
[090h 0144   1]                 Processor ID : 07
[091h 0145   1]                Local Apic ID : 0E
[092h 0146   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[096h 0150   1]                Subtable Type : 04 [Local APIC NMI]
[097h 0151   1]                       Length : 06
[098h 0152   1]                 Processor ID : 07
[099h 0153   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[09Bh 0155   1]         Interrupt Input LINT : 01

[09Ch 0156   1]                Subtable Type : 00 [Processor Local APIC]
[09Dh 0157   1]                       Length : 08
[09Eh 0158   1]                 Processor ID : 08
[09Fh 0159   1]                Local Apic ID : 10
[0A0h 0160   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0A4h 0164   1]                Subtable Type : 04 [Local APIC NMI]
[0A5h 0165   1]                       Length : 06
[0A6h 0166   1]                 Processor ID : 08
[0A7h 0167   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[0A9h 0169   1]         Interrupt Input LINT : 01

[0AAh 0170   1]                Subtable Type : 00 [Processor Local APIC]
[0ABh 0171   1]                       Length : 08
[0ACh 0172   1]                 Processor ID : 09
[0ADh 0173   1]                Local Apic ID : 12
[0AEh 0174   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0B2h 0178   1]                Subtable Type : 04 [Local APIC NMI]
[0B3h 0179   1]                       Length : 06
[0B4h 0180   1]                 Processor ID : 09
[0B5h 0181   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[0B7h 0183   1]         Interrupt Input LINT : 01

[0B8h 0184   1]                Subtable Type : 00 [Processor Local APIC]
[0B9h 0185   1]                       Length : 08
[0BAh 0186   1]                 Processor ID : 0A
[0BBh 0187   1]                Local Apic ID : 14
[0BCh 0188   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0C0h 0192   1]                Subtable Type : 04 [Local APIC NMI]
[0C1h 0193   1]                       Length : 06
[0C2h 0194   1]                 Processor ID : 0A
[0C3h 0195   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[0C5h 0197   1]         Interrupt Input LINT : 01

[0C6h 0198   1]                Subtable Type : 00 [Processor Local APIC]
[0C7h 0199   1]                       Length : 08
[0C8h 0200   1]                 Processor ID : 0B
[0C9h 0201   1]                Local Apic ID : 16
[0CAh 0202   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0CEh 0206   1]                Subtable Type : 04 [Local APIC NMI]
[0CFh 0207   1]                       Length : 06
[0D0h 0208   1]                 Processor ID : 0B
[0D1h 0209   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[0D3h 0211   1]         Interrupt Input LINT : 01

[0D4h 0212   1]                Subtable Type : 00 [Processor Local APIC]
[0D5h 0213   1]                       Length : 08
[0D6h 0214   1]                 Processor ID : 0C
[0D7h 0215   1]                Local Apic ID : 18
[0D8h 0216   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0DCh 0220   1]                Subtable Type : 04 [Local APIC NMI]
[0DDh 0221   1]                       Length : 06
[0DEh 0222   1]                 Processor ID : 0C
[0DFh 0223   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[0E1h 0225   1]         Interrupt Input LINT : 01

[0E2h 0226   1]                Subtable Type : 00 [Processor Local APIC]
[0E3h 0227   1]                       Length : 08
[0E4h 0228   1]                 Processor ID : 0D
[0E5h 0229   1]                Local Apic ID : 1A
[0E6h 0230   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0EAh 0234   1]                Subtable Type : 04 [Local APIC NMI]
[0EBh 0235   1]                       Length : 06
[0ECh 0236   1]                 Processor ID : 0D
[0EDh 0237   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[0EFh 0239   1]         Interrupt Input LINT : 01

[0F0h 0240   1]                Subtable Type : 00 [Processor Local APIC]
[0F1h 0241   1]                       Length : 08
[0F2h 0242   1]                 Processor ID : 0E
[0F3h 0243   1]                Local Apic ID : 1C
[0F4h 0244   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[0F8h 0248   1]                Subtable Type : 04 [Local APIC NMI]
[0F9h 0249   1]                       Length : 06
[0FAh 0250   1]                 Processor ID : 0E
[0FBh 0251   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[0FDh 0253   1]         Interrupt Input LINT : 01

[0FEh 0254   1]                Subtable Type : 00 [Processor Local APIC]
[0FFh 0255   1]                       Length : 08
[100h 0256   1]                 Processor ID : 0F
[101h 0257   1]                Local Apic ID : 1E
[102h 0258   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[106h 0262   1]                Subtable Type : 04 [Local APIC NMI]
[107h 0263   1]                       Length : 06
[108h 0264   1]                 Processor ID : 0F
[109h 0265   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[10Bh 0267   1]         Interrupt Input LINT : 01

[10Ch 0268   1]                Subtable Type : 00 [Processor Local APIC]
[10Dh 0269   1]                       Length : 08
[10Eh 0270   1]                 Processor ID : 10
[10Fh 0271   1]                Local Apic ID : 20
[110h 0272   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[114h 0276   1]                Subtable Type : 04 [Local APIC NMI]
[115h 0277   1]                       Length : 06
[116h 0278   1]                 Processor ID : 10
[117h 0279   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[119h 0281   1]         Interrupt Input LINT : 01

[11Ah 0282   1]                Subtable Type : 00 [Processor Local APIC]
[11Bh 0283   1]                       Length : 08
[11Ch 0284   1]                 Processor ID : 11
[11Dh 0285   1]                Local Apic ID : 22
[11Eh 0286   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[122h 0290   1]                Subtable Type : 04 [Local APIC NMI]
[123h 0291   1]                       Length : 06
[124h 0292   1]                 Processor ID : 11
[125h 0293   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[127h 0295   1]         Interrupt Input LINT : 01

[128h 0296   1]                Subtable Type : 00 [Processor Local APIC]
[129h 0297   1]                       Length : 08
[12Ah 0298   1]                 Processor ID : 12
[12Bh 0299   1]                Local Apic ID : 24
[12Ch 0300   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[130h 0304   1]                Subtable Type : 04 [Local APIC NMI]
[131h 0305   1]                       Length : 06
[132h 0306   1]                 Processor ID : 12
[133h 0307   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[135h 0309   1]         Interrupt Input LINT : 01

[136h 0310   1]                Subtable Type : 00 [Processor Local APIC]
[137h 0311   1]                       Length : 08
[138h 0312   1]                 Processor ID : 13
[139h 0313   1]                Local Apic ID : 26
[13Ah 0314   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[13Eh 0318   1]                Subtable Type : 04 [Local APIC NMI]
[13Fh 0319   1]                       Length : 06
[140h 0320   1]                 Processor ID : 13
[141h 0321   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[143h 0323   1]         Interrupt Input LINT : 01

[144h 0324   1]                Subtable Type : 00 [Processor Local APIC]
[145h 0325   1]                       Length : 08
[146h 0326   1]                 Processor ID : 14
[147h 0327   1]                Local Apic ID : 28
[148h 0328   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[14Ch 0332   1]                Subtable Type : 04 [Local APIC NMI]
[14Dh 0333   1]                       Length : 06
[14Eh 0334   1]                 Processor ID : 14
[14Fh 0335   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[151h 0337   1]         Interrupt Input LINT : 01

[152h 0338   1]                Subtable Type : 00 [Processor Local APIC]
[153h 0339   1]                       Length : 08
[154h 0340   1]                 Processor ID : 15
[155h 0341   1]                Local Apic ID : 2A
[156h 0342   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[15Ah 0346   1]                Subtable Type : 04 [Local APIC NMI]
[15Bh 0347   1]                       Length : 06
[15Ch 0348   1]                 Processor ID : 15
[15Dh 0349   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[15Fh 0351   1]         Interrupt Input LINT : 01

[160h 0352   1]                Subtable Type : 00 [Processor Local APIC]
[161h 0353   1]                       Length : 08
[162h 0354   1]                 Processor ID : 16
[163h 0355   1]                Local Apic ID : 2C
[164h 0356   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[168h 0360   1]                Subtable Type : 04 [Local APIC NMI]
[169h 0361   1]                       Length : 06
[16Ah 0362   1]                 Processor ID : 16
[16Bh 0363   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[16Dh 0365   1]         Interrupt Input LINT : 01

[16Eh 0366   1]                Subtable Type : 00 [Processor Local APIC]
[16Fh 0367   1]                       Length : 08
[170h 0368   1]                 Processor ID : 17
[171h 0369   1]                Local Apic ID : 2E
[172h 0370   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[176h 0374   1]                Subtable Type : 04 [Local APIC NMI]
[177h 0375   1]                       Length : 06
[178h 0376   1]                 Processor ID : 17
[179h 0377   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[17Bh 0379   1]         Interrupt Input LINT : 01

[17Ch 0380   1]                Subtable Type : 00 [Processor Local APIC]
[17Dh 0381   1]                       Length : 08
[17Eh 0382   1]                 Processor ID : 18
[17Fh 0383   1]                Local Apic ID : 30
[180h 0384   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[184h 0388   1]                Subtable Type : 04 [Local APIC NMI]
[185h 0389   1]                       Length : 06
[186h 0390   1]                 Processor ID : 18
[187h 0391   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[189h 0393   1]         Interrupt Input LINT : 01

[18Ah 0394   1]                Subtable Type : 00 [Processor Local APIC]
[18Bh 0395   1]                       Length : 08
[18Ch 0396   1]                 Processor ID : 19
[18Dh 0397   1]                Local Apic ID : 32
[18Eh 0398   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[192h 0402   1]                Subtable Type : 04 [Local APIC NMI]
[193h 0403   1]                       Length : 06
[194h 0404   1]                 Processor ID : 19
[195h 0405   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[197h 0407   1]         Interrupt Input LINT : 01

[198h 0408   1]                Subtable Type : 00 [Processor Local APIC]
[199h 0409   1]                       Length : 08
[19Ah 0410   1]                 Processor ID : 1A
[19Bh 0411   1]                Local Apic ID : 34
[19Ch 0412   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1A0h 0416   1]                Subtable Type : 04 [Local APIC NMI]
[1A1h 0417   1]                       Length : 06
[1A2h 0418   1]                 Processor ID : 1A
[1A3h 0419   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[1A5h 0421   1]         Interrupt Input LINT : 01

[1A6h 0422   1]                Subtable Type : 00 [Processor Local APIC]
[1A7h 0423   1]                       Length : 08
[1A8h 0424   1]                 Processor ID : 1B
[1A9h 0425   1]                Local Apic ID : 36
[1AAh 0426   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1AEh 0430   1]                Subtable Type : 04 [Local APIC NMI]
[1AFh 0431   1]                       Length : 06
[1B0h 0432   1]                 Processor ID : 1B
[1B1h 0433   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[1B3h 0435   1]         Interrupt Input LINT : 01

[1B4h 0436   1]                Subtable Type : 00 [Processor Local APIC]
[1B5h 0437   1]                       Length : 08
[1B6h 0438   1]                 Processor ID : 1C
[1B7h 0439   1]                Local Apic ID : 38
[1B8h 0440   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1BCh 0444   1]                Subtable Type : 04 [Local APIC NMI]
[1BDh 0445   1]                       Length : 06
[1BEh 0446   1]                 Processor ID : 1C
[1BFh 0447   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[1C1h 0449   1]         Interrupt Input LINT : 01

[1C2h 0450   1]                Subtable Type : 00 [Processor Local APIC]
[1C3h 0451   1]                       Length : 08
[1C4h 0452   1]                 Processor ID : 1D
[1C5h 0453   1]                Local Apic ID : 3A
[1C6h 0454   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1CAh 0458   1]                Subtable Type : 04 [Local APIC NMI]
[1CBh 0459   1]                       Length : 06
[1CCh 0460   1]                 Processor ID : 1D
[1CDh 0461   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[1CFh 0463   1]         Interrupt Input LINT : 01

[1D0h 0464   1]                Subtable Type : 00 [Processor Local APIC]
[1D1h 0465   1]                       Length : 08
[1D2h 0466   1]                 Processor ID : 1E
[1D3h 0467   1]                Local Apic ID : 3C
[1D4h 0468   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1D8h 0472   1]                Subtable Type : 04 [Local APIC NMI]
[1D9h 0473   1]                       Length : 06
[1DAh 0474   1]                 Processor ID : 1E
[1DBh 0475   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[1DDh 0477   1]         Interrupt Input LINT : 01

[1DEh 0478   1]                Subtable Type : 00 [Processor Local APIC]
[1DFh 0479   1]                       Length : 08
[1E0h 0480   1]                 Processor ID : 1F
[1E1h 0481   1]                Local Apic ID : 3E
[1E2h 0482   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1E6h 0486   1]                Subtable Type : 04 [Local APIC NMI]
[1E7h 0487   1]                       Length : 06
[1E8h 0488   1]                 Processor ID : 1F
[1E9h 0489   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[1EBh 0491   1]         Interrupt Input LINT : 01

[1ECh 0492   1]                Subtable Type : 00 [Processor Local APIC]
[1EDh 0493   1]                       Length : 08
[1EEh 0494   1]                 Processor ID : 20
[1EFh 0495   1]                Local Apic ID : 40
[1F0h 0496   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[1F4h 0500   1]                Subtable Type : 04 [Local APIC NMI]
[1F5h 0501   1]                       Length : 06
[1F6h 0502   1]                 Processor ID : 20
[1F7h 0503   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[1F9h 0505   1]         Interrupt Input LINT : 01

[1FAh 0506   1]                Subtable Type : 00 [Processor Local APIC]
[1FBh 0507   1]                       Length : 08
[1FCh 0508   1]                 Processor ID : 21
[1FDh 0509   1]                Local Apic ID : 42
[1FEh 0510   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[202h 0514   1]                Subtable Type : 04 [Local APIC NMI]
[203h 0515   1]                       Length : 06
[204h 0516   1]                 Processor ID : 21
[205h 0517   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[207h 0519   1]         Interrupt Input LINT : 01

[208h 0520   1]                Subtable Type : 00 [Processor Local APIC]
[209h 0521   1]                       Length : 08
[20Ah 0522   1]                 Processor ID : 22
[20Bh 0523   1]                Local Apic ID : 44
[20Ch 0524   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[210h 0528   1]                Subtable Type : 04 [Local APIC NMI]
[211h 0529   1]                       Length : 06
[212h 0530   1]                 Processor ID : 22
[213h 0531   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[215h 0533   1]         Interrupt Input LINT : 01

[216h 0534   1]                Subtable Type : 00 [Processor Local APIC]
[217h 0535   1]                       Length : 08
[218h 0536   1]                 Processor ID : 23
[219h 0537   1]                Local Apic ID : 46
[21Ah 0538   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[21Eh 0542   1]                Subtable Type : 04 [Local APIC NMI]
[21Fh 0543   1]                       Length : 06
[220h 0544   1]                 Processor ID : 23
[221h 0545   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[223h 0547   1]         Interrupt Input LINT : 01

[224h 0548   1]                Subtable Type : 00 [Processor Local APIC]
[225h 0549   1]                       Length : 08
[226h 0550   1]                 Processor ID : 24
[227h 0551   1]                Local Apic ID : 48
[228h 0552   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[22Ch 0556   1]                Subtable Type : 04 [Local APIC NMI]
[22Dh 0557   1]                       Length : 06
[22Eh 0558   1]                 Processor ID : 24
[22Fh 0559   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[231h 0561   1]         Interrupt Input LINT : 01

[232h 0562   1]                Subtable Type : 00 [Processor Local APIC]
[233h 0563   1]                       Length : 08
[234h 0564   1]                 Processor ID : 25
[235h 0565   1]                Local Apic ID : 4A
[236h 0566   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[23Ah 0570   1]                Subtable Type : 04 [Local APIC NMI]
[23Bh 0571   1]                       Length : 06
[23Ch 0572   1]                 Processor ID : 25
[23Dh 0573   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[23Fh 0575   1]         Interrupt Input LINT : 01

[240h 0576   1]                Subtable Type : 00 [Processor Local APIC]
[241h 0577   1]                       Length : 08
[242h 0578   1]                 Processor ID : 26
[243h 0579   1]                Local Apic ID : 4C
[244h 0580   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[248h 0584   1]                Subtable Type : 04 [Local APIC NMI]
[249h 0585   1]                       Length : 06
[24Ah 0586   1]                 Processor ID : 26
[24Bh 0587   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[24Dh 0589   1]         Interrupt Input LINT : 01

[24Eh 0590   1]                Subtable Type : 00 [Processor Local APIC]
[24Fh 0591   1]                       Length : 08
[250h 0592   1]                 Processor ID : 27
[251h 0593   1]                Local Apic ID : 4E
[252h 0594   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[256h 0598   1]                Subtable Type : 04 [Local APIC NMI]
[257h 0599   1]                       Length : 06
[258h 0600   1]                 Processor ID : 27
[259h 0601   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[25Bh 0603   1]         Interrupt Input LINT : 01

[25Ch 0604   1]                Subtable Type : 00 [Processor Local APIC]
[25Dh 0605   1]                       Length : 08
[25Eh 0606   1]                 Processor ID : 28
[25Fh 0607   1]                Local Apic ID : 50
[260h 0608   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[264h 0612   1]                Subtable Type : 04 [Local APIC NMI]
[265h 0613   1]                       Length : 06
[266h 0614   1]                 Processor ID : 28
[267h 0615   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[269h 0617   1]         Interrupt Input LINT : 01

[26Ah 0618   1]                Subtable Type : 00 [Processor Local APIC]
[26Bh 0619   1]                       Length : 08
[26Ch 0620   1]                 Processor ID : 29
[26Dh 0621   1]                Local Apic ID : 52
[26Eh 0622   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[272h 0626   1]                Subtable Type : 04 [Local APIC NMI]
[273h 0627   1]                       Length : 06
[274h 0628   1]                 Processor ID : 29
[275h 0629   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[277h 0631   1]         Interrupt Input LINT : 01

[278h 0632   1]                Subtable Type : 00 [Processor Local APIC]
[279h 0633   1]                       Length : 08
[27Ah 0634   1]                 Processor ID : 2A
[27Bh 0635   1]                Local Apic ID : 54
[27Ch 0636   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[280h 0640   1]                Subtable Type : 04 [Local APIC NMI]
[281h 0641   1]                       Length : 06
[282h 0642   1]                 Processor ID : 2A
[283h 0643   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[285h 0645   1]         Interrupt Input LINT : 01

[286h 0646   1]                Subtable Type : 00 [Processor Local APIC]
[287h 0647   1]                       Length : 08
[288h 0648   1]                 Processor ID : 2B
[289h 0649   1]                Local Apic ID : 56
[28Ah 0650   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[28Eh 0654   1]                Subtable Type : 04 [Local APIC NMI]
[28Fh 0655   1]                       Length : 06
[290h 0656   1]                 Processor ID : 2B
[291h 0657   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[293h 0659   1]         Interrupt Input LINT : 01

[294h 0660   1]                Subtable Type : 00 [Processor Local APIC]
[295h 0661   1]                       Length : 08
[296h 0662   1]                 Processor ID : 2C
[297h 0663   1]                Local Apic ID : 58
[298h 0664   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[29Ch 0668   1]                Subtable Type : 04 [Local APIC NMI]
[29Dh 0669   1]                       Length : 06
[29Eh 0670   1]                 Processor ID : 2C
[29Fh 0671   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[2A1h 0673   1]         Interrupt Input LINT : 01

[2A2h 0674   1]                Subtable Type : 00 [Processor Local APIC]
[2A3h 0675   1]                       Length : 08
[2A4h 0676   1]                 Processor ID : 2D
[2A5h 0677   1]                Local Apic ID : 5A
[2A6h 0678   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2AAh 0682   1]                Subtable Type : 04 [Local APIC NMI]
[2ABh 0683   1]                       Length : 06
[2ACh 0684   1]                 Processor ID : 2D
[2ADh 0685   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[2AFh 0687   1]         Interrupt Input LINT : 01

[2B0h 0688   1]                Subtable Type : 00 [Processor Local APIC]
[2B1h 0689   1]                       Length : 08
[2B2h 0690   1]                 Processor ID : 2E
[2B3h 0691   1]                Local Apic ID : 5C
[2B4h 0692   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2B8h 0696   1]                Subtable Type : 04 [Local APIC NMI]
[2B9h 0697   1]                       Length : 06
[2BAh 0698   1]                 Processor ID : 2E
[2BBh 0699   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[2BDh 0701   1]         Interrupt Input LINT : 01

[2BEh 0702   1]                Subtable Type : 00 [Processor Local APIC]
[2BFh 0703   1]                       Length : 08
[2C0h 0704   1]                 Processor ID : 2F
[2C1h 0705   1]                Local Apic ID : 5E
[2C2h 0706   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2C6h 0710   1]                Subtable Type : 04 [Local APIC NMI]
[2C7h 0711   1]                       Length : 06
[2C8h 0712   1]                 Processor ID : 2F
[2C9h 0713   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[2CBh 0715   1]         Interrupt Input LINT : 01

[2CCh 0716   1]                Subtable Type : 00 [Processor Local APIC]
[2CDh 0717   1]                       Length : 08
[2CEh 0718   1]                 Processor ID : 30
[2CFh 0719   1]                Local Apic ID : 60
[2D0h 0720   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2D4h 0724   1]                Subtable Type : 04 [Local APIC NMI]
[2D5h 0725   1]                       Length : 06
[2D6h 0726   1]                 Processor ID : 30
[2D7h 0727   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[2D9h 0729   1]         Interrupt Input LINT : 01

[2DAh 0730   1]                Subtable Type : 00 [Processor Local APIC]
[2DBh 0731   1]                       Length : 08
[2DCh 0732   1]                 Processor ID : 31
[2DDh 0733   1]                Local Apic ID : 62
[2DEh 0734   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2E2h 0738   1]                Subtable Type : 04 [Local APIC NMI]
[2E3h 0739   1]                       Length : 06
[2E4h 0740   1]                 Processor ID : 31
[2E5h 0741   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[2E7h 0743   1]         Interrupt Input LINT : 01

[2E8h 0744   1]                Subtable Type : 00 [Processor Local APIC]
[2E9h 0745   1]                       Length : 08
[2EAh 0746   1]                 Processor ID : 32
[2EBh 0747   1]                Local Apic ID : 64
[2ECh 0748   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2F0h 0752   1]                Subtable Type : 04 [Local APIC NMI]
[2F1h 0753   1]                       Length : 06
[2F2h 0754   1]                 Processor ID : 32
[2F3h 0755   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[2F5h 0757   1]         Interrupt Input LINT : 01

[2F6h 0758   1]                Subtable Type : 00 [Processor Local APIC]
[2F7h 0759   1]                       Length : 08
[2F8h 0760   1]                 Processor ID : 33
[2F9h 0761   1]                Local Apic ID : 66
[2FAh 0762   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[2FEh 0766   1]                Subtable Type : 04 [Local APIC NMI]
[2FFh 0767   1]                       Length : 06
[300h 0768   1]                 Processor ID : 33
[301h 0769   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[303h 0771   1]         Interrupt Input LINT : 01

[304h 0772   1]                Subtable Type : 00 [Processor Local APIC]
[305h 0773   1]                       Length : 08
[306h 0774   1]                 Processor ID : 34
[307h 0775   1]                Local Apic ID : 68
[308h 0776   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[30Ch 0780   1]                Subtable Type : 04 [Local APIC NMI]
[30Dh 0781   1]                       Length : 06
[30Eh 0782   1]                 Processor ID : 34
[30Fh 0783   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[311h 0785   1]         Interrupt Input LINT : 01

[312h 0786   1]                Subtable Type : 00 [Processor Local APIC]
[313h 0787   1]                       Length : 08
[314h 0788   1]                 Processor ID : 35
[315h 0789   1]                Local Apic ID : 6A
[316h 0790   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[31Ah 0794   1]                Subtable Type : 04 [Local APIC NMI]
[31Bh 0795   1]                       Length : 06
[31Ch 0796   1]                 Processor ID : 35
[31Dh 0797   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[31Fh 0799   1]         Interrupt Input LINT : 01

[320h 0800   1]                Subtable Type : 00 [Processor Local APIC]
[321h 0801   1]                       Length : 08
[322h 0802   1]                 Processor ID : 36
[323h 0803   1]                Local Apic ID : 6C
[324h 0804   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[328h 0808   1]                Subtable Type : 04 [Local APIC NMI]
[329h 0809   1]                       Length : 06
[32Ah 0810   1]                 Processor ID : 36
[32Bh 0811   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[32Dh 0813   1]         Interrupt Input LINT : 01

[32Eh 0814   1]                Subtable Type : 00 [Processor Local APIC]
[32Fh 0815   1]                       Length : 08
[330h 0816   1]                 Processor ID : 37
[331h 0817   1]                Local Apic ID : 6E
[332h 0818   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[336h 0822   1]                Subtable Type : 04 [Local APIC NMI]
[337h 0823   1]                       Length : 06
[338h 0824   1]                 Processor ID : 37
[339h 0825   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[33Bh 0827   1]         Interrupt Input LINT : 01

[33Ch 0828   1]                Subtable Type : 00 [Processor Local APIC]
[33Dh 0829   1]                       Length : 08
[33Eh 0830   1]                 Processor ID : 38
[33Fh 0831   1]                Local Apic ID : 70
[340h 0832   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[344h 0836   1]                Subtable Type : 04 [Local APIC NMI]
[345h 0837   1]                       Length : 06
[346h 0838   1]                 Processor ID : 38
[347h 0839   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[349h 0841   1]         Interrupt Input LINT : 01

[34Ah 0842   1]                Subtable Type : 00 [Processor Local APIC]
[34Bh 0843   1]                       Length : 08
[34Ch 0844   1]                 Processor ID : 39
[34Dh 0845   1]                Local Apic ID : 72
[34Eh 0846   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[352h 0850   1]                Subtable Type : 04 [Local APIC NMI]
[353h 0851   1]                       Length : 06
[354h 0852   1]                 Processor ID : 39
[355h 0853   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[357h 0855   1]         Interrupt Input LINT : 01

[358h 0856   1]                Subtable Type : 00 [Processor Local APIC]
[359h 0857   1]                       Length : 08
[35Ah 0858   1]                 Processor ID : 3A
[35Bh 0859   1]                Local Apic ID : 74
[35Ch 0860   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[360h 0864   1]                Subtable Type : 04 [Local APIC NMI]
[361h 0865   1]                       Length : 06
[362h 0866   1]                 Processor ID : 3A
[363h 0867   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[365h 0869   1]         Interrupt Input LINT : 01

[366h 0870   1]                Subtable Type : 00 [Processor Local APIC]
[367h 0871   1]                       Length : 08
[368h 0872   1]                 Processor ID : 3B
[369h 0873   1]                Local Apic ID : 76
[36Ah 0874   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[36Eh 0878   1]                Subtable Type : 04 [Local APIC NMI]
[36Fh 0879   1]                       Length : 06
[370h 0880   1]                 Processor ID : 3B
[371h 0881   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[373h 0883   1]         Interrupt Input LINT : 01

[374h 0884   1]                Subtable Type : 00 [Processor Local APIC]
[375h 0885   1]                       Length : 08
[376h 0886   1]                 Processor ID : 3C
[377h 0887   1]                Local Apic ID : 78
[378h 0888   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[37Ch 0892   1]                Subtable Type : 04 [Local APIC NMI]
[37Dh 0893   1]                       Length : 06
[37Eh 0894   1]                 Processor ID : 3C
[37Fh 0895   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[381h 0897   1]         Interrupt Input LINT : 01

[382h 0898   1]                Subtable Type : 00 [Processor Local APIC]
[383h 0899   1]                       Length : 08
[384h 0900   1]                 Processor ID : 3D
[385h 0901   1]                Local Apic ID : 7A
[386h 0902   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[38Ah 0906   1]                Subtable Type : 04 [Local APIC NMI]
[38Bh 0907   1]                       Length : 06
[38Ch 0908   1]                 Processor ID : 3D
[38Dh 0909   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[38Fh 0911   1]         Interrupt Input LINT : 01

[390h 0912   1]                Subtable Type : 00 [Processor Local APIC]
[391h 0913   1]                       Length : 08
[392h 0914   1]                 Processor ID : 3E
[393h 0915   1]                Local Apic ID : 7C
[394h 0916   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[398h 0920   1]                Subtable Type : 04 [Local APIC NMI]
[399h 0921   1]                       Length : 06
[39Ah 0922   1]                 Processor ID : 3E
[39Bh 0923   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[39Dh 0925   1]         Interrupt Input LINT : 01

[39Eh 0926   1]                Subtable Type : 00 [Processor Local APIC]
[39Fh 0927   1]                       Length : 08
[3A0h 0928   1]                 Processor ID : 3F
[3A1h 0929   1]                Local Apic ID : 7E
[3A2h 0930   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3A6h 0934   1]                Subtable Type : 04 [Local APIC NMI]
[3A7h 0935   1]                       Length : 06
[3A8h 0936   1]                 Processor ID : 3F
[3A9h 0937   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[3ABh 0939   1]         Interrupt Input LINT : 01

[3ACh 0940   1]                Subtable Type : 00 [Processor Local APIC]
[3ADh 0941   1]                       Length : 08
[3AEh 0942   1]                 Processor ID : 40
[3AFh 0943   1]                Local Apic ID : 80
[3B0h 0944   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3B4h 0948   1]                Subtable Type : 04 [Local APIC NMI]
[3B5h 0949   1]                       Length : 06
[3B6h 0950   1]                 Processor ID : 40
[3B7h 0951   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[3B9h 0953   1]         Interrupt Input LINT : 01

[3BAh 0954   1]                Subtable Type : 00 [Processor Local APIC]
[3BBh 0955   1]                       Length : 08
[3BCh 0956   1]                 Processor ID : 41
[3BDh 0957   1]                Local Apic ID : 82
[3BEh 0958   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3C2h 0962   1]                Subtable Type : 04 [Local APIC NMI]
[3C3h 0963   1]                       Length : 06
[3C4h 0964   1]                 Processor ID : 41
[3C5h 0965   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[3C7h 0967   1]         Interrupt Input LINT : 01

[3C8h 0968   1]                Subtable Type : 00 [Processor Local APIC]
[3C9h 0969   1]                       Length : 08
[3CAh 0970   1]                 Processor ID : 42
[3CBh 0971   1]                Local Apic ID : 84
[3CCh 0972   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3D0h 0976   1]                Subtable Type : 04 [Local APIC NMI]
[3D1h 0977   1]                       Length : 06
[3D2h 0978   1]                 Processor ID : 42
[3D3h 0979   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[3D5h 0981   1]         Interrupt Input LINT : 01

[3D6h 0982   1]                Subtable Type : 00 [Processor Local APIC]
[3D7h 0983   1]                       Length : 08
[3D8h 0984   1]                 Processor ID : 43
[3D9h 0985   1]                Local Apic ID : 86
[3DAh 0986   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3DEh 0990   1]                Subtable Type : 04 [Local APIC NMI]
[3DFh 0991   1]                       Length : 06
[3E0h 0992   1]                 Processor ID : 43
[3E1h 0993   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[3E3h 0995   1]         Interrupt Input LINT : 01

[3E4h 0996   1]                Subtable Type : 00 [Processor Local APIC]
[3E5h 0997   1]                       Length : 08
[3E6h 0998   1]                 Processor ID : 44
[3E7h 0999   1]                Local Apic ID : 88
[3E8h 1000   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3ECh 1004   1]                Subtable Type : 04 [Local APIC NMI]
[3EDh 1005   1]                       Length : 06
[3EEh 1006   1]                 Processor ID : 44
[3EFh 1007   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[3F1h 1009   1]         Interrupt Input LINT : 01

[3F2h 1010   1]                Subtable Type : 00 [Processor Local APIC]
[3F3h 1011   1]                       Length : 08
[3F4h 1012   1]                 Processor ID : 45
[3F5h 1013   1]                Local Apic ID : 8A
[3F6h 1014   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[3FAh 1018   1]                Subtable Type : 04 [Local APIC NMI]
[3FBh 1019   1]                       Length : 06
[3FCh 1020   1]                 Processor ID : 45
[3FDh 1021   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[3FFh 1023   1]         Interrupt Input LINT : 01

[400h 1024   1]                Subtable Type : 00 [Processor Local APIC]
[401h 1025   1]                       Length : 08
[402h 1026   1]                 Processor ID : 46
[403h 1027   1]                Local Apic ID : 8C
[404h 1028   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[408h 1032   1]                Subtable Type : 04 [Local APIC NMI]
[409h 1033   1]                       Length : 06
[40Ah 1034   1]                 Processor ID : 46
[40Bh 1035   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[40Dh 1037   1]         Interrupt Input LINT : 01

[40Eh 1038   1]                Subtable Type : 00 [Processor Local APIC]
[40Fh 1039   1]                       Length : 08
[410h 1040   1]                 Processor ID : 47
[411h 1041   1]                Local Apic ID : 8E
[412h 1042   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[416h 1046   1]                Subtable Type : 04 [Local APIC NMI]
[417h 1047   1]                       Length : 06
[418h 1048   1]                 Processor ID : 47
[419h 1049   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[41Bh 1051   1]         Interrupt Input LINT : 01

[41Ch 1052   1]                Subtable Type : 00 [Processor Local APIC]
[41Dh 1053   1]                       Length : 08
[41Eh 1054   1]                 Processor ID : 48
[41Fh 1055   1]                Local Apic ID : 90
[420h 1056   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[424h 1060   1]                Subtable Type : 04 [Local APIC NMI]
[425h 1061   1]                       Length : 06
[426h 1062   1]                 Processor ID : 48
[427h 1063   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[429h 1065   1]         Interrupt Input LINT : 01

[42Ah 1066   1]                Subtable Type : 00 [Processor Local APIC]
[42Bh 1067   1]                       Length : 08
[42Ch 1068   1]                 Processor ID : 49
[42Dh 1069   1]                Local Apic ID : 92
[42Eh 1070   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[432h 1074   1]                Subtable Type : 04 [Local APIC NMI]
[433h 1075   1]                       Length : 06
[434h 1076   1]                 Processor ID : 49
[435h 1077   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[437h 1079   1]         Interrupt Input LINT : 01

[438h 1080   1]                Subtable Type : 00 [Processor Local APIC]
[439h 1081   1]                       Length : 08
[43Ah 1082   1]                 Processor ID : 4A
[43Bh 1083   1]                Local Apic ID : 94
[43Ch 1084   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[440h 1088   1]                Subtable Type : 04 [Local APIC NMI]
[441h 1089   1]                       Length : 06
[442h 1090   1]                 Processor ID : 4A
[443h 1091   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[445h 1093   1]         Interrupt Input LINT : 01

[446h 1094   1]                Subtable Type : 00 [Processor Local APIC]
[447h 1095   1]                       Length : 08
[448h 1096   1]                 Processor ID : 4B
[449h 1097   1]                Local Apic ID : 96
[44Ah 1098   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[44Eh 1102   1]                Subtable Type : 04 [Local APIC NMI]
[44Fh 1103   1]                       Length : 06
[450h 1104   1]                 Processor ID : 4B
[451h 1105   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[453h 1107   1]         Interrupt Input LINT : 01

[454h 1108   1]                Subtable Type : 00 [Processor Local APIC]
[455h 1109   1]                       Length : 08
[456h 1110   1]                 Processor ID : 4C
[457h 1111   1]                Local Apic ID : 98
[458h 1112   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[45Ch 1116   1]                Subtable Type : 04 [Local APIC NMI]
[45Dh 1117   1]                       Length : 06
[45Eh 1118   1]                 Processor ID : 4C
[45Fh 1119   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[461h 1121   1]         Interrupt Input LINT : 01

[462h 1122   1]                Subtable Type : 00 [Processor Local APIC]
[463h 1123   1]                       Length : 08
[464h 1124   1]                 Processor ID : 4D
[465h 1125   1]                Local Apic ID : 9A
[466h 1126   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[46Ah 1130   1]                Subtable Type : 04 [Local APIC NMI]
[46Bh 1131   1]                       Length : 06
[46Ch 1132   1]                 Processor ID : 4D
[46Dh 1133   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[46Fh 1135   1]         Interrupt Input LINT : 01

[470h 1136   1]                Subtable Type : 00 [Processor Local APIC]
[471h 1137   1]                       Length : 08
[472h 1138   1]                 Processor ID : 4E
[473h 1139   1]                Local Apic ID : 9C
[474h 1140   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[478h 1144   1]                Subtable Type : 04 [Local APIC NMI]
[479h 1145   1]                       Length : 06
[47Ah 1146   1]                 Processor ID : 4E
[47Bh 1147   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[47Dh 1149   1]         Interrupt Input LINT : 01

[47Eh 1150   1]                Subtable Type : 00 [Processor Local APIC]
[47Fh 1151   1]                       Length : 08
[480h 1152   1]                 Processor ID : 4F
[481h 1153   1]                Local Apic ID : 9E
[482h 1154   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[486h 1158   1]                Subtable Type : 04 [Local APIC NMI]
[487h 1159   1]                       Length : 06
[488h 1160   1]                 Processor ID : 4F
[489h 1161   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[48Bh 1163   1]         Interrupt Input LINT : 01

[48Ch 1164   1]                Subtable Type : 00 [Processor Local APIC]
[48Dh 1165   1]                       Length : 08
[48Eh 1166   1]                 Processor ID : 50
[48Fh 1167   1]                Local Apic ID : A0
[490h 1168   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[494h 1172   1]                Subtable Type : 04 [Local APIC NMI]
[495h 1173   1]                       Length : 06
[496h 1174   1]                 Processor ID : 50
[497h 1175   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[499h 1177   1]         Interrupt Input LINT : 01

[49Ah 1178   1]                Subtable Type : 00 [Processor Local APIC]
[49Bh 1179   1]                       Length : 08
[49Ch 1180   1]                 Processor ID : 51
[49Dh 1181   1]                Local Apic ID : A2
[49Eh 1182   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[4A2h 1186   1]                Subtable Type : 04 [Local APIC NMI]
[4A3h 1187   1]                       Length : 06
[4A4h 1188   1]                 Processor ID : 51
[4A5h 1189   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4A7h 1191   1]         Interrupt Input LINT : 01

[4A8h 1192   1]                Subtable Type : 00 [Processor Local APIC]
[4A9h 1193   1]                       Length : 08
[4AAh 1194   1]                 Processor ID : 52
[4ABh 1195   1]                Local Apic ID : A4
[4ACh 1196   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[4B0h 1200   1]                Subtable Type : 04 [Local APIC NMI]
[4B1h 1201   1]                       Length : 06
[4B2h 1202   1]                 Processor ID : 52
[4B3h 1203   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4B5h 1205   1]         Interrupt Input LINT : 01

[4B6h 1206   1]                Subtable Type : 00 [Processor Local APIC]
[4B7h 1207   1]                       Length : 08
[4B8h 1208   1]                 Processor ID : 53
[4B9h 1209   1]                Local Apic ID : A6
[4BAh 1210   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[4BEh 1214   1]                Subtable Type : 04 [Local APIC NMI]
[4BFh 1215   1]                       Length : 06
[4C0h 1216   1]                 Processor ID : 53
[4C1h 1217   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4C3h 1219   1]         Interrupt Input LINT : 01

[4C4h 1220   1]                Subtable Type : 00 [Processor Local APIC]
[4C5h 1221   1]                       Length : 08
[4C6h 1222   1]                 Processor ID : 54
[4C7h 1223   1]                Local Apic ID : A8
[4C8h 1224   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[4CCh 1228   1]                Subtable Type : 04 [Local APIC NMI]
[4CDh 1229   1]                       Length : 06
[4CEh 1230   1]                 Processor ID : 54
[4CFh 1231   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4D1h 1233   1]         Interrupt Input LINT : 01

[4D2h 1234   1]                Subtable Type : 00 [Processor Local APIC]
[4D3h 1235   1]                       Length : 08
[4D4h 1236   1]                 Processor ID : 55
[4D5h 1237   1]                Local Apic ID : AA
[4D6h 1238   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[4DAh 1242   1]                Subtable Type : 04 [Local APIC NMI]
[4DBh 1243   1]                       Length : 06
[4DCh 1244   1]                 Processor ID : 55
[4DDh 1245   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4DFh 1247   1]         Interrupt Input LINT : 01

[4E0h 1248   1]                Subtable Type : 00 [Processor Local APIC]
[4E1h 1249   1]                       Length : 08
[4E2h 1250   1]                 Processor ID : 56
[4E3h 1251   1]                Local Apic ID : AC
[4E4h 1252   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[4E8h 1256   1]                Subtable Type : 04 [Local APIC NMI]
[4E9h 1257   1]                       Length : 06
[4EAh 1258   1]                 Processor ID : 56
[4EBh 1259   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4EDh 1261   1]         Interrupt Input LINT : 01

[4EEh 1262   1]                Subtable Type : 00 [Processor Local APIC]
[4EFh 1263   1]                       Length : 08
[4F0h 1264   1]                 Processor ID : 57
[4F1h 1265   1]                Local Apic ID : AE
[4F2h 1266   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[4F6h 1270   1]                Subtable Type : 04 [Local APIC NMI]
[4F7h 1271   1]                       Length : 06
[4F8h 1272   1]                 Processor ID : 57
[4F9h 1273   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[4FBh 1275   1]         Interrupt Input LINT : 01

[4FCh 1276   1]                Subtable Type : 00 [Processor Local APIC]
[4FDh 1277   1]                       Length : 08
[4FEh 1278   1]                 Processor ID : 58
[4FFh 1279   1]                Local Apic ID : B0
[500h 1280   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[504h 1284   1]                Subtable Type : 04 [Local APIC NMI]
[505h 1285   1]                       Length : 06
[506h 1286   1]                 Processor ID : 58
[507h 1287   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[509h 1289   1]         Interrupt Input LINT : 01

[50Ah 1290   1]                Subtable Type : 00 [Processor Local APIC]
[50Bh 1291   1]                       Length : 08
[50Ch 1292   1]                 Processor ID : 59
[50Dh 1293   1]                Local Apic ID : B2
[50Eh 1294   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[512h 1298   1]                Subtable Type : 04 [Local APIC NMI]
[513h 1299   1]                       Length : 06
[514h 1300   1]                 Processor ID : 59
[515h 1301   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[517h 1303   1]         Interrupt Input LINT : 01

[518h 1304   1]                Subtable Type : 00 [Processor Local APIC]
[519h 1305   1]                       Length : 08
[51Ah 1306   1]                 Processor ID : 5A
[51Bh 1307   1]                Local Apic ID : B4
[51Ch 1308   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[520h 1312   1]                Subtable Type : 04 [Local APIC NMI]
[521h 1313   1]                       Length : 06
[522h 1314   1]                 Processor ID : 5A
[523h 1315   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[525h 1317   1]         Interrupt Input LINT : 01

[526h 1318   1]                Subtable Type : 00 [Processor Local APIC]
[527h 1319   1]                       Length : 08
[528h 1320   1]                 Processor ID : 5B
[529h 1321   1]                Local Apic ID : B6
[52Ah 1322   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[52Eh 1326   1]                Subtable Type : 04 [Local APIC NMI]
[52Fh 1327   1]                       Length : 06
[530h 1328   1]                 Processor ID : 5B
[531h 1329   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[533h 1331   1]         Interrupt Input LINT : 01

[534h 1332   1]                Subtable Type : 00 [Processor Local APIC]
[535h 1333   1]                       Length : 08
[536h 1334   1]                 Processor ID : 5C
[537h 1335   1]                Local Apic ID : B8
[538h 1336   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[53Ch 1340   1]                Subtable Type : 04 [Local APIC NMI]
[53Dh 1341   1]                       Length : 06
[53Eh 1342   1]                 Processor ID : 5C
[53Fh 1343   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[541h 1345   1]         Interrupt Input LINT : 01

[542h 1346   1]                Subtable Type : 00 [Processor Local APIC]
[543h 1347   1]                       Length : 08
[544h 1348   1]                 Processor ID : 5D
[545h 1349   1]                Local Apic ID : BA
[546h 1350   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[54Ah 1354   1]                Subtable Type : 04 [Local APIC NMI]
[54Bh 1355   1]                       Length : 06
[54Ch 1356   1]                 Processor ID : 5D
[54Dh 1357   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[54Fh 1359   1]         Interrupt Input LINT : 01

[550h 1360   1]                Subtable Type : 00 [Processor Local APIC]
[551h 1361   1]                       Length : 08
[552h 1362   1]                 Processor ID : 5E
[553h 1363   1]                Local Apic ID : BC
[554h 1364   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[558h 1368   1]                Subtable Type : 04 [Local APIC NMI]
[559h 1369   1]                       Length : 06
[55Ah 1370   1]                 Processor ID : 5E
[55Bh 1371   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[55Dh 1373   1]         Interrupt Input LINT : 01

[55Eh 1374   1]                Subtable Type : 00 [Processor Local APIC]
[55Fh 1375   1]                       Length : 08
[560h 1376   1]                 Processor ID : 5F
[561h 1377   1]                Local Apic ID : BE
[562h 1378   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[566h 1382   1]                Subtable Type : 04 [Local APIC NMI]
[567h 1383   1]                       Length : 06
[568h 1384   1]                 Processor ID : 5F
[569h 1385   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[56Bh 1387   1]         Interrupt Input LINT : 01

[56Ch 1388   1]                Subtable Type : 00 [Processor Local APIC]
[56Dh 1389   1]                       Length : 08
[56Eh 1390   1]                 Processor ID : 60
[56Fh 1391   1]                Local Apic ID : C0
[570h 1392   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[574h 1396   1]                Subtable Type : 04 [Local APIC NMI]
[575h 1397   1]                       Length : 06
[576h 1398   1]                 Processor ID : 60
[577h 1399   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[579h 1401   1]         Interrupt Input LINT : 01

[57Ah 1402   1]                Subtable Type : 00 [Processor Local APIC]
[57Bh 1403   1]                       Length : 08
[57Ch 1404   1]                 Processor ID : 61
[57Dh 1405   1]                Local Apic ID : C2
[57Eh 1406   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[582h 1410   1]                Subtable Type : 04 [Local APIC NMI]
[583h 1411   1]                       Length : 06
[584h 1412   1]                 Processor ID : 61
[585h 1413   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[587h 1415   1]         Interrupt Input LINT : 01

[588h 1416   1]                Subtable Type : 00 [Processor Local APIC]
[589h 1417   1]                       Length : 08
[58Ah 1418   1]                 Processor ID : 62
[58Bh 1419   1]                Local Apic ID : C4
[58Ch 1420   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[590h 1424   1]                Subtable Type : 04 [Local APIC NMI]
[591h 1425   1]                       Length : 06
[592h 1426   1]                 Processor ID : 62
[593h 1427   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[595h 1429   1]         Interrupt Input LINT : 01

[596h 1430   1]                Subtable Type : 00 [Processor Local APIC]
[597h 1431   1]                       Length : 08
[598h 1432   1]                 Processor ID : 63
[599h 1433   1]                Local Apic ID : C6
[59Ah 1434   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[59Eh 1438   1]                Subtable Type : 04 [Local APIC NMI]
[59Fh 1439   1]                       Length : 06
[5A0h 1440   1]                 Processor ID : 63
[5A1h 1441   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5A3h 1443   1]         Interrupt Input LINT : 01

[5A4h 1444   1]                Subtable Type : 00 [Processor Local APIC]
[5A5h 1445   1]                       Length : 08
[5A6h 1446   1]                 Processor ID : 64
[5A7h 1447   1]                Local Apic ID : C8
[5A8h 1448   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[5ACh 1452   1]                Subtable Type : 04 [Local APIC NMI]
[5ADh 1453   1]                       Length : 06
[5AEh 1454   1]                 Processor ID : 64
[5AFh 1455   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5B1h 1457   1]         Interrupt Input LINT : 01

[5B2h 1458   1]                Subtable Type : 00 [Processor Local APIC]
[5B3h 1459   1]                       Length : 08
[5B4h 1460   1]                 Processor ID : 65
[5B5h 1461   1]                Local Apic ID : CA
[5B6h 1462   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[5BAh 1466   1]                Subtable Type : 04 [Local APIC NMI]
[5BBh 1467   1]                       Length : 06
[5BCh 1468   1]                 Processor ID : 65
[5BDh 1469   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5BFh 1471   1]         Interrupt Input LINT : 01

[5C0h 1472   1]                Subtable Type : 00 [Processor Local APIC]
[5C1h 1473   1]                       Length : 08
[5C2h 1474   1]                 Processor ID : 66
[5C3h 1475   1]                Local Apic ID : CC
[5C4h 1476   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[5C8h 1480   1]                Subtable Type : 04 [Local APIC NMI]
[5C9h 1481   1]                       Length : 06
[5CAh 1482   1]                 Processor ID : 66
[5CBh 1483   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5CDh 1485   1]         Interrupt Input LINT : 01

[5CEh 1486   1]                Subtable Type : 00 [Processor Local APIC]
[5CFh 1487   1]                       Length : 08
[5D0h 1488   1]                 Processor ID : 67
[5D1h 1489   1]                Local Apic ID : CE
[5D2h 1490   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[5D6h 1494   1]                Subtable Type : 04 [Local APIC NMI]
[5D7h 1495   1]                       Length : 06
[5D8h 1496   1]                 Processor ID : 67
[5D9h 1497   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5DBh 1499   1]         Interrupt Input LINT : 01

[5DCh 1500   1]                Subtable Type : 00 [Processor Local APIC]
[5DDh 1501   1]                       Length : 08
[5DEh 1502   1]                 Processor ID : 68
[5DFh 1503   1]                Local Apic ID : D0
[5E0h 1504   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[5E4h 1508   1]                Subtable Type : 04 [Local APIC NMI]
[5E5h 1509   1]                       Length : 06
[5E6h 1510   1]                 Processor ID : 68
[5E7h 1511   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5E9h 1513   1]         Interrupt Input LINT : 01

[5EAh 1514   1]                Subtable Type : 00 [Processor Local APIC]
[5EBh 1515   1]                       Length : 08
[5ECh 1516   1]                 Processor ID : 69
[5EDh 1517   1]                Local Apic ID : D2
[5EEh 1518   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[5F2h 1522   1]                Subtable Type : 04 [Local APIC NMI]
[5F3h 1523   1]                       Length : 06
[5F4h 1524   1]                 Processor ID : 69
[5F5h 1525   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[5F7h 1527   1]         Interrupt Input LINT : 01

[5F8h 1528   1]                Subtable Type : 00 [Processor Local APIC]
[5F9h 1529   1]                       Length : 08
[5FAh 1530   1]                 Processor ID : 6A
[5FBh 1531   1]                Local Apic ID : D4
[5FCh 1532   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[600h 1536   1]                Subtable Type : 04 [Local APIC NMI]
[601h 1537   1]                       Length : 06
[602h 1538   1]                 Processor ID : 6A
[603h 1539   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[605h 1541   1]         Interrupt Input LINT : 01

[606h 1542   1]                Subtable Type : 00 [Processor Local APIC]
[607h 1543   1]                       Length : 08
[608h 1544   1]                 Processor ID : 6B
[609h 1545   1]                Local Apic ID : D6
[60Ah 1546   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[60Eh 1550   1]                Subtable Type : 04 [Local APIC NMI]
[60Fh 1551   1]                       Length : 06
[610h 1552   1]                 Processor ID : 6B
[611h 1553   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[613h 1555   1]         Interrupt Input LINT : 01

[614h 1556   1]                Subtable Type : 00 [Processor Local APIC]
[615h 1557   1]                       Length : 08
[616h 1558   1]                 Processor ID : 6C
[617h 1559   1]                Local Apic ID : D8
[618h 1560   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[61Ch 1564   1]                Subtable Type : 04 [Local APIC NMI]
[61Dh 1565   1]                       Length : 06
[61Eh 1566   1]                 Processor ID : 6C
[61Fh 1567   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[621h 1569   1]         Interrupt Input LINT : 01

[622h 1570   1]                Subtable Type : 00 [Processor Local APIC]
[623h 1571   1]                       Length : 08
[624h 1572   1]                 Processor ID : 6D
[625h 1573   1]                Local Apic ID : DA
[626h 1574   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[62Ah 1578   1]                Subtable Type : 04 [Local APIC NMI]
[62Bh 1579   1]                       Length : 06
[62Ch 1580   1]                 Processor ID : 6D
[62Dh 1581   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[62Fh 1583   1]         Interrupt Input LINT : 01

[630h 1584   1]                Subtable Type : 00 [Processor Local APIC]
[631h 1585   1]                       Length : 08
[632h 1586   1]                 Processor ID : 6E
[633h 1587   1]                Local Apic ID : DC
[634h 1588   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[638h 1592   1]                Subtable Type : 04 [Local APIC NMI]
[639h 1593   1]                       Length : 06
[63Ah 1594   1]                 Processor ID : 6E
[63Bh 1595   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[63Dh 1597   1]         Interrupt Input LINT : 01

[63Eh 1598   1]                Subtable Type : 00 [Processor Local APIC]
[63Fh 1599   1]                       Length : 08
[640h 1600   1]                 Processor ID : 6F
[641h 1601   1]                Local Apic ID : DE
[642h 1602   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[646h 1606   1]                Subtable Type : 04 [Local APIC NMI]
[647h 1607   1]                       Length : 06
[648h 1608   1]                 Processor ID : 6F
[649h 1609   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[64Bh 1611   1]         Interrupt Input LINT : 01

[64Ch 1612   1]                Subtable Type : 00 [Processor Local APIC]
[64Dh 1613   1]                       Length : 08
[64Eh 1614   1]                 Processor ID : 70
[64Fh 1615   1]                Local Apic ID : E0
[650h 1616   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[654h 1620   1]                Subtable Type : 04 [Local APIC NMI]
[655h 1621   1]                       Length : 06
[656h 1622   1]                 Processor ID : 70
[657h 1623   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[659h 1625   1]         Interrupt Input LINT : 01

[65Ah 1626   1]                Subtable Type : 00 [Processor Local APIC]
[65Bh 1627   1]                       Length : 08
[65Ch 1628   1]                 Processor ID : 71
[65Dh 1629   1]                Local Apic ID : E2
[65Eh 1630   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[662h 1634   1]                Subtable Type : 04 [Local APIC NMI]
[663h 1635   1]                       Length : 06
[664h 1636   1]                 Processor ID : 71
[665h 1637   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[667h 1639   1]         Interrupt Input LINT : 01

[668h 1640   1]                Subtable Type : 00 [Processor Local APIC]
[669h 1641   1]                       Length : 08
[66Ah 1642   1]                 Processor ID : 72
[66Bh 1643   1]                Local Apic ID : E4
[66Ch 1644   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[670h 1648   1]                Subtable Type : 04 [Local APIC NMI]
[671h 1649   1]                       Length : 06
[672h 1650   1]                 Processor ID : 72
[673h 1651   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[675h 1653   1]         Interrupt Input LINT : 01

[676h 1654   1]                Subtable Type : 00 [Processor Local APIC]
[677h 1655   1]                       Length : 08
[678h 1656   1]                 Processor ID : 73
[679h 1657   1]                Local Apic ID : E6
[67Ah 1658   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[67Eh 1662   1]                Subtable Type : 04 [Local APIC NMI]
[67Fh 1663   1]                       Length : 06
[680h 1664   1]                 Processor ID : 73
[681h 1665   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[683h 1667   1]         Interrupt Input LINT : 01

[684h 1668   1]                Subtable Type : 00 [Processor Local APIC]
[685h 1669   1]                       Length : 08
[686h 1670   1]                 Processor ID : 74
[687h 1671   1]                Local Apic ID : E8
[688h 1672   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[68Ch 1676   1]                Subtable Type : 04 [Local APIC NMI]
[68Dh 1677   1]                       Length : 06
[68Eh 1678   1]                 Processor ID : 74
[68Fh 1679   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[691h 1681   1]         Interrupt Input LINT : 01

[692h 1682   1]                Subtable Type : 00 [Processor Local APIC]
[693h 1683   1]                       Length : 08
[694h 1684   1]                 Processor ID : 75
[695h 1685   1]                Local Apic ID : EA
[696h 1686   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[69Ah 1690   1]                Subtable Type : 04 [Local APIC NMI]
[69Bh 1691   1]                       Length : 06
[69Ch 1692   1]                 Processor ID : 75
[69Dh 1693   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[69Fh 1695   1]         Interrupt Input LINT : 01

[6A0h 1696   1]                Subtable Type : 00 [Processor Local APIC]
[6A1h 1697   1]                       Length : 08
[6A2h 1698   1]                 Processor ID : 76
[6A3h 1699   1]                Local Apic ID : EC
[6A4h 1700   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[6A8h 1704   1]                Subtable Type : 04 [Local APIC NMI]
[6A9h 1705   1]                       Length : 06
[6AAh 1706   1]                 Processor ID : 76
[6ABh 1707   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6ADh 1709   1]         Interrupt Input LINT : 01

[6AEh 1710   1]                Subtable Type : 00 [Processor Local APIC]
[6AFh 1711   1]                       Length : 08
[6B0h 1712   1]                 Processor ID : 77
[6B1h 1713   1]                Local Apic ID : EE
[6B2h 1714   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[6B6h 1718   1]                Subtable Type : 04 [Local APIC NMI]
[6B7h 1719   1]                       Length : 06
[6B8h 1720   1]                 Processor ID : 77
[6B9h 1721   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6BBh 1723   1]         Interrupt Input LINT : 01

[6BCh 1724   1]                Subtable Type : 00 [Processor Local APIC]
[6BDh 1725   1]                       Length : 08
[6BEh 1726   1]                 Processor ID : 78
[6BFh 1727   1]                Local Apic ID : F0
[6C0h 1728   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[6C4h 1732   1]                Subtable Type : 04 [Local APIC NMI]
[6C5h 1733   1]                       Length : 06
[6C6h 1734   1]                 Processor ID : 78
[6C7h 1735   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6C9h 1737   1]         Interrupt Input LINT : 01

[6CAh 1738   1]                Subtable Type : 00 [Processor Local APIC]
[6CBh 1739   1]                       Length : 08
[6CCh 1740   1]                 Processor ID : 79
[6CDh 1741   1]                Local Apic ID : F2
[6CEh 1742   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[6D2h 1746   1]                Subtable Type : 04 [Local APIC NMI]
[6D3h 1747   1]                       Length : 06
[6D4h 1748   1]                 Processor ID : 79
[6D5h 1749   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6D7h 1751   1]         Interrupt Input LINT : 01

[6D8h 1752   1]                Subtable Type : 00 [Processor Local APIC]
[6D9h 1753   1]                       Length : 08
[6DAh 1754   1]                 Processor ID : 7A
[6DBh 1755   1]                Local Apic ID : F4
[6DCh 1756   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[6E0h 1760   1]                Subtable Type : 04 [Local APIC NMI]
[6E1h 1761   1]                       Length : 06
[6E2h 1762   1]                 Processor ID : 7A
[6E3h 1763   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6E5h 1765   1]         Interrupt Input LINT : 01

[6E6h 1766   1]                Subtable Type : 00 [Processor Local APIC]
[6E7h 1767   1]                       Length : 08
[6E8h 1768   1]                 Processor ID : 7B
[6E9h 1769   1]                Local Apic ID : F6
[6EAh 1770   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[6EEh 1774   1]                Subtable Type : 04 [Local APIC NMI]
[6EFh 1775   1]                       Length : 06
[6F0h 1776   1]                 Processor ID : 7B
[6F1h 1777   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[6F3h 1779   1]         Interrupt Input LINT : 01

[6F4h 1780   1]                Subtable Type : 00 [Processor Local APIC]
[6F5h 1781   1]                       Length : 08
[6F6h 1782   1]                 Processor ID : 7C
[6F7h 1783   1]                Local Apic ID : F8
[6F8h 1784   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[6FCh 1788   1]                Subtable Type : 04 [Local APIC NMI]
[6FDh 1789   1]                       Length : 06
[6FEh 1790   1]                 Processor ID : 7C
[6FFh 1791   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[701h 1793   1]         Interrupt Input LINT : 01

[702h 1794   1]                Subtable Type : 00 [Processor Local APIC]
[703h 1795   1]                       Length : 08
[704h 1796   1]                 Processor ID : 7D
[705h 1797   1]                Local Apic ID : FA
[706h 1798   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[70Ah 1802   1]                Subtable Type : 04 [Local APIC NMI]
[70Bh 1803   1]                       Length : 06
[70Ch 1804   1]                 Processor ID : 7D
[70Dh 1805   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[70Fh 1807   1]         Interrupt Input LINT : 01

[710h 1808   1]                Subtable Type : 00 [Processor Local APIC]
[711h 1809   1]                       Length : 08
[712h 1810   1]                 Processor ID : 7E
[713h 1811   1]                Local Apic ID : FC
[714h 1812   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[718h 1816   1]                Subtable Type : 04 [Local APIC NMI]
[719h 1817   1]                       Length : 06
[71Ah 1818   1]                 Processor ID : 7E
[71Bh 1819   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[71Dh 1821   1]         Interrupt Input LINT : 01

[71Eh 1822   1]                Subtable Type : 00 [Processor Local APIC]
[71Fh 1823   1]                       Length : 08
[720h 1824   1]                 Processor ID : 7F
[721h 1825   1]                Local Apic ID : FE
[722h 1826   4]        Flags (decoded below) : 00000000
                           Processor Enabled : 0

[726h 1830   1]                Subtable Type : 04 [Local APIC NMI]
[727h 1831   1]                       Length : 06
[728h 1832   1]                 Processor ID : 7F
[729h 1833   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1
[72Bh 1835   1]         Interrupt Input LINT : 01

[72Ch 1836   1]                Subtable Type : 01 [I/O APIC]
[72Dh 1837   1]                       Length : 0C
[72Eh 1838   1]                  I/O Apic ID : 80
[72Fh 1839   1]                     Reserved : 00
[730h 1840   4]                      Address : FEC00000
[734h 1844   4]                    Interrupt : 00000000

[738h 1848   1]                Subtable Type : 02 [Interrupt Source Override]
[739h 1849   1]                       Length : 0A
[73Ah 1850   1]                          Bus : 00
[73Bh 1851   1]                       Source : 00
[73Ch 1852   4]                    Interrupt : 00000002
[740h 1856   2]        Flags (decoded below) : 0005
                                    Polarity : 1
                                Trigger Mode : 1

Raw Table Data: Length 1858 (0x742)

  0000: 41 50 49 43 42 07 00 00 03 79 56 4D 57 41 52 45  // APICB....yVMWARE
  0010: 45 46 49 41 50 49 43 20 01 00 04 06 56 4D 57 20  // EFIAPIC ....VMW 
  0020: CE 07 00 00 00 00 E0 FE 01 00 00 00 00 08 00 00  // ................
  0030: 01 00 00 00 04 06 00 05 00 01 00 08 01 02 01 00  // ................
  0040: 00 00 04 06 01 05 00 01 00 08 02 04 01 00 00 00  // ................
  0050: 04 06 02 05 00 01 00 08 03 06 01 00 00 00 04 06  // ................
  0060: 03 05 00 01 00 08 04 08 00 00 00 00 04 06 04 05  // ................
  0070: 00 01 00 08 05 0A 00 00 00 00 04 06 05 05 00 01  // ................
  0080: 00 08 06 0C 00 00 00 00 04 06 06 05 00 01 00 08  // ................
  0090: 07 0E 00 00 00 00 04 06 07 05 00 01 00 08 08 10  // ................
  00A0: 00 00 00 00 04 06 08 05 00 01 00 08 09 12 00 00  // ................
  00B0: 00 00 04 06 09 05 00 01 00 08 0A 14 00 00 00 00  // ................
  00C0: 04 06 0A 05 00 01 00 08 0B 16 00 00 00 00 04 06  // ................
  00D0: 0B 05 00 01 00 08 0C 18 00 00 00 00 04 06 0C 05  // ................
  00E0: 00 01 00 08 0D 1A 00 00 00 00 04 06 0D 05 00 01  // ................
  00F0: 00 08 0E 1C 00 00 00 00 04 06 0E 05 00 01 00 08  // ................
  0100: 0F 1E 00 00 00 00 04 06 0F 05 00 01 00 08 10 20  // ............... 
  0110: 00 00 00 00 04 06 10 05 00 01 00 08 11 22 00 00  // ............."..
  0120: 00 00 04 06 11 05 00 01 00 08 12 24 00 00 00 00  // ...........$....
  0130: 04 06 12 05 00 01 00 08 13 26 00 00 00 00 04 06  // .........&......
  0140: 13 05 00 01 00 08 14 28 00 00 00 00 04 06 14 05  // .......(........
  0150: 00 01 00 08 15 2A 00 00 00 00 04 06 15 05 00 01  // .....*..........
  0160: 00 08 16 2C 00 00 00 00 04 06 16 05 00 01 00 08  // ...,............
  0170: 17 2E 00 00 00 00 04 06 17 05 00 01 00 08 18 30  // ...............0
  0180: 00 00 00 00 04 06 18 05 00 01 00 08 19 32 00 00  // .............2..
  0190: 00 00 04 06 19 05 00 01 00 08 1A 34 00 00 00 00  // ...........4....
  01A0: 04 06 1A 05 00 01 00 08 1B 36 00 00 00 00 04 06  // .........6......
  01B0: 1B 05 00 01 00 08 1C 38 00 00 00 00 04 06 1C 05  // .......8........
  01C0: 00 01 00 08 1D 3A 00 00 00 00 04 06 1D 05 00 01  // .....:..........
  01D0: 00 08 1E 3C 00 00 00 00 04 06 1E 05 00 01 00 08  // ...<............
  01E0: 1F 3E 00 00 00 00 04 06 1F 05 00 01 00 08 20 40  // .>............ @
  01F0: 00 00 00 00 04 06 20 05 00 01 00 08 21 42 00 00  // ...... .....!B..
  0200: 00 00 04 06 21 05 00 01 00 08 22 44 00 00 00 00  // ....!....."D....
  0210: 04 06 22 05 00 01 00 08 23 46 00 00 00 00 04 06  // ..".....#F......
  0220: 23 05 00 01 00 08 24 48 00 00 00 00 04 06 24 05  // #.....$H......$.
  0230: 00 01 00 08 25 4A 00 00 00 00 04 06 25 05 00 01  // ....%J......%...
  0240: 00 08 26 4C 00 00 00 00 04 06 26 05 00 01 00 08  // ..&L......&.....
  0250: 27 4E 00 00 00 00 04 06 27 05 00 01 00 08 28 50  // 'N......'.....(P
  0260: 00 00 00 00 04 06 28 05 00 01 00 08 29 52 00 00  // ......(.....)R..
  0270: 00 00 04 06 29 05 00 01 00 08 2A 54 00 00 00 00  // ....).....*T....
  0280: 04 06 2A 05 00 01 00 08 2B 56 00 00 00 00 04 06  // ..*.....+V......
  0290: 2B 05 00 01 00 08 2C 58 00 00 00 00 04 06 2C 05  // +.....,X......,.
  02A0: 00 01 00 08 2D 5A 00 00 00 00 04 06 2D 05 00 01  // ....-Z......-...
  02B0: 00 08 2E 5C 00 00 00 00 04 06 2E 05 00 01 00 08  // ...\............
  02C0: 2F 5E 00 00 00 00 04 06 2F 05 00 01 00 08 30 60  // /^....../.....0`
  02D0: 00 00 00 00 04 06 30 05 00 01 00 08 31 62 00 00  // ......0.....1b..
  02E0: 00 00 04 06 31 05 00 01 00 08 32 64 00 00 00 00  // ....1.....2d....
  02F0: 04 06 32 05 00 01 00 08 33 66 00 00 00 00 04 06  // ..2.....3f......
  0300: 33 05 00 01 00 08 34 68 00 00 00 00 04 06 34 05  // 3.....4h......4.
  0310: 00 01 00 08 35 6A 00 00 00 00 04 06 35 05 00 01  // ....5j......5...
  0320: 00 08 36 6C 00 00 00 00 04 06 36 05 00 01 00 08  // ..6l......6.....
  0330: 37 6E 00 00 00 00 04 06 37 05 00 01 00 08 38 70  // 7n......7.....8p
  0340: 00 00 00 00 04 06 38 05 00 01 00 08 39 72 00 00  // ......8.....9r..
  0350: 00 00 04 06 39 05 00 01 00 08 3A 74 00 00 00 00  // ....9.....:t....
  0360: 04 06 3A 05 00 01 00 08 3B 76 00 00 00 00 04 06  // ..:.....;v......
  0370: 3B 05 00 01 00 08 3C 78 00 00 00 00 04 06 3C 05  // ;.....<x......<.
  0380: 00 01 00 08 3D 7A 00 00 00 00 04 06 3D 05 00 01  // ....=z......=...
  0390: 00 08 3E 7C 00 00 00 00 04 06 3E 05 00 01 00 08  // ..>|......>.....
  03A0: 3F 7E 00 00 00 00 04 06 3F 05 00 01 00 08 40 80  // ?~......?.....@.
  03B0: 00 00 00 00 04 06 40 05 00 01 00 08 41 82 00 00  // ......@.....A...
  03C0: 00 00 04 06 41 05 00 01 00 08 42 84 00 00 00 00  // ....A.....B.....
  03D0: 04 06 42 05 00 01 00 08 43 86 00 00 00 00 04 06  // ..B.....C.......
  03E0: 43 05 00 01 00 08 44 88 00 00 00 00 04 06 44 05  // C.....D.......D.
  03F0: 00 01 00 08 45 8A 00 00 00 00 04 06 45 05 00 01  // ....E.......E...
  0400: 00 08 46 8C 00 00 00 00 04 06 46 05 00 01 00 08  // ..F.......F.....
  0410: 47 8E 00 00 00 00 04 06 47 05 00 01 00 08 48 90  // G.......G.....H.
  0420: 00 00 00 00 04 06 48 05 00 01 00 08 49 92 00 00  // ......H.....I...
  0430: 00 00 04 06 49 05 00 01 00 08 4A 94 00 00 00 00  // ....I.....J.....
  0440: 04 06 4A 05 00 01 00 08 4B 96 00 00 00 00 04 06  // ..J.....K.......
  0450: 4B 05 00 01 00 08 4C 98 00 00 00 00 04 06 4C 05  // K.....L.......L.
  0460: 00 01 00 08 4D 9A 00 00 00 00 04 06 4D 05 00 01  // ....M.......M...
  0470: 00 08 4E 9C 00 00 00 00 04 06 4E 05 00 01 00 08  // ..N.......N.....
  0480: 4F 9E 00 00 00 00 04 06 4F 05 00 01 00 08 50 A0  // O.......O.....P.
  0490: 00 00 00 00 04 06 50 05 00 01 00 08 51 A2 00 00  // ......P.....Q...
  04A0: 00 00 04 06 51 05 00 01 00 08 52 A4 00 00 00 00  // ....Q.....R.....
  04B0: 04 06 52 05 00 01 00 08 53 A6 00 00 00 00 04 06  // ..R.....S.......
  04C0: 53 05 00 01 00 08 54 A8 00 00 00 00 04 06 54 05  // S.....T.......T.
  04D0: 00 01 00 08 55 AA 00 00 00 00 04 06 55 05 00 01  // ....U.......U...
  04E0: 00 08 56 AC 00 00 00 00 04 06 56 05 00 01 00 08  // ..V.......V.....
  04F0: 57 AE 00 00 00 00 04 06 57 05 00 01 00 08 58 B0  // W.......W.....X.
  0500: 00 00 00 00 04 06 58 05 00 01 00 08 59 B2 00 00  // ......X.....Y...
  0510: 00 00 04 06 59 05 00 01 00 08 5A B4 00 00 00 00  // ....Y.....Z.....
  0520: 04 06 5A 05 00 01 00 08 5B B6 00 00 00 00 04 06  // ..Z.....[.......
  0530: 5B 05 00 01 00 08 5C B8 00 00 00 00 04 06 5C 05  // [.....\.......\.
  0540: 00 01 00 08 5D BA 00 00 00 00 04 06 5D 05 00 01  // ....].......]...
  0550: 00 08 5E BC 00 00 00 00 04 06 5E 05 00 01 00 08  // ..^.......^.....
  0560: 5F BE 00 00 00 00 04 06 5F 05 00 01 00 08 60 C0  // _......._.....`.
  0570: 00 00 00 00 04 06 60 05 00 01 00 08 61 C2 00 00  // ......`.....a...
  0580: 00 00 04 06 61 05 00 01 00 08 62 C4 00 00 00 00  // ....a.....b.....
  0590: 04 06 62 05 00 01 00 08 63 C6 00 00 00 00 04 06  // ..b.....c.......
  05A0: 63 05 00 01 00 08 64 C8 00 00 00 00 04 06 64 05  // c.....d.......d.
  05B0: 00 01 00 08 65 CA 00 00 00 00 04 06 65 05 00 01  // ....e.......e...
  05C0: 00 08 66 CC 00 00 00 00 04 06 66 05 00 01 00 08  // ..f.......f.....
  05D0: 67 CE 00 00 00 00 04 06 67 05 00 01 00 08 68 D0  // g.......g.....h.
  05E0: 00 00 00 00 04 06 68 05 00 01 00 08 69 D2 00 00  // ......h.....i...
  05F0: 00 00 04 06 69 05 00 01 00 08 6A D4 00 00 00 00  // ....i.....j.....
  0600: 04 06 6A 05 00 01 00 08 6B D6 00 00 00 00 04 06  // ..j.....k.......
  0610: 6B 05 00 01 00 08 6C D8 00 00 00 00 04 06 6C 05  // k.....l.......l.
  0620: 00 01 00 08 6D DA 00 00 00 00 04 06 6D 05 00 01  // ....m.......m...
  0630: 00 08 6E DC 00 00 00 00 04 06 6E 05 00 01 00 08  // ..n.......n.....
  0640: 6F DE 00 00 00 00 04 06 6F 05 00 01 00 08 70 E0  // o.......o.....p.
  0650: 00 00 00 00 04 06 70 05 00 01 00 08 71 E2 00 00  // ......p.....q...
  0660: 00 00 04 06 71 05 00 01 00 08 72 E4 00 00 00 00  // ....q.....r.....
  0670: 04 06 72 05 00 01 00 08 73 E6 00 00 00 00 04 06  // ..r.....s.......
  0680: 73 05 00 01 00 08 74 E8 00 00 00 00 04 06 74 05  // s.....t.......t.
  0690: 00 01 00 08 75 EA 00 00 00 00 04 06 75 05 00 01  // ....u.......u...
  06A0: 00 08 76 EC 00 00 00 00 04 06 76 05 00 01 00 08  // ..v.......v.....
  06B0: 77 EE 00 00 00 00 04 06 77 05 00 01 00 08 78 F0  // w.......w.....x.
  06C0: 00 00 00 00 04 06 78 05 00 01 00 08 79 F2 00 00  // ......x.....y...
  06D0: 00 00 04 06 79 05 00 01 00 08 7A F4 00 00 00 00  // ....y.....z.....
  06E0: 04 06 7A 05 00 01 00 08 7B F6 00 00 00 00 04 06  // ..z.....{.......
  06F0: 7B 05 00 01 00 08 7C F8 00 00 00 00 04 06 7C 05  // {.....|.......|.
  0700: 00 01 00 08 7D FA 00 00 00 00 04 06 7D 05 00 01  // ....}.......}...
  0710: 00 08 7E FC 00 00 00 00 04 06 7E 05 00 01 00 08  // ..~.......~.....
  0720: 7F FE 00 00 00 00 04 06 7F 05 00 01 01 0C 80 00  // ................
  0730: 00 00 C0 FE 00 00 00 00 02 0A 00 00 02 00 00 00  // ................
  0740: 05 00                                            // ..
