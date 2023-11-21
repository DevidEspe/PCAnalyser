unit ProcessorDB;

interface

uses
  System.Classes, System.SysUtils, SystemAccess, ProcessorCacheAndFeatures;

const
  CPUID_STD_MaximumLevel     = $00000000;
  CPUID_STD_VendorSignature  = $00000000;
  CPUID_STD_Signature        = $00000001;
  CPUID_STD_FeatureSet       = $00000001;
  CPUID_STD_CacheTlbs        = $00000002;
  CPUID_STD_SerialNumber     = $00000003;
  CPUID_STD_CacheParams      = $00000004;
  CPUID_STD_MonitorMWAIT     = $00000005;
  CPUID_STD_ThermalPower     = $00000006;
  CPUID_STD_ExtFeatureSet    = $00000007;
  CPUID_STD_DCA              = $00000009;
  CPUID_STD_ArcPerfMon       = $0000000A;
  CPUID_STD_Topology         = $0000000B;
  CPUID_STD_XSAVE            = $0000000D;
  CPUID_STD_IRDTMCE          = $0000000F;
  CPUID_STD_10H              = $00000010;
  CPUID_STD_ISGX             = $00000012;
  CPUID_STD_IPTE             = $00000014;

  CPUID_EXT_MaximumLevel     = $80000000;
  CPUID_EXT_Signature        = $80000001;
  CPUID_EXT_FeatureSet       = $80000001;
  CPUID_EXT_MarketingName1   = $80000002;
  CPUID_EXT_MarketingName2   = $80000003;
  CPUID_EXT_MarketingName3   = $80000004;
  CPUID_EXT_Level1Cache      = $80000005;
  CPUID_EXT_Level2Cache      = $80000006;
  CPUID_EXT_PowerManagement  = $80000007;
  CPUID_EXT_AA64Information  = $80000008;
  CPUID_EXT_AMDExtFeatures   = $80000008;
  CPUID_EXT_AMDSVMFeatures   = $8000000A;
  CPUID_EXT_Unsupported      = $80000099;  // Dummy command for unsuported features

  CPUID_TMX_MaximumLevel     = $80860000;
  CPUID_TMX_Signature        = $80860001;
  CPUID_TMX_SoftwareVersion  = $80860002;
  CPUID_TMX_MarketingName1   = $80860003;
  CPUID_TMX_MarketingName2   = $80860004;
  CPUID_TMX_MarketingName3   = $80860005;
  CPUID_TMX_MarketingName4   = $80860006;
  CPUID_TMX_Operation        = $80860007;

