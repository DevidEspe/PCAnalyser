unit SMBIOSClass;

interface

uses
  WinAPI.Windows, System.Classes, System.SysUtils, System.WideStrUtils,
  System.Win.Registry, System.Variants, System.Math, System.Win.ComObj,
  WinAPI.ActiveX;

type
  //Contains a SMBIOS dump including some additional version details
  TRawSMBIOSData = packed record
    Used20CallingMethod : Byte;
    SMBIOSMajorVersion : Byte;
    SMBIOSMinorVersion : Byte;
    DmiRevision : Byte;
    Length : Cardinal;
    SMBIOSTableData : Array[0..0] of Byte;
  end;
  PRawSMBIOSData = ^TRawSMBIOSData;

  //Contains an SMBIOS header with version and length details
  TSMBIOSHeader = record
    MajorVersion : Byte;
    MinorVersion : Byte;
    DmiRevision : Byte;
    Length : Cardinal;
  end;

  //Contains the SMBIOS table header area
  TSMBIOSTableHeader = packed record
    &Type : Byte;
    Length : Byte;
    Handle : Word;
  end;
  PSMBIOSTableHeader = ^TSMBIOSTableHeader;

  //Contains all data of a SMBIOS table with control details,
  //which are later addressed via a generic array
  TSMBIOSTable = record
    Header : TSMBIOSTableHeader;
    Offset : Cardinal;
    Name : String;
    Index : Integer;
    TotalLength : Cardinal;
  end;

  TSMBIOS = class(TObject)
  private
    type
      TGetSystemFirmwareTable = function(FirmwareTableProviderSignature : DWord;
                                         FirmwareTableID : DWord;
                                         out pFirmwareTableBuffer;
                                         BufferSize : DWord): UInt; stdcall;
    var
      Kernel32Handle : THandle;
      GetSystemFirmwareTable : TGetSystemFirmwareTable;
      FData : TBytes;
      FHeader : TSMBIOSHeader;
      FTables : TArray<TSMBIOSTable>;
      FDataSource : String;
    const
      ArrayDelimiter = '|';
  public
    //Class basic functions
    constructor Create;
    destructor Destroy; override;
    procedure Clear;

    //Core loading functions
    function  LoadFromSystem : Boolean;
    function  LoadFromAPI : Boolean;
    function  LoadFromWMI : Boolean;
    function  LoadFromRegistry : Boolean;

    //General helper functions
    function  GetSMBIOS(out AHeader : TSMBIOSHeader; out AData : TBytes) : Boolean;
    function  DumpSystemFirmwareTable(ATableSignature, ATableID : Cardinal; out AData : TBytes) : Boolean;
    procedure Load(AHeader : TSMBIOSHeader; AData : TBytes);
    function  GetTableCount : Integer;
    function  GetTableName(ATyp : Byte) : String;
    function  GetTable(AIndex: Integer) : TSMBIOSTable;
    function  GetTableByType(ATyp : Byte; AIndex : Integer = 0) : Integer;
    function  IsTableAvailable(ATyp : Byte) : Boolean;
    function  ReadSMBIOSString(AOffset : Cardinal; AIndex : Byte) : String;
    function  GetNameFromStr(ASource : String; ASep : String = '=') : String;
    function  GetValueFromStr(ASource : String; ASep : String = '=') : String;
    function  GetSize : Cardinal;
    function  GetDMIRev : Byte;
    function  GetMajor : Byte;
    function  GetMinor : Byte;
    function  IsDDR4MemoryAvailable : Boolean;
    function  IsDDR5MemoryAvailable : Boolean;

    //Binary and Text helper functions
    function  HiDWord(AValue : UInt64) : Cardinal;
    function  LoDWord(AValue : UInt64) : Cardinal;
    function  IsBitOn(Value : UInt64; Bit : Byte) : Boolean;
    function  YesNo(ABool : Boolean) : String;
    function  GetCapacity(AValue : UInt64) : String;
    function  CheckIfEmptyString(AStr : String) : String;

    //Published properties
    property Data : TBytes read FData;
    property MajorVersion : Byte read GetMajor;
    property MinorVersion : Byte read GetMinor;
    property DMIRevision : Byte read GetDMIRev;
    property Size : Cardinal read GetSize;
    property DataSource : String read FDataSource;
    property TableCount : Integer read GetTableCount;
    property Tables[AIndex : Integer] : TSMBIOSTable read GetTable;

    //Main evaluation for raw data
    procedure GetSMBIOSStructureDetails(ATableNum : Byte; SMBIOSData : TStrings);
  end;

implementation

uses
  SMBIOSStructures;

constructor TSMBIOS.Create;
begin
  inherited;

  Kernel32Handle := GetModuleHandle(PChar(Winapi.Windows.kernel32));
  GetSystemFirmwareTable :=
    TGetSystemFirmwareTable(
      GetProcAddress(Kernel32Handle, 'GetSystemFirmwareTable'));
end;

destructor TSMBIOS.Destroy;
begin
  inherited;
end;

procedure TSMBIOS.Clear;
begin
  Finalize(FData);
  FHeader := Default(TSMBIOSHeader);
end;

function TSMBIOS.LoadFromSystem : Boolean;
begin
  FDataSource := 'unbekannt';
  Result := LoadFromAPI;
  if Result then
    FDataSource := 'Windows API'
  else
  begin
    Result := LoadFromWMI;
    if Result then
      FDataSource := 'Windows Management Instrumentation (WMI)'
    else
    begin
      Result := LoadFromRegistry;
      if Result then
        FDataSource := 'Windows Registrierung';
    end;
  end;
end;

function TSMBIOS.LoadFromAPI : Boolean;
begin
  Clear;
  Result := GetSMBIOS(FHeader, FData);
  if Result then
    Load(FHeader, FData);
end;

function TSMBIOS.LoadFromWMI : Boolean;
var
  WbemLocator,
  WMIService,
  WbemObjectSet,
  WbemObject : OLEVariant;
  LEnum : IEnumVariant;
  LongValue : LongWord;
  Counter : Integer;
  LVariant : Variant;
begin
  Result := False;
  Clear;
  CoInitialize(nil);
  WbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
  WMIService := WbemLocator.ConnectServer('localhost', 'root\WMI', '', '');
  WbemObjectSet := WMIService.ExecQuery('SELECT * FROM MSSmBios_RawSMBiosTables',
                                        'WQL', $00000020);
  LEnum := IUnknown(WbemObjectSet._NewEnum) as IEnumVariant;
  while LEnum.Next(1, WbemObject, LongValue) = 0 do
  begin
    FHeader.MajorVersion := WbemObject.SmbiosMajorVersion;
    FHeader.MinorVersion := WbemObject.SmbiosMinorVersion;
    FHeader.DmiRevision := WbemObject.DmiRevision;
    FHeader.Length := WbemObject.Size;
    LVariant := WbemObject.SMBiosData;
    SetLength(FData, VarArrayHighBound(LVariant, 1) + 1);
    for Counter := VarArrayLowBound(LVariant, 1) to VarArrayHighBound(LVariant, 1) do
      FData[Counter] := LVariant[Counter];
    WbemObject := Unassigned;
    Result := True;
    Break;
  end;
  if not Result then
    Exit;
  FHeader.Length := Length(FData);
  Load(FHeader, FData);
end;

function TSMBIOS.LoadFromRegistry : Boolean;
type
  TIsWow64Process = function(Handle : THandle; var Res : Bool) : Bool; stdcall;
var
  RegDataInfo : TRegDataInfo;
  Buffer : TBytes;
  SMBRawData : TRawSMBIOSData;
  KeyAccess : Cardinal;
  IsWow64Process : TIsWow64process;
  IsWow64 : Bool;
begin
  //Check if WoW64 is active
  IsWow64 := False;
  IsWow64Process := nil;
  if Kernel32Handle <> 0 then
    IsWOW64Process := GetProcAddress(Kernel32Handle, PChar('IsWow64Process'));
  if Assigned(IsWow64Process) then
    IsWow64Process(GetCurrentProcess, IsWow64);

  //Proceed with Registry read process
  KeyAccess := KEY_READ;
  if IsWow64 then
    KeyAccess := KeyAccess or KEY_WOW64_64KEY;
  Clear;
  Result := False;
  with TRegistry.Create(KeyAccess) do
    try
      Rootkey := HKEY_LOCAL_MACHINE;
      if OpenKey('SYSTEM\CurrentControlSet\Services\mssmbios\Data', False) then
      begin
        if ValueExists('SMBiosData') then
        begin
          GetDataInfo('SMBiosData', RegDataInfo);
          if RegDataInfo.RegData = rdBinary then
          begin
            SetLength(Buffer, RegDataInfo.DataSize);
            if (RegDataInfo.DataSize > 0) and
               (ReadBinaryData('SMBiosData', Buffer[0], RegDataInfo.DataSize) =
                 RegDataInfo.DataSize) then
            begin
              Move(Buffer[0], SMBRawData, SizeOf(SMBRawData));
              SetLength(FData, SMBRawData.Length);
              Move(Buffer[SizeOf(SMBRawData) - 1], FData[0], SMBRawData.Length);
              FHeader.MajorVersion := SMBRawData.SMBIOSMajorVersion;
              FHeader.MinorVersion := SMBRawData.SMBIOSMinorVersion;
              FHeader.DmiRevision := SMBRawData.DmiRevision;
              FHeader.Length := SMBRawData.Length;
              Load(FHeader, FData);
              Result := True;
            end;
          end;
        end;
        CloseKey;
      end;
    finally
      Free;
    end;
end;

function TSMBIOS.GetDMIRev : Byte;
begin
  Result := FHeader.DmiRevision;
end;

function TSMBIOS.GetMajor : Byte;
begin
  Result := FHeader.MajorVersion;
end;

function TSMBIOS.GetMinor : Byte;
begin
  Result := FHeader.MinorVersion;
end;

function TSMBIOS.GetSize : Cardinal;
begin
  Result := Length(FData);
end;

function TSMBIOS.IsDDR4MemoryAvailable : Boolean;
var
  TableCount : Cardinal;
  SMBIOSTable017 : PSMBIOS_MemoryDevice;
begin
  Result := False;
  for TableCount := 0 to High(FTables) do
    case FTables[TableCount].Header.&Type of
      SMB_MEMDEV : //Memory Device
        begin
          SMBIOSTable017 := @FData[FTables[TableCount].Offset];
          if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 21) then
          begin
            if Pos('DDR4',
              GetSMBIOS017_MemoryType(SMBIOSTable017.MemoryType)) <> 0 then
            begin
              Result := True;
              Break;
            end;
          end;
        end;
    end;
end;

function TSMBIOS.IsDDR5MemoryAvailable : Boolean;
var
  TableCount : Cardinal;
  SMBIOSTable017 : PSMBIOS_MemoryDevice;
