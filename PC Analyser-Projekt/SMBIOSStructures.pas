unit SMBIOSStructures;

interface

uses
  System.SysUtils, SMBIOSClass;

const SMB_BIOSINFO              = 0;   // BIOS Information
      SMB_SYSINFO               = 1;   // System Information
      SMB_BASEINFO              = 2;   // Base Board Information
      SMB_SYSENC                = 3;   // System Enclosure or Chassis
      SMB_CPU                   = 4;   // Processor Information
      SMB_MEMCTRL               = 5;   // Memory Controller Information
      SMB_MEMMOD                = 6;   // Memory Module Information
      SMB_CACHE                 = 7;   // Cache Information
      SMB_PORTCON               = 8;   // Port Connector Information
      SMB_SLOTS                 = 9;   // System Slots
      SMB_ONBOARD               = 10;  // On Board Devices Information
      SMB_OEMSTR                = 11;  // OEM Strings
      SMB_SYSCFG                = 12;  // System Configuration Options
      SMB_LANG                  = 13;  // BIOS Language Information
      SMB_GRP                   = 14;  // Group Associations
      SMB_EVENT                 = 15;  // System Event Log
      SMB_PHYSMEM               = 16;  // Physical Memory Array
      SMB_MEMDEV                = 17;  // Memory Device
      SMB_MEMERR32              = 18;  // 32-bit Memory Error Information
      SMB_MEMMAP                = 19;  // Memory Array Mapped Address
      SMB_MEMDEVMAP             = 20;  // Memory Device Mapped Address
      SMB_POINTER               = 21;  // Built-in Pointing Device
      SMB_BATTERY               = 22;  // Portable Battery
      SMB_RESET                 = 23;  // System Reset
      SMB_SECURITY              = 24;  // Hardware Security
      SMB_POWER                 = 25;  // System Power Controls
      SMB_VOLTAGE               = 26;  // Voltage Probe
      SMB_COOL                  = 27;  // Cooling Device
      SMB_TEMP                  = 28;  // Tempature Probe
      SMB_CURRENT               = 29;  // Electrical Current Probe
      SMB_OOBREM                = 30;  // Out-of-Band Remote Access
      SMB_BIS                   = 31;  // Boot Integrity Services (BIS) Entry Point
      SMB_SYSBOOT               = 32;  // System Boot Information
      SMB_MEMERR64              = 33;  // 64-bit Memory Error Information
      SMB_MGT                   = 34;  // Management Device
      SMB_MGTCMP                = 35;  // Management Device Component
      SMB_MGTTHR                = 36;  // Management Device Threshold Data
      SMB_MEMCHAN               = 37;  // Memory Channel
      SMB_IPMI                  = 38;  // IPMI Device Information
      SMB_SPS                   = 39;  // System Power Supply
      SMB_ADD                   = 40;  // Additional  Information
      SMB_ONBOARDX              = 41;  // On Board Devices Extended Information
      SMB_MGMTCTRL              = 42;  // Management Controller Host Interface
      SMB_TPMDEV                = 43;  // TPM Devices
      SMB_PAI                   = 44;  // Processor Additional Information
      SMB_FIRM                  = 45;  // Firmware Inventory Information
      SMB_STRP                  = 46;  // String Property

      SMB_INACTIVE              = 126; // Inactive
      SMB_EOT                   = 127; // End-of-Table

      SMB_OEM_BEGIN             = 128;
      SMB_OEM_END               = 255;

  SMB_TableTypes : Array[0..48] of
  record
    &Type : Byte;
    Name : String
  end = (
    (&Type : SMB_BIOSINFO;  Name : 'BIOS-Information'),
    (&Type : SMB_SYSINFO;   Name : 'System-Information'),
    (&Type : SMB_BASEINFO;  Name : 'Hauptplatine'),
    (&Type : SMB_SYSENC;    Name : 'Gehäuse'),
    (&Type : SMB_CPU;       Name : 'Prozessor'),
    (&Type : SMB_MEMCTRL;   Name : 'Speicherkontroller'),
    (&Type : SMB_MEMMOD;    Name : 'Speichermodul'),
    (&Type : SMB_CACHE;     Name : 'Cache'),
    (&Type : SMB_PORTCON;   Name : 'Anschluss'),
    (&Type : SMB_SLOTS;     Name : 'Steckplatz'),
    (&Type : SMB_ONBOARD;   Name : 'On-Board-Gerät'),
    (&Type : SMB_OEMSTR;    Name : 'OEM-Zeichenketten'),
    (&Type : SMB_SYSCFG;    Name : 'System-Konfigurationsoptionen'),
    (&Type : SMB_LANG;      Name : 'BIOS-Sprache'),
    (&Type : SMB_GRP;       Name : 'Gruppenzugehörigkeiten'),
    (&Type : SMB_EVENT;     Name : 'System-Ereignislog'),
    (&Type : SMB_PHYSMEM;   Name : 'Physikalisches Speicherfeld'),
    (&Type : SMB_MEMDEV;    Name : 'Speichergerät'),
    (&Type : SMB_MEMERR32;  Name : '32 Bit Speicher-Fehler-Informationen'),
    (&Type : SMB_MEMMAP;    Name : 'Gemappte Speicherfeldadresse'),
    (&Type : SMB_MEMDEVMAP; Name : 'Gemappte Speichergerätadresse'),
    (&Type : SMB_POINTER;   Name : 'Eingebautes Zeigegerät'),
    (&Type : SMB_BATTERY;   Name : 'Tragbare Batterie'),
    (&Type : SMB_RESET;     Name : 'System-Reset'),
    (&Type : SMB_SECURITY;  Name : 'Hardware-Sicherheit'),
    (&Type : SMB_POWER;     Name : 'System-Stromkontrolle'),
    (&Type : SMB_VOLTAGE;   Name : 'Spannungssensor'),
    (&Type : SMB_COOL;      Name : 'Lüftersensor'),
    (&Type : SMB_TEMP;      Name : 'Temperatursensor'),
    (&Type : SMB_CURRENT;   Name : 'Stromstärkesensor'),
    (&Type : SMB_OOBREM;    Name : 'Fernzugriff ohne Betriebssystem'),
    (&Type : SMB_BIS;       Name : 'Einsprungspunkt für Boot-Integritätsdienste'),
    (&Type : SMB_SYSBOOT;   Name : 'Systemstart-Information'),
    (&Type : SMB_MEMERR64;  Name : '64 Bit Speicher-Fehler-Informationen'),
    (&Type : SMB_MGT;       Name : 'Verwaltungsgerät'),
    (&Type : SMB_MGTCMP;    Name : 'Verwaltungsgerät-Komponente'),
    (&Type : SMB_MGTTHR;    Name : 'Verwaltungsgerät-Schwellwertdaten'),
    (&Type : SMB_MEMCHAN;   Name : 'Speicherkanal'),
    (&Type : SMB_IPMI;      Name : 'IPMI-Gerät-Informationen'),
    (&Type : SMB_SPS;       Name : 'System-Stromversorgung'),
    (&Type : SMB_ADD;       Name : 'Zusätzliche Informationen'),
    (&Type : SMB_ONBOARDX;  Name : 'Erweitertes On-Board-Gerät'),
    (&Type : SMB_MGMTCTRL;  Name : 'Verwaltungskontroller Host-Schnittstelle'),
    (&Type : SMB_TPMDEV;    Name : 'TPM-Gerät'),
    (&Type : SMB_PAI;       Name : 'Zusätzliche Prozessor-Informationen'),
    (&Type : SMB_FIRM;      Name : 'Firmware-Inventur-Informationen'),
    (&Type : SMB_STRP;      Name : 'Zeichenketten-Eigenschaft für andere Strukturen'),
    (&Type : SMB_INACTIVE;  Name : 'Inaktiv'),
    (&Type : SMB_EOT;       Name : 'Tabellenende')
    );