const
  cFeatureDefinitions : Array[0..236] of TFeatureDefinition = (
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:0;  FeatSet:fsStandard; Availability:faCommon; Name:'FPU';   Desc:'Floating point unit'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:1;  FeatSet:fsStandard; Availability:faCommon; Name:'VME';   Desc:'Virtual mode extension'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:2;  FeatSet:fsStandard; Availability:faCommon; Name:'DE';    Desc:'Debugging extensions'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:3;  FeatSet:fsStandard; Availability:faCommon; Name:'PSE';   Desc:'Page size extension'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:4;  FeatSet:fsStandard; Availability:faCommon; Name:'TSC';   Desc:'Time stamp counter'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:5;  FeatSet:fsStandard; Availability:faCommon; Name:'MSR';   Desc:'Machine specific registers'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:6;  FeatSet:fsStandard; Availability:faCommon; Name:'PAE';   Desc:'Physical address extension'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:7;  FeatSet:fsStandard; Availability:faCommon; Name:'MCE';   Desc:'Machine check extension'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:8;  FeatSet:fsStandard; Availability:faCommon; Name:'CX8';   Desc:'CMPXCHG8 instrucion support'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:9;  FeatSet:fsStandard; Availability:faCommon; Name:'APIC';  Desc:'APIC'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:11; FeatSet:fsStandard; Availability:faCommon; Name:'SEP';   Desc:'Fast system call (SYSENTER/SYSEXIT)'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:12; FeatSet:fsStandard; Availability:faCommon; Name:'MTRR';  Desc:'Memory type range registers'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:13; FeatSet:fsStandard; Availability:faCommon; Name:'PGE';   Desc:'Page global extension'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:13; FeatSet:fsStandard; Availability:faCommon; Name:'MCA';   Desc:'Machine check architecture'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:15; FeatSet:fsStandard; Availability:faCommon; Name:'CMOV';  Desc:'Conditional move support'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:16; FeatSet:fsStandard; Availability:faCommon; Name:'PAT';   Desc:'Page attribute table'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:17; FeatSet:fsStandard; Availability:faCommon; Name:'PSE36'; Desc:'36-bit page size extension'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:18; FeatSet:fsStandard; Availability:faIntel;  Name:'PSN';   Desc:'Processor serial number'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:19; FeatSet:fsStandard; Availability:faCommon; Name:'CLFSH'; Desc:'CLFLUSH instruction support'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:21; FeatSet:fsStandard; Availability:faIntel;  Name:'DS';    Desc:'Debug trace store'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:22; FeatSet:fsStandard; Availability:faCommon; Name:'ACPI';  Desc:'Thermal monitor and software controlled clock'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:23; FeatSet:fsStandard; Availability:faCommon; Name:'MMX';   Desc:'MMX architecture support'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:24; FeatSet:fsStandard; Availability:faCommon; Name:'FXSR';  Desc:'Fast floating point save (FXSAVE/FXRSTOR)'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:25; FeatSet:fsStandard; Availability:faCommon; Name:'SSE';   Desc:'Streaming SIMD instruction support'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:26; FeatSet:fsStandard; Availability:faCommon; Name:'SSE2';  Desc:'Streaming SIMD extensions 2'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:27; FeatSet:fsStandard; Availability:faCommon; Name:'SS';    Desc:'Self snoop'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:28; FeatSet:fsStandard; Availability:faCommon; Name:'HTT';   Desc:'Hyper-Threading technology'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:29; FeatSet:fsStandard; Availability:faCommon; Name:'TM';    Desc:'Thermal monitor support'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:30; FeatSet:fsStandard; Availability:faIntel;  Name:'IA-64'; Desc:'IA-64 Intel'),
    (Func:CPUID_STD_FeatureSet; ExX:rEDX; Index:31; FeatSet:fsStandard; Availability:faCommon; Name:'PBE';   Desc:'Pending Break Enable'),

    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:0;  FeatSet:fsStandard; Availability:faCommon; Name:'SSE3';     Desc:'Streaming SIMD extensions 3'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:1;  FeatSet:fsStandard; Availability:faCommon; Name:'PCLMULDQ'; Desc:'Carry-less Multiplication'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:2;  FeatSet:fsStandard; Availability:faIntel;  Name:'DTES64';   Desc:'64-bit debug store'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:3;  FeatSet:fsStandard; Availability:faCommon; Name:'MON';      Desc:'MONITOR/MWAIT'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:4;  FeatSet:fsStandard; Availability:faIntel;  Name:'DSCPL';    Desc:'CPL qualified debug store'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:5;  FeatSet:fsStandard; Availability:faCommon; Name:'VMX';      Desc:'Virtual machine extension (VT-x)'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:6;  FeatSet:fsStandard; Availability:faCommon; Name:'SMX';      Desc:'Safer Mode Extensions'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:7;  FeatSet:fsStandard; Availability:faCommon; Name:'EIST';     Desc:'Enhanced Intel SpeedStep Technology'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:8;  FeatSet:fsStandard; Availability:faCommon; Name:'TM2';      Desc:'Thermal Monitor 2'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:9;  FeatSet:fsStandard; Availability:faCommon; Name:'SSSE3';    Desc:'Supplemental Streaming SIMD Extensions 3'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:10; FeatSet:fsStandard; Availability:faIntel;  Name:'CNXT-ID';  Desc:'L1 Context Id'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:11; FeatSet:fsStandard; Availability:faIntel;  Name:'SLC';      Desc:'Segment Limit Checking'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:12; FeatSet:fsStandard; Availability:faCommon; Name:'FMA3';     Desc:'Fused Multiply–Add'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:13; FeatSet:fsStandard; Availability:faCommon; Name:'CX16';     Desc:'CMPXCHG16B instrucion support'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:14; FeatSet:fsStandard; Availability:faCommon; Name:'xTPR';     Desc:'Send task priority messages'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:15; FeatSet:fsStandard; Availability:faIntel;  Name:'PDCM';     Desc:'Perfmon & debug capability'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:16; FeatSet:fsStandard; Availability:faIntel;  Name:'VMC';      Desc:'Virtual Machine Channels'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:17; FeatSet:fsStandard; Availability:faCommon; Name:'PCID';     Desc:'Process context identifiers'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:18; FeatSet:fsStandard; Availability:faIntel;  Name:'DCA';      Desc:'Direct cache access for DMA writes'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:19; FeatSet:fsStandard; Availability:faCommon; Name:'SSE4.1';   Desc:'Streaming SIMD extensions 4.1'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:20; FeatSet:fsStandard; Availability:faCommon; Name:'SSE4.2';   Desc:'Streaming SIMD extensions 4.2'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:21; FeatSet:fsStandard; Availability:faIntel;  Name:'x2APIC';   Desc:'Advanced Programmable Interrupt Controller'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:22; FeatSet:fsStandard; Availability:faCommon; Name:'MOVBE';    Desc:'MOVBE instruction'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:23; FeatSet:fsStandard; Availability:faCommon; Name:'POPCNT';   Desc:'POPCNT instruction'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:24; FeatSet:fsStandard; Availability:faCommon; Name:'TSCDL';    Desc:'APIC implements one-shot operation using a TSC deadline value'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:25; FeatSet:fsStandard; Availability:faCommon; Name:'AES';      Desc:'Advanced Encryption Standard'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:26; FeatSet:fsStandard; Availability:faCommon; Name:'XSAVE';    Desc:'XSAVE, XRESTOR, XSETBV, XGETBV'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:27; FeatSet:fsStandard; Availability:faCommon; Name:'OSXSAVE';  Desc:'XSAVE enabled by OS'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:28; FeatSet:fsStandard; Availability:faCommon; Name:'AVX';      Desc:'Advanced Vector Extension'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:29; FeatSet:fsStandard; Availability:faCommon; Name:'F16C';     Desc:'F16C (half-precision) FP feature'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:30; FeatSet:fsStandard; Availability:faCommon; Name:'RDRAND';   Desc:'On-chip Random Number Generator'),
    (Func:CPUID_STD_FeatureSet; ExX:rECX; Index:31; FeatSet:fsStandard; Availability:faCommon; Name:'HVM';      Desc:'Hypervisor Virtual Machine'),

    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:0;  FeatSet:fsPowerManagement; Availability:faIntel;  Name:'DTS';    Desc:'Digital temperature sensor'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:1;  FeatSet:fsPowerManagement; Availability:faIntel;  Name:'DAE';    Desc:'Intel Turbo Boost Technology'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:2;  FeatSet:fsPowerManagement; Availability:faCommon; Name:'ARAT';   Desc:'APIC-Timer-always-running feature'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:4;  FeatSet:fsPowerManagement; Availability:faIntel;  Name:'PLN';    Desc:'Power limit notification controls'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:5;  FeatSet:fsPowerManagement; Availability:faIntel;  Name:'ECMD';   Desc:'Clock modulation duty cycle extension'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:6;  FeatSet:fsPowerManagement; Availability:faIntel;  Name:'PTM';    Desc:'Package thermal management'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:7;  FeatSet:fsPowerManagement; Availability:faIntel;  Name:'HWPCAP'; Desc:'HWP Capabilities, Request and Status'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:8;  FeatSet:fsPowerManagement; Availability:faIntel;  Name:'HWPNOT'; Desc:'HWP Interrupt Notification'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:9;  FeatSet:fsPowerManagement; Availability:faIntel;  Name:'HWPACT'; Desc:'HWP Request Activity Window'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:10; FeatSet:fsPowerManagement; Availability:faIntel;  Name:'HWPEGY'; Desc:'HWP Request Energy Performance'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:11; FeatSet:fsPowerManagement; Availability:faIntel;  Name:'HWPPKG'; Desc:'HWP Request Package Level MSRs'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:13; FeatSet:fsPowerManagement; Availability:faIntel;  Name:'HDC';    Desc:'HDC base registers'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:14; FeatSet:fsPowerManagement; Availability:faIntel;  Name:'TBMT3';  Desc:'Intel Turbo Boost Max Technology 3.0'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:15; FeatSet:fsPowerManagement; Availability:faIntel;  Name:'HWPPC';  Desc:'HWP Highest Performance Change'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:16; FeatSet:fsPowerManagement; Availability:faIntel;  Name:'HWPPI';  Desc:'HWP PECI Override Support'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:17; FeatSet:fsPowerManagement; Availability:faIntel;  Name:'FHWP';   Desc:'Flexible HWP Support'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:18; FeatSet:fsPowerManagement; Availability:faIntel;  Name:'FAHWP';  Desc:'Fast Access IA32_HWP_REQUEST MSR'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:19; FeatSet:fsPowerManagement; Availability:faIntel;  Name:'HWFB';   Desc:'Hardware feedback'),
    (Func:CPUID_STD_ThermalPower; ExX:rEAX; Index:20; FeatSet:fsPowerManagement; Availability:faIntel;  Name:'IILHWP'; Desc:'Ignore Idle Logical CPU HWP Request'),

    (Func:CPUID_STD_ThermalPower; ExX:rECX; Index:0; FeatSet:fsPowerManagement; Availability:faCommon; Name:'PERF';  Desc:'Effective frequency interface support (MPERF, APERF)'),
    (Func:CPUID_STD_ThermalPower; ExX:rECX; Index:1; FeatSet:fsPowerManagement; Availability:faIntel;  Name:'ACNT2'; Desc:'ACNT2 Reporting Mechanism'),
    (Func:CPUID_STD_ThermalPower; ExX:rECX; Index:3; FeatSet:fsPowerManagement; Availability:faIntel;  Name:'EEPS';  Desc:'Energy Efficient Policy support'),

    (Func:CPUID_EXT_PowerManagement; ExX:rEDX; Index:0; FeatSet:fsPowerManagement; Availability:faAMD;    Name:'TS';     Desc:'Temperature Sensor'),
    (Func:CPUID_EXT_PowerManagement; ExX:rEDX; Index:1; FeatSet:fsPowerManagement; Availability:faAMD;    Name:'FID';    Desc:'Frequency ID control'),
    (Func:CPUID_EXT_PowerManagement; ExX:rEDX; Index:2; FeatSet:fsPowerManagement; Availability:faAMD;    Name:'VID';    Desc:'Voltage ID Control'),
    (Func:CPUID_EXT_PowerManagement; ExX:rEDX; Index:3; FeatSet:fsPowerManagement; Availability:faAMD;    Name:'TTP';    Desc:'ThermTrip'),
    (Func:CPUID_EXT_PowerManagement; ExX:rEDX; Index:4; FeatSet:fsPowerManagement; Availability:faAMD;    Name:'HTC';    Desc:'Hardware Thermal Control'),
    (Func:CPUID_EXT_PowerManagement; ExX:rEDX; Index:6; FeatSet:fsPowerManagement; Availability:faAMD;    Name:'100MHZ'; Desc:'100 MHz Multiplier Control'),
    (Func:CPUID_EXT_PowerManagement; ExX:rEDX; Index:7; FeatSet:fsPowerManagement; Availability:faAMD;    Name:'HWPSC';  Desc:'Hardware P-state control'),
    (Func:CPUID_EXT_PowerManagement; ExX:rEDX; Index:8; FeatSet:fsPowerManagement; Availability:faCommon; Name:'TSCIV';  Desc:'Invariant TSC'),
    (Func:CPUID_EXT_PowerManagement; ExX:rEDX; Index:9; FeatSet:fsPowerManagement; Availability:faAMD;    Name:'CPB';    Desc:'Core Performance Boost'),
    (Func:CPUID_EXT_PowerManagement; ExX:rEDX; Index:10; FeatSet:fsPowerManagement; Availability:faAMD;   Name:'ROEF';   Desc:'Read-only Effective Frequency Interface'),
    (Func:CPUID_EXT_PowerManagement; ExX:rEDX; Index:11; FeatSet:fsPowerManagement; Availability:faAMD;   Name:'PFI';    Desc:'Proc Feedback Interface'),
    (Func:CPUID_EXT_PowerManagement; ExX:rEDX; Index:12; FeatSet:fsPowerManagement; Availability:faAMD;   Name:'PA';     Desc:'Processor Accumulator Support'),
    (Func:CPUID_EXT_PowerManagement; ExX:rEDX; Index:13; FeatSet:fsPowerManagement; Availability:faAMD;   Name:'CSB';    Desc:'ConnectedStandby Support'),
    (Func:CPUID_EXT_PowerManagement; ExX:rEDX; Index:14; FeatSet:fsPowerManagement; Availability:faAMD;   Name:'RAPL';   Desc:'RAPL instruction set'),

    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:0;  FeatSet:fsExtended; Availability:faCommon; Name:'FSGSBASE';   Desc:'RD/WR FSGSBASE Instructions'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:1;  FeatSet:fsExtended; Availability:faCommon; Name:'ITA';        Desc:'IA32_TSC_ADJUST MSR'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:2;  FeatSet:fsExtended; Availability:faIntel;  Name:'SGX';        Desc:'Software Guard Extensions'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:3;  FeatSet:fsExtended; Availability:faCommon; Name:'BMI1';       Desc:'Bit Manipulation Instruction Set 1'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:4;  FeatSet:fsExtended; Availability:faIntel;  Name:'HLE';        Desc:'TSX Hardware Lock Elision'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:5;  FeatSet:fsExtended; Availability:faCommon; Name:'AVX2';       Desc:'Advanced Vector Extensions 2'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:7;  FeatSet:fsExtended; Availability:faCommon; Name:'SMEP';       Desc:'Supervisor Mode Execution Prevention'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:8;  FeatSet:fsExtended; Availability:faCommon; Name:'BMI2';       Desc:'Bit Manipulation Instruction Set 2'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:9;  FeatSet:fsExtended; Availability:faIntel;  Name:'ERMS';       Desc:'Enhanced REP MOVSB/STOSB'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:10; FeatSet:fsExtended; Availability:faCommon; Name:'INVPCID';    Desc:'INVPCID instruction'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:11; FeatSet:fsExtended; Availability:faIntel;  Name:'RTM';        Desc:'TSX Restricted Transactional Memory'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:12; FeatSet:fsExtended; Availability:faCommon; Name:'PQM';        Desc:'Platform Quality of Service Monitoring'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:13; FeatSet:fsExtended; Availability:faCommon; Name:'FPUCSDS';    Desc:'FPU CS and FPU DS deprecated'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:14; FeatSet:fsExtended; Availability:faCommon; Name:'MPX';        Desc:'Intel Memory Protection Extensions'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:15; FeatSet:fsExtended; Availability:faCommon; Name:'PQE';        Desc:'Platform Quality of Service Enforcement'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:16; FeatSet:fsExtended; Availability:faCommon; Name:'AVX512F';    Desc:'AVX-512 Foundation'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:17; FeatSet:fsExtended; Availability:faCommon; Name:'AVX512DQ';   Desc:'AVX-512 Doubleword and Quadword Instructions'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:18; FeatSet:fsExtended; Availability:faCommon; Name:'RDSEED';     Desc:'RDSEED instruction'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:19; FeatSet:fsExtended; Availability:faCommon; Name:'ADX';        Desc:'Intel Multi-Precision Add-Carry Instruction Extensions'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:20; FeatSet:fsExtended; Availability:faCommon; Name:'SMAP';       Desc:'Supervisor Mode Access Prevention'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:21; FeatSet:fsExtended; Availability:faCommon; Name:'AVX512IFMA'; Desc:'AVX-512 Integer Fused Multiply-Add Instructions'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:22; FeatSet:fsExtended; Availability:faIntel;  Name:'PCOMMIT';    Desc:'PCOMMIT instruction'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:23; FeatSet:fsExtended; Availability:faCommon; Name:'CLFLUSHOPT'; Desc:'CLFLUSHOPT instruction'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:24; FeatSet:fsExtended; Availability:faCommon; Name:'CLWB';       Desc:'CLWB instruction'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:25; FeatSet:fsExtended; Availability:faIntel;  Name:'IPT';        Desc:'Intel Processor Trace'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:26; FeatSet:fsExtended; Availability:faCommon; Name:'AVX512PF';   Desc:'AVX-512 Prefetch Instructions'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:27; FeatSet:fsExtended; Availability:faCommon; Name:'AVX512ER';   Desc:'AVX-512 Exponential and Reciprocal Instructions'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:28; FeatSet:fsExtended; Availability:faCommon; Name:'AVX512CD';   Desc:'AVX-512 Conflict Detection Instructions'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:29; FeatSet:fsExtended; Availability:faCommon; Name:'SHA';        Desc:'Intel SHA extensions'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:30; FeatSet:fsExtended; Availability:faCommon; Name:'AVX512BW';   Desc:'AVX-512 Byte and Word Instructions'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEBX; Index:31; FeatSet:fsExtended; Availability:faCommon; Name:'AVX512VL';   Desc:'AVX-512 Vector Length Extensions'),

    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:0;  FeatSet:fsExtended; Availability:faCommon; Name:'PREFETCHWT1';     Desc:'PREFETCHWT1 instruction'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:1;  FeatSet:fsExtended; Availability:faCommon; Name:'AVX512VBMI';      Desc:'AVX-512 Vector Bit Manipulation Instructions'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:2;  FeatSet:fsExtended; Availability:faCommon; Name:'UMIP';            Desc:'User-mode Instruction Prevention'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:3;  FeatSet:fsExtended; Availability:faCommon; Name:'PKU';             Desc:'Memory Protection Keys for User-mode pages'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:4;  FeatSet:fsExtended; Availability:faIntel;  Name:'OSPKE';           Desc:'PKU enabled by OS'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:5;  FeatSet:fsExtended; Availability:faCommon; Name:'WAITPKG';         Desc:'Wait and Pause Enhancements'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:6;  FeatSet:fsExtended; Availability:faCommon; Name:'AVX512VBMI2';     Desc:'AVX-512 Vector Bit Manipulation Instructions 2'),
    //(Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:7; FeatSet:fsExtended; Availability:faCommon; Name:'SHSTK'; Desc:''),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:8;  FeatSet:fsExtended; Availability:faIntel;  Name:'GFNI';            Desc:'Galois Field instructions'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:9;  FeatSet:fsExtended; Availability:faIntel;  Name:'VAES';            Desc:'Vector AES instruction set (VEX-256/EVEX)'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:10; FeatSet:fsExtended; Availability:faIntel;  Name:'VPCLMULQDQ';      Desc:'CLMUL instruction set (VEX-256/EVEX)'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:11; FeatSet:fsExtended; Availability:faCommon; Name:'AVX512VNNI';      Desc:'AVX-512 Vector Neural Network Instructions'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:12; FeatSet:fsExtended; Availability:faCommon; Name:'AVX512BITALG';    Desc:'AVX-512 BITALG instructions'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:14; FeatSet:fsExtended; Availability:faCommon; Name:'AVX512VPOPCNTDQ'; Desc:'AVX-512 Vector Population Count Double and Quad-word'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:22; FeatSet:fsExtended; Availability:faCommon; Name:'RDPID';           Desc:'Read Processor ID and IA32_TSC_AUX'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:25; FeatSet:fsExtended; Availability:faCommon; Name:'CLDEMOTE';        Desc:'Cache line demote'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:27; FeatSet:fsExtended; Availability:faCommon; Name:'MOVDIRI';         Desc:'MOVDIRI:Direct stores'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:28; FeatSet:fsExtended; Availability:faCommon; Name:'MOVDIR64B';       Desc:'MOVDIR64B:Direct stores'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:29; FeatSet:fsExtended; Availability:faCommon; Name:'ENQCMD';          Desc:'Enqueue Stores'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rECX; Index:30; FeatSet:fsExtended; Availability:faIntel;  Name:'SGXLC';           Desc:'SGX Launch Configuration'),

    (Func:CPUID_STD_ExtFeatureSet; ExX:rEDX; Index:2;  FeatSet:fsExtended; Availability:faCommon; Name:'AVX5124VNNIW';         Desc:'AVX-512 4-register Neural Network Instructions'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEDX; Index:3;  FeatSet:fsExtended; Availability:faCommon; Name:'AVX5124FMAPS';         Desc:'AVX-512 4-register Multiply Accumulation Single precision'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEDX; Index:4;  FeatSet:fsExtended; Availability:faIntel;  Name:'FSRM';                 Desc:'Fast Short REP MOVSB'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEDX; Index:8;  FeatSet:fsExtended; Availability:faCommon; Name:'AVX512VP2INTERSECT';   Desc:'AVX-512 VP2INTERSECT Doubleword and Quadword Instructions'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEDX; Index:10; FeatSet:fsExtended; Availability:faIntel;  Name:'MDCLEAR';              Desc:'MD_CLEAR support'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEDX; Index:13; FeatSet:fsExtended; Availability:faIntel;  Name:'TSXFORCEABORT';        Desc:'TSX Force Abort'),
    //(Func:CPUID_STD_ExtFeatureSet; ExX:rEDX; Index:14; FeatSet:fsExtended; Availability:faCommon; Name:'SERIALIZE'; Desc:'Serialize instruction execution'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEDX; Index:16; FeatSet:fsExtended; Availability:faIntel;  Name:'TSXLDTRK';             Desc:'TSX suspend load address tracking'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEDX; Index:18; FeatSet:fsExtended; Availability:faIntel;  Name:'PCONFIG';              Desc:'Platform configuration (Memory Encryption Technologies Instructions)'),
    //(Func:CPUID_STD_ExtFeatureSet; ExX:rEDX; Index:20; FeatSet:fsExtended; Availability:faCommon; Name:'IBT'; Desc:''),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEDX; Index:26; FeatSet:fsExtended; Availability:faCommon; Name:'IBRSIBPB';             Desc:'Indirect Branch Restricted Speculation (IBRS) and Indirect Branch Prediction Barrier (IBPB)'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEDX; Index:27; FeatSet:fsExtended; Availability:faCommon; Name:'STIBP';                Desc:'Single Thread Indirect Branch Predictor, part of IBC'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEDX; Index:29; FeatSet:fsExtended; Availability:faCommon; Name:'IA32ARCHCAPABILITIES'; Desc:'Enumerates support for the IA32_ARCH_CAPABILITIES MSR.'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEDX; Index:30; FeatSet:fsExtended; Availability:faCommon; Name:'IA32CORECAPABILITIES'; Desc:'Enumerates support for the IA32_CORE_CAPABILITIES MSR.'),
    (Func:CPUID_STD_ExtFeatureSet; ExX:rEDX; Index:31; FeatSet:fsExtended; Availability:faCommon; Name:'SSBD';                 Desc:'Speculative Store Bypass Disable'),

    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:0;  FeatSet:fsExtended; Availability:faCommon; Name:'LSAHF';         Desc:'LAHF/SAHF support'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:1;  FeatSet:fsExtended; Availability:faAMD;    Name:'CMPL';          Desc:'Core multiprocessing legacy'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:2;  FeatSet:fsExtended; Availability:faAMD;    Name:'SVM';           Desc:'Secure Virtual Machine (AMD-V)'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:3;  FeatSet:fsExtended; Availability:faAMD;    Name:'EXTAPIC';       Desc:'Extended APIC space'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:4;  FeatSet:fsExtended; Availability:faAMD;    Name:'CR8L';          Desc:'CR8 in 32-bit mode'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:5;  FeatSet:fsExtended; Availability:faCommon; Name:'ABM';           Desc:'Advanced bit manipulation (lzcnt and popcnt)'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:6;  FeatSet:fsExtended; Availability:faAMD;    Name:'SSE4A';         Desc:'Streaming SIMD extensions 4a'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:7;  FeatSet:fsExtended; Availability:faAMD;    Name:'MSSEM';         Desc:'Misaligned SSE mode'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:8;  FeatSet:fsExtended; Availability:faCommon; Name:'3DNOWPREFETCH'; Desc:'PREFETCH and PREFETCHW instructions'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:9;  FeatSet:fsExtended; Availability:faAMD;    Name:'OSVW';          Desc:'OS Visible Workaround'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:10; FeatSet:fsExtended; Availability:faAMD;    Name:'IBS';           Desc:'Instruction Based Sampling'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:11; FeatSet:fsExtended; Availability:faAMD;    Name:'XOP';           Desc:'XOP instruction set'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:12; FeatSet:fsExtended; Availability:faAMD;    Name:'SKINIT';        Desc:'SKINIT/STGI instructions'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:13; FeatSet:fsExtended; Availability:faAMD;    Name:'WDT';           Desc:'Watchdog timer'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:15; FeatSet:fsExtended; Availability:faAMD;    Name:'LWP';           Desc:'Light Weight Profiling'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:16; FeatSet:fsExtended; Availability:faAMD;    Name:'FMA4';          Desc:'4 operands Fused Multiply-Add'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:17; FeatSet:fsExtended; Availability:faAMD;    Name:'TCE';           Desc:'Translation Cache Extension'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:19; FeatSet:fsExtended; Availability:faAMD;    Name:'NODEIDMSR';     Desc:'NodeID MSR'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:21; FeatSet:fsExtended; Availability:faAMD;    Name:'TBM';           Desc:'Trailing Bit Manipulation'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:22; FeatSet:fsExtended; Availability:faAMD;    Name:'TOPOEXT';       Desc:'Topology Extensions'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:23; FeatSet:fsExtended; Availability:faAMD;    Name:'PERFCTRCORE';   Desc:'Core performance counter extensions'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:24; FeatSet:fsExtended; Availability:faAMD;    Name:'PERFCTRNB';     Desc:'NB performance counter extensions'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:26; FeatSet:fsExtended; Availability:faAMD;    Name:'DBX';           Desc:'Data breakpoint extensions'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:27; FeatSet:fsExtended; Availability:faAMD;    Name:'PERFTSC';       Desc:'Performance TSC'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:28; FeatSet:fsExtended; Availability:faAMD;    Name:'PCXL2I';        Desc:'L2I perf counter extensions'),
    (Func:CPUID_EXT_FeatureSet; ExX:rECX; Index:29; FeatSet:fsExtended; Availability:faAMD;    Name:'MWAITX';        Desc:'MwaitExtended support'),

    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:0;  FeatSet:fsExtended; Availability:faAMD;    Name:'FPU';     Desc:'Onboard x87 FPU'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:1;  FeatSet:fsExtended; Availability:faAMD;    Name:'VME';     Desc:'Virtual mode extensions'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:2;  FeatSet:fsExtended; Availability:faAMD;    Name:'DE';      Desc:'Debugging extensions'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:3;  FeatSet:fsExtended; Availability:faAMD;    Name:'PSE';     Desc:'Page Size Extension'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:4;  FeatSet:fsExtended; Availability:faAMD;    Name:'TSC';     Desc:'Time Stamp Counter'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:5;  FeatSet:fsExtended; Availability:faAMD;    Name:'MSR';     Desc:'Model-specific registers'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:6;  FeatSet:fsExtended; Availability:faAMD;    Name:'PAE';     Desc:'Physical Address Extension'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:7;  FeatSet:fsExtended; Availability:faAMD;    Name:'MCE';     Desc:'Machine Check Exception'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:8;  FeatSet:fsExtended; Availability:faAMD;    Name:'CX8';     Desc:'CMPXCHG8 (compare-and-swap) instruction'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:9;  FeatSet:fsExtended; Availability:faAMD;    Name:'APIC';    Desc:'On-chip APIC hardware'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:11; FeatSet:fsExtended; Availability:faCommon; Name:'SYSCALL'; Desc:'SYSCALL and SYSRET instructions'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:12; FeatSet:fsExtended; Availability:faAMD;    Name:'MTRR';    Desc:'Memory Type Range Registers'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:13; FeatSet:fsExtended; Availability:faAMD;    Name:'PGE';     Desc:'Page global enable'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:14; FeatSet:fsExtended; Availability:faAMD;    Name:'MCA';     Desc:'Machine check architecture'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:15; FeatSet:fsExtended; Availability:faAMD;    Name:'CMOV';    Desc:'Conditional move and FCMOV instructions'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:16; FeatSet:fsExtended; Availability:faAMD;    Name:'PAT';     Desc:'Page Attribute Table'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:17; FeatSet:fsExtended; Availability:faAMD;    Name:'PSE36';   Desc:'36-bit page size extension'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:19; FeatSet:fsExtended; Availability:faAMD;    Name:'MP';      Desc:'Multiprocessing capable'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:20; FeatSet:fsExtended; Availability:faAMD;    Name:'XD';      Desc:'Execute Disable Bit (DEP)'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:20; FeatSet:fsExtended; Availability:faIntel;  Name:'NX';      Desc:'No-execute page protection (DEP)'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:22; FeatSet:fsExtended; Availability:faAMD;    Name:'MMX+';    Desc:'Extended MMX instructions'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:23; FeatSet:fsExtended; Availability:faAMD;    Name:'MMX';     Desc:'MMX instructions'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:24; FeatSet:fsExtended; Availability:faAMD;    Name:'FXSR';    Desc:'FXSAVE, FXRSTOR instructions, CR4 bit 9'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:25; FeatSet:fsExtended; Availability:faAMD;    Name:'FXSROPT'; Desc:'FXSAVE/FXRSTOR optimizations'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:26; FeatSet:fsExtended; Availability:faCommon; Name:'1GBLPS';  Desc:'1-GByte pages are available'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:27; FeatSet:fsExtended; Availability:faCommon; Name:'RDTSCP';  Desc:'RDTSCP instruction'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:29; FeatSet:fsExtended; Availability:faCommon; Name:'x64';     Desc:'x86 with 64-Bit Support (AMD64/EM64T)'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:30; FeatSet:fsExtended; Availability:faAMD;    Name:'3DNOW+';  Desc:'Extended 3DNow! extensions'),
    (Func:CPUID_EXT_FeatureSet; ExX:rEDX; Index:31; FeatSet:fsExtended; Availability:faAMD;    Name:'3DNOW';   Desc:'3DNow! extensions'),

    (Func:CPUID_EXT_AMDExtFeatures; ExX:rEBX; Index:0; FeatSet:fsExtended; Availability:faAMD; Name:'CLZERO';        Desc:''),
    (Func:CPUID_EXT_AMDExtFeatures; ExX:rEBX; Index:1; FeatSet:fsExtended; Availability:faAMD; Name:'INSTRETCNTMSR'; Desc:'Instruction Retired Counter MSR'),
    (Func:CPUID_EXT_AMDExtFeatures; ExX:rEBX; Index:2; FeatSet:fsExtended; Availability:faAMD; Name:'RSTRFPERRPTRS'; Desc:'FP Error Pointers Restored by XRSTOR'),
    (Func:CPUID_EXT_AMDExtFeatures; ExX:rEBX; Index:4; FeatSet:fsExtended; Availability:faAMD; Name:'RDPRU';         Desc:'RDPRU instruction'),
    (Func:CPUID_EXT_AMDExtFeatures; ExX:rEBX; Index:8; FeatSet:fsExtended; Availability:faAMD; Name:'MCOMMIT';       Desc:'MCOMMIT instruction'),
    (Func:CPUID_EXT_AMDExtFeatures; ExX:rEBX; Index:9; FeatSet:fsExtended; Availability:faAMD; Name:'WBNOINVD';      Desc:'WBNOINVD instruction'),

    (Func:CPUID_EXT_AMDSVMFeatures; ExX:rEDX; Index:0;  FeatSet:fsSecureVirtualMachine; Availability:faAMD; Name:'NP';       Desc:'Nested paging'),
    (Func:CPUID_EXT_AMDSVMFeatures; ExX:rEDX; Index:1;  FeatSet:fsSecureVirtualMachine; Availability:faAMD; Name:'LBRVS';    Desc:'LBR virtualization support'),
    (Func:CPUID_EXT_AMDSVMFeatures; ExX:rEDX; Index:2;  FeatSet:fsSecureVirtualMachine; Availability:faAMD; Name:'SVML';     Desc:'SVM lock support'),
    (Func:CPUID_EXT_AMDSVMFeatures; ExX:rEDX; Index:3;  FeatSet:fsSecureVirtualMachine; Availability:faAMD; Name:'NRIPS';    Desc:'NRIP save support'),
    (Func:CPUID_EXT_AMDSVMFeatures; ExX:rEDX; Index:4;  FeatSet:fsSecureVirtualMachine; Availability:faAMD; Name:'TRMSR';    Desc:'MSR base TSC rate control'),
    (Func:CPUID_EXT_AMDSVMFeatures; ExX:rEDX; Index:5;  FeatSet:fsSecureVirtualMachine; Availability:faAMD; Name:'VMCBCB';   Desc:'VMCB clean bits support'),
    (Func:CPUID_EXT_AMDSVMFeatures; ExX:rEDX; Index:6;  FeatSet:fsSecureVirtualMachine; Availability:faAMD; Name:'FBASID';   Desc:'Flush by ASID support'),
    (Func:CPUID_EXT_AMDSVMFeatures; ExX:rEDX; Index:7;  FeatSet:fsSecureVirtualMachine; Availability:faAMD; Name:'DAS';      Desc:'Decode Assists support'),
    (Func:CPUID_EXT_AMDSVMFeatures; ExX:rEDX; Index:10; FeatSet:fsSecureVirtualMachine; Availability:faAMD; Name:'PIF';      Desc:'Pause Intercept Filter support'),
    (Func:CPUID_EXT_AMDSVMFeatures; ExX:rEDX; Index:13; FeatSet:fsSecureVirtualMachine; Availability:faAMD; Name:'AVIC';     Desc:'AMD Virtual Interupt Controller'),
    (Func:CPUID_EXT_AMDSVMFeatures; ExX:rEDX; Index:15; FeatSet:fsSecureVirtualMachine; Availability:faAMD; Name:'VLAS';     Desc:'Virtualized VMLOAD and VMSAVE'),
    (Func:CPUID_EXT_AMDSVMFeatures; ExX:rEDX; Index:16; FeatSet:fsSecureVirtualMachine; Availability:faAMD; Name:'VGIF';     Desc:'Virtualized GIF support'),
    (Func:CPUID_EXT_AMDSVMFeatures; ExX:rEDX; Index:17; FeatSet:fsSecureVirtualMachine; Availability:faAMD; Name:'GMET';     Desc:'Guest Mode Execution Trap'),
    (Func:CPUID_EXT_AMDSVMFeatures; ExX:rEDX; Index:20; FeatSet:fsSecureVirtualMachine; Availability:faAMD; Name:'SPECCTRL'; Desc:'SPEC_CTRL virtualization'),
    (Func:CPUID_EXT_AMDSVMFeatures; ExX:rEDX; Index:24; FeatSet:fsSecureVirtualMachine; Availability:faAMD; Name:'TLBICTL';  Desc:'Support for INVLPGB/TLBSYNC hypervisor enable in VMCB and TLBSYNC intercept')
  );