begin
  Result := False;
  for TableCount := 0 to High(FTables) do
    case FTables[TableCount].Header.&Type of
      SMB_MEMDEV : //Memory Device
        begin
          SMBIOSTable017 := @FData[FTables[TableCount].Offset];
          if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 21) then
          begin
            if Pos('DDR5',
              GetSMBIOS017_MemoryType(SMBIOSTable017.MemoryType)) <> 0 then
            begin
              Result := True;
              Break;
            end;
          end;
        end;
    end;
end;

function TSMBIOS.GetTable(AIndex : Integer) : TSMBIOSTable;
begin
  Result := FTables[AIndex];
end;

function TSMBIOS.GetTableCount : Integer;
begin
  Result := Length(FTables);
end;

function TSMBIOS.GetTableByType(ATyp : Byte; AIndex : Integer) : Integer;
var
  i : Integer;
begin
  Result := -1;
  for i := 0 to High(FTables) do
    if (FTables[i].Header.&Type = ATyp) and
       (FTables[i].Index = AIndex) then
    begin
      Result := i;
      Break;
    end;
end;

procedure TSMBIOS.Load(AHeader : TSMBIOSHeader; AData : TBytes);
var
  TableName : String;
  TableCount,
  IndexOfSameTable,
  CharZeroCount,
  TableIndex : Integer;
  Position : Cardinal;
  TableHeader : TSMBIOSTableHeader;
begin
  Clear;
  FHeader := AHeader;
  FData := AData;
  if Length(FData) = 0 then
    Exit;
  Position := 0;
  CharZeroCount := 2;
  while Position < Cardinal(Length(FData)) do
  begin
    if CharZeroCount = 2 then
    begin
      Move(FData[Position], TableHeader, SizeOf(TableHeader));
      if TableHeader.&Type >= SMB_OEM_BEGIN then
        TableName := 'OEM-spezifisch'
      else
        TableName := GetTableName(TableHeader.&Type);

      IndexOfSameTable := 0;
      for TableCount := 0 to High(FTables) do
        if FTables[TableCount].Header.&Type = TableHeader.&Type then
          Inc(IndexOfSameTable);

      TableIndex := Length(FTables);
      SetLength(FTables, TableIndex + 1);
      FTables[TableIndex].Header := TableHeader;
      FTables[TableIndex].Offset := Position;
      FTables[TableIndex].Name := TableName;
      FTables[TableIndex].Index := IndexOfSameTable;
      FTables[TableIndex].TotalLength := TableHeader.Length;

      Inc(Position, TableHeader.Length);
      CharZeroCount := 0;
      if TableHeader.&Type = SMB_EOT then
        Break;
    end; //of CharZeroCount = 2
    if FData[Position] = 0 then
      Inc(CharZeroCount)
    else
      CharZeroCount := 0;
    Inc(Position);
  end;

  TableCount := GetTableByType(SMB_EOT);
  if (TableCount >- 1) and (Cardinal(Length(FData)) > FTables[TableCount].Offset + FTables[TableCount].Header.Length + 2) then
    SetLength(FData, FTables[TableCount].Offset + FTables[TableCount].Header.Length + 2);
end;

function TSMBIOS.GetSMBIOS(out AHeader : TSMBIOSHeader; out AData : TBytes) : Boolean;
var
  Buffer : TBytes;
  SMBIOSData : TRawSMBIOSData;
const
  sigRSMB = $52534D42;
begin
  AHeader := Default(TSMBIOSHeader);
  Finalize(AData);

  Result := DumpSystemFirmwareTable(sigRSMB, 0, Buffer);
  if Result then
  begin
    Move(Buffer[0], SMBIOSData, SizeOf(SMBIOSData));
    SetLength(AData, SMBIOSData.Length);
    Move(Buffer[SizeOf(SMBIOSData) - 1], AData[0], SMBIOSData.Length);
    AHeader.MajorVersion := SMBIOSData.SMBIOSMajorVersion;
    AHeader.MinorVersion := SMBIOSData.SMBIOSMinorVersion;
    AHeader.DmiRevision := SMBIOSData.DmiRevision;
    AHeader.Length := SMBIOSData.Length;
  end;
end;

function TSMBIOS.DumpSystemFirmwareTable(ATableSignature, ATableID : Cardinal; out AData : TBytes) : Boolean;
var
  BytesWrittenInBuffer : Cardinal;
begin
  Result := False;
  if not Assigned(GetSystemFirmwareTable) then
    Exit;
  BytesWrittenInBuffer := GetSystemFirmwareTable(ATableSignature, ATableID, nil^, 0);
  if BytesWrittenInBuffer > 0 then
  begin
    SetLength(AData, BytesWrittenInBuffer);
    BytesWrittenInBuffer := GetSystemFirmwareTable(ATableSignature, ATableID, AData[0], BytesWrittenInBuffer);
    Result := BytesWrittenInBuffer > 0;
  end;
end;

function TSMBIOS.GetTableName(ATyp : Byte) : String;
var
  Counter : Integer;
begin
  Result := 'unbekannt';
  for Counter := 0 to High(SMB_TableTypes) do
    if SMB_TableTypes[Counter].&Type = ATyp then
    begin
      Result := SMB_TableTypes[Counter].Name;
      Break;
    end;
end;

function TSMBIOS.GetNameFromStr(ASource : String; ASep : String = '=') : String;
var
  Position : Integer;
begin
  Position := Pos(ASep, ASource);
  if Position > 0 then
    Result := Trim(Copy(ASource, 1, Position - 1))
  else
    Result := ASource;
end;

function TSMBIOS.GetValueFromStr(ASource : String; ASep : String = '=') : String;
var
  Position : Integer;
begin
  Position := Pos(ASep, ASource);
  if Position > 0 then
    Result := Copy(ASource, Position + Length(ASep), 1024)
  else
    Result := '';
end;

function TSMBIOS.IsTableAvailable(ATyp : Byte) : Boolean;
var
  Counter : Integer;
begin
  Result := False;
  for Counter := 0 to TableCount - 1 do
    if Tables[Counter].Header.&Type = ATyp then
    begin
      Result := True;
      Break;
    end;
end;

function TSMBIOS.ReadSMBIOSString(AOffset : Cardinal; AIndex : Byte) : String;
var
  Count : byte;
begin
  Result := '';
  if AIndex = 0 then
    Exit;
  Count := 1;
  while (Count <= AIndex) and (AOffset < Cardinal(Length(FData))) do
  begin
    if FData[AOffset] = 0 then
      Inc(Count)
    else if (Count = AIndex) then
      Result := Result + Chr(FData[AOffset]);
    Inc(AOffset);
  end;
  Result := Result;
end;