type
  TSMBIOS_Structures = class helper for TSMBIOS
    type
      TSMBIOS_BIOS = packed record //Table Type 0
        Header                                 : TSMBIOSTableHeader;
        VendorStr                              : Byte;
        BIOSVersionStr                         : Byte;
        BIOSStartingAddressSegment             : Word;
        BIOSReleaseDateStr                     : Byte;
        BIOSROMSize                            : Byte;
        BIOSCharacteristics                    : UInt64;
        BIOSCharacteristicsExtensionBytes      : Array [0..1] of Byte;
        SystemBIOSMajorRelease                 : Byte;
        SystemBIOSMinorRelease                 : Byte;
        EmbeddedControllerFirmwareMajorRelease : Byte;
        EmbeddedControllerFirmwareMinorRelease : Byte;
        ExtendedBIOSROMSize                    : Word;
      end;
      PSMBIOS_BIOS = ^TSMBIOS_BIOS;

      TSMBIOS_System = packed record //Table Type 1
        Header          : TSMBIOSTableHeader;
        ManufacturerStr : Byte;
        ProductNameStr  : Byte;
        VersionStr      : Byte;
        SerialNumberStr : Byte;
        UUID            : Array [0..15] of Byte;
        WakeUpType      : Byte;
        SKUNumberStr    : Byte;
        FamilyStr       : Byte;
      end;
      PSMBIOS_System = ^TSMBIOS_System;

      TSMBIOS_Baseboard = packed record //Table Type 2
        Header                         : TSMBIOSTableHeader;
        ManufacturerStr                : Byte;
        ProductStr                     : Byte;
        VersionStr                     : Byte;
        SerialNumberStr                : Byte;
        AssetTagStr                    : Byte;
        FeatureFlags                   : Byte;
        LocationInChassisStr           : Byte;
        ChassisHandle                  : Word;
        BoardType                      : Byte;
        NumberOfContainedObjectHandles : Byte;
      end;
      PSMBIOS_Baseboard = ^TSMBIOS_Baseboard;

      TSMBIOS_ContainedElements = packed record //Extension for Table Type 3
        ContainedElementType : Byte;
        ContainedElementMinimum : Byte;
        ContainedElementMaximum : Byte;
      end;
      PSMBIOS_ContainedElements = ^TSMBIOS_ContainedElements;

      TSMBIOS_SystemEnclosure = packed record //Table Type 3
        Header                       : TSMBIOSTableHeader;
        ManufacturerStr              : Byte;
        &Type                        : Byte;
        VersionStr                   : Byte;
        SerialNumberStr              : Byte;
        AssetTagNumberStr            : Byte;
        BootUpState                  : Byte;
        PowerSupplyState             : Byte;
        ThermalState                 : Byte;
        SecurityStatus               : Byte;
        OEMDefined                   : Cardinal;
        Height                       : Byte;
        NumberOfPowerCords           : Byte;
        ContainedElementCount        : Byte;
        ContainedElementRecordLength : Byte;
        SKUNumberStr                 : Byte; //must be calculated manually
      end;
      PSMBIOS_SystemEnclosure = ^TSMBIOS_SystemEnclosure;

      TSMBIOS_Processor = packed record //Table Type 4
       Header                   : TSMBIOSTableHeader;
       SocketDesignationStr     : Byte;
       ProcessorType            : Byte;
       ProcessorFamily          : Byte;
       ProcessorManufacturerStr : Byte;
       ProcessorID              : UInt64;
       ProcessorVersionStr      : Byte;
       Voltage                  : Byte;
       ExternalClock            : Word;
       MaxSpeed                 : Word;
       CurrentSpeed             : Word;
       Status                   : Byte;
       ProcessorUpgrade         : Byte;
       L1CacheHandle            : Word;
       L2CacheHandle            : Word;
       L3CacheHandle            : Word;
       SerialNumberStr          : Byte;
       AssetTagStr              : Byte;
       PartNumberStr            : Byte;
       CoreCount                : Byte;
       CoreEnabled              : Byte;
       ThreadCount              : Byte;
       ProcessorCharacterics    : Word;
       ProcessorFamily2         : Word;
       CoreCount2               : Word;
       CoreEnabled2             : Word;
       ThreadCount2             : Word;
       ThreadEnabled            : Word;
     end;
     PSMBIOS_Processor = ^TSMBIOS_Processor;

     TSMBIOS_Cache = packed record //Table Type 7
       Header               : TSMBIOSTableHeader;
       SocketDesignationStr : Byte;
       CacheConfiguration   : Word;
       MaximumCacheSize     : Word;
       InstalledSize        : Word;
       SupportedSRAMType    : Word;
       CurrentSRAMType      : Word;
       CacheSpeed           : Byte;
       ErrorCorrectionType  : Byte;
       SystemCacheType      : Byte;
       Associativity        : Byte;
       MaximumCacheSize2    : Cardinal;
       InstalledCacheSize2  : Cardinal;
     end;
     PSMBIOS_Cache = ^TSMBIOS_Cache;

     TSMBIOS_PortConnector = packed record //Table Type 8
       Header                         : TSMBIOSTableHeader;
       InternalReferenceDesignatorStr : Byte;
       InternalConnectorType          : Byte;
       ExternalReferenceDesignatorStr : Byte;
       ExternalConnectorType          : Byte;
       PortType                       : Byte;
     end;
     PSMBIOS_PortConnector = ^TSMBIOS_PortConnector;

     TPeerGroup = packed record //Helper for Table Type 9
       SegmentGroupNumber   : Word;
       BusNumber            : Byte;
       DeviceFunctionNumber : Byte;
       DataBusWidth         : Byte;
     end;

     TSMBIOS_SystemSlots = packed record //Table Type 9
       Header               : TSMBIOSTableHeader;
       SlotDesignationStr   : Byte;
       SlotType             : Byte;
       SlotDataBusWidth     : Byte;
       CurrentUsage         : Byte;
       SlotLength           : Byte;
       SlotID               : Word;
       SlotCharacteristics1 : Byte;
       SlotCharacteristics2 : Byte;
       SegmentGroupNumber   : Word;
       BusNumber            : Byte;
       DeviceFunctionNumber : Byte;
       DataBusWidth         : Byte;
       PeerGroupingCount    : Byte;
       SlotInformation      : Byte; //must be calculated manually
       SlotPhysicalWidth    : Byte; //must be calculated manually
       SlotPitch            : Word; //must be calculated manually
       SlotHeight           : Byte; //must be calculated manually
     end;
     PSMBIOS_SystemSlots = ^TSMBIOS_SystemSlots;

     TSMBIOS_PhysicalMemoryArray = packed record //Table Type 16
       Header                       : TSMBIOSTableHeader;
       Location                     : Byte;
       Use                          : Byte;
       MemoryErrorCorrection        : Byte;
       MaximumCapacity              : Cardinal;
       MemoryErrorInformationHandle : Word;
       NumberOfMemoryDevices        : Word;
       ExtendedMaximumCapacity      : UInt64;
     end;
     PSMBIOS_PhysicalMemoryArray = ^TSMBIOS_PhysicalMemoryArray;

     TSMBIOS_MemoryDevice = packed record //Table Type 17
       Header                                  : TSMBIOSTableHeader;
       PhysicalMemoryArrayHandle               : Word;
       MemoryErrorInformationHandle            : Word;
       TotalWidth                              : Word;
       DataWidth                               : Word;
       Size                                    : Word;
       FormFactor                              : Byte;
       DeviceSet                               : Byte;
       DeviceLocatorStr                        : Byte;
       BankLocatorStr                          : Byte;
       MemoryType                              : Byte;
       TypeDetail                              : Word;
       Speed                                   : Word;
       ManufacturerStr                         : Byte;
       SerialNumberStr                         : Byte;
       AssetTagStr                             : Byte;
       PartNumberStr                           : Byte;
       Attributes                              : Byte;
       ExtendedSize                            : Cardinal;
       ConfiguredMemorySpeed                   : Word;
       MinimumVoltage                          : Word;
       MaximumVoltage                          : Word;
       ConfiguredVoltage                       : Word;
       MemoryTechnology                        : Byte;
       MemoryOperatingModeCapability           : Word;
       FirmwareVersionStr                      : Byte;
       ModuleManufacturerID                    : Word;
       ModuleProductID                         : Word;
       MemorySubsystemControllerManufacturerID : Word;
       MemorySubsystemControllerProductID      : Word;
       NonVolatileSize                         : UInt64;
       VolatileSize                            : UInt64;
       CacheSize                               : UInt64;
       LogicalSize                             : UInt64;
       ExtendedSpeed                           : Cardinal;
       ExtendedConfiguredMemorySpeed           : Cardinal;
     end;
     PSMBIOS_MemoryDevice = ^TSMBIOS_MemoryDevice;

     TSMBIOS_VoltageProbe = packed record //Table Type 26
       Header            : TSMBIOSTableHeader;
       DescriptionStr    : Byte;
       LocationAndStatus : Byte;
       MaximumValue      : Word;
       MinimumValue      : Word;
       Resolution        : Word;
       Tolerance         : Word;
       Accuracy          : Word;
       OEMDefined        : Cardinal;
       NominalValue      : Word;
     end;
     PSMBIOS_VoltageProbe = ^TSMBIOS_VoltageProbe;

     TSMBIOS_CoolingDevice = packed record //Table Type 27
       Header                 : TSMBIOSTableHeader;
       TemperatureProbeHandle : Word;
       DeviceTypeAndStatus    : Byte;
       CoolingUnitGroup       : Byte;
       OEMDefined             : Cardinal;
       NominalSpeed           : Word;
       DescriptionStr         : Byte;
     end;
     PSMBIOS_CoolingDevice = ^TSMBIOS_CoolingDevice;

     TSMBIOS_TemperatureProbe = packed record //Table Type 28
       Header            : TSMBIOSTableHeader;
       DescriptionStr    : Byte;
       LocationAndStatus : Byte;
       MaximumValue      : Word;
       MinimumValue      : Word;
       Resolution        : Word;
       Tolerance         : Word;
       Accuracy          : Word;
       OEMDefined        : Cardinal;
       NominalValue      : Word;
     end;
     PSMBIOS_TemperatureProbe = ^TSMBIOS_TemperatureProbe;

     TSMBIOS_ElectricalCurrentProbe = packed record //Table Type 29
       Header            : TSMBIOSTableHeader;
       DescriptionStr    : Byte;
       LocationAndStatus : Byte;
       MaximumValue      : Word;
       MinimumValue      : Word;
       Resolution        : Word;
       Tolerance         : Word;
       Accuracy          : Word;
       OEMDefined        : Cardinal;
       NominalValue      : Word;
     end;
     PSMBIOS_ElectricalCurrentProbe = ^TSMBIOS_ElectricalCurrentProbe;

     TSMBIOS_TPMDevice = packed record //Table Type 43
       Header           : TSMBIOSTableHeader;
       VendorID         : Array [1..4] of Byte;
       MajorSpecVersion : Byte;
       MinorSpecVersion : Byte;
       FirmwareVersion1 : Cardinal;
       FirmwareVersion2 : Cardinal;
       DescriptionStr   : Byte;
       Characteristics  : UInt64;
       OEMDefined       : Cardinal;
     end;
     PSMBIOS_TPMDevice = ^TSMBIOS_TPMDevice;

     function GetSMBIOS001_WakeUpType(AValue : Byte) : String;
     function GetSMBIOS002_BoardType(AValue : Byte) : String;
     function GetSMBIOS003_ChassisType(AValue : Byte) : String;
     function GetSMBIOS003_State(AValue : Byte) : String;
     function GetSMBIOS003_SecurityStatus(AValue : Byte) : String;
     function GetSMBIOS004_ProcessorType(AValue : Byte) : String;
     function GetSMBIOS004_ProcessorFamily(AValue : Byte) : String;
     function GetSMBIOS004_CPUStatus(AValue : Byte) : String;
     function GetSMBIOS004_ProcessorUpgrade(AValue : Byte) : String;
     function GetSMBIOS004_ProcessorFamily2(AValue : Word) : String;
     function GetSMBIOS007_CacheSRAMType(AValue : Word) : String;
     function GetSMBIOS007_ErrorCorrectionType(AValue : Byte) : String;
     function GetSMBIOS007_SystemCacheType(AValue : Byte) : String;
     function GetSMBIOS007_Associativity(AValue : Byte) : String;
     function GetSMBIOS008_ConnectorType(AValue : Byte) : String;
     function GetSMBIOS008_PortType(AValue : Byte) : String;
     function GetSMBIOS009_SlotType(AValue : Byte) : String;
     function GetSMBIOS009_SlotDataBusWidth(AValue : Byte) : String;
     function GetSMBIOS016_Location(AValue : Byte) : String;
     function GetSMBIOS016_Use(AValue : Byte) : String;
     function GetSMBIOS016_ErrorCorrectionTypes(AValue : Byte) : String;
     function GetSMBIOS017_FormFactor(AValue : Byte) : String;
     function GetSMBIOS017_MemoryType(AValue : Byte) : String;
     function GetSMBIOS017_TypeDetail(AValue : Word) : String;
     function GetSMBIOS017_MemoryTechnology(AValue : Byte) : String;
     function GetSMBIOS017_MemoryOperatingModeCapability(AValue : Word) : String;
     function GetSMBIOS026_Location(AValue : Byte) : String;
     function GetSMBIOS026_Status(AValue : Byte) : String;
     function GetSMBIOS027_DeviceType(AValue : Byte) : String;
     function GetSMBIOS027_Status(AValue : Byte) : String;
     function GetSMBIOS028_Location(AValue : Byte) : String;
     function GetSMBIOS028_Status(AValue : Byte) : String;
     function GetSMBIOS029_Location(AValue : Byte) : String;
     function GetSMBIOS029_Status(AValue : Byte) : String;
  end;