type
  TCPUDBRecord = record
    Vendor,
    Family,
    ModelEx,
    Stepping,
    TechProcess : Integer;
    MCA,
    CoreDesign : String;
  end;
  TCPUDB = Array [0..117] of TCPUDBRecord;

  TProcessor_Database = class helper for TProcessor
  type
    TVendorCacheDetect = (vcdStandard, vcdExtended, vcdCombined);

    TCPUVendorInfo = record
      Signature,
      Prefix,
      Name : String;
      FeatureAvailability : TFeatureAvailability;
      CacheDetect : TVendorCacheDetect;
    end;

    TCacheDescriptorInfo = record
      Descriptor : Byte;
      Level : TCacheLevel;
      Associativity : TCacheAssociativity;
      Size : Integer;
      LineSize : Integer;
      Description : String;
    end;

    TFeatureDefinition = record
      Func : Cardinal;
      ExX : TExXRegister;
      Index : Byte;
      FeatSet : TFeatureSet;
      Availability : TFeatureAvailability;
      Name,
      Desc : String;
    end;

  const
    CPUDB : TCPUDB = (
      // Intel
      (Vendor:2; Family:$06; ModelEx:$01; Stepping:-1; TechProcess: 350; MCA:'P6';                 CoreDesign:''),
      (Vendor:2; Family:$06; ModelEx:$03; Stepping:-1; TechProcess: 350; MCA:'P6';                 CoreDesign:''),
      (Vendor:2; Family:$06; ModelEx:$05; Stepping:-1; TechProcess: 350; MCA:'P6';                 CoreDesign:''),
      (Vendor:2; Family:$06; ModelEx:$06; Stepping:-1; TechProcess: 350; MCA:'P6';                 CoreDesign:''),
      (Vendor:2; Family:$06; ModelEx:$07; Stepping:-1; TechProcess: 250; MCA:'P6';                 CoreDesign:'Katmai'),
      (Vendor:2; Family:$06; ModelEx:$08; Stepping:-1; TechProcess: 180; MCA:'P6';                 CoreDesign:'Coppermine'),
      (Vendor:2; Family:$06; ModelEx:$09; Stepping:-1; TechProcess: 130; MCA:'Pentium M';          CoreDesign:'Banias'),
      (Vendor:2; Family:$06; ModelEx:$0A; Stepping:-1; TechProcess: 350; MCA:'P6';                 CoreDesign:''),
      (Vendor:2; Family:$06; ModelEx:$0B; Stepping:-1; TechProcess: 130; MCA:'P6';                 CoreDesign:'Tualatin'),
      (Vendor:2; Family:$06; ModelEx:$0D; Stepping:-1; TechProcess: 90;  MCA:'Pentium M';          CoreDesign:'Dothan'),
      (Vendor:2; Family:$06; ModelEx:$0E; Stepping:-1; TechProcess: 65;  MCA:'Modified Pentium M'; CoreDesign:'Yonah'),
      (Vendor:2; Family:$06; ModelEx:$0F; Stepping:-1; TechProcess: 65;  MCA:'Core';               CoreDesign:'Merom'),
      (Vendor:2; Family:$06; ModelEx:$15; Stepping:-1; TechProcess: 90;  MCA:'Pentium M';          CoreDesign:'Tolapai'),
      (Vendor:2; Family:$06; ModelEx:$16; Stepping:-1; TechProcess: 65;  MCA:'Core';               CoreDesign:'Merom L'),
      (Vendor:2; Family:$06; ModelEx:$17; Stepping:-1; TechProcess: 45;  MCA:'Penryn';             CoreDesign:'Wolfdale, Yorkfield'),
      (Vendor:2; Family:$06; ModelEx:$17; Stepping:-1; TechProcess: 45;  MCA:'Penryn';             CoreDesign:'Harpertown, QC, Wolfdale, Yorkfield'),
      (Vendor:2; Family:$06; ModelEx:$1A; Stepping:-1; TechProcess: 45;  MCA:'Nehalem';            CoreDesign:'Bloomfield, EP, WS'),
      (Vendor:2; Family:$06; ModelEx:$1C; Stepping:-1; TechProcess: 45;  MCA:'Bonnel';             CoreDesign:'Silverthorne, Diamondville, Pineview'),
      (Vendor:2; Family:$06; ModelEx:$1D; Stepping:-1; TechProcess: 45;  MCA:'Penryn';             CoreDesign:'Dunnington'),
      (Vendor:2; Family:$06; ModelEx:$1E; Stepping:-1; TechProcess: 45;  MCA:'Nehalem';            CoreDesign:'Lynnfield'),
      (Vendor:2; Family:$06; ModelEx:$1E; Stepping:-1; TechProcess: 45;  MCA:'Nehalem';            CoreDesign:'Clarksfield'),
      (Vendor:2; Family:$06; ModelEx:$1F; Stepping:-1; TechProcess: 45;  MCA:'Nehalem';            CoreDesign:'Auburndale, Havendale'),
      (Vendor:2; Family:$06; ModelEx:$25; Stepping:-1; TechProcess: 32;  MCA:'Westmere';           CoreDesign:'Arrandale, Clarkdale'),
      (Vendor:2; Family:$06; ModelEx:$26; Stepping:-1; TechProcess: 45;  MCA:'Bonnel';             CoreDesign:'Lincroft'),
      (Vendor:2; Family:$06; ModelEx:$27; Stepping:-1; TechProcess: 32;  MCA:'Saltwell';           CoreDesign:'Penwell'),
      (Vendor:2; Family:$06; ModelEx:$2A; Stepping:-1; TechProcess: 32;  MCA:'Sandy Bridge';       CoreDesign:'M, H'),
      (Vendor:2; Family:$06; ModelEx:$2C; Stepping:-1; TechProcess: 32;  MCA:'Westmere';           CoreDesign:'Gulftown, EP'),
      (Vendor:2; Family:$06; ModelEx:$2D; Stepping:-1; TechProcess: 32;  MCA:'Sandy Bridge';       CoreDesign:'E, EN, EP'),
      (Vendor:2; Family:$06; ModelEx:$2E; Stepping:-1; TechProcess: 45;  MCA:'Nehalem';            CoreDesign:'EX'),
      (Vendor:2; Family:$06; ModelEx:$2F; Stepping:-1; TechProcess: 32;  MCA:'Westmere';           CoreDesign:'EX'),
      (Vendor:2; Family:$06; ModelEx:$35; Stepping:-1; TechProcess: 32;  MCA:'Saltwell';           CoreDesign:'Cloverview'),
      (Vendor:2; Family:$06; ModelEx:$36; Stepping:-1; TechProcess: 32;  MCA:'Saltwell';           CoreDesign:'CedarView'),
      (Vendor:2; Family:$06; ModelEx:$37; Stepping:-1; TechProcess: 22;  MCA:'Silvermont';         CoreDesign:'Bay Trail'),
      (Vendor:2; Family:$06; ModelEx:$3A; Stepping:-1; TechProcess: 22;  MCA:'Ivy Bridge';         CoreDesign:'M, H, Gladden'),
      (Vendor:2; Family:$06; ModelEx:$3C; Stepping:-1; TechProcess: 22;  MCA:'Haswell';            CoreDesign:'S'),
      (Vendor:2; Family:$06; ModelEx:$3D; Stepping:-1; TechProcess: 14;  MCA:'Broadwell';          CoreDesign:'U, Y, S'),
      (Vendor:2; Family:$06; ModelEx:$3E; Stepping:-1; TechProcess: 22;  MCA:'Ivy Bridge';         CoreDesign:'E, EN, EP, EX'),
      (Vendor:2; Family:$06; ModelEx:$3F; Stepping:-1; TechProcess: 22;  MCA:'Haswell';            CoreDesign:'E, EP, EX'),
      (Vendor:2; Family:$06; ModelEx:$45; Stepping:-1; TechProcess: 22;  MCA:'Haswell';            CoreDesign:'ULT'),
      (Vendor:2; Family:$06; ModelEx:$46; Stepping:-1; TechProcess: 22;  MCA:'Haswell';            CoreDesign:'GT3E'),
      (Vendor:2; Family:$06; ModelEx:$47; Stepping:-1; TechProcess: 14;  MCA:'Broadwell';          CoreDesign:'H'),
      (Vendor:2; Family:$06; ModelEx:$4A; Stepping:-1; TechProcess: 22;  MCA:'Silvermont';         CoreDesign:'Tangier'),
      (Vendor:2; Family:$06; ModelEx:$4C; Stepping:-1; TechProcess: 14;  MCA:'Airmont';            CoreDesign:'Cherry Trail, Braswell'),
      (Vendor:2; Family:$06; ModelEx:$4D; Stepping:-1; TechProcess: 22;  MCA:'Silvermont';         CoreDesign:'Avoton, Rangeley'),
      (Vendor:2; Family:$06; ModelEx:$4E; Stepping:-1; TechProcess: 14;  MCA:'Skylake';            CoreDesign:'Y, U'),
      (Vendor:2; Family:$06; ModelEx:$4F; Stepping:-1; TechProcess: 14;  MCA:'Broadwel';           CoreDesign:'E, EP, EX'),
      (Vendor:2; Family:$06; ModelEx:$55; Stepping:$4; TechProcess: 14;  MCA:'Skylake';            CoreDesign:'SP, X, DE, W'),
      (Vendor:2; Family:$06; ModelEx:$55; Stepping:$5; TechProcess: 14;  MCA:'Cascade Lake';       CoreDesign:'SP, X, W'),
      (Vendor:2; Family:$06; ModelEx:$55; Stepping:$6; TechProcess: 14;  MCA:'Cascade Lake';       CoreDesign:'SP, X, W'),
      (Vendor:2; Family:$06; ModelEx:$55; Stepping:$7; TechProcess: 14;  MCA:'Cascade Lake';       CoreDesign:'SP, X, W'),
      (Vendor:2; Family:$06; ModelEx:$56; Stepping:-1; TechProcess: 14;  MCA:'Broadwel';           CoreDesign:'DE, Hewitt Lake'),
      (Vendor:2; Family:$06; ModelEx:$57; Stepping:-1; TechProcess: 14;  MCA:'Knights Landing';    CoreDesign:''),
      (Vendor:2; Family:$06; ModelEx:$5A; Stepping:-1; TechProcess: 22;  MCA:'Silvermont';         CoreDesign:'Anniedale'),
      (Vendor:2; Family:$06; ModelEx:$5C; Stepping:-1; TechProcess: 14;  MCA:'Goldmont';           CoreDesign:'Apollo Lake, Broxton'),
      (Vendor:2; Family:$06; ModelEx:$5D; Stepping:-1; TechProcess: 22;  MCA:'Silvermont';         CoreDesign:'SoFIA'),
      (Vendor:2; Family:$06; ModelEx:$5E; Stepping:-1; TechProcess: 14;  MCA:'Skylake';            CoreDesign:'DT, H, S'),
      (Vendor:2; Family:$06; ModelEx:$5F; Stepping:-1; TechProcess: 14;  MCA:'Goldmont';           CoreDesign:'Denverton'),
      (Vendor:2; Family:$06; ModelEx:$66; Stepping:-1; TechProcess: 10;  MCA:'Cannon Lake';        CoreDesign:'U'),
      (Vendor:2; Family:$06; ModelEx:$6A; Stepping:-1; TechProcess: 10;  MCA:'Ice Lake';           CoreDesign:'X'),
      (Vendor:2; Family:$06; ModelEx:$6C; Stepping:-1; TechProcess: 10;  MCA:'Ice Lake';           CoreDesign:'D'),
      (Vendor:2; Family:$06; ModelEx:$7A; Stepping:-1; TechProcess: 14;  MCA:'Gemini Lake';        CoreDesign:''),
      (Vendor:2; Family:$06; ModelEx:$7D; Stepping:-1; TechProcess: 10;  MCA:'Ice Lake';           CoreDesign:''),
      (Vendor:2; Family:$06; ModelEx:$7E; Stepping:-1; TechProcess: 10;  MCA:'Ice Lake';           CoreDesign:'U, Y'),
      (Vendor:2; Family:$06; ModelEx:$85; Stepping:-1; TechProcess: 14;  MCA:'Knights Mill';       CoreDesign:''),
      (Vendor:2; Family:$06; ModelEx:$86; Stepping:-1; TechProcess: 10;  MCA:'Tremont';            CoreDesign:'Elkhart Lake'),
      (Vendor:2; Family:$06; ModelEx:$8C; Stepping:-1; TechProcess: 10;  MCA:'Tiger Lake';         CoreDesign:'U'),
      (Vendor:2; Family:$06; ModelEx:$8D; Stepping:-1; TechProcess: 10;  MCA:'Tiger Lake';         CoreDesign:''),
      (Vendor:2; Family:$06; ModelEx:$8E; Stepping:$9; TechProcess: 14;  MCA:'Kaby Lake';          CoreDesign:'Y, U'),
      (Vendor:2; Family:$06; ModelEx:$8E; Stepping:$A; TechProcess: 14;  MCA:'Coffee Lake';        CoreDesign:'U'),
      (Vendor:2; Family:$06; ModelEx:$8E; Stepping:$B; TechProcess: 14;  MCA:'Whiskey Lake';       CoreDesign:'U'),
      (Vendor:2; Family:$06; ModelEx:$8E; Stepping:$C; TechProcess: 14;  MCA:'Comet Lake';         CoreDesign:'U'),
      (Vendor:2; Family:$06; ModelEx:$97; Stepping:-1; TechProcess: 10;  MCA:'Alder Lake';         CoreDesign:'S'),
      (Vendor:2; Family:$06; ModelEx:$9A; Stepping:-1; TechProcess: 10;  MCA:'Alder Lake';         CoreDesign:'P'),
      (Vendor:2; Family:$06; ModelEx:$9D; Stepping:-1; TechProcess: 10;  MCA:'Sunny Cove';         CoreDesign:''),
      (Vendor:2; Family:$06; ModelEx:$9E; Stepping:$B; TechProcess: 14;  MCA:'Coffee Lake';        CoreDesign:''),
      (Vendor:2; Family:$06; ModelEx:$9E; Stepping:$A; TechProcess: 14;  MCA:'Coffee Lake';        CoreDesign:'S, H, E'),
      (Vendor:2; Family:$06; ModelEx:$9E; Stepping:$D; TechProcess: 14;  MCA:'Coffee Lake';        CoreDesign:''),
      (Vendor:2; Family:$06; ModelEx:$9E; Stepping:$C; TechProcess: 14;  MCA:'Coffee Lake';        CoreDesign:''),
      (Vendor:2; Family:$06; ModelEx:$9E; Stepping:$9; TechProcess: 14;  MCA:'Kaby Lake';          CoreDesign:'DT, H, S, X'),
      (Vendor:2; Family:$06; ModelEx:$A5; Stepping:-1; TechProcess: 14;  MCA:'Comet Lake';         CoreDesign:''),
      (Vendor:2; Family:$06; ModelEx:$A6; Stepping:-1; TechProcess: 14;  MCA:'Comet Lake';         CoreDesign:'U, L'),
      (Vendor:2; Family:$06; ModelEx:$A7; Stepping:-1; TechProcess: 14;  MCA:'Rocket Lake';        CoreDesign:'S'),
      (Vendor:2; Family:$0B; ModelEx:$00; Stepping:-1; TechProcess: 45;  MCA:'Knights Ferry';      CoreDesign:''),
      (Vendor:2; Family:$0B; ModelEx:$01; Stepping:-1; TechProcess: 22;  MCA:'Knights Corner';     CoreDesign:''),
      (Vendor:2; Family:$0F; ModelEx:$01; Stepping:-1; TechProcess: 180; MCA:'Netburst';           CoreDesign:'Wilamette'),
      (Vendor:2; Family:$0F; ModelEx:$02; Stepping:-1; TechProcess: 180; MCA:'Netburst';           CoreDesign:'Northwood'),
      (Vendor:2; Family:$0F; ModelEx:$03; Stepping:-1; TechProcess: 180; MCA:'Netburst';           CoreDesign:'Prescott'),
      (Vendor:2; Family:$0F; ModelEx:$04; Stepping:-1; TechProcess: 180; MCA:'Netburst';           CoreDesign:'Prescott'),
      (Vendor:2; Family:$0F; ModelEx:$06; Stepping:-1; TechProcess: 180; MCA:'Netburst';           CoreDesign:''),

      // AMD
      (Vendor:3; Family:$15; ModelEx:$00; Stepping:-1; TechProcess: 32; MCA:'Bulldozer';   CoreDesign:'Zurich, Valencia'),
      (Vendor:3; Family:$15; ModelEx:$01; Stepping:-1; TechProcess: 32; MCA:'Bulldozer';   CoreDesign:'Zurich, Valencia'),
      (Vendor:3; Family:$15; ModelEx:$10; Stepping:-1; TechProcess: 32; MCA:'Piledriver';  CoreDesign:'Richland, Vishera, Delhi, Seoul, Abu Dhabi'),
      (Vendor:3; Family:$15; ModelEx:$11; Stepping:-1; TechProcess: 32; MCA:'Piledriver';  CoreDesign:'Trinity'),
      (Vendor:3; Family:$15; ModelEx:$30; Stepping:-1; TechProcess: 28; MCA:'Steamroller'; CoreDesign:'Kaveri'),
      (Vendor:3; Family:$15; ModelEx:$38; Stepping:-1; TechProcess: 28; MCA:'Steamroller'; CoreDesign:'Godavari'),
      (Vendor:3; Family:$15; ModelEx:$60; Stepping:-1; TechProcess: 28; MCA:'Excavator';   CoreDesign:'Carrizo'),
      (Vendor:3; Family:$15; ModelEx:$65; Stepping:-1; TechProcess: 28; MCA:'Excavator';   CoreDesign:'Bristol Ridge'),
      (Vendor:3; Family:$15; ModelEx:$70; Stepping:-1; TechProcess: 28; MCA:'Excavator';   CoreDesign:'Stoney Ridge'),
      (Vendor:3; Family:$16; ModelEx:$00; Stepping:-1; TechProcess: 0;  MCA:'Jaguar';      CoreDesign:'Kabini, Temash'),
      (Vendor:3; Family:$16; ModelEx:$30; Stepping:-1; TechProcess: 0;  MCA:'Puma';        CoreDesign:'Beema, Steppe Eagle'),
      (Vendor:3; Family:$17; ModelEx:$01; Stepping:$1; TechProcess: 14; MCA:'Zen';         CoreDesign:'Whitehaven, Summit Ridge'),
      (Vendor:3; Family:$17; ModelEx:$01; Stepping:$2; TechProcess: 14; MCA:'Zen';         CoreDesign:'Naples'),
      (Vendor:3; Family:$17; ModelEx:$08; Stepping:-1; TechProcess: 12; MCA:'Zen+';        CoreDesign:'Colfax, Pinnacle Ridge'),
      (Vendor:3; Family:$17; ModelEx:$11; Stepping:-1; TechProcess: 14; MCA:'Zen';         CoreDesign:'Raven Ridge, Snowy Owl'),
      (Vendor:3; Family:$17; ModelEx:$18; Stepping:-1; TechProcess: 12; MCA:'Zen+';        CoreDesign:'Picasso'),
      (Vendor:3; Family:$17; ModelEx:$20; Stepping:-1; TechProcess: 14; MCA:'Zen 2';       CoreDesign:'Raven2'),
      (Vendor:3; Family:$17; ModelEx:$20; Stepping:1;  TechProcess: 14; MCA:'Zen';         CoreDesign:'Dali'),
      (Vendor:3; Family:$17; ModelEx:$31; Stepping:-1; TechProcess: 14; MCA:'Zen 2';       CoreDesign:'Castle Peak/Rome'),
      (Vendor:3; Family:$17; ModelEx:$60; Stepping:-1; TechProcess: 7;  MCA:'Zen 2';       CoreDesign:'Renoir/Gray Hawk'),
      (Vendor:3; Family:$17; ModelEx:$68; Stepping:-1; TechProcess: 7;  MCA:'Zen 2';       CoreDesign:'Lucienne'),
      (Vendor:3; Family:$17; ModelEx:$71; Stepping:-1; TechProcess: 7;  MCA:'Zen 2';       CoreDesign:'Matisse'),
      (Vendor:3; Family:$17; ModelEx:$90; Stepping:-1; TechProcess: 7;  MCA:'Zen 2';       CoreDesign:'Van Gogh'),
      (Vendor:3; Family:$18; ModelEx:$00; Stepping:-1; TechProcess: 14; MCA:'Zen';         CoreDesign:'Dhyana'),
      (Vendor:3; Family:$19; ModelEx:$50; Stepping:-1; TechProcess: 7;  MCA:'Zen 3';       CoreDesign:'Cezanne'),
      (Vendor:3; Family:$19; ModelEx:$40; Stepping:-1; TechProcess: 7;  MCA:'Zen 3';       CoreDesign:'Rembrant'),
      (Vendor:3; Family:$19; ModelEx:$21; Stepping:-1; TechProcess: 7;  MCA:'Zen 3';       CoreDesign:'Vermeer'),
      (Vendor:3; Family:$19; ModelEx:$01; Stepping:-1; TechProcess: 7;  MCA:'Zen 3';       CoreDesign:'Milan'),
      (Vendor:3; Family:$19; ModelEx:$00; Stepping:-1; TechProcess: 7;  MCA:'Zen 3';       CoreDesign:'Milan')
    );

    cDescriptorInfo: Array[0..103] of TCacheDescriptorInfo = (
      (Descriptor: $01; Level: clCodeTLB;     Associativity: ca4Way;   Size: 4;        LineSize: 32;  Description: 'Code TLB, 4K pages, 4 ways, 32 entries'),
      (Descriptor: $02; Level: clCodeTLB;     Associativity: caFull;   Size: 4096;     LineSize: 2;   Description: 'Code TLB, 4M pages, fullway, 2 entries'),
      (Descriptor: $03; Level: clDataTLB;     Associativity: ca4Way;   Size: 4;        LineSize: 64;  Description: 'Data TLB, 4K pages, 4 ways, 64 entries'),
      (Descriptor: $04; Level: clDataTLB;     Associativity: ca4Way;   Size: 4096;     LineSize: 8;   Description: 'Data TLB, 4M pages, 4 ways, 8 entries'),
      (Descriptor: $05; Level: clDataTLB;     Associativity: ca4Way;   Size: 4096;     LineSize: 32;  Description: 'Data TLB, 4M pages, 4 ways, 32 entries'),
      (Descriptor: $06; Level: clLevel1Code;  Associativity: ca4Way;   Size: 8;        LineSize: 32;  Description: 'Code L1 Cache, 8K, 4 ways, 32b lines'),
      (Descriptor: $08; Level: clLevel1Code;  Associativity: ca4Way;   Size: 16;       LineSize: 32;  Description: 'Code L1 Cache, 16K, 4 ways, 32b lines'),
      (Descriptor: $0A; Level: clLevel1Data;  Associativity: ca2Way;   Size: 8;        LineSize: 32;  Description: 'Data L1 Cache, 8K, 2 ways, 32b lines'),
      (Descriptor: $0B; Level: clCodeTLB;     Associativity: ca4Way;   Size: 4096;     LineSize: 4;   Description: 'Code TLB, 4M pages, 4 ways, 4 entries'),
      (Descriptor: $0C; Level: clLevel1Data;  Associativity: ca4Way;   Size: 16;       LineSize: 32;  Description: 'Data L1 Cache, 16K, 4 ways, 32b lines'),
      (Descriptor: $10; Level: clLevel1Data;  Associativity: ca4Way;   Size: 16;       LineSize: 32;  Description: 'Data L1 Cache, 16 KB, 4 ways, 32 byte lines (IA-64)'),
      (Descriptor: $15; Level: clLevel1Code;  Associativity: ca4Way;   Size: 16;       LineSize: 32;  Description: 'Code L1 Cache, 16 KB, 4 ways, 32 byte lines (IA-64)'),
      (Descriptor: $1A; Level: clLevel2;      Associativity: ca6Way;   Size: 96;       LineSize: 64;  Description: 'Unified L2 Cache, 96 KB, 6 ways, 64 byte lines (IA-64)'),
      (Descriptor: $22; Level: clLevel3;      Associativity: ca4Way;   Size: 512;      LineSize: 64;  Description: 'Unified L3 Cache, 512K, 4 ways, 64b lines'),
      (Descriptor: $23; Level: clLevel3;      Associativity: ca8Way;   Size: 1024;     LineSize: 64;  Description: 'Unified L3 Cache, 1024K, 8 ways, 64b lines'),
      (Descriptor: $25; Level: clLevel3;      Associativity: ca8Way;   Size: 2048;     LineSize: 64;  Description: 'Unified L3 Cache, 2048K, 8 ways, 64b lines'),
      (Descriptor: $29; Level: clLevel3;      Associativity: ca8Way;   Size: 4096;     LineSize: 64;  Description: 'Unified L3 Cache, 4096K, 8 ways, 64b lines'),
      (Descriptor: $2C; Level: clLevel1Data;  Associativity: ca8Way;   Size: 32;       LineSize: 64;  Description: 'Data L1 Cache, 32 KB, 8 ways, 64 byte lines'),
      (Descriptor: $30; Level: clLevel1Code;  Associativity: ca8Way;   Size: 32;       LineSize: 64;  Description: 'Code L1 Cache, 32 KB, 8 ways, 64 byte lines'),
      (Descriptor: $39; Level: clLevel2;      Associativity: ca4Way;   Size: 128;      LineSize: 64;  Description: 'Unified L2 Cache, 128 KB, 4 ways, 64 byte lines, sectored'),
      (Descriptor: $3A; Level: clLevel2;      Associativity: ca6Way;   Size: 192;      LineSize: 64;  Description: 'Unified L2 Cache, 192 KB, 6 ways, 64 byte lines, sectored'),
      (Descriptor: $3B; Level: clLevel2;      Associativity: ca2Way;   Size: 128;      LineSize: 64;  Description: 'Unified L2 Cache, 128 KB, 2 ways, 64 byte lines, sectored'),
      (Descriptor: $3C; Level: clLevel2;      Associativity: ca4Way;   Size: 256;      LineSize: 64;  Description: 'Unified L2 Cache, 256B, 4 ways, 64 byte lines, sectored'),
      (Descriptor: $3D; Level: clLevel2;      Associativity: ca6Way;   Size: 384;      LineSize: 64;  Description: 'Unified L2 Cache, 384 KB, 6 ways, 64 byte lines, sectored'),
      (Descriptor: $3E; Level: clLevel2;      Associativity: ca4Way;   Size: 512;      LineSize: 64;  Description: 'Unified L2 Cache, 512 KB, 4 ways, 64 byte lines, sectored'),
      //(Descriptor: $40; Level: clLevel2;      Associativity: caNone;   Size: 0;        LineSize: 0;   Description: 'non integrated L2/L3 Cache'),
      (Descriptor: $41; Level: clLevel2;      Associativity: ca4Way;   Size: 128;      LineSize: 32;  Description: 'Unified L2 Cache, 128K, 4 ways, 32b lines'),
      (Descriptor: $42; Level: clLevel2;      Associativity: ca4Way;   Size: 256;      LineSize: 32;  Description: 'Unified L2 Cache, 256K, 4 ways, 32b lines'),
      (Descriptor: $43; Level: clLevel2;      Associativity: ca4Way;   Size: 512;      LineSize: 32;  Description: 'Unified L2 Cache, 512K, 4 ways, 32b lines'),
      (Descriptor: $44; Level: clLevel2;      Associativity: ca4Way;   Size: 1024;     LineSize: 32;  Description: 'Unified L2 Cache, 1024K, 4 ways, 32b lines'),
      (Descriptor: $45; Level: clLevel2;      Associativity: ca4Way;   Size: 2048;     LineSize: 32;  Description: 'Unified L2 Cache, 2048K, 4 ways, 32b lines'),
      (Descriptor: $46; Level: clLevel3;      Associativity: ca4Way;   Size: 4096;     LineSize: 64;  Description: 'Unified L3 Cache, 4096 KB, 4 ways, 64 byte lines'),
      (Descriptor: $47; Level: clLevel3;      Associativity: ca8Way;   Size: 8192;     LineSize: 64;  Description: 'Unified L3 Cache, 8192 KB, 8 ways, 64 byte lines'),
      (Descriptor: $49; Level: clLevel2;      Associativity: ca16Way;  Size: 4096;     LineSize: 64;  Description: 'Unified L2 Cache, 4096 KB, 16 ways, 64 byte lines (Core 2)'),
      (Descriptor: $49; Level: clLevel3;      Associativity: ca16Way;  Size: 4096;     LineSize: 64;  Description: 'Unified L3 Cache, 4096 KB, 16 ways, 64 byte lines (P4)'),
      (Descriptor: $4A; Level: clLevel3;      Associativity: ca12Way;  Size: 6144;     LineSize: 64;  Description: 'Unified L3 Cache, 6144 KB, 12 ways, 64 byte lines'),
      (Descriptor: $4B; Level: clLevel3;      Associativity: ca16Way;  Size: 8192;     LineSize: 64;  Description: 'Unified L3 Cache, 8192 KB, 16 ways, 64 byte lines'),
      (Descriptor: $4C; Level: clLevel3;      Associativity: ca12Way;  Size: 12288;    LineSize: 64;  Description: 'Unified L3 Cache, 12288 KB, 12 ways, 64 byte lines'),
      (Descriptor: $4D; Level: clLevel3;      Associativity: ca16Way;  Size: 16384;    LineSize: 64;  Description: 'Unified L3 Cache, 16384 KB, 16 ways, 64 byte lines'),
      (Descriptor: $50; Level: clCodeTLB;     Associativity: caNone;   Size: 0;        LineSize: 64;  Description: 'Code TLB, all pages, 64 entries'),
      (Descriptor: $51; Level: clCodeTLB;     Associativity: caNone;   Size: 0;        LineSize: 128; Description: 'Code TLB, all pages, 128 entries'),
      (Descriptor: $52; Level: clCodeTLB;     Associativity: caNone;   Size: 0;        LineSize: 512; Description: 'Code TLB, all pages, 512 entries'),
      (Descriptor: $56; Level: clDataTLB;     Associativity: ca4way;   Size: 4096;     LineSize: 16;  Description: 'L0 Data TLB, 4M pages, 4 ways, 16 entries'),
      (Descriptor: $57; Level: clDataTLB;     Associativity: ca4way;   Size: 4096;     LineSize: 16;  Description: 'L0 Data TLB, 4M pages, 4 ways, 16 entries'),
      (Descriptor: $5B; Level: clDataTLB;     Associativity: caNone;   Size: 0;        LineSize: 64;  Description: 'Data TLB, all pages, 64 entries'),
      (Descriptor: $5C; Level: clDataTLB;     Associativity: caNone;   Size: 0;        LineSize: 128; Description: 'Data TLB, all pages, 128 entries'),
      (Descriptor: $5D; Level: clDataTLB;     Associativity: caNone;   Size: 0;        LineSize: 256; Description: 'Data TLB, all pages, 256 entries'),
      (Descriptor: $60; Level: clLevel1Data;  Associativity: ca8Way;   Size: 16;       LineSize: 64;  Description: 'Data L1 Cache, 16K, 8 ways, 64 byte lines, sectored'),
      (Descriptor: $66; Level: clLevel1Data;  Associativity: ca4Way;   Size: 8;        LineSize: 64;  Description: 'Data L1 Cache, 8K, 4 ways'),
      (Descriptor: $67; Level: clLevel1Data;  Associativity: ca4Way;   Size: 16;       LineSize: 64;  Description: 'Data L1 Cache, 16K, 4 ways'),
      (Descriptor: $68; Level: clLevel1Data;  Associativity: ca4Way;   Size: 32;       LineSize: 64;  Description: 'Data L1 Cache, 32K, 4 ways'),
      (Descriptor: $70; Level: clUnifiedTLB;  Associativity: ca4Way;   Size: 4;        LineSize: 32;  Description: 'Unified TLB, 4k pages, 4 ways, 32 entries'), //Cyrix
      (Descriptor: $70; Level: clTrace;       Associativity: ca8Way;   Size: 12;       LineSize: 0;   Description: 'Trace L1 Cache, 12 KµOPs, 4 ways'),
      (Descriptor: $71; Level: clTrace;       Associativity: ca8Way;   Size: 16;       LineSize: 0;   Description: 'Trace L1 Cache, 16 KµOPs, 4 ways'),
      (Descriptor: $72; Level: clTrace;       Associativity: ca8Way;   Size: 32;       LineSize: 0;   Description: 'Trace L1 Cache, 32 KµOPs, 4 ways'),
      (Descriptor: $73; Level: clTrace;       Associativity: ca8Way;   Size: 64;       LineSize: 0;   Description: 'Trace L1 Cache, 64 KµOPs, 8 ways'),
      (Descriptor: $77; Level: clLevel1Code;  Associativity: ca4Way;   Size: 16;       LineSize: 64;  Description: 'Code L1 Cache, 16 KB, 4 ways, 64 byte lines, sectored (IA-64)'),
      (Descriptor: $78; Level: clLevel2;      Associativity: ca4Way;   Size: 1024;     LineSize: 64;  Description: 'Unified L2 Cache, 1024K, 4 ways, 64 byte lines'),
      (Descriptor: $79; Level: clLevel2;      Associativity: ca8Way;   Size: 128;      LineSize: 64;  Description: 'Unified L2 Cache, 128K, 8 ways, 32b lines, dual-sectored'),
      (Descriptor: $7A; Level: clLevel2;      Associativity: ca8Way;   Size: 256;      LineSize: 64;  Description: 'Unified L2 Cache, 512K, 8 ways, 32b lines, dual-sectored'),
      (Descriptor: $7B; Level: clLevel2;      Associativity: ca8Way;   Size: 512;      LineSize: 64;  Description: 'Unified L2 Cache, 1024K, 8 ways, 32b lines, dual-sectored'),
      (Descriptor: $7C; Level: clLevel2;      Associativity: ca8Way;   Size: 1024;     LineSize: 64;  Description: 'Unified L2 Cache, 1024K, 8 ways, 64 byte lines, dual-sectored'),
      (Descriptor: $7D; Level: clLevel2;      Associativity: ca8Way;   Size: 2048;     LineSize: 64;  Description: 'Unified L2 Cache, 2048K, 8 ways, 64 byte lines'),
      (Descriptor: $7E; Level: clLevel2;      Associativity: ca8Way;   Size: 1024;     LineSize: 128; Description: 'Unified L2 Cache, 256 KB, 8 ways, 128 byte lines, sect. (IA-64)'),
      (Descriptor: $7F; Level: clLevel2;      Associativity: ca2Way;   Size: 512;      LineSize: 64;  Description: 'Unified L2 Cache, 512 KB, 2 ways, 64 byte lines'),
      (Descriptor: $80; Level: clUnifiedTLB;  Associativity: ca4Way;   Size: 16;       LineSize: 32;  Description: 'Unified TLB, 16k pages, 4 ways, 32 entries'), //Cyrix
      (Descriptor: $81; Level: clLevel2;      Associativity: ca8Way;   Size: 128;      LineSize: 32;  Description: 'Unified L2 Cache, 128K, 8 ways, 32 byte lines'),
      (Descriptor: $82; Level: clLevel2;      Associativity: ca8Way;   Size: 256;      LineSize: 32;  Description: 'Unified L2 Cache, 256K, 8 ways, 32b lines'),
      (Descriptor: $83; Level: clLevel2;      Associativity: ca8Way;   Size: 512;      LineSize: 32;  Description: 'Unified L2 Cache, 512K, 8 ways, 32b lines'),
      (Descriptor: $84; Level: clLevel2;      Associativity: ca8Way;   Size: 1024;     LineSize: 32;  Description: 'Unified L2 Cache, 1024K, 8 ways, 32b lines'),
      (Descriptor: $85; Level: clLevel2;      Associativity: ca8Way;   Size: 2048;     LineSize: 32;  Description: 'Unified L2 Cache, 2048K, 8 ways, 32b lines'),
      (Descriptor: $86; Level: clLevel2;      Associativity: ca4Way;   Size: 512;      LineSize: 64;  Description: 'Unified L2 Cache, 512 KB, 4 ways, 64 byte lines'),
      (Descriptor: $87; Level: clLevel2;      Associativity: ca8Way;   Size: 1024;     LineSize: 64;  Description: 'Unified L2 Cache, 1024 KB, 8 ways, 64 byte lines'),
      (Descriptor: $88; Level: clLevel3;      Associativity: ca4Way;   Size: 2048;     LineSize: 64;  Description: 'Unified L3 Cache, 2048 KB, 4 ways, 64 byte lines (IA-64)'),
      (Descriptor: $89; Level: clLevel3;      Associativity: ca4Way;   Size: 4069;     LineSize: 64;  Description: 'Unified L3 Cache, 4096 KB, 4 ways, 64 byte lines (IA-64)'),
      (Descriptor: $8A; Level: clLevel3;      Associativity: ca4Way;   Size: 8192;     LineSize: 64;  Description: 'Unified L3 Cache, 8192 KB, 4 ways, 64 byte lines (IA-64)'),
      (Descriptor: $8D; Level: clLevel3;      Associativity: ca12Way;  Size: 3096;     LineSize: 128; Description: 'Unified L3 Cache, 3096 KB, 12 ways, 128 byte lines (IA-64)'),
      (Descriptor: $90; Level: clCodeTLB;     Associativity: caFull;   Size: 4096;     LineSize: 64;  Description: 'Code TLB, 4K...256M pages, fully, 64 entries (IA-64)'),
      (Descriptor: $96; Level: clDataTLB;     Associativity: caFull;   Size: 4;        LineSize: 32;  Description: 'Data TLB, 4K...256M pages, fully, 32 entries (IA-64)'),
      (Descriptor: $96; Level: clLevel1Data;  Associativity: caFull;   Size: 4;        LineSize: 32;  Description: 'Data L1 Cache, 4K...256M pages, fully, 32 entries (IA-64)'),
      (Descriptor: $9B; Level: clDataTLB;     Associativity: caFull;   Size: 4;        LineSize: 96;  Description: 'Data L2 TLB, 4K...256M pages, fully, 96 entries (IA-64)'),
      (Descriptor: $9B; Level: clLevel2;      Associativity: caFull;   Size: 4096;     LineSize: 96;  Description: 'Data L2 Cache, 4K...256M pages, fully, 96 entries (IA-64)'),
      (Descriptor: $B0; Level: clCodeTLB;     Associativity: ca4Way;   Size: 4;        LineSize: 128; Description: 'Code TLB, 4K pages, 4 ways, 128 entries'),
      (Descriptor: $B1; Level: clCodeTLB;     Associativity: ca4way;   Size: 4096;     LineSize: 4;   Description: 'Code TLB, 4M pages, 4 ways, 4 entries'),
      (Descriptor: $B2; Level: clCodeTLB;     Associativity: ca4way;   Size: 4096;     LineSize: 64;  Description: 'Code TLB: 4KByte pages, 4-way set associative, 64 entries'),
      (Descriptor: $B3; Level: clDataTLB;     Associativity: ca4Way;   Size: 4;        LineSize: 128; Description: 'Data TLB: 4 KByte pages, 4-way set associative, 128 entries'),
      (Descriptor: $B4; Level: clDataTLB;     Associativity: ca4Way;   Size: 4;        LineSize: 256; Description: 'Data TLB1: 4 KByte pages, 4-way associative, 256 entries'),
      (Descriptor: $BA; Level: clDataTLB;     Associativity: ca4Way;   Size: 4;        LineSize: 64;  Description: 'Data TLB1: 4 KByte pages, 4-way associative, 64 entries'),
      (Descriptor: $C0; Level: clDataTLB;     Associativity: ca4Way;   Size: 4096;     LineSize: 8;   Description: 'Data TLB: 4 KByte and 4 MByte pages, 4-way associative, 8 entries'),
      (Descriptor: $CA; Level: clDataTLB;     Associativity: ca4Way;   Size: 4096;     LineSize: 512; Description: 'Shared 2nd-Level TLB: 4 KByte pages, 4-way associative, 512 entries'),
      (Descriptor: $D0; Level: clLevel3;      Associativity: ca4Way;   Size: 524288;   LineSize: 64;  Description: 'L3 Cache: 512 KByte, 4-way set associative, 64 byte line size'),
      (Descriptor: $D1; Level: clLevel3;      Associativity: ca4Way;   Size: 1048576;  LineSize: 64;  Description: 'L3 Cache: 1 MByte, 4-way set associative, 64 byte line size'),
      (Descriptor: $D2; Level: clLevel3;      Associativity: ca4Way;   Size: 2097152;  LineSize: 64;  Description: 'L3 Cache: 2 MByte, 4-way set associative, 64 byte line size'),
      (Descriptor: $D6; Level: clLevel3;      Associativity: ca8Way;   Size: 1048576;  LineSize: 64;  Description: 'L3 Cache: 1 MByte, 8-way set associative, 64 byte line size'),
      (Descriptor: $D7; Level: clLevel3;      Associativity: ca8Way;   Size: 2097152;  LineSize: 64;  Description: 'L3 Cache: 2 MByte, 8-way set associative, 64 byte line size'),
      (Descriptor: $D8; Level: clLevel3;      Associativity: ca8Way;   Size: 4194304;  LineSize: 64;  Description: 'L3 Cache: 4 MByte, 8-way set associative, 64 byte line size'),
      (Descriptor: $DC; Level: clLevel3;      Associativity: ca12Way;  Size: 1572864;  LineSize: 64;  Description: 'L3 Cache: 1.5 MByte, 12-way set associative, 64 byte line size'),
      (Descriptor: $DD; Level: clLevel3;      Associativity: ca12Way;  Size: 3145728;  LineSize: 64;  Description: 'L3 Cache: 3 MByte, 12-way set associative, 64 byte line size'),
      (Descriptor: $DE; Level: clLevel3;      Associativity: ca12Way;  Size: 6291456;  LineSize: 64;  Description: 'L3 Cache: 6 MByte, 12-way set associative, 64 byte line size'),
      (Descriptor: $E2; Level: clLevel3;      Associativity: ca16Way;  Size: 2097152;  LineSize: 64;  Description: 'L3 Cache: 2 MByte, 16-way set associative, 64 byte line size'),
      (Descriptor: $E3; Level: clLevel3;      Associativity: ca16Way;  Size: 4194304;  LineSize: 64;  Description: 'L3 Cache: 4 MByte, 16-way set associative, 64 byte line size'),
      (Descriptor: $E4; Level: clLevel3;      Associativity: ca16Way;  Size: 8388608;  LineSize: 64;  Description: 'L3 Cache: 8 MByte, 16-way set associative, 64 byte line size'),
      (Descriptor: $EA; Level: clLevel3;      Associativity: ca24Way;  Size: 12582912; LineSize: 64;  Description: 'L3 Cache: 12MByte, 24-way set associative, 64 byte line size'),
      (Descriptor: $EB; Level: clLevel3;      Associativity: ca24Way;  Size: 18874368; LineSize: 64;  Description: 'L3 Cache: 18MByte, 24-way set associative, 64 byte line size'),
      (Descriptor: $EC; Level: clLevel3;      Associativity: ca24Way;  Size: 25165824; LineSize: 64;  Description: 'L3 Cache: 24MByte, 24-way set associative, 64 byte line size')
    );

    cVendorNames : Array [cvNone..cvTransmeta] of TCpuVendorInfo = (
      (Signature: ''; Prefix: '';   Name: '';
        FeatureAvailability: faCommon; CacheDetect: vcdStandard),  (Signature: 'BadCpuVendor'; Prefix: 'Unknown';   Name: 'Unknown Vendor';
        FeatureAvailability: faCommon; CacheDetect: vcdStandard),  (Signature: 'GenuineIntel'; Prefix: 'Intel';     Name: 'Intel Corporation';
        FeatureAvailability: faIntel;  CacheDetect: vcdStandard),  (Signature: 'AuthenticAMD'; Prefix: 'AMD';       Name: 'Advanced Micro Devices';
        FeatureAvailability: faAmd;    CacheDetect: vcdExtended),  (Signature: 'CyrixInstead'; Prefix: 'Cyrix';     Name: 'Via Technologies Inc';
        FeatureAvailability: faCyrix;  CacheDetect: vcdCombined),  (Signature: 'CentaurHauls'; Prefix: 'Via';       Name: 'Via Technologies Inc';
        FeatureAvailability: faCommon; CacheDetect: vcdExtended),  (Signature: 'NexGenDriven'; Prefix: 'NexGen';    Name: 'NexGen Inc';
        FeatureAvailability: faCommon; CacheDetect: vcdStandard),  (Signature: 'UMC UMC UMC '; Prefix: 'UMC';       Name: 'United Microelectronics Corp';
        FeatureAvailability: faCommon; CacheDetect: vcdStandard),  (Signature: 'RiseRiseRise'; Prefix: 'Rise';      Name: 'Rise Technology';
        FeatureAvailability: faCommon; CacheDetect: vcdStandard),  (Signature: 'SiS SiS SiS';  Prefix: 'SiS';       Name: 'SiS';
        FeatureAvailability: faCommon; CacheDetect: vcdStandard),  (Signature: 'Geode by NSC'; Prefix: 'NSC';       Name: 'National Semiconductor';
        FeatureAvailability: faCommon; CacheDetect: vcdStandard),  (Signature: 'GenuineTMx86'; Prefix: 'Transmeta'; Name: 'Transmeta';
        FeatureAvailability: faAmd;    CacheDetect: vcdExtended)
    );

    rsGenericName_x86 = 'x86 Familie %d Modell %d Stepping %d';
    rsGenericName_x64 = 'x64 Familie %d Modell %d Stepping %d';
    rsGenericName_ia64 = 'ia64 Familie %d Modell %d Stepping %d';

    procedure IntelLookupName;
    procedure AMDLookupName;
    procedure CyrixLookupName;
    procedure IDTLookupName;
    procedure NexGenLookupName;
    procedure UMCLookupName;
    procedure RiseLookupName;
    procedure SiSLookupName;
    procedure GeodeLookupName;
    procedure TransmetaLookupName;
  end;