function TSMBIOS.CheckIfEmptyString(AStr : String) : String;
begin
  Result:='(leer)';

  if (Trim(AStr) = '') or
     (UpperCase(AStr) = 'TO BE FILLED') OR
     (UpperCase(AStr) = 'DEFAULT STRING') then
    Exit else
  if (AStr[1] = '') or (AStr[1] = ' ') or (AStr[1] = #0) then
    Exit;
  Result := AStr;
end;

function TSMBIOS.HiDWord(AValue : UInt64) : Cardinal;
begin
  Result := AValue shr 32;
end;

function TSMBIOS.LoDWord(AValue : UInt64) : Cardinal;
begin
  Result := Cardinal(AValue);
end;

function TSMBIOS.IsBitOn(Value : UInt64; Bit : Byte) : Boolean;
begin
  if Bit > 31 then
    Result := (HiDWord(Value) and (1 shl (Bit - 32))) <> 0
  else
    Result := (LoDWord(Value) and (1 shl Bit)) <> 0;
end;

function TSMBIOS.YesNo(ABool : Boolean) : String;
begin
  case ABool of
    True  : Result := 'ja';
    False : Result := 'nein';
  end;
end;

function TSMBIOS.GetCapacity(AValue : UInt64) : String;
const
  ByteShortUnits : array[0..8] of String =
                   ('B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB');
var
  Counter  : Integer;
  OutputUnit : String;
begin
  for Counter := 1 to Length(ByteShortUnits) - 1 do
    if Power(2, Counter * 10) > AValue then
      Break;
  Dec(Counter);
  OutputUnit := ByteShortUnits[Counter];
  Result := FloatToStr(RoundTo(AValue / Power(2, Counter * 10), 0)) + ' ' + OutputUnit;
end;

procedure TSMBIOS.GetSMBIOSStructureDetails(ATableNum : Byte; SMBIOSData : TStrings);
var
  StringValue : String;
  TableCount,
  StringPosition,
  CardinalValue : Cardinal;
  Counter : Integer;
  WordValue : Word;
  Unsigned64BitValue : UInt64;

  SMBIOSTable000 : PSMBIOS_BIOS;
  SMBIOSTable001 : PSMBIOS_System;
  SMBIOSTable002 : PSMBIOS_Baseboard;
  SMBIOSTable002_ContainedObjectHandles : TArray<Word>;
  SMBIOSTable003 : PSMBIOS_SystemEnclosure;
  SMBIOSTable003_ContainedElements : TArray<TSMBIOS_ContainedElements>;
  SMBIOSTable004 : PSMBIOS_Processor;
  SMBIOSTable007 : PSMBIOS_Cache;
  SMBIOSTable008 : PSMBIOS_PortConnector;
  SMBIOSTable009 : PSMBIOS_SystemSlots;
  SMBIOSTable009_PeerGroups : TArray<TPeerGroup>;
  SMBIOSTable016 : PSMBIOS_PhysicalMemoryArray;
  SMBIOSTable017 : PSMBIOS_MemoryDevice;
  SMBIOSTable026 : PSMBIOS_VoltageProbe;
  SMBIOSTable027 : PSMBIOS_CoolingDevice;
  SMBIOSTable028 : PSMBIOS_TemperatureProbe;
  SMBIOSTable029 : PSMBIOS_ElectricalCurrentProbe;
  SMBIOSTable043 : PSMBIOS_TPMDevice;
begin
  SMBIOSData.Clear;

  for TableCount := 0 to High(FTables) do
    if FTables[TableCount].Header.&Type = ATableNum then
      case ATableNum of
        SMB_BIOSINFO : //BIOS Information
          begin
            SMBIOSTable000 := @FData[FTables[TableCount].Offset];
            StringPosition := FTables[TableCount].Offset +
                              FTables[TableCount].Header.Length;

            SMBIOSData.Add('Hersteller='+
              CheckIfEmptyString(ReadSMBIOSString(StringPosition,
              SMBIOSTable000.VendorStr)));

            SMBIOSData.Add('BIOS-Version='+
              CheckIfEmptyString(ReadSMBIOSString(StringPosition,
              SMBIOSTable000.BIOSVersionStr)));

            SMBIOSData.Add('BIOS-Startadress-Segment='+
              IntToHex(SMBIOSTable000.BIOSStartingAddressSegment, 4) + 'h');

            SMBIOSData.Add('BIOS-Veröffentlichungsdatum='+
              CheckIfEmptyString(ReadSMBIOSString(StringPosition,
              SMBIOSTable000.BIOSReleaseDateStr)));

            SMBIOSData.Add('BIOS-ROM-Größe='+
              IntToStr(SMBIOSTable000.BIOSROMSize * 64) + ' KByte');

            SMBIOSData.Add('');
            SMBIOSData.Add('BIOS-Eigenschaften Standard=');

            SMBIOSData.Add('- BIOS Eigenschaften unterstützt='+
              YesNo(not IsBitOn(SMBIOSTable000.BIOSCharacteristics, 3)));

            SMBIOSData.Add('- ISA wird unterstützt='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 4)));

            SMBIOSData.Add('- MCA wird unterstützt='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 5)));

            SMBIOSData.Add('- EISA wird unterstützt='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 6)));

            SMBIOSData.Add('- PCI wird unterstützt='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 7)));

            SMBIOSData.Add('- PC Card/PCMCIA wird unterstützt='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 8)));

            SMBIOSData.Add('- Plug&Play wird unterstützt='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 9)));

            SMBIOSData.Add('- APM wird unterstützt='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 10)));

            SMBIOSData.Add('- BIOS ist aktualisierbar (Flash)='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 11)));

            SMBIOSData.Add('- BIOS-Schattierung ist erlaubt='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 12)));

            SMBIOSData.Add('- VL-VESA wird unterstützt='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 13)));

            SMBIOSData.Add('- ESCD wird unterstützt='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 14)));

            SMBIOSData.Add('- Start von CD wird unterstützt='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 15)));

            SMBIOSData.Add('- Auswählbarer Start wird unterstützt='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 16)));

            SMBIOSData.Add('- BIOS-ROM ist gesockelt='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 17)));

            SMBIOSData.Add('- Starten von PCMCIA wird unterstützt='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 18)));

            SMBIOSData.Add('- Enhanced Disk Drive wird unterstützt='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 19)));

            SMBIOSData.Add('- Int13h: Japanisches FDD für NEC 9800='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 20)));

            SMBIOSData.Add('- Int13h: Japanisches FDD für Toshiba='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 21)));

            SMBIOSData.Add('- Int13h: 5.25"/360KB FDD-Dienste='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 22)));

            SMBIOSData.Add('- Int13h: 5.25"/1.2MB FDD-Dienste='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 23)));

            SMBIOSData.Add('- Int13h: 3.5"/720KB FDD-Dienste='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 24)));

            SMBIOSData.Add('- Int13h: 3.5"/2.88MB FDD-Dienste='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 25)));

            SMBIOSData.Add('- Int05h: Bildschirmdruck-Dienst='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 26)));

            SMBIOSData.Add('- Int09h: 8042 Tastatur-Dienst='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 27)));

            SMBIOSData.Add('- Int14h: Serieller Dienst='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 28)));

            SMBIOSData.Add('- Int17h: Drucker-Dienst='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 29)));

            SMBIOSData.Add('- Int10h: CGA/Mono Video-Dienst='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 30)));

            SMBIOSData.Add('- NEC PC-98 Spezifikation='+
              YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristics, 31)));

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 24) and
               (SMBIOSTable000.Header.Length - $12 > 0) then
            begin
              SMBIOSData.Add('');
              SMBIOSData.Add('BIOS-Eigenschaften Erweitert=');

              SMBIOSData.Add('- ACPI wird unterstützt='+
                YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristicsExtensionBytes[0], 0)));

              SMBIOSData.Add('- Veraltetes USB wird unterstützt='+
                YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristicsExtensionBytes[0], 1)));

              SMBIOSData.Add('- AGP wird unterstützt='+
                YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristicsExtensionBytes[0], 2)));

              SMBIOSData.Add('- I2O-Start wird unterstützt='+
                YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristicsExtensionBytes[0], 3)));

              SMBIOSData.Add('- LS120-Start wird unterstützt='+
                YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristicsExtensionBytes[0], 4)));

              SMBIOSData.Add('- ATAPI ZIP-Start wird unterstützt='+
                YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristicsExtensionBytes[0], 5)));

              SMBIOSData.Add('- Firewire/1394-Start wird unterstützt='+
                YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristicsExtensionBytes[0], 6)));

              SMBIOSData.Add('- Smart Batterie wird unterstützt='+
                YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristicsExtensionBytes[0], 7)));
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 24) and
               (SMBIOSTable000.Header.Length - $12 > 1) then
            begin
              SMBIOSData.Add('- BIOS Boot-Spezifikation unterstützt='+
                YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristicsExtensionBytes[1], 0)));

              SMBIOSData.Add('- Netzwerk-Dienst-Start wird unterstützt='+
                YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristicsExtensionBytes[1], 1)));

              SMBIOSData.Add('- Gezielte Inhaltsdistribution aktiv='+
                YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristicsExtensionBytes[1], 2)));

              SMBIOSData.Add('- UEFI wird unterstützt='+
                YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristicsExtensionBytes[1], 3)));

              SMBIOSData.Add('- SMBIOS definiert virtuelle Maschine='+
                YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristicsExtensionBytes[1], 4)));

              SMBIOSData.Add('- Herstellermodus wird unterstützt='+
                YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristicsExtensionBytes[1], 5)));

              SMBIOSData.Add('- Herstellermodus ist aktiviert='+
                YesNo(IsBitOn(SMBIOSTable000.BIOSCharacteristicsExtensionBytes[1], 6)));
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 24) then
            begin
              SMBIOSData.Add('');

              if (SMBIOSTable000.SystemBIOSMajorRelease = $FF) or
                 (SMBIOSTable000.SystemBIOSMinorRelease = $FF) then
                StringValue := 'wird nicht unterstützt'
              else
                StringValue := IntToStr(SMBIOSTable000.SystemBIOSMajorRelease) +
                               '.' +
                               IntToStr(SMBIOSTable000.SystemBIOSMinorRelease);
              SMBIOSData.Add('System BIOS-Version='+
                StringValue);

              if (SMBIOSTable000.EmbeddedControllerFirmwareMajorRelease = $FF) or
                 (SMBIOSTable000.EmbeddedControllerFirmwareMinorRelease = $FF) then
                StringValue := 'wird nicht unterstützt'
              else
                StringValue := IntToStr(SMBIOSTable000.EmbeddedControllerFirmwareMajorRelease) +
                               '.' +
                               IntToStr(SMBIOSTable000.EmbeddedControllerFirmwareMinorRelease);
              SMBIOSData.Add('Integrierte Kontroller-Firmware-Version='+
                StringValue);
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 31) then
            begin
              case ((SMBIOSTable000.ExtendedBIOSROMSize shr 14) and 3) of
                0  : StringValue :=
                       IntToStr(SMBIOSTable000.ExtendedBIOSROMSize and $3FFF) +
                       ' MByte';
                1  : StringValue :=
                       IntToStr(SMBIOSTable000.ExtendedBIOSROMSize and $3FFF) +
                       ' GByte';
                else StringValue := 'reserviert';
              end;
              SMBIOSData.Add('Erweiterte BIOS ROM-Größe='+
                StringValue);
            end;
          end;
        SMB_SYSINFO : //System Information
          begin
            SMBIOSTable001 := @FData[FTables[TableCount].Offset];
            StringPosition := FTables[TableCount].Offset +
                              FTables[TableCount].Header.Length;

            SMBIOSData.Add('Hersteller='+
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable001.ManufacturerStr)));

            SMBIOSData.Add('Produktname='+
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable001.ProductNameStr)));

            SMBIOSData.Add('Version='+
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable001.VersionStr)));

            SMBIOSData.Add('Seriennummer='+
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable001.SerialNumberStr)));

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 21) then
            begin
              StringValue := '';
              for Counter := 0 to 15 do
                StringValue := StringValue +
                Format('%2.2x', [SMBIOSTable001.UUID[Counter]]);
              if StringValue = 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF' then
                StringValue := 'aktuell nicht vorhanden, aber setzbar' else
              if StringValue = '00000000000000000000000000000000' then
                StringValue := 'nicht vorhanden';
              SMBIOSData.Add('Einzigartige ID (UUID)='+
                StringValue);

              SMBIOSData.Add('Aufwachtyp='+
                GetSMBIOS001_WakeUpType(SMBIOSTable001.WakeUpType));
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 24) then
            begin
              SMBIOSData.Add('SKU-Nummer='+
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable001.SKUNumberStr)));

              SMBIOSData.Add('Familie='+
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable001.FamilyStr)));
            end;
          end;
        SMB_BASEINFO : //Baseboard (or Module) Information
          begin
            SMBIOSTable002 := @FData[FTables[TableCount].Offset];
            StringPosition := FTables[TableCount].Offset +
                              FTables[TableCount].Header.Length;

            if SMBIOSData.Count > 0 then
              SMBIOSData.Add('');

            SMBIOSData.Add('Hersteller='+
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable002.ManufacturerStr)));

            SMBIOSData.Add('Produkt='+
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable002.ProductStr)));

            SMBIOSData.Add('Version='+
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable002.VersionStr)));

            SMBIOSData.Add('Seriennummer='+
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable002.SerialNumberStr)));

            SMBIOSData.Add('Asset-Kennzeichnung='+
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable002.AssetTagStr)));

            SMBIOSData.Add('');
            SMBIOSData.Add('Funktionen=');

            SMBIOSData.Add('- Übergreifende Platine='+
              YesNo(IsBitOn(SMBIOSTable002.FeatureFlags, 0)));

            SMBIOSData.Add('- Platine benötigt min. 1 Tochterplatine='+
              YesNo(IsBitOn(SMBIOSTable002.FeatureFlags, 1)));

            SMBIOSData.Add('- Platine ist entfernbar='+
              YesNo(IsBitOn(SMBIOSTable002.FeatureFlags, 2)));

            SMBIOSData.Add('- Platine ist ersetzbar='+
              YesNo(IsBitOn(SMBIOSTable002.FeatureFlags, 3)));

            SMBIOSData.Add('- Platine ist wechselbar im Betrieb='+
              YesNo(IsBitOn(SMBIOSTable002.FeatureFlags, 4)));

            SMBIOSData.Add('');
            SMBIOSData.Add('Position im Gehäuse='+
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable002.LocationInChassisStr)));

            SMBIOSData.Add('Gehäuse-Instanz='+
              IntToHex(SMBIOSTable002.ChassisHandle, 4) + 'h');

            SMBIOSData.Add('Platinentyp='+
              GetSMBIOS002_BoardType(SMBIOSTable002.BoardType));

            SMBIOSData.Add('');
            SMBIOSData.Add('Anzahl Objektinstanzen='+
              IntToStr(SMBIOSTable002.NumberOfContainedObjectHandles));

            if SMBIOSTable002.NumberOfContainedObjectHandles > 0 then
            begin
              SetLength(SMBIOSTable002_ContainedObjectHandles,
                        SMBIOSTable002.NumberOfContainedObjectHandles);
              Move(FData[FTables[TableCount].Offset + $0F],
                         SMBIOSTable002_ContainedObjectHandles[0],
                         Length(SMBIOSTable002_ContainedObjectHandles));

              for Counter := 0 to High(SMBIOSTable002_ContainedObjectHandles) do
                SMBIOSData.Add(' - Objektinstanz ' + IntToStr(Counter + 1) + '='+
                  IntToHex(SMBIOSTable002_ContainedObjectHandles[Counter], 4) + 'h');
            end;
          end;
        SMB_SYSENC : //System Enclosure or Chassis
          begin
            SMBIOSTable003 := @FData[FTables[TableCount].Offset];
            StringPosition := FTables[TableCount].Offset +
                              FTables[TableCount].Header.Length;

            if SMBIOSData.Count > 0 then
              SMBIOSData.Add('');

            SMBIOSData.Add('Hersteller=' +
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable003.ManufacturerStr)));

            SMBIOSData.Add('Typ=' +
              GetSMBIOS003_ChassisType(SMBIOSTable003.&Type));

            SMBIOSData.Add('- Gehäuse-Verriegelung vorhanden=' +
              YesNo(IsBitOn(SMBIOSTable003.&Type, 7)));

            SMBIOSData.Add('Version=' +
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable003.VersionStr)));

            SMBIOSData.Add('Seriennummer=' +
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable003.SerialNumberStr)));

            SMBIOSData.Add('Asset-Kennzeichnung=' +
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable003.AssetTagNumberStr)));

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 21) then
            begin
              SMBIOSData.Add('Boot-Status=' +
                GetSMBIOS003_State(SMBIOSTable003.BootUpState));

              SMBIOSData.Add('Stromversorgungsstatus=' +
                GetSMBIOS003_State(SMBIOSTable003.PowerSupplyState));

              SMBIOSData.Add('Thermischer Status=' +
                GetSMBIOS003_State(SMBIOSTable003.ThermalState));

              SMBIOSData.Add('Sicherheitsstatus=' +
                GetSMBIOS003_SecurityStatus(SMBIOSTable003.SecurityStatus));
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 23) then
            begin
              SMBIOSData.Add('OEM-spezifisch=' +
                IntToHex(SMBIOSTable003.OEMDefined, 8) + 'h');

              if SMBIOSTable003.Height = 0 then
                StringValue := 'nicht spezifiziert'
              else
                StringValue := IntToStr(SMBIOSTable003.Height) + ' U' +
                               ' (' +
                               FloatToStrF(SMBIOSTable003.Height * 4.445, ffNumber, 4, 3) +
                               ' cm)';
              SMBIOSData.Add('Höhe=' +
                StringValue);

              if SMBIOSTable003.NumberOfPowerCords = 0 then
                StringValue := 'nicht spezifiziert'
              else
                StringValue := IntToStr(SMBIOSTable003.NumberOfPowerCords);
              SMBIOSData.Add('Anzahl Stromkabel=' +
                StringValue);

              SMBIOSData.Add('');

              if SMBIOSTable003.ContainedElementCount = 0 then
                StringValue := 'keine'
              else
                StringValue := IntToStr(SMBIOSTable003.ContainedElementCount);
              SMBIOSData.Add('Gesamt enthaltene Elemente=' +
                StringValue);

              SMBIOSData.Add('Enthaltene Elementgrößenlänge=' +
                IntToStr(SMBIOSTable003.ContainedElementRecordLength) + ' Byte');

              if SMBIOSTable003.ContainedElementCount > 0 then
              begin
                SetLength(SMBIOSTable003_ContainedElements,
                          SMBIOSTable003.ContainedElementCount);
                Move(FData[FTables[TableCount].Offset + $15],
                           SMBIOSTable003_ContainedElements[0],
                           Length(SMBIOSTable003_ContainedElements));

                for Counter := 0 to High(SMBIOSTable003_ContainedElements) do
                begin
                  SMBIOSData.Add('');
                  SMBIOSData.Add('Enthaltenes Element ' + IntToStr(Counter + 1) + '=');

                  if IsBitOn(SMBIOSTable003_ContainedElements[Counter].ContainedElementType, 7) then
                    StringValue := GetTableName(SMBIOSTable003_ContainedElements[Counter].ContainedElementType and $7F)
                  else
                    StringValue := GetSMBIOS002_BoardType(SMBIOSTable003_ContainedElements[Counter].ContainedElementType and $7F);
                  SMBIOSData.Add('Enthaltener Element-Typ=' +
                    StringValue);

                  if IsBitOn(SMBIOSTable003_ContainedElements[Counter].ContainedElementType, 7) then
                    StringValue := 'SMBIOS-Strukturen Typ-Nummerierung'
                  else
                    StringValue := 'SMBIOS-Hauptplatinen Typ-Nummerierung';
                  SMBIOSData.Add('- Typ=' +
                    StringValue);

                  if SMBIOSTable003_ContainedElements[Counter].ContainedElementMinimum = 255 then
                    StringValue := 'unbekannt'
                  else
                    StringValue := IntToStr(SMBIOSTable003_ContainedElements[Counter].ContainedElementMinimum);
                  SMBIOSData.Add('- Minimal enthaltene Elemente=' +
                    StringValue);

                  if SMBIOSTable003_ContainedElements[Counter].ContainedElementMaximum = 255 then
                    StringValue := 'unbekannt'
                  else
                    StringValue := IntToStr(SMBIOSTable003_ContainedElements[Counter].ContainedElementMaximum);
                  SMBIOSData.Add('- Maximal enthaltene Elemente=' +
                    StringValue);
                end;
              end;
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 27) then
            begin
              SMBIOSTable003.SKUNumberStr :=
                FData[FTables[TableCount].Offset +
                $15 +
                SizeOf(TSMBIOS_ContainedElements) *
                SMBIOSTable003.ContainedElementCount];
              SMBIOSData.Add('SKU-Nummer=' +
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable003.SKUNumberStr)));
            end;
          end;
        SMB_CPU : //Processor Information
          begin
            SMBIOSTable004 := @FData[FTables[TableCount].Offset];
            StringPosition := FTables[TableCount].Offset +
                              FTables[TableCount].Header.Length;

            if SMBIOSData.Count > 0 then
              SMBIOSData.Add('');

            SMBIOSData.Add('Sockel-Bezeichnung=' +
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable004.SocketDesignationStr)));

            SMBIOSData.Add('Prozessor-Typ=' +
              GetSMBIOS004_ProcessorType(SMBIOSTable004.ProcessorType));

            SMBIOSData.Add('Prozessor-Familie=' +
              GetSMBIOS004_ProcessorFamily(SMBIOSTable004.ProcessorFamily));

            SMBIOSData.Add('Prozessor-Hersteller=' +
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable004.ProcessorManufacturerStr)));

            SMBIOSData.Add('Prozessor-ID=' +
              IntToHex(SMBIOSTable004.ProcessorID, 8) + 'h');

            SMBIOSData.Add('- Familie=' +
              IntToStr((SMBIOSTable004.ProcessorID shr 8) and $F));

            SMBIOSData.Add('- Modell=' +
              IntToStr((SMBIOSTable004.ProcessorID shr 4) and $F));

            SMBIOSData.Add('- Stepping=' +
              IntToStr(SMBIOSTable004.ProcessorID and $F));

            SMBIOSData.Add('- Erweiterte Familie=' +
              IntToStr((SMBIOSTable004.ProcessorID shr 20) and $FF));

            SMBIOSData.Add('- Erweitertes Modell=' +
              IntToStr((SMBIOSTable004.ProcessorID shr 16) and $F));

            case (SMBIOSTable004.ProcessorID shr 12) and 3 of
              0  : StringValue := 'Hauptprozessor';
              1  : StringValue := 'Overdrive-Prozessor';
              2  : StringValue := 'Zweiter Prozessor (Multiprozessor)';
              else StringValue := 'unbekannt (' + IntToStr((SMBIOSTable004.ProcessorID shr 12) and 3) + ')';
            end;
            SMBIOSData.Add('- Prozessor-Typ=' +
              StringValue);

            SMBIOSData.Add('Prozessor-Version=' +
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable004.ProcessorVersionStr)));

            SMBIOSData.Add('');
            SMBIOSData.Add('Spannung=');

            SMBIOSData.Add('- Legacy-Modus=' +
              YesNo(IsBitOn(SMBIOSTable004.Voltage, 7)));

            if not IsBitOn(SMBIOSTable004.Voltage, 7) then
            begin
              StringValue := '';
              if IsBitOn(SMBIOSTable004.Voltage, 0) then StringValue := StringValue + '5V, ';
              if IsBitOn(SMBIOSTable004.Voltage, 1) then StringValue := StringValue + '3.3V, ';
              if IsBitOn(SMBIOSTable004.Voltage, 2) then StringValue := StringValue + '2.9V, ';
              Delete(StringValue, Length(StringValue) - 1, 255);
              if StringValue = '' then StringValue := 'reserviert';
            end else
              StringValue := FloatToStrF((SMBIOSTable004.Voltage and $7F) / 10,
                                         ffFixed, 0, 2) +
                                         'V';

            SMBIOSData.Add('- Spannungsdetails=' +
              StringValue);

            SMBIOSData.Add('');

            if SMBIOSTable004.ExternalClock <> 0 then
              StringValue := IntToStr(SMBIOSTable004.ExternalClock) + ' MHz'
            else
              StringValue := 'unbekannt';
            SMBIOSData.Add('Externer Takt=' +
              StringValue);

            if SMBIOSTable004.MaxSpeed <> 0 then
              StringValue := IntToStr(SMBIOSTable004.MaxSpeed) + ' MHz'
            else
              StringValue := 'unbekannt';
            SMBIOSData.Add('Maximale Geschwindigkeit=' +
              StringValue);

            if SMBIOSTable004.CurrentSpeed <> 0 then
              StringValue := IntToStr(SMBIOSTable004.CurrentSpeed) + ' MHz'
            else
              StringValue := 'unbekannt';
            SMBIOSData.Add('Aktuelle Geschwindigkeit=' +
              StringValue);

            SMBIOSData.Add('');
            SMBIOSData.Add('Status=');

            SMBIOSData.Add('CPU-Status=' +
              GetSMBIOS004_CPUStatus(SMBIOSTable004.Status and 7));

            SMBIOSData.Add('- CPU Sockel benutzt=' +
              YesNo(IsBitOn(SMBIOSTable004.Status, 6)));

            SMBIOSData.Add('');

            SMBIOSData.Add('Prozessor-Upgrade=' +
              GetSMBIOS004_ProcessorUpgrade(SMBIOSTable004.ProcessorUpgrade));

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 21) then
            begin
              if SMBIOSTable004.L1CacheHandle = $FFFF then
                StringValue := 'kein L1 Cache vorhanden'
              else
                StringValue := IntToHex(SMBIOSTable004.L1CacheHandle, 4) + 'h';
              SMBIOSData.Add('L1 Cache Objektnummer=' +
                StringValue);

              if SMBIOSTable004.L2CacheHandle = $FFFF then
                StringValue := 'kein L2 Cache vorhanden'
              else
                StringValue := IntToHex(SMBIOSTable004.L2CacheHandle, 4) + 'h';
              SMBIOSData.Add('L2 Cache Objektnummer=' +
                StringValue);

              if SMBIOSTable004.L3CacheHandle = $FFFF then
                StringValue := 'kein L3 Cache vorhanden'
              else
                StringValue := IntToHex(SMBIOSTable004.L3CacheHandle, 4) + 'h';
              SMBIOSData.Add('L3 Cache Objektnummer=' +
                StringValue);
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 23) then
            begin
              SMBIOSData.Add('Seriennummer=' +
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable004.SerialNumberStr)));

              SMBIOSData.Add('Asset-Kennzeichnung=' +
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable004.AssetTagStr)));

              SMBIOSData.Add('Teilenummer=' +
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable004.PartNumberStr)));
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 25) then
            begin
              if SMBIOSTable004.CoreCount <> 0 then
                StringValue := IntToStr(SMBIOSTable004.CoreCount)
              else
                StringValue := 'unbekannt';
              SMBIOSData.Add('Anzahl Kerne=' +
                StringValue);

              if SMBIOSTable004.CoreEnabled <> 0 then
                StringValue := IntToStr(SMBIOSTable004.CoreEnabled)
              else
                StringValue := 'unbekannt';
              SMBIOSData.Add('Aktive Kerne=' +
                StringValue);

              if SMBIOSTable004.ThreadCount <> 0 then
                StringValue := IntToStr(SMBIOSTable004.ThreadCount)
              else
                StringValue := 'unbekannt';
              SMBIOSData.Add('Threads pro Prozessor=' +
                StringValue);

              SMBIOSData.Add('');
              SMBIOSData.Add('Prozessor-Charakteristiken=');

              SMBIOSData.Add('- 64 Bit Fähigkeit=' +
                YesNo(IsBitOn(SMBIOSTable004.ProcessorCharacterics, 2)));

              SMBIOSData.Add('- Multi-Core=' +
                YesNo(IsBitOn(SMBIOSTable004.ProcessorCharacterics, 3)));

              SMBIOSData.Add('- Hardware Thread=' +
                YesNo(IsBitOn(SMBIOSTable004.ProcessorCharacterics, 4)));

              SMBIOSData.Add('- Ausführungsverhinderung=' +
                YesNo(IsBitOn(SMBIOSTable004.ProcessorCharacterics, 5)));

              SMBIOSData.Add('- Erweiterte Virtualisierung=' +
                YesNo(IsBitOn(SMBIOSTable004.ProcessorCharacterics, 6)));

              SMBIOSData.Add('- Strom-/Geschwindigkeitskontrolle=' +
                YesNo(IsBitOn(SMBIOSTable004.ProcessorCharacterics, 7)));

              SMBIOSData.Add('- 128 Bit Fähigkeit=' +
                YesNo(IsBitOn(SMBIOSTable004.ProcessorCharacterics, 8)));

              SMBIOSData.Add('- Arm64 SoC-Kennung=' +
                YesNo(IsBitOn(SMBIOSTable004.ProcessorCharacterics, 9)));
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 26) then
            begin
              SMBIOSData.Add('Prozessor-Familie 2=' +
                GetSMBIOS004_ProcessorFamily2(SMBIOSTable004.ProcessorFamily2));
            end;

            if FHeader.MajorVersion >= 3 then
            begin
              SMBIOSData.Add('');

              case SMBIOSTable004.CoreCount2 of
                $0000 : StringValue := 'unbekannt';
                $FFFF : StringValue := 'reserviert';
                $0011..
                $00FF : StringValue := IntToStr(SMBIOSTable004.CoreCount2) +
                                       ' (passend zum Feld "Anzahl Kerne")';
                else    StringValue := IntToStr(SMBIOSTable004.CoreCount2);
              end;
              SMBIOSData.Add('Anzahl Kerne 2=' +
                StringValue);

              case SMBIOSTable004.CoreEnabled2 of
                $0000 : StringValue := 'unbekannt';
                $FFFF : StringValue := 'reserviert';
                $0011..
                $00FF : StringValue := IntToStr(SMBIOSTable004.CoreEnabled2) +
                                       ' (passend zum Feld "Aktive Kerne")';
                else    StringValue := IntToStr(SMBIOSTable004.CoreEnabled2);
              end;
              SMBIOSData.Add('Aktive Kerne 2=' +
                StringValue);

              case SMBIOSTable004.ThreadCount2 of
                $0000 : StringValue := 'unbekannt';
                $FFFF : StringValue := 'reserviert';
                $0011..
                $00FF : StringValue := IntToStr(SMBIOSTable004.ThreadCount2) +
                                       ' (passend zum Feld "Threads pro Prozessor")';
                else    StringValue := IntToStr(SMBIOSTable004.ThreadCount2);
              end;
              SMBIOSData.Add('Threads pro Prozessor 2=' +
                StringValue);
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 36) then
            begin
              case SMBIOSTable004.ThreadEnabled of
                $0000 : StringValue := 'unbekannt';
                $FFFF : StringValue := 'reserviert';
                else    StringValue := IntToStr(SMBIOSTable004.ThreadEnabled);
              end;
              SMBIOSData.Add('Aktive Threads=' +
                StringValue);
            end;
          end;
        SMB_CACHE : //Cache Information
          begin
            SMBIOSTable007 := @FData[FTables[TableCount].Offset];
            StringPosition := FTables[TableCount].Offset +
                              FTables[TableCount].Header.Length;

            if SMBIOSData.Count > 0 then
              SMBIOSData.Add('');

            SMBIOSData.Add('Sockel-Bezeichnung=' +
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable007.SocketDesignationStr)));

            SMBIOSData.Add('');
            SMBIOSData.Add('Cache-Konfiguration=');

            case ((SMBIOSTable007.CacheConfiguration shr 8) and 3) of
              0 : StringValue := 'Write Through-Modus';
              1 : StringValue := 'Write Back-Modus';
              2 : StringValue := 'variiert mit Speicherzugriff';
              3 : StringValue := 'unbekannt';
            end;
            SMBIOSData.Add('- Operationsmodus=' +
              StringValue);

            SMBIOSData.Add('- Aktiv während Boot=' +
              YesNo(IsBitOn(SMBIOSTable007.CacheConfiguration, 7)));

            case ((SMBIOSTable007.CacheConfiguration shr 5) and 3) of
              0 : StringValue := 'intern';
              1 : StringValue := 'extern';
              2 : StringValue := 'reserviert';
              3 : StringValue := 'unbekannt';
            end;
            SMBIOSData.Add('- Position relativ zum CPU-Modul=' +
              StringValue);

            SMBIOSData.Add('- Cache gesockelt=' +
              YesNo(IsBitOn(SMBIOSTable007.CacheConfiguration, 3)));

            SMBIOSData.Add('- Cache-Level=' +
              'L' + IntToStr((SMBIOSTable007.CacheConfiguration and 7) + 1));

            SMBIOSData.Add('');
            SMBIOSData.Add('Maximale Cachegröße=');

            if IsBitOn(SMBIOSTable007.MaximumCacheSize, 15) then
            begin
              WordValue := 64;
              Stringvalue := '64 KByte';
            end
            else
            begin
              WordValue := 1;
              Stringvalue := '1 KByte';
            end;
            SMBIOSData.Add('- Granularität=' +
              StringValue);

            CardinalValue := SMBIOSTable007.MaximumCacheSize and $7FFF;
            if CardinalValue = 0 then
              StringValue := 'unbekannt'
            else
            begin
              CardinalValue := CardinalValue * WordValue;
              StringValue := IntToStr(CardinalValue) + ' KByte';
            end;
            SMBIOSData.Add('- Maximale Größe=' +
              StringValue);

            SMBIOSData.Add('');
            SMBIOSData.Add('Installierte Cachegröße=');

            if IsBitOn(SMBIOSTable007.InstalledSize, 15) then
            begin
              WordValue := 64;
              Stringvalue := '64 KByte';
            end
            else
            begin
              WordValue := 1;
              Stringvalue := '1 KByte';
            end;
            SMBIOSData.Add('- Granularität=' +
              StringValue);

            CardinalValue := SMBIOSTable007.InstalledSize and $7FFF;
            if CardinalValue = 0 then
              StringValue := 'unbekannt'
            else
            begin
              CardinalValue := CardinalValue * WordValue;
              StringValue := IntToStr(CardinalValue) + ' KByte';
            end;
            SMBIOSData.Add('- Installierte Größe=' +
              StringValue);

            SMBIOSData.Add('');

            SMBIOSData.Add('Unterstützter SRAM-Typ=' +
              GetSMBIOS007_CacheSRAMType(SMBIOSTable007.SupportedSRAMType));

            SMBIOSData.Add('Aktueller SRAM-Typ=' +
              GetSMBIOS007_CacheSRAMType(SMBIOSTable007.CurrentSRAMType));

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 21) then
            begin
              if SMBIOSTable007.CacheSpeed = 0 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable007.CacheSpeed) + ' ns';
              SMBIOSData.Add('Cache-Geschwindigkeit=' +
                StringValue);

              SMBIOSData.Add('Fehlerkorrekturtyp=' +
                GetSMBIOS007_ErrorCorrectionType(SMBIOSTable007.ErrorCorrectionType));

              SMBIOSData.Add('System Cache-Typ=' +
                GetSMBIOS007_SystemCacheType(SMBIOSTable007.SystemCacheType));

              SMBIOSData.Add('Assoziativität=' +
                GetSMBIOS007_Associativity(SMBIOSTable007.Associativity));
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 31) then
            begin
              SMBIOSData.Add('');
              SMBIOSData.Add('Maximale Cachegröße 2=');

              if IsBitOn(SMBIOSTable007.MaximumCacheSize2, 31) then
              begin
                WordValue := 64;
                Stringvalue := '64 KByte';
              end
              else
              begin
                WordValue := 1;
                Stringvalue := '1 KByte';
              end;
              SMBIOSData.Add('- Granularität=' +
                StringValue);

              CardinalValue := SMBIOSTable007.MaximumCacheSize2 and $FFFFFFFE;
              if CardinalValue = 0 then
                StringValue := 'unbekannt'
              else
              begin
                CardinalValue := CardinalValue * WordValue;
                StringValue := IntToStr(CardinalValue) + ' KByte';
              end;
              SMBIOSData.Add('- Maximale Größe=' +
                StringValue);

              SMBIOSData.Add('');
              SMBIOSData.Add('Installierte Cachegröße 2=');

              if IsBitOn(SMBIOSTable007.InstalledCacheSize2, 31) then
              begin
                WordValue := 64;
                Stringvalue := '64 KByte';
              end
              else
              begin
                WordValue := 1;
                Stringvalue := '1 KByte';
              end;
              SMBIOSData.Add('- Granularität=' +
                StringValue);

              CardinalValue := SMBIOSTable007.InstalledCacheSize2 and $FFFFFFFE;
              if CardinalValue = 0 then
                StringValue := 'unbekannt'
              else
              begin
                CardinalValue := CardinalValue * WordValue;
                StringValue := IntToStr(CardinalValue) + ' KByte';
              end;
              SMBIOSData.Add('- Installierte Größe=' +
                StringValue);
            end;
          end;
        SMB_PORTCON : //Port Connector Information
          begin
            SMBIOSTable008 := @FData[FTables[TableCount].Offset];
            StringPosition := FTables[TableCount].Offset +
                              FTables[TableCount].Header.Length;

            if SMBIOSData.Count > 0 then
              SMBIOSData.Add('');

            SMBIOSData.Add('Interne Referenz-Bezeichnung=' +
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable008.InternalReferenceDesignatorStr)));

            SMBIOSData.Add('Interner Anschlußtyp=' +
              GetSMBIOS008_ConnectorType(SMBIOSTable008.InternalConnectorType));

            SMBIOSData.Add('Externe Referenz-Bezeichnung=' +
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable008.ExternalReferenceDesignatorStr)));

            SMBIOSData.Add('Externer Anschlußtyp=' +
              GetSMBIOS008_ConnectorType(SMBIOSTable008.ExternalConnectorType));

            SMBIOSData.Add('Schnittstellentyp=' +
              GetSMBIOS008_PortType(SMBIOSTable008.PortType));
          end;
        SMB_SLOTS : //System Slots
          begin
            SMBIOSTable009 := @FData[FTables[TableCount].Offset];
            StringPosition := FTables[TableCount].Offset +
                              FTables[TableCount].Header.Length;

            if SMBIOSData.Count > 0 then
              SMBIOSData.Add('');

            SMBIOSData.Add('Steckplatz-Bezeichnung=' +
              CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable009.SlotDesignationStr)));

            SMBIOSData.Add('Steckplatz-Typ=' +
              GetSMBIOS009_SlotType(SMBIOSTable009.SlotType));

            SMBIOSData.Add('Steckplatz-Datenbusbreite=' +
              GetSMBIOS009_SlotDataBusWidth(SMBIOSTable009.SlotDataBusWidth));

            case SMBIOSTable009.CurrentUsage of
              $01 : StringValue := 'andere';
              $02 : StringValue := 'unbekannt';
              $03 : StringValue := 'verfügbar';
              $04 : StringValue := 'benutzt';
              $05 : StringValue := 'nicht verfügbar';
              else  StringValue := 'unbekannter Typ (' + IntToHex(SMBIOSTable009.CurrentUsage, 2) + 'h)';
            end;
            SMBIOSData.Add('Aktuelle Benutzung=' +
              StringValue);

            case SMBIOSTable009.SlotLength of
              $01 : StringValue := 'andere';
              $02 : StringValue := 'unbekannt';
              $03 : StringValue := 'kurze Länge';
              $04 : StringValue := 'lange Länge';
              $05 : StringValue := '2.5" Formfaktor für Laufwerke';
              $06 : StringValue := '3.5" Formfaktor für Laufwerke';
              else  StringValue := 'unbekannter Typ (' + IntToHex(SMBIOSTable009.SlotLength, 2) + 'h)';
            end;
            SMBIOSData.Add('Steckplatz-Länge=' +
              StringValue);

            SMBIOSData.Add('Steckplatz-ID=' +
              IntToHex(SMBIOSTable009.SlotID, 4) + 'h');

            SMBIOSData.Add('');
            SMBIOSData.Add('Steckplatz-Eigenschaften 1=');

            if IsBitOn(SMBIOSTable009.SlotCharacteristics1, 0) then
              SMBIOSData.Add('- Eigenschaften unbekannt=');

            if IsBitOn(SMBIOSTable009.SlotCharacteristics1, 1) then
              SMBIOSData.Add('- bietet 5.0 Volt=');

            if IsBitOn(SMBIOSTable009.SlotCharacteristics1, 2) then
              SMBIOSData.Add('- bietet 3.3 Volt=');

            if IsBitOn(SMBIOSTable009.SlotCharacteristics1, 3) then
              SMBIOSData.Add('- Steckplatz-Öffnung wird mit anderem Steckplatz geteilt=');

            if IsBitOn(SMBIOSTable009.SlotCharacteristics1, 4) then
              SMBIOSData.Add('- PC Card Steckplatz unterstützt PC Card-16=');

            if IsBitOn(SMBIOSTable009.SlotCharacteristics1, 5) then
              SMBIOSData.Add('- PC Card Steckplatz unterstützt CardBus=');

            if IsBitOn(SMBIOSTable009.SlotCharacteristics1, 6) then
              SMBIOSData.Add('- PC Card Steckplatz unterstützt Zoom Video=');

            if IsBitOn(SMBIOSTable009.SlotCharacteristics1, 7) then
              SMBIOSData.Add('- PC Card Steckplatz unterstützt Modem Ring-Fortsetzung=');

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 21) then
            begin
              SMBIOSData.Add('');
              SMBIOSData.Add('Steckplatz-Eigenschaften 2=');

              if IsBitOn(SMBIOSTable009.SlotCharacteristics2, 0) then
                SMBIOSData.Add('- PCI Steckplatz unterstützt Power Management-Signal (PME)=');

              if IsBitOn(SMBIOSTable009.SlotCharacteristics2, 1) then
                SMBIOSData.Add('- Steckplatz unterstützt Hot-Plug Geräte=');

              if IsBitOn(SMBIOSTable009.SlotCharacteristics2, 2) then
                SMBIOSData.Add('- PCI Steckplatz unterstützt SMBus-Signal=');

              if IsBitOn(SMBIOSTable009.SlotCharacteristics2, 3) then
                SMBIOSData.Add('- PCIe Steckplatz unterstützt Bifurkation=');

              if IsBitOn(SMBIOSTable009.SlotCharacteristics2, 4) then
                SMBIOSData.Add('- Steckplatz unterstützt asynchrones/überraschendes Entfernen=');

              if IsBitOn(SMBIOSTable009.SlotCharacteristics2, 5) then
                SMBIOSData.Add('- Flexbus Steckplatz, CXL 1.0 fähig=');

              if IsBitOn(SMBIOSTable009.SlotCharacteristics2, 6) then
                SMBIOSData.Add('- Flexbus Steckplatz, CXL 2.0 fähig=');
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 26) then
            begin
              SMBIOSData.Add('');

              SMBIOSData.Add('Segmentgruppennummer (Basis)=' +
                IntToHex(SMBIOSTable009.SegmentGroupNumber, 4) + 'h');

              SMBIOSData.Add('Bus:Gerät:Funktion (Basis)=' +
                IntToStr(SMBIOSTable009.BusNumber) + ':' +
                IntToStr(SMBIOSTable009.DeviceFunctionNumber shr 3) + ':' +
                IntToStr(SMBIOSTable009.DeviceFunctionNumber and 7));
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 32) then
            begin
              SMBIOSData.Add('Datenbusbreite (Basis)=' +
                IntToStr(SMBIOSTable009.DataBusWidth));

              SMBIOSData.Add('Peer-Gruppenanzahl (Basis)=' +
                IntToStr(SMBIOSTable009.PeerGroupingCount));

              if (SMBIOSTable009.PeerGroupingCount > 0) and
                 (FTables[TableCount].Header.Length >=
                  $13 + SMBIOSTable009.PeerGroupingCount * 5) then
              begin
                SetLength(SMBIOSTable009_PeerGroups, SMBIOSTable009.PeerGroupingCount);
                Move(FData[FTables[TableCount].Offset + $13],
                     SMBIOSTable009_PeerGroups[0],
                     SMBIOSTable009.PeerGroupingCount * 5);
                try
                  for Counter := 0 to SMBIOSTable009.PeerGroupingCount - 1 do
                  begin
                    SMBIOSData.Add('Peer-Gruppe ' + IntToStr(Counter + 1) + '=');

                    SMBIOSTable009_PeerGroups[Counter].SegmentGroupNumber :=
                      FData[FTables[TableCount].Offset + $13 + Cardinal(Counter) * SizeOf(TPeerGroup)];
                    SMBIOSData.Add('- Segmentgruppennummer=' +
                       IntToHex(SMBIOSTable009_PeerGroups[Counter].SegmentGroupNumber, 4) + 'h');

                    SMBIOSTable009_PeerGroups[Counter].BusNumber :=
                      FData[FTables[TableCount].Offset + $14 + Cardinal(Counter) * SizeOf(TPeerGroup)];
                    SMBIOSTable009_PeerGroups[Counter].DeviceFunctionNumber :=
                      FData[FTables[TableCount].Offset + $15 + Cardinal(Counter) * SizeOf(TPeerGroup)];
                    SMBIOSData.Add('- Bus:Gerät:Funktion=' +
                      IntToStr(SMBIOSTable009_PeerGroups[Counter].BusNumber) + ':' +
                      IntToStr(SMBIOSTable009_PeerGroups[Counter].DeviceFunctionNumber shr 3) + ':' +
                      IntToStr(SMBIOSTable009_PeerGroups[Counter].DeviceFunctionNumber and 7));

                    SMBIOSTable009_PeerGroups[Counter].DataBusWidth :=
                      FData[FTables[TableCount].Offset + $16 + Cardinal(Counter) * SizeOf(TPeerGroup)];
                    SMBIOSData.Add('- Breite=' +
                      IntToStr(SMBIOSTable009_PeerGroups[Counter].DataBusWidth));

                    SMBIOSData.Add('');
                  end;
                except
                  SetLength(SMBIOSTable009_PeerGroups, 0);
                end;
              end;
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 34) then
            begin
              SMBIOSData.Add('');
              SMBIOSData.Add('Weitere Steckplatz-Details=');

              SMBIOSTable009.SlotInformation :=
                FData[FTables[TableCount].Offset + $14 + SizeOf(TPeerGroup) * SMBIOSTable009.PeerGroupingCount];
              SMBIOSData.Add('Information=' +
                IntToStr(SMBIOSTable009.SlotInformation));

              SMBIOSTable009.SlotPhysicalWidth :=
                FData[FTables[TableCount].Offset + $15 + SizeOf(TPeerGroup) * SMBIOSTable009.PeerGroupingCount];
              SMBIOSData.Add('Physikalische Breite=' +
                IntToStr(SMBIOSTable009.SlotPhysicalWidth));

              SMBIOSTable009.SlotPitch :=
                FData[FTables[TableCount].Offset + $16 + SizeOf(TPeerGroup) * SMBIOSTable009.PeerGroupingCount];
              if SMBIOSTable009.SlotPitch = 0 then
                StringValue := 'nicht vergeben / unbekannt'
              else
                StringValue := FloatToStrF(SMBIOSTable009.SlotPitch / 100, ffNumber, 4, 3) + ' mm';
              SMBIOSData.Add('Pitch=' +
                StringValue);
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 35) then
            begin
              SMBIOSTable009.SlotHeight :=
                FData[FTables[TableCount].Offset + $18 + SizeOf(TPeerGroup) * SMBIOSTable009.PeerGroupingCount];
              case SMBIOSTable009.SlotHeight of
                00 : StringValue := 'nicht verfügbar';
                01 : StringValue := 'andere';
                02 : StringValue := 'unbekannt';
                03 : StringValue := 'vollständige Höhe';
                04 : StringValue := 'Niedrigprofil';
                else StringValue := 'unbekannte Höhe (' + IntToHex(SMBIOSTable009.SlotHeight, 2) + 'h)';
              end;
              SMBIOSData.Add('Höhe=' +
                StringValue);
            end;
          end;
        SMB_PHYSMEM : //Physical Memory Array
          begin
            SMBIOSTable016 := @FData[FTables[TableCount].Offset];

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 21) then
            begin
              if SMBIOSData.Count > 0 then
              SMBIOSData.Add('');

              SMBIOSData.Add('Position=' +
                GetSMBIOS016_Location(SMBIOSTable016.Location));

              SMBIOSData.Add('Benutzung=' +
                GetSMBIOS016_Use(SMBIOSTable016.Use));

              SMBIOSData.Add('Speicherfehlerkorrektur=' +
                GetSMBIOS016_ErrorCorrectionTypes(SMBIOSTable016.MemoryErrorCorrection));

              case SMBIOSTable016.MaximumCapacity of
                0         : StringValue := 'unbekannt';
                $80000000 : StringValue := 'siehe Feld "Erweiterte maximale Kapazität"';
                else
                  Unsigned64BitValue := SMBIOSTable016.MaximumCapacity;
                  StringValue := GetCapacity(Unsigned64BitValue * 1024);
              end;
              SMBIOSData.Add('Maximale Kapazität=' +
                StringValue);

              case SMBIOSTable016.MemoryErrorInformationHandle of
                $FFFE : StringValue := 'nicht unterstützt';
                $FFFF : StringValue := 'kein Fehler erkannt';
                else    StringValue := IntToHex(SMBIOSTable016.MemoryErrorInformationHandle, 4) + 'h';
              end;
              SMBIOSData.Add('Speicherfehler-Informationsinstanz=' +
                StringValue);

              SMBIOSData.Add('Anzahl Speichergeräte=' +
                IntToStr(SMBIOSTable016.NumberOfMemoryDevices));
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 27) then
            begin
              if SMBIOSTable016.MaximumCapacity = $80000000 then
                SMBIOSData.Add('Erweiterte maximale Kapazität=' +
                  GetCapacity(SMBIOSTable016.ExtendedMaximumCapacity));
            end;
          end;
        SMB_MEMDEV : //Memory Device
          begin
            SMBIOSTable017 := @FData[FTables[TableCount].Offset];
            StringPosition := FTables[TableCount].Offset +
                              FTables[TableCount].Header.Length;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 21) then
            begin
              if SMBIOSData.Count > 0 then
                SMBIOSData.Add('');

              SMBIOSData.Add('Physikalischer Speicherfeldinstanz=' +
                IntToHex(SMBIOSTable017.PhysicalMemoryArrayHandle, 4) + 'h');

              case SMBIOSTable017.MemoryErrorInformationHandle of
                $FFFE : StringValue := 'nicht unterstützt';
                $FFFF : StringValue := 'kein Fehler erkannt';
                else    StringValue := IntToHex(SMBIOSTable017.MemoryErrorInformationHandle, 4) + 'h';
              end;
              SMBIOSData.Add('Speicherfehler-Informationsinstanz=' +
                StringValue);

              if SMBIOSTable017.TotalWidth = $FFFF then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable017.TotalWidth) + ' Bit';
              SMBIOSData.Add('Gesamtbreite=' +
                StringValue);

              if SMBIOSTable017.DataWidth = $FFFF then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable017.DataWidth) + ' Bit';
              SMBIOSData.Add('Datenbreite=' +
                StringValue);

              SMBIOSData.Add('Größe=');
              case SMBIOSTable017.Size of
                $0000 : StringValue := 'kein Speichergerät im Sockel installiert';
                $7FFF : StringValue := 'siehe Feld "Erweiterte Größe"';
                $FFFF : StringValue := 'unbekannt';
                else
                  StringValue := IntToStr(SMBIOSTable017.Size);
                  if IsBitOn(SMBIOSTable017.Size, 15) then
                    StringValue := StringValue + ' KByte'
                  else
                    StringValue := StringValue + ' MByte';
              end;
              SMBIOSData.Add('- Größe=' +
                StringValue);

              if IsBitOn(SMBIOSTable017.Size, 15) then
                StringValue := 'KByte'
              else
                StringValue := 'MByte';
              SMBIOSData.Add('- Maßeineinheit=' +
                StringValue);

              SMBIOSData.Add('Formfaktor=' +
                GetSMBIOS017_FormFactor(SMBIOSTable017.FormFactor));

              case SMBIOSTable017.DeviceSet of
                $00 : StringValue := 'nein';
                $FF : StringValue := 'unbekannt';
                else  StringValue := 'ja, Gerätesatz-Nummer ' + IntToHex(SMBIOSTable017.DeviceSet, 2) + 'h';
              end;
              SMBIOSData.Add('Gerätesatz=' +
                StringValue);

              SMBIOSData.Add('Geräteposition=' +
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable017.DeviceLocatorStr)));

              SMBIOSData.Add('Bankposition=' +
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable017.BankLocatorStr)));

              SMBIOSData.Add('Speichertyp=' +
                GetSMBIOS017_MemoryType(SMBIOSTable017.MemoryType));

              SMBIOSData.Add('Typdetails=' +
                GetSMBIOS017_TypeDetail(SMBIOSTable017.TypeDetail));
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 23) then
            begin
              if SMBIOSTable017.Speed = 0 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable017.Speed) + ' MT/s';
              SMBIOSData.Add('Geschwindigkeit=' +
                StringValue);

              SMBIOSData.Add('Hersteller=' +
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable017.ManufacturerStr)));

              SMBIOSData.Add('Seriennummer=' +
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable017.SerialNumberStr)));

              SMBIOSData.Add('Asset-Kennzeichnung=' +
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable017.AssetTagStr)));

              SMBIOSData.Add('Teilenummer=' +
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable017.PartNumberStr)));
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 26) then
            begin
              SMBIOSData.Add('');
              SMBIOSData.Add('Attribute=');

              if (SMBIOSTable017.Attributes and 15) = 0 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable017.Attributes and 15);
              SMBIOSData.Add('- Rang=' +
                StringValue);
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 27) then
            begin
              if SMBIOSTable017.Size = $7FFF then
              begin
                CardinalValue := SMBIOSTable017.ExtendedSize and $7FFFFFFF;
                StringValue := GetCapacity(CardinalValue * 1024 * 1024);
                SMBIOSData.Add('Erweiterte Größe=' +
                  StringValue);
              end;

              if SMBIOSTable017.ConfiguredMemorySpeed = 0 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable017.ConfiguredMemorySpeed) + ' MT/s';
              SMBIOSData.Add('Konfigurierte Speichergeschwindigkeit=' +
                StringValue);
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 28) then
            begin
              if SMBIOSTable017.MinimumVoltage = 0 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable017.MinimumVoltage) + ' mVolt';
              SMBIOSData.Add('Minimale Spannung=' +
                StringValue);

              IF SMBIOSTable017.MaximumVoltage = 0 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable017.MaximumVoltage) + ' mVolt';
              SMBIOSData.Add('Maximale Spannung=' +
                StringValue);

              IF SMBIOSTable017.ConfiguredVoltage = 0 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable017.ConfiguredVoltage) + ' mVolt';
              SMBIOSData.Add('Konfigurierte Spannung=' +
                StringValue);
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 32) then
            begin
              SMBIOSData.Add('Speicher-Technologie=' +
                GetSMBIOS017_MemoryTechnology(SMBIOSTable017.MemoryTechnology));

              SMBIOSData.Add('Speicher-Betriebsmodus-Fähigkeit=' +
                GetSMBIOS017_MemoryOperatingModeCapability(SMBIOSTable017.MemoryOperatingModeCapability));

              SMBIOSData.Add('Firmware-Version=' +
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable017.FirmwareVersionStr)));

              IF SMBIOSTable017.ModuleManufacturerID = 0 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToHex(SMBIOSTable017.ModuleManufacturerID, 4) + 'h';
              SMBIOSData.Add('Modul-Hersteller-ID=' +
                StringValue);

              IF SMBIOSTable017.ModuleProductID = 0 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToHex(SMBIOSTable017.ModuleProductID, 4) + 'h';
              SMBIOSData.Add('Modul-Produkt-ID=' +
                StringValue);

              IF SMBIOSTable017.MemorySubsystemControllerManufacturerID = 0 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToHex(SMBIOSTable017.MemorySubsystemControllerManufacturerID, 4) + 'h';
              SMBIOSData.Add('Speicheruntersystem Kontroller-Hersteller-ID=' +
                StringValue);

              IF SMBIOSTable017.MemorySubsystemControllerProductID = 0 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToHex(SMBIOSTable017.MemorySubsystemControllerProductID, 4) + 'h';
              SMBIOSData.Add('Speicheruntersystem Kontroller-Produkt-ID=' +
                StringValue);

              if SMBIOSTable017.NonVolatileSize = 0 then
                StringValue := 'nicht vorhanden' else
              if SMBIOSTable017.NonVolatileSize = $FFFFFFFFFFFFFFFF  then
                StringValue := 'unbekannt' else
              begin
                Unsigned64BitValue := SMBIOSTable017.NonVolatileSize;
                StringValue := GetCapacity(Unsigned64BitValue);
              end;
              SMBIOSData.Add('Nicht-flüchtige Größe=' +
                StringValue);

              if SMBIOSTable017.VolatileSize = 0 then
                StringValue := 'nicht vorhanden' else
              if SMBIOSTable017.VolatileSize = $FFFFFFFFFFFFFFFF then
                StringValue := 'unbekannt' else
              begin
                Unsigned64BitValue := SMBIOSTable017.VolatileSize;
                StringValue := GetCapacity(Unsigned64BitValue);
              end;
              SMBIOSData.Add('Flüchtige Größe=' +
                StringValue);

              if SMBIOSTable017.CacheSize = 0 then
                StringValue := 'nicht vorhanden' else
              if SMBIOSTable017.CacheSize = $FFFFFFFFFFFFFFFF then
                StringValue := 'unbekannt' else
              begin
                Unsigned64BitValue := SMBIOSTable017.CacheSize;
                StringValue := GetCapacity(Unsigned64BitValue);
              end;
              SMBIOSData.Add('Cache-Größe=' +
                StringValue);

              if SMBIOSTable017.LogicalSize = 0 then
                StringValue := 'nicht vorhanden' else
              if SMBIOSTable017.LogicalSize = $FFFFFFFFFFFFFFFF then
                StringValue := 'unbekannt' else
              begin
                Unsigned64BitValue := SMBIOSTable017.LogicalSize;
                StringValue := GetCapacity(Unsigned64BitValue);
              end;
              SMBIOSData.Add('Logische Größe=' +
                StringValue);
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 33) then
            begin
              if SMBIOSTable017.Speed = $FFFF then
              begin
                if SMBIOSTable017.ExtendedSpeed = 0 then
                  StringValue := 'unbekannt'
                else
                  StringValue := IntToStr(SMBIOSTable017.ExtendedSpeed and $7FFFFFFF) + ' MT/s';
                SMBIOSData.Add('Erweiterte Geschwindigkeit=' +
                  StringValue);
              end;

              if SMBIOSTable017.ConfiguredMemorySpeed = $FFFF then
              begin
                if SMBIOSTable017.ExtendedConfiguredMemorySpeed = 0 then
                  StringValue := 'unbekannt'
                else
                  StringValue := IntToStr(SMBIOSTable017.ExtendedConfiguredMemorySpeed and $7FFFFFFF) + ' MT/s';
                SMBIOSData.Add('Erweiterte konfigurierte Speichergeschwindigkeit=' +
                  StringValue);
              end;
            end;
          end;
        SMB_VOLTAGE : //Voltage Probe
          begin
            SMBIOSTable026 := @FData[FTables[TableCount].Offset];
            StringPosition := FTables[TableCount].Offset +
                              FTables[TableCount].Header.Length;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 22) then
            begin
              if SMBIOSData.Count > 0 then
                SMBIOSData.Add('');

              SMBIOSData.Add('Beschreibung=' +
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable026.DescriptionStr)));

              SMBIOSData.Add('');
              SMBIOSData.Add('Position und Status=');

              SMBIOSData.Add('- Position=' +
                GetSMBIOS026_Location(SMBIOSTable026.LocationAndStatus and 31));

              SMBIOSData.Add('- Status=' +
                GetSMBIOS026_Status((SMBIOSTable026.LocationAndStatus shr 5) and 7));

              if SMBIOSTable026.MaximumValue = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable026.MaximumValue) + ' mVolt';
              SMBIOSData.Add('Maximalwert=' +
                StringValue);

              if SMBIOSTable026.MinimumValue = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable026.MinimumValue) + ' mVolt';
              SMBIOSData.Add('Minimalwert=' +
                StringValue);

              if SMBIOSTable026.Resolution = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable026.Resolution * 10) + ' mVolt';
              SMBIOSData.Add('Auflösung=' +
                StringValue);

              if SMBIOSTable026.Tolerance = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable026.Tolerance) + ' +/- mVolt';
              SMBIOSData.Add('Toleranz=' +
                StringValue);

              if SMBIOSTable026.Accuracy = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable026.Accuracy * 100) + ' +/- Prozent';
              SMBIOSData.Add('Genauigkeit=' +
                StringValue);

              SMBIOSData.Add('OEM-spezifisch=' +
                IntToHex(SMBIOSTable026.OEMDefined, 8) + 'h');

              if SMBIOSTable026.NominalValue = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable026.NominalValue) + ' mVolt';
              SMBIOSData.Add('Nominalwert=' +
                StringValue);
            end;
          end;
        SMB_COOL : //Cooling Device
          begin
            SMBIOSTable027 := @FData[FTables[TableCount].Offset];
            StringPosition := FTables[TableCount].Offset +
                              FTables[TableCount].Header.Length;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 22) then
            begin
              if SMBIOSData.Count > 0 then
                SMBIOSData.Add('');

              if SMBIOSTable027.TemperatureProbeHandle = $FFFF then
                StringValue := 'kein Sensor verfügbar'
              else
                StringValue := IntToHex(SMBIOSTable027.TemperatureProbeHandle, 4) + 'h';
              SMBIOSData.Add('Temperatur-Sensorinstanz=' +
                StringValue);

              SMBIOSData.Add('');
              SMBIOSData.Add('Gerätetyp und Status=');

              SMBIOSData.Add('- Gerätetyp=' +
                GetSMBIOS027_DeviceType(SMBIOSTable027.DeviceTypeAndStatus and 31));

              SMBIOSData.Add('- Status=' +
                GetSMBIOS027_Status((SMBIOSTable027.DeviceTypeAndStatus shr 5) and 7));

              SMBIOSData.Add('Gruppe der Kühlungseinheit=' +
                IntToStr(SMBIOSTable027.CoolingUnitGroup));

              SMBIOSData.Add('OEM-spezifisch=' +
                IntToHex(SMBIOSTable027.OEMDefined, 8) + 'h');

              if SMBIOSTable027.NominalSpeed = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable027.NominalSpeed) + ' UPM (Umdrehungen pro Minute)';
              SMBIOSData.Add('Nominalgeschwindigkeit=' +
                StringValue);
            end;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 27) then
            begin
              SMBIOSData.Add('Beschreibung=' +
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable027.DescriptionStr)));
            end;
          end;
        SMB_TEMP : //Tempature Probe
          begin
            SMBIOSTable028 := @FData[FTables[TableCount].Offset];
            StringPosition := FTables[TableCount].Offset +
                              FTables[TableCount].Header.Length;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 22) then
            begin
              if SMBIOSData.Count > 0 then
                SMBIOSData.Add('');

              SMBIOSData.Add('Beschreibung=' +
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable028.DescriptionStr)));

              SMBIOSData.Add('');
              SMBIOSData.Add('Position und Status=');

              SMBIOSData.Add('- Position=' +
                GetSMBIOS028_Location(SMBIOSTable028.LocationAndStatus and 31));

              SMBIOSData.Add('- Status=' +
                GetSMBIOS028_Status((SMBIOSTable028.LocationAndStatus shr 5) and 7));

              if SMBIOSTable028.MaximumValue = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable028.MaximumValue * 10) + ' Grad C';
              SMBIOSData.Add('Maximalwert=' +
                StringValue);

              if SMBIOSTable028.MinimumValue = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable028.MinimumValue * 10) + ' Grad C';
              SMBIOSData.Add('Minimalwert=' +
                StringValue);

              if SMBIOSTable028.Resolution = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable028.Resolution * 1000) + ' Grad C';
              SMBIOSData.Add('Auflösung=' +
                StringValue);

              if SMBIOSTable028.Tolerance = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable028.Tolerance * 10) + ' +/- Grad C';
              SMBIOSData.Add('Toleranz=' +
                StringValue);

              if SMBIOSTable028.Accuracy = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable028.Accuracy * 100) + ' +/- Prozent';
              SMBIOSData.Add('Genauigkeit=' +
                StringValue);

              SMBIOSData.Add('OEM-spezifisch=' +
                IntToHex(SMBIOSTable028.OEMDefined, 8) + 'h');

              if SMBIOSTable028.NominalValue = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable028.NominalValue * 10) + ' Grad C';
              SMBIOSData.Add('Nominalwert=' +
                StringValue);
            end;
          end;
        SMB_CURRENT : //Electrical Current Probe
          begin
            SMBIOSTable029 := @FData[FTables[TableCount].Offset];
            StringPosition := FTables[TableCount].Offset +
                              FTables[TableCount].Header.Length;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 22) then
            begin
              if SMBIOSData.Count > 0 then
                SMBIOSData.Add('');

              SMBIOSData.Add('Beschreibung=' +
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable029.DescriptionStr)));

              SMBIOSData.Add('');
              SMBIOSData.Add('Position und Status=');

              SMBIOSData.Add('- Position=' +
                GetSMBIOS029_Location(SMBIOSTable029.LocationAndStatus and 31));

              SMBIOSData.Add('- Status=' +
                GetSMBIOS029_Status((SMBIOSTable029.LocationAndStatus shr 5) and 7));

              if SMBIOSTable029.MaximumValue = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable029.MaximumValue) + ' mAmp';
              SMBIOSData.Add('Maximalwert=' +
                StringValue);

              if SMBIOSTable029.MinimumValue = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable029.MinimumValue) + ' mAmp';
              SMBIOSData.Add('Minimalwert=' +
                StringValue);

              if SMBIOSTable029.Resolution = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable029.Resolution * 10) + ' mAmp';
              SMBIOSData.Add('Auflösung=' +
                StringValue);

              if SMBIOSTable029.Tolerance = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable029.Tolerance) + ' +/- mAmp';
              SMBIOSData.Add('Toleranz=' +
                StringValue);

              if SMBIOSTable029.Accuracy = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable029.Accuracy * 100) + ' +/- Prozent';
              SMBIOSData.Add('Genauigkeit=' +
                StringValue);

              SMBIOSData.Add('OEM-spezifisch=' +
                IntToHex(SMBIOSTable029.OEMDefined, 8) + 'h');

              if SMBIOSTable029.NominalValue = $8000 then
                StringValue := 'unbekannt'
              else
                StringValue := IntToStr(SMBIOSTable029.NominalValue) + ' mAmp';
              SMBIOSData.Add('Nominalwert=' +
                StringValue);
            end;
          end;
        SMB_TPMDEV : //TPM Device
          begin
            SMBIOSTable043 := @FData[FTables[TableCount].Offset];
            StringPosition := FTables[TableCount].Offset +
                              FTables[TableCount].Header.Length;

            if (FHeader.MajorVersion * 10 + FHeader.MinorVersion >= 31) then
            begin
              if SMBIOSData.Count > 0 then
                SMBIOSData.Add('');

              SMBIOSData.Add('Hersteller-Kennung=' +
                Chr(SMBIOSTable043.VendorID[1]) +
                Chr(SMBIOSTable043.VendorID[2]) +
                Chr(SMBIOSTable043.VendorID[3]) +
                Chr(SMBIOSTable043.VendorID[4]));

              SMBIOSData.Add('Firmware-Version 1=' +
                IntToHex(SMBIOSTable043.FirmwareVersion1, 8) + 'h');

              SMBIOSData.Add('Firmware-Version 2=' +
                IntToHex(SMBIOSTable043.FirmwareVersion2, 8) + 'h');

              SMBIOSData.Add('Beschreibung=' +
                CheckIfEmptyString(ReadSMBIOSString(StringPosition, SMBIOSTable043.DescriptionStr)));

              SMBIOSData.Add('');
              SMBIOSData.Add('TPM-Geräteeigenschaften=');

              SMBIOSData.Add('- TPM-Geräteeigenschaften unterstützt='+
                YesNo(not IsBitOn(SMBIOSTable043.Characteristics, 2)));

              SMBIOSData.Add('- Familie konfigurierbar via Firmware-Update='+
                YesNo(IsBitOn(SMBIOSTable043.Characteristics, 3)));

              SMBIOSData.Add('- Familie konfigurierbar via Plattform Software Support='+
                YesNo(IsBitOn(SMBIOSTable043.Characteristics, 4)));

              SMBIOSData.Add('- Familie konfigurierbar via OEM proprietären Mechanismus='+
                YesNo(IsBitOn(SMBIOSTable043.Characteristics, 5)));

              SMBIOSData.Add('');
              SMBIOSData.Add('OEM-spezifisch=' +
                IntToHex(SMBIOSTable043.OEMDefined, 8) + 'h');
            end;
          end;
      end;
end;

end.