implementation

function TSMBIOS_Structures.GetSMBIOS001_WakeUpType(AValue : Byte) : String;
begin
  case AValue of
    $00 : Result := 'reserviert';
    $01 : Result := 'anderer';
    $02 : Result := 'unbekannt';
    $03 : Result := 'APM-Zeitgeber';
    $04 : Result := 'Modem Ring';
    $05 : Result := 'LAN Fernzugriff';
    $06 : Result := 'Stromschalter';
    $07 : Result := 'PCI PME#';
    $08 : Result := 'Strom wiederhergestellt';
    else  Result := 'unbekannter Typ (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS002_BoardType(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result:='unbekannt';
    $02 : Result:='anderer';
    $03 : Result:='Server Blade';
    $04 : Result:='Connectivity Switch';
    $05 : Result:='Systemverwaltungsmodul';
    $06 : Result:='Prozessormodul';
    $07 : Result:='I/O-Modul';
    $08 : Result:='Speichermodul';
    $09 : Result:='Tochterplatine';
    $0A : Result:='Hauptplatine';
    $0B : Result:='Prozessor / Speichermodul';
    $0C : Result:='Prozessor / I/O-Modul';
    $0D : Result:='Interconnectplatine';
    else  Result:='unbekannter Typ (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS003_ChassisType(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'anderer';
    $02 : Result := 'unbekannt';
    $03 : Result := 'Desktop';
    $04 : Result := 'Desktop (Niedrigprofil)';
    $05 : Result := 'Pizza Box';
    $06 : Result := 'Mini-Turm';
    $07 : Result := 'Turm';
    $08 : Result := 'Tragbar';
    $09 : Result := 'Laptop';
    $0A : Result := 'Notebook';
    $0B : Result := 'Hand Held';
    $0C : Result := 'Docking Station';
    $0D : Result := 'All in One';
    $0E : Result := 'Sub Notebook';
    $0F : Result := 'Platzsparend';
    $10 : Result := 'Lunch Box';
    $11 : Result := 'Hauptserver-Chassis';
    $12 : Result := 'Erweiterungs-Chassis';
    $13 : Result := 'Unter-Chassis';
    $14 : Result := 'Buserweiterungs-Chassis';
    $15 : Result := 'Peripheral-Chassis';
    $16 : Result := 'RAID-Chassis';
    $17 : Result := 'Rack Mount-Chassis';
    $18 : Result := 'Versiegelter PC';
    $19 : Result := 'Multi-System-Chassis';
    $1A : Result := 'Kompakt-PCI';
    $1B : Result := 'Erweiterter TCA';
    $1C : Result := 'Blade';
    $1D : Result := 'Blade-Gehäuse';
    $1E : Result := 'Tablet';
    $1F : Result := 'Umwandelbar';
    $20 : Result := 'Abnehmbar';
    $21 : Result := 'IoT Gateway';
    $22 : Result := 'Embedded PC';
    $23 : Result := 'Mini PC';
    $24 : Result := 'Stick PC';
    else  Result := 'unbekannter Typ ('+IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS003_State(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'anderer';
    $02 : Result := 'unbekannt';
    $03 : Result := 'sicher';
    $04 : Result := 'Warnung';
    $05 : Result := 'kritisch';
    $06 : Result := 'nicht wiederherstellbar';
    else  Result := 'unbekannter Status (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS003_SecurityStatus(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'anderer';
    $02 : Result := 'unbekannt';
    $03 : Result := 'keiner';
    $04 : Result := 'externe Schnittstelle ausgeschlossen';
    $05 : Result := 'externe Schnittstelle aktiv';
    else  Result := 'unbekannter Status (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS004_ProcessorType(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'anderer';
    $02 : Result := 'unbekannt';
    $03 : Result := 'Hauptprozessor';
    $04 : Result := 'Mathematischer Prozessor';
    $05 : Result := 'DSP-Prozessor';
    $06 : Result := 'Video-Prozessor';
    else  Result := 'unbekannter Typ (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS004_ProcessorFamily(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'andere';
    $02 : Result := 'unbekannt';
    $03 : Result := '8086';
    $04 : Result := '80286';
    $05 : Result := 'Intel 386';
    $06 : Result := 'Intel 486';
    $07 : Result := '8087';
    $08 : Result := '80287';
    $09 : Result := '80387';
    $0A : Result := '80487';
    $0B : Result := 'Intel Pentium';
    $0C : Result := 'Intel Pentium Pro';
    $0D : Result := 'Intel Pentium II';
    $0E : Result := 'Intel Pentium MMX';
    $0F : Result := 'Intel Celeron';
    $10 : Result := 'Intel Pentium II Xeon';
    $11 : Result := 'Intel Pentium III';
    $12 : Result := 'Cyrix M1';
    $13 : Result := 'Cyrix M2';
    $14 : Result := 'Intel Celeron M';
    $15 : Result := 'Intel Pentium 4 HT';
    $18 : Result := 'AMD Duron';
    $19 : Result := 'AMD K5';
    $1A : Result := 'AMD K6';
    $1B : Result := 'AMD K6-2';
    $1C : Result := 'AMD K6-3';
    $1D : Result := 'AMD Athlon';
    $1E : Result := 'AMD 29000';
    $1F : Result := 'AMD K6-2+';
    $20 : Result := 'Power PC';
    $21 : Result := 'Power PC 601';
    $22 : Result := 'Power PC 603';
    $23 : Result := 'Power PC 603+';
    $24 : Result := 'Power PC 604';
    $25 : Result := 'Power PC 620';
    $26 : Result := 'Power PC x704';
    $27 : Result := 'Power PC 750';
    $28 : Result := 'Intel Core Duo';
    $29 : Result := 'Intel Core Duo Mobile';
    $2A : Result := 'Intel Core Solo Mobile';
    $2B : Result := 'Intel Atom';
    $2C : Result := 'Intel Core M';
    $2D : Result := 'Intel Core m3';
    $2E : Result := 'Intel Core m5';
    $2F : Result := 'Intel Core m7';
    $30 : Result := 'Alpha';
    $31 : Result := 'Alpha 21064';
    $32 : Result := 'Alpha 21066';
    $33 : Result := 'Alpha 21164';
    $34 : Result := 'Alpha 21164PC';
    $35 : Result := 'Alpha 21164a';
    $36 : Result := 'Alpha 21264';
    $37 : Result := 'Alpha 21364';
    $38 : Result := 'AMD Turion II Ultra Dual-Core Mobile M';
    $39 : Result := 'AMD Turion II Dual-Core Mobile M';
    $3A : Result := 'AMD Athlon II Dual-Core M';
    $3B : Result := 'AMD Opteron 6100';
    $3C : Result := 'AMD Opteron 4100';
    $3D : Result := 'AMD Opteron 6200';
    $3E : Result := 'AMD Opteron 4200';
    $3F : Result := 'AMD FX';
    $40 : Result := 'MIPS';
    $41 : Result := 'MIPS R4000';
    $42 : Result := 'MIPS R4200';
    $43 : Result := 'MIPS R4400';
    $44 : Result := 'MIPS R4600';
    $45 : Result := 'MIPS R10000';
    $46 : Result := 'AMD C';
    $47 : Result := 'AMD E';
    $48 : Result := 'AMD A';
    $49 : Result := 'AMD G';
    $4A : Result := 'AMD Z';
    $4B : Result := 'AMD R';
    $4C : Result := 'AMD Opteron 4300';
    $4D : Result := 'AMD Opteron 6300';
    $4E : Result := 'AMD Opteron 3300';
    $4F : Result := 'AMD FirePro';
    $50 : Result := 'SPARC';
    $51 : Result := 'SuperSPARC';
    $52 : Result := 'microSPARC II';
    $53 : Result := 'microSPARC IIep';
    $54 : Result := 'UltraSPARC';
    $55 : Result := 'UltraSPARC II';
    $56 : Result := 'UltraSPARC Iii';
    $57 : Result := 'UltraSPARC III';
    $58 : Result := 'UltraSPARC IIIi';
    $60 : Result := '68040';
    $61 : Result := '68xxx';
    $62 : Result := '68000';
    $63 : Result := '68010';
    $64 : Result := '68020';
    $65 : Result := '68030';
    $66 : Result := 'AMD Athlon X4 Quad-Core';
    $67 : Result := 'AMD Opteron X1000';
    $68 : Result := 'AMD Opteron X2000 APU';
    $69 : Result := 'AMD Opteron A';
    $6A : Result := 'AMD Opteron X3000 APU';
    $6B : Result := 'AMD Zen';
    $70 : Result := 'Hobbit';
    $78 : Result := 'Crusoe TM5000';
    $79 : Result := 'Crusoe TM3000';
    $7A : Result := 'Efficeon TM8000';
    $80 : Result := 'Weitek';
    $82 : Result := 'Intel Itanium';
    $83 : Result := 'AMD Athlon 64';
    $84 : Result := 'AMD Opteron';
    $85 : Result := 'AMD Sempron';
    $86 : Result := 'AMD Turion 64 Mobile';
    $87 : Result := 'Dual-Core AMD Opteron';
    $88 : Result := 'AMD Athlon 64 X2 Dual-Core';
    $89 : Result := 'AMD Turion 64 X2 Mobile';
    $8A : Result := 'Quad-Core AMD Opteron';
    $8B : Result := 'AMD Opteron (3. Generation)';
    $8C : Result := 'AMD Phenom FX Quad-Core';
    $8D : Result := 'AMD Phenom X4 Quad-Core';
    $8E : Result := 'AMD Phenom X2 Dual-Core';
    $8F : Result := 'AMD Athlon X2 Dual-Core';
    $90 : Result := 'PA-RISC';
    $91 : Result := 'PA-RISC 8500';
    $92 : Result := 'PA-RISC 8000';
    $93 : Result := 'PA-RISC 7300LC';
    $94 : Result := 'PA-RISC 7200';
    $95 : Result := 'PA-RISC 7100LC';
    $96 : Result := 'PA-RISC 7100';
    $A0 : Result := 'V30';
    $A1 : Result := 'Quad-Core Intel Xeon 3200';
    $A2 : Result := 'Dual-Core Intel Xeon 3000';
    $A3 : Result := 'Quad-Core Intel Xeon 5300';
    $A4 : Result := 'Dual-Core Intel Xeon 5100';
    $A5 : Result := 'Dual-Core Intel Xeon 5000';
    $A6 : Result := 'Dual-Core Intel Xeon LV';
    $A7 : Result := 'Dual-Core Intel Xeon ULV';
    $A8 : Result := 'Dual-Core Intel Xeon 7100';
    $A9 : Result := 'Quad-Core Intel Xeon 5400';
    $AA : Result := 'Quad-Core Intel Xeon';
    $AB : Result := 'Dual-Core Intel Xeon 5200';
    $AC : Result := 'Dual-Core Intel Xeon 7200';
    $AD : Result := 'Quad-Core Intel Xeon 7300';
    $AE : Result := 'Quad-Core Intel Xeon 7400';
    $AF : Result := 'Multi-Core Intel Xeon 7400';
    $B0 : Result := 'Intel Pentium III Xeon';
    $B1 : Result := 'Intel Pentium III SpeedStep';
    $B2 : Result := 'Intel Pentium 4';
    $B3 : Result := 'Intel Xeon';
    $B4 : Result := 'AS400';
    $B5 : Result := 'Intel Xeon MP';
    $B6 : Result := 'AMD Athlon XP';
    $B7 : Result := 'AMD Athlon MP';
    $B8 : Result := 'Intel Itanium 2';
    $B9 : Result := 'Intel Pentium M';
    $BA : Result := 'Intel Celeron D';
    $BB : Result := 'Intel Pentium D';
    $BC : Result := 'Intel Pentium Extreme Edition';
    $BD : Result := 'Intel Core Solo';
    $BF : Result := 'Intel Core 2 Duo';
    $C0 : Result := 'Intel Core 2 Solo';
    $C1 : Result := 'Intel Core 2 Extreme';
    $C2 : Result := 'Intel Core 2 Quad';
    $C3 : Result := 'Intel Core 2 Extreme Mobile';
    $C4 : Result := 'Intel Core 2 Duo Mobile';
    $C5 : Result := 'Intel Core 2 Solo Mobile';
    $C6 : Result := 'Intel Core i7';
    $C7 : Result := 'Dual-Core Intel Celeron';
    $C8 : Result := 'IBM390';
    $C9 : Result := 'G4';
    $CA : Result := 'G5';
    $CB : Result := 'ESA/390 G6';
    $CC : Result := 'z/Architektur-Basis';
    $CD : Result := 'Intel Core i5';
    $CE : Result := 'Intel Core i3';
    $D2 : Result := 'VIA C7-M';
    $D3 : Result := 'VIA C7-D';
    $D4 : Result := 'VIA C7';
    $D5 : Result := 'VIA Eden';
    $D6 : Result := 'Multi-Core Intel Xeon';
    $D7 : Result := 'Dual-Core Intel Xeon 3xxx';
    $D8 : Result := 'Quad-Core Intel Xeon 3xxx';
    $D9 : Result := 'VIA Nano';
    $DA : Result := 'Dual-Core Intel Xeon 5xxx';
    $DB : Result := 'Quad-Core Intel Xeon 5xxx';
    $DD : Result := 'Dual-Core Intel Xeon 7xxx';
    $DE : Result := 'Quad-Core Intel Xeon 7xxx';
    $DF : Result := 'Multi-Core Intel Xeon 7xxx';
    $E0 : Result := 'Multi-Core Intel Xeon 3400';
    $E4 : Result := 'AMD Opteron 3000';
    $E5 : Result := 'AMD Sempron II';
    $E6 : Result := 'Embedded AMD Opteron Quad-Core';
    $E7 : Result := 'AMD Phenom Triple-Core';
    $E8 : Result := 'AMD Turion Ultra Dual-Core Mobile';
    $E9 : Result := 'AMD Turion Dual-Core Mobile';
    $EA : Result := 'AMD Athlon Dual-Core';
    $EB : Result := 'AMD Sempron SI';
    $EC : Result := 'AMD Phenom II';
    $ED : Result := 'AMD Athlon II';
    $EE : Result := 'Six-Core AMD Opteron';
    $EF : Result := 'AMD Sempron M';
    $FA : Result := 'Intel i860';
    $FB : Result := 'Intel i960';
    $FE : Result := 'siehe Prozessor Familie 2-Feld';
    else  Result := 'reserviert ( '+ IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS004_CPUStatus(AValue : Byte) : String;
begin
  case AValue of
    $00 : Result := 'unbekannt';
    $01 : Result := 'CPU aktiv';
    $02 : Result := 'CPU inaktiv durch Benutzer im BIOS';
    $03 : Result := 'CPU inaktiv durch BIOS (POST-Fehler)';
    $04 : Result := 'CPU im Leerlauf, wartend auf Aktivierung';
    $05,
    $06 : Result := 'reserviert';
    $07 : Result := 'anderer';
    else  Result := 'unbekannter Status (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS004_ProcessorUpgrade(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'anderes';
    $02 : Result := 'unbekannt';
    $03 : Result := 'Tochterplatine';
    $04 : Result := 'ZIF-Sockel';
    $05 : Result := 'Ersetzbares Piggy Back';
    $06 : Result := 'kein';
    $07 : Result := 'LIF-Sockel';
    $08 : Result := 'Slot 1';
    $09 : Result := 'Slot 2';
    $0A : Result := '370-Pin-Sockel';
    $0B : Result := 'Slot A';
    $0C : Result := 'Slot M';
    $0D : Result := 'Sockel 423';
    $0E : Result := 'Sockel A (Sockel 462)';
    $0F : Result := 'Sockel 478';
    $10 : Result := 'Sockel 754';
    $11 : Result := 'Sockel 940';
    $12 : Result := 'Sockel 939';
    $13 : Result := 'Sockel mPGA604';
    $14 : Result := 'Sockel LGA771';
    $15 : Result := 'Sockel LGA775';
    $16 : Result := 'Sockel S1';
    $17 : Result := 'Sockel AM2';
    $18 : Result := 'Sockel F (1207)';
    $19 : Result := 'Sockel LGA1366';
    $1A : Result := 'Sockel G34';
    $1B : Result := 'Sockel AM3';
    $1C : Result := 'Sockel C32';
    $1D : Result := 'Sockel LGA1156';
    $1E : Result := 'Sockel LGA1567';
    $1F : Result := 'Sockel PGA988A';
    $20 : Result := 'Sockel BGA1288';
    $21 : Result := 'Sockel rPGA988B';
    $22 : Result := 'Sockel BGA1023';
    $23 : Result := 'Sockel BGA1224';
    $24 : Result := 'Sockel BGA1155';
    $25 : Result := 'Sockel LGA1356';
    $26 : Result := 'Sockel LGA2011';
    $27 : Result := 'Sockel FS1';
    $28 : Result := 'Sockel FS2';
    $29 : Result := 'Sockel FM1';
    $2A : Result := 'Sockel FM2';
    $2B : Result := 'Sockel LGA2011-3';
    $2C : Result := 'Sockel LGA1356-3';
    $2D : Result := 'Sockel LGA1150';
    $2E : Result := 'Sockel BGA1168';
    $2F : Result := 'Sockel BGA1234';
    $30 : Result := 'Sockel BGA1364';
    $31 : Result := 'Sockel AM4';
    $32 : Result := 'Sockel LGA1151';
    $33 : Result := 'Sockel BGA1356';
    $34 : Result := 'Sockel BGA1440';
    $35 : Result := 'Sockel BGA1515';
    $36 : Result := 'Sockel LGA3647-1';
    $37 : Result := 'Sockel SP3';
    $38 : Result := 'Sockel SP3r2';
    $39 : Result := 'Sockel LGA2066';
    $3A : Result := 'Sockel BGA1392';
    $3B : Result := 'Sockel BGA1510';
    $3C : Result := 'Sockel BGA1528';
    $3D : Result := 'Sockel LGA4189';
    $3E : Result := 'Sockel LGA1200';
    $3F : Result := 'Sockel LGA4677';
    $40 : Result := 'Sockel LGA1700';
    $41 : Result := 'Sockel BGA1744';
    $42 : Result := 'Sockel BGA1781';
    $43 : Result := 'Sockel BGA1211';
    $44 : Result := 'Sockel BGA2422';
    $45 : Result := 'Sockel LGA1211';
    $46 : Result := 'Sockel LGA2422';
    $47 : Result := 'Sockel LGA5773';
    $48 : Result := 'Sockel BGA5773';
    else  Result := 'unbekannter Typ (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS004_ProcessorFamily2(AValue : Word) : String;
begin
  if AValue in [00..$FD] then
    Result := GetSMBIOS004_ProcessorFamily(AValue)
  else
  case AValue of
    $100 : Result:='ARMv7';
    $101 : Result:='ARMv8';
    $104 : Result:='SH-3';
    $105 : Result:='SH-4';
    $118 : Result:='ARM';
    $119 : Result:='StrongARM';
    $12C : Result:='6x86';
    $12D : Result:='MediaGX';
    $12E : Result:='MII';
    $140 : Result:='WinChip';
    $15E : Result:='DSP';
    $1F4 : Result:='Video';
    $200 : Result:='RISC-V RV32';
    $201 : Result:='RISC-V RV64';
    $202 : Result:='RISC-V RV128';
    $258 : Result:='LoongArch';
    $259 : Result:='Loongson 1';
    $25A : Result:='Loongson 2';
    $25B : Result:='Loongson 3';
    $25C : Result:='Loongson 2K';
    $25D : Result:='Loongson 3A';
    $25E : Result:='Loongson 3B';
    $25F : Result:='Loongson 3C';
    $260 : Result:='Loongson 3D';
    $261 : Result:='Loongson 3E';
    $262 : Result:='Dual-Core Loongson 2K 2xxx';
    $26C : Result:='Quad-Core Loongson 3A 5xxx';
    $26D : Result:='Multi-Core Loongson 3A 5xxx';
    $26E : Result:='Quad-Core Loongson 3B 5xxx';
    $26F : Result:='Multi-Core Loongson 3B 5xxx';
    $270 : Result:='Multi-Core Loongson 3C 5xxx';
    $271 : Result:='Multi-Core Loongson 3D 5xxx';
    else   Result:='reserviert (' + IntToHex(AValue, 4) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS007_CacheSRAMType(AValue : Word) : String;
var
  ReturnStr : String;
begin
  ReturnStr := '';
  if AValue = 0 then ReturnStr := '---' else
  begin
    if IsBitOn(AValue, 6) then ReturnStr := ReturnStr + 'asynchron, ';
    if IsBitOn(AValue, 5) then ReturnStr := ReturnStr + 'synchron, ';
    if IsBitOn(AValue, 4) then ReturnStr := ReturnStr + 'Pipeline Burst, ';
    if IsBitOn(AValue, 3) then ReturnStr := ReturnStr + 'Burst, ';
    if IsBitOn(AValue, 2) then ReturnStr := ReturnStr + 'kein Burst, ';
    if IsBitOn(AValue, 1) then ReturnStr := ReturnStr + 'unbekannt, ';
    if IsBitOn(AValue, 0) then ReturnStr := ReturnStr + 'anderer, ';

    Delete(ReturnStr, Length(ReturnStr) - 1, 255);
  end;
  Result := ReturnStr;
end;

function TSMBIOS_Structures.GetSMBIOS007_ErrorCorrectionType(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'anderer';
    $02 : Result := 'unbekannt';
    $03 : Result := 'keiner';
    $04 : Result := 'Parität';
    $05 : Result := 'einfaches Bit-ECC';
    $06 : Result := 'multiples Bit-ECC';
    else  Result := 'unbekannter Typ (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS007_SystemCacheType(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'anderer';
    $02 : Result := 'unbekannt';
    $03 : Result := 'Instruktion';
    $04 : Result := 'Daten';
    $05 : Result := 'Instruktion + Daten (Unified)';
    else  Result := 'unbekannter Typ (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS007_Associativity(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'andere';
    $02 : Result := 'unbekannt';
    $03 : Result := 'direkt gemappt';
    $04 : Result := '2-Wege Set-Assoziativ';
    $05 : Result := '4-Wege Set-Assoziativ';
    $06 : Result := 'voll Assoziativ';
    $07 : Result := '8-Wege Set-Assoziativ';
    $08 : Result := '16-Wege Set-Assoziativ';
    $09 : Result := '12-Wege Set-Assoziativ';
    $0A : Result := '24-Wege Set-Assoziativ';
    $0B : Result := '32-Wege Set-Assoziativ';
    $0C : Result := '48-Wege Set-Assoziativ';
    $0D : Result := '64-Wege Set-Assoziativ';
    $0E : Result := '20-Wege Set-Assoziativ';
    else  Result := 'unbekannte Assoziativität (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS008_ConnectorType(AValue : Byte) : String;
begin
  case AValue of
    $00 : Result := 'keiner';
    $01 : Result := 'Centronics';
    $02 : Result := 'Mini Centronics';
    $03 : Result := 'veraltet';
    $04 : Result := 'DB-25 Pin männlich';
    $05 : Result := 'DB-25 Pin weiblich';
    $06 : Result := 'DB-15 Pin männlich';
    $07 : Result := 'DB-15 Pin weiblich';
    $08 : Result := 'DB-9 Pin männlich';
    $09 : Result := 'DB-9 Pin weiblich';
    $0A : Result := 'RJ-11';
    $0B : Result := 'RJ-45';
    $0C : Result := '50 Pin MiniSCSI';
    $0D : Result := 'Mini-DIN';
    $0E : Result := 'Micro-DIN';
    $0F : Result := 'PS/2';
    $10 : Result := 'Infrarot';
    $11 : Result := 'HP-HIL';
    $12 : Result := 'Zugriffsbus (USB)';
    $13 : Result := 'SSA SCSI';
    $14 : Result := 'Zirkulär DIN-8 männlich';
    $15 : Result := 'Zirkulär DIN-8 weiblich';
    $16 : Result := 'OnBoard IDE';
    $17 : Result := 'OnBoard Floppy';
    $18 : Result := '9 Pin doppelt Inline (Pin 10 Schnitt)';
    $19 : Result := '25 Pin doppelt Inline (Pin 26 Schnitt)';
    $1A : Result := '50 Pin doppelt Inline';
    $1B : Result := '68 Pin doppelt Inline';
    $1C : Result := 'OnBoard Soundeingang von CD-ROM';
    $1D : Result := 'Mini-Centronics Typ 14';
    $1E : Result := 'Mini-Centronics Typ 26';
    $1F : Result := 'Mini-Jack (Kopfhörer)';
    $20 : Result := 'BNC';
    $21 : Result := '1394 (Firewire)';
    $22 : Result := 'SAS/SATA Stecker-Steckbuchse';
    $23 : Result := 'USB Typ-C-Steckbuchse';
    $A0 : Result := 'PC-98';
    $A1 : Result := 'PC-98 Hireso';
    $A2 : Result := 'PC-H98';
    $A3 : Result := 'PC-98 Notebook';
    $A4 : Result := 'PC-98 vollständig';
    $FF : Result := 'anderer';
    else  Result := 'unbekannter Typ (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS008_PortType(AValue : Byte) : String;
begin
  case AValue of
    $00 : Result := 'keiner';
    $01 : Result := 'parallele Schnittstelle XT/AT-kompatibel';
    $02 : Result := 'parallele Schnittstelle PS/2';
    $03 : Result := 'parallele Schnittstelle ECP';
    $04 : Result := 'parallele Schnittstelle EPP';
    $05 : Result := 'parallele Schnittstelle ECP/EPP';
    $06 : Result := 'serielle Schnittstelle XT/AT-kompatibel';
    $07 : Result := 'serielle Schnittstelle 16450-kompatibel';
    $08 : Result := 'serielle Schnittstelle 16550-kompatibel';
    $09 : Result := 'serielle Schnittstelle 16550A-kompatibel';
    $0A : Result := 'SCSI-Schnittstelle';
    $0B : Result := 'MIDI-Schnittstelle';
    $0C : Result := 'Joystick-Schnittstelle';
    $0D : Result := 'Tastatur-Schnittstelle';
    $0E : Result := 'Maus-Schnittstelle';
    $0F : Result := 'SSA SCSI';
    $10 : Result := 'USB';
    $11 : Result := 'Firewire (IEEE P1394)';
    $12 : Result := 'PCMCIA Typ I²';
    $13 : Result := 'PCMCIA Typ II';
    $14 : Result := 'PCMCIA Typ III';
    $15 : Result := 'Cardbus';
    $16 : Result := 'Zugriffsbus-Schnittstelle';
    $17 : Result := 'SCSI II';
    $18 : Result := 'SCSI Breit';
    $19 : Result := 'PC-98';
    $1A : Result := 'PC-98 Hireso';
    $1B : Result := 'PC-H98';
    $1C : Result := 'Video-Schnittstelle';
    $1D : Result := 'Audio-Schnittstelle';
    $1E : Result := 'Modem-Schnittstelle';
    $1F : Result := 'Netzwerk-Schnittstelle';
    $20 : Result := 'SATA';
    $21 : Result := 'SAS';
    $22 : Result := 'MFDP (Multifunktions-Bildschirmanschluss)';
    $23 : Result := 'Thunderbolt';
    $A0 : Result := '8251-kompatibel';
    $A1 : Result := '8251 FIFO-kompatibel';
    $FF : Result := 'anderer';
    else  Result := 'unbekannter Typ (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS009_SlotType(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'anderer';
    $02 : Result := 'unbekannt';
    $03 : Result := 'ISA';
    $04 : Result := 'MCA';
    $05 : Result := 'EISA';
    $06 : Result := 'PCI';
    $07 : Result := 'PC Card (PCMCIA)';
    $08 : Result := 'VL-VESA';
    $09 : Result := 'veraltet';
    $0A : Result := 'Prozessor-Kartensteckplatz';
    $0B : Result := 'veralteter Speicherkartensteckplatz';
    $0C : Result := 'E/A Riserkartensteckplatz';
    $0D : Result := 'NuBus';
    $0E : Result := 'PCI (66 MHz fähig)';
    $0F : Result := 'AGP';
    $10 : Result := 'AGP 2X';
    $11 : Result := 'AGP 4X';
    $12 : Result := 'PCI-X';
    $13 : Result := 'AGP 8X';
    $14 : Result := 'M.2 Sockel 1-DP (Mechanischer Schlüssel A)';
    $15 : Result := 'M.2 Sockel 1-SD (Mechanischer Schlüssel E)';
    $16 : Result := 'M.2 Sockel 2 (Mechanischer Schlüssel B)';
    $17 : Result := 'M.2 Sockel 3 (Mechanischer Schlüssel M)';
    $18 : Result := 'MXM Typ I';
    $19 : Result := 'MXM Typ II';
    $1A : Result := 'MXM Typ III (Standard-Verbindung)';
    $1B : Result := 'MXM Typ III (HE-Verbindung)';
    $1C : Result := 'MXM Typ IV';
    $1D : Result := 'MXM 3.0 Typ A';
    $1E : Result := 'MXM 3.0 Typ B';
    $1F : Result := 'PCI Express Gen 2 SFF-8639';
    $20 : Result := 'PCI Express Gen 3 SFF-8639';
    $21 : Result := 'PCI Express Mini 52-pin mit Ausgängen an Unterseite';
    $22 : Result := 'PCI Express Mini 52-pin ohne Ausgängen an Unterseite';
    $23 : Result := 'PCI Express Mini 76-pin';
    $24 : Result := 'PCI Express Gen 4 SFF-8639 (U.2)';
    $25 : Result := 'PCI Express Gen 5 SFF-8639 (U.2)';
    $26 : Result := 'OCP NIC 3.0 Kleiner Formfaktor (SFF)';
    $27 : Result := 'OCP NIC 3.0 Großer Formfaktor (LFF)';
    $28 : Result := 'OCP NIC vor 3.0';
    $30 : Result := 'CXL Flexbus 1.0';
    $A0 : Result := 'PC-98/C20';
    $A1 : Result := 'PC-98/C24';
    $A2 : Result := 'PC-98/E';
    $A3 : Result := 'PC-98/Lokaler Bus';
    $A4 : Result := 'PC-98/Karte';
    $A5 : Result := 'PCI Express';
    $A6 : Result := 'PCI Express x1';
    $A7 : Result := 'PCI Express x2';
    $A8 : Result := 'PCI Express x4';
    $A9 : Result := 'PCI Express x8';
    $AA : Result := 'PCI Express x16';
    $AB : Result := 'PCI Express Gen 2';
    $AC : Result := 'PCI Express Gen 2 x1';
    $AD : Result := 'PCI Express Gen 2 x2';
    $AE : Result := 'PCI Express Gen 2 x4';
    $AF : Result := 'PCI Express Gen 2 x8';
    $B0 : Result := 'PCI Express Gen 2 x16';
    $B1 : Result := 'PCI Express Gen 3';
    $B2 : Result := 'PCI Express Gen 3 x1';
    $B3 : Result := 'PCI Express Gen 3 x2';
    $B4 : Result := 'PCI Express Gen 3 x4';
    $B5 : Result := 'PCI Express Gen 3 x8';
    $B6 : Result := 'PCI Express Gen 3 x16';
    $B8 : Result := 'PCI Express Gen 4';
    $B9 : Result := 'PCI Express Gen 4 x1';
    $BA : Result := 'PCI Express Gen 4 x2';
    $BB : Result := 'PCI Express Gen 4 x4';
    $BC : Result := 'PCI Express Gen 4 x8';
    $BD : Result := 'PCI Express Gen 4 x16';
    $BE : Result := 'PCI Express Gen 5';
    $BF : Result := 'PCI Express Gen 5 x1';
    $C0 : Result := 'PCI Express Gen 5 x2';
    $C1 : Result := 'PCI Express Gen 5 x4';
    $C2 : Result := 'PCI Express Gen 5 x8';
    $C3 : Result := 'PCI Express Gen 5 x16';
    $C4 : Result := 'PCI Express Gen 6 und zukünftig';
    $C5 : Result := 'Enterprise und Datacenter 1U E1 Formfaktor-Steckplatz (EDSFF E1.S, E1.L)';
    $C6 : Result := 'Enterprise und Datacenter 3" E3 Formfaktor-Steckplatz (EDSFF E3.S, E3.L)';
    else  Result := 'unbekannter Typ (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS009_SlotDataBusWidth(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'andere';
    $02 : Result := 'unbekannt';
    $03 : Result := '8 Bit';
    $04 : Result := '16 Bit';
    $05 : Result := '32 Bit';
    $06 : Result := '64 Bit';
    $07 : Result := '128 Bit';
    $08 : Result := '1x oder x1';
    $09 : Result := '2x oder x2';
    $0A : Result := '4x oder x4';
    $0B : Result := '8x oder x8';
    $0C : Result := '12x oder x12';
    $0D : Result := '16x oder x16';
    $0E : Result := '32x oder x32';
    else  Result := 'unbekannter Typ (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS016_Location(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'andere';
    $02 : Result := 'unbekannt';
    $03 : Result := 'Systemplatine oder Hauptplatine';
    $04 : Result := 'ISA-Zusatzkarte';
    $05 : Result := 'EISA-Zusatzkarte';
    $06 : Result := 'PCI-Zusatzkarte';
    $07 : Result := 'MCA-Zusatzkarte';
    $08 : Result := 'PCMCIA-Zusatzkarte';
    $09 : Result := 'veraltete Zusatzkarte';
    $0A : Result := 'NuBus';
    $A0 : Result := 'PC-98/C20-Zusatzkarte';
    $A1 : Result := 'PC-98/C24-Zusatzkarte';
    $A2 : Result := 'PC-98/E-Zusatzkarte';
    $A3 : Result := 'PC-98/Lokalbus-Zusatzkarte';
    $A4 : Result := 'CXL Flexbus 1.0-Zusatzkarte';
    else  Result := 'unbekannte Position (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS016_Use(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'andere';
    $02 : Result := 'unbekannt';
    $03 : Result := 'Systemspeicher';
    $04 : Result := 'Videospeicher';
    $05 : Result := 'Flashspeicher';
    $06 : Result := 'nicht-flüchtiges RAM (NVRAM)';
    $07 : Result := 'Cache-Speicher';
    else  Result := 'unbekannte Benutzung (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS016_ErrorCorrectionTypes(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'andere';
    $02 : Result := 'unbekannt';
    $03 : Result := 'keine';
    $04 : Result := 'Parität';
    $05 : Result := 'einfaches Bit-ECC';
    $06 : Result := 'multiples Bit-ECC';
    $07 : Result := 'CRC';
    else  Result := 'unbekannte Korrektur (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS017_FormFactor(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'anderer';
    $02 : Result := 'unbekannt';
    $03 : Result := 'SIMM';
    $04 : Result := 'SIP';
    $05 : Result := 'Chip';
    $06 : Result := 'DIP';
    $07 : Result := 'ZIP';
    $08 : Result := 'veraltete Karte';
    $09 : Result := 'DIMM';
    $0A : Result := 'TSOP';
    $0B : Result := 'Chipreihe';
    $0C : Result := 'RIMM';
    $0D : Result := 'SODIMM';
    $0E : Result := 'SRIMM';
    $0F : Result := 'FB-DIMM';
    $10 : Result := 'Die';
    else  Result := 'unbekannter Typ (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS017_MemoryType(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'anderer';
    $02 : Result := 'unbekannt';
    $03 : Result := 'DRAM';
    $04 : Result := 'EDRAM';
    $05 : Result := 'VRAM';
    $06 : Result := 'SRAM';
    $07 : Result := 'RAM';
    $08 : Result := 'ROM';
    $09 : Result := 'FLASH';
    $0A : Result := 'EEPROM';
    $0B : Result := 'FEPROM';
    $0C : Result := 'EPROM';
    $0D : Result := 'CDRAM';
    $0E : Result := '3DRAM';
    $0F : Result := 'SDRAM';
    $10 : Result := 'SGRAM';
    $11 : Result := 'RDRAM';
    $12 : Result := 'DDR';
    $13 : Result := 'DDR2';
    $14 : Result := 'DDR2 FB-DIMM';
    $18 : Result := 'DDR3';
    $19 : Result := 'FBD2';
    $1A : Result := 'DDR4';
    $1B : Result := 'LPDDR';
    $1C : Result := 'LPDDR2';
    $1D : Result := 'LPDDR3';
    $1E : Result := 'LPDDR4';
    $1F : Result := 'Logisches nicht-flüchtiges Gerät';
    $20 : Result := 'HBM (Hoch-Bandbreiten-Speicher)';
    $21 : Result := 'HBM2 (Hoch-Bandbreiten-Speicher Gen 2)';
    $22 : Result := 'DDR5';
    $23 : Result := 'LPDDR5';
    $24 : Result := 'HBM3 (Hoch-Bandbreiten-Speicher Gen 3)';
    else  Result := 'unbekannter Typ (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS017_TypeDetail(AValue : Word) : String;
var
  ReturnStr : String;
begin
  ReturnStr := '';
  if AValue = 0 then ReturnStr := '---' else
  begin
    if IsBitOn(AValue, 15) then ReturnStr := ReturnStr + 'LRDIMM, ';
    if IsBitOn(AValue, 14) then ReturnStr := ReturnStr + 'ungepuffert (unregistriert), ';
    if IsBitOn(AValue, 13) then ReturnStr := ReturnStr + 'registriert (gepuffert), ';
    if IsBitOn(AValue, 12) then ReturnStr := ReturnStr + 'nicht-flüchtig, ';
    if IsBitOn(AValue, 11) then ReturnStr := ReturnStr + 'Cache DRAM, ';
    if IsBitOn(AValue, 10) then ReturnStr := ReturnStr + 'Window DRAM, ';
    if IsBitOn(AValue,  9) then ReturnStr := ReturnStr + 'EDO, ';
    if IsBitOn(AValue,  8) then ReturnStr := ReturnStr + 'CMOS, ';
    if IsBitOn(AValue,  7) then ReturnStr := ReturnStr + 'synchron, ';
    if IsBitOn(AValue,  6) then ReturnStr := ReturnStr + 'RAMBUS, ';
    if IsBitOn(AValue,  5) then ReturnStr := ReturnStr + 'Pseudo-statisch, ';
    if IsBitOn(AValue,  4) then ReturnStr := ReturnStr + 'statische Zeile, ';
    if IsBitOn(AValue,  3) then ReturnStr := ReturnStr + 'Fast-Paged, ';
    if IsBitOn(AValue,  2) then ReturnStr := ReturnStr + 'unbekannt, ';
    if IsBitOn(AValue,  1) then ReturnStr := ReturnStr + 'anderes Detail, ';

    Delete(ReturnStr, Length(ReturnStr) - 1, 255);
  end;
  Result := ReturnStr;
end;

function TSMBIOS_Structures.GetSMBIOS017_MemoryTechnology(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'anderer';
    $02 : Result := 'unbekannt';
    $03 : Result := 'DRAM';
    $04 : Result := 'NVDIMM-N';
    $05 : Result := 'NVDIMM-F';
    $06 : Result := 'NVDIMM-P';
    $07 : Result := 'Intel Optane DC Persistenter Speicher';
    else  Result := 'unbekannter Typ (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS017_MemoryOperatingModeCapability(AValue : Word) : String;
var
  ReturnStr : String;
begin
  ReturnStr := '';
  if AValue = 0 then ReturnStr := '---' else
  begin
    if IsBitOn(AValue, 5) then ReturnStr := ReturnStr + 'per Block zugreifbarer persistenter Speicher, ';
    if IsBitOn(AValue, 4) then ReturnStr := ReturnStr + 'per Byte zugreifbarer persistenter Speicher, ';
    if IsBitOn(AValue, 3) then ReturnStr := ReturnStr + 'flüchtiger Speicher, ';
    if IsBitOn(AValue, 2) then ReturnStr := ReturnStr + 'unbekannt, ';
    if IsBitOn(AValue, 1) then ReturnStr := ReturnStr + 'anderer Modus, ';

    Delete(ReturnStr, Length(ReturnStr) - 1, 255);
  end;
  Result := ReturnStr;
end;

function TSMBIOS_Structures.GetSMBIOS026_Location(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'andere';
    $02 : Result := 'unbekannt';
    $03 : Result := 'Prozessor';
    $04 : Result := 'Festplatte';
    $05 : Result := 'Zusatzgeräte';
    $06 : Result := 'Systemverwaltungsmodul';
    $07 : Result := 'Hauptplatine';
    $08 : Result := 'Speichermodul';
    $09 : Result := 'Prozessormodul';
    $0A : Result := 'Stromeinheit';
    $0B : Result := 'Erweiterungskarte';
    else  Result := 'unbekannte Position (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS026_Status(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'anderer';
    $02 : Result := 'unbekannt';
    $03 : Result := 'OK';
    $04 : Result := 'nicht kritisch';
    $05 : Result := 'kritisch';
    $06 : Result := 'nicht wiederherstellbar';
    else  Result := 'unbekannter Status (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS027_DeviceType(AValue : Byte) : String;
begin
  case AValue of
    01 : Result := 'anderer';
    02 : Result := 'unbekannt';
    03 : Result := 'Lüfter';
    04 : Result := 'zentrifugales Gebläse';
    05 : Result := 'Chip-Lüfter';
    06 : Result := 'Schaltschrank-Lüfter';
    07 : Result := 'Stromversorgungslüfter';
    08 : Result := 'Hitzerohr';
    09 : Result := 'integrierte Kühlung';
    16 : Result := 'aktive Kühlung';
    17 : Result := 'passive Kühlung';
    else Result := 'unbekannter Typ (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS027_Status(AValue : Byte) : String;
begin
  case AValue of
    01 : Result := 'anderer';
    02 : Result := 'unbekannt';
    03 : Result := 'OK';
    04 : Result := 'nicht kritisch';
    05 : Result := 'kritisch';
    06 : Result := 'nicht wiederherstellbar';
    else Result := 'unbekannter Status (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS028_Location(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'andere';
    $02 : Result := 'unbekannt';
    $03 : Result := 'Prozessor';
    $04 : Result := 'Festplatte';
    $05 : Result := 'Zusatzgeräte';
    $06 : Result := 'Systemverwaltungsmodul';
    $07 : Result := 'Hauptplatine';
    $08 : Result := 'Speichermodul';
    $09 : Result := 'Prozessormodul';
    $0A : Result := 'Stromeinheit';
    $0B : Result := 'Erweiterungskarte';
    $0C : Result := 'Vorderseitenplatine';
    $0D : Result := 'Rückseitenplatine';
    $0E : Result := 'Stromsystemplatine';
    $0F : Result := 'Laufwerksrückseite';
    else  Result := 'unbekannte Position (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS028_Status(AValue : Byte) : String;
begin
  case AValue of
    01 : Result := 'anderer';
    02 : Result := 'unbekannt';
    03 : Result := 'OK';
    04 : Result := 'nicht kritisch';
    05 : Result := 'kritisch';
    06 : Result := 'nicht wiederherstellbar';
    else Result := 'unbekannter Status (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS029_Location(AValue : Byte) : String;
begin
  case AValue of
    $01 : Result := 'andere';
    $02 : Result := 'unbekannt';
    $03 : Result := 'Prozessor';
    $04 : Result := 'Festplatte';
    $05 : Result := 'Zusatzgerät';
    $06 : Result := 'Systemverwaltungsmodul';
    $07 : Result := 'Hauptplatine';
    $08 : Result := 'Speichermodul';
    $09 : Result := 'Prozessormodul';
    $0A : Result := 'Stromeinheit';
    $0B : Result := 'Erweiterungskarte';
    else  Result := 'unbekannte Position (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

function TSMBIOS_Structures.GetSMBIOS029_Status(AValue : Byte) : String;
begin
  case AValue of
    01 : Result := 'anderer';
    02 : Result := 'unbekannt';
    03 : Result := 'OK';
    04 : Result := 'nicht kritisch';
    05 : Result := 'kritisch';
    06 : Result := 'nicht wiederherstellbar';
    else Result := 'unbekannter Status (' + IntToHex(AValue, 2) + 'h)';
  end;
end;

end.