implementation

procedure TProcessor_Database.IntelLookupName;
begin
  case FFamily of
    4 : case FModel of
         0 : begin
           FCPUName := 'i80486DX';
           FCodename := 'P4';
           case FStepping of
             0 : FRevision := 'A0-A1';
             1 : FRevision := 'B2-B6';
             2 : FRevision := 'C0';
             3 : FRevision := 'C1';
             4 : FRevision := 'D0';
           end;
         end;
         1 : begin
           FCPUName := 'i80486DX';
           if FStepping in [4, 5] then
             FCPUName := FCPUName + '-SL';
           FCodename := 'P4';
           case FStepping of
             0 : FRevision := 'cA2,cA3';
             1 : FRevision := 'cB0,cB1';
             3 : FRevision := 'cC0';
             4 : FRevision := 'aA0,aA1';
             5 : FRevision := 'aB0';
           end;
         end;
         2 : begin
           FCPUName := 'i80486SX';
           if FStepping = 3 then
             FCPUName := FCPUName + '-WB';
           if FStepping in [10..11] then
             FCPUName := FCPUName + '-SL';
           FCodename := 'P4S';
           case FStepping of
             0  : FRevision := 'A0';
             2  : FRevision := 'B0';
             3  : FRevision := 'bBx';
             4  : FRevision := 'gAx';
             7  : FRevision := 'cA0';
             8  : FRevision := 'cB0';
             10 : FRevision := 'aA0,aA1';
             11 : FRevision := 'aB0,aC0';
           end;
         end;
         3 : begin
           FCPUName := 'i80486DX/2';
           if FStepping in [4, 5] then
             FCPUName := FCPUName + '-SL';
           FCodename := 'P24S';
           if FStepping = 6 then
           begin
             FCPUName := FCPUName + '-WB';
             FCodeName := 'P24D';
           end;
           case FStepping of
             2 : FRevision := 'A0-A2';
             3 : FRevision := 'B1';
             4 : FRevision := 'aA0,aA1';
             5 : FRevision := 'aB0,aC0';
             6 : FRevision := 'A';
           end;
         end;
         4 : begin
           FCPUName := 'i80486SL';
           FCodename := 'P23';
           if FStepping = 0 then
             FRevision := 'A';
         end;
         5 : begin
           FCPUName := 'i80486SX/2';
           FCodename := 'P23';
           if FStepping = 11 then
             FRevision := 'aC0';
         end;
         7 : begin
           FCPUName := 'i80486DX/2-WB';
           FCodename := 'P24D';
           FRevision := 'A';
         end;
         8, 9 : begin
           FCPUName := 'i80486DX/4';
           if FCPUType = 1 then
             FCPUName := FCPUName + ' OverDrive';
           FCodename := 'P24C';
           FRevision := 'A';
         end;
    end;
    5 : case FModel of
         0 : begin
           FCPUName := 'Pentium';
           FCodename := 'A80501,P5';
           FRevision := 'Ax';
           FTech := '0.80 µm';
         end;
         1 : begin
           FCPUName := 'Pentium';
           FCodename := 'A80501,P5';
           FTech := '0.80 µm';
           if FCPUType = 1 then
           begin
             FCPUName := 'Pentium OverDrive for P5';
             FCodename := 'PODP5V,P5T';
             if FStepping = 10 then
               FRevision := 'tA0';
           end else
             case FStepping of
               3 : FRevision := 'B1';
               4 : FRevision := 'B2';
               5 : FRevision := 'C1';
               7 : FRevision := 'D1';
             end;
         end;
         2 : begin
           {FCPUName := 'Mobile Pentium';
           FCodeName := 'P54LM';
           case FStepping of
             5  : FRevision := 'A1,mA1';
             11 : FRevision := 'mcB1';
             12 : FRevision := 'mcC0';
           end;}
           case FCPUType of
             0 : begin
               FCPUName := 'Pentium';
               FCodename := 'A80502,P54C,P54CS';
               FTech := '0.50 µm';
               case FStepping of
                 1  : FRevision := 'B1';
                 2  : FRevision := 'B3';
                 4  : FRevision := 'B5';
                 5  : FRevision := 'C1,C2,mA1';
                 6  : FRevision := 'E0';
                 11 : FRevision := 'cB1,mcB1';
                 12 : FRevision := 'aC0,cC0,mcC0,acC0';
               end;
             end;
             1: begin
               FCPUName := 'Pentium OverDrive for P54C';
               FCodename := 'P54CT';
               FTech := '0.35 µm';
             end;
             2: begin
               FCPUName := 'Pentium OverDrive for P54C';
               FCodename := 'P54M';
               FTech := '0.35 µm';
             end;
           end;
         end;
         3 : begin
           FCPUName := 'Pentium OverDrive for 486';
           if FStepping = 1 then
             FCodename := 'P24T'
           else
             FCodename := 'P24B'
         end;
         4 : begin
           FCPUName := 'Pentium MMX';
           FCodename := 'A80503,P55C';
           FTech := '0.28 µm';
           if FCPUType = 1 then
           begin
             FCPUName := 'Pentium MMX OverDrive for P54C';
             FCodename := 'P55CTP';
             if FStepping = 4 then
               FRevision := 'oxA3';
           end else
             case FStepping of
               1 : FRevision := 'A1';
               2 : FRevision := 'A3';
               3 : FRevision := 'xB1,mxB1';
               4 : FRevision := 'xA3,mxA3';
             end;
         end;
         7 : begin
           FCPUName := 'Pentium';
           FCodename := 'A80502,P54C,P54CS';
           FTech := '0.35 µm';
         end;
         8 : begin
           FCPUName := 'Pentium MMX';
           FCodename := 'A80503,P55C';
           FTech := '0.25 µm';
           case FStepping of
             1 : FRevision := 'myA0';
             2 : FRevision := 'sB1,myB1';
           end;
         end;
    end;
    6 : case FModel of
         0 : begin
           FCPUName := 'Pentium Pro';
           FCodename := 'A80521,P6';
           FTech := '0.50 µm';
         end;
         1 : begin
           FCPUName := 'Pentium Pro';
           FCodename := 'A80521,P6';
           FTech := '0.35 µm';
           case FStepping of
             1 : FRevision := 'B0';
             2 : FRevision := 'C0';
             6 : FRevision := 'sA0';
             7 : FRevision := 'sA1';
             9 : FRevision := 'sB1';
           end;
         end;
         3 : if FCPUType = 0 then
         begin
           FCPUName := 'Pentium II';
           FCodename := 'A80522,P6L Klamath';
           FTech := '0.28 µm';
           case FStepping of
             3 : FRevision := 'C0';
             4 : FRevision := 'C1';
           end;
         end else
         begin
           FCPUName := 'Pentium II OverDrive';
           FCodename := 'POPD66X333,P6T';
           FTech := '0.28 µm';
           if FStepping = 2 then
             FRevision := 'TdB0';
         end;
         5 : begin
           FTech := '0.25 µm';
           if FCPUCache.Level2.Size >= 1024 then
           begin
             FCPUName := 'Pentium II Xeon';
             FCodename := 'A80523, P6L Deschutes';
           end else
           if FCPUCache.Level2.Size = 512 then
           begin
             FCPUName := 'Pentium II';
             FCodename := 'A80523, P6L Deschutes';
           end else
           if FCPUCache.Level2.Size = 256 then
           begin
             FCPUName := 'Pentium II PE';
             FCodename := 'Tonga';
           end else
           begin
             FCPUName := 'Celeron';
             FCodename := 'P6C Covington';
           end;
           case FStepping of
             0 : FRevision := 'dA0,mdA0,mmdA0';
             1 : FRevision := 'dA1';
             2 : FRevision := 'B0,dB0,mdB0,mmdB0';
             3 : FRevision := 'B1,dB1';
           end;
         end;
         6 : begin
           FCodename := 'Dixon';
           FTech := '0.25 µm';
           if FCPUCache.Level2.Size = 128 then
           begin
             if FCPUFeatures.Standard.FeaturesByName['PSN'].Value then
               FCPUName := 'Mobile Celeron'
             else
             begin
               FCPUName := 'Celeron';
               FCodename := 'P6C Mendocino, Celeron A';
             end;
           end else
             FCPUName := 'Mobile Pentium II';
           case FStepping of
             0  : FRevision := 'mA0';
             2  : FRevision := 'dB1';
             5  : FRevision := 'mB0';
             10 : FRevision := 'mdbA0,mdxA0,mqbA1,mqpA1';
           end;
         end;
         7 : begin
           FTech := '0.25 µm';
           if FCPUCache.Level2.Size < 1024 then
           begin
             FCPUName := 'Pentium III';
             FCodename := 'A80525,P6K Katmai';
           end else
           begin
             FCPUName := 'Pentium III Xeon';
             FCodename := 'Tanner';
           end;
           case FStepping of
             2 : FRevision := 'B0,kB0';
             3 : FRevision := 'C0,kC0';
           end;
         end;
         8 : begin
           FTech := '0.18 µm';
           if FCPUCache.Level2.Size <= 128 then
           begin
             FCPUName := 'Celeron';
             FCodename := 'Coppermine-128, Celeron II';
           end else
             case FBrand of
               1 : begin
                 FCPUName := 'Celeron';
                 FCodename := 'A80526, Coppermine';
               end;
               3 : begin
                 FCPUName := 'Pentium III Xeon';
                 FCodename := 'Cascades';
               end
               else
               begin  //2,4
                 FCPUName := 'Pentium III';
                 FCodename := 'A80526, Coppermine';
               end;
             end;
           case FStepping of
             1  : FRevision := 'A2,cA2,cA2c';
             3  : FRevision := 'B0,cB0,cB0c';
             6  : FRevision := 'C0,cC0';
             10 : FRevision := 'D0,cD0';
           end;
         end;
         9 : begin
           FTech := '0.13 µm';
           FCPUName := 'Pentium III';
           case FBrand of
             18 : begin
               FCPUName := 'Celeron M';
               FCodename := 'Banias';
               FTech := '0.13 µm';
             end;
             22 : begin
               FCPUName := 'Pentium M';
               FCodename := 'Banias';
               FTech := '0.13 µm';
             end;
           end;
         end;
         10 : begin
           FCPUName := 'Pentium III Xeon A';
           FCodename := 'A80530,Tualatin';
           FTech := '0.18 µm';
           case FStepping of
             0 : FRevision := 'A0';
             1 : FRevision := 'A1';
             4 : FRevision := 'B0';
           end;
         end;
         11 : begin
           FTech := '0.13 µm';
           FCPUName := 'Pentium III B';
           FCodename := 'A80530,Tualatin';
           case FBrand of
             1 : FCPUName := 'Celeron';
             3 : if FCPUCache.Level2.Size>256 then
                   FCPUName := 'Pentium III Xeon'
                 else
                   FCPUName := 'Celeron';
             6 : begin
               FCPUName := 'Mobile Pentium III M';
               FCodename := 'Geyservile';
             end;
             7 : begin
               FCPUName := 'Mobile Celeron';
               FCodename := 'Geyservile';
             end;
           end;
           case FStepping of
             1 : FRevision := 'tA1,A1';
             4 : FRevision := 'tB1';
           end;
         end;
         12 : begin
           FCPUName := '';
           FTech := '0.09 µm';
           FCodename := 'Dothan';
         end;
         13 : begin
           FCPUName := '';
           FTech := '0.09 µm';
           FCodename := 'Dothan';
           case FStepping of
             8 : if FCPUCache.Level2.Size = 4096 then
                   FCodename := 'Yonah';
             else FCodename := 'Dothan';
           end;
         end;
         14 : begin
           FCPUName := '';
           FTech := '65 nm';
           case FStepping of
             8, 12: FCodename := 'Yonah';
             else   FCodename := 'Dothan';
           end;
         end;
         15 : begin
           FCPUName := '';
           FTech := '65 nm';
           case FStepping of
             1 : begin
               FCodename := 'Conroe';
               if ibXeon in FIntelBrand then
                 FCodename := 'Woodcrest';
             end;
             else FCodename := 'Merom';
           end;
         end;
    end;
    7 : begin
      FCPUName := 'Itanium';
      FCodename := 'Merced';
      FTech := '0.18 µm';
    end;
    15: case FFamilyEx of
          0 : begin
            FCPUName := 'Pentium 4';
            if ibCeleron in FIntelBrand then
              FCPUName := 'Celeron 4';
            if ibMobile in FIntelBrand then
              FCPUName := FCPUName+' Mobile';
            if ibM in FIntelBrand then
              FCPUName := FCPUName+' M';
            if (ibXeon in FIntelBrand) or (GetCPUPhysicalCount > 1) then
              FCPUName := FCPUName+' Xeon';
            if ibMP in FIntelBrand then
              FCPUName := FCPUName+' MP';
            if (FCPUCache.Level2.Size <= 128) then
              FCPUName := 'Celeron';
            if (FCPUCache.Level2.Size = 256) and (FIntelBrand = []) then
              FCPUName := 'Celeron D';

            case FModel of
              0, 1: begin
                FCodename := 'P68, Willamette';
                FTech := '0.18 µm';
                if ibXeon in FIntelBrand then
                begin
                  FCodename := 'Foster';
                  if ibMP in FIntelBrand then
                    FCodename := FCodename+' MP';
                end;
                case FStepping of
                  2  : FRevision := 'D0';
                  3  : FRevision := 'E0';
                  7  : FRevision := 'B2';
                  10 : FRevision := 'C1';
                end;
              end;
              2: begin
                FCodename := 'Northwood';
                FTech := '0.13 µm';
                if (ibXeon in FIntelBrand) then
                  FCodename := 'Prestonia';
                if (ibMP in FIntelBrand) then
                  FCodename := 'Gallatin';
                case FStepping of
                  4 : FRevision := 'B0';
                  5 : FRevision := 'M0';
                  7 : FRevision := 'C1';
                  9 : FRevision := 'D1';
                end;
              end;
              3: begin
                FCodename := 'Prescott';
                FTech := '90 nm';
                if (ibXeon in FIntelBrand) then
                  FCodename := 'Nocona';
                if (ibMP in FIntelBrand) then
                  FCodename := 'Potomac';
              end;
              4: begin
                FTech := '90 nm';
                FCodeName := 'Prescott';
                if (ibCeleron in FIntelBrand) then
                begin
                  if FCPUCache.Level2.Size = 256 then
                    FCPUName := 'Celeron D'
                  else
                    FCPUName := 'Celeron';
                end;
                if (ibXeon in FIntelBrand) then
                  FCodename := 'Nocona';
                if (ibMP in FIntelBrand) then
                  FCodename := 'Potomac';
                if (FStepping = 1) and (ibXeon in FIntelBrand) and (ibMP in FIntelBrand) then
                begin
                  FCPUName := 'Pentium 4';
                  FCodeName := 'Cranford';
                end;
                if FStepping in [3, 4, 7] then
                begin
                  FCPUName := 'Pentium D';
                  FCodeName := 'Smithfield';
                end;
                if (FStepping = 3) and (ibXeon in FIntelBrand) and (ibMP in FIntelBrand) then
                begin
                  FCPUName := 'Pentium 4 DP';
                  FCodeName := 'Irwindale';
                end;
              end;
              6: begin
                FTech := '90 nm';
                FCodeName := 'Presler';
                FCPUName := 'Pentium D';
              end;
            end;
          end;
          1: begin
            FCPUName := 'Itanium 2';
            FTech := '0.13 µm';
            case FModel of
              0 : begin
                FCodename := 'McKinley';
                FTech := '0.18 µm';
              end;
              1 : FCodename := 'Madison/Deerfield';
              2 : FCodename := 'Madison 9M';
            end;
          end;
        end;
    16: begin
            FCPUName := 'Pentium 4';
            if ibCeleron in FIntelBrand then
              FCPUName := 'Celeron 4';
            if ibMobile in FIntelBrand then
              FCPUName := FCPUName+' Mobile';
            if ibM in FIntelBrand then
              FCPUName := FCPUName+' M';
            if (ibXeon in FIntelBrand) or (GetCPUPhysicalCount > 1) then
              FCPUName := FCPUName+' Xeon';
            if ibMP in FIntelBrand then
              FCPUName := FCPUName+' MP';
            if (FCPUCache.Level2.Size <= 128) then
              FCPUName := 'Celeron';
            if (FCPUCache.Level2.Size = 256) and (FIntelBrand = []) then
              FCPUName := 'Celeron D';
            if FCPUFeatures.Standard.FeaturesByName['IA64'].Value or (FArch = 9{x64 (AMD or Intel)}) then
              FCPUName := '64bit '+FCPUName;
    end;
  end;
