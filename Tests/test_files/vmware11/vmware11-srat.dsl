/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20180105 (64-bit version)
 * Copyright (c) 2000 - 2018 Intel Corporation
 * 
 * Disassembly of srat.dat, Fri Jul 17 14:13:23 2020
 *
 * ACPI Data Table [SRAT]
 *
 * Format: [HexOffset DecimalOffset ByteLength]  FieldName : FieldValue
 */

[000h 0000   4]                    Signature : "SRAT"    [System Resource Affinity Table]
[004h 0004   4]                 Table Length : 000008D0
[008h 0008   1]                     Revision : 03
[009h 0009   1]                     Checksum : B9
[00Ah 0010   6]                       Oem ID : "VMWARE"
[010h 0016   8]                 Oem Table ID : "EFISRAT "
[018h 0024   4]                 Oem Revision : 06040001
[01Ch 0028   4]              Asl Compiler ID : "VMW "
[020h 0032   4]        Asl Compiler Revision : 000007CE

[024h 0036   4]               Table Revision : 00000001
[028h 0040   8]                     Reserved : 0000000000000000

[030h 0048   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[031h 0049   1]                       Length : 10

[032h 0050   1]      Proximity Domain Low(8) : 00
[033h 0051   1]                      Apic ID : 00
[034h 0052   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[038h 0056   1]              Local Sapic EID : 00
[039h 0057   3]    Proximity Domain High(24) : 000000
[03Ch 0060   4]                 Clock Domain : 00000000

[040h 0064   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[041h 0065   1]                       Length : 10

[042h 0066   1]      Proximity Domain Low(8) : 00
[043h 0067   1]                      Apic ID : 02
[044h 0068   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[048h 0072   1]              Local Sapic EID : 00
[049h 0073   3]    Proximity Domain High(24) : 000000
[04Ch 0076   4]                 Clock Domain : 00000000

[050h 0080   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[051h 0081   1]                       Length : 10

[052h 0082   1]      Proximity Domain Low(8) : 00
[053h 0083   1]                      Apic ID : 04
[054h 0084   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[058h 0088   1]              Local Sapic EID : 00
[059h 0089   3]    Proximity Domain High(24) : 000000
[05Ch 0092   4]                 Clock Domain : 00000000

[060h 0096   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[061h 0097   1]                       Length : 10

[062h 0098   1]      Proximity Domain Low(8) : 00
[063h 0099   1]                      Apic ID : 06
[064h 0100   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[068h 0104   1]              Local Sapic EID : 00
[069h 0105   3]    Proximity Domain High(24) : 000000
[06Ch 0108   4]                 Clock Domain : 00000000

[070h 0112   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[071h 0113   1]                       Length : 10

[072h 0114   1]      Proximity Domain Low(8) : 00
[073h 0115   1]                      Apic ID : 08
[074h 0116   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[078h 0120   1]              Local Sapic EID : 00
[079h 0121   3]    Proximity Domain High(24) : 000000
[07Ch 0124   4]                 Clock Domain : 00000000

[080h 0128   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[081h 0129   1]                       Length : 10

[082h 0130   1]      Proximity Domain Low(8) : 00
[083h 0131   1]                      Apic ID : 0A
[084h 0132   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[088h 0136   1]              Local Sapic EID : 00
[089h 0137   3]    Proximity Domain High(24) : 000000
[08Ch 0140   4]                 Clock Domain : 00000000

[090h 0144   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[091h 0145   1]                       Length : 10

[092h 0146   1]      Proximity Domain Low(8) : 00
[093h 0147   1]                      Apic ID : 0C
[094h 0148   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[098h 0152   1]              Local Sapic EID : 00
[099h 0153   3]    Proximity Domain High(24) : 000000
[09Ch 0156   4]                 Clock Domain : 00000000

[0A0h 0160   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[0A1h 0161   1]                       Length : 10

[0A2h 0162   1]      Proximity Domain Low(8) : 00
[0A3h 0163   1]                      Apic ID : 0E
[0A4h 0164   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[0A8h 0168   1]              Local Sapic EID : 00
[0A9h 0169   3]    Proximity Domain High(24) : 000000
[0ACh 0172   4]                 Clock Domain : 00000000

[0B0h 0176   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[0B1h 0177   1]                       Length : 10

[0B2h 0178   1]      Proximity Domain Low(8) : 00
[0B3h 0179   1]                      Apic ID : 10
[0B4h 0180   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[0B8h 0184   1]              Local Sapic EID : 00
[0B9h 0185   3]    Proximity Domain High(24) : 000000
[0BCh 0188   4]                 Clock Domain : 00000000

[0C0h 0192   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[0C1h 0193   1]                       Length : 10

[0C2h 0194   1]      Proximity Domain Low(8) : 00
[0C3h 0195   1]                      Apic ID : 12
[0C4h 0196   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[0C8h 0200   1]              Local Sapic EID : 00
[0C9h 0201   3]    Proximity Domain High(24) : 000000
[0CCh 0204   4]                 Clock Domain : 00000000

[0D0h 0208   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[0D1h 0209   1]                       Length : 10

[0D2h 0210   1]      Proximity Domain Low(8) : 00
[0D3h 0211   1]                      Apic ID : 14
[0D4h 0212   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[0D8h 0216   1]              Local Sapic EID : 00
[0D9h 0217   3]    Proximity Domain High(24) : 000000
[0DCh 0220   4]                 Clock Domain : 00000000

[0E0h 0224   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[0E1h 0225   1]                       Length : 10

[0E2h 0226   1]      Proximity Domain Low(8) : 00
[0E3h 0227   1]                      Apic ID : 16
[0E4h 0228   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[0E8h 0232   1]              Local Sapic EID : 00
[0E9h 0233   3]    Proximity Domain High(24) : 000000
[0ECh 0236   4]                 Clock Domain : 00000000

[0F0h 0240   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[0F1h 0241   1]                       Length : 10

[0F2h 0242   1]      Proximity Domain Low(8) : 00
[0F3h 0243   1]                      Apic ID : 18
[0F4h 0244   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[0F8h 0248   1]              Local Sapic EID : 00
[0F9h 0249   3]    Proximity Domain High(24) : 000000
[0FCh 0252   4]                 Clock Domain : 00000000

[100h 0256   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[101h 0257   1]                       Length : 10

[102h 0258   1]      Proximity Domain Low(8) : 00
[103h 0259   1]                      Apic ID : 1A
[104h 0260   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[108h 0264   1]              Local Sapic EID : 00
[109h 0265   3]    Proximity Domain High(24) : 000000
[10Ch 0268   4]                 Clock Domain : 00000000

[110h 0272   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[111h 0273   1]                       Length : 10

[112h 0274   1]      Proximity Domain Low(8) : 00
[113h 0275   1]                      Apic ID : 1C
[114h 0276   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[118h 0280   1]              Local Sapic EID : 00
[119h 0281   3]    Proximity Domain High(24) : 000000
[11Ch 0284   4]                 Clock Domain : 00000000

[120h 0288   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[121h 0289   1]                       Length : 10

[122h 0290   1]      Proximity Domain Low(8) : 00
[123h 0291   1]                      Apic ID : 1E
[124h 0292   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[128h 0296   1]              Local Sapic EID : 00
[129h 0297   3]    Proximity Domain High(24) : 000000
[12Ch 0300   4]                 Clock Domain : 00000000

[130h 0304   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[131h 0305   1]                       Length : 10

[132h 0306   1]      Proximity Domain Low(8) : 00
[133h 0307   1]                      Apic ID : 20
[134h 0308   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[138h 0312   1]              Local Sapic EID : 00
[139h 0313   3]    Proximity Domain High(24) : 000000
[13Ch 0316   4]                 Clock Domain : 00000000

[140h 0320   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[141h 0321   1]                       Length : 10

[142h 0322   1]      Proximity Domain Low(8) : 00
[143h 0323   1]                      Apic ID : 22
[144h 0324   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[148h 0328   1]              Local Sapic EID : 00
[149h 0329   3]    Proximity Domain High(24) : 000000
[14Ch 0332   4]                 Clock Domain : 00000000

[150h 0336   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[151h 0337   1]                       Length : 10

[152h 0338   1]      Proximity Domain Low(8) : 00
[153h 0339   1]                      Apic ID : 24
[154h 0340   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[158h 0344   1]              Local Sapic EID : 00
[159h 0345   3]    Proximity Domain High(24) : 000000
[15Ch 0348   4]                 Clock Domain : 00000000

[160h 0352   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[161h 0353   1]                       Length : 10

[162h 0354   1]      Proximity Domain Low(8) : 00
[163h 0355   1]                      Apic ID : 26
[164h 0356   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[168h 0360   1]              Local Sapic EID : 00
[169h 0361   3]    Proximity Domain High(24) : 000000
[16Ch 0364   4]                 Clock Domain : 00000000

[170h 0368   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[171h 0369   1]                       Length : 10

[172h 0370   1]      Proximity Domain Low(8) : 00
[173h 0371   1]                      Apic ID : 28
[174h 0372   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[178h 0376   1]              Local Sapic EID : 00
[179h 0377   3]    Proximity Domain High(24) : 000000
[17Ch 0380   4]                 Clock Domain : 00000000

[180h 0384   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[181h 0385   1]                       Length : 10

[182h 0386   1]      Proximity Domain Low(8) : 00
[183h 0387   1]                      Apic ID : 2A
[184h 0388   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[188h 0392   1]              Local Sapic EID : 00
[189h 0393   3]    Proximity Domain High(24) : 000000
[18Ch 0396   4]                 Clock Domain : 00000000

[190h 0400   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[191h 0401   1]                       Length : 10

[192h 0402   1]      Proximity Domain Low(8) : 00
[193h 0403   1]                      Apic ID : 2C
[194h 0404   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[198h 0408   1]              Local Sapic EID : 00
[199h 0409   3]    Proximity Domain High(24) : 000000
[19Ch 0412   4]                 Clock Domain : 00000000

[1A0h 0416   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[1A1h 0417   1]                       Length : 10

[1A2h 0418   1]      Proximity Domain Low(8) : 00
[1A3h 0419   1]                      Apic ID : 2E
[1A4h 0420   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[1A8h 0424   1]              Local Sapic EID : 00
[1A9h 0425   3]    Proximity Domain High(24) : 000000
[1ACh 0428   4]                 Clock Domain : 00000000

[1B0h 0432   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[1B1h 0433   1]                       Length : 10

[1B2h 0434   1]      Proximity Domain Low(8) : 00
[1B3h 0435   1]                      Apic ID : 30
[1B4h 0436   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[1B8h 0440   1]              Local Sapic EID : 00
[1B9h 0441   3]    Proximity Domain High(24) : 000000
[1BCh 0444   4]                 Clock Domain : 00000000

[1C0h 0448   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[1C1h 0449   1]                       Length : 10

[1C2h 0450   1]      Proximity Domain Low(8) : 00
[1C3h 0451   1]                      Apic ID : 32
[1C4h 0452   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[1C8h 0456   1]              Local Sapic EID : 00
[1C9h 0457   3]    Proximity Domain High(24) : 000000
[1CCh 0460   4]                 Clock Domain : 00000000

[1D0h 0464   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[1D1h 0465   1]                       Length : 10

[1D2h 0466   1]      Proximity Domain Low(8) : 00
[1D3h 0467   1]                      Apic ID : 34
[1D4h 0468   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[1D8h 0472   1]              Local Sapic EID : 00
[1D9h 0473   3]    Proximity Domain High(24) : 000000
[1DCh 0476   4]                 Clock Domain : 00000000

[1E0h 0480   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[1E1h 0481   1]                       Length : 10

[1E2h 0482   1]      Proximity Domain Low(8) : 00
[1E3h 0483   1]                      Apic ID : 36
[1E4h 0484   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[1E8h 0488   1]              Local Sapic EID : 00
[1E9h 0489   3]    Proximity Domain High(24) : 000000
[1ECh 0492   4]                 Clock Domain : 00000000

[1F0h 0496   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[1F1h 0497   1]                       Length : 10

[1F2h 0498   1]      Proximity Domain Low(8) : 00
[1F3h 0499   1]                      Apic ID : 38
[1F4h 0500   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[1F8h 0504   1]              Local Sapic EID : 00
[1F9h 0505   3]    Proximity Domain High(24) : 000000
[1FCh 0508   4]                 Clock Domain : 00000000

[200h 0512   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[201h 0513   1]                       Length : 10

[202h 0514   1]      Proximity Domain Low(8) : 00
[203h 0515   1]                      Apic ID : 3A
[204h 0516   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[208h 0520   1]              Local Sapic EID : 00
[209h 0521   3]    Proximity Domain High(24) : 000000
[20Ch 0524   4]                 Clock Domain : 00000000

[210h 0528   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[211h 0529   1]                       Length : 10

[212h 0530   1]      Proximity Domain Low(8) : 00
[213h 0531   1]                      Apic ID : 3C
[214h 0532   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[218h 0536   1]              Local Sapic EID : 00
[219h 0537   3]    Proximity Domain High(24) : 000000
[21Ch 0540   4]                 Clock Domain : 00000000

[220h 0544   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[221h 0545   1]                       Length : 10

[222h 0546   1]      Proximity Domain Low(8) : 00
[223h 0547   1]                      Apic ID : 3E
[224h 0548   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[228h 0552   1]              Local Sapic EID : 00
[229h 0553   3]    Proximity Domain High(24) : 000000
[22Ch 0556   4]                 Clock Domain : 00000000

[230h 0560   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[231h 0561   1]                       Length : 10

[232h 0562   1]      Proximity Domain Low(8) : 00
[233h 0563   1]                      Apic ID : 40
[234h 0564   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[238h 0568   1]              Local Sapic EID : 00
[239h 0569   3]    Proximity Domain High(24) : 000000
[23Ch 0572   4]                 Clock Domain : 00000000

[240h 0576   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[241h 0577   1]                       Length : 10

[242h 0578   1]      Proximity Domain Low(8) : 00
[243h 0579   1]                      Apic ID : 42
[244h 0580   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[248h 0584   1]              Local Sapic EID : 00
[249h 0585   3]    Proximity Domain High(24) : 000000
[24Ch 0588   4]                 Clock Domain : 00000000

[250h 0592   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[251h 0593   1]                       Length : 10

[252h 0594   1]      Proximity Domain Low(8) : 00
[253h 0595   1]                      Apic ID : 44
[254h 0596   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[258h 0600   1]              Local Sapic EID : 00
[259h 0601   3]    Proximity Domain High(24) : 000000
[25Ch 0604   4]                 Clock Domain : 00000000

[260h 0608   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[261h 0609   1]                       Length : 10

[262h 0610   1]      Proximity Domain Low(8) : 00
[263h 0611   1]                      Apic ID : 46
[264h 0612   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[268h 0616   1]              Local Sapic EID : 00
[269h 0617   3]    Proximity Domain High(24) : 000000
[26Ch 0620   4]                 Clock Domain : 00000000

[270h 0624   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[271h 0625   1]                       Length : 10

[272h 0626   1]      Proximity Domain Low(8) : 00
[273h 0627   1]                      Apic ID : 48
[274h 0628   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[278h 0632   1]              Local Sapic EID : 00
[279h 0633   3]    Proximity Domain High(24) : 000000
[27Ch 0636   4]                 Clock Domain : 00000000

[280h 0640   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[281h 0641   1]                       Length : 10

[282h 0642   1]      Proximity Domain Low(8) : 00
[283h 0643   1]                      Apic ID : 4A
[284h 0644   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[288h 0648   1]              Local Sapic EID : 00
[289h 0649   3]    Proximity Domain High(24) : 000000
[28Ch 0652   4]                 Clock Domain : 00000000

[290h 0656   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[291h 0657   1]                       Length : 10

[292h 0658   1]      Proximity Domain Low(8) : 00
[293h 0659   1]                      Apic ID : 4C
[294h 0660   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[298h 0664   1]              Local Sapic EID : 00
[299h 0665   3]    Proximity Domain High(24) : 000000
[29Ch 0668   4]                 Clock Domain : 00000000

[2A0h 0672   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[2A1h 0673   1]                       Length : 10

[2A2h 0674   1]      Proximity Domain Low(8) : 00
[2A3h 0675   1]                      Apic ID : 4E
[2A4h 0676   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[2A8h 0680   1]              Local Sapic EID : 00
[2A9h 0681   3]    Proximity Domain High(24) : 000000
[2ACh 0684   4]                 Clock Domain : 00000000

[2B0h 0688   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[2B1h 0689   1]                       Length : 10

[2B2h 0690   1]      Proximity Domain Low(8) : 00
[2B3h 0691   1]                      Apic ID : 50
[2B4h 0692   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[2B8h 0696   1]              Local Sapic EID : 00
[2B9h 0697   3]    Proximity Domain High(24) : 000000
[2BCh 0700   4]                 Clock Domain : 00000000

[2C0h 0704   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[2C1h 0705   1]                       Length : 10

[2C2h 0706   1]      Proximity Domain Low(8) : 00
[2C3h 0707   1]                      Apic ID : 52
[2C4h 0708   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[2C8h 0712   1]              Local Sapic EID : 00
[2C9h 0713   3]    Proximity Domain High(24) : 000000
[2CCh 0716   4]                 Clock Domain : 00000000

[2D0h 0720   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[2D1h 0721   1]                       Length : 10

[2D2h 0722   1]      Proximity Domain Low(8) : 00
[2D3h 0723   1]                      Apic ID : 54
[2D4h 0724   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[2D8h 0728   1]              Local Sapic EID : 00
[2D9h 0729   3]    Proximity Domain High(24) : 000000
[2DCh 0732   4]                 Clock Domain : 00000000

[2E0h 0736   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[2E1h 0737   1]                       Length : 10

[2E2h 0738   1]      Proximity Domain Low(8) : 00
[2E3h 0739   1]                      Apic ID : 56
[2E4h 0740   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[2E8h 0744   1]              Local Sapic EID : 00
[2E9h 0745   3]    Proximity Domain High(24) : 000000
[2ECh 0748   4]                 Clock Domain : 00000000

[2F0h 0752   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[2F1h 0753   1]                       Length : 10

[2F2h 0754   1]      Proximity Domain Low(8) : 00
[2F3h 0755   1]                      Apic ID : 58
[2F4h 0756   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[2F8h 0760   1]              Local Sapic EID : 00
[2F9h 0761   3]    Proximity Domain High(24) : 000000
[2FCh 0764   4]                 Clock Domain : 00000000

[300h 0768   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[301h 0769   1]                       Length : 10

[302h 0770   1]      Proximity Domain Low(8) : 00
[303h 0771   1]                      Apic ID : 5A
[304h 0772   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[308h 0776   1]              Local Sapic EID : 00
[309h 0777   3]    Proximity Domain High(24) : 000000
[30Ch 0780   4]                 Clock Domain : 00000000

[310h 0784   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[311h 0785   1]                       Length : 10

[312h 0786   1]      Proximity Domain Low(8) : 00
[313h 0787   1]                      Apic ID : 5C
[314h 0788   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[318h 0792   1]              Local Sapic EID : 00
[319h 0793   3]    Proximity Domain High(24) : 000000
[31Ch 0796   4]                 Clock Domain : 00000000

[320h 0800   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[321h 0801   1]                       Length : 10

[322h 0802   1]      Proximity Domain Low(8) : 00
[323h 0803   1]                      Apic ID : 5E
[324h 0804   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[328h 0808   1]              Local Sapic EID : 00
[329h 0809   3]    Proximity Domain High(24) : 000000
[32Ch 0812   4]                 Clock Domain : 00000000

[330h 0816   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[331h 0817   1]                       Length : 10

[332h 0818   1]      Proximity Domain Low(8) : 00
[333h 0819   1]                      Apic ID : 60
[334h 0820   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[338h 0824   1]              Local Sapic EID : 00
[339h 0825   3]    Proximity Domain High(24) : 000000
[33Ch 0828   4]                 Clock Domain : 00000000

[340h 0832   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[341h 0833   1]                       Length : 10

[342h 0834   1]      Proximity Domain Low(8) : 00
[343h 0835   1]                      Apic ID : 62
[344h 0836   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[348h 0840   1]              Local Sapic EID : 00
[349h 0841   3]    Proximity Domain High(24) : 000000
[34Ch 0844   4]                 Clock Domain : 00000000

[350h 0848   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[351h 0849   1]                       Length : 10

[352h 0850   1]      Proximity Domain Low(8) : 00
[353h 0851   1]                      Apic ID : 64
[354h 0852   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[358h 0856   1]              Local Sapic EID : 00
[359h 0857   3]    Proximity Domain High(24) : 000000
[35Ch 0860   4]                 Clock Domain : 00000000

[360h 0864   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[361h 0865   1]                       Length : 10

[362h 0866   1]      Proximity Domain Low(8) : 00
[363h 0867   1]                      Apic ID : 66
[364h 0868   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[368h 0872   1]              Local Sapic EID : 00
[369h 0873   3]    Proximity Domain High(24) : 000000
[36Ch 0876   4]                 Clock Domain : 00000000

[370h 0880   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[371h 0881   1]                       Length : 10

[372h 0882   1]      Proximity Domain Low(8) : 00
[373h 0883   1]                      Apic ID : 68
[374h 0884   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[378h 0888   1]              Local Sapic EID : 00
[379h 0889   3]    Proximity Domain High(24) : 000000
[37Ch 0892   4]                 Clock Domain : 00000000

[380h 0896   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[381h 0897   1]                       Length : 10

[382h 0898   1]      Proximity Domain Low(8) : 00
[383h 0899   1]                      Apic ID : 6A
[384h 0900   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[388h 0904   1]              Local Sapic EID : 00
[389h 0905   3]    Proximity Domain High(24) : 000000
[38Ch 0908   4]                 Clock Domain : 00000000

[390h 0912   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[391h 0913   1]                       Length : 10

[392h 0914   1]      Proximity Domain Low(8) : 00
[393h 0915   1]                      Apic ID : 6C
[394h 0916   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[398h 0920   1]              Local Sapic EID : 00
[399h 0921   3]    Proximity Domain High(24) : 000000
[39Ch 0924   4]                 Clock Domain : 00000000

[3A0h 0928   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[3A1h 0929   1]                       Length : 10

[3A2h 0930   1]      Proximity Domain Low(8) : 00
[3A3h 0931   1]                      Apic ID : 6E
[3A4h 0932   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[3A8h 0936   1]              Local Sapic EID : 00
[3A9h 0937   3]    Proximity Domain High(24) : 000000
[3ACh 0940   4]                 Clock Domain : 00000000

[3B0h 0944   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[3B1h 0945   1]                       Length : 10

[3B2h 0946   1]      Proximity Domain Low(8) : 00
[3B3h 0947   1]                      Apic ID : 70
[3B4h 0948   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[3B8h 0952   1]              Local Sapic EID : 00
[3B9h 0953   3]    Proximity Domain High(24) : 000000
[3BCh 0956   4]                 Clock Domain : 00000000

[3C0h 0960   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[3C1h 0961   1]                       Length : 10

[3C2h 0962   1]      Proximity Domain Low(8) : 00
[3C3h 0963   1]                      Apic ID : 72
[3C4h 0964   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[3C8h 0968   1]              Local Sapic EID : 00
[3C9h 0969   3]    Proximity Domain High(24) : 000000
[3CCh 0972   4]                 Clock Domain : 00000000

[3D0h 0976   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[3D1h 0977   1]                       Length : 10

[3D2h 0978   1]      Proximity Domain Low(8) : 00
[3D3h 0979   1]                      Apic ID : 74
[3D4h 0980   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[3D8h 0984   1]              Local Sapic EID : 00
[3D9h 0985   3]    Proximity Domain High(24) : 000000
[3DCh 0988   4]                 Clock Domain : 00000000

[3E0h 0992   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[3E1h 0993   1]                       Length : 10

[3E2h 0994   1]      Proximity Domain Low(8) : 00
[3E3h 0995   1]                      Apic ID : 76
[3E4h 0996   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[3E8h 1000   1]              Local Sapic EID : 00
[3E9h 1001   3]    Proximity Domain High(24) : 000000
[3ECh 1004   4]                 Clock Domain : 00000000

[3F0h 1008   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[3F1h 1009   1]                       Length : 10

[3F2h 1010   1]      Proximity Domain Low(8) : 00
[3F3h 1011   1]                      Apic ID : 78
[3F4h 1012   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[3F8h 1016   1]              Local Sapic EID : 00
[3F9h 1017   3]    Proximity Domain High(24) : 000000
[3FCh 1020   4]                 Clock Domain : 00000000

[400h 1024   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[401h 1025   1]                       Length : 10

[402h 1026   1]      Proximity Domain Low(8) : 00
[403h 1027   1]                      Apic ID : 7A
[404h 1028   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[408h 1032   1]              Local Sapic EID : 00
[409h 1033   3]    Proximity Domain High(24) : 000000
[40Ch 1036   4]                 Clock Domain : 00000000

[410h 1040   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[411h 1041   1]                       Length : 10

[412h 1042   1]      Proximity Domain Low(8) : 00
[413h 1043   1]                      Apic ID : 7C
[414h 1044   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[418h 1048   1]              Local Sapic EID : 00
[419h 1049   3]    Proximity Domain High(24) : 000000
[41Ch 1052   4]                 Clock Domain : 00000000

[420h 1056   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[421h 1057   1]                       Length : 10

[422h 1058   1]      Proximity Domain Low(8) : 00
[423h 1059   1]                      Apic ID : 7E
[424h 1060   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[428h 1064   1]              Local Sapic EID : 00
[429h 1065   3]    Proximity Domain High(24) : 000000
[42Ch 1068   4]                 Clock Domain : 00000000

[430h 1072   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[431h 1073   1]                       Length : 10

[432h 1074   1]      Proximity Domain Low(8) : 00
[433h 1075   1]                      Apic ID : 80
[434h 1076   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[438h 1080   1]              Local Sapic EID : 00
[439h 1081   3]    Proximity Domain High(24) : 000000
[43Ch 1084   4]                 Clock Domain : 00000000

[440h 1088   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[441h 1089   1]                       Length : 10

[442h 1090   1]      Proximity Domain Low(8) : 00
[443h 1091   1]                      Apic ID : 82
[444h 1092   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[448h 1096   1]              Local Sapic EID : 00
[449h 1097   3]    Proximity Domain High(24) : 000000
[44Ch 1100   4]                 Clock Domain : 00000000

[450h 1104   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[451h 1105   1]                       Length : 10

[452h 1106   1]      Proximity Domain Low(8) : 00
[453h 1107   1]                      Apic ID : 84
[454h 1108   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[458h 1112   1]              Local Sapic EID : 00
[459h 1113   3]    Proximity Domain High(24) : 000000
[45Ch 1116   4]                 Clock Domain : 00000000

[460h 1120   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[461h 1121   1]                       Length : 10

[462h 1122   1]      Proximity Domain Low(8) : 00
[463h 1123   1]                      Apic ID : 86
[464h 1124   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[468h 1128   1]              Local Sapic EID : 00
[469h 1129   3]    Proximity Domain High(24) : 000000
[46Ch 1132   4]                 Clock Domain : 00000000

[470h 1136   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[471h 1137   1]                       Length : 10

[472h 1138   1]      Proximity Domain Low(8) : 00
[473h 1139   1]                      Apic ID : 88
[474h 1140   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[478h 1144   1]              Local Sapic EID : 00
[479h 1145   3]    Proximity Domain High(24) : 000000
[47Ch 1148   4]                 Clock Domain : 00000000

[480h 1152   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[481h 1153   1]                       Length : 10

[482h 1154   1]      Proximity Domain Low(8) : 00
[483h 1155   1]                      Apic ID : 8A
[484h 1156   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[488h 1160   1]              Local Sapic EID : 00
[489h 1161   3]    Proximity Domain High(24) : 000000
[48Ch 1164   4]                 Clock Domain : 00000000

[490h 1168   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[491h 1169   1]                       Length : 10

[492h 1170   1]      Proximity Domain Low(8) : 00
[493h 1171   1]                      Apic ID : 8C
[494h 1172   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[498h 1176   1]              Local Sapic EID : 00
[499h 1177   3]    Proximity Domain High(24) : 000000
[49Ch 1180   4]                 Clock Domain : 00000000

[4A0h 1184   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[4A1h 1185   1]                       Length : 10

[4A2h 1186   1]      Proximity Domain Low(8) : 00
[4A3h 1187   1]                      Apic ID : 8E
[4A4h 1188   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[4A8h 1192   1]              Local Sapic EID : 00
[4A9h 1193   3]    Proximity Domain High(24) : 000000
[4ACh 1196   4]                 Clock Domain : 00000000

[4B0h 1200   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[4B1h 1201   1]                       Length : 10

[4B2h 1202   1]      Proximity Domain Low(8) : 00
[4B3h 1203   1]                      Apic ID : 90
[4B4h 1204   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[4B8h 1208   1]              Local Sapic EID : 00
[4B9h 1209   3]    Proximity Domain High(24) : 000000
[4BCh 1212   4]                 Clock Domain : 00000000

[4C0h 1216   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[4C1h 1217   1]                       Length : 10

[4C2h 1218   1]      Proximity Domain Low(8) : 00
[4C3h 1219   1]                      Apic ID : 92
[4C4h 1220   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[4C8h 1224   1]              Local Sapic EID : 00
[4C9h 1225   3]    Proximity Domain High(24) : 000000
[4CCh 1228   4]                 Clock Domain : 00000000

[4D0h 1232   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[4D1h 1233   1]                       Length : 10

[4D2h 1234   1]      Proximity Domain Low(8) : 00
[4D3h 1235   1]                      Apic ID : 94
[4D4h 1236   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[4D8h 1240   1]              Local Sapic EID : 00
[4D9h 1241   3]    Proximity Domain High(24) : 000000
[4DCh 1244   4]                 Clock Domain : 00000000

[4E0h 1248   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[4E1h 1249   1]                       Length : 10

[4E2h 1250   1]      Proximity Domain Low(8) : 00
[4E3h 1251   1]                      Apic ID : 96
[4E4h 1252   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[4E8h 1256   1]              Local Sapic EID : 00
[4E9h 1257   3]    Proximity Domain High(24) : 000000
[4ECh 1260   4]                 Clock Domain : 00000000

[4F0h 1264   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[4F1h 1265   1]                       Length : 10

[4F2h 1266   1]      Proximity Domain Low(8) : 00
[4F3h 1267   1]                      Apic ID : 98
[4F4h 1268   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[4F8h 1272   1]              Local Sapic EID : 00
[4F9h 1273   3]    Proximity Domain High(24) : 000000
[4FCh 1276   4]                 Clock Domain : 00000000

[500h 1280   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[501h 1281   1]                       Length : 10

[502h 1282   1]      Proximity Domain Low(8) : 00
[503h 1283   1]                      Apic ID : 9A
[504h 1284   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[508h 1288   1]              Local Sapic EID : 00
[509h 1289   3]    Proximity Domain High(24) : 000000
[50Ch 1292   4]                 Clock Domain : 00000000

[510h 1296   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[511h 1297   1]                       Length : 10

[512h 1298   1]      Proximity Domain Low(8) : 00
[513h 1299   1]                      Apic ID : 9C
[514h 1300   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[518h 1304   1]              Local Sapic EID : 00
[519h 1305   3]    Proximity Domain High(24) : 000000
[51Ch 1308   4]                 Clock Domain : 00000000

[520h 1312   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[521h 1313   1]                       Length : 10

[522h 1314   1]      Proximity Domain Low(8) : 00
[523h 1315   1]                      Apic ID : 9E
[524h 1316   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[528h 1320   1]              Local Sapic EID : 00
[529h 1321   3]    Proximity Domain High(24) : 000000
[52Ch 1324   4]                 Clock Domain : 00000000

[530h 1328   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[531h 1329   1]                       Length : 10

[532h 1330   1]      Proximity Domain Low(8) : 00
[533h 1331   1]                      Apic ID : A0
[534h 1332   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[538h 1336   1]              Local Sapic EID : 00
[539h 1337   3]    Proximity Domain High(24) : 000000
[53Ch 1340   4]                 Clock Domain : 00000000

[540h 1344   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[541h 1345   1]                       Length : 10

[542h 1346   1]      Proximity Domain Low(8) : 00
[543h 1347   1]                      Apic ID : A2
[544h 1348   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[548h 1352   1]              Local Sapic EID : 00
[549h 1353   3]    Proximity Domain High(24) : 000000
[54Ch 1356   4]                 Clock Domain : 00000000

[550h 1360   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[551h 1361   1]                       Length : 10

[552h 1362   1]      Proximity Domain Low(8) : 00
[553h 1363   1]                      Apic ID : A4
[554h 1364   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[558h 1368   1]              Local Sapic EID : 00
[559h 1369   3]    Proximity Domain High(24) : 000000
[55Ch 1372   4]                 Clock Domain : 00000000

[560h 1376   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[561h 1377   1]                       Length : 10

[562h 1378   1]      Proximity Domain Low(8) : 00
[563h 1379   1]                      Apic ID : A6
[564h 1380   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[568h 1384   1]              Local Sapic EID : 00
[569h 1385   3]    Proximity Domain High(24) : 000000
[56Ch 1388   4]                 Clock Domain : 00000000

[570h 1392   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[571h 1393   1]                       Length : 10

[572h 1394   1]      Proximity Domain Low(8) : 00
[573h 1395   1]                      Apic ID : A8
[574h 1396   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[578h 1400   1]              Local Sapic EID : 00
[579h 1401   3]    Proximity Domain High(24) : 000000
[57Ch 1404   4]                 Clock Domain : 00000000

[580h 1408   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[581h 1409   1]                       Length : 10

[582h 1410   1]      Proximity Domain Low(8) : 00
[583h 1411   1]                      Apic ID : AA
[584h 1412   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[588h 1416   1]              Local Sapic EID : 00
[589h 1417   3]    Proximity Domain High(24) : 000000
[58Ch 1420   4]                 Clock Domain : 00000000

[590h 1424   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[591h 1425   1]                       Length : 10

[592h 1426   1]      Proximity Domain Low(8) : 00
[593h 1427   1]                      Apic ID : AC
[594h 1428   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[598h 1432   1]              Local Sapic EID : 00
[599h 1433   3]    Proximity Domain High(24) : 000000
[59Ch 1436   4]                 Clock Domain : 00000000

[5A0h 1440   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[5A1h 1441   1]                       Length : 10

[5A2h 1442   1]      Proximity Domain Low(8) : 00
[5A3h 1443   1]                      Apic ID : AE
[5A4h 1444   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[5A8h 1448   1]              Local Sapic EID : 00
[5A9h 1449   3]    Proximity Domain High(24) : 000000
[5ACh 1452   4]                 Clock Domain : 00000000

[5B0h 1456   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[5B1h 1457   1]                       Length : 10

[5B2h 1458   1]      Proximity Domain Low(8) : 00
[5B3h 1459   1]                      Apic ID : B0
[5B4h 1460   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[5B8h 1464   1]              Local Sapic EID : 00
[5B9h 1465   3]    Proximity Domain High(24) : 000000
[5BCh 1468   4]                 Clock Domain : 00000000

[5C0h 1472   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[5C1h 1473   1]                       Length : 10

[5C2h 1474   1]      Proximity Domain Low(8) : 00
[5C3h 1475   1]                      Apic ID : B2
[5C4h 1476   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[5C8h 1480   1]              Local Sapic EID : 00
[5C9h 1481   3]    Proximity Domain High(24) : 000000
[5CCh 1484   4]                 Clock Domain : 00000000

[5D0h 1488   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[5D1h 1489   1]                       Length : 10

[5D2h 1490   1]      Proximity Domain Low(8) : 00
[5D3h 1491   1]                      Apic ID : B4
[5D4h 1492   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[5D8h 1496   1]              Local Sapic EID : 00
[5D9h 1497   3]    Proximity Domain High(24) : 000000
[5DCh 1500   4]                 Clock Domain : 00000000

[5E0h 1504   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[5E1h 1505   1]                       Length : 10

[5E2h 1506   1]      Proximity Domain Low(8) : 00
[5E3h 1507   1]                      Apic ID : B6
[5E4h 1508   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[5E8h 1512   1]              Local Sapic EID : 00
[5E9h 1513   3]    Proximity Domain High(24) : 000000
[5ECh 1516   4]                 Clock Domain : 00000000

[5F0h 1520   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[5F1h 1521   1]                       Length : 10

[5F2h 1522   1]      Proximity Domain Low(8) : 00
[5F3h 1523   1]                      Apic ID : B8
[5F4h 1524   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[5F8h 1528   1]              Local Sapic EID : 00
[5F9h 1529   3]    Proximity Domain High(24) : 000000
[5FCh 1532   4]                 Clock Domain : 00000000

[600h 1536   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[601h 1537   1]                       Length : 10

[602h 1538   1]      Proximity Domain Low(8) : 00
[603h 1539   1]                      Apic ID : BA
[604h 1540   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[608h 1544   1]              Local Sapic EID : 00
[609h 1545   3]    Proximity Domain High(24) : 000000
[60Ch 1548   4]                 Clock Domain : 00000000

[610h 1552   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[611h 1553   1]                       Length : 10

[612h 1554   1]      Proximity Domain Low(8) : 00
[613h 1555   1]                      Apic ID : BC
[614h 1556   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[618h 1560   1]              Local Sapic EID : 00
[619h 1561   3]    Proximity Domain High(24) : 000000
[61Ch 1564   4]                 Clock Domain : 00000000

[620h 1568   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[621h 1569   1]                       Length : 10

[622h 1570   1]      Proximity Domain Low(8) : 00
[623h 1571   1]                      Apic ID : BE
[624h 1572   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[628h 1576   1]              Local Sapic EID : 00
[629h 1577   3]    Proximity Domain High(24) : 000000
[62Ch 1580   4]                 Clock Domain : 00000000

[630h 1584   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[631h 1585   1]                       Length : 10

[632h 1586   1]      Proximity Domain Low(8) : 00
[633h 1587   1]                      Apic ID : C0
[634h 1588   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[638h 1592   1]              Local Sapic EID : 00
[639h 1593   3]    Proximity Domain High(24) : 000000
[63Ch 1596   4]                 Clock Domain : 00000000

[640h 1600   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[641h 1601   1]                       Length : 10

[642h 1602   1]      Proximity Domain Low(8) : 00
[643h 1603   1]                      Apic ID : C2
[644h 1604   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[648h 1608   1]              Local Sapic EID : 00
[649h 1609   3]    Proximity Domain High(24) : 000000
[64Ch 1612   4]                 Clock Domain : 00000000

[650h 1616   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[651h 1617   1]                       Length : 10

[652h 1618   1]      Proximity Domain Low(8) : 00
[653h 1619   1]                      Apic ID : C4
[654h 1620   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[658h 1624   1]              Local Sapic EID : 00
[659h 1625   3]    Proximity Domain High(24) : 000000
[65Ch 1628   4]                 Clock Domain : 00000000

[660h 1632   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[661h 1633   1]                       Length : 10

[662h 1634   1]      Proximity Domain Low(8) : 00
[663h 1635   1]                      Apic ID : C6
[664h 1636   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[668h 1640   1]              Local Sapic EID : 00
[669h 1641   3]    Proximity Domain High(24) : 000000
[66Ch 1644   4]                 Clock Domain : 00000000

[670h 1648   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[671h 1649   1]                       Length : 10

[672h 1650   1]      Proximity Domain Low(8) : 00
[673h 1651   1]                      Apic ID : C8
[674h 1652   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[678h 1656   1]              Local Sapic EID : 00
[679h 1657   3]    Proximity Domain High(24) : 000000
[67Ch 1660   4]                 Clock Domain : 00000000

[680h 1664   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[681h 1665   1]                       Length : 10

[682h 1666   1]      Proximity Domain Low(8) : 00
[683h 1667   1]                      Apic ID : CA
[684h 1668   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[688h 1672   1]              Local Sapic EID : 00
[689h 1673   3]    Proximity Domain High(24) : 000000
[68Ch 1676   4]                 Clock Domain : 00000000

[690h 1680   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[691h 1681   1]                       Length : 10

[692h 1682   1]      Proximity Domain Low(8) : 00
[693h 1683   1]                      Apic ID : CC
[694h 1684   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[698h 1688   1]              Local Sapic EID : 00
[699h 1689   3]    Proximity Domain High(24) : 000000
[69Ch 1692   4]                 Clock Domain : 00000000

[6A0h 1696   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[6A1h 1697   1]                       Length : 10

[6A2h 1698   1]      Proximity Domain Low(8) : 00
[6A3h 1699   1]                      Apic ID : CE
[6A4h 1700   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[6A8h 1704   1]              Local Sapic EID : 00
[6A9h 1705   3]    Proximity Domain High(24) : 000000
[6ACh 1708   4]                 Clock Domain : 00000000

[6B0h 1712   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[6B1h 1713   1]                       Length : 10

[6B2h 1714   1]      Proximity Domain Low(8) : 00
[6B3h 1715   1]                      Apic ID : D0
[6B4h 1716   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[6B8h 1720   1]              Local Sapic EID : 00
[6B9h 1721   3]    Proximity Domain High(24) : 000000
[6BCh 1724   4]                 Clock Domain : 00000000

[6C0h 1728   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[6C1h 1729   1]                       Length : 10

[6C2h 1730   1]      Proximity Domain Low(8) : 00
[6C3h 1731   1]                      Apic ID : D2
[6C4h 1732   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[6C8h 1736   1]              Local Sapic EID : 00
[6C9h 1737   3]    Proximity Domain High(24) : 000000
[6CCh 1740   4]                 Clock Domain : 00000000

[6D0h 1744   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[6D1h 1745   1]                       Length : 10

[6D2h 1746   1]      Proximity Domain Low(8) : 00
[6D3h 1747   1]                      Apic ID : D4
[6D4h 1748   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[6D8h 1752   1]              Local Sapic EID : 00
[6D9h 1753   3]    Proximity Domain High(24) : 000000
[6DCh 1756   4]                 Clock Domain : 00000000

[6E0h 1760   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[6E1h 1761   1]                       Length : 10

[6E2h 1762   1]      Proximity Domain Low(8) : 00
[6E3h 1763   1]                      Apic ID : D6
[6E4h 1764   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[6E8h 1768   1]              Local Sapic EID : 00
[6E9h 1769   3]    Proximity Domain High(24) : 000000
[6ECh 1772   4]                 Clock Domain : 00000000

[6F0h 1776   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[6F1h 1777   1]                       Length : 10

[6F2h 1778   1]      Proximity Domain Low(8) : 00
[6F3h 1779   1]                      Apic ID : D8
[6F4h 1780   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[6F8h 1784   1]              Local Sapic EID : 00
[6F9h 1785   3]    Proximity Domain High(24) : 000000
[6FCh 1788   4]                 Clock Domain : 00000000

[700h 1792   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[701h 1793   1]                       Length : 10

[702h 1794   1]      Proximity Domain Low(8) : 00
[703h 1795   1]                      Apic ID : DA
[704h 1796   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[708h 1800   1]              Local Sapic EID : 00
[709h 1801   3]    Proximity Domain High(24) : 000000
[70Ch 1804   4]                 Clock Domain : 00000000

[710h 1808   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[711h 1809   1]                       Length : 10

[712h 1810   1]      Proximity Domain Low(8) : 00
[713h 1811   1]                      Apic ID : DC
[714h 1812   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[718h 1816   1]              Local Sapic EID : 00
[719h 1817   3]    Proximity Domain High(24) : 000000
[71Ch 1820   4]                 Clock Domain : 00000000

[720h 1824   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[721h 1825   1]                       Length : 10

[722h 1826   1]      Proximity Domain Low(8) : 00
[723h 1827   1]                      Apic ID : DE
[724h 1828   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[728h 1832   1]              Local Sapic EID : 00
[729h 1833   3]    Proximity Domain High(24) : 000000
[72Ch 1836   4]                 Clock Domain : 00000000

[730h 1840   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[731h 1841   1]                       Length : 10

[732h 1842   1]      Proximity Domain Low(8) : 00
[733h 1843   1]                      Apic ID : E0
[734h 1844   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[738h 1848   1]              Local Sapic EID : 00
[739h 1849   3]    Proximity Domain High(24) : 000000
[73Ch 1852   4]                 Clock Domain : 00000000

[740h 1856   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[741h 1857   1]                       Length : 10

[742h 1858   1]      Proximity Domain Low(8) : 00
[743h 1859   1]                      Apic ID : E2
[744h 1860   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[748h 1864   1]              Local Sapic EID : 00
[749h 1865   3]    Proximity Domain High(24) : 000000
[74Ch 1868   4]                 Clock Domain : 00000000

[750h 1872   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[751h 1873   1]                       Length : 10

[752h 1874   1]      Proximity Domain Low(8) : 00
[753h 1875   1]                      Apic ID : E4
[754h 1876   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[758h 1880   1]              Local Sapic EID : 00
[759h 1881   3]    Proximity Domain High(24) : 000000
[75Ch 1884   4]                 Clock Domain : 00000000

[760h 1888   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[761h 1889   1]                       Length : 10

[762h 1890   1]      Proximity Domain Low(8) : 00
[763h 1891   1]                      Apic ID : E6
[764h 1892   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[768h 1896   1]              Local Sapic EID : 00
[769h 1897   3]    Proximity Domain High(24) : 000000
[76Ch 1900   4]                 Clock Domain : 00000000

[770h 1904   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[771h 1905   1]                       Length : 10

[772h 1906   1]      Proximity Domain Low(8) : 00
[773h 1907   1]                      Apic ID : E8
[774h 1908   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[778h 1912   1]              Local Sapic EID : 00
[779h 1913   3]    Proximity Domain High(24) : 000000
[77Ch 1916   4]                 Clock Domain : 00000000

[780h 1920   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[781h 1921   1]                       Length : 10

[782h 1922   1]      Proximity Domain Low(8) : 00
[783h 1923   1]                      Apic ID : EA
[784h 1924   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[788h 1928   1]              Local Sapic EID : 00
[789h 1929   3]    Proximity Domain High(24) : 000000
[78Ch 1932   4]                 Clock Domain : 00000000

[790h 1936   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[791h 1937   1]                       Length : 10

[792h 1938   1]      Proximity Domain Low(8) : 00
[793h 1939   1]                      Apic ID : EC
[794h 1940   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[798h 1944   1]              Local Sapic EID : 00
[799h 1945   3]    Proximity Domain High(24) : 000000
[79Ch 1948   4]                 Clock Domain : 00000000

[7A0h 1952   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[7A1h 1953   1]                       Length : 10

[7A2h 1954   1]      Proximity Domain Low(8) : 00
[7A3h 1955   1]                      Apic ID : EE
[7A4h 1956   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[7A8h 1960   1]              Local Sapic EID : 00
[7A9h 1961   3]    Proximity Domain High(24) : 000000
[7ACh 1964   4]                 Clock Domain : 00000000

[7B0h 1968   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[7B1h 1969   1]                       Length : 10

[7B2h 1970   1]      Proximity Domain Low(8) : 00
[7B3h 1971   1]                      Apic ID : F0
[7B4h 1972   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[7B8h 1976   1]              Local Sapic EID : 00
[7B9h 1977   3]    Proximity Domain High(24) : 000000
[7BCh 1980   4]                 Clock Domain : 00000000

[7C0h 1984   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[7C1h 1985   1]                       Length : 10

[7C2h 1986   1]      Proximity Domain Low(8) : 00
[7C3h 1987   1]                      Apic ID : F2
[7C4h 1988   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[7C8h 1992   1]              Local Sapic EID : 00
[7C9h 1993   3]    Proximity Domain High(24) : 000000
[7CCh 1996   4]                 Clock Domain : 00000000

[7D0h 2000   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[7D1h 2001   1]                       Length : 10

[7D2h 2002   1]      Proximity Domain Low(8) : 00
[7D3h 2003   1]                      Apic ID : F4
[7D4h 2004   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[7D8h 2008   1]              Local Sapic EID : 00
[7D9h 2009   3]    Proximity Domain High(24) : 000000
[7DCh 2012   4]                 Clock Domain : 00000000

[7E0h 2016   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[7E1h 2017   1]                       Length : 10

[7E2h 2018   1]      Proximity Domain Low(8) : 00
[7E3h 2019   1]                      Apic ID : F6
[7E4h 2020   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[7E8h 2024   1]              Local Sapic EID : 00
[7E9h 2025   3]    Proximity Domain High(24) : 000000
[7ECh 2028   4]                 Clock Domain : 00000000

[7F0h 2032   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[7F1h 2033   1]                       Length : 10

[7F2h 2034   1]      Proximity Domain Low(8) : 00
[7F3h 2035   1]                      Apic ID : F8
[7F4h 2036   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[7F8h 2040   1]              Local Sapic EID : 00
[7F9h 2041   3]    Proximity Domain High(24) : 000000
[7FCh 2044   4]                 Clock Domain : 00000000

[800h 2048   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[801h 2049   1]                       Length : 10

[802h 2050   1]      Proximity Domain Low(8) : 00
[803h 2051   1]                      Apic ID : FA
[804h 2052   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[808h 2056   1]              Local Sapic EID : 00
[809h 2057   3]    Proximity Domain High(24) : 000000
[80Ch 2060   4]                 Clock Domain : 00000000

[810h 2064   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[811h 2065   1]                       Length : 10

[812h 2066   1]      Proximity Domain Low(8) : 00
[813h 2067   1]                      Apic ID : FC
[814h 2068   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[818h 2072   1]              Local Sapic EID : 00
[819h 2073   3]    Proximity Domain High(24) : 000000
[81Ch 2076   4]                 Clock Domain : 00000000

[820h 2080   1]                Subtable Type : 00 [Processor Local APIC/SAPIC Affinity]
[821h 2081   1]                       Length : 10

[822h 2082   1]      Proximity Domain Low(8) : 00
[823h 2083   1]                      Apic ID : FE
[824h 2084   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
[828h 2088   1]              Local Sapic EID : 00
[829h 2089   3]    Proximity Domain High(24) : 000000
[82Ch 2092   4]                 Clock Domain : 00000000

[830h 2096   1]                Subtable Type : 01 [Memory Affinity]
[831h 2097   1]                       Length : 28

[832h 2098   4]             Proximity Domain : 00000000
[836h 2102   2]                    Reserved1 : 0000
[838h 2104   8]                 Base Address : 0000000000000000
[840h 2112   8]               Address Length : 00000000000A0000
[848h 2120   4]                    Reserved2 : 00000000
[84Ch 2124   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
                               Hot Pluggable : 0
                                Non-Volatile : 0
[850h 2128   8]                    Reserved3 : 0000000000000000

[858h 2136   1]                Subtable Type : 01 [Memory Affinity]
[859h 2137   1]                       Length : 28

[85Ah 2138   4]             Proximity Domain : 00000000
[85Eh 2142   2]                    Reserved1 : 0000
[860h 2144   8]                 Base Address : 0000000000100000
[868h 2152   8]               Address Length : 00000000BFF00000
[870h 2160   4]                    Reserved2 : 00000000
[874h 2164   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
                               Hot Pluggable : 0
                                Non-Volatile : 0
[878h 2168   8]                    Reserved3 : 0000000000000000

[880h 2176   1]                Subtable Type : 01 [Memory Affinity]
[881h 2177   1]                       Length : 28

[882h 2178   4]             Proximity Domain : 00000000
[886h 2182   2]                    Reserved1 : 0000
[888h 2184   8]                 Base Address : 0000000100000000
[890h 2192   8]               Address Length : 0000000340000000
[898h 2200   4]                    Reserved2 : 00000000
[89Ch 2204   4]        Flags (decoded below) : 00000001
                                     Enabled : 1
                               Hot Pluggable : 0
                                Non-Volatile : 0
[8A0h 2208   8]                    Reserved3 : 0000000000000000

[8A8h 2216   1]                Subtable Type : 01 [Memory Affinity]
[8A9h 2217   1]                       Length : 28

[8AAh 2218   4]             Proximity Domain : 00000000
[8AEh 2222   2]                    Reserved1 : 0000
[8B0h 2224   8]                 Base Address : 0000000440000000
[8B8h 2232   8]               Address Length : 0000003C00000000
[8C0h 2240   4]                    Reserved2 : 00000000
[8C4h 2244   4]        Flags (decoded below) : 00000003
                                     Enabled : 1
                               Hot Pluggable : 1
                                Non-Volatile : 0
[8C8h 2248   8]                    Reserved3 : 0000000000000000

Raw Table Data: Length 2256 (0x8D0)

  0000: 53 52 41 54 D0 08 00 00 03 B9 56 4D 57 41 52 45  // SRAT......VMWARE
  0010: 45 46 49 53 52 41 54 20 01 00 04 06 56 4D 57 20  // EFISRAT ....VMW 
  0020: CE 07 00 00 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0030: 00 10 00 00 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0040: 00 10 00 02 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0050: 00 10 00 04 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0060: 00 10 00 06 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0070: 00 10 00 08 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0080: 00 10 00 0A 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0090: 00 10 00 0C 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  00A0: 00 10 00 0E 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  00B0: 00 10 00 10 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  00C0: 00 10 00 12 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  00D0: 00 10 00 14 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  00E0: 00 10 00 16 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  00F0: 00 10 00 18 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0100: 00 10 00 1A 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0110: 00 10 00 1C 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0120: 00 10 00 1E 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0130: 00 10 00 20 01 00 00 00 00 00 00 00 00 00 00 00  // ... ............
  0140: 00 10 00 22 01 00 00 00 00 00 00 00 00 00 00 00  // ..."............
  0150: 00 10 00 24 01 00 00 00 00 00 00 00 00 00 00 00  // ...$............
  0160: 00 10 00 26 01 00 00 00 00 00 00 00 00 00 00 00  // ...&............
  0170: 00 10 00 28 01 00 00 00 00 00 00 00 00 00 00 00  // ...(............
  0180: 00 10 00 2A 01 00 00 00 00 00 00 00 00 00 00 00  // ...*............
  0190: 00 10 00 2C 01 00 00 00 00 00 00 00 00 00 00 00  // ...,............
  01A0: 00 10 00 2E 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  01B0: 00 10 00 30 01 00 00 00 00 00 00 00 00 00 00 00  // ...0............
  01C0: 00 10 00 32 01 00 00 00 00 00 00 00 00 00 00 00  // ...2............
  01D0: 00 10 00 34 01 00 00 00 00 00 00 00 00 00 00 00  // ...4............
  01E0: 00 10 00 36 01 00 00 00 00 00 00 00 00 00 00 00  // ...6............
  01F0: 00 10 00 38 01 00 00 00 00 00 00 00 00 00 00 00  // ...8............
  0200: 00 10 00 3A 01 00 00 00 00 00 00 00 00 00 00 00  // ...:............
  0210: 00 10 00 3C 01 00 00 00 00 00 00 00 00 00 00 00  // ...<............
  0220: 00 10 00 3E 01 00 00 00 00 00 00 00 00 00 00 00  // ...>............
  0230: 00 10 00 40 01 00 00 00 00 00 00 00 00 00 00 00  // ...@............
  0240: 00 10 00 42 01 00 00 00 00 00 00 00 00 00 00 00  // ...B............
  0250: 00 10 00 44 01 00 00 00 00 00 00 00 00 00 00 00  // ...D............
  0260: 00 10 00 46 01 00 00 00 00 00 00 00 00 00 00 00  // ...F............
  0270: 00 10 00 48 01 00 00 00 00 00 00 00 00 00 00 00  // ...H............
  0280: 00 10 00 4A 01 00 00 00 00 00 00 00 00 00 00 00  // ...J............
  0290: 00 10 00 4C 01 00 00 00 00 00 00 00 00 00 00 00  // ...L............
  02A0: 00 10 00 4E 01 00 00 00 00 00 00 00 00 00 00 00  // ...N............
  02B0: 00 10 00 50 01 00 00 00 00 00 00 00 00 00 00 00  // ...P............
  02C0: 00 10 00 52 01 00 00 00 00 00 00 00 00 00 00 00  // ...R............
  02D0: 00 10 00 54 01 00 00 00 00 00 00 00 00 00 00 00  // ...T............
  02E0: 00 10 00 56 01 00 00 00 00 00 00 00 00 00 00 00  // ...V............
  02F0: 00 10 00 58 01 00 00 00 00 00 00 00 00 00 00 00  // ...X............
  0300: 00 10 00 5A 01 00 00 00 00 00 00 00 00 00 00 00  // ...Z............
  0310: 00 10 00 5C 01 00 00 00 00 00 00 00 00 00 00 00  // ...\............
  0320: 00 10 00 5E 01 00 00 00 00 00 00 00 00 00 00 00  // ...^............
  0330: 00 10 00 60 01 00 00 00 00 00 00 00 00 00 00 00  // ...`............
  0340: 00 10 00 62 01 00 00 00 00 00 00 00 00 00 00 00  // ...b............
  0350: 00 10 00 64 01 00 00 00 00 00 00 00 00 00 00 00  // ...d............
  0360: 00 10 00 66 01 00 00 00 00 00 00 00 00 00 00 00  // ...f............
  0370: 00 10 00 68 01 00 00 00 00 00 00 00 00 00 00 00  // ...h............
  0380: 00 10 00 6A 01 00 00 00 00 00 00 00 00 00 00 00  // ...j............
  0390: 00 10 00 6C 01 00 00 00 00 00 00 00 00 00 00 00  // ...l............
  03A0: 00 10 00 6E 01 00 00 00 00 00 00 00 00 00 00 00  // ...n............
  03B0: 00 10 00 70 01 00 00 00 00 00 00 00 00 00 00 00  // ...p............
  03C0: 00 10 00 72 01 00 00 00 00 00 00 00 00 00 00 00  // ...r............
  03D0: 00 10 00 74 01 00 00 00 00 00 00 00 00 00 00 00  // ...t............
  03E0: 00 10 00 76 01 00 00 00 00 00 00 00 00 00 00 00  // ...v............
  03F0: 00 10 00 78 01 00 00 00 00 00 00 00 00 00 00 00  // ...x............
  0400: 00 10 00 7A 01 00 00 00 00 00 00 00 00 00 00 00  // ...z............
  0410: 00 10 00 7C 01 00 00 00 00 00 00 00 00 00 00 00  // ...|............
  0420: 00 10 00 7E 01 00 00 00 00 00 00 00 00 00 00 00  // ...~............
  0430: 00 10 00 80 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0440: 00 10 00 82 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0450: 00 10 00 84 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0460: 00 10 00 86 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0470: 00 10 00 88 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0480: 00 10 00 8A 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0490: 00 10 00 8C 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  04A0: 00 10 00 8E 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  04B0: 00 10 00 90 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  04C0: 00 10 00 92 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  04D0: 00 10 00 94 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  04E0: 00 10 00 96 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  04F0: 00 10 00 98 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0500: 00 10 00 9A 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0510: 00 10 00 9C 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0520: 00 10 00 9E 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0530: 00 10 00 A0 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0540: 00 10 00 A2 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0550: 00 10 00 A4 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0560: 00 10 00 A6 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0570: 00 10 00 A8 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0580: 00 10 00 AA 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0590: 00 10 00 AC 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  05A0: 00 10 00 AE 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  05B0: 00 10 00 B0 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  05C0: 00 10 00 B2 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  05D0: 00 10 00 B4 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  05E0: 00 10 00 B6 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  05F0: 00 10 00 B8 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0600: 00 10 00 BA 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0610: 00 10 00 BC 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0620: 00 10 00 BE 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0630: 00 10 00 C0 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0640: 00 10 00 C2 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0650: 00 10 00 C4 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0660: 00 10 00 C6 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0670: 00 10 00 C8 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0680: 00 10 00 CA 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0690: 00 10 00 CC 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  06A0: 00 10 00 CE 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  06B0: 00 10 00 D0 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  06C0: 00 10 00 D2 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  06D0: 00 10 00 D4 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  06E0: 00 10 00 D6 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  06F0: 00 10 00 D8 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0700: 00 10 00 DA 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0710: 00 10 00 DC 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0720: 00 10 00 DE 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0730: 00 10 00 E0 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0740: 00 10 00 E2 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0750: 00 10 00 E4 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0760: 00 10 00 E6 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0770: 00 10 00 E8 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0780: 00 10 00 EA 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0790: 00 10 00 EC 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  07A0: 00 10 00 EE 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  07B0: 00 10 00 F0 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  07C0: 00 10 00 F2 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  07D0: 00 10 00 F4 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  07E0: 00 10 00 F6 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  07F0: 00 10 00 F8 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0800: 00 10 00 FA 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0810: 00 10 00 FC 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0820: 00 10 00 FE 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0830: 01 28 00 00 00 00 00 00 00 00 00 00 00 00 00 00  // .(..............
  0840: 00 00 0A 00 00 00 00 00 00 00 00 00 01 00 00 00  // ................
  0850: 00 00 00 00 00 00 00 00 01 28 00 00 00 00 00 00  // .........(......
  0860: 00 00 10 00 00 00 00 00 00 00 F0 BF 00 00 00 00  // ................
  0870: 00 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00  // ................
  0880: 01 28 00 00 00 00 00 00 00 00 00 00 01 00 00 00  // .(..............
  0890: 00 00 00 40 03 00 00 00 00 00 00 00 01 00 00 00  // ...@............
  08A0: 00 00 00 00 00 00 00 00 01 28 00 00 00 00 00 00  // .........(......
  08B0: 00 00 00 40 04 00 00 00 00 00 00 00 3C 00 00 00  // ...@........<...
  08C0: 00 00 00 00 03 00 00 00 00 00 00 00 00 00 00 00  // ................