end;

procedure TProcessor_Database.AMDLookupName;
begin
  case FFamily of
    4: case FModel of
         0: FCPUName := 'Am486DX';
         3,7: FCPUName := 'Am486DX2';
         8,9: FCPUName := 'Am486DX4';
         14, 15: begin
           FCPUName := 'Am5x86';
           FRevision := 'A';
         end;
    end;
    5: case FModel of
         0: begin
           FCPUName := 'K5';
           FCodename := 'SSA/5';
           FTech := '0.50 µm';
           case FStepping of
             0 : FRevision := 'E';
             1 : FRevision := 'F';
           end;
         end;
         1, 2, 3: begin
           FCPUName := 'K5';
           FCodename := '5k86';
           FTech := '0.35 µm';
         end;
         6: begin
           FCPUName := 'K6';
           FCodename := 'K6';
           FTech := '0.30 µm';
           case FStepping of
             1 : FRevision := 'B';
             2 : FRevision := 'C';
           end;
         end;
         7: begin
           FCPUName := 'K6';
           FCodename := 'Little Foot';
           FTech := '0.25 µm';
           FRevision := 'A';
         end;
         8: begin
           FCPUName := 'K6-II';
           FCodename := 'Chomper';
           FTech := '0.25 µm';
           if FStepping = 0 then
             FRevision := 'A';
         end;
         9: begin
           FCPUName := 'K6-III';
           FCodename := 'Sharptooth';
           FTech := '0.25 µm';
           if FStepping = 0 then
             FRevision := 'A';
         end;
         13: FCPUName := 'K6-II+/K6-III+';
    end;
    6: case FModel of
         0: begin
           FCPUName := 'Athlon';
           FCodename := 'Argon';
           FTech := '0.25 µm';
         end;
         1: begin
           FCPUName := 'Athlon';
           FCodename := 'Argon';
           FTech := '0.25 µm';
           case FStepping of
             1 : FRevision := 'C1';
             2 : FRevision := 'C2';
           end;
         end;
         2: begin
           FCPUName := 'Athlon';
           FCodename := 'Pluto/Orion';
           FTech := '0.18 µm';
           case FStepping of
             1 : FRevision := 'A1';
             2 : FRevision := 'A2';
           end;
         end;
         3: begin
           FCPUName := 'Duron';
           FCodename := 'Spitfire';
           FTech := '0.18 µm';
           case FStepping of
             0 : FRevision := 'A0';
             1 : FRevision := 'A1,A2';
           end;
         end;
         4: begin
           FCPUName := 'Athlon';
           FCodename := 'Thunderbird';
           FTech := '0.18 µm';
           case FStepping of
             2 : FRevision := 'A4,A5,A6,A7';
             4 : FRevision := 'A9';
           end;
         end;
         6: begin
           FCPUName := 'Athlon XP';
           FCodename := 'Palomino/Corvette';
           FTech := '0.18 µm';
           case FStepping of
             0 : FRevision := 'A0';
             1 : FRevision := 'A2';
             2 : FRevision := 'A5';
           end;
         end;
         7: begin
           FCPUName := 'Duron';
           FCodename := 'Morgan/Camaro';
           FTech := '0.18 µm';
           case FStepping of
             0 : FRevision := 'A0';
             1 : FRevision := 'A1';
           end;
         end;
         8: begin
           if FCPUCache.Level2.Size >= 256 then
           begin
             if FCPUFeatures.Extended.FeaturesByName['MP'].Value then
               FCPUName := 'Sempron'
             else
               FCPUName := 'Athlon XP';
           end else
             FCPUName := 'Duron';
           FCodename := 'Thoroughbred';
           FTech := '0.13 µm';
           case FStepping of
             0 : FRevision := 'A0';
             1 : FRevision := 'B0';
           end;
         end;
         9: begin
           FCPUName := 'Athlon';
           FCodename := 'Appaloosa';
           FTech := '0.13 µm';
         end;
         10: begin
           FCPUName := 'Sempron';
           FTech := '0.13 µm';
           if FCPUFeatures.Extended.FeaturesByName['MP'].Value then
             FCodename := 'Sempron'
           else
             if FCPUCache.Level2.Size = 512 then
               FCodename := 'Athlon'
             else
               FCodename := 'Athlon XP';
           FRevision := 'A2';
           if FCPUCache.Level2.Size = 64 then
             FCodename := 'Applebred'
           else
             if FCPUCache.Level2.Size = 256 then
               FCodename := 'Geode'
             else
               FCodename := 'Barton';
         end;
    end;
    15: begin
      case FModel of
         3: begin
              FCPUName := 'Athlon 64';
              FCodename := 'Toledo';
              FTech := '90 nm';
         end;
         4: begin
              FCPUName := 'Athlon 64';
              FCodename := 'Clawhammer';
              FTech := '0.13 µm';
              case FBrand shr 5 of
                1: if FCPUCache.Level2.Size = 512 then
                     FCodename := 'Newcastle'
                   else
                     FCodename := 'Hammer';
                9: FCPUName := 'Athlon 64 FX';
              end;
              if (FModel = 4) and (FStepping = 8) then
                FRevision := 'SH7-C0';
         end;
         5: begin
              FCPUName := 'Opteron';
              FCodename := 'Sledgehammer';
              FTech := '0.13 µm';
              case FBrand shr 5 of
                3 : FRevision := Format(' UP1-%d', [38+2*(Swap(FBrand shl 3) shr 11)]);
                4 : FRevision := Format(' DP2-%d', [38+2*(Swap(FBrand shl 3) shr 11)]);
                5 : FRevision := Format(' MP8-%d', [38+2*(Swap(FBrand shl 3) shr 11)]);
              end;
              case FStepping of
                1 : FRevision := 'SH7-B3';
                8 : FRevision := 'SH7-C0';
              end;
         end;
         6: begin
           FCPUName := '';
           FCodename := 'Toledo';
           FTech := '90 nm';
         end;
         7: begin
           FCPUName := '';
           FCodename := 'San Diego';
           FTech := '90 nm';
         end;
         8
         : begin
           FCPUName := '';
           FCodename := 'Paris';
           FTech := '130 nm';
           if Hi(FSI.wProcessorRevision) = $48 then
           begin
             FCodename := 'Taylor';
             FTech := '90 nm';
           end;
         end;
         9: begin
           FCPUName := '';
           FCodename := 'K9';
           FTech := '90 nm';
         end;
         10: begin
           FCPUName := '';
           FCodename := 'Victoria';
           FTech := '90 nm';
         end;
         11: begin
           FCPUName := '';
           case FModelEx of
             11  : FCodename := 'Windsor';
             $4B : FCodename := 'Windsor';
           end;
           FTech := '90 nm';
         end;
         12: begin
           FCPUName := '';
           FCodename := 'Victoria';
           FTech := '90 nm';
         end;
         17: begin
           FCPUName := '';
           case FModelEx of
             $1F : FCodename := 'Winchester';
             $2F : FCodename := 'Venice';
           end;
           FTech := '90 nm';
         end;
       end;
       {if (FCPP > 1) and (FCPUName <> '') then
         FCPUName := FCPUName+' X2';}
       if (Pos('64',FCPUName) = 0) and (FArch = 9{x64 (AMD or Intel)}) then
         FCPUName := FCPUName+' 64';
    end;
  end;
end;

procedure TProcessor_Database.CyrixLookupName;
begin
  case FFamily of
    0: case FStepping of
         5: begin
           FCPUName := 'Cx486S/D';
           FCodeName := 'M5';
         end;
         6: begin
           FCPUName := 'Cx486DX';
           FCodeName := 'M6';
         end;
         7: begin
           FCPUName := 'Cx486DX2';
           FCodeName := 'M7';
         end;
         8: begin
           FCPUName := 'Cx486DX4';
           FCodeName := 'M8';
         end;
    end;
    4: case FModel of
         1: begin
           FCPUName := 'Cx486SLC';
           FRevision := 'A';
         end;
         2: begin
           FCPUName := 'Cx5x86';
           if FStepping in [9, 11, 13, 15] then
             FRevision := '0,rev1';
         end;
         4: begin
           FCPUName := 'MediaGX';
           FRevision := 'GX,GXm';
         end;
         9: begin
           FCPUName := 'Cx5x86';
           FRevision := '0,rev2+';
           FTech := '0.65 µm';
         end;
       end;
    5: case FModel of
         2 :begin
           FCPUName := '6x86';
           FCodename := 'M1';
           FTech := '0.65 µm';
         end;
         3 :begin
           FCPUName := '6x86L';
           FCodename := 'M1L';
           FTech := '0.35 µm';
         end;
       end;
    6: case FModel of
         0: if FFreq < 225 then
            begin
              FCPUName := '6x86MX';
              FCodeName := 'M2';
              FTech := '0.35 µm';
            end else
            begin
              FCPUName := 'M-II';
              FCodename := 'M2';
              FTech := '0.35 µm';
            end;
         5: begin
           FCPUName := 'VIA Cyrix III';
           FCodename := 'Joshua';
         end;
         6: begin
           FCPUName := 'VIA Cyrix 3';
           FCodename := 'Samuel I';
           if FStepping = 5 then
             FCodename := 'Samuel II';
         end;
         7: begin
           FCPUName := 'VIA Cyrix 3';
           FCodename := 'Ezra';
         end;
       end;
  end;
end;

procedure TProcessor_Database.IDTLookupName;
begin
  case FFamily of
    5: case FModel of
         4: begin
           FCPUName := 'WinChip';
           FCodename := 'C6';
           FTech := '0.35 µm';
         end;
         8: begin
           FCPUName := 'WinChip 2';
           FCodename := 'C6-2';
           FTech := '0.35-0.25 µm';
           case FStepping of
             1,5    : FRevision := 'WC2';
             7..9   : FRevision := 'WC2A';
             10..15 : FRevision := 'WC2B';
           end;
         end;
         9: begin
           FCPUName := 'WinChip 3';
           FTech := '0.25 µm';
         end;
       end;
    6: case FModel of
         6: begin
           FCPUName := 'VIA C3 C5A';
           FCodename := 'Samuel 1';
           FTech := '0.18 µm';
         end;
         7: if FStepping < 8 then
            begin
              FCPUName := 'VIA C3 C5B';
              FCodename := 'Samuel 2';
              FTech := '0.13 µm';
            end else
            begin
              FCPUName := 'VIA C3 C5C';
              FCodename := 'Ezra';
              FTech := '0.13µm';
            end;
         8: begin
           FCPUName := 'VIA C3 C5N';
           FCodename := 'Ezra-T';
           FTech := '0.13 µm';
         end;
         9: if FStepping < 8 then
            begin
              FCPUName := 'VIA C3 C5XL';
              FCodename := 'Nehemiah';
              FTech := '0.13 µm';
            end else
            begin
              FCPUName := 'VIA C3 C5P';
              FCodename := 'Nehemiah';
              FTech := '0.13 µm';
            end;
       end;
  end;
end;

procedure TProcessor_Database.NexGenLookupName;
begin
  case FFamily of
    5: case FModel of
         0: begin
           FCPUName := 'Nx586';
           FTech := '0.50-0.44 µm';
         end;
         6: begin
           FCPUName := 'Nx686';
           FCodename := 'HA';
           FTech := '0,50 µm';
         end;
       end;
  end;
end;

procedure TProcessor_Database.UMCLookupName;
begin
  case FFamily of
    4: case FModel of
         1 : FCPUName := 'U5SD';
         2 : FCPUName := 'U5S/X';
         3 : FCPUName := 'U486DX2';
         5 : FCPUName := 'U486SX2';
        end;
  end;
end;

procedure TProcessor_Database.RiseLookupName;
begin
  case FFamily of
    5: case FModel of
         0: begin
           FCPUName := 'mP6';
           FCodename := 'iDragon';
         end;
         2: begin
           FCPUName := 'mP6';
           FCodename := 'iDragon';
           FTech := '0.18 µm';
         end;
         8: begin
           FCPUName := 'mP6';
           FCodename := 'iDragon II';
           FTech := '0.25 µm';
         end;
         9: begin
           FCPUName := 'mP6';
           FCodename := 'iDragon II';
           FTech := '0.18 µm';
         end;
       end;
  end;
end;

procedure TProcessor_Database.SiSLookupName;
begin
  case FFamily of
    5: case FModel of
      0: FCPUName := '55x';
    end;
  end;
end;

procedure TProcessor_Database.GeodeLookupName;
begin
  FCPUName := 'Geode';
end;

procedure TProcessor_Database.TransmetaLookupName;
begin
  case FFamily of
    5: begin
      FCPUName := 'Crusoe';
      if FCPUCache.Level2.Size = 0 then
        FCodename := 'TM3200'
      else
        if FCPUCache.Level2.Size = 256 then
          FCodename := 'TM5400/TM5500'
        else
          FCodename := 'TM5600/TM5800';
    end;
    6: begin
      FCPUName := 'Efficeon';
      if FCPUCache.Level2.Size = 256 then
        FCodename := 'Astro,TM8300/TM8500'
      else
        FCodename := 'Astro,TM8600/TM8800';
    end;
  end;
end;

end.
