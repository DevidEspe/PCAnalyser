{$WARN SYMBOL_PLATFORM OFF}

unit SystemAccess;

interface

uses
  WinAPI.Windows, Winapi.ShellAPI, WinAPI.WinSock, Winapi.WinSvc,
  System.Win.Registry, System.SysUtils, System.StrUtils, System.Math,
  System.Classes, Vcl.Dialogs, SystemDefinitions, WindowsClass,
  SMBIOSClass, ProcessorCacheAndFeatures;

type
  TProcessor = class;
  TPCIBus = class;
  TSMBus = class;

  Array8 = array [0..7] of Byte;

  TSystemAccess = class(TObject)
  private
    type
      DriverStatusValues = (NotInstalled,
                            Stopping,
                            Stopped,
                            Starting,
                            Running,
                            Pausing,
                            Paused,
                            Continued);

    var
      DriverStatus : DriverStatusValues;
      DriverHandle : THandle;
      fDriverName,
      fDriverFileName,
      fDriverFullPath : String;
      NtQuerySystemInformation : TNativeQuerySystemInformation;
      GetFirmwareEnvironmentVariable : TGetFirmwareEnvironmentVariable;
      NTDLLHandle,
      Kernel32Handle : THandle;
      IOCTL_PCANALYS_TransferTest,
      IOCTL_PCANALYS_Version,
      IOCTL_PCANALYS_ReadMSR,
      IOCTL_PCANALYS_WriteMSR,
      IOCTL_PCANALYS_ReadPCI,
      IOCTL_PCANALYS_WritePCI,
      IOCTL_PCANALYS_ReadMem8Bit,
      IOCTL_PCANALYS_ReadMem16Bit,
      IOCTL_PCANALYS_ReadMem32Bit,
      IOCTL_PCANALYS_WriteMem8Bit,
      IOCTL_PCANALYS_WriteMem16Bit,
      IOCTL_PCANALYS_WriteMem32Bit,
      IOCTL_PCANALYS_ReadPort8Bit,
      IOCTL_PCANALYS_ReadPort16Bit,
      IOCTL_PCANALYS_ReadPort32Bit,
      IOCTL_PCANALYS_WritePort8Bit,
      IOCTL_PCANALYS_WritePort16Bit,
      IOCTL_PCANALYS_WritePort32Bit : LongWord;
    const
      DEVICE_PCANALYS   = $8000;
      DEVICE_NAME       = 'PCANALYS';
      METHOD_BUFFERED   = 0;
      FILE_ANY_ACCESS   = 0;
      FILE_READ_ACCESS  = $0001;
      FILE_WRITE_ACCESS = $0002;
    function Generate_IOCTL(DeviceType, Func, Method, Access : Word) : DWord;
    procedure Generate_IOCTLs;
    function DriverSysErrorMessage(ErrorCode : Cardinal) : String;
    procedure ResetMemory(out P; Size: Longint);
  public
    WindowsClass : TWindows;
    ProcessorClass : TProcessor;
    SMBIOSClass : TSMBIOS;
    PCIBusClass : TPCIBus;
    SMBusClass : TSMBus;

    constructor Create;
    destructor Destroy; override;

    function GetCurrentUserName : String;
    function GetCurrentComputerName : String;
    function IsAdmin : Boolean;
    function IsElevated : Boolean;
    function RunAsAdmin(hWnd : HWND; AFilename, AParams : String) : Boolean;
    function ShellExecuteAndWaitW(hWnd : HWND; Operation, FileName,
                                  Parameters, Directory : PWideChar;
                                  ShowCmd : Integer; bWait : BOOL) : HINST; stdcall;
    function IsSystemCodeIntegrityEnabled : Boolean;
    function IsTestSigningModeEnabled : Boolean;
    function IsUEFISecureBoot : Boolean;
    function WindowsExit(AMode : Cardinal) : Boolean;
    function IsProcess32OnWin64(ProcessHandle : THandle) : Boolean;
    function FileExistsExt(Filename : String) : Boolean;
    function EnablePrivilege(Privilege : String) : Boolean;
    function DisablePrivileges : Boolean;
    function DisablePrivilege(Privilege : String) : Boolean;

    //Driver Management Functions
    function OpenServiceControlManager : THandle;
    function InstallKernelModeDriver(DrvName, DrvFileName : String; Var ErrorCode : Integer) : Boolean;
    function RemoveKernelModeDriver(DrvName : String; Var ErrorCode : Integer) : Boolean;
    function StartKernelModeDriver(DrvName : String; Var ErrorCode : Integer) : Boolean;
    function StopKernelModeDriver(DrvName : String; Var ErrorCode : Integer) : Boolean;
    function GetKernelModeDriverStatus(DrvName : String) : Integer;
    function GetKernelModeDriverConfig(DrvName : String; var ServiceConfig : TServiceConfig) : Boolean;
    function GetDriverName : String;
    function GetDriverFileName : String;
    function OpenDriver(Var ErrorCode : Integer) : Boolean;
    procedure CloseDriver;

    //Public Driver Functions connected to corresponding IOCTLs
    function Driver_GetVersion(Var OutputBuf : VersionOutputStruct) : Boolean;
    function Driver_TransferTest : Boolean;
    function Driver_ReadMSR (InputBuf : ReadMSRInputStruct; Var OutputBuf : ReadMSROutputStruct) : Boolean;
    function Driver_WriteMSR(InputBuf : WriteMSRInputStruct) : Boolean;
    function Driver_ReadPCI (InputBuf : ReadPCIInputStruct; Var OutputBuf : ReadPCIOutputStruct) : Boolean;
    function Driver_WritePCI(InputBuf : WritePCIInputStruct; Var OutputBuf : WritePCIOutputStruct) : Boolean;
    function Driver_ReadMem8Bit(InputBuf : ReadMemXBitInputStruct; Var OutputBuf : ReadMem8BitOutputStruct) : Boolean;
    function Driver_ReadMem16Bit(InputBuf : ReadMemXBitInputStruct; Var OutputBuf : ReadMem16BitOutputStruct) : Boolean;
    function Driver_ReadMem32Bit(InputBuf : ReadMemXBitInputStruct; Var OutputBuf : ReadMem32BitOutputStruct) : Boolean;
    function Driver_WriteMem8Bit(InputBuf : WriteMem8BitInputStruct) : Boolean;
    function Driver_WriteMem16Bit(InputBuf : WriteMem16BitInputStruct) : Boolean;
    function Driver_WriteMem32Bit(InputBuf : WriteMem32BitInputStruct) : Boolean;
    function Driver_ReadPort8Bit(InputBuf : ReadPortXBitInputStruct; Var OutputBuf : ReadPort8BitOutputStruct) : Boolean;
    function Driver_ReadPort16Bit(InputBuf : ReadPortXBitInputStruct; Var OutputBuf : ReadPort16BitOutputStruct) : Boolean;
    function Driver_ReadPort32Bit(InputBuf : ReadPortXBitInputStruct; Var OutputBuf : ReadPort32BitOutputStruct) : Boolean;
    function Driver_WritePort8Bit(InputBuf : WritePort8BitInputStruct) : Boolean;
    function Driver_WritePort16Bit(InputBuf : WritePort16BitInputStruct) : Boolean;
    function Driver_WritePort32Bit(InputBuf : WritePort32BitInputStruct) : Boolean;

    //Published Properties
    property DriverName : String read GetDriverName write fDriverName;
    property DriverFileName : String read GetDriverFileName write fDriverFileName;
    property DriverFullPath : String read fDriverFullPath write fDriverFullPath;
  end;

  TCpuVendor = (cvNone, cvUnknown, cvIntel, cvAmd, cvCyrix, cvIDT, cvNexGen,
                cvUMC, cvRise, cvSiS, cvGeode, cvTransmeta);
  TIntelBrand = (ibCeleron, ibPentium, ibXeon, ibMP, ibMobile, ibM, ibDuoCore, ibP4);
  TIntelBrands = set of TIntelBrand;
  TCacheLevel = (clLevel1Code, clLevel1Data, clLevel1Unified, clCodeTLB, clDataTLB, clUnifiedTLB,
                 clLevel2, clLevel3, clTrace, clNone);
  TCPUIDExecutionLevel = (celStandard, celExtended, celTransmeta);

  TProcessor = class(TObject)
  private
    type
      TGetLogicalProcessorInformation = function(Buffer : PSystemLogicalProcessorInformation;
                                                 var ReturnLength : DWord): Bool; stdcall;
      TGetLogicalProcessorInformationEx = function(RelationshipType : TLogicalProcessorRelationship;
                                                   Buffer : PSystemLogicalProcessorInformationEx;
                                                   var ReturnLength : DWord) : Bool; stdcall;
    var
    FParent : TSystemAccess;
    OldAffinity : DWord_Ptr;
    FCount,           //CPUCount
    FPC,              //CPUPhysicalCount
    FTC,              //ThreadCount
    FCC,              //CoreCount
    FCPP,             //CorePerPackage
    FLPP,             //LogicalPerPackage
    FLPC,             //LogicalPerCore
    FSC : Byte;       //SocketCount
    FMCPP,            //MaxCorePerPackage
    FMLPP,            //MaxLogicalPerPackage
    FMLPC : Cardinal; //MaxLogicalPerCore
    Kernel32Handle : THandle;
    GetLogicalProcessorInformation : TGetLogicalProcessorInformation;
    GetLogicalProcessorInformationEx : TGetLogicalProcessorInformationEx;
  public
    FCPUID,
    FfsStd, FfsStdExt, FfsExt,
    FfsStdPM, FfsExtPM,
    FfsAMDExt, FfsAMDSVM : TCPUIDRec;
    FIntelBrand: TIntelBrands;
    FCPUCache : TCPUCache;
    FCacheDescriptors : TCacheDescriptors;
    FCPUFeatures : TCPUFeatures;
    FSI : TSystemInfo;
    FArch : Word;
    FCPUType : Integer;
    FVendor : TCPUVendor;
    FFamily,
    FFamilyEx,
    FModel,
    FModelEx,
    FStepping,
    FSteppingEx,
    FBrand : Integer;
    FFreq: Double;
    FCPUName,
    FCodeName,
    FMarketingName,
    FGenericName,
    FRevision,
    FTech : String;

    //Class basic functions
    constructor Create(Parent : TSystemAccess);
    destructor Destroy; override;
    procedure Clear;

    //Cache functions
    function ValidDescriptor(Value : Cardinal) : Boolean;
    procedure DecodeDescriptor(Value : Cardinal; Index : Integer);
    function DescriptorExists(Value : Cardinal) : Boolean;
    function DecodeCacheParams(ACache : TCPUIDRec) : TCacheDetails;
    function LookupAssociativity(Value : Byte) : TCacheAssociativity;

    //Feature functions
    procedure GetAvailableFeatures(AFS : TFeatureSet; var AF : TAvailableFeatures);

    //CPU Name functions
    function GetCPUCodename(AIndex : Byte;
                            AVendor, AFamily, AModelEx, AStepping : Integer;
                            out AMCA, ACoreDesign, ARevision : String;
                            out ATechProcess : Integer) : Boolean;
    function StripSpaces(ASource : String) : String;
    function FormatCPUName(const AName : String) : String;
    function FormatString(AValue : Cardinal) : String;

    //Affinity functions
    procedure SetProcAffinity(FIndex : Byte);
    procedure RestoreProcAffinity;

    //CPUID functions
    function GetIntelBrand : TIntelBrands;
    function ExecuteCPUID(Cpu : Integer; FunctionID : Cardinal;
                          SubFunctionID : Cardinal = 0) : TCPUIDRec;
    function GetCPUIDMaximumCommand(Cpu : Byte; Level : TCPUIDExecutionLevel) : {$IFDEF WIN64}NativeUInt{$ELSE}Cardinal{$ENDIF};
    function GetCPUIDCommandLevel(Command : Cardinal) : TCPUIDExecutionLevel;
    function IsCPUIDCommandSupported(Cpu : Byte; Command : Cardinal) : Boolean;

    //Processor number functions
    function GetWinCPUNumbers : Byte;
    function GetCPUPhysicalCount : Byte;

    //Binary helper functions
    function HiDWord(AValue : UInt64) : Cardinal;
    function LoDWord(AValue : UInt64) : Cardinal;
    function IsBitOn(Value : UInt64; Bit : Byte) : Boolean;
    function YesNo(ABool : Boolean) : String;
    function GetBitsFromDWord(const aval : Cardinal; const afrom, ato : Byte) : Integer;
    function CountSetBits(ABitMask : NativeUInt) : DWord;

    //Main detection functions
    procedure GetProcessorDetails(FIndex : Byte);

    //MSR related functions
    function GetIntelAMD_MicrocodeUpdate : Cardinal;
    function GetIntelTjMax : Byte;

    //Properties
    property CPUPhysicalCount : Byte read FPC;
    property CorePerPackage : Byte read FCPP;
    property LogicalPerPackage : Byte read FLPP;
    property LogicalPerCore : Byte read FLPC;
    property ThreadCount : Byte read FTC;
    property CoreCount : Byte read FCC;
    property SocketCount : Byte read FSC;
    property MaxCorePerPackage : Cardinal read FMCPP;
    property MaxLogicalPerCore : Cardinal read FMLPC;
    property MaxLogicalPerPackage : Cardinal read FMLPP;
  end;

  TPCIBus = class(TObject)
  private
    FParent : TSystemAccess;
    FPCIDCount : Byte;
    FSMBusBaseAddress : Cardinal;
    FSMBusControllerName : String;
    PCIVendorList,
    PCIDeviceList,
    PCISubDeviceList : TStrings;
    const
      PCIVendorDatabase : String = 'PCIVendors.txt';
      PCIDeviceDatabase : String = 'PCIDevices.txt';
      PCISubDeviceDatabase : String = 'PCISubDevices.txt';
  public
    type
      TPCIDevice = record
        VendorID, DeviceID,
        SubVendorID, SubDeviceID : Word;
        Bus, Dev, Func, Rev,
        ClassID, SubClassID, PrgInt : Byte;
        PCIContent : Array [0..255] of Byte;
      end;
    var
      FPCIDevices : TArray<TPCIDevice>;

    //Class basic functions
    constructor Create(Parent : TSystemAccess);
    destructor Destroy; override;
    procedure Clear;

    //Core detection function
    function DetectPCIDevices : Boolean;
    function GetBaseClassName(AIndex : Integer) : String;
    function GetSubClassName(AIndex : Integer) : String;
    procedure GetSMBusBaseAddress;

    //PCI Database functions
    function PCIDatabasesAvailable : Boolean;
    function GetVendorString(Vendor : Word) : String;
    function GetDeviceString(Vendor, Device : Word; Revision : Byte) : String;
    function GetSubDeviceString(Vendor, Device : Word; Revision : Byte;
                                SubVendor, SubDevice : Word) : String;

    //Binary helper functions
    function HiDWord(AValue : UInt64) : Cardinal;
    function LoDWord(AValue : UInt64) : Cardinal;
    function IsBitOn(Value : UInt64; Bit : Byte) : Boolean;
    function YesNo(ABool : Boolean) : String;
    function ActiveInactive(ABool : Boolean) : String;

    //Published Properties
    property PCIDeviceCount : Byte read FPCIDCount write FPCIDCount;
    property SMBusBaseAddress : Cardinal read FSMBusBaseAddress write FSMBusBaseAddress;
    property SMBusControllerName : String read FSMBusControllerName write FSMBusControllerName;
    property PCIDatabases : Boolean read PCIDatabasesAvailable;
  end;

  TSMBus = class(TObject)
  private
    FParent : TSystemAccess;
    FSMBusBaseAddress : LongWord;
    FSMBusControllerName : String;
    FSMBUSMemoryDevices : Array8;
    FMutexHandle : THandle;
    FSID : PSID;
    FACL : PACL;
  public
    type
    TModuleInfo = record
      Manufacturer,
      Model        : String;
      Size         : Word;
      TypeDetail,
      SerialNumber : String;
      SPDData      : TArray<Byte>;
    end;

    //Class basic functions
    constructor Create(Parent : TSystemAccess);
    destructor Destroy; override;

    //SMBus core functions
    function SMBus_IsHostBusyStatus : Boolean;
    procedure SMBus_WaitForBusyStatus;
    procedure SMBus_WaitForReadyStatus;
    function SMBus_IsDeviceErrorOccurred : Boolean;
    function ReadDataByte(Adr, Reg : Byte) : Byte;
    function ReadDataWord(Adr, Reg : Byte) : Word;
    procedure WriteDataByte(Adr, Reg, Content : Byte);

    //DDR4/DDR5 Select page functions
    procedure DDR4_SelectSPDPage0;
    procedure DDR4_SelectSPDPage1;
    procedure DDR5_SelectSPDPage(Address, Page : Byte);
    function IsIntel_SPDWD : Boolean;

    //SMBus Mutex functions
    function CreateWorldMutex(MutexName : String) : Boolean;
    procedure ReleaseWorldMutex;

    //Core detection functions
    function GetSMBusMemoryModules : Array8;
    function GetMemoryModuleInfo(Address : Byte) : TModuleInfo;

    //SPD size functions
    function GetMemSize_FPMEDOSDRAM(Data : TArray<Byte>) : Word;
    function GetMemSize_DirectRambus(Data : TArray<Byte>) : Word;
    function GetMemSize_Rambus(Data : TArray<Byte>) : Word;
    function GetMemSize_SDRSDRAM(Data : TArray<Byte>) : Word;
    function GetMemSize_DDRSDRAM(Data : TArray<Byte>) : Word;
    function GetMemSize_DDR2SDRAM(Data : TArray<Byte>) : Word;
    function GetMemSize_DDR2SDRAMFBDIMM(Data : TArray<Byte>) : Word;
    function GetMemSize_DDR3SDRAM(Data : TArray<Byte>) : Word;
    function GetMemSize_DDR4SDRAM(Data : TArray<Byte>) : Word;
    function GetMemSize_DDR5SDRAM(Data : TArray<Byte>) : Word;

    //SPD interpretation functions
    procedure GetSPDDetails(Address : Byte; var SPDData : TStrings);
    procedure GetSPD_FPMEDODRAM(Data : TArray<Byte>; var SPDData : TStrings);
    procedure GetSPD_DDRSDRAM(Data : TArray<Byte>; var SPDData : TStrings);
    procedure GetSPD_DDR2SDRAM(Data : TArray<Byte>; var SPDData : TStrings);
    procedure GetSPD_DDR3SDRAM(Data : TArray<Byte>; var SPDData : TStrings);
    procedure GetSPD_DDR4SDRAM(Data : TArray<Byte>; var SPDData : TStrings);
    procedure GetSPD_DDR5SDRAM(Data : TArray<Byte>; var SPDData : TStrings);
    function GetMemoryModuleDetails(Module : TModuleInfo) : TModuleInfo;

    //Binary and text helper functions
    function HiDWord(AValue : UInt64) : Cardinal;
    function LoDWord(AValue : UInt64) : Cardinal;
    function IsBitOn(Value : UInt64; Bit : Byte) : Boolean;
    function Swap32(Value : LongWord) : LongWord;
    function GetNameFromStr(ASource : String; ASep : String = '=') : String;
    function GetValueFromStr(ASource : String; ASep : String = '=') : String;
    function GetCapacity(AValue : UInt64) : String;

    //Published Properties
    property SMBusBaseAddress : Cardinal read FSMBusBaseAddress write FSMBusBaseAddress;
    property SMBusControllerName : String read FSMBusControllerName write FSMBusControllerName;
    property MemoryDevices : Array8 read FSMBUSMemoryDevices write FSMBUSMemoryDevices;
  end;

const
  ctDataCache    = 1;
  ctCodeCache    = 2;
  ctUnifiedCache = 3;

implementation

uses
  ProcessorDB, JEDECVendors;

{ TSystemAccess }

function TSystemAccess.GetCurrentUserName : String;
var
  UserName : Cardinal;
  Buffer : PChar;
begin
  Result := '';
  UserName := 255;
  Buffer := StrAlloc(UserName);
  if GetUserName(Buffer, UserName) then
    Result := StrPas(Buffer);
  StrDispose(Buffer);
end;

function TSystemAccess.GetCurrentComputerName : String;
var
  ComputerName : Cardinal;
  Buffer : PChar;
begin
  Result := '';
  ComputerName := 255;
  Buffer := StrAlloc(ComputerName);
  if GetComputerName(Buffer, ComputerName) then
    Result := StrPas(Buffer);
  StrDispose(Buffer);
end;

function TSystemAccess.IsAdmin : Boolean;
const
  SECURITY_NT_AUTHORITY : TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
  SECURITY_BUILTIN_DOMAIN_RID = $00000020;
  DOMAIN_ALIAS_RID_ADMINS     = $00000220;
var
  Handle : THandle;
  PTG : PTokenGroups;
  ReturnedLength : Cardinal;
  psidAdmins : PSID;
  GroupCounter : Integer;
  BoolResult : Bool;
  AttributeChar : PAnsiChar;
  SIDAndAttr : TSIDAndAttributes;
begin
  Result := False;
  BoolResult := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True, Handle);
  if not BoolResult then
  begin
    if GetLastError = ERROR_NO_TOKEN then
      BoolResult := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, Handle);
  end;
  ReturnedLength := 0;
  if BoolResult then
  begin
    try
      GetTokenInformation(Handle, TokenGroups, nil, 0, ReturnedLength);
      GetMem(PTG, ReturnedLength);
      BoolResult := GetTokenInformation(Handle, TokenGroups, PTG, ReturnedLength, ReturnedLength);
    finally
      CloseHandle(Handle);
    end;
    try
      if BoolResult and
         AllocateAndInitializeSid(SECURITY_NT_AUTHORITY, 2,
                                  SECURITY_BUILTIN_DOMAIN_RID,
                                  DOMAIN_ALIAS_RID_ADMINS,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  psidAdmins) and
         (PTG.GroupCount > 0) then
        try
          AttributeChar := @(PTG.Groups[0]);
          for GroupCounter := 0 to PTG.GroupCount - 1 do
          begin
            SIDAndAttr := PSIDAndAttributes(AttributeChar)^;
            if EqualSid(psidAdmins, SIDAndAttr.Sid) then
            begin
              Result := True;
              Break;
            end;
            Inc(AttributeChar, SizeOf(SIDAndAttr));
          end;
        finally
          FreeSid(psidAdmins);
        end;
    finally
      FreeMem(PTG);
    end;
  end;
end;

function TSystemAccess.IsElevated : Boolean;
var
  Handle : THandle;
  TokenIsElevated,
  ReturnedLength : DWord;
begin
  OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, Handle);
  try
    ReturnedLength := 0;
    GetTokenInformation(Handle,
                        TokenElevation,
                        @TokenIsElevated,
                        SizeOf(TokenIsElevated),
                        ReturnedLength);
  finally
    CloseHandle(Handle);
  end;
  Result := TokenIsElevated <> 0;
end;

function TSystemAccess.RunAsAdmin(hWnd : HWND; AFilename, AParams : String) : Boolean;
var
  ShellExecuteInfo : TShellExecuteInfo;
begin
  ResetMemory(ShellExecuteInfo, SizeOf(ShellExecuteInfo));
  ShellExecuteInfo.cbSize := SizeOf(TShellExecuteInfo);
  ShellExecuteInfo.Wnd := hWnd;
  ShellExecuteInfo.fMask := SEE_MASK_FLAG_DDEWAIT or SEE_MASK_FLAG_NO_UI or SEE_MASK_UNICODE;
  ShellExecuteInfo.lpVerb := PChar('runas');
  ShellExecuteInfo.lpFile := PChar(AFilename);
  if AParams <> '' then
    ShellExecuteInfo.lpParameters := PChar(AParams);
  ShellExecuteInfo.nShow := SW_SHOWNORMAL;
  Result := ShellExecuteEx(@ShellExecuteInfo);
end;

procedure TSystemAccess.ResetMemory(out P; Size : Longint);
begin
  if Size > 0 then
  begin
    Byte(P) := 0;
    FillChar(P, Size, 0);
  end;
end;

function TSystemAccess.ShellExecuteAndWaitW(hWnd : HWND; Operation, FileName,
                                            Parameters, Directory : PWideChar;
                                            ShowCmd : Integer; bWait : BOOL) : HINST; StdCall;
var
  ShellExecuteInfo : TShellExecuteInfoW;
begin
  ResetMemory(ShellExecuteInfo, SizeOf(ShellExecuteInfo));
  ShellExecuteInfo.cbSize := SizeOf(ShellExecuteInfo);
  ShellExecuteInfo.Wnd := hWnd;
  ShellExecuteInfo.fMask := SEE_MASK_NOCLOSEPROCESS;
  ShellExecuteInfo.lpVerb := Operation;
  ShellExecuteInfo.lpFile := FileName;
  if Parameters <> '' then
    ShellExecuteInfo.lpParameters := Parameters;
  ShellExecuteInfo.lpDirectory := Directory;
  ShellExecuteInfo.nShow := ShowCmd;
  if ShellExecuteExW(@ShellExecuteInfo) then
  try
    if bWait then
      WaitForSingleObject(ShellExecuteInfo.hProcess, INFINITE);
  finally
    CloseHandle(ShellExecuteInfo.hProcess);
  end;
  Result := ShellExecuteInfo.hInstApp;
end;

function TSystemAccess.IsSystemCodeIntegrityEnabled : Boolean;
type
  TSystemCodeIntegrityInformation = record
    Length,
    CodeIntegrityOptions : ULong;
  end;
var
  SCII : TSystemCodeIntegrityInformation;
begin
  Result := False;

  if not Assigned(NtQuerySystemInformation) then
    Exit;
  SCII.Length := SizeOf(SCII);
  if NtQuerySystemInformation(SystemCodeIntegrityInformation, @SCII, SizeOf(SCII), nil) = S_OK then
    Result := (SCII.CodeIntegrityOptions and CODEINTEGRITY_OPTION_ENABLED) > 0;
end;

function TSystemAccess.IsTestSigningModeEnabled : Boolean;
type
  TSystemCodeIntegrityInformation = record
    Length,
    CodeIntegrityOptions : ULong;
  end;
var
  SCII : TSystemCodeIntegrityInformation;
begin
  Result := False;

  if not Assigned(NtQuerySystemInformation) then
    Exit;
  SCII.Length := SizeOf(SCII);
  if NtQuerySystemInformation(SystemCodeIntegrityInformation, @SCII, SizeOf(SCII), nil) = S_OK then
    Result := (SCII.CodeIntegrityOptions and CODEINTEGRITY_OPTION_TESTSIGN) > 0;
end;

function TSystemAccess.IsUEFISecureBoot : Boolean;
var
  pBuffer : Byte;
  nSize : Cardinal;
begin
  Result := False;
  if not Assigned(GetFirmwareEnvironmentVariable) then
    Exit;
  pBuffer := 0;
  nSize := SizeOf(pBuffer);
  if GetFirmwareEnvironmentVariable(
       PChar('SecureBoot'),
       PChar('{8be4df61-93ca-11d2-aa0d-00e098032b8c}'),
       @pBuffer,
       nSize) > 0 then
    Result := pBuffer = 1;
end;

function TSystemAccess.WindowsExit(AMode : Cardinal) : Boolean;
//AMode: EWX_POWEROFF - Power Off
//       EWX_REBOOT - Reboot
//       EWX_LOGOFF - LogOff
var
  th : THandle;
  tp1, tp2 : TTokenPrivileges;
  n, c : Cardinal;
  r : Boolean;
const
  SE_SHUTDOWN_NAME = 'SeShutdownPrivilege';
begin
  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    r := OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, th);
    if r then
    begin
      r := LookupPrivilegeValue(nil, SE_SHUTDOWN_NAME, tp1.Privileges[0].Luid);
      tp1.PrivilegeCount := 1;
      tp1.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
      n := SizeOf(tp1) ;
      c := 0;
      if r then
        AdjustTokenPrivileges(th, False, tp1, n, tp2, c);
    end;
  end;
  Result := ExitWindowsEx(AMode, 0);
end;

function TSystemAccess.IsProcess32OnWin64(ProcessHandle : THandle) : Boolean;
type
  TIsWow64Process = function(Handle : THandle; var Res : Bool) : Bool; stdcall;
var
  IsWow64Result : Bool;
  IsWow64Process : TIsWow64Process;
begin
  Result := False;
  IsWow64Process := GetProcAddress(GetModuleHandle(Winapi.Windows.kernel32), 'IsWow64Process');
  if Assigned(IsWow64Process) then
    if IsWow64Process(ProcessHandle, IsWow64Result) and IsWow64Result then
      Result := True;
end;

function TSystemAccess.FileExistsExt(Filename : String) : Boolean;
begin
  if (TOSVersion.Architecture in [arIntelX64, arARM64]) and
     (IsProcess32OnWin64(GetCurrentProcess)) then
    Filename := StringReplace(Filename, '\system32\', '\Sysnative\', [rfIgnoreCase]);
  Result := FileExists(Filename);
end;

function TSystemAccess.EnablePrivilege(Privilege : String) : Boolean;
var
  tp : TTOKENPRIVILEGES;
  th : THandle;
  n : Cardinal;
begin
  n := 0;
  tp.PrivilegeCount := 1;
  tp.Privileges[0].Luid := 0;
  tp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
  if OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES,  th) then
  begin
    if LookupPrivilegeValue(nil, PChar(Privilege), tp.Privileges[0].Luid) then
      AdjustTokenPrivileges(th, False, tp, SizeOf(TTOKENPRIVILEGES), nil, n);
    CloseHandle(th);
  end;
  Result := GetLastError = ERROR_SUCCESS;
end;

function TSystemAccess.DisablePrivileges : Boolean;
var
  tp : TOKEN_PRIVILEGES;
  th : THandle;
  n : Cardinal;
begin
  n := 0;
  tp.PrivilegeCount := 1;
  tp.Privileges[0].Luid := 0;
  tp.Privileges[0].Attributes := 0;
  if OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES, th) then
  begin
    AdjustTokenPrivileges(th, True, tp, SizeOf(TOKEN_PRIVILEGES), nil, n);
    CloseHandle(th);
  end;
  Result := GetLastError = ERROR_SUCCESS;
end;

function TSystemAccess.DisablePrivilege(Privilege : String) : Boolean;
var
  tp : TOKEN_PRIVILEGES;
  th : THandle;
  n : Cardinal;
begin
  n := 0;
  tp.PrivilegeCount := 1;
  tp.Privileges[0].Luid := 0;
  tp.Privileges[0].Attributes := 0;
  if OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES, th) then
  begin
    if LookupPrivilegeValue(nil, PChar(Privilege), tp.Privileges[0].Luid) then
      AdjustTokenPrivileges(th, True, tp, SizeOf(TOKEN_PRIVILEGES), nil, n);
    CloseHandle(th);
  end;
  Result := GetLastError = ERROR_SUCCESS;
end;

function TSystemAccess.GetDriverName : String;
begin
  if TOSVersion.Architecture in [arIntelX64, arARM64] then
    Result := 'PCANALYSx64'
  else
    Result := 'PCANALYSx86';
end;

function TSystemAccess.GetDriverFileName : String;
begin
  if TOSVersion.Architecture in [arIntelX64, arARM64] then
    Result := 'PCANALYSx64.sys'
  else
    Result := 'PCANALYSx86.sys';
end;

function TSystemAccess.Generate_IOCTL(DeviceType, Func, Method, Access : Word) : DWord;
begin
  Result := (DeviceType shl 16) or (Access shl 14) or (Func shl 2) or Method;
end;

procedure TSystemAccess.Generate_IOCTLs;
begin
  IOCTL_PCANALYS_TransferTest :=
    Generate_IOCTL(DEVICE_PCANALYS, $800, METHOD_BUFFERED, FILE_READ_ACCESS);
  IOCTL_PCANALYS_Version :=
    Generate_IOCTL(DEVICE_PCANALYS, $801, METHOD_BUFFERED, FILE_READ_ACCESS);
  IOCTL_PCANALYS_ReadMSR :=
    Generate_IOCTL(DEVICE_PCANALYS, $900, METHOD_BUFFERED, FILE_READ_ACCESS);
  IOCTL_PCANALYS_WriteMSR :=
    Generate_IOCTL(DEVICE_PCANALYS, $901, METHOD_BUFFERED, FILE_READ_ACCESS or FILE_WRITE_ACCESS);
  IOCTL_PCANALYS_ReadPCI :=
    Generate_IOCTL(DEVICE_PCANALYS, $902, METHOD_BUFFERED, FILE_READ_ACCESS);
  IOCTL_PCANALYS_WritePCI :=
    Generate_IOCTL(DEVICE_PCANALYS, $903, METHOD_BUFFERED, FILE_READ_ACCESS or FILE_WRITE_ACCESS);
  IOCTL_PCANALYS_ReadMem8Bit :=
    Generate_IOCTL(DEVICE_PCANALYS, $904, METHOD_BUFFERED, FILE_READ_ACCESS);
  IOCTL_PCANALYS_ReadMem16Bit :=
    Generate_IOCTL(DEVICE_PCANALYS, $905, METHOD_BUFFERED, FILE_READ_ACCESS);
  IOCTL_PCANALYS_ReadMem32Bit :=
    Generate_IOCTL(DEVICE_PCANALYS, $906, METHOD_BUFFERED, FILE_READ_ACCESS);
  IOCTL_PCANALYS_WriteMem8Bit :=
    Generate_IOCTL(DEVICE_PCANALYS, $907, METHOD_BUFFERED, FILE_READ_ACCESS or FILE_WRITE_ACCESS);
  IOCTL_PCANALYS_WriteMem16Bit :=
    Generate_IOCTL(DEVICE_PCANALYS, $908, METHOD_BUFFERED, FILE_READ_ACCESS or FILE_WRITE_ACCESS);
  IOCTL_PCANALYS_WriteMem32Bit :=
    Generate_IOCTL(DEVICE_PCANALYS, $909, METHOD_BUFFERED, FILE_READ_ACCESS or FILE_WRITE_ACCESS);
  IOCTL_PCANALYS_ReadPort8Bit :=
    Generate_IOCTL(DEVICE_PCANALYS, $90A, METHOD_BUFFERED, FILE_READ_ACCESS);
  IOCTL_PCANALYS_ReadPort16Bit :=
    Generate_IOCTL(DEVICE_PCANALYS, $90B, METHOD_BUFFERED, FILE_READ_ACCESS);
  IOCTL_PCANALYS_ReadPort32Bit :=
    Generate_IOCTL(DEVICE_PCANALYS, $90C, METHOD_BUFFERED, FILE_READ_ACCESS);
  IOCTL_PCANALYS_WritePort8Bit :=
    Generate_IOCTL(DEVICE_PCANALYS, $90D, METHOD_BUFFERED, FILE_READ_ACCESS or FILE_WRITE_ACCESS);
  IOCTL_PCANALYS_WritePort16Bit :=
    Generate_IOCTL(DEVICE_PCANALYS, $90E, METHOD_BUFFERED, FILE_READ_ACCESS or FILE_WRITE_ACCESS);
  IOCTL_PCANALYS_WritePort32Bit :=
    Generate_IOCTL(DEVICE_PCANALYS, $90F, METHOD_BUFFERED, FILE_READ_ACCESS or FILE_WRITE_ACCESS);
end;

function TSystemAccess.DriverSysErrorMessage(ErrorCode : Cardinal) : String;
const
  STATUS_UNSUCCESSFUL           = $C0000001;
  STATUS_INVALID_PARAMETER      = $C000000D;
  STATUS_INVALID_DEVICE_REQUEST = $C0000010;
  STATUS_ILLEGAL_INSTRUCTION    = $C000001D;
  STATUS_BUFFER_TOO_SMALL       = $C0000023;
begin
  case ErrorCode of
    STATUS_UNSUCCESSFUL           : Result := 'Not successful';
    STATUS_INVALID_PARAMETER      : Result := 'Invalid parameter';
    STATUS_INVALID_DEVICE_REQUEST : Result := 'Invalid device request';
    STATUS_ILLEGAL_INSTRUCTION    : Result := 'Illegal instruction';
    STATUS_BUFFER_TOO_SMALL       : Result := 'Input buffer to big/small';
    else
      if SysErrorMessage(ErrorCode) <> '' then
        Result := SysErrorMessage(ErrorCode)
      else
        Result := 'unknown Error';
  end;
end;

function TSystemAccess.InstallKernelModeDriver(DrvName, DrvFileName : String; Var ErrorCode : Integer) : Boolean;
var
  HandleServiceControlManager,
  ServiceHandle : THandle;
begin
  Result := False;
  ErrorCode := 0;
  HandleServiceControlManager := OpenServiceControlManager;
  if (HandleServiceControlManager > 0) and (HandleServiceControlManager <> INVALID_HANDLE_VALUE) then
  begin
    ServiceHandle := CreateService(HandleServiceControlManager,
                                   PChar(DrvName),
                                   PChar(DrvName),
                                   SERVICE_ALL_ACCESS,
                                   SERVICE_KERNEL_DRIVER,
                                   SERVICE_DEMAND_START,
                                   SERVICE_ERROR_NORMAL,
                                   PChar(DrvFileName),
                                   nil,
                                   nil,
                                   nil,
                                   nil,
                                   nil);
    ErrorCode := GetLastError;
    if ServiceHandle = 0 then
    begin
      CloseServiceHandle(HandleServiceControlManager);
      Exit;
    end
    else
      Result := True;
    CloseServiceHandle(HandleServiceControlManager);
    CloseServiceHandle(ServiceHandle);
  end;
end;

function TSystemAccess.StartKernelModeDriver(DrvName : String; Var ErrorCode : Integer) : Boolean;
var
  HandleServiceControlManager,
  ServiceHandle : THandle;
  ServiceArgVectors : PChar;
begin
  Result := False;
  ErrorCode := 0;
  HandleServiceControlManager := OpenServiceControlManager;
  if (HandleServiceControlManager > 0) and (HandleServiceControlManager <> INVALID_HANDLE_VALUE) then
  begin
    ServiceHandle := OpenService(HandleServiceControlManager,
                                 PChar(DrvName),
                                 SERVICE_ALL_ACCESS);
    ErrorCode := GetLastError;
    if (ServiceHandle = 0) or (ServiceHandle = INVALID_HANDLE_VALUE) then
    begin
      CloseServiceHandle(HandleServiceControlManager);
      Exit;
    end
    else
    begin
      ServiceArgVectors := nil;
      Result := StartService(ServiceHandle, 0, ServiceArgVectors);
      ErrorCode := GetLastError;
      if ServiceArgVectors <> nil then
        StrDispose(ServiceArgVectors);
    end;
    CloseServiceHandle(HandleServiceControlManager);
    CloseServiceHandle(ServiceHandle);
  end;

  if DriverName <> '' then
  begin
    case GetKernelModeDriverStatus(DriverName)of
      SERVICE_STOPPED          : DriverStatus := Stopped;      //The service is not running
      SERVICE_START_PENDING    : DriverStatus := Starting;     //The service is starting
      SERVICE_STOP_PENDING     : DriverStatus := Stopping;     //The service is stopping
      SERVICE_RUNNING          : DriverStatus := Running;      //The service is running
      SERVICE_CONTINUE_PENDING : DriverStatus := Continued;    //The service continue is pending
      SERVICE_PAUSE_PENDING    : DriverStatus := Pausing;      //The service pause is pending
      SERVICE_PAUSED           : DriverStatus := Paused;       //The service is paused
      else                       DriverStatus := NotInstalled; //The service is not installed
    end;
  end;

  if Result then
    Result := OpenDriver(ErrorCode);

  if Result then
    Generate_IOCTLs;
end;

function TSystemAccess.StopKernelModeDriver(DrvName : String; Var ErrorCode : Integer) : Boolean;
var
  HandleServiceControlManager,
  ServiceHandle : THandle;
  ServiceStatus : SERVICE_STATUS;
begin
  Result := False;
  ErrorCode := 0;

  CloseDriver;
  HandleServiceControlManager := OpenServiceControlManager;
  if (HandleServiceControlManager > 0) and (HandleServiceControlManager <> INVALID_HANDLE_VALUE) then
  begin
    ServiceHandle := OpenService(HandleServiceControlManager,
                                 PChar(DrvName),
                                 SERVICE_ALL_ACCESS);
    ErrorCode := GetLastError;
    if (ServiceHandle = 0) or (ServiceHandle = INVALID_HANDLE_VALUE) then
    begin
      CloseServiceHandle(HandleServiceControlManager);
      Exit;
    end
    else
    begin
      Result := ControlService(ServiceHandle,
                               SERVICE_CONTROL_STOP,
                               ServiceStatus);
      ErrorCode := GetLastError;
    end;
    CloseServiceHandle(HandleServiceControlManager);
    CloseServiceHandle(ServiceHandle);
  end;
end;

function TSystemAccess.RemoveKernelModeDriver(DrvName : String; Var ErrorCode : Integer) : Boolean;
var
  HandleServiceControlManager,
  ServiceHandle : THandle;
begin
  Result := False;
  ErrorCode := 0;
  HandleServiceControlManager := OpenServiceControlManager;
  if (HandleServiceControlManager > 0) and (HandleServiceControlManager <> INVALID_HANDLE_VALUE) then
  begin
    ServiceHandle := OpenService(HandleServiceControlManager,
                                 PChar(DrvName),
                                 SERVICE_ALL_ACCESS);
    ErrorCode := GetLastError;
    if ServiceHandle = 0 then
    begin
      CloseServiceHandle(HandleServiceControlManager);
      Exit;
    end
    else
    begin
      Result := DeleteService(ServiceHandle);
      ErrorCode := GetLastError;
    end;
    CloseServiceHandle(HandleServiceControlManager);
    CloseServiceHandle(ServiceHandle);
  end;
end;

function TSystemAccess.OpenDriver(Var ErrorCode : Integer) : Boolean;
var
  SecAttributes : PSecurityAttributes;
begin
  Result := False;
  ErrorCode := 0;
  if DriverStatus = Running then
  begin
    SecAttributes := New(PSecurityAttributes);
    SecAttributes.nLength := SizeOf(TSecurityAttributes);
    SecAttributes.lpSecurityDescriptor := nil;
    SecAttributes.bInheritHandle := False;
    DriverHandle := CreateFile('\\.\'+DEVICE_NAME,
                               GENERIC_READ or GENERIC_WRITE,
                               FILE_SHARE_READ,
                               SecAttributes,
                               OPEN_EXISTING,
                               FILE_ATTRIBUTE_NORMAL,
                               0);
    Dispose(SecAttributes);
    ErrorCode := GetLastError;
    Result := (ErrorCode = 0) and (DriverHandle <> INVALID_HANDLE_VALUE);
  end;
end;

procedure TSystemAccess.CloseDriver;
begin
  if DriverStatus = Running then
  begin
    if DriverHandle <> INVALID_HANDLE_VALUE then
      CloseHandle(DriverHandle);
  end;
end;

function TSystemAccess.GetKernelModeDriverConfig(DrvName : String; var ServiceConfig : TServiceConfig) : Boolean;
var
  HandleServiceControlManager,
  ServiceHandle : THandle;
  Dependencies,
  DependenciesNew : PChar;
  BytesNeeded : Cardinal;
  Buffer : LPQuery_Service_ConfigW;
begin
  Result := False;
  HandleServiceControlManager := OpenServiceControlManager;
  if (HandleServiceControlManager > 0) and (HandleServiceControlManager <> INVALID_HANDLE_VALUE) then
  begin
    ServiceHandle := OpenService(HandleServiceControlManager,
                                 PChar(DrvName),
                                 SERVICE_ALL_ACCESS);
    if ServiceHandle > 0 then
    begin
      QueryServiceConfig(ServiceHandle, nil, 0, BytesNeeded);
      Buffer := Allocmem(BytesNeeded);
      try
        if QueryServiceConfig(ServiceHandle, Buffer, BytesNeeded, BytesNeeded) then
        begin
          ServiceConfig.dwServiceType := Buffer^.dwServiceType;
          ServiceConfig.dwStartType := Buffer^.dwStartType;
          ServiceConfig.dwErrorControl := Buffer^.dwErrorControl;
          ServiceConfig.BinaryPathName := Buffer^.lpBinaryPathName;
          ServiceConfig.LoadOrderGroup := Buffer^.lpLoadOrderGroup;
          ServiceConfig.dwTagId := Buffer^.dwTagId;
          ServiceConfig.Dependencies := '';
          ServiceConfig.ServiceStartName := Buffer^.lpServiceStartName;
          ServiceConfig.DisplayName := Buffer^.lpDisplayName;
          Dependencies := Buffer^.lpDependencies;
          if Dependencies <> nil then
          begin
            while Dependencies^ <> #0 do
            begin
              DependenciesNew := Dependencies;
              while Dependencies^ <> #0 do
                Inc(Dependencies);
              if Dependencies > DependenciesNew then
              begin
                if ServiceConfig.Dependencies <> '' then
                  ServiceConfig.Dependencies := ServiceConfig.Dependencies + ' ';
                ServiceConfig.Dependencies := ServiceConfig.Dependencies +
                                              Copy(DependenciesNew,
                                                   1, Dependencies - DependenciesNew);
              end;
              Inc(Dependencies);
            end;
          end;
          Result := True;
        end;
      finally
        Freemem(Buffer);
      end;
      CloseServiceHandle(ServiceHandle);
    end;
    CloseServiceHandle(HandleServiceControlManager);
  end;
end;

function TSystemAccess.OpenServiceControlManager : THandle;
begin
  Result := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if Result = 0 then
    Result := INVALID_HANDLE_VALUE; //Unable to open Service Control Manager
end;

function TSystemAccess.GetKernelModeDriverStatus(DrvName : String) : Integer;
var
  HandleServiceControlManager,
  ServiceHandle : THandle;
  ServiceStatus : SERVICE_STATUS;
begin
  Result := -1;
  HandleServiceControlManager := OpenServiceControlManager;
  if (HandleServiceControlManager > 0) and (HandleServiceControlManager <> INVALID_HANDLE_VALUE) then
  begin
    ServiceHandle := OpenService(HandleServiceControlManager, PChar(DrvName), SERVICE_ALL_ACCESS);
    if (ServiceHandle > 0) and (ServiceHandle <> INVALID_HANDLE_VALUE) then
    begin
      if QueryServiceStatus(ServiceHandle, ServiceStatus) then
        Result := ServiceStatus.dwCurrentState;
      CloseServiceHandle(ServiceHandle);
    end;
    CloseServiceHandle(HandleServiceControlManager);
  end;
end;

constructor TSystemAccess.Create;
var
  DrvStatus{,
  ErrorCode} : Integer;
begin
  inherited;
  WindowsClass := TWindows.Create;
  ProcessorClass := TProcessor.Create(Self);
  SMBIOSClass := TSMBIOS.Create;
  PCIBusClass := TPCIBus.Create(Self);
  SMBusClass := TSMBus.Create(Self);

  DriverStatus := NotInstalled;
  DriverHandle := INVALID_HANDLE_VALUE;

  if DriverName <> '' then
  begin
    DrvStatus := GetKernelModeDriverStatus(DriverName);
    case DrvStatus of
      SERVICE_STOPPED          : DriverStatus := Stopped;      //The service is not running
      SERVICE_START_PENDING    : DriverStatus := Starting;     //The service is starting
      SERVICE_STOP_PENDING     : DriverStatus := Stopping;     //The service is stopping
      SERVICE_RUNNING          : DriverStatus := Running;      //The service is running
      SERVICE_CONTINUE_PENDING : DriverStatus := Continued;    //The service continue is pending
      SERVICE_PAUSE_PENDING    : DriverStatus := Pausing;      //The service pause is pending
      SERVICE_PAUSED           : DriverStatus := Paused;       //The service is paused
      else                       DriverStatus := NotInstalled; //The service is not installed
    end;
  end;

  NTDLLHandle := GetModuleHandle('NTDLL.DLL');
  NtQuerySystemInformation := nil;
  @NtQuerySystemInformation := GetProcAddress(NTDLLHandle,
                                              'NtQuerySystemInformation');
  Kernel32Handle := GetModuleHandle(PChar(Winapi.Windows.kernel32));
  GetFirmwareEnvironmentVariable :=
    TGetFirmwareEnvironmentVariable(GetProcAddress(Kernel32Handle,
                                                   'GetFirmwareEnvironmentVariable'+{$IFDEF UNICODE}'W'{$ELSE}'A'{$ENDIF}));
end;

destructor TSystemAccess.Destroy;
var
  LastErrorCode : Integer;
begin
  if GetKernelModeDriverStatus(DriverName) = SERVICE_RUNNING then
  begin
    if not StopKernelModeDriver(DriverName, LastErrorCode) then
      ShowMessage('Die Treiberdatei ' +
                  DriverFullPath +
                  ' kann nicht gestoppt werden.');
  end;

  if GetKernelModeDriverStatus(DriverName) = SERVICE_STOPPED then
  begin
    if not RemoveKernelModeDriver(DriverName, LastErrorCode) then
      ShowMessage('Die Treiberdatei ' +
                  DriverFullPath +
                  ' kann nicht entfernt werden.');
  end;

  case GetKernelModeDriverStatus(DriverName) of
    SERVICE_STOPPED          : DriverStatus := Stopped;
    SERVICE_START_PENDING    : DriverStatus := Starting;
    SERVICE_STOP_PENDING     : DriverStatus := Stopping;
    SERVICE_RUNNING          : DriverStatus := Running;
    SERVICE_CONTINUE_PENDING : DriverStatus := Continued;
    SERVICE_PAUSE_PENDING    : DriverStatus := Pausing;
    SERVICE_PAUSED           : DriverStatus := Paused;
    else                       DriverStatus := NotInstalled;
  end;

  SMBusClass.Destroy;
  PCIBusClass.Destroy;
  WindowsClass.Destroy;
  ProcessorClass.Destroy;
  SMBIOSClass.Destroy;
  inherited;
end;

function TSystemAccess.Driver_GetVersion(
           Var OutputBuf : VersionOutputStruct) : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
begin
  Result := False;
  with OutputBuf do
  begin
    Version := 0;
    Date := 0;
  end;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_Version,
                                     nil,
                                     0,
                                     @OutputBuf,
                                     SizeOf(OutputBuf),
                                     ReturnLength,
                                     nil);
      if IoctlResult and
         (ReturnLength >= SizeOf(OutputBuf)) then
        Result := True
      else
        ShowMessage('Error was detected: ' + DriverSysErrorMessage(GetLastError));
    except
      Result := False;
    end;
  end;
end;

function TSystemAccess.Driver_TransferTest : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
  OutputBuf : TransferTestOutputStruct;
begin
  Result := False;
  with OutputBuf do
    TransferTest := 0;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_TransferTest,
                                     nil,
                                     0,
                                     @OutputBuf,
                                     SizeOf(OutputBuf),
                                     ReturnLength,
                                     nil);
      if IoctlResult and
         (ReturnLength >= SizeOf(OutputBuf)) and
         (OutputBuf.TransferTest = $12345678) then
        Result := True
      else
        ShowMessage('Error was detected: ' + DriverSysErrorMessage(GetLastError));
    except
      Result := False;
    end;
  end;
end;

function TSystemAccess.Driver_ReadMSR(
           InputBuf : ReadMSRInputStruct;
           var OutputBuf : ReadMSROutputStruct) : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
begin
  Result := False;
  with OutputBuf do
  begin
    EAXReg := 0;
    EDXReg := 0;
  end;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_ReadMSR,
                                     @InputBuf,
                                     SizeOf(InputBuf),
                                     @OutputBuf,
                                     SizeOf(OutputBuf),
                                     ReturnLength,
                                     nil);
      if IoctlResult and
         (ReturnLength >= SizeOf(OutputBuf)) then
        Result := True;
    except
      Result := False;
    end;
  end;
end;

function TSystemAccess.Driver_WriteMSR(
           InputBuf : WriteMSRInputStruct) : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
begin
  Result := False;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_WriteMSR,
                                     @InputBuf,
                                     SizeOf(InputBuf),
                                     nil,
                                     0,
                                     ReturnLength,
                                     nil);
      if IoctlResult then
        Result := True;
    except
      Result := False;
    end;
  end;
end;

function TSystemAccess.Driver_ReadPCI(
           InputBuf : ReadPCIInputStruct;
           Var OutputBuf : ReadPCIOutputStruct) : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
begin
  Result := False;
  with OutputBuf do
    DataBuffer := 0;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_ReadPCI,
                                     @InputBuf,
                                     SizeOf(InputBuf),
                                     @OutputBuf,
                                     SizeOf(OutputBuf),
                                     ReturnLength,
                                     nil);

       if IoctlResult and
         (ReturnLength >= SizeOf(OutputBuf)) then
        Result := True
      else
        ShowMessage('Error was detected: ' + DriverSysErrorMessage(GetLastError));
    except
      Result := False;
    end;
  end;
end;

function TSystemAccess.Driver_WritePCI(
           InputBuf : WritePCIInputStruct;
           Var OutputBuf : WritePCIOutputStruct) : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
begin
  Result := False;

  with OutputBuf do
    DataBuffer := 0;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_WritePCI,
                                     @InputBuf,
                                     SizeOf(InputBuf),
                                     @OutputBuf,
                                     SizeOf(OutputBuf),
                                     ReturnLength,
                                     nil);
      if IoctlResult and
         (ReturnLength >= SizeOf(OutputBuf)) then
        Result := True
      else
        ShowMessage('Error was detected: ' + DriverSysErrorMessage(GetLastError));
    except
      Result := False;
    end;
  end;
end;

function TSystemAccess.Driver_ReadMem8Bit(
           InputBuf : ReadMemXBitInputStruct;
           Var OutputBuf : ReadMem8BitOutputStruct) : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
begin
  Result := False;
  with OutputBuf do
    Data := 0;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_ReadMem8Bit,
                                     @InputBuf,
                                     SizeOf(InputBuf),
                                     @OutputBuf,
                                     SizeOf(OutputBuf),
                                     ReturnLength,
                                     nil);
      if IoctlResult and
         (ReturnLength >= SizeOf(OutputBuf)) then
        Result := True
      else
        ShowMessage('Error was detected: ' + DriverSysErrorMessage(GetLastError));
    except
      Result := False;
    end;
  end;
end;

function TSystemAccess.Driver_ReadMem16Bit(
           InputBuf : ReadMemXBitInputStruct;
           Var OutputBuf : ReadMem16BitOutputStruct) : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
begin
  Result := False;
  with OutputBuf do
    Data := 0;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_ReadMem16Bit,
                                     @InputBuf,
                                     SizeOf(InputBuf),
                                     @OutputBuf,
                                     SizeOf(OutputBuf),
                                     ReturnLength,
                                     nil);
      if IoctlResult and
         (ReturnLength >= SizeOf(OutputBuf)) then
        Result := True
      else
        ShowMessage('Error was detected: ' + DriverSysErrorMessage(GetLastError));
    except
      Result := False;
    end;
  end;
end;

function TSystemAccess.Driver_ReadMem32Bit(
           InputBuf : ReadMemXBitInputStruct;
           Var OutputBuf : ReadMem32BitOutputStruct) : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
begin
  Result := False;
  with OutputBuf do
    Data := 0;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_ReadMem32Bit,
                                     @InputBuf,
                                     SizeOf(InputBuf),
                                     @OutputBuf,
                                     SizeOf(OutputBuf),
                                     ReturnLength,
                                     nil);
      if IoctlResult and
         (ReturnLength >= SizeOf(OutputBuf)) then
        Result := True
      else
        ShowMessage('Error was detected: ' + DriverSysErrorMessage(GetLastError));
    except
      Result := False;
    end;
  end;
end;

function TSystemAccess.Driver_WriteMem8Bit(
           InputBuf : WriteMem8BitInputStruct) : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
begin
  Result := False;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_WriteMem8Bit,
                                     @InputBuf,
                                     SizeOf(InputBuf),
                                     nil,
                                     0,
                                     ReturnLength,
                                     nil);
      if IoctlResult then
        Result := True
      else
        ShowMessage('Error was detected: ' + DriverSysErrorMessage(GetLastError));
    except
      Result := False;
    end;
  end;
end;

function TSystemAccess.Driver_WriteMem16Bit(
           InputBuf : WriteMem16BitInputStruct) : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
begin
  Result := False;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_WriteMem16Bit,
                                     @InputBuf,
                                     SizeOf(InputBuf),
                                     nil,
                                     0,
                                     ReturnLength,
                                     nil);
      if IoctlResult then
        Result := True
      else
        ShowMessage('Error was detected: ' + DriverSysErrorMessage(GetLastError));
    except
      Result := False;
    end;
  end;
end;

function TSystemAccess.Driver_WriteMem32Bit(
           InputBuf : WriteMem32BitInputStruct) : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
begin
  Result := False;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_WriteMem32Bit,
                                     @InputBuf,
                                     SizeOf(InputBuf),
                                     nil,
                                     0,
                                     ReturnLength,
                                     nil);
      if IoctlResult then
        Result := True
      else
        ShowMessage('Error was detected: ' + DriverSysErrorMessage(GetLastError));
    except
      Result := False;
    end;
  end;
end;

function TSystemAccess.Driver_ReadPort8Bit(
           InputBuf : ReadPortXBitInputStruct;
           Var OutputBuf : ReadPort8BitOutputStruct) : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
begin
  Result := False;
  with OutputBuf do
    Data := 0;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_ReadPort8Bit,
                                     @InputBuf,
                                     SizeOf(InputBuf),
                                     @OutputBuf,
                                     SizeOf(OutputBuf),
                                     ReturnLength,
                                     nil);
      if IoctlResult and
         (ReturnLength >= SizeOf(OutputBuf)) then
        Result := True
      else
        ShowMessage('Error was detected: ' + DriverSysErrorMessage(GetLastError));
    except
      Result := False;
    end;
  end;
end;

function TSystemAccess.Driver_ReadPort16Bit(
           InputBuf : ReadPortXBitInputStruct;
           Var OutputBuf : ReadPort16BitOutputStruct) : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
begin
  Result := False;
  with OutputBuf do
    Data := 0;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_ReadPort16Bit,
                                     @InputBuf,
                                     SizeOf(InputBuf),
                                     @OutputBuf,
                                     SizeOf(OutputBuf),
                                     ReturnLength,
                                     nil);
      if IoctlResult and
         (ReturnLength >= SizeOf(OutputBuf)) then
        Result := True
      else
        ShowMessage('Error was detected: ' + DriverSysErrorMessage(GetLastError));
    except
      Result := False;
    end;
  end;
end;

function TSystemAccess.Driver_ReadPort32Bit(
           InputBuf : ReadPortXBitInputStruct;
           Var OutputBuf : ReadPort32BitOutputStruct) : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
begin
  Result := False;
  with OutputBuf do
    Data := 0;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_ReadPort32Bit,
                                     @InputBuf,
                                     SizeOf(InputBuf),
                                     @OutputBuf,
                                     SizeOf(OutputBuf),
                                     ReturnLength,
                                     nil);
      if IoctlResult and
         (ReturnLength >= SizeOf(OutputBuf)) then
        Result := True
      else
        ShowMessage('Error was detected: ' + DriverSysErrorMessage(GetLastError));
    except
      Result := False;
    end;
  end;
end;

function TSystemAccess.Driver_WritePort8Bit(
           InputBuf : WritePort8BitInputStruct) : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
begin
  Result := False;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_WritePort8Bit,
                                     @InputBuf,
                                     SizeOf(InputBuf),
                                     nil,
                                     0,
                                     ReturnLength,
                                     nil);
      if IoctlResult then
        Result := True
      else
        ShowMessage('Error was detected: ' + DriverSysErrorMessage(GetLastError));
    except
      Result := False;
    end;
  end;
end;

function TSystemAccess.Driver_WritePort16Bit(
           InputBuf : WritePort16BitInputStruct) : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
begin
  Result := False;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_WritePort16Bit,
                                     @InputBuf,
                                     SizeOf(InputBuf),
                                     nil,
                                     0,
                                     ReturnLength,
                                     nil);
      if IoctlResult then
        Result := True
      else
        ShowMessage('Error was detected: ' + DriverSysErrorMessage(GetLastError));
    except
      Result := False;
    end;
  end;
end;

function TSystemAccess.Driver_WritePort32Bit(
           InputBuf : WritePort32BitInputStruct) : Boolean;
var
  IoctlResult : Boolean;
  ReturnLength : LongWord;
begin
  Result := False;

  if (DriverStatus = Running) and (DriverHandle <> INVALID_HANDLE_VALUE) then
  begin
    try
      IoctlResult := DeviceIoControl(DriverHandle,
                                     IOCTL_PCANALYS_WritePort32Bit,
                                     @InputBuf,
                                     SizeOf(InputBuf),
                                     nil,
                                     0,
                                     ReturnLength,
                                     nil);
      if IoctlResult then
        Result := True
      else
        ShowMessage('Error was detected: ' + DriverSysErrorMessage(GetLastError));
    except
      Result := False;
    end;
  end;
end;

{ TProcessor }

{ Class basic functions }

constructor TProcessor.Create(Parent : TSystemAccess);
begin
  inherited Create;
  FParent := Parent;

  Kernel32Handle := GetModuleHandle(PChar(Winapi.Windows.kernel32));

  GetLogicalProcessorInformation :=
    TGetLogicalProcessorInformation(
      GetProcAddress(Kernel32Handle, 'GetLogicalProcessorInformation'));
  GetLogicalProcessorInformationEx :=
    TGetLogicalProcessorInformationEx(
      GetProcAddress(Kernel32Handle, 'GetLogicalProcessorInformationEx'));
end;

destructor TProcessor.Destroy;
begin
  if Assigned(FCPUCache) then
    FCPUCache.Free;
  if Assigned(FCPUFeatures) then
    FCPUFeatures.Free;
  inherited;
end;

procedure TProcessor.Clear;
begin
  FCPUType := 0;
  FIntelBrand := [];
  FFamily := 0;
  FFamilyEx := 0;
  FModel := 0;
  FModelEx := 0;
  FStepping := 0;
  FSteppingEx := 0;
  FBrand := 0;
  FCPUName := '';
  FCodename := '';
  FMarketingName := '';
  FGenericName := '';
  FRevision := '';
  FTech := '';
  FArch := 0;
  FFreq := 0;
end;

{ Cache functions }

function TProcessor.ValidDescriptor(Value : Cardinal) : Boolean;
begin
  Result := (Value and (1 shl 31)) = 0;
end;

procedure TProcessor.DecodeDescriptor(Value : Cardinal; Index : Integer);
begin
  if ValidDescriptor(Value) then
  begin
    FCacheDescriptors[Index * 4 - 3] := LoByte(LoWord(Value));
    FCacheDescriptors[Index * 4 - 2] := HiByte(LoWord(Value));
    FCacheDescriptors[Index * 4 - 1] := LoByte(HiWord(Value));
    FCacheDescriptors[Index * 4] := HiByte(HiWord(Value));
  end;
end;

function TProcessor.DescriptorExists(Value : Cardinal) : Boolean;
var
  i : Integer;
begin
  Result := False;
  for i := Low(FCacheDescriptors) to High(FCacheDescriptors) do
    if not Result then
      Result := FCacheDescriptors[i] = Value;
end;

function TProcessor.DecodeCacheParams(ACache : TCPUIDRec) : TCacheDetails;
var
  s : string;
begin
  s := '';
  ResetMemory(Result, SizeOf(Result));
  with Result do
  begin
    Level := (ACache.EAX shr 5) and $7;
    &Type := ACache.EAX and $1F;
    LineSize := ACache.EBX and $FFF + 1;
    Ways := ACache.EBX shr 22 + 1;
    Partitions := (ACache.EBX shr 12) and $FF + 1;
    Size := LineSize * Ways * Partitions * (ACache.ECX + 1) shr 10;
    Shared := (ACache.EAX shr 14) and $FFF + 1;
    if Shared < FLPC then
      Shared := FLPC;
    if Shared > FMCPP then
      Shared := 1;
    case &Type of
      ctDataCache    : s := 'Daten';
      ctCodecache    : s := 'Instruktionen';
      ctUnifiedCache : s := 'Instruktionen+Daten';
    end;
    Desc := Format('L%d %s %d KB, %d-fach assoziativ, %d Byte Zeilengröße', [Level, s, Size, Ways, LineSize]);
  end;
end;

function TProcessor.LookupAssociativity(Value : Byte) : TCacheAssociativity;
var
  i : TCacheAssociativity;
begin
  Result := caNone;
  for i := Low(TCacheAssociativity) to High(TCacheAssociativity) do
    if Value = cAssociativityInfo[i] then
    begin
      Result := i;
      Break;
    end;
end;

{ Feature functions }

procedure TProcessor.GetAvailableFeatures(AFS : TFeatureSet; var AF : TAvailableFeatures);
var
  Counter : Integer;
  FeatureSet : TFeatureAvailability;
  CPUID : TCPUIDRec;
  Reg : {$IFDEF WIN64}NativeUInt{$ELSE}Cardinal{$ENDIF};
begin
  Finalize(AF);

  case FVendor of
    cvIntel : FeatureSet := faIntel;
    cvAMD   : FeatureSet := faAMD;
    cvCyrix : FeatureSet := faCyrix;
    else      FeatureSet := faCommon;
  end;

  Reg := 0;
  Counter := 0;
  repeat
    if (cFeatureDefinitions[Counter].Availability in [faCommon, FeatureSet]) and
       (AFS = cFeatureDefinitions[Counter].FeatSet) then
    begin
      SetLength(AF, Length(AF) + 1);
      with AF[High(AF)] do
      begin
        Definition := cFeatureDefinitions[Counter];
        Value := False;
      end;
    end;
    Inc(Counter);
  until (Counter > High(cFeatureDefinitions));

  for Counter := 0 to High(AF) do
  begin
    case AF[Counter].Definition.Func of
      CPUID_STD_FeatureSet      : CPUID := FfsStd;
      CPUID_STD_ExtFeatureSet   : CPUID := FfsStdExt;
      CPUID_STD_ThermalPower    : CPUID := FfsStdPM;
      CPUID_EXT_FeatureSet      : CPUID := FfsExt;
      CPUID_EXT_PowerManagement : CPUID := FfsExtPM;
      CPUID_EXT_AMDExtFeatures  : CPUID := FfsAMDExt;
      CPUID_EXT_AMDSVMFeatures  : CPUID := FfsAMDSVM;
    end;
    case AF[Counter].Definition.ExX of
      rEAX : Reg := CPUID.EAX;
      rEBX : Reg := CPUID.EBX;
      rECX : Reg := CPUID.ECX;
      rEDX : Reg := CPUID.EDX;
    end;

    AF[Counter].Value := (Reg and (1 shl AF[Counter].Definition.Index)) <> 0;
  end;
end;

{ CPU Name functions }

function TProcessor.GetCPUCodename(AIndex : Byte;
                                   AVendor, AFamily, AModelEx, AStepping : Integer;
                                   out AMCA, ACoreDesign, ARevision : String;
                                   out ATechProcess : Integer) : Boolean;
var
  CPURec : TCPUDBRecord;
begin
  Result := False;
  AMCA := '';
  ACoreDesign := '';
  ARevision := '';
  ATechProcess := 0;
  for CPURec in CPUDB do
    if (CPURec.Vendor = AVendor)   and (CPURec.Family = AFamily) and
       (CPURec.ModelEx = AModelEx) and
       ((CPURec.Stepping = -1) or (CPURec.Stepping = AStepping)) then
    begin
      Result := True;
      AMCA := CPURec.MCA;
      ACoreDesign := CPURec.CoreDesign;
      ATechProcess := CPURec.TechProcess;
      Break;
    end;
end;

function TProcessor.StripSpaces(ASource : String) : String;
var
  l, c, i : Integer;
begin
  c := 0;
  l := Length(ASource);
  Result := '';
  for i := 1 to l do
    if ASource[i] = ' ' then
    begin
      Inc(c);
      if c < 2 then
        Result := Result + ASource[i];
    end else
    begin
      Result := Result + ASource[i];
      c := 0;
    end;
end;

function TProcessor.FormatCPUName(const AName : String) : String;
var
  Counter : Integer;
begin
  Result := AName;
  Result := StringReplace(Result, '(R)',        '',  [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '(TM)',       ' ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'Genuine',    '',  [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'Procesor',   '',  [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'Processor',  '',  [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'Technology', '',  [rfReplaceAll, rfIgnoreCase]);
  Counter := Pos('@', Result);
  if Counter > 0 then
  begin
    Delete(Result, Counter, 255);
    Result := StringReplace(Result, 'CPU', '', [rfReplaceAll, rfIgnoreCase]);
  end else
  begin
    Counter := Pos('CPU', Result);
    if Counter > 0 then
      Delete(Result, Counter, 255);
  end;
  Result := Trim(Result);
  Result := StripSpaces(Result);
end;

function TProcessor.FormatString(AValue : Cardinal) : String;
begin
  Result := String(AnsiChar(LoByte(LoWord(AValue)))+
                   AnsiChar(HiByte(LoWord(AValue)))+
                   AnsiChar(LoByte(HiWord(AValue)))+
                   AnsiChar(HiByte(HiWord(AValue))));
end;

{ Affinity functions }

procedure TProcessor.SetProcAffinity(FIndex : Byte);
var
  aProcessAffinityMask : Cardinal;
  SystemAffinityMask : DWord_Ptr;
  WinInfo : TSystemInfo;
  ph : THandle;
begin
  if FIndex in [0..31] then
  begin
    ph := GetCurrentProcess;
    GetProcessAffinityMask(ph, OldAffinity, SystemAffinityMask);
    GetSystemInfo(WinInfo);
    if FIndex > WinInfo.dwNumberOfProcessors - 1 then
      FIndex := 0;
    aProcessAffinityMask := 1 shl FIndex;
    if OldAffinity <> aProcessAffinityMask then
    begin
      SetProcessAffinityMask(ph, aProcessAffinityMask);
      Sleep(0);
    end else
    OldAffinity := UInt(-1);
  end;
end;

procedure TProcessor.RestoreProcAffinity;
begin
  if OldAffinity <> UInt(-1) then
    SetProcessAffinityMask(GetCurrentProcess, OldAffinity);
end;

{ CPUID functions }

function TProcessor.IsCPUIDCommandSupported(Cpu : Byte; Command : Cardinal) : Boolean;
begin
  Result := Command <= GetCPUIDMaximumCommand(Cpu, GetCPUIDCommandLevel(Command));
end;

function TProcessor.GetCPUIDCommandLevel(Command : Cardinal) : TCPUIDExecutionLevel;
begin
  case Command of
    CPUID_STD_MaximumLevel..CPUID_STD_SerialNumber    : Result := celStandard;
    CPUID_EXT_MaximumLevel..CPUID_EXT_AA64Information : Result := celExtended;
    CPUID_TMX_MaximumLevel..CPUID_TMX_Operation       : Result := celTransmeta;
  else
    Result := celStandard;
  end;
end;

function TProcessor.GetCPUIDMaximumCommand(Cpu : Byte; Level : TCPUIDExecutionLevel) : {$IFDEF WIN64}NativeUInt{$ELSE}Cardinal{$ENDIF};
begin
  SetProcAffinity(Cpu);
  try
    case Level of
      celStandard  : Result := System.GetCPUID(CPUID_STD_MaximumLevel, 0).EAX;
      celExtended  : Result := System.GetCPUID(CPUID_EXT_MaximumLevel, 0).EAX;
      celTransmeta : Result := System.GetCPUID(CPUID_TMX_MaximumLevel, 0).EAX;
    else
      Result := 0;
    end;
  finally
    RestoreProcAffinity;
  end;
end;

function TProcessor.GetIntelBrand : TIntelBrands;
begin
  Result := [];
  case FBrand of
    $1     : Result := Result + [ibCeleron];
    $2, $4 : Result := Result + [ibPentium];
    $3     : if FCPUCache.Level2.Size <= 128 then
               Result := Result + [ibCeleron]
             else
               Result := Result + [ibXeon];
    $6     : Result := Result + [ibPentium, ibMobile];
    $7     : Result := Result + [ibCeleron, ibMobile];
    $8     : if (FFamily = $f) and (FModel = 2) and (FStepping = 4) then
               Result := Result + [ibCeleron, ibMobile]
             else
               Result := Result + [ibPentium];
    $A     : Result := Result + [ibCeleron];
    $9     : Result := Result + [ibPentium];
    $B     : if FCPUCache.Level3.Size = 0 then
               Result := Result + [ibXeon]
             else
               Result := Result + [ibXeon, ibMP];
    $C     : Result := Result + [ibXeon, ibMP];
    $E     : Result := Result + [ibPentium, ibMobile];
    $F     : if (FFamily = $f) and (FModel = 2) and (FStepping = 7) then
               Result := Result + [ibCeleron, ibMobile]
             else
               Result := Result + [ibPentium, ibMobile];
    $11    : Result := Result + [ibMobile];
    $12    : Result := Result + [ibCeleron, ibM];
    $13    : Result := Result + [ibCeleron, ibMobile];
    $14    : Result := Result + [ibCeleron];
    $15    : Result := Result + [ibMobile];
    $16    : Result := Result + [ibPentium, ibM];
    $17    : Result := Result + [ibCeleron, ibMobile];
  end;
  if FCPP = 2 then
    FIntelBrand := FIntelBrand + [ibDuoCore];
  if FFamily = 15 then
    FIntelBrand := FIntelBrand + [ibP4];
end;

function TProcessor.ExecuteCPUID(Cpu : Integer; FunctionID : Cardinal;
                                 SubFunctionID : Cardinal = 0) : TCPUIDRec;
begin
  if CPU > -1 then
    SetProcAffinity(Cpu);
  try
    Result := System.GetCPUID(FunctionID, SubFunctionID);
  finally
    if CPU > -1 then
      RestoreProcAffinity;
  end;
end;

{ Helper functions }

function TProcessor.GetWinCPUNumbers : Byte;
type
  TIsWow64Process = function(Handle : THandle; var Res : Bool) : Bool; stdcall;
var
  WinInfo : TSystemInfo;
  IsWow64Process : TIsWow64process;
  IsWow64 : Bool;
begin
  IsWow64 := False;
  IsWow64Process := nil;
  if Kernel32Handle  = 0 then
    Kernel32Handle := LoadLibrary(PChar(Winapi.Windows.kernel32));
  if Kernel32Handle <> 0 then
    IsWOW64Process := GetProcAddress(Kernel32Handle, PChar('IsWow64Process'));

  if Assigned(IsWow64Process) then
    IsWow64Process(GetCurrentProcess, IsWow64);
  if IsWow64 then
    GetNativeSystemInfo(WinInfo)
  else GetSystemInfo(WinInfo);

  Result := Byte(WinInfo.dwNumberOfProcessors);
end;

function TProcessor.GetCPUPhysicalCount : Byte;
var
  Counter, WinCount : Integer;
  CPUID : TCPUIDRec;
  APIC, LPP, LID : Byte;
  Mask, b : Cardinal;
begin
  Result := 0;
  WinCount := GetWinCPUNumbers;
  for Counter := 0 to WinCount - 1 do
  begin
    SetProcAffinity(Counter);

    CPUID := System.GetCPUID($00000001, 0);
    if (CPUID.EDX and (1 shl 28{SFS_HTT})) <> 0 then
    begin
      APIC := (CPUID.EBX and $FF000000{INITIAL_APIC_ID_BITS}) shr 24;
      LPP := ((CPUID.EBX and $00FF0000{NUM_LOGICAL_BITS}) shr 16) and $FF;
    end else
    begin
      APIC := Byte(-1);
      LPP := 1;
    end;
    b := 1;
    Mask := $FF;
    while (b < LPP) do
    begin
      b := b * 2;
      Mask := Mask shl 1;
    end;
    LID := APIC and not Mask shl 24 shr 24;
    if LID = 0 then
      Inc(Result, 1);
  end;
  RestoreProcAffinity;
  if Result = 0 then Result := WinCount;
end;

{ Binary helper functions }

function TProcessor.HiDWord(AValue : UInt64) : Cardinal;
begin
  Result := AValue shr 32;
end;

function TProcessor.LoDWord(AValue : UInt64) : Cardinal;
begin
  Result := Cardinal(AValue);
end;

function TProcessor.IsBitOn(Value : UInt64; Bit : Byte) : Boolean;
begin
  if Bit > 31 then
    Result := (HiDWord(Value) and (1 shl (Bit - 32))) <> 0
  else
    Result := (LoDWord(Value) and (1 shl Bit)) <> 0;
end;

function TProcessor.YesNo(ABool : Boolean) : String;
begin
  case ABool of
    True  : Result := 'ja';
    False : Result := 'nein';
  end;
end;

function TProcessor.GetBitsFromDWord(const aval : Cardinal; const afrom, ato : Byte) : Integer;
var
  mask : Integer;
begin
  mask := (1 shl (ato + 1)) - 1;
  if ato = 31 then
    Result := aval shr afrom
  else
    Result := (aval and mask) shr afrom;
end;

function TProcessor.CountSetBits(ABitMask : NativeUInt) : DWord;
var
  LShift, LIdx : UInt32;
  LBitTest : NativeUInt;
begin
  LShift := (SizeOf(NativeUInt) * 8) - 1;
  Result := 0;
  LBitTest := NativeUInt(1) shl LShift;
  LIdx := 0;
  while LIdx <= LShift do
  begin
    if (ABitMask and LBitTest) <> 0 then
      Inc(Result);
    LBitTest := LBitTest shr 1;
    Inc(LIdx);
  end;
end;

{ Main detection functions }

procedure TProcessor.GetProcessorDetails(FIndex : Byte);
var
  VID, s, r : String;
  Counter,
  i, c, t, p,
  l, k, m : Integer;
  FAMD,
  FCache : TCPUIDRec;
  cd1 : Array[clLevel1Code..clLevel1Unified] of TCacheDetails;
  cd, cd2, cd3, cd4 : TCacheDetails;
  j : TCacheLevel;
  fs1, fs2, fs3, fs4 : TAvailableFeatures;
  FHTT : Boolean;
  n : Cardinal;
  buf1, slpi : PSystemLogicalProcessorInformation;
  buf2, slpiex : PSystemLogicalProcessorInformationEx;

  procedure SetCache;
  begin
    if (cd.Level = 1) and (cd.&Type = 1) then
      cd1[clLevel1Data] := cd
    else if (cd.Level = 1) and (cd.&Type = 2) then
      cd1[clLevel1Code] := cd
    else if (cd.Level = 1) and (cd.&Type = 3) then
      cd1[clLevel1Unified] := cd
    else if (cd.Level = 2) then
      cd2 := cd
    else if (cd.Level = 3) then
      cd3 := cd;
  end;

begin
  // Initializations
  Clear;
  if Assigned(FCPUCache) then
    FCPUCache.Free;
  if Assigned(FCPUFeatures) then
    FCPUFeatures.Free;
  FCPUCache := TCPUCache.Create;
  FCPUFeatures := TCPUFeatures.Create;
  GetNativeSystemInfo(FSI);
  FArch := FSI.wProcessorArchitecture;
  FModelEx := Hi(FSI.wProcessorRevision);
  FSteppingEx := Lo(FSI.wProcessorRevision);
  FCount := FSI.dwNumberOfProcessors;
  FTC := FSI.dwNumberOfProcessors;
  FPC := 1;
  FSC := 1;

  // CPU Vendor
  FCPUID := ExecuteCPUID(FIndex, CPUID_STD_VendorSignature);
  VID := FormatString(FCPUID.EBX) + FormatString(FCPUID.EDX) + FormatString(FCPUID.ECX);
  FVendor := cvUnknown;
  for Counter := Integer(cvUnknown) to Integer(cvTransmeta) do
    if cVendorNames[TCPUVendor(Counter)].Signature = VID then
    begin
      FVendor := TCPUVendor(Counter);
      Break;
    end;

  if IsCPUIDCommandSupported(FIndex, CPUID_STD_Signature) then
  begin
    // CPU Generic Details
    FCPUID := ExecuteCPUID(FIndex, CPUID_STD_Signature);
    FCPUType := (FCPUID.EAX shr 12 and 3);
    if (FCPUID.EAX shr 8 and $F) >= $F then
      FFamily := (FCPUID.EAX shr 20 and $FF) + (FCPUID.EAX shr 8 and $F)
    else
      FFamily := FCPUID.EAX shr 8 and $F;
    if (FCPUID.EAX shr 4 and $F) >= $F then
      FModel := (FCPUID.EAX shr 16 and $F) + (FCPUID.EAX shr 4 and $F)
    else
      FModel := FCPUID.EAX shr 4 and $F;
    FStepping := FCPUID.EAX and $F;
    if (FVendor = cvAmd) and (FFamily = 15) and (FModel > 4) and (FCPUID.EBX = 0) then
    begin // AMD Opteron
      FAMD := ExecuteCPUID(FIndex, CPUID_EXT_Signature);
      FBrand := LoByte(LoWord(FAMD.EBX));
    end else
      FBrand := LoByte(LoWord(FCPUID.EBX));

    case FArch of
      PROCESSOR_ARCHITECTURE_IA64 : FGenericName :=
         Format(rsGenericName_ia64,
         [FSI.wProcessorLevel,
          Hi(FSI.wProcessorRevision),
          Lo(FSI.wProcessorRevision)
         ]);
      PROCESSOR_ARCHITECTURE_AMD64 : FGenericName :=
         Format(rsGenericName_x64,
         [FSI.wProcessorLevel,
          Hi(FSI.wProcessorRevision),
          Lo(FSI.wProcessorRevision)
         ]);
      else FGenericName := Format(rsGenericName_x86, [FFamily, FModel, FStepping]);
    end;

    // MaxLogicalPerPackage
    FHTT := (FCPUID.EDX and (1 shl 28)) <> 0;
    if FHTT then
      FMLPP := GetBitsFromDWord(FCPUID.EBX, 16, 23)
    else
      FMLPP := 1;

    // Core Number Statistics
    FCPP := 1; {CorePerPackage}
    FLPP := 1; {LogicalPerPackage}
    FLPC := 1; {LogicalPerCore}
    case FVendor of
      cvIntel : if IsCPUIDCommandSupported(FIndex,
                                           CPUID_STD_CacheParams) then
      begin
        FCPUID := ExecuteCPUID(-1, CPUID_STD_CacheParams);
        FMCPP := GetBitsFromDWord(FCPUID.EAX, 26, 31) + 1;
        FMLPC := FMLPP div FMCPP;
        if FMCPP = 2 then
          FIntelBrand := FIntelBrand + [ibDuoCore]
        else
          if FFamily = 15 then
            FIntelBrand := FIntelBrand + [ibP4];
        if IsCPUIDCommandSupported(FIndex, CPUID_STD_Topology) then
        begin
          for i := 0 to 254 do
          begin
            FCPUID := ExecuteCPUID(-1, CPUID_STD_Topology, i);
            if GetBitsFromDWord(FCPUID.EBX, 0, 15) > 0 then
            begin
              case GetBitsFromDWord(FCPUID.ECX, 8, 15) of
                1 : {SMT}  FLPC := GetBitsFromDWord(FCPUID.EAX, 0, 4);
                2 : {Core} FCPP := GetBitsFromDWord(FCPUID.EAX, 0, 4);
              end;
            end else
              Break;
          end;
        end;
        if FCPP = 0 then
          FCPP := FMCPP;
        FCPP := FMCPP div FCPP;
        if FCPP = 0 then
          FCPP := FMCPP;
        if FMLPC > FLPC then
          FLPC := FMLPC;
        FLPP := FCPP * FLPC;

        if (FCount div FPC) > FLPP then
        begin
          FCPP := (FCount div FPC) div FLPC;
          FLPP := (FCount div FPC);
        end;
      end;
      cvAMD : if IsCPUIDCommandSupported(FIndex,
                                         CPUID_EXT_AA64Information) then
      begin
        FCPUID := ExecuteCPUID(FIndex, CPUID_EXT_AA64Information);
        FLPP := (FCPUID.ECX and $FF) + 1;
      end;
    end;

    // CPU Marketing Name
    if FVendor <> cvTransmeta then
    begin
      if IsCPUIDCommandSupported(FIndex, CPUID_EXT_MarketingName1) then
      begin
        FCPUID := ExecuteCPUID(FIndex, CPUID_EXT_MarketingName1);
        FMarketingName := FormatString(FCPUID.EAX) +
                          FormatString(FCPUID.EBX) +
                          FormatString(FCPUID.ECX) +
                          FormatString(FCPUID.EDX);
        FCPUID := ExecuteCPUID(FIndex, CPUID_EXT_MarketingName2);
        FMarketingName := FMarketingName + FormatString(FCPUID.EAX) +
                                           FormatString(FCPUID.EBX) +
                                           FormatString(FCPUID.ECX) +
                                           FormatString(FCPUID.EDX);
        FCPUID := ExecuteCPUID(FIndex, CPUID_EXT_MarketingName3);
        FMarketingName := FMarketingName + FormatString(FCPUID.EAX) +
                                           FormatString(FCPUID.EBX) +
                                           FormatString(FCPUID.ECX) +
                                           FormatString(FCPUID.EDX);
      end
      else
      if IsCPUIDCommandSupported(FIndex, CPUID_TMX_MarketingName1) then
      begin
        FCPUID := ExecuteCPUID(FIndex, CPUID_TMX_MarketingName1);
        FMarketingName := FormatString(FCPUID.EAX) +
                          FormatString(FCPUID.EBX) +
                          FormatString(FCPUID.ECX) +
                          FormatString(FCPUID.EDX);
        FCPUID := ExecuteCPUID(FIndex, CPUID_TMX_MarketingName2);
        FMarketingName := FMarketingName + FormatString(FCPUID.EAX) +
                                           FormatString(FCPUID.EBX) +
                                           FormatString(FCPUID.ECX) +
                                           FormatString(FCPUID.EDX);
        FCPUID := ExecuteCPUID(FIndex, CPUID_TMX_MarketingName3);
        FMarketingName := FMarketingName + FormatString(FCPUID.EAX) +
                                           FormatString(FCPUID.EBX) +
                                           FormatString(FCPUID.ECX) +
                                           FormatString(FCPUID.EDX);
        FCPUID := ExecuteCPUID(FIndex, CPUID_TMX_MarketingName4);
        FMarketingName := FMarketingName + FormatString(FCPUID.EAX) +
                                           FormatString(FCPUID.EBX) +
                                           FormatString(FCPUID.ECX) +
                                           FormatString(FCPUID.EDX);
      end;
    end;
    FMarketingName := Trim(FMarketingName);
  end;

  // CPU Ext Signature
  if IsCPUIDCommandSupported(FIndex, CPUID_EXT_Signature) then
  begin
    FCPUID := ExecuteCPUID(FIndex, CPUID_EXT_Signature);
    FFamilyEx := FCPUID.EAX shr 8 and $F;
    FModelEx := FCPUID.EAX shr 4 and $F;
    FSteppingEx := FCPUID.EAX and $F;
  end;

  // CPU cache
  for j := clLevel1Code to clLevel1Unified do
  begin
    ResetMemory(cd1[j], SizeOf(TCacheDetails));
    cd1[j].Shared := 1;
  end;
  ResetMemory(cd2, SizeOf(TCacheDetails));
  cd2.Shared := 1;
  ResetMemory(cd3, SizeOf(TCacheDetails));
  cd3.Shared := 1;
  ResetMemory(cd4, SizeOf(TCacheDetails));
  cd4.Shared := 1;
  i := 0;
  repeat
    FCache := ExecuteCPUID(FIndex, CPUID_STD_CacheParams, i);
    cd := DecodeCacheParams(FCache);
    if cd.&Type > 0 then
      SetCache;
    Inc(i);
  until cd.&Type = 0;

  // CPU Cache Level1
  if cVendorNames[FVendor].CacheDetect <> vcdExtended then
  begin
    if FVendor = cvIntel then
      FCache := ExecuteCPUID(FIndex,
                             CPUID_STD_CacheTlbs,
                             LoByte(LoWord(ExecuteCPUID(FIndex, CPUID_STD_CacheTlbs).EAX)))
    else
      FCache := ExecuteCPUID(FIndex,
                             CPUID_EXT_Level1Cache);
    DecodeDescriptor(FCache.EAX, 1);
    DecodeDescriptor(FCache.EBX, 2);
    DecodeDescriptor(FCache.ECX, 3);
    DecodeDescriptor(FCache.EDX, 4);
    for j := clLevel1Code to clLevel1Unified do
    begin
      if cd1[j].&Type = 0 then
      begin
        cd1[j].Descriptors := FCacheDescriptors;
        for i := Low(cDescriptorInfo) to High(cDescriptorInfo) do
          if (cDescriptorInfo[i].Level = j) and DescriptorExists(cDescriptorInfo[i].Descriptor) then
          begin
            cd1[j].Associativity := cDescriptorInfo[i].Associativity;
            cd1[j].LineSize := cDescriptorInfo[i].LineSize;
            cd1[j].Size := cDescriptorInfo[i].Size;
            cd1[j].&Type := cDescriptorInfo[i].Descriptor;
            cd1[j].Desc := cDescriptorInfo[i].Description;
          end;
      end;
    end;
  end else
  begin
    if cd1[clLevel1Code].&Type = 0 then
    begin
      FCache := ExecuteCPUID(FIndex, CPUID_EXT_Level1Cache);
      cd1[clLevel1Code].Size := HiByte(HiWord(FCache.EDX));
      cd1[clLevel1Code].LineSize := LoByte(LoWord(FCache.EDX));
      cd1[clLevel1Code].Associativity := LookupAssociativity(LoByte(HiWord(FCache.EDX)));
      cd1[clLevel1Code].&Type := ctCodeCache;
      with cd1[clLevel1Code] do
        Desc := Format('L1 Instruktionen %d KB, %s, %d Byte Zeilengröße',
                       [Size, cAssociativityDescription[Associativity], LineSize]);
    end;

    if cd1[clLevel1Data].&Type = 0 then
    begin
      cd1[clLevel1Data].Size := HiByte(HiWord(FCache.ECX));
      cd1[clLevel1Data].LineSize := LoByte(LoWord(FCache.ECX));
      cd1[clLevel1Data].Associativity := LookupAssociativity(LoByte(HiWord(FCache.ECX)));
      cd1[clLevel1Data].&Type := ctDataCache;
      with cd1[clLevel1Data] do
        Desc := Format('L1 Daten %d KB, %s, %d Byte Zeilengröße',
                       [Size, cAssociativityDescription[Associativity], LineSize]);
    end;
  end;
  // CPU Cache Level2
  if cd2.&Type = 0 then
  begin
    if cVendorNames[FVendor].CacheDetect <> vcdExtended then
    begin
      if FVendor = cvIntel then
        FCache := ExecuteCPUID(FIndex,
                               CPUID_STD_CacheTlbs,
                               LoByte(LoWord(ExecuteCPUID(FIndex, CPUID_STD_CacheTlbs).EAX)))
      else
        FCache := ExecuteCPUID(FIndex,
                               CPUID_EXT_Level2Cache);
      DecodeDescriptor(FCache.EAX, 1);
      DecodeDescriptor(FCache.EBX, 2);
      DecodeDescriptor(FCache.ECX, 3);
      DecodeDescriptor(FCache.EDX, 4);
      cd2.Descriptors := FCacheDescriptors;
      for i := Low(cDescriptorInfo) to High(cDescriptorInfo) do
        if cDescriptorInfo[i].Level = clLevel2 then
        begin
          if DescriptorExists(cDescriptorInfo[i].Descriptor) then
          begin
            if (cDescriptorInfo[i].Descriptor = $49) and not(ibDuoCore in FIntelBrand) then
              Continue;
            cd2.LineSize := cDescriptorInfo[i].LineSize;
            cd2.Size := cDescriptorInfo[i].Size;
            cd2.&Type := cDescriptorInfo[i].Descriptor;
            cd2.Desc := cDescriptorInfo[i].Description;
            cd2.Associativity := cDescriptorInfo[i].Associativity;
          end;
        end;
    end else
    begin
      FCache := ExecuteCPUID(FIndex, CPUID_EXT_Level2Cache);
      if FVendor = cvIDT then
        cd2.Size := HiByte(HiWord(FCache.ECX))
      else
        cd2.Size := HiWord(FCache.ECX);
      cd2.LineSize := LoByte(LoWord(FCache.ECX));
      if (FVendor = cvAmd) and (FFamily = 6) then
        cd2.Associativity := ca16Way
      else
        cd2.Associativity := LookupAssociativity(LoByte(HiWord(FCache.ECX)));
      cd2.&Type := ctUnifiedCache;
      with cd2 do
        Desc := Format('L2 Instruktionen+Daten %d KB, %s, %d Byte Zeilengröße',
                       [Size, cAssociativityDescription[Associativity], LineSize]);
    end;
  end;
  // CPU Cache Level3
  if cd3.&Type = 0 then
  begin
    if cVendorNames[FVendor].CacheDetect <> vcdExtended then
    begin
      if FVendor = cvIntel then
        FCache := ExecuteCPUID(FIndex,
                               CPUID_STD_CacheTlbs,
                               LoByte(LoWord(ExecuteCPUID(FIndex, CPUID_STD_CacheTlbs).EAX)))
      else
        FCache := ExecuteCPUID(FIndex,
                               CPUID_EXT_Level2Cache);
      DecodeDescriptor(FCache.EAX, 1);
      DecodeDescriptor(FCache.EBX, 2);
      DecodeDescriptor(FCache.ECX, 3);
      DecodeDescriptor(FCache.EDX, 4);
      cd3.Descriptors := FCacheDescriptors;
      for i := Low(cDescriptorInfo) to High(cDescriptorInfo) do
        if cDescriptorInfo[i].Level = clLevel3 then
        begin
          if DescriptorExists(cDescriptorInfo[i].Descriptor) then
          begin
            if (cDescriptorInfo[i].Descriptor = $49) and not(ibP4 in FIntelBrand) then
              Continue;
            cd3.Associativity := cDescriptorInfo[i].Associativity;
            cd3.LineSize := cDescriptorInfo[i].LineSize;
            cd3.Size := cDescriptorInfo[i].Size;
            cd3.&Type := cDescriptorInfo[i].Descriptor;
            cd3.Desc := cDescriptorInfo[i].Description;
          end;
        end;
    end;
  end;
  // CPU Cache Trace
  if cVendorNames[FVendor].CacheDetect <> vcdExtended then
  begin
    if FVendor = cvIntel then
      FCache := ExecuteCPUID(FIndex,
                             CPUID_STD_CacheTlbs,
                             LoByte(LoWord(ExecuteCPUID(FIndex, CPUID_STD_CacheTlbs).EAX)))
    else
      FCache := ExecuteCPUID(FIndex,
                             CPUID_EXT_Level2Cache);
    DecodeDescriptor(FCache.EAX, 1);
    DecodeDescriptor(FCache.EBX, 2);
    DecodeDescriptor(FCache.ECX, 3);
    DecodeDescriptor(FCache.EDX, 4);
    cd4.Descriptors := FCacheDescriptors;
    for i := Low(cDescriptorInfo) to High(cDescriptorInfo) do
      if cDescriptorInfo[i].Level = clTrace then
      begin
        if DescriptorExists(cDescriptorInfo[i].Descriptor) then
        begin
          cd4.Associativity := cDescriptorInfo[i].Associativity;
          cd4.LineSize := cDescriptorInfo[i].LineSize;
          cd4.Size := cDescriptorInfo[i].Size;
          cd4.&Type := cDescriptorInfo[i].Descriptor;
          cd4.Desc := cDescriptorInfo[i].Description;
        end;
     end;
  end;
  FCPUCache.SetContent(cd1[clLevel1Code],
                       cd1[clLevel1Data],
                       cd1[clLevel1Unified],
                       cd2,
                       cd3,
                       cd4);
  // CPU Features
  Finalize(fs1);
  Finalize(fs2);
  Finalize(fs3);
  Finalize(fs4);
  ZeroMemory(@FfsStd, SizeOf(TCPUIDRec));
  ZeroMemory(@FfsStdExt, SizeOf(TCPUIDRec));
  ZeroMemory(@FfsStdPM, SizeOf(TCPUIDRec));
  ZeroMemory(@FfsExtPM, SizeOf(TCPUIDRec));
  ZeroMemory(@FfsExt, SizeOf(TCPUIDRec));
  ZeroMemory(@FfsAMDExt, SizeOf(TCPUIDRec));
  ZeroMemory(@FfsAMDSVM, SizeOf(TCPUIDRec));
  FfsStd:=ExecuteCPUID(FIndex, CPUID_STD_FeatureSet);
  FfsStdExt:=ExecuteCPUID(FIndex, CPUID_STD_ExtFeatureSet);
  FfsStdPM:=ExecuteCPUID(FIndex, CPUID_STD_ThermalPower);
  FfsExt:=ExecuteCPUID(FIndex, CPUID_EXT_FeatureSet);
  FfsExtPM:=ExecuteCPUID(FIndex, CPUID_EXT_PowerManagement);
  FfsAMDExt:=ExecuteCPUID(FIndex, CPUID_EXT_AMDExtFeatures);
  FfsAMDSVM:=ExecuteCPUID(FIndex, CPUID_EXT_AMDSVMFeatures);
  GetAvailableFeatures(fsStandard, fs1);
  GetAvailableFeatures(fsExtended, fs2);
  GetAvailableFeatures(fsPowerManagement, fs3);
  GetAvailableFeatures(fsSecureVirtualMachine, fs4);
  FCPUFeatures.SetContent(fs1, fs2, fs3, fs4);

  // CPU Speed
  SetProcAffinity(FIndex);
  try
    FFreq := GetCPUClock;
  finally
    RestoreProcAffinity;
  end;

  // CPU Name, Codename, Revision, Technology
  case FVendor of
    cvIntel    :
      begin
        FIntelBrand := GetIntelBrand;
        if Trim(FMarketingName) <> '' then
        begin
          FCPUName := StringReplace(FMarketingName, 'Intel', '', [rfReplaceAll, rfIgnoreCase]);
          FCPUName := FormatCPUName(FCPUName);
          if ibMobile in FIntelBrand then
            FCPUName := 'Mobile ' + FCPUName;
        end else
        IntelLookupName;
      end;
    cvAmd      :
      if Trim(FMarketingName) <> '' then
      begin
        FCPUName := StringReplace(FMarketingName, 'AMD', '', [rfReplaceAll, rfIgnoreCase]);
        FCPUName := FormatCPUName(FCPUName);
      end else
      AMDLookupName;
    cvCyrix     : CyrixLookupName;
    cvIDT       : IDTLookupName;
    cvNexGen    : NexGenLookupName;
    cvUMC       : UMCLookupName;
    cvRise      : RiseLookupName;
    cvSiS       : SiSLookupName;
    cvGeode     : GeodeLookupName;
    cvTransmeta : TransmetaLookupName;
  end;

  if FCodename = '' then
  begin
    GetCPUCodename(FIndex, Integer(FVendor), FFamily, FModelEx, FSteppingEx, FCodeName, s, r, t);
    FCodename := Trim(FCodename + ' ' + s);
    if FTech = '' then
      FTech := IntToStr(t) + ' nm';
    if FRevision = '' then
      FRevision := r;
  end;

  if FCPP > 1 then
    FCC := FPC * FCPP
  else
    FCC := FCount div FLPC;
  if FLPP = 0 then
    FLPP := FTC div FPC;
  if FLPC = 0 then
    FLPC := FTC div FCC;

  if Assigned(GetLogicalProcessorInformationEx) then
  begin
    c := 0;
    p := 0;
    l := 0;
    n := 0;
    GetLogicalProcessorInformationEx(RelationAll, nil, n);
    buf2 := AllocMem(n);
    try
      if GetLogicalProcessorInformationEx(RelationAll, buf2, n) then
      begin
        FCPUCache.Clear;
        slpiex := buf2;
        while (NativeUInt(slpiex) - NativeUInt(buf2)) < n do
        begin
          case slpiex.Relationship of
            RelationProcessorPackage : begin
              m := 0;
              for k := 0 to slpiex.Processor.GroupCount - 1 do
                Inc(m, CountSetBits(slpiex.Processor.GroupMask[k].Mask));
              if m > 0 then
                Inc(p);
            end;
            RelationProcessorCore : begin
              Inc(c);
              for k := 0 to slpiex.Processor.GroupCount - 1 do
                Inc(l, CountSetBits(slpiex.Processor.GroupMask[k].Mask));
            end;
            RelationCache : with slpiex.Cache do
              FCPUCache.AddData(&Type, Level, Associativity, LineSize, CacheSize shr 10);
          end;
          slpiex := PSystemLogicalProcessorInformationEx(NativeUInt(slpiex) + slpiex.Size);
        end;
        FCC := Max(c, 1);
        FPC := Max(p, 1);
        FTC := Max(l, 1);
        FLPP := FTC div FPC;
        FCPP := FCC div FPC;
        FLPC := FTC div FCC;
        FSC := FPC;
      end;
    finally
      Freemem(buf2);
    end;
  end else
  if Assigned(GetLogicalProcessorInformation) then
  begin
    l := 0;
    p := 0;
    c := 0;
    n := 0;
    if not GetLogicalProcessorInformation(nil, n) then
    begin
      buf1 := AllocMem(n);
      try
        if GetLogicalProcessorInformation(buf1, n) then
        begin
          FCPUCache.Clear;
          slpi := buf1;
          while (NativeUInt(slpi) - NativeUInt(buf1)) < n do
          begin
            case slpi.Relationship of
              RelationProcessorPackage : Inc(p);
              RelationProcessorCore : begin
                Inc(l, CountSetBits(slpi.ProcessorMask));
                Inc(c);
              end;
              RelationCache : with slpi.Cache do
                FCPUCache.AddData(&Type, Level, Associativity, LineSize, Size shr 10);
            end;
            slpi := PSystemLogicalProcessorInformation(NativeUInt(slpi) +
                    SizeOf(TSystemLogicalProcessorInformation));
          end;
          FCC := Max(c, 1);
          FPC := Max(p, FPC);
          FTC := Max(l, FTC);
          FLPP := FTC div FPC;
          FCPP := FCC div FPC;
          FLPC := FTC div FCC;
          FSC := FPC;
        end;
      finally
        FreeMem(buf1);
      end;
    end;
  end;

  // Final Cache adjustments
  FCPUCache.Trace.SharedWays := FCPUCache.Trace.SharedWays div FPC;
  FCPUCache.Level1.Data.SharedWays := FCPUCache.Level1.Data.SharedWays div FPC;
  FCPUCache.Level1.Code.SharedWays := FCPUCache.Level1.Code.SharedWays div FPC;
  FCPUCache.Level1.Unified.SharedWays := FCPUCache.Level1.Unified.SharedWays div FPC;
  FCPUCache.Level2.SharedWays := FCPUCache.Level2.SharedWays div FPC;
  FCPUCache.Level3.SharedWays := FCPUCache.Level3.SharedWays div FPC;
end;

{ MSR related functions }

function TProcessor.GetIntelAMD_MicrocodeUpdate : Cardinal;
var
  InputBuf : ReadMSRInputStruct;
  OutputBuf : ReadMSROutputStruct;
begin
  Result := 0;

  if (FParent.DriverStatus <> Running) or
     (FParent.DriverHandle = INVALID_HANDLE_VALUE) then
    Exit;

  if FVendor in [cvIntel, cvAMD] then
  begin
    InputBuf.ECXReg := $8B; {Intel: IA32_BIOS_SIGN_ID, AMD: PATCH_LEVEL}
    if FParent.Driver_ReadMSR(InputBuf, OutputBuf) then
    case FVendor of
      cvIntel : Result := OutputBuf.EDXReg;
      cvAMD   : Result := OutputBuf.EAXReg;
    end;
  end;
end;

function TProcessor.GetIntelTjMax : Byte;
var
  InputBuf : ReadMSRInputStruct;
  OutputBuf : ReadMSROutputStruct;
begin
  Result := 0;

  if (FParent.DriverStatus <> Running) or
     (FParent.DriverHandle = INVALID_HANDLE_VALUE) then
    Exit;

  if FVendor = cvIntel then
  begin
    Result := 85; {Standard-Wert, falls es zu keiner Ermittlung kommen sollte}

    InputBuf.ECXReg := $1A2; {MSR_TEMPERATURE_TARGET}
    if FParent.Driver_ReadMSR(InputBuf, OutputBuf) then
    begin
      if ((OutputBuf.EAXReg shr 16) and $FF) <> 0 then
        Result := ((OutputBuf.EAXReg shr 16) and $FF);
    end else
    begin
      InputBuf.ECXReg := $EE; {EXT_CONFIG}
      if FParent.Driver_ReadMSR(InputBuf, OutputBuf) then
      begin
        if IsBitOn(OutputBuf.EAXReg, 30) then
          Result := 85
        else
          Result := 100;
      end;
    end;
  end;
end;

{ TPCIBus }

constructor TPCIBus.Create(Parent : TSystemAccess);
begin
  inherited Create;
  FParent := Parent;

  PCIVendorList := TStringList.Create;
  (PCIVendorList as TStringList).Sorted := True;
  (PCIVendorList as TStringList).Duplicates := dupIgnore;

  PCIDeviceList := TStringList.Create;
  (PCIDeviceList as TStringList).Sorted := True;
  (PCIDeviceList as TStringList).Duplicates := dupIgnore;

  PCISubDeviceList := TStringList.Create;
  (PCISubDeviceList as TStringList).Sorted := True;
  (PCISubDeviceList as TStringList).Duplicates := dupIgnore;
end;

procedure TPCIBus.Clear;
begin
  FPCIDCount := 0;
  FSMBusBaseAddress := 0;
  FSMBusControllerName := '';
  SetLength(FPCIDevices, 0);
end;

destructor TPCIBus.Destroy;
begin
  PCIVendorList.Free;
  PCIDeviceList.Free;
  PCISubDeviceList.Free;

  inherited;
end;

function TPCIBus.DetectPCIDevices : Boolean;
var
  InputBuf  : ReadPCIInputStruct;
  OutputBuf : ReadPCIOutputStruct;
  PortBase : LongWord;
  Vendor, Device : Word;
  RegisterCnt, ContentPosition,
  BusNr, Dev, DeviceID,
  CurrentFunction, MaxFunctions : Byte;
  DevIndex : Integer;
begin
  Result := False;
  FPCIDCount := 0;

  if (FParent.DriverStatus <> Running) or
     (FParent.DriverHandle = INVALID_HANDLE_VALUE) then
    Exit;

  {Schleife mit max. 256 Bus-Nummern beginnen}
  for BusNr := 0 to $FF do
  begin
    {pro Bus mit max. 32 Geräte fortfahren}
    for Dev := 0 to $1F do
    begin
      MaxFunctions := 1;
      CurrentFunction := 0;
      while CurrentFunction <> MaxFunctions do
      begin
        Inc(CurrentFunction, 1);

        {zusammensetzen des Configuration Address Register}
        {- zunächst die Geräte- und Funktionsnummern}
        DeviceID := Dev;
        DeviceID := DeviceID shl 3;
        DeviceID := DeviceID + ((CurrentFunction - 1) and $F);
        {- dann das vollständige Register}
        PortBase := $80;
        PortBase := (PortBase shl 8) or BusNr;
        PortBase := (PortBase shl 8) or DeviceID;
        PortBase := (PortBase shl 8) or $00;
        InputBuf.PortNumber := PortBase;
        if FParent.Driver_ReadPCI(InputBuf, OutputBuf) then
        begin
          {Vendor und Device temporär zusammensetzen...}
          Vendor := OutputBuf.DataBuffer and $FFFF;
          Device := (OutputBuf.DataBuffer shr 16) and $FFFF;

          {...und auf allgemeine Gültigkeit prüfen}
          if (Vendor <> $FFFF) and (Device <> $FFFF) then
          begin
            {Zähler erhöhen und neues Gerät im Array anlegen}
            Inc(FPCIDCount, 1);

            DevIndex := Length(FPCIDevices);
            SetLength(FPCIDevices, DevIndex + 1);
            FPCIDevices[DevIndex].Bus := BusNr;
            FPCIDevices[DevIndex].Dev := Dev;
            FPCIDevices[DevIndex].Func := CurrentFunction - 1;

            {64 LongWords pro PCI-Gerät (64 x 4 Byte = 256 Byte}
            for RegisterCnt := 0 to 63 do
            begin
              {Portnummer mit Registernummer erhöhen und dann lesen}
              ContentPosition := RegisterCnt * 4;
              InputBuf.PortNumber := PortBase + ContentPosition;
              if FParent.Driver_ReadPCI(InputBuf, OutputBuf) then
              begin
                {Sonderbehandlungen für Record-Einträge}
                case ContentPosition of
                  $00 : begin
                          FPCIDevices[DevIndex].VendorID :=
                            OutputBuf.DataBuffer and $FFFF;
                          FPCIDevices[DevIndex].DeviceID :=
                            (OutputBuf.DataBuffer shr 16) and $FFFF;
                        end;
                  $08 : begin //Revision + (Sub)-Class + Prg. Interface
                          FPCIDevices[DevIndex].Rev :=
                            OutputBuf.DataBuffer and $FF;
                          FPCIDevices[DevIndex].PrgInt :=
                            (OutputBuf.DataBuffer shr 8) and $FF;
                          FPCIDevices[DevIndex].SubClassID :=
                            (OutputBuf.DataBuffer shr 16) and $FF;
                          FPCIDevices[DevIndex].ClassID :=
                            (OutputBuf.DataBuffer shr 24) and $FF;
                        end;
                  $0C : begin
                          if (OutputBuf.Databuffer shr 16) and $80 = $80 then
                            MaxFunctions := 8;
                        end;
                  $2C : begin //SubVendor & SubDevice
                          FPCIDevices[DevIndex].SubVendorID :=
                            OutputBuf.DataBuffer and $FFFF;
                          FPCIDevices[DevIndex].SubDeviceID :=
                            (OutputBuf.DataBuffer shr 16) and $FFFF;
                        end;
                end;

                {jedes Byte im Array speichern}
                FPCIDevices[DevIndex].PCIContent[ContentPosition + 0] :=
                  (OutputBuf.DataBuffer shr 00) and $FF;
                FPCIDevices[DevIndex].PCIContent[ContentPosition + 1] :=
                  (OutputBuf.DataBuffer shr 08) and $FF;
                FPCIDevices[DevIndex].PCIContent[ContentPosition + 2] :=
                  (OutputBuf.DataBuffer shr 16) and $FF;
                FPCIDevices[DevIndex].PCIContent[ContentPosition + 3] :=
                  (OutputBuf.DataBuffer shr 24) and $FF;
              end;
            end;
          end;
        end;
      end;
    end;
  end;

  Result := Boolean(FPCIDCount > 0);
  if Result then
    GetSMBusBaseAddress;
end;

function TPCIBus.GetBaseClassName(AIndex : Integer) : String;
begin
  Result := 'unbekannt';

  case FPCIDevices[AIndex].ClassID of
    $00      : Result := 'keine';
    $01      : Result := 'Massenspeicher';
    $02      : Result := 'Netzwerk';
    $03      : Result := 'Anzeige';
    $04      : Result := 'Multimedia';
    $05      : Result := 'Speicher';
    $06      : Result := 'Brücke';
    $07      : Result := 'Kommunikation';
    $08      : Result := 'System';
    $09      : Result := 'Eingabegerät(e)';
    $0A      : Result := 'Docking Station';
    $0B      : Result := 'Prozessor';
    $0C      : Result := 'Seriell';
    $0D      : Result := 'Kabellos';
    $0E      : Result := 'Intelligent E/A';
    $0F      : Result := 'Satellitenkommunikation';
    $10      : Result := 'Ver-/Entschlüsselung';
    $11      : Result := 'Daten-Beschaffung';
    $12      : Result := 'Verarbeitungsbeschleuniger';
    $13..$FE : Result := 'reserviert';
    $FF      : Result := 'keine';
  end;
end;

function TPCIBus.GetSubClassName(AIndex : Integer) : String;
begin
  Result := 'unbekannt';

  case FPCIDevices[AIndex].ClassID of
    $00 : case FPCIDevices[AIndex].SubClassID of
            $01 : Result := 'VGA'
          end;
    $01 : case FPCIDevices[AIndex].SubClassID of
            $00 : Result := 'SCSI';
            $01 : Result := 'IDE';
            $02 : Result := 'Diskette';
            $03 : Result := 'IPI';
            $04 : Result := 'RAID';
            $05 : case FPCIDevices[AIndex].PrgInt of
                    $20 : Result := 'ATA, Einfach DMA';
                    $30 : Result := 'ATA, Verkettet DMA';
                    else  Result := 'ATA';
                  end;
            $06 : case FPCIDevices[AIndex].PrgInt of
                    $00 : Result := 'Seriell ATA (herst.-spez.)';
                    $01 : Result := 'Seriell ATA (AHCI 1.0)';
                    $02 : Result := 'Serielle Speicherbus-Schnittstelle';
                    else  Result := 'Seriell ATA';
                  end;
            $07 : case FPCIDevices[AIndex].PrgInt of
                    $00 : Result := 'Seriell angeschlossenes SCSI (SAS)';
                    $01 : Result := 'Serielle Speicherbus-Schnittstelle';
                    else  Result := 'Seriell angeschlossenes SCSI (SAS)';
                  end;
            $08 : case FPCIDevices[AIndex].PrgInt of
                    $00 : Result := 'SSD Speicher';
                    $01 : Result := 'SSD Speicher (NVMHCI 1.0)';
                    $02 : Result := 'SSD Speicher (Enterprise NVMHCI 1.0)';
                    else  Result := 'SSD Speicher';
                  end;
            else  Result := 'Massenspeicher';
          end;
    $02 : case FPCIDevices[AIndex].SubClassID of
            $00 : Result := 'Ethernet';
            $01 : Result := 'Token Ring';
            $02 : Result := 'FDDI';
            $03 : Result := 'ATM';
            $04 : Result := 'ISDN';
            $05 : Result := 'WorldFip';
            $06 : Result := 'PICMG 2.14';
            $07 : Result := 'InfiniBand';
            else  Result := 'Netzwerk';
          end;
    $03 : case FPCIDevices[AIndex].SubClassID of
            $00 : case FPCIDevices[AIndex].PrgInt and 1 of
                    0 :  Result := 'VGA';
                    1 :  Result := '8514';
                    else Result := 'VGA/8514';
                  end;
            $01 : Result := 'XGA';
            $02 : Result := '3D-Grafik';
            else  Result := 'Anzeige';
          end;
    $04 : case FPCIDevices[AIndex].SubClassID of
            $00 : Result := 'Video';
            $01 : Result := 'Audio';
            $02 : Result := 'Computer-Telefon';
            $03 : Result := 'Gemischtes Modus-Gerät';
            else  Result := 'Multimedia';
          end;
    $05 : case FPCIDevices[AIndex].SubClassID of
            $00 : Result := 'RAM';
            $01 : Result := 'Flash';
            else  Result := 'Speicher';
          end;
    $06 : case FPCIDevices[AIndex].SubClassID of
            $00 : Result := 'PCI-zu-HOST';
            $01 : Result := 'PCI-zu-ISA';
            $02 : Result := 'PCI-zu-EISA';
            $03 : Result := 'PCI-zu-MCA';
            $04 : case FPCIDevices[AIndex].PrgInt of
                    $00 : Result := 'PCI-zu-PCI';
                    $01 : Result := 'Subtraktive Dekodierung PCI-zu-PCI';
                    else  Result := 'PCI-zu-PCI';
                  end;
            $05 : Result := 'PCI-zu-PCMCIA';
            $06 : Result := 'PCI-zu-NuBus';
            $07 : Result := 'PCI-zu-CardBus';
            $08 : Result := 'PCI-zu-RACEway';
            $09 : Result := 'Semi-transparentes PCI-zu-PCI';
            $0A : Result := 'InfiBand-zu-PCI';
            $0B : case FPCIDevices[AIndex].PrgInt of
                    $00 : Result := 'Erw. Umschaltung-zu-PCI (Benutzerdef.)';
                    $01 : Result := 'Erw. Umschaltung-zu-PCI (ASI-SIG)';
                    else  Result := 'Erw. Umschaltung-zu-PCI';
                  end;
            else  Result := 'Brücke';
          end;
    $07 : case FPCIDevices[AIndex].SubClassID of
            $00 : case FPCIDevices[AIndex].PrgInt of
                    $00 : Result := 'XT Seriell';
                    $01 : Result := '16450 Seriell';
                    $02 : Result := '16550 Seriell';
                    $03 : Result := '16650 Seriell';
                    $04 : Result := '16750 Seriell';
                    $05 : Result := '16850 Seriell';
                    $06 : Result := '16950 Seriell';
                    else  Result := 'Seriell';
                  end;
            $01 : case FPCIDevices[AIndex].PrgInt of
                    $00 : Result := 'Parallel';
                    $01 : Result := 'Bidirektional Parallel';
                    $02 : Result := 'ECP 1.x Parallel';
                    $03 : Result := 'IEEE 1284, Parallel Kontroller';
                    $FE : Result := 'IEEE 1284, Parallel Gerät';
                    else  Result := 'Parallel';
                  end;
            $02 : Result := 'Multiport Seriell';
            $03 : case FPCIDevices[AIndex].PrgInt of
                    $00 : Result := 'Modem';
                    $01 : Result := 'Modem, 16450 Schnittstelle';
                    $02 : Result := 'Modem, 16550 Schnittstelle';
                    $03 : Result := 'Modem, 16650 Schnittstelle';
                    $04 : Result := 'Modem, 16750 Schnittstelle';
                    else  Result := 'Hayes-Modem';
                  end;
            $04 : Result := 'GPIB (IEEE 488.1/2)';
            $05 : Result := 'Smart Card';
            else  Result := 'Kommunikation';
          end;
    $08 : case FPCIDevices[AIndex].SubClassID of
            $00 : case FPCIDevices[AIndex].PrgInt of
                    $00 : Result := '8259 PIC';
                    $01 : Result := 'ISA PIC';
                    $02 : Result := 'EISA PIC';
                    $10 : Result := 'I/O APIC';
                    $20 : Result := 'I/O(x) APIC';
                    else  Result := 'PIC 8259';
                  end;
            $01 : case FPCIDevices[AIndex].PrgInt of
                    $00 : Result := '8237 DMA';
                    $01 : Result := 'ISA DMA';
                    $02 : Result := 'EISA DMA';
                    else  Result := '8237 DMA';
                  end;
            $02 : case FPCIDevices[AIndex].PrgInt of
                    $00 : Result := '8254 System-Zeitgeber';
                    $01 : Result := 'ISA System-Zeitgeber';
                    $02 : Result := 'EISA System-Zeitgeber';
                    $03 : Result := 'Hochleistungs-Ereignis-Zeitgeber';
                    else  Result := '8254 System-Zeitgeber';
                  end;
            $03 : case FPCIDevices[AIndex].PrgInt of
                    $00 : Result := 'RTC';
                    $01 : Result := 'ISA RTC';
                    else  Result := 'RTC';
                  end;
            $04 : Result := 'PCI Hot-Plug';
            $05 : Result := 'SD Host';
            $06 : Result := 'E/A MMU';
            else  Result := 'System';
          end;
    $09 : case FPCIDevices[AIndex].SubClassID of
            $00 : Result := 'Tastatur';
            $01 : Result := 'Digitizer (Stift)';
            $02 : Result := 'Maus';
            $03 : Result := 'Scanner';
            $04 : Result := 'Game Port';
            else  Result := 'Eingabegerät(e)';
          end;
   $0A : Result := 'Docking Station';
   $0B : case FPCIDevices[AIndex].SubClassID of
           $00 : Result := '386';
           $01 : Result := '486';
           $02 : Result := 'Pentium';
           $03 : Result := 'Pentium Pro';
           $10 : Result := 'DEC Alpha';
           $20 : Result := 'PowerPC';
           $30 : Result := 'MIPS';
           $40 : Result := 'Koprozessor';
           else  Result := 'Prozessor';
         end;
   $0C : case FPCIDevices[AIndex].SubClassID of
           $00 : case FPCIDevices[AIndex].PrgInt of
                   $00 : Result := 'IEEE 1394 Firewire';
                   $10 : Result := 'IEEE 1394 Firewire, OpenHCI';
                   else  Result := 'IEEE 1394 Firewire';
                 end;
           $01 : Result := 'ACCESS.Bus';
           $02 : Result := 'SSA';
           $03 : case FPCIDevices[AIndex].PrgInt of
                   $00 : Result := 'USB (UHC)';
                   $10 : Result := 'USB (OHC)';
                   $20 : Result := 'USB2 (EHC)';
                   $30 : Result := 'USB3 (xHCI)';
                   $FE : Result := 'USB-Gerät';
                   else  Result := 'USB';
                 end;
           $04 : Result := 'Fibre Channel';
           $05 : Result := 'SMBus';
           $06 : Result := 'InfiniBand';
           $07 : case FPCIDevices[AIndex].PrgInt of
                   $00 : Result := 'IPMI SMIC-Schnittstele';
                   $01 : Result := 'IPMI Tastatur-Schnittstelle';
                   $02 : Result := 'IPMI Block Transfer-Schnittstelle';
                   else  Result := 'IPMI';
                 end;
           $08 : Result := 'SERCOS (IEC 61491)';
           $09 : Result := 'CANbus';
           else  Result := 'Seriell';
         end;
   $0D : case FPCIDevices[AIndex].SubClassID of
           $00 : Result := 'iRDA';
           $01 : Result := 'IR';
           $10 : Result := 'RF';
           $11 : Result := 'Bluetooth';
           $12 : Result := 'Breitband';
           $20 : Result := 'Ethernet (802.11a - 5 GHz)';
           $21 : Result := 'Ethernet (802.11b - 2.4 GHz)';
           else  Result := 'Kabellos';
         end;
   $0E : Result := 'Intelligent E/A';
   $0F : case FPCIDevices[AIndex].SubClassID of
           $01 : Result := 'TV';
           $02 : Result := 'Audio';
           $03 : Result := 'Sprache';
           $04 : Result := 'Daten';
           else  Result := 'Satellitenkomm.-Gerät';
         end;
   $10: case FPCIDevices[AIndex].SubClassID of
          $00 : Result := 'Netzwerk/PC Ver-/Entschlüsseler';
          $10 : Result := 'Unterhaltungs Ver-/Entschlüsseler';
          else  Result := 'Ver-/Entschlüsseler';
        end;
   $11: case FPCIDevices[AIndex].SubClassID of
          $00 : Result := 'DPIO-Modul';
          $01 : Result := 'Performance-Zähler';
          $10 : Result := 'Komm. Sync, Zeit+Frequenz';
          $20 : Result := 'Verwaltungskarte';
          else  Result := 'Daten-Beschaffung';
        end;
   $12: Result := 'Verarbeitungsbeschleuniger';
  end;
end;

procedure TPCIBus.GetSMBusBaseAddress;
var
  PCIDevCnt : Integer;
  WordValue : Word;
  WriteInputBuf : WritePCIInputStruct;
  WriteOutputBuf : WritePCIOutputStruct;
  DataBase,
  PortBase : LongWord;
  DeviceID : Byte;
begin
  if PCIDeviceCount = 0 then
    Exit;

  for PCIDevCnt := 0 to PCIDeviceCount - 1 do
  begin
    case FPCIDevices[PCIDevCnt].VendorID of
      $8086 : case FPCIDevices[PCIDevCnt].DeviceID of {Intel}
                $7113,
                $719B,
                $7603 : begin
                          if (FPCIDevices[PCIDevCnt].ClassID = $C) and
                             (FPCIDevices[PCIDevCnt].SubClassID = 5) then
                          begin
                            WordValue := MakeWord(FPCIDevices[PCIDevCnt].PCIContent[$90],
                                                  FPCIDevices[PCIDevCnt].PCIContent[$91]);
                            FSMBusBaseAddress := WordValue and $FFF0; {Register 90-91 Bits 4-15}

                            case FPCIDevices[PCIDevCnt].DeviceID of
                              $7113 : FSMBusControllerName := 'Intel 82371AB PIIX4E Function 3: Advanced Power Management';
                              $719B : FSMBusControllerName := 'Intel 82440MX PIIX4 Mobile';
                              $7603 : FSMBusControllerName := 'Intel 82372FB PIIX5 SMBus Controller';
                            end;
                            Break;
                          end;
                        end;
                $02A3,  {Intel Comet Lake SMBus Host Controller}
                $06A3,  {Intel Comet Lake-H SMBus Host Controller}
                $0AD4,  {Intel Broxton SoC SMBus Host Controller}
                $0C59,  {Intel Centerton SMBus 2.0 Controller 0}
                $0C5A,  {Intel Centerton SMBus 2.0 Controller 1}
                $0C5B,  {Intel Atom Processor S1200 SMBus Controller 2}
                $0C5C,  {Intel Atom Processor S1200 SMBus Controller 3}
                $0C5D,  {Intel Atom Processor S1200 SMBus Controller 4}
                $0C5E,  {Intel Atom Processor S1200 SMBus Controller 5}
                $0F12,  {Intel ValleyView SMBus Controller}
                $0F13,  {Intel ValleyView SMBus Controller}

                $18DF,  {Intel "Cedar Fork" SMBus Contoller}
                $19AC,  {Intel DNV SMBus Contoller}
                $19DF,  {Intel DNV SMBus Controller}
                $1BC9,  {Intel Emmitsburg SMBus Host Controller}
                $1C22,  {Intel 6 Series "Sandy Bridge/Cougar Point" SMBus Controller}
                $1CA2,  {Intel PCH SMBus Controller}
                $1D22,  {Intel C600/X79 Series "Sandy Bridge-E/Patsburg" SMBus Controller}
                $1D70,  {Intel C600/X79 Series "Patsburg SCU0" Chipset SMBus Controller}
                $1D71,  {Intel C608/C606/X79 Series "Patsburg SCU1" Chipset SMBus Controller}
                $1D72,  {Intel C608 Chipset SMBus Controller}
                $1DA2,  {Intel PCH SMBus Controller}
                $1E22,  {Intel 7 Series/C216 "Panther Point" SMBus Controller}
                $1EA2,  {Intel PCH SMBus Controller}
                $1F15,  {Intel Avoton SMBus 2.0}
                $1F3C,  {Intel Avoton PCU SMBus}
                $1F3D,  {Intel Avoton PCU SMBus}

                $2292,  {Intel Braswell Platform Controller Unit SMBus}
                $2330,  {Intel DH89xxCC SMBus Controller}
                $23B0,  {Intel Coleto Creek SMBus Controller}
                $2413,  {Intel ICH1 - 82801-AA SMBus Controller}
                $2423,  {Intel ICH1 - 82801-AB SMBUS Controller}
                $2443,  {Intel ICH2 - 82801-BA SMBus Controller}
                $2453,  {Intel 82801E SMBus Controller}
                $2483,  {Intel ICH3 - 82801-CA/CAM SMBus Controller}
                $24C3,  {Intel ICH4 - 82801-DB SMBus Controller}
                $24D3,  {Intel ICH5 - 82801-EB SMBus Controller}
                $25A4,  {Intel 6300ESB SMBus Controller}
                $266A,  {Intel ICH6 - 82801-FB SMBus Controller}
                $269B,  {Intel Enterprise Southbridge - ESB2 SMBus Controller}
                $27DA,  {Intel ICH7 - 82801-G SMBus Controller}
                $283E,  {Intel ICH8 - 82801-H SMBus Controller}
                $2930,  {Intel ICH9 - 82801-I SMBus Controller}

                $31D4,  {Intel Celeron/Pentium Silver Processor Gaussian Mixture Model "Gemini Lake"}
                $34A3,  {Intel Ice Lake-LP SMBus Controller}
                $38A3,  {Intel Ice Lake-N SMBus Host Controller}
                $3A30,  {Intel ICH10 - 82801-JR (Consumer) SMBus Controller}
                $3A60,  {Intel ICH10 - 82801-JD (Corporate) SMBus Controller}
                $3B30,  {Intel 5 Series/3400 Series Chipset Family SMBus Controller}

                $43A3,  {Intel Tiger Lake-H SMBus Host Controller}
                $4B23,  {Intel Elkhart Lake SMBus Host Controller}
                $4DA3,  {Intel Jasper Lake SMBus Host Controller}

                $5032,  {Intel Tolapai SMBus Controller}
                $51A3,  {Intel Alder Lake-P/M SMBus Host Controller}
                $54A3,  {Intel Alder Lake-M SMBus Host Controller}
                $5AD4,  {Intel Broxton SMBus Controller}

                $7A23,  {Intel Raptor Lake-S SMBus Host Controller}
                $7AA3,  {Intel Alder Lake-S SMBus Host Controller}

                $8186,  {Intel Atom E6xx}
                $8119,  {Intel Poulsbo}
                $85A4,  {Intel 6300ESB SMBus Controller}
                $8C22,  {Intel 8 Series/C220 Series "Lynx Point" SMBus Controller}
                $8CA2,  {Intel 9 Series Chipset Family "Wildcat Point" SMBus Controller}
                $8D22,  {Intel C610 Series Chipset & X99 Chipset "Wellsburg" SMBus Controller}
                $8D7D,  {Intel C610 Series Chipset & X99 Chipset "Wellsburg" SMBus 0 Controller}
                $8D7E,  {Intel C610 Series Chipset & X99 Chipset "Wellsburg" SMBus 1 Controller}
                $8D7F,  {Intel C610 Series Chipset & X99 Chipset "Wellsburg" SMBus 2 Controller}

                $9C22,  {Intel Lynx Point-LP SMBus Controller}
                $9CA2,  {Intel Wildcat Point-LP SMBus Controller}
                $9D23,  {Intel Sunrise Point-LP SMBus Controller}
                $9DA3,  {Intel Cannon Lake-LP SMBus Controller}

                $A0A3,  {Intel Tiger Lake-LP SMBus Host Controller}
                $A123,  {Intel Sunrise Point-H SMBus Controller}
                $A1A3,  {Intel Lewisburg SMBus Controller}
                $A223,  {Intel C620 Series Chipset "Lewisburg" SMBus Controller}
                $A2A3,  {Intel 200 Series/Z370 Chipset Family SMBus Controller}
                $A323,  {Intel Cannon Lake-H PCH SMBus Controller}
                $A3A3 : {Intel Comet Lake-V SMBus Host Controller}
                        begin
                          IF (FPCIDevices[PCIDevCnt].ClassID = $C) and
                             (FPCIDevices[PCIDevCnt].SubClassID = 5) then
                          begin
                            WordValue := MakeWord(FPCIDevices[PCIDevCnt].PCIContent[$20],
                                                  FPCIDevices[PCIDevCnt].PCIContent[$21]);
                            FSMBusBaseAddress := WordValue and $FFE0; {Register 20-21 Bits 5-15}

                            case FPCIDevices[PCIDevCnt].DeviceID of
                              $02A3 : FSMBusControllerName := 'Intel Comet Lake SMBus Host Controller';
                              $06A3 : FSMBusControllerName := 'Intel Comet Lake-H SMBus Host Controller';
                              $0AD4 : FSMBusControllerName := 'Intel Broxton SoC SMBus Host Controller';
                              $0C59 : FSMBusControllerName := 'Intel Centerton SMBus 2.0 Controller 0';
                              $0C5A : FSMBusControllerName := 'Intel Centerton SMBus 2.0 Controller 1';
                              $0C5B : FSMBusControllerName := 'Intel Atom Processor S1200 SMBus Controller 2';
                              $0C5C : FSMBusControllerName := 'Intel Atom Processor S1200 SMBus Controller 3';
                              $0C5D : FSMBusControllerName := 'Intel Atom Processor S1200 SMBus Controller 4';
                              $0C5E : FSMBusControllerName := 'Intel Atom Processor S1200 SMBus Controller 5';
                              $0F12 : FSMBusControllerName := 'Intel ValleyView SMBus Controller';
                              $0F13 : FSMBusControllerName := 'Intel ValleyView SMBus Controller';

                              $18DF : FSMBusControllerName := 'Intel "Cedar Fork" SMBus Controller';
                              $19AC : FSMBusControllerName := 'Intel DNV SMBus Controller';
                              $19DF : FSMBusControllerName := 'Intel DNV SMBus Controller';
                              $1BC9 : FSMBusControllerName := 'Intel Emmitsburg SMBus Host Controller';
                              $1C22 : FSMBusControllerName := 'Intel 6 Series "Sandy Bridge/Cougar Point" SMBus Controller';
                              $1CA2 : FSMBusControllerName := 'Intel PCH SMBus Controller';
                              $1D22 : FSMBusControllerName := 'Intel C600/X79 Series "Sandy Bridge-E/Patsburg" SMBus Controller';
                              $1D70 : FSMBusControllerName := 'Intel C600/X79 Series "Patsburg SCU0" Chipset SMBus Controller';
                              $1D71 : FSMBusControllerName := 'Intel C608/C606/X79 Series "Patsburg SCU1" Chipset SMBus Controller';
                              $1D72 : FSMBusControllerName := 'Intel C608 Chipset SMBus Controller';
                              $1DA2 : FSMBusControllerName := 'Intel PCH SMBus Controller';
                              $1E22 : FSMBusControllerName := 'Intel 7 Series/C216 "Panther Point" SMBus Controller';
                              $1EA2 : FSMBusControllerName := 'Intel PCH SMBus Controller';
                              $1F15 : FSMBusControllerName := 'Intel Avoton SMBus 2.0';
                              $1F3C : FSMBusControllerName := 'Intel Avoton PCU SMBus';
                              $1F3D : FSMBusControllerName := 'Intel Avoton PCU SMBus';

                              $2292 : FSMBusControllerName := 'Intel Braswell Platform Controller Unit SMBus';
                              $2330 : FSMBusControllerName := 'Intel DH89xxCC SMBus Controller';
                              $23B0 : FSMBusControllerName := 'Intel Coleto Creek SMBus Controller';
                              $2413 : FSMBusControllerName := 'Intel ICH1 - 82801-AA SMBus Controller';
                              $2423 : FSMBusControllerName := 'Intel ICH1 - 82801-AB SMBUS Controller';
                              $2443 : FSMBusControllerName := 'Intel ICH2 - 82801-BA SMBus Controller';
                              $2453 : FSMBusControllerName := 'Intel 82801E SMBus Controller';
                              $2483 : FSMBusControllerName := 'Intel ICH3 - 82801-CA/CAM SMBus Controller';
                              $24C3 : FSMBusControllerName := 'Intel ICH4 - 82801-DB SMBus Controller';
                              $24D3 : FSMBusControllerName := 'Intel ICH5 - 82801-EB SMBus Controller';
                              $25A4 : FSMBusControllerName := 'Intel 6300ESB SMBus Controller';
                              $266A : FSMBusControllerName := 'Intel ICH6 - 82801-FB SMBus Controller';
                              $269B : FSMBusControllerName := 'Intel Enterprise Southbridge - ESB2 SMBus Controller';
                              $27DA : FSMBusControllerName := 'Intel ICH7 - 82801-G SMBus Controller';
                              $283E : FSMBusControllerName := 'Intel ICH8 - 82801-H SMBus Controller';
                              $2930 : FSMBusControllerName := 'Intel ICH9 - 82801-I SMBus Controller';

                              $31D4 : FSMBusControllerName := 'Intel Celeron/Pentium Silver Processor Gaussian Mixture Model "Gemini Lake"';
                              $34A3 : FSMBusControllerName := 'Intel Ice Lake-LP SMBus Controller';
                              $38A3 : FSMBusControllerName := 'Intel Ice Lake-N SMBus Host Controller';
                              $3A30 : FSMBusControllerName := 'Intel ICH10 - 82801-JR (Consumer) SMBus Controller';
                              $3A60 : FSMBusControllerName := 'Intel ICH10 - 82801-JD (Corporate) SMBus Controller';
                              $3B30 : FSMBusControllerName := 'Intel 5 Series/3400 Series Chipset Family SMBus Controller';

                              $43A3 : FSMBusControllerName := 'Intel Tiger Lake-H SMBus Host Controller';
                              $4B23 : FSMBusControllerName := 'Intel Elkhart Lake SMBus Host Controller';
                              $4DA3 : FSMBusControllerName := 'Intel Jasper Lake SMBus Host Controller';

                              $5032 : FSMBusControllerName := 'Intel Tolapai SMBus Controller';
                              $51A3 : FSMBusControllerName := 'Intel Alder Lake-P/M SMBus Host Controller';
                              $54A3 : FSMBusControllerName := 'Intel Alder Lake-M SMBus Host Controller';
                              $5AD4 : FSMBusControllerName := 'Intel Broxton SMBus Controller';

                              $7A23 : FSMBusControllerName := 'Intel Raptor Lake-S SMBus Host Controller';
                              $7AA3 : FSMBusControllerName := 'Intel Alder Lake-S SMBus Host Controller';

                              $8186 : FSMBusControllerName := 'Intel Atom E6xx';
                              $8119 : FSMBusControllerName := 'Intel Poulsbo';
                              $85A4 : FSMBusControllerName := 'Intel 6300ESB SMBus Controller';
                              $8C22 : FSMBusControllerName := 'Intel 8 Series/C220 Series "Lynx Point" SMBus Controller';
                              $8CA2 : FSMBusControllerName := 'Intel 9 Series Chipset Family "Wildcat Point" SMBus Controller';
                              $8D22 : FSMBusControllerName := 'Intel C610 Series Chipset & X99 Chipset "Wellsburg" SMBus Controller';
                              $8D7D : FSMBusControllerName := 'Intel C610 Series Chipset & X99 Chipset "Wellsburg" SMBus 0 Controller';
                              $8D7E : FSMBusControllerName := 'Intel C610 Series Chipset & X99 Chipset "Wellsburg" SMBus 1 Controller';
                              $8D7F : FSMBusControllerName := 'Intel C610 Series Chipset & X99 Chipset "Wellsburg" SMBus 2 Controller';

                              $9C22 : FSMBusControllerName := 'Intel Lynx Point-LP SMBus Controller';
                              $9CA2 : FSMBusControllerName := 'Intel Wildcat Point-LP SMBus Controller';
                              $9D23 : FSMBusControllerName := 'Intel Sunrise Point-LP SMBus Controller';
                              $9DA3 : FSMBusControllerName := 'Intel Cannon Lake-LP SMBus Controller';

                              $A0A3 : FSMBusControllerName := 'Intel Tiger Lake-LP SMBus Host Controller';
                              $A123 : FSMBusControllerName := 'Intel Sunrise Point-H SMBus Controller';
                              $A1A3 : FSMBusControllerName := 'Intel Lewisburg SMBus Controller';
                              $A223 : FSMBusControllerName := 'Intel C620 Series Chipset "Lewisburg" SMBus Controller';
                              $A2A3 : FSMBusControllerName := 'Intel 200 Series/Z370 Chipset Family SMBus Controller';
                              $A323 : FSMBusControllerName := 'Intel Cannon Lake-H PCH SMBus Controller';
                              $A3A3 : FSMBusControllerName := 'Intel Comet Lake-V SMBus Host Controller';
                            end;
                            Break;
                          end;
                        end;
                else
                  if (FPCIDevices[PCIDevCnt].ClassID = $C) and
                     (FPCIDevices[PCIDevCnt].SubClassID = 5) then
                  begin
                    WordValue := MakeWord(FPCIDevices[PCIDevCnt].PCIContent[$20],
                                          FPCIDevices[PCIDevCnt].PCIContent[$21]);
                    {Register 20-21 Bits 5-15}
                    FSMBusBaseAddress := WordValue and $FFE0;
                    FSMBusControllerName := 'Unbekannter Intel SMBus Controller';
                    Break;
                  end;
              end;
      $1106 : case FPCIDevices[PCIDevCnt].DeviceID of {VIA}
                $3040,  {VIA VT82C596B Apollo ACPI}
                $3050,  {VIA VT82C596/A/B Apollo ACPI}
                $3051,  {VIA VT82C596B ACPI}
                $3057,  {VIA VT82C686A/B Apollo ACPI}
                $3074,  {VIA VT8233 VLink South Bridge}
                $3109,  {VIA VT8233C PCI to ISA Bridge}
                $3147,  {VIA VT8233A South Bridge}
                $3177,  {VIA VT8233A/8235 South Bridge}
                $3227,  {VIA VT8237 South Bridge}
                $3287,  {VIA VT8251 South Bridge}
                $3337,  {VIA VT8237A South Bridge}
                $8235,  {VIA VT8231 South Bridge}
                $8324,  {VIA CX700/VX700 PCI to ISA Bridge}
                $8353 : {VIA VX800/VX820 South Bridge}
                        begin
                          if (FPCIDevices[PCIDevCnt].ClassID = $C) and
                             (FPCIDevices[PCIDevCnt].SubClassID = 5) then
                          begin
                            WordValue := MakeWord(FPCIDevices[PCIDevCnt].PCIContent[$90],
                                                  FPCIDevices[PCIDevCnt].PCIContent[$91]);
                            FSMBusBaseAddress := WordValue and $FFF0; {Register 90-91 Bits 4-15}

                            case FPCIDevices[PCIDevCnt].DeviceID of
                              $3040 : FSMBusControllerName := 'VIA VT82C596B Apollo ACPI';
                              $3050 : FSMBusControllerName := 'VIA VT82C596/A/B Apollo ACPI';
                              $3051 : FSMBusControllerName := 'VIA VT82C596 Power Management';
                              $3057 : FSMBusControllerName := 'VIA VT82C686A/B Apollo ACPI';
                              $3074 : FSMBusControllerName := 'VIA VT8233 VLink South Bridge';
                              $3109 : FSMBusControllerName := 'VIA VT8233C PCI to ISA Bridge';
                              $3147 : FSMBusControllerName := 'VIA VT8233A South Bridge';
                              $3177 : FSMBusControllerName := 'VIA VT8233A/8235 South Bridge';
                              $3227 : FSMBusControllerName := 'VIA VT8237 South Bridge';
                              $3287 : FSMBusControllerName := 'VIA VT8251 South Bridge';
                              $3337 : FSMBusControllerName := 'VIA VT8237A South Bridge';
                              $8235 : FSMBusControllerName := 'VIA VT8231 South Bridge';
                              $8324 : FSMBusControllerName := 'VIA CX700/VX700 PCI to ISA Bridge';
                              $8353 : FSMBusControllerName := 'VIA VX800/VX820 South Bridge';
                            end;
                            Break;
                          end;
                        end;
                $3402 : {VIA VT8261}
                        begin
                          if (FPCIDevices[PCIDevCnt].ClassID = $C) and
                             (FPCIDevices[PCIDevCnt].SubClassID = 5) then
                          begin
                            WordValue := MakeWord(FPCIDevices[PCIDevCnt].PCIContent[$D0],
                                                  FPCIDevices[PCIDevCnt].PCIContent[$D1]);
                            FSMBusBaseAddress := WordValue and $FFF0; {Register D0-D1 Bits 4-15}

                            case FPCIDevices[PCIDevCnt].DeviceID of
                              $3402 : FSMBusControllerName := 'VIA VT82C596/A/B Apollo ACPI';
                            end;
                            Break;
                          end;
                        end;
              end;
      $1022 : case FPCIDevices[PCIDevCnt].DeviceID of {AMD}
                $740B,  {AMD 756, Power Management Controller}
                $7413,  {AMD 766, Power Management Controller}
                $7443,  {AMD 768, Power Management Controller}
                $746A,  {AMD 8111, SMBus 2.0}
                $746B:  {AMD 8111, ACPI}
                        begin
                          if (FPCIDevices[PCIDevCnt].ClassID = $C) and
                             (FPCIDevices[PCIDevCnt].SubClassID = 5) then
                          begin
                            WordValue := MakeWord(FPCIDevices[PCIDevCnt].PCIContent[$58],
                                                  FPCIDevices[PCIDevCnt].PCIContent[$59]);
                            FSMBusBaseAddress := WordValue and $FF00; {Registers 58-59 Bits 0-7}
                            FSMBusBaseAddress := FSMBusBaseAddress + $E0; {SMB_ADDR_OFFSET}

                            case FPCIDevices[PCIDevCnt].DeviceID of
                              $740B : FSMBusControllerName := 'AMD 756, Power Management Controller';
                              $7413 : FSMBusControllerName := 'AMD 766, Power Management Controller';
                              $7443 : FSMBusControllerName := 'AMD 768, Power Management Controller';
                              $746A : FSMBusControllerName := 'AMD 8111, SMBus 2.0';
                              $746B : FSMBusControllerName := 'AMD 8111, ACPI';
                              $780B : FSMBusControllerName := 'AMD Hudson-2 SMBus';
                              $790B : FSMBusControllerName := 'AMD KERNCZ SMBus';
                            end;
                            Break;
                          end;
                        end;
              end;
      $10DE : case FPCIDevices[PCIDevCnt].DeviceID of {nVidia}
                $01B4 : begin {nVidia nForce SMBus}
                          if (FPCIDevices[PCIDevCnt].ClassID = $C) and
                             (FPCIDevices[PCIDevCnt].SubClassID = 5) then
                          begin
                            WordValue := MakeWord(FPCIDevices[PCIDevCnt].PCIContent[$10],
                                                  FPCIDevices[PCIDevCnt].PCIContent[$11]);
                            FSMBusBaseAddress := WordValue and $FFF0; {Register 10-11 Bits 4-15}

                            case FPCIDevices[PCIDevCnt].DeviceID of
                              $01B4 : FSMBusControllerName := 'nVidia nForce SMBus';
                            end;
                            Break;
                          end;
                        end;
                $0064,  {nVidia MCP2 SMBus Controller}
                $0084,  {nVidia MCP2A SMBus Controller}
                $00D4,  {nVidia CK8 SMBus Controller}
                $00E4,  {nVidia CK8S SMBus Controller}
                $0034,  {nVidia MCP04 SMBus Controller}
                $0052 : {nVidia CK804 SMBus Controller}
                        begin
                          if (FPCIDevices[PCIDevCnt].ClassID = $C) and
                             (FPCIDevices[PCIDevCnt].SubClassID = 5) then
                          begin
                            WordValue := MakeWord(FPCIDevices[PCIDevCnt].PCIContent[$50],
                                                  FPCIDevices[PCIDevCnt].PCIContent[$51]);
                            FSMBusBaseAddress := WordValue and $FFF0; {Register 50-51}
                            if FSMBusBaseAddress = 0 then
                            begin
                              WordValue := MakeWord(FPCIDevices[PCIDevCnt].PCIContent[$54],
                                                    FPCIDevices[PCIDevCnt].PCIContent[$55]);
                              FSMBusBaseAddress := WordValue and $FFF0; {Register 54-55}
                            end;

                            case FPCIDevices[PCIDevCnt].DeviceID of
                              $0064 : FSMBusControllerName:='nVidia MCP2 SMBus Controller';
                              $0084 : FSMBusControllerName:='nVidia MCP2A SMBus Controller';
                              $00D4 : FSMBusControllerName:='nVidia CK8 SMBus Controller';
                              $00E4 : FSMBusControllerName:='nVidia CK8S SMBus Controller';
                              $0034 : FSMBusControllerName:='nVidia MCP04 SMBus Controller';
                              $0052 : FSMBusControllerName:='nVidia CK804 SMBus Controller';
                            end;
                            Break;
                          end;
                        end;
                $0264,  {nVidia MCP51 SMBus Controller}
                $0368,  {nVidia MCP55 SMBus Controller}
                $03EB,  {nVidia MCP61 SMBus Controller}
                $0446,  {nVidia MCP65 SMBus Controller}
                $0542,  {nVidia MCP67 SMBus Controller}
                $07D8,  {nVidia MCP73 SMBus Controller}
                $0752,  {nVidia MCP77 SMBus Controller}
                $0AA2,  {nVidia MCP79 SMBus Controller}
                $0D79 : {nVidia MCP89 SMBus Controller}
                        begin
                          if (FPCIDevices[PCIDevCnt].ClassID = $C) and
                             (FPCIDevices[PCIDevCnt].SubClassID = 5) then
                          begin
                            WordValue := MakeWord(FPCIDevices[PCIDevCnt].PCIContent[$20],
                                                  FPCIDevices[PCIDevCnt].PCIContent[$21]);
                            FSMBusBaseAddress := WordValue and $FFF0; {Register 20-21}
                            if FSMBusBaseAddress = 0 then
                            begin
                              WordValue := MakeWord(FPCIDevices[PCIDevCnt].PCIContent[$24],
                                                    FPCIDevices[PCIDevCnt].PCIContent[$25]);
                              FSMBusBaseAddress := WordValue and $FFF0; {Register 24-25}
                            end;

                            case FPCIDevices[PCIDevCnt].DeviceID of
                              $0264 : FSMBusControllerName:='nVidia MCP51 SMBus Controller';
                              $0368 : FSMBusControllerName:='nVidia MCP55 SMBus Controller';
                              $03EB : FSMBusControllerName:='nVidia MCP61 SMBus Controller';
                              $0446 : FSMBusControllerName:='nVidia MCP65 SMBus Controller';
                              $0542 : FSMBusControllerName:='nVidia MCP67 SMBus Controller';
                              $07D8 : FSMBusControllerName:='nVidia MCP73 SMBus Controller';
                              $0752 : FSMBusControllerName:='nVidia MCP77 SMBus Controller';
                              $0AA2 : FSMBusControllerName:='nVidia MCP79 SMBus Controller';
                              $0D79 : FSMBusControllerName:='nVidia MCP89 SMBus Controller';
                            end;
                            Break;
                          end;
                        end;
              end;
      $1002 : case FPCIDevices[PCIDevCnt].DeviceID of {ATI}
                $4353,  {ATI SMBus}
                $4363,  {ATI SMBus}
                $4372 : {ATI SB400 SMBus Controller}
                        begin
                          if (FPCIDevices[PCIDevCnt].ClassID = $C) and
                             (FPCIDevices[PCIDevCnt].SubClassID = 5) then
                          begin
                            WordValue := MakeWord(FPCIDevices[PCIDevCnt].PCIContent[$90],
                                                  FPCIDevices[PCIDevCnt].PCIContent[$91]);
                            FSMBusBaseAddress := WordValue and $FFF0; {Register 90-91 Bits 4-15}

                            case FPCIDevices[PCIDevCnt].DeviceID of
                              $4353 : FSMBusControllerName:='ATI SMBus';
                              $4363 : FSMBusControllerName:='ATI SMBus';
                              $4372 : FSMBusControllerName:='ATI SB400 SMBus Controller';
                            end;
                            Break;
                          end;
                        end;
                $4385 : {ATI SB600/SB700 SMBus}
                        begin
                          if (FPCIDevices[PCIDevCnt].ClassID = $C) and
                             (FPCIDevices[PCIDevCnt].SubClassID = 5) then
                          begin
                            WordValue := MakeWord(FPCIDevices[PCIDevCnt].PCIContent[$10],
                                                  FPCIDevices[PCIDevCnt].PCIContent[$11]);
                            FSMBusBaseAddress := WordValue and $FFF0; {Register 10-11 Bits 4-15}
                            if FSMBusBaseAddress = 0 then
                            begin
                              WordValue := MakeWord(FPCIDevices[PCIDevCnt].PCIContent[$90],
                                                    FPCIDevices[PCIDevCnt].PCIContent[$91]);
                              FSMBusBaseAddress := WordValue and $FFF0; {Register 90-91 Bits 4-15}
                            end;

                            case FPCIDevices[PCIDevCnt].DeviceID of
                              $4385 : FSMBusControllerName:='ATI SB600/SB700 SMBus';
                            end;
                            Break;
                          end;
                        end;
              end;
    end;
  end;

  //Abschnitt zum Prüfen und Setzen des I/O Space Bits im
  //PCI Command Register
  if (FSMBusBaseAddress <> 0) and
     (FSMBusControllerName <> '') and
     (FPCIDevices[PCIDevCnt].ClassID = $C) and
     (FPCIDevices[PCIDevCnt].SubClassID = 5) then
  begin
    //Prüfen von Bit 0 (I/O Space Enable) im
    //PCI Command Register bei Offset 4h
    if not IsBitOn(
             FPCIDevices[PCIDevCnt].PCIContent[$4],
             0) then
    begin
      {zusammensetzen des Configuration Address Register}
      {- zunächst die Geräte- und Funktionsnummern}
      DeviceID := FPCIDevices[PCIDevCnt].Dev;
      DeviceID := DeviceID shl 3;
      DeviceID := DeviceID + (FPCIDevices[PCIDevCnt].Func and $F);
      {- dann das vollständige Register}
      PortBase := $80;
      PortBase := (PortBase shl 8) or FPCIDevices[PCIDevCnt].Bus;
      PortBase := (PortBase shl 8) or DeviceID;
      PortBase := (PortBase shl 8) or $4;
      WriteInputBuf.PortNumber := PortBase;

      Move(FPCIDevices[PCIDevCnt].PCIContent[$4],
           DataBase,
           SizeOf(DataBase));
      DataBase := DataBase or 1;
      WriteInputBuf.DataBuffer := DataBase;
      if FParent.Driver_WritePCI(WriteInputBuf, WriteOutputBuf) then
        Move(WriteOutputBuf.DataBuffer,
             FPCIDevices[PCIDevCnt].PCIContent[$4],
             SizeOf(WriteOutputBuf.DataBuffer))
      else
        ShowMessage('I/O Space Enable des SMBus-Kontrollers " ' +
                    FSMBusControllerName +
                    '" konnte nicht aktiviert werden.');
    end;

    //Bei Intel SMBus-Kontrollern prüfen von Bit 0 (Host Enable) im
    //PCI Host Configuration Register bei Offset 40h
    if (FPCIDevices[PCIDevCnt].VendorID = $8086) and
       not IsBitOn(FPCIDevices[PCIDevCnt].PCIContent[$40], 0) then
    begin
      {zusammensetzen des Configuration Address Register}
      {- zunächst die Geräte- und Funktionsnummern}
      DeviceID := FPCIDevices[PCIDevCnt].Dev;
      DeviceID := DeviceID shl 3;
      DeviceID := DeviceID + (FPCIDevices[PCIDevCnt].Func and $F);
      {- dann das vollständige Register}
      PortBase := $80;
      PortBase := (PortBase shl 8) or FPCIDevices[PCIDevCnt].Bus;
      PortBase := (PortBase shl 8) or DeviceID;
      PortBase := (PortBase shl 8) or $40;
      WriteInputBuf.PortNumber := PortBase;

      Move(FPCIDevices[PCIDevCnt].PCIContent[$40],
           DataBase,
           SizeOf(DataBase));
      DataBase := DataBase or 1;
      WriteInputBuf.DataBuffer := DataBase;
      if FParent.Driver_WritePCI(WriteInputBuf, WriteOutputBuf) then
        Move(WriteOutputBuf.DataBuffer,
             FPCIDevices[PCIDevCnt].PCIContent[$40],
             SizeOf(WriteOutputBuf.DataBuffer))
      else
        ShowMessage('Host Enable des Intel SMBus-Kontrollers " ' +
                    FSMBusControllerName +
                    '" konnte nicht aktiviert werden.');
    end;
  end;
end;

function TPCIBus.PCIDatabasesAvailable : Boolean;
var
  BasePath : String;
begin
  BasePath := IncludeTrailingPathDelimiter(ExtractFilePath(FParent.fDriverFullPath));

  Result := FileExists(BasePath + PCIVendorDatabase) and
            FileExists(BasePath + PCIDeviceDatabase) and
            FileExists(BasePath + PCISubDeviceDatabase);

  if Result and
     (PCIVendorList.Count = 0) and
     (PCIDeviceList.Count = 0) and
     (PCISubDeviceList.Count = 0) then
  begin
    PCIVendorList.LoadFromFile(BasePath + PCIVendorDatabase);
    PCIDeviceList.LoadFromFile(BasePath + PCIDeviceDatabase);
    PCISubDeviceList.LoadFromFile(BasePath + PCISubDeviceDatabase);
  end;
end;

function TPCIBus.GetVendorString(Vendor : Word) : String;
var
  Cnt : Integer;
  SearchStr : String;
begin
  Result := '';

  if not PCIDatabasesAvailable then
    Exit('Keine PCI-Datenbank verfügbar');

  if PCIVendorList.Count > 0 then
  begin
    SearchStr := Format('%4.4x=', [Vendor]);
    for Cnt := 0 to PCIVendorList.Count - 1 do
    begin
      if Pos(SearchStr, PCIVendorList.Strings[Cnt]) = 1 then
      begin
        Result := PCIVendorList.ValueFromIndex[Cnt].DeQuotedString('"');
        Break;
      end;
    end;
  end;
end;

function TPCIBus.GetDeviceString(Vendor, Device : Word; Revision : Byte) : String;
var
  Cnt : Integer;
  SearchStr : String;
begin
  Result := '';

  if not PCIDatabasesAvailable then
    Exit('Keine PCI-Datenbank verfügbar');

  if PCIDeviceList.Count > 0 then
  begin
    SearchStr := Format('%4.4x,%4.4x,%2.2x',
                        [Vendor, Device, Revision]);
    for Cnt := 0 to PCIDeviceList.Count - 1 do
    begin
      if Pos(SearchStr, PCIDeviceList.Strings[Cnt]) = 1 then
      begin
        Result := PCIDeviceList.ValueFromIndex[Cnt].DeQuotedString('"');
        Break;
      end;
    end;

    if Result = '' then
    begin
      SearchStr := Format('%4.4x,%4.4x,%s',
                          [Vendor, Device, 'XX']);
      for Cnt := 0 to PCIDeviceList.Count - 1 do
      begin
        if Pos(SearchStr, PCIDeviceList.Strings[Cnt]) = 1 then
        begin
          Result := PCIDeviceList.ValueFromIndex[Cnt].DeQuotedString('"');
          Break;
        end;
      end;
    end;
  end;
end;

function TPCIBus.GetSubDeviceString(Vendor, Device : Word; Revision : Byte;
                                    SubVendor, SubDevice : Word) : String;
var
  Cnt : Integer;
  SearchStr : String;
begin
  Result := '';

  if not PCIDatabasesAvailable then
    Exit('Keine PCI-Datenbank verfügbar');

  if PCISubDeviceList.Count > 0 then
  begin
    SearchStr := Format('%4.4x,%4.4x,%2.2x,%4.4x,%4.4x',
                        [Vendor, Device, Revision, SubVendor, SubDevice]);
    for Cnt := 0 to PCISubDeviceList.Count - 1 do
    begin
      if Pos(SearchStr, PCISubDeviceList.Strings[Cnt]) = 1 then
      begin
        Result := PCISubDeviceList.ValueFromIndex[Cnt].DeQuotedString('"');
        Break;
      end;
    end;

    if Result = '' then
    begin
      SearchStr := Format('%4.4x,%4.4x,%s,%4.4x,%4.4x',
                          [Vendor, Device, 'XX', SubVendor, SubDevice]);
      for Cnt := 0 to PCISubDeviceList.Count - 1 do
      begin
        if Pos(SearchStr, PCISubDeviceList.Strings[Cnt]) = 1 then
        begin
          Result := PCISubDeviceList.ValueFromIndex[Cnt].DeQuotedString('"');
          Break;
        end;
      end;
    end;
  end;
end;

function TPCIBus.HiDWord(AValue : UInt64) : Cardinal;
begin
  Result := AValue shr 32;
end;

function TPCIBus.LoDWord(AValue : UInt64) : Cardinal;
begin
  Result := Cardinal(AValue);
end;

function TPCIBus.IsBitOn(Value : UInt64; Bit : Byte) : Boolean;
begin
  if Bit > 31 then
    Result := (HiDWord(Value) and (1 shl (Bit - 32))) <> 0
  else
    Result := (LoDWord(Value) and (1 shl Bit)) <> 0;
end;

function TPCIBus.YesNo(ABool : Boolean) : String;
begin
  case ABool of
    True  : Result := 'ja';
    False : Result := 'nein';
  end;
end;

function TPCIBus.ActiveInactive(ABool : Boolean) : String;
begin
  case ABool of
    True  : Result := 'aktiv';
    False : Result := 'inaktiv';
  end;
end;

{ TSMBus }

constructor TSMBus.Create(Parent : TSystemAccess);
var
  ModuleCnt : Byte;
begin
  inherited Create;
  FParent := Parent;

  FSMBusBaseAddress := 0;
  FSMBusControllerName := 'unbekannt';
  for ModuleCnt := 0 to 7 do
    FSMBUSMemoryDevices[ModuleCnt] := 0;
end;

destructor TSMBus.Destroy;
begin
  inherited;
end;

function TSMBus.SMBus_IsHostBusyStatus : Boolean;
var
  ReadInputBuf : ReadPortXBitInputStruct;
  ReadOutputBuf : ReadPort8BitOutputStruct;
begin
  Result := False;

  ReadInputBuf.Address := FSMBusBaseAddress + $00;
  if FParent.Driver_ReadPort8Bit(ReadInputBuf, ReadOutputBuf) and
     IsBitOn(ReadOutputBuf.Data, 0) then
  Result := True;
end;

procedure TSMBus.SMBus_WaitForBusyStatus;
var
  TickCount : UInt64;
begin
  TickCount := GetTickCount64;
  while not SMBus_IsHostBusyStatus and (GetTickCount64 - TickCount < 20) do
    Sleep(1);
end;

procedure TSMBus.SMBus_WaitForReadyStatus;
var
  TickCount : UInt64;
begin
  TickCount := GetTickCount64;
  while SMBus_IsHostBusyStatus and (GetTickCount64 - TickCount < 20) do
    Sleep(1);
end;

function TSMBus.SMBus_IsDeviceErrorOccurred : Boolean;
var
  ReadInputBuf : ReadPortXBitInputStruct;
  ReadOutputBuf : ReadPort8BitOutputStruct;
begin
  Result := False;

  ReadInputBuf.Address := FSMBusBaseAddress + $0;
  if FParent.Driver_ReadPort8Bit(ReadInputBuf, ReadOutputBuf) and
     IsBitOn(ReadOutputBuf.Data, 2) then
  Result := True;
end;

function TSMBus.ReadDataByte(Adr, Reg : Byte) : Byte;
var
  ReadInputBuf : ReadPortXBitInputStruct;
  ReadOutputBuf : ReadPort8BitOutputStruct;
  WriteInputBuf : WritePort8BitInputStruct;
begin
  Result := 0;

  {Host Status zurücksetzen}
  WriteInputBuf.Address := FSMBusBaseAddress + $0; {SMBus Host Status}
  WriteInputBuf.Data := $1E;
  FParent.Driver_WritePort8Bit(WriteInputBuf);

  {Adresse und Transferrichtung schreiben}
  WriteInputBuf.Address := FSMBusBaseAddress + $4; {SMBus Host Address}
  WriteInputBuf.Data := (Adr shl 1) or 1;
  FParent.Driver_WritePort8Bit(WriteInputBuf);

  {Anzusprechendes Register schreiben}
  WriteInputBuf.Address := FSMBusBaseAddress + $3; {SMBus Host Command}
  WriteInputBuf.Data := Reg;
  FParent.Driver_WritePort8Bit(WriteInputBuf);

  {Transfertyp und Startsignal schreiben}
  WriteInputBuf.Address := FSMBusBaseAddress + $2; {SMBus Host Count}
  WriteInputBuf.Data := $48; //Byte-Daten & Start
  FParent.Driver_WritePort8Bit(WriteInputBuf);

  {Warten bis der SMBus nicht mehr beschäftigt ist}
  SMBus_WaitForReadyStatus;

  {wenn der SMBus im Leerlauf ist und kein Gerätefehler gemeldet wurde...}
  if not SMBus_IsHostBusyStatus and
     not SMBus_IsDeviceErrorOccurred then
  begin
    {...dann Daten auslesen}
    ReadInputBuf.Address := FSMBusBaseAddress + $5; {SMBus Host Data 0}
    if FParent.Driver_ReadPort8Bit(ReadInputBuf, ReadOutputBuf) then
      Result := ReadOutputBuf.Data;
  end;
end;

function TSMBus.ReadDataWord(Adr, Reg : Byte) : Word;
var
  ReadInputBuf : ReadPortXBitInputStruct;
  ReadOutputBuf : ReadPort8BitOutputStruct;
  WriteInputBuf : WritePort8BitInputStruct;
begin
  Result := 0;

  {Host Status zurücksetzen}
  WriteInputBuf.Address := FSMBusBaseAddress + $0; {SMBus Host Status}
  WriteInputBuf.Data := $1E;
  FParent.Driver_WritePort8Bit(WriteInputBuf);

  {Adresse und Transferrichtung schreiben}
  WriteInputBuf.Address := FSMBusBaseAddress + $4; {SMBus Host Address}
  WriteInputBuf.Data := (Adr shl 1) or 1;
  FParent.Driver_WritePort8Bit(WriteInputBuf);

  {Anzusprechendes Register schreiben}
  WriteInputBuf.Address := FSMBusBaseAddress + $3; {SMBus Host Command}
  WriteInputBuf.Data := Reg;
  FParent.Driver_WritePort8Bit(WriteInputBuf);

  {Transfertyp und Startsignal schreiben}
  WriteInputBuf.Address := FSMBusBaseAddress + $2; {SMBus Host Count}
  WriteInputBuf.Data := $4C; //Word-Daten & Start
  FParent.Driver_WritePort8Bit(WriteInputBuf);

  {Warten bis der SMBus nicht mehr beschäftigt ist}
  SMBus_WaitForReadyStatus;

  {wenn der SMBus im Leerlauf ist und kein Gerätefehler gemeldet wurde...}
  if not SMBus_IsHostBusyStatus and
     not SMBus_IsDeviceErrorOccurred then
  begin
    {...dann Daten auslesen}
    ReadInputBuf.Address := FSMBusBaseAddress + $6; {SMBus Host Data 1}
    if FParent.Driver_ReadPort8Bit(ReadInputBuf, ReadOutputBuf) then
      Result := ReadOutputBuf.Data;

    ReadInputBuf.Address := FSMBusBaseAddress + $5; {SMBus Host Data 0}
    if FParent.Driver_ReadPort8Bit(ReadInputBuf, ReadOutputBuf) then
      Result := (Result shl 8) + ReadOutputBuf.Data;
  end;
end;

procedure TSMBus.WriteDataByte(Adr, Reg, Content : Byte);
var
  WriteInputBuf : WritePort8BitInputStruct;
begin
  {Host Status zurücksetzen}
  WriteInputBuf.Address := FSMBusBaseAddress + $0; {SMBus Host Status}
  WriteInputBuf.Data := $1E;
  FParent.Driver_WritePort8Bit(WriteInputBuf);

  {Adresse und Transferrichtung schreiben}
  WriteInputBuf.Address := FSMBusBaseAddress + $4; {SMBus Host Address}
  WriteInputBuf.Data := (Adr shl 1) or 0;
  FParent.Driver_WritePort8Bit(WriteInputBuf);

  {Anzusprechendes Register schreiben}
  WriteInputBuf.Address := FSMBusBaseAddress + $3; {SMBus Host Command}
  WriteInputBuf.Data := Reg;
  FParent.Driver_WritePort8Bit(WriteInputBuf);

  {Registerinhalt schreiben}
  WriteInputBuf.Address := FSMBusBaseAddress + $5; {SMBus Host Data 0}
  WriteInputBuf.Data := Content;
  FParent.Driver_WritePort8Bit(WriteInputBuf);

  {Transfertyp und Startsignal schreiben}
  WriteInputBuf.Address := FSMBusBaseAddress + $2; {SMBus Host Count}
  WriteInputBuf.Data := $48; //Byte-Daten & Start
  FParent.Driver_WritePort8Bit(WriteInputBuf);

  {Warten bis der SMBus nicht mehr beschäftigt ist}
  SMBus_WaitForReadyStatus;
end;

function TSMBus.GetSMBusMemoryModules : Array8;
var
  AddressCnt,
  ResultCnt : Byte;
begin
  for ResultCnt := 0 to 7 do
    Result[ResultCnt] := 0;

  if FSMBusBaseAddress = 0 then
    Exit;

  if CreateWorldMutex('Access_SMBUS.HTP.Method') then
  begin
    ResultCnt := 0;
    for AddressCnt := $50 to $57 do
      if ReadDataByte(AddressCnt, 0) <> 0 then
      begin
        Result[ResultCnt] := AddressCnt;
        Inc(ResultCnt, 1);
      end;

    ReleaseWorldMutex;
  end;
end;

function TSMBus.GetMemoryModuleInfo(Address : Byte) : TModuleInfo;
var
  WordValue,
  SizeValue,
  ByteCnt,
  PageCnt : Word;
  ByteValue : Byte;
begin
  with Result do
  begin
    Manufacturer := '';
    Model := '';
    Size := 0;
    TypeDetail := '';
    SerialNumber := '';
    SPDData := nil;
  end;

  if Address = 0 then
    Exit;

  if CreateWorldMutex('Access_SMBUS.HTP.Method') then
  begin
    SizeValue := 256; {Standardwert}
    if FParent.SMBIOSClass.IsDDR4MemoryAvailable then
    begin
      DDR4_SelectSPDPage0;

      SetLength(Result.SPDData, SizeValue);
      for ByteCnt := 0 to (SizeValue div 2) - 1 do
      begin
        WordValue := ReadDataWord(Address, ByteCnt * 2);
        Result.SPDData[ByteCnt * 2] := WordValue and $FF;
        Result.SPDData[(ByteCnt * 2) + 1] := WordValue shr 8;

        if ByteCnt = 0 then
        begin
          //SPD-Byte 0 auslesen zur Bestimmung der SPD-Größe
          case (WordValue shr 4) and 7 of
            1  : SizeValue := 256;
            2  : SizeValue := 512;
            else SizeValue := 0;
          end;

          if SizeValue > 256 then
            SetLength(Result.SPDData, SizeValue);
        end;
      end;

      if SizeValue > 256 then
      begin
        DDR4_SelectSPDPage1;

        for ByteCnt := 0 to ((SizeValue - 256) div 2) - 1 do
        begin
          WordValue := ReadDataWord(Address, ByteCnt * 2);
          Result.SPDData[256 + (ByteCnt * 2)] := WordValue and $FF;
          Result.SPDData[256 + ((ByteCnt * 2) + 1)] := WordValue shr 8;
        end;
      end;
    end else
    if FParent.SMBIOSClass.IsDDR5MemoryAvailable then
    begin
      SetLength(Result.SPDData, 0);
      if not IsIntel_SPDWD then
      begin
        DDR5_SelectSPDPage(Address, 0);
        if ReadDataByte(Address, $0) = $51 {SPD5 Hub Device} then
        begin
          ByteValue := ReadDataByte(Address, 0 or $80);
          //SPD-Byte 0 auslesen zur Bestimmung der SPD-Größe
          case (ByteValue shr 4) and 7 of
            1  : SizeValue := 256;
            2  : SizeValue := 512;
            3  : SizeValue := 1024;
            4  : SizeValue := 1024; //eigentlich 2048 Byte, aber das
                                    //Umschalten der Seite über MR11'
                                    //funktioniert nur von 0 bis 7 in
                                    //jeweils 128 Byte-Blöcken, somit
                                    //können wir max. 1024 Byte ansprechen
            else SizeValue := 0;
          end;

          if SizeValue >= 256 then
            SetLength(Result.SPDData, SizeValue);

          if High(Result.SPDData) >= 255 then
          for PageCnt := 0 to (SizeValue div 128) - 1  do
          begin
            DDR5_SelectSPDPage(Address, PageCnt);

            for ByteCnt := 0 to 63 do
            begin
              WordValue := ReadDataWord(Address, (ByteCnt * 2) or $80);
              Result.SPDData[(PageCnt * 128) + (ByteCnt * 2)] := WordValue and $FF;
              Result.SPDData[(PageCnt * 128) + ((ByteCnt * 2) + 1)] := WordValue shr 8;
            end;

            //Auskommentierter Code für alternatives byteweises Lesen
            //for ByteCnt := 0 to 127 do
            //begin
            //  ByteValue := ReadDataByte(Address, ByteCnt or $80);
            //  Result.SPDData[(PageCnt * 128) + ByteCnt] := ByteValue;
            //end;
          end;
        end;
      end;
    end else
    begin
      SetLength(Result.SPDData, SizeValue);
      for ByteCnt := 0 to (SizeValue div 2) - 1 do
      begin
        WordValue := ReadDataWord(Address, ByteCnt * 2);
        Result.SPDData[ByteCnt * 2] := WordValue and $FF;
        Result.SPDData[(ByteCnt * 2) + 1] := WordValue shr 8;
      end;
    end;

    {Prüfen der Rohdaten}
    if (High(Result.SPDData) > 0) and
       (Result.SPDData[0] <> 0) then
      Result := GetMemoryModuleDetails(Result);

    ReleaseWorldMutex;
  end;
end;

procedure TSMBus.DDR4_SelectSPDPage0;
begin
  //Seite 0 mit den Bytes 0-255 aktivieren
  WriteDataByte($36, 0, 0);
  SMBus_IsHostBusyStatus;
  SMBus_WaitForBusyStatus;
  SMBus_WaitForReadyStatus;
end;

procedure TSMBus.DDR4_SelectSPDPage1;
begin
  //Seite 1 mit den Bytes 256-511 aktivieren
  WriteDataByte($37, 0, 0);
  SMBus_IsHostBusyStatus;
  SMBus_WaitForBusyStatus;
  SMBus_WaitForReadyStatus;
end;

procedure TSMBus.DDR5_SelectSPDPage(Address, Page : Byte);
begin
  WriteDataByte(Address, 11 {MR11}, Page and 7);
  SMBus_IsHostBusyStatus;
  SMBus_WaitForBusyStatus;
  SMBus_WaitForReadyStatus;
end;

function TSMBus.IsIntel_SPDWD : Boolean;
var
  PCIDevCnt : Integer;
begin
  Result := False;

  if FParent.PCIBusClass.PCIDeviceCount = 0 then
    Exit;

  for PCIDevCnt := 0 to FParent.PCIBusClass.PCIDeviceCount - 1 do
  begin
    if (FParent.PCIBusClass.FPCIDevices[PCIDevCnt].VendorID = $8086) and
       (FParent.PCIBusClass.FPCIDevices[PCIDevCnt].ClassID = $C) and
       (FParent.PCIBusClass.FPCIDevices[PCIDevCnt].SubClassID = 5) then
    begin
      //Prüfen von Bit 4 (SPD Write Disable) im
      //Host Configuration (HCFG) Register bei Offset $40
      Result := IsBitOn(
                  FParent.PCIBusClass.FPCIDevices[PCIDevCnt].PCIContent[$40],
                  4);
      Break;
    end;
  end;
end;

function TSMBus.CreateWorldMutex(MutexName : String) : Boolean;
var
  SecurityDesc : TSecurityDescriptor;
  SecurityAttr : TSecurityAttributes;
  ACLSize : NativeInt;
  BoolRes : Boolean;
const
  SECURITY_WORLD_SID_AUTHORITY : TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 1));
  SECURITY_WORLD_RID = 0;
  ACL_REVISION = 2;
begin
  FSID := nil;
  ACLSize := SizeOf(TACL) * 32;
  FACL := AllocMem(ACLSize);

  InitializeSecurityDescriptor(@SecurityDesc, SECURITY_DESCRIPTOR_REVISION);

  FACL := AllocMem(SizeOf(FACL^));

  BoolRes := InitializeAcl(FACL^, ACLSize, ACL_REVISION);

  BoolRes := BoolRes and
    AllocateAndInitializeSid(SECURITY_WORLD_SID_AUTHORITY,
                             1,
                             SECURITY_WORLD_RID,
                             0,
                             0,
                             0,
                             0,
                             0,
                             0,
                             0,
                             FSID);

  BoolRes := BoolRes and
    AddAccessAllowedAce(FACL^,
                        ACL_REVISION,
                        MUTANT_ALL_ACCESS,
                        FSID);

  if BoolRes then
    SetSecurityDescriptorDacl(@SecurityDesc, True, nil, False)
  else
    SetSecurityDescriptorDacl(@SecurityDesc, True, FACL, False);

  SecurityAttr.nLength := SizeOf(SecurityAttr);
  SecurityAttr.lpSecurityDescriptor := @SecurityDesc;
  SecurityAttr.bInheritHandle := False;

  FMutexHandle := CreateMutex(@SecurityAttr,
                              False,
                              PChar('Global\' + MutexName));
  if FMutexHandle = 0 then
  begin
    FMutexHandle := OpenMutex(READ_CONTROL or MUTANT_QUERY_STATE or SYNCHRONIZE,
                              False,
                              PChar('Global\' + MutexName));
    if FMutexHandle = 0 then
    begin
      FMutexHandle := CreateMutex(@SecurityAttr,
                                  False,
                                  PChar(MutexName));
      Result := FMutexHandle <> 0;
    end else
      Result := True;
  end else
    Result := True;
end;

procedure TSMBus.ReleaseWorldMutex;
begin
  if FMutexHandle <> 0 then
  begin
    ReleaseMutex(FMutexHandle);
    CloseHandle(FMutexHandle);
  end;

  if Assigned(FSID) then
    FreeSid(FSID);
  if Assigned(FACL) then
    FreeMem(FACL);
end;

function TSMBus.GetMemSize_FPMEDOSDRAM(Data : TArray<Byte>) : Word;
var
  NumberOfAddressesAndBanks : Integer;
begin
  Result := 0;

  //Calculation variables used in the following offsets:
  //Number of Column Addresses on Offset 4
  //Number of Physical Banks on POffset 5
  NumberOfAddressesAndBanks := (Data[4] and $F) +
                               (Data[4] shr 4) +
                               (Data[5] and $F) +
                               (Data[5] shr 4) - 14;

  if (NumberOfAddressesAndBanks > 0) and (NumberOfAddressesAndBanks < 16) then
    Result := 1 shl NumberOfAddressesAndBanks;
end;

function TSMBus.GetMemSize_DirectRambus(Data : TArray<Byte>) : Word;
var
  NumberOfAddressesAndBanks : Integer;
begin
  Result := 0;

  //Calculation variables used in the following offsets:
  //Number of Column Addresses on Offset 4
  //Number of Physical Banks on Offset 5
  NumberOfAddressesAndBanks := (Data[4] and $F) +
                               (Data[4] shr 4) +
                               (Data[5] and $7) - 13;

  if (NumberOfAddressesAndBanks > 0) and (NumberOfAddressesAndBanks < 16) then
    Result := 1 shl NumberOfAddressesAndBanks;
end;

function TSMBus.GetMemSize_Rambus(Data : TArray<Byte>) : Word;
var
  NumberOfAddressesAndBanks : Integer;
begin
  Result := 0;

  //Calculation variables used in the following offsets:
  //Number of Row Addresses on Offset 3
  //Number of Physical Banks on Offset 5
  NumberOfAddressesAndBanks := (Data[3] and $F) +
                               (Data[3] shr 4) +
                               (Data[5] and $7) - 13;

  if (NumberOfAddressesAndBanks > 0) and (NumberOfAddressesAndBanks < 16) then
    Result := 1 shl NumberOfAddressesAndBanks;
end;

function TSMBus.GetMemSize_SDRSDRAM(Data : TArray<Byte>) : Word;
var
  NumberOfAddresses,
  NumberOfBanks : Integer;
begin
  Result := 0;
  NumberOfBanks:=0;

  //Calculation variables used in the following offsets:
  //Number of Row Addresses on Offset 3
  //Number of Column Addresses on Offset 4
  //Number of Physical Banks on Offset 5
  //Number of Banks on Offset 17
  NumberOfAddresses := (Data[3] and $F) + (Data[4] and $F) - 17;

  if (Data[5] <= 8) and (Data[17] <= 8) then
    NumberOfBanks := Data[5] * Data[17];

  if (NumberOfAddresses > 0) and (NumberOfAddresses <= 12) and (NumberOfBanks > 0) then
    Result := (1 shl NumberOfAddresses) * NumberOfBanks;
end;

function TSMBus.GetMemSize_DDRSDRAM(Data : TArray<Byte>) : Word;
var
  NumberOfAddresses,
  NumberOfBanks : Integer;
begin
  Result := 0;
  NumberOfBanks:=0;

  //Calculation variables used in the following offsets:
  //Number of Row Addresses on Offset 3
  //Number of Column Addresses on Offset 4
  //Number of Physical Banks on Offset 5
  //Number of Banks on Offset 17

  NumberOfAddresses := (Data[3] and $F) + (Data[4] and $F) - 17;

  if (Data[5] <= 8) and (Data[17] <= 8) then NumberOfBanks := Data[5] * Data[17];

  if (NumberOfAddresses > 0) and
     (NumberOfAddresses <= 12) and
     (NumberOfBanks > 0) then
    Result := (1 shl NumberOfAddresses) * NumberOfBanks;
end;

function TSMBus.GetMemSize_DDR2SDRAM(Data : TArray<Byte>) : Word;
var
  RankDensity : Word;
  Ranks : Byte;
begin
  Result := 0;

  //Calculation variables used in the following offsets:
  //Number of Physical Banks on Offset 5
  //Module Bank Density on Offset 31

  Ranks := (Data[5] and 7) + 1;

  case Data[31] of
    1   : RankDensity := 1024;  {Bit 0}
    2   : RankDensity := 2048;  {Bit 1}
    4   : RankDensity := 4096;  {Bit 2}
    8   : RankDensity := 8192;  {Bit 3}
    16  : RankDensity := 16384; {Bit 4}
    32  : RankDensity := 128;   {Bit 5}
    64  : RankDensity := 256;   {Bit 6}
    128 : RankDensity := 512;   {Bit 7}
    else  RankDensity := 0;
  end;

  if (RankDensity <> 0) and (Ranks <> 0) then
    Result := Ranks * RankDensity;
end;

function TSMBus.GetMemSize_DDR2SDRAMFBDIMM(Data : TArray<Byte>) : Word;
var
  RowAddrBits,
  ColAddrBits,
  Ranks,
  Banks : Byte;
begin
  Result := 0;

  //Calculation variables used in the following offsets:
  //SDRAM Addressing on Offset 4
  //Module Organization on Offset 7

  case (Data[4] shr 5) and 7 of
    0  : RowAddrBits := 12;
    1  : RowAddrBits := 13;
    2  : RowAddrBits := 14;
    3  : RowAddrBits := 15;
    else RowAddrBits := 0;
  end;

  case (Data[4] shr 2) and 7 of
    0  : ColAddrBits := 9;
    1  : ColAddrBits := 10;
    2  : ColAddrBits := 11;
    else ColAddrBits := 0;
  end;

  case (Data[7] shr 3) and 7 of
    1  : Ranks := 1;
    2  : Ranks := 2;
    else Ranks := 0;
  end;

  case Data[4] and 3 of
    0  : Banks := 4;
    1  : Banks := 8;
    2  : Banks := 16;
    3  : Banks := 32;
    else Banks := 0;
  end;

  if (RowAddrBits <> 0) and (ColAddrBits <> 1) and
     (Ranks <> 0) and (Banks <> 0) then
    Result := (1 shl (RowAddrBits + ColAddrBits - 20)) * Ranks * Banks * 8;
end;

function TSMBus.GetMemSize_DDR3SDRAM(Data : TArray<Byte>) : Word;
var
  Cap,
  BusWidth,
  Width,
  Ranks : Word;
begin
  Result := 0;

  //Calculation variables used in the following offsets:
  //SDRAM Density and Banks on Offset 4
  //Module Organization on Offset 7
  //Module Memory Bus Width on Offset 8

  {Total SDRAM Capacity, in megabits}
  case Data[4] and 15 of
    0  : Cap := 256;
    1  : Cap := 512;
    2  : Cap := 1024;
    3  : Cap := 2048;
    4  : Cap := 4096;
    5  : Cap := 8192;
    6  : Cap := 16384;
    else Cap := 0;
  end;

  {Primary Bus Width}
  case Data[8] and 7 of
    0  : BusWidth := 8;
    1  : BusWidth := 16;
    2  : BusWidth := 32;
    3  : BusWidth := 64;
    else BusWidth := 0;
  end;

  {SDRAM Device Width}
  case Data[7] and 7 of
    0  : Width := 4;
    1  : Width := 8;
    2  : Width := 16;
    3  : Width := 32;
    else Width := 0;
  end;

  {Number of Ranks}
  case (Data[7] shr 3) and 7 of
    0  : Ranks := 1;
    1  : Ranks := 2;
    2  : Ranks := 3;
    3  : Ranks := 4;
    else Ranks := 0;
  end;

  if (Cap <> 0) and (BusWidth <> 0) and (Width <> 0) and (Ranks <> 0) then
    Result := Round(Cap / 8 * (BusWidth / Width) * Ranks);
end;

function TSMBus.GetMemSize_DDR4SDRAM(Data : TArray<Byte>) : Word;
var
  Cap,
  BusWidth,
  Width,
  PackageRanks,
  Die,
  LogicalRanks : Word;
begin
  Result := 0;

  //Calculation variables used in the following offsets:
  //SDRAM Density and Banks on Offset 4
  //SDRAM Device Type on Offset 6
  //Module Organization on Offset 12
  //Module Memory Bus Width on Offset 13

  {Total SDRAM Capacity, in megabits}
  case (Data[4] and 15) of
    0  : Cap := 256;
    1  : Cap := 512;
    2  : Cap := 1024;
    3  : Cap := 2048;
    4  : Cap := 4096;
    5  : Cap := 8192;
    6  : Cap := 16384;
    7  : Cap := 32768;
    else Cap := 0;
  end;

  {Primary Bus Width}
  case Data[13] and 7 of
    0  : BusWidth := 8;
    1  : BusWidth := 16;
    2  : BusWidth := 32;
    3  : BusWidth := 64;
    else BusWidth := 0;
  end;

  {SDRAM Device Width}
  case Data[12] and 7 of
    0 : Width := 4;
    1 : Width := 8;
    2 : Width := 16;
    3 : Width := 32;
    else Width := 0;
  end;

  {Number of Package Ranks}
  case (Data[12] shr 3) and 7 of
    0 : PackageRanks := 1;
    1 : PackageRanks := 2;
    2 : PackageRanks := 3;
    3 : PackageRanks := 4;
    else PackageRanks := 0;
  end;

  {Die Count}
  case (Data[6] shr 4) and 7 of
    0 : Die := 1;
    1 : Die := 2;
    2 : Die := 3;
    3 : Die := 4;
    4 : Die := 5;
    5 : Die := 6;
    6 : Die := 7;
    7 : Die := 8;
    else Die := 0;
  end;

  LogicalRanks := PackageRanks * Die;

  if (Cap <> 0) and
     (BusWidth <> 0) and
     (Width <> 0) and
     (PackageRanks <> 0) and
     (Die <> 0) and
     (LogicalRanks <> 0) then
  Result := Round(Cap / 8 * (BusWidth / Width) * LogicalRanks);
end;

function TSMBus.GetMemSize_DDR5SDRAM(Data : TArray<Byte>) : Word;
type
  ModuleType = (Symmetric, Asymmetric);
var
  PackageRanksPerSubChannel,
  First_SubChannelsPerDIMM,
  First_PrimaryBusWidthPerSubChannel,
  First_SDRAMIOWidth,
  First_DiePerPackage,
  First_SDRAMDensityPerDie,
  Second_SubChannelsPerDIMM,
  Second_PrimaryBusWidthPerSubChannel,
  Second_SDRAMIOWidth,
  Second_DiePerPackage,
  Second_SDRAMDensityPerDie : Word;
  MType : ModuleType;
begin
  Result := 0;
  Second_SubChannelsPerDIMM := 0;
  Second_PrimaryBusWidthPerSubChannel := 0;
  Second_SDRAMIOWidth := 0;
  Second_DiePerPackage := 0;
  Second_SDRAMDensityPerDie := 0;

  //Distinction between symmetric and asymmetric modules
  if IsBitOn(Data[234], 6) then //Rank Mix
    MType := Asymmetric
  else
    MType := Symmetric;

  //Calculation variables for symmetric modules used in the
  //following offsets:
  //Package ranks per sub-channel on Offset 234
  //Number of sub-channels per DIMM on Offset 235
  //Primary bus width per sub-channel on Offset 235
  //SDRAM I/O Width on Offset 6
  //Die per package on Offset 4
  //SDRAM density per die on Offset 4

  //Calculation variables for asymmetric modules used in the
  //following offsets:
  //Package ranks per sub-channel on Offset 234
  //Even ranks (first SDRAM type) are identical to the offsets
  //  for symmetric modules
  //Odd ranks (second SDRAM type):
  //- Number of sub-channels per DIMM on Offset 235
  //- Primary bus width per sub-channel on Offset 235
  //- SDRAM I/O Width on Offset 10
  //- Die per package on Offset 8
  //- SDRAM density per die on Offset 8

  {Package ranks per sub-channel}
  case (Data[234] shr 3) and 7 of
    0  : PackageRanksPerSubChannel := 1;
    1  : PackageRanksPerSubChannel := 2;
    2  : PackageRanksPerSubChannel := 3;
    3  : PackageRanksPerSubChannel := 4;
    4  : PackageRanksPerSubChannel := 5;
    5  : PackageRanksPerSubChannel := 6;
    6  : PackageRanksPerSubChannel := 7;
    7  : PackageRanksPerSubChannel := 8;
    else PackageRanksPerSubChannel := 0;
  end;

  {Number of sub-channels per DIMM}
  case (Data[235] shr 5) and 3 of
    0  : First_SubChannelsPerDIMM := 1;
    1  : First_SubChannelsPerDIMM := 2;
    else First_SubChannelsPerDIMM := 0;
  end;

  {Primary bus width per sub-channel}
  case Data[235] and 7 of
    0  : First_PrimaryBusWidthPerSubChannel := 8;
    1  : First_PrimaryBusWidthPerSubChannel := 16;
    2  : First_PrimaryBusWidthPerSubChannel := 32;
    3  : First_PrimaryBusWidthPerSubChannel := 64;
    else First_PrimaryBusWidthPerSubChannel := 0;
  end;

  {SDRAM I/O Width}
  case (Data[6] shr 5) and 7 of
    0  : First_SDRAMIOWidth := 4;
    1  : First_SDRAMIOWidth := 8;
    2  : First_SDRAMIOWidth := 16;
    3  : First_SDRAMIOWidth := 32;
    else First_SDRAMIOWidth := 0;
  end;

  {Die per package}
  case (Data[4] shr 5) and 7 of
    0  : First_DiePerPackage := 1;
    1  : First_DiePerPackage := 2;
    2  : First_DiePerPackage := 2;
    3  : First_DiePerPackage := 4;
    4  : First_DiePerPackage := 8;
    5  : First_DiePerPackage := 16;
    else First_DiePerPackage := 0;
  end;

  {SDRAM density per die, in GBits}
  case Data[4] and 31 of
    1  : First_SDRAMDensityPerDie := 4;
    2  : First_SDRAMDensityPerDie := 8;
    3  : First_SDRAMDensityPerDie := 12;
    4  : First_SDRAMDensityPerDie := 16;
    5  : First_SDRAMDensityPerDie := 24;
    6  : First_SDRAMDensityPerDie := 32;
    7  : First_SDRAMDensityPerDie := 48;
    8  : First_SDRAMDensityPerDie := 64;
    else First_SDRAMDensityPerDie := 0;
  end;

  if MType = Asymmetric then
  begin
    {Second SDRAM Type - Number of sub-channels per DIMM}
    case (Data[235] shr 5) and 3 of
      0  : Second_SubChannelsPerDIMM := 1;
      1  : Second_SubChannelsPerDIMM := 2;
      else Second_SubChannelsPerDIMM := 0;
    end;

    {Second SDRAM Type - Primary bus width per sub-channel}
    case Data[235] and 7 of
      0  : Second_PrimaryBusWidthPerSubChannel := 8;
      1  : Second_PrimaryBusWidthPerSubChannel := 16;
      2  : Second_PrimaryBusWidthPerSubChannel := 32;
      3  : Second_PrimaryBusWidthPerSubChannel := 64;
      else Second_PrimaryBusWidthPerSubChannel := 0;
    end;

    {Second SDRAM Type - SDRAM I/O Width}
    case (Data[10] shr 5) and 7 of
      0  : Second_SDRAMIOWidth := 4;
      1  : Second_SDRAMIOWidth := 8;
      2  : Second_SDRAMIOWidth := 16;
      3  : Second_SDRAMIOWidth := 32;
      else Second_SDRAMIOWidth := 0;
    end;

    {Second SDRAM Type - Die per package}
    case (Data[8] shr 5) and 7 of
      0  : Second_DiePerPackage := 1;
      1  : Second_DiePerPackage := 2;
      2  : Second_DiePerPackage := 2;
      3  : Second_DiePerPackage := 4;
      4  : Second_DiePerPackage := 8;
      5  : Second_DiePerPackage := 16;
      else Second_DiePerPackage := 0;
    end;

    {Second SDRAM Type - SDRAM density per die, in GBits}
    case Data[8] and 31 of
      1  : Second_SDRAMDensityPerDie := 4;
      2  : Second_SDRAMDensityPerDie := 8;
      3  : Second_SDRAMDensityPerDie := 12;
      4  : Second_SDRAMDensityPerDie := 16;
      5  : Second_SDRAMDensityPerDie := 24;
      6  : Second_SDRAMDensityPerDie := 32;
      7  : Second_SDRAMDensityPerDie := 48;
      8  : Second_SDRAMDensityPerDie := 64;
      else Second_SDRAMDensityPerDie := 0;
    end;
  end;

  if MType = Symmetric then
  begin
    if (PackageRanksPerSubChannel <> 0) and
       (First_SubChannelsPerDIMM <> 0) and
       (First_PrimaryBusWidthPerSubChannel <> 0) and
       (First_SDRAMIOWidth <> 0) and
       (First_DiePerPackage <> 0) and
       (First_SDRAMDensityPerDie <> 0) then
    Result := Round(First_SubChannelsPerDIMM *
                    (First_PrimaryBusWidthPerSubChannel /
                     First_SDRAMIOWidth) *
                    First_DiePerPackage *
                    (First_SDRAMDensityPerDie / 8) *
                    PackageRanksPerSubChannel);
  end else
  begin
    if (PackageRanksPerSubChannel <> 0) and
       (First_SubChannelsPerDIMM <> 0) and
       (First_PrimaryBusWidthPerSubChannel <> 0) and
       (First_SDRAMIOWidth <> 0) and
       (First_DiePerPackage <> 0) and
       (First_SDRAMDensityPerDie <> 0) and
       (Second_SubChannelsPerDIMM <> 0) and
       (Second_PrimaryBusWidthPerSubChannel <> 0) and
       (Second_SDRAMIOWidth <> 0) and
       (Second_DiePerPackage <> 0) and
       (Second_SDRAMDensityPerDie <> 0) then
    Result := Round(First_SubChannelsPerDIMM *
                    (First_PrimaryBusWidthPerSubChannel /
                     First_SDRAMIOWidth) *
                    First_DiePerPackage *
                    (First_SDRAMDensityPerDie / 8) *
                    PackageRanksPerSubChannel) +
              Round(Second_SubChannelsPerDIMM *
                    (Second_PrimaryBusWidthPerSubChannel /
                     Second_SDRAMIOWidth) *
                    Second_DiePerPackage *
                    (Second_SDRAMDensityPerDie / 8) *
                    PackageRanksPerSubChannel);
  end;
end;

function TSMBus.GetMemoryModuleDetails(Module : TModuleInfo) : TModuleInfo;
var
  ManufacturerCnt : Byte;
  Counter : Word;
  StringValue : String;
  LWordValue : LongWord;
begin
  {Zuerst die SPD-Rohdaten ins Ergebnis übertragen}
  with Result do
  begin
    Manufacturer := '';
    Model := '';
    Size := 0;
    TypeDetail := '';
    SerialNumber := '';
    SPDData := Module.SPDData;
  end;

  {Speichertyp / Größe / Seriennummer}
  case Result.SPDData[2] of
    0  : Result.TypeDetail := ''; {unbekannt}
    1  : begin
           case Result.SPDData[11] of
             1 : StringValue := ' Parität';
             2 : StringValue := ' ECC';
             else StringValue := '';
           end;

           if Result.SPDData[0] < 4 then
           begin
             Result.TypeDetail := 'Direct Rambus' + StringValue;
             Result.Size := GetMemSize_DirectRambus(Result.SPDData);
           end else
             Result.TypeDetail := 'FPM DRAM' + StringValue;

           Move(Result.SPDData[95], LWordValue, SizeOf(LWordValue));
           if LWordValue <> 0 then
             Result.SerialNumber := IntToHex(Swap32(LWordValue), 8) + ' (' + IntToStr(LWordValue) + ')';
         end;
    2  : begin
           case Result.SPDData[11] of
             1 : StringValue := ' Parität';
             2 : StringValue := ' ECC';
             else StringValue := '';
           end;
           Result.TypeDetail := 'EDO DRAM' + StringValue;

           Move(Result.SPDData[95], LWordValue, SizeOf(LWordValue));
           if LWordValue <> 0 then
             Result.SerialNumber := IntToHex(Swap32(LWordValue), 8) + ' (' + IntToStr(LWordValue) + ')';
         end;
    3  : begin
           case Result.SPDData[11] of
             1 : StringValue:=' Parität';
             2 : StringValue:=' ECC';
             else StringValue := '';
           end;
           Result.TypeDetail := 'Pipelined Nibble' + StringValue;
         end;
    4  : begin
           case Result.SPDData[11] of
             1 : StringValue := ' Parität';
             2 : StringValue := ' ECC';
             else StringValue := '';
           end;
           Result.TypeDetail := ' ' + StringValue;

           Result.Size := GetMemSize_SDRSDRAM(Result.SPDData);

           Move(Result.SPDData[95], LWordValue, SizeOf(LWordValue));
           if LWordValue <> 0 then
             Result.SerialNumber := IntToHex(Swap32(LWordValue), 8) + ' (' + IntToStr(LWordValue) + ')';
         end;
    5  : begin
           case Result.SPDData[11] of
             1 : StringValue := ' Parität';
             2 : StringValue := ' ECC';
             else StringValue := '';
           end;
           Result.TypeDetail := 'Multiplexed ROM' + StringValue;
         end;
    6  : begin
           case Result.SPDData[11] of
             1 : StringValue := ' Parität';
             2 : StringValue := ' ECC';
             else StringValue := '';
           end;
           Result.TypeDetail := 'DDR SGRAM' + StringValue;
         end;
    7  : begin
           case Result.SPDData[11] of
             1 : StringValue := ' Parität';
             2 : StringValue := ' ECC';
             else StringValue := '';
           end;
           Result.TypeDetail := 'DDR SDRAM' + StringValue;

           Result.Size := GetMemSize_DDRSDRAM(Result.SPDData);

           Move(Result.SPDData[95], LWordValue, SizeOf(LWordValue));
           if LWordValue <> 0 then
             Result.SerialNumber := IntToHex(Swap32(LWordValue), 8) + ' (' + IntToStr(LWordValue) + ')';
         end;
    8  : begin
           StringValue := '';
           if IsBitOn(Result.SPDData[11], 0) then
             StringValue := ' Parität';
           if IsBitOn(Result.SPDData[11], 1) then
             StringValue := StringValue + ' ECC';
           Result.TypeDetail := 'DDR2 SDRAM' + StringValue;

           Result.Size := GetMemSize_DDR2SDRAM(Result.SPDData);

           Move(Result.SPDData[95], LWordValue, SizeOf(LWordValue));
           if LWordValue <> 0 then
             Result.SerialNumber := IntToHex(Swap32(LWordValue), 8) + ' (' + IntToStr(LWordValue) + ')';
         end;
    9,
    10 : begin
           case Result.SPDData[6] and 15 of
             1, 5 : StringValue := 'Registriert ';
             else StringValue := '';
           end;

           Result.TypeDetail := StringValue + 'DDR2 SDRAM FB-DIMM';
           if (Result.SPDData[81] shr 1) and 1 = 1 then
             Result.TypeDetail := Result.TypeDetail + ' ECC';

           Result.Size := GetMemSize_DDR2SDRAMFBDIMM(Result.SPDData);

           Move(Result.SPDData[122], LWordValue, SizeOf(LWordValue));
           if LWordValue <> 0 then
             Result.SerialNumber := IntToHex(Swap32(LWordValue), 8) + ' (' + IntToStr(LWordValue) + ')';
         end;
    11 : begin
           case Result.SPDData[3] and 15 of
             1, 5 : StringValue := 'Registriert ';
             else StringValue := '';
           end;

           Result.TypeDetail := StringValue + 'DDR3 SDRAM';
           if (Result.SPDData[8] shr 3) and 3 = 1 then
             Result.TypeDetail := Result.TypeDetail + ' ECC';

           Result.Size := GetMemSize_DDR3SDRAM(Result.SPDData);

           Move(Result.SPDData[122], LWordValue, SizeOf(LWordValue));
           if LWordValue <> 0 then
             Result.SerialNumber := IntToHex(Swap32(LWordValue), 8) + ' (' + IntToStr(LWordValue) + ')';
         end;
    12 : begin
           case Result.SPDData[3] and 15 of
             1, 5, 8 : StringValue := 'Registriert ';
             else StringValue := '';
           end;

           Result.TypeDetail := StringValue + 'DDR4 SDRAM';
           if (Result.SPDData[13] shr 3) and 3 = 1 then
             Result.TypeDetail := Result.TypeDetail + ' ECC';

           Result.Size := GetMemSize_DDR4SDRAM(Result.SPDData);

           Move(Result.SPDData[325], LWordValue, SizeOf(LWordValue));
           if LWordValue <> 0 then
             Result.SerialNumber := IntToHex(Swap32(LWordValue), 8) + ' (' + IntToStr(LWordValue) + ')';
         end;
    17 : begin
           Result.TypeDetail := 'Rambus';
           Result.Size := GetMemSize_Rambus(Result.SPDData);

           Move(Result.SPDData[95], LWordValue, SizeOf(LWordValue));
           if LWordValue <> 0 then
             Result.SerialNumber := IntToHex(Swap32(LWordValue), 8) + ' (' + IntToStr(LWordValue) + ')';
         end;
    18 : begin
           Result.TypeDetail := 'DDR5 SDRAM';
           if (Result.SPDData[235] shr 3) and 3 in [1, 2] then
             Result.TypeDetail := Result.TypeDetail + ' ECC';

           Result.Size := GetMemSize_DDR5SDRAM(Result.SPDData);

           if High(Result.SPDData) >= 520 then
           begin
             Move(Result.SPDData[517], LWordValue, SizeOf(LWordValue));
             if LWordValue <> 0 then
               Result.SerialNumber := IntToHex(Swap32(LWordValue), 8) + ' (' + IntToStr(LWordValue) + ')';
           end;
         end;
  end;

  {Hersteller}
  case Result.SPDData[2] of
    9,   {DDR2 SDRAM FB-DIMM}
    10,  {DDR2 SDRAM FB-DIMM}
    11 : {DDR3 SDRAM}
         case Result.SPDData[117] and $7F of
           00 : Result.Manufacturer := GetJEDECBank1 (Result.SPDData[118]);
           01 : Result.Manufacturer := GetJEDECBank2 (Result.SPDData[118]);
           02 : Result.Manufacturer := GetJEDECBank3 (Result.SPDData[118]);
           03 : Result.Manufacturer := GetJEDECBank4 (Result.SPDData[118]);
           04 : Result.Manufacturer := GetJEDECBank5 (Result.SPDData[118]);
           05 : Result.Manufacturer := GetJEDECBank6 (Result.SPDData[118]);
           06 : Result.Manufacturer := GetJEDECBank7 (Result.SPDData[118]);
           07 : Result.Manufacturer := GetJEDECBank8 (Result.SPDData[118]);
           08 : Result.Manufacturer := GetJEDECBank9 (Result.SPDData[118]);
           09 : Result.Manufacturer := GetJEDECBank10(Result.SPDData[118]);
           10 : Result.Manufacturer := GetJEDECBank11(Result.SPDData[118]);
           11 : Result.Manufacturer := GetJEDECBank12(Result.SPDData[118]);
           12 : Result.Manufacturer := GetJEDECBank13(Result.SPDData[118]);
           13 : Result.Manufacturer := GetJEDECBank14(Result.SPDData[118]);
           14 : Result.Manufacturer := GetJEDECBank15(Result.SPDData[118]);
         end;
    12 : {DDR4 SDRAM}
         case Result.SPDData[320] and $7F of
           00 : Result.Manufacturer := GetJEDECBank1 (Result.SPDData[321]);
           01 : Result.Manufacturer := GetJEDECBank2 (Result.SPDData[321]);
           02 : Result.Manufacturer := GetJEDECBank3 (Result.SPDData[321]);
           03 : Result.Manufacturer := GetJEDECBank4 (Result.SPDData[321]);
           04 : Result.Manufacturer := GetJEDECBank5 (Result.SPDData[321]);
           05 : Result.Manufacturer := GetJEDECBank6 (Result.SPDData[321]);
           06 : Result.Manufacturer := GetJEDECBank7 (Result.SPDData[321]);
           07 : Result.Manufacturer := GetJEDECBank8 (Result.SPDData[321]);
           08 : Result.Manufacturer := GetJEDECBank9 (Result.SPDData[321]);
           09 : Result.Manufacturer := GetJEDECBank10(Result.SPDData[321]);
           10 : Result.Manufacturer := GetJEDECBank11(Result.SPDData[321]);
           11 : Result.Manufacturer := GetJEDECBank12(Result.SPDData[321]);
           12 : Result.Manufacturer := GetJEDECBank13(Result.SPDData[321]);
           13 : Result.Manufacturer := GetJEDECBank14(Result.SPDData[321]);
           14 : Result.Manufacturer := GetJEDECBank15(Result.SPDData[321]);
         end;
    18 : begin {DDR5 SDRAM}
           if High(Result.SPDData) >= 512 then
           case Result.SPDData[512] and $7F of
             00 : Result.Manufacturer := GetJEDECBank1 (Result.SPDData[513]);
             01 : Result.Manufacturer := GetJEDECBank2 (Result.SPDData[513]);
             02 : Result.Manufacturer := GetJEDECBank3 (Result.SPDData[513]);
             03 : Result.Manufacturer := GetJEDECBank4 (Result.SPDData[513]);
             04 : Result.Manufacturer := GetJEDECBank5 (Result.SPDData[513]);
             05 : Result.Manufacturer := GetJEDECBank6 (Result.SPDData[513]);
             06 : Result.Manufacturer := GetJEDECBank7 (Result.SPDData[513]);
             07 : Result.Manufacturer := GetJEDECBank8 (Result.SPDData[513]);
             08 : Result.Manufacturer := GetJEDECBank9 (Result.SPDData[513]);
             09 : Result.Manufacturer := GetJEDECBank10(Result.SPDData[513]);
             10 : Result.Manufacturer := GetJEDECBank11(Result.SPDData[513]);
             11 : Result.Manufacturer := GetJEDECBank12(Result.SPDData[513]);
             12 : Result.Manufacturer := GetJEDECBank13(Result.SPDData[513]);
             13 : Result.Manufacturer := GetJEDECBank14(Result.SPDData[513]);
             14 : Result.Manufacturer := GetJEDECBank15(Result.SPDData[513]);
           end;
         end;
    else
      for ManufacturerCnt := 71 downto 64 do
      begin
        if Result.SPDData[ManufacturerCnt] <> $7F then
        begin
          case ManufacturerCnt of
            64 : Result.Manufacturer := GetJEDECBank1(Result.SPDData[ManufacturerCnt]);
            65 : Result.Manufacturer := GetJEDECBank2(Result.SPDData[ManufacturerCnt]);
            66 : Result.Manufacturer := GetJEDECBank3(Result.SPDData[ManufacturerCnt]);
            67 : Result.Manufacturer := GetJEDECBank4(Result.SPDData[ManufacturerCnt]);
            68 : Result.Manufacturer := GetJEDECBank5(Result.SPDData[ManufacturerCnt]);
            69 : Result.Manufacturer := GetJEDECBank6(Result.SPDData[ManufacturerCnt]);
            70 : Result.Manufacturer := GetJEDECBank7(Result.SPDData[ManufacturerCnt]);
            71 : Result.Manufacturer := GetJEDECBank8(Result.SPDData[ManufacturerCnt]);
          end;
          Break;
        end;
      end;
  end;

  {Modell}
  StringValue := '';
  case Result.SPDData[2] of
    9, 10, 11 : begin {DDR2 SDRAM FB-DIMM, DDR3 SDRAM}
                  for Counter := 128 to 145 do
                    StringValue := StringValue + Char(Result.SPDData[Counter]);
                end;
    12        : begin {DDR4 SDRAM}
                  for Counter := 329 to 348 do
                    StringValue := StringValue + Char(Result.SPDData[Counter]);
                end;
    18        : begin {DDR5 SDRAM}
                  if High(Result.SPDData) >= 550 then
                  for Counter := 521 to 550 do
                    StringValue := StringValue + Char(Result.SPDData[Counter]);
                end;
    else
      for Counter := 73 to 90 do
        StringValue := StringValue + Char(Result.SPDData[Counter]);
  end;
  StringValue := Trim(StringValue);
  if StringValue = '' then
    StringValue := 'unbekanntes Modell';
  Result.Model := StringValue;
end;

procedure TSMBus.GetSPDDetails(Address : Byte; var SPDData : TStrings);
var
  SPDModuleDetails : TModuleInfo;
  DumpCnt : Word;
  StringValue : String;
begin
  SPDData.Clear;

  if FSMBusBaseAddress = 0 then
    Exit;

  if Address = 0 then
    Exit;

  SPDModuleDetails := GetMemoryModuleInfo(Address);

  if FParent.SMBIOSClass.IsDDR5MemoryAvailable and IsIntel_SPDWD then
  begin
    SPDData.Add('Keine Speichermodul-Details ermittelbar,');
    SPDData.Add('da "SPD Write Disabled" aktiviert ist.');
    SPDData.Add('Bitte prüfen Sie im BIOS, ob diese Funktion');
    SPDData.Add('abgeschaltet werden kann.');
    Exit;
  end;

  if High(SPDModuleDetails.SPDData) >= 127 then
  begin
    case SPDModuleDetails.SPDData[2] of
      0  : ; {unbekannt}
      1,
      2  : GetSPD_FPMEDODRAM(SPDModuleDetails.SPDData, SPDData);
      3  : ; {Pipelined Nibble}
      4  : ; {SDR SDRAM}
      5  : ; {Multiplexed ROM}
      6  : ; {DDR SGRAM}
      7  : GetSPD_DDRSDRAM(SPDModuleDetails.SPDData, SPDData);
      8  : GetSPD_DDR2SDRAM(SPDModuleDetails.SPDData, SPDData);
      9,
      10 : ; {DDR2 SDRAM FB-DIMM}
      11 : GetSPD_DDR3SDRAM(SPDModuleDetails.SPDData, SPDData);
      12 : GetSPD_DDR4SDRAM(SPDModuleDetails.SPDData, SPDData);
      17 : ; {Rambus}
      18 : GetSPD_DDR5SDRAM(SPDModuleDetails.SPDData, SPDData);
    end;

    if SPDData.Count > 0 then
      SPDData.Add('');
    SPDData.Add('Gerätedump');

    for DumpCnt := 1 to (High(SPDModuleDetails.SPDData) + 1) div 16 do
    begin
      StringValue :=
      IntToHex(SPDModuleDetails.SPDData[(DumpCnt * 16) - 16], 2) + ' ' +
      IntToHex(SPDModuleDetails.SPDData[(DumpCnt * 16) - 15], 2) + ' ' +
      IntToHex(SPDModuleDetails.SPDData[(DumpCnt * 16) - 14], 2) + ' ' +
      IntToHex(SPDModuleDetails.SPDData[(DumpCnt * 16) - 13], 2) + ' ' +
      IntToHex(SPDModuleDetails.SPDData[(DumpCnt * 16) - 12], 2) + ' ' +
      IntToHex(SPDModuleDetails.SPDData[(DumpCnt * 16) - 11], 2) + ' ' +
      IntToHex(SPDModuleDetails.SPDData[(DumpCnt * 16) - 10], 2) + ' ' +
      IntToHex(SPDModuleDetails.SPDData[(DumpCnt * 16) - 9], 2) + ' ' +
      IntToHex(SPDModuleDetails.SPDData[(DumpCnt * 16) - 8], 2) + ' ' +
      IntToHex(SPDModuleDetails.SPDData[(DumpCnt * 16) - 7], 2) + ' ' +
      IntToHex(SPDModuleDetails.SPDData[(DumpCnt * 16) - 6], 2) + ' ' +
      IntToHex(SPDModuleDetails.SPDData[(DumpCnt * 16) - 5], 2) + ' ' +
      IntToHex(SPDModuleDetails.SPDData[(DumpCnt * 16) - 4], 2) + ' ' +
      IntToHex(SPDModuleDetails.SPDData[(DumpCnt * 16) - 3], 2) + ' ' +
      IntToHex(SPDModuleDetails.SPDData[(DumpCnt * 16) - 2], 2) + ' ' +
      IntToHex(SPDModuleDetails.SPDData[(DumpCnt * 16) - 1], 2);

      SPDData.Add('Offset ' +
                  IntToHex((DumpCnt * 16) - 16, 2) +
                  ' - ' +
                  IntToHex((DumpCnt * 16) - 1, 2) +
                  '=' +
                  StringValue);
    end;
  end;
end;

procedure TSMBus.GetSPD_FPMEDODRAM(Data : TArray<Byte>; var SPDData : TStrings); {Typ 1 und 2}
var
  StringValue,
  SizeValue : String;
  Counter : Word;
  SizeTemp : UInt64;
  LWordValue : Cardinal;
  ManufacturerCnt : Byte;
begin
  case Data[2] of
    1 : SPDData.Add('Speichertyp=FPM DRAM');
    2 : SPDData.Add('Speichertyp=EDO DRAM');
  end;

  {Hersteller}
  StringValue := '';
  for ManufacturerCnt := 71 downto 64 do
  begin
    if Data[ManufacturerCnt] <> $7F then
    begin
      case ManufacturerCnt of
        64 : StringValue := GetJEDECBank1(Data[ManufacturerCnt]);
        65 : StringValue := GetJEDECBank2(Data[ManufacturerCnt]);
        66 : StringValue := GetJEDECBank3(Data[ManufacturerCnt]);
        67 : StringValue := GetJEDECBank4(Data[ManufacturerCnt]);
        68 : StringValue := GetJEDECBank5(Data[ManufacturerCnt]);
        69 : StringValue := GetJEDECBank6(Data[ManufacturerCnt]);
        70 : StringValue := GetJEDECBank7(Data[ManufacturerCnt]);
        71 : StringValue := GetJEDECBank8(Data[ManufacturerCnt]);
      end;
      Break;
    end;
  end;
  if StringValue = '' then
    StringValue := 'unbekannter Hersteller';
  SPDData.Add('Hersteller=' + StringValue);

  {Modell}
  StringValue := '';
  for Counter := 73 to 90 do
    StringValue := StringValue + Char(Data[Counter]);
  StringValue := Trim(StringValue);
  if StringValue = '' then
    StringValue := 'unbekanntes Modell';
  SPDData.Add('Modell=' + StringValue);

  {Größe}
  SizeTemp := GetMemSize_FPMEDOSDRAM(Data);
  SPDData.Add('Größe=' + GetCapacity(SizeTemp * 1024 * 1024));

  {Seriennummer}
  Move(Data[95], LWordValue, SizeOf(LWordValue));
  if LWordValue <> 0 then
    SPDData.Add('Seriennummer=' + IntToHex(Swap32(LWordValue), 8) + ' (' + IntToStr(LWordValue) + ')')
  else
    SPDData.Add('Seriennummer=nicht vorhanden');

  {Zusatzfunktionen}
  StringValue := '';
  case Data[11] of
    1  : StringValue := 'Parität';
    2  : StringValue := 'ECC';
    else StringValue := 'keine';
  end;
  SPDData.Add('Zusatzfunktionen=' + StringValue);

  {Herstellungsdatum}
  if (Data[94] <> 0) and (Data[93] <> 0) then
    SPDData.Add('Herstellungsdatum=' +
                'Woche ' + IntToHex(Data[94], 2) + '/20 ' + IntToHex(Data[93], 2))
  else
    SPDData.Add('Herstellungsdatum=nicht vorhanden');

  {Physikalische Bänke}
  if Data[17] = 0 then
    StringValue := 'unbekannt' else
    StringValue := IntToHex(Data[17], 2);
  SPDData.Add('Physikalische Bänke=' + StringValue);

  {Unterstützte Latenzen}
  StringValue := '';
  if IsBitOn(Data[18], 0) then StringValue := StringValue + '1, ';
  if IsBitOn(Data[18], 1) then StringValue := StringValue + '2, ';
  if IsBitOn(Data[18], 2) then StringValue := StringValue + '3, ';
  if IsBitOn(Data[18], 3) then StringValue := StringValue + '4, ';
  if IsBitOn(Data[18], 4) then StringValue := StringValue + '5, ';
  if IsBitOn(Data[18], 5) then StringValue := StringValue + '6, ';
  if IsBitOn(Data[18], 6) then StringValue := StringValue + '7, ';
  Delete(StringValue, Length(StringValue) - 1, 255);
  if StringValue = '' then
    StringValue := 'unbekannt';
  SPDData.Add('CAS-Latenzen=' + StringValue);

  {Unterstützte Latenzen}
  StringValue := '';
  if IsBitOn(Data[19], 0) then StringValue := StringValue + '0, ';
  if IsBitOn(Data[19], 1) then StringValue := StringValue + '1, ';
  if IsBitOn(Data[19], 2) then StringValue := StringValue + '2, ';
  if IsBitOn(Data[19], 3) then StringValue := StringValue + '3, ';
  if IsBitOn(Data[19], 4) then StringValue := StringValue + '4, ';
  if IsBitOn(Data[19], 5) then StringValue := StringValue + '5, ';
  if IsBitOn(Data[19], 6) then StringValue := StringValue + '6, ';
  Delete(StringValue, Length(StringValue) - 1, 255);
  if StringValue = '' then
    StringValue := 'unbekannt';
  SPDData.Add('CS-Latenzen=' + StringValue);

  {Unterstützte Latenzen}
  StringValue := '';
  if IsBitOn(Data[20], 0) then StringValue := StringValue + '0, ';
  if IsBitOn(Data[20], 1) then StringValue := StringValue + '1, ';
  if IsBitOn(Data[20], 2) then StringValue := StringValue + '2, ';
  if IsBitOn(Data[20], 3) then StringValue := StringValue + '3, ';
  if IsBitOn(Data[20], 4) then StringValue := StringValue + '4, ';
  if IsBitOn(Data[20], 5) then StringValue := StringValue + '5, ';
  if IsBitOn(Data[20], 6) then StringValue := StringValue + '6, ';
  Delete(StringValue, Length(StringValue) - 1, 255);
  if StringValue = '' then
    StringValue := 'unbekannt';
  SPDData.Add('WE-Latenzen=' + StringValue);

  {SPD-Details}
  StringValue := IntToHex(Data[62], 2);
  if Data[0] = 0 then
    SizeValue := 'unbekannt' else
    SizeValue := IntToStr(Data[0]) + ' Bytes';
  SPDData.Add('SPD-EEPROM-Details=Revision ' + StringValue[1] + '.' + StringValue[2] +
              ', Größe ' + SizeValue);
end;

procedure TSMBus.GetSPD_DDRSDRAM(Data : TArray<Byte>; var SPDData : TStrings); {Typ 7}
var
  StringValue,
  SizeValue : String;
  Counter : Word;
  SizeTemp : UInt64;
  LWordValue : Cardinal;
  ManufacturerCnt : Byte;
begin
  SPDData.Add('Speichertyp=DDR SDRAM');

  {Hersteller}
  StringValue := '';
  for ManufacturerCnt := 71 downto 64 do
  begin
    if Data[ManufacturerCnt] <> $7F then
    begin
      case ManufacturerCnt of
        64 : StringValue := GetJEDECBank1(Data[ManufacturerCnt]);
        65 : StringValue := GetJEDECBank2(Data[ManufacturerCnt]);
        66 : StringValue := GetJEDECBank3(Data[ManufacturerCnt]);
        67 : StringValue := GetJEDECBank4(Data[ManufacturerCnt]);
        68 : StringValue := GetJEDECBank5(Data[ManufacturerCnt]);
        69 : StringValue := GetJEDECBank6(Data[ManufacturerCnt]);
        70 : StringValue := GetJEDECBank7(Data[ManufacturerCnt]);
        71 : StringValue := GetJEDECBank8(Data[ManufacturerCnt]);
      end;
      Break;
    end;
  end;
  if StringValue = '' then
    StringValue := 'unbekannter Hersteller';
  SPDData.Add('Hersteller=' + StringValue);

  {Modell}
  StringValue := '';
  for Counter := 73 to 90 do
    StringValue := StringValue + Char(Data[Counter]);
  StringValue := Trim(StringValue);
  if StringValue = '' then
    StringValue := 'unbekanntes Modell';
  SPDData.Add('Modell=' + StringValue);

  {Größe}
  SizeTemp := GetMemSize_DDRSDRAM(Data);
  SPDData.Add('Größe=' + GetCapacity(SizeTemp * 1024 * 1024));

  {Seriennummer}
  Move(Data[95], LWordValue, SizeOf(LWordValue));
  if LWordValue <> 0 then
    SPDData.Add('Seriennummer=' + IntToHex(Swap32(LWordValue), 8) + ' (' + IntToStr(LWordValue) + ')')
  else
    SPDData.Add('Seriennummer=nicht vorhanden');

  {Zusatzfunktionen}
  case Data[11] of
    1  : StringValue := 'Parität';
    2  : StringValue := 'ECC';
    else StringValue := 'keine';
  end;
  SPDData.Add('Zusatzfunktionen=' + StringValue);

  {Herstellungsdatum}
  if (Data[94] <> 0) and (Data[93] <> 0) then
    SPDData.Add('Herstellungsdatum=' +
                'Woche ' + IntToHex(Data[94], 2) + '/20' + IntToHex(Data[93], 2))
  else
    SPDData.Add('Herstellungsdatum=nicht vorhanden');

  {Physikalische Bänke}
  if Data[17] = 0 then
    StringValue := 'unbekannt' else
    StringValue := IntToHex(Data[17], 2);
  SPDData.Add('Physikalische Bänke=' + StringValue);

  {Unterstützte Latenzen}
  StringValue := '';
  if IsBitOn(Data[18], 0) then StringValue := StringValue + '1, ';
  if IsBitOn(Data[18], 1) then StringValue := StringValue + '1.5, ';
  if IsBitOn(Data[18], 2) then StringValue := StringValue + '2, ';
  if IsBitOn(Data[18], 3) then StringValue := StringValue + '2.5, ';
  if IsBitOn(Data[18], 4) then StringValue := StringValue + '3, ';
  if IsBitOn(Data[18], 5) then StringValue := StringValue + '3.5, ';
  if IsBitOn(Data[18], 6) then StringValue := StringValue + '4, ';
  Delete(StringValue, Length(StringValue) - 1, 255);
  if StringValue = '' then
    StringValue := 'unbekannt';
  SPDData.Add('CAS-Latenzen=' + StringValue);

  {Unterstützte Latenzen}
  StringValue := '';
  if IsBitOn(Data[19], 0) then StringValue := StringValue + '0, ';
  if IsBitOn(Data[19], 1) then StringValue := StringValue + '1, ';
  if IsBitOn(Data[19], 2) then StringValue := StringValue + '2, ';
  if IsBitOn(Data[19], 3) then StringValue := StringValue + '3, ';
  if IsBitOn(Data[19], 4) then StringValue := StringValue + '4, ';
  if IsBitOn(Data[19], 5) then StringValue := StringValue + '5, ';
  if IsBitOn(Data[19], 6) then StringValue := StringValue + '6, ';
  Delete(StringValue, Length(StringValue) - 1, 255);
  if StringValue = '' then
    StringValue := 'unbekannt';
  SPDData.Add('CS-Latenzen=' + StringValue);

  {SPD-Details}
  StringValue := IntToHex(Data[62], 2);
  if Data[0] = 0 then
    SizeValue := 'unbekannt' else
    SizeValue := IntToStr(Data[0]) + ' Bytes';
  SPDData.Add('SPD-EEPROM-Details=' +
    'Revision ' + StringValue[1] + '.' + StringValue[2] +
    ', Größe ' + SizeValue);
end;

procedure TSMBus.GetSPD_DDR2SDRAM(Data : TArray<Byte>; var SPDData : TStrings); {Typ 8}
var
  StringValue,
  StringValue2,
  SizeValue : String;
  Counter : Word;
  SizeTemp : UInt64;
  LWordValue : Cardinal;
  ManufacturerCnt : Byte;
begin
  SPDData.Add('Speichertyp=DDR2 SDRAM');

  {Hersteller}
  StringValue := '';
  for ManufacturerCnt := 71 downto 64 do
  begin
    if Data[ManufacturerCnt] <> $7F then
    begin
      case ManufacturerCnt of
        64 : StringValue := GetJEDECBank1(Data[ManufacturerCnt]);
        65 : StringValue := GetJEDECBank2(Data[ManufacturerCnt]);
        66 : StringValue := GetJEDECBank3(Data[ManufacturerCnt]);
        67 : StringValue := GetJEDECBank4(Data[ManufacturerCnt]);
        68 : StringValue := GetJEDECBank5(Data[ManufacturerCnt]);
        69 : StringValue := GetJEDECBank6(Data[ManufacturerCnt]);
        70 : StringValue := GetJEDECBank7(Data[ManufacturerCnt]);
        71 : StringValue := GetJEDECBank8(Data[ManufacturerCnt]);
      end;
      Break;
    end;
  end;
  if StringValue = '' then
    StringValue := 'unbekannter Hersteller';
  SPDData.Add('Hersteller=' + StringValue);

  {Modell}
  StringValue := '';
  for Counter := 73 to 90 do
    StringValue := StringValue + Char(Data[Counter]);
  StringValue := Trim(StringValue);
  if StringValue = '' then
    StringValue := 'unbekanntes Modell';
  SPDData.Add('Modell=' + StringValue);

  {Größe}
  SizeTemp := GetMemSize_DDR2SDRAM(Data);
  SPDData.Add('Größe=' + GetCapacity(SizeTemp * 1024 * 1024));

  {Seriennummer}
  Move(Data[95], LWordValue, SizeOf(LWordValue));
  if LWordValue <> 0 then
    SPDData.Add('Seriennummer=' + IntToHex(Swap32(LWordValue), 8) + ' (' + IntToStr(LWordValue) + ')')
  else
    SPDData.Add('Seriennummer=nicht vorhanden');

  {Zusatzfunktionen}
  StringValue := '';
  if IsBitOn(Data[11], 0) then
    StringValue := 'Parität';
  if IsBitOn(Data[11], 1) then
  begin
    if StringValue = '' then
      StringValue := 'ECC' else
      StringValue := StringValue + ', ECC';
  end;
  if StringValue = '' then
    StringValue := 'keine';
  SPDData.Add('Zusatzfunktionen=' + StringValue);

  {Herstellungsdatum}
  if (Data[94] <> 0) and (Data[93] <> 0) then
    SPDData.Add('Herstellungsdatum=' +
                'Woche ' + IntToHex(Data[94], 2) + '/20' + IntToHex(Data[93], 2))
  else
    SPDData.Add('Herstellungsdatum=nicht vorhanden');

  {Physikalische Bänke}
  if Data[17] = 0 then
    StringValue := 'unbekannt' else
    StringValue := IntToHex(Data[17], 2);
  SPDData.Add('Physikalische Bänke=' + StringValue);

  {Zeilen x Spalten}
  case Data[3] of
    1..31 : StringValue := IntToStr(Data[3]);
    else    StringValue := 'unbekannt';
  end;
  case Data[4] of
    1..15 : StringValue2 := IntToStr(Data[4]);
    else    StringValue2 := 'unbekannt';
  end;
  SPDData.Add('Zeilen x Spalten=' + StringValue + ' x ' + StringValue2);

  {Unterstützte Latenzen}
  StringValue := '';
  if IsBitOn(Data[18], 2) then StringValue := StringValue + 'CL2, ';
  if IsBitOn(Data[18], 3) then StringValue := StringValue + 'CL3, ';
  if IsBitOn(Data[18], 4) then StringValue := StringValue + 'CL4, ';
  if IsBitOn(Data[18], 5) then StringValue := StringValue + 'CL5, ';
  if IsBitOn(Data[18], 6) then StringValue := StringValue + 'CL6, ';
  if IsBitOn(Data[18], 7) then StringValue := StringValue + 'CL7, ';
  Delete(StringValue, Length(StringValue) - 1, 255);
  if StringValue = '' then
    StringValue := 'unbekannt';
  SPDData.Add('CAS-Latenzen=' + StringValue);

  {SPD-Details}
  StringValue := IntToHex(Data[62], 2);
  if Data[0] = 0 then
    SizeValue := 'unbekannt' else
    SizeValue := IntToStr(Data[0]) + ' Bytes';
  SPDData.Add('SPD-EEPROM-Details=' +
    'Revision ' + StringValue[1] + '.' + StringValue[2] +
    ', Größe ' + SizeValue);
end;

procedure TSMBus.GetSPD_DDR3SDRAM(Data : TArray<Byte>; var SPDData : TStrings); {Typ 11}
var
  StringValue,
  StringValue2,
  SizeValue,
  UsedValue : String;
  Counter : Word;
  SizeTemp : UInt64;
  LWordValue : Cardinal;
begin
  SPDData.Add('Speichertyp=DDR3 SDRAM');

  case Data[3] and 15 of
    1  : StringValue := 'Registered DIMM, 133,35 mm';
    2  : StringValue := 'Unbuffered DIMM, 133,35 mm';
    3  : StringValue := 'Unbuffered 64 Bit Small Outline DIMM, 67,6 mm';
    4  : StringValue := 'Micro DIMM, unbekannte Größe';
    5  : StringValue := 'Mini Registered DIMM, 82,0 mm';
    6  : StringValue := 'Mini Unbuffered DIMM, 82,0 mm';
    7  : StringValue := 'Clocked 72 Bit Mini DIMM, 67,6 mm';
    8  : StringValue := 'Unbuffered 72 Bit Small Outline DIMM, 67,6 mm';
    9  : StringValue := 'Registered 72 Bit Small Outline DIMM, 67,6 mm';
    10 : StringValue := 'Clocked 72 Bit Small Outline DIMM, 67,6 mm';
    11 : StringValue := 'Load Reduction DIMM, 133,35 mm';
    12 : StringValue := 'Unbuffered 16 Bit Small Outline DIMM, 67,6 mm';
    13 : StringValue := 'Unbuffered 32 Bit Small Outline DIMM, 67,6 mm';
    else StringValue := 'unbekannt';
  end;
  SPDData.Add('Modultyp/-länge=' + StringValue);

  {Hersteller}
  case Data[117] and $7F of
    00 : StringValue := GetJEDECBank1 (Data[118]);
    01 : StringValue := GetJEDECBank2 (Data[118]);
    02 : StringValue := GetJEDECBank3 (Data[118]);
    03 : StringValue := GetJEDECBank4 (Data[118]);
    04 : StringValue := GetJEDECBank5 (Data[118]);
    05 : StringValue := GetJEDECBank6 (Data[118]);
    06 : StringValue := GetJEDECBank7 (Data[118]);
    07 : StringValue := GetJEDECBank8 (Data[118]);
    08 : StringValue := GetJEDECBank9 (Data[118]);
    09 : StringValue := GetJEDECBank10(Data[118]);
    10 : StringValue := GetJEDECBank11(Data[118]);
    11 : StringValue := GetJEDECBank12(Data[118]);
    12 : StringValue := GetJEDECBank13(Data[118]);
    13 : StringValue := GetJEDECBank14(Data[118]);
    14 : StringValue := GetJEDECBank15(Data[118]);
    else StringValue := 'unbekannt';
  end;
  SPDData.Add('Hersteller=' + StringValue);

  {Modell}
  StringValue := '';
  for Counter := 128 to 145 do
    StringValue := StringValue + Char(Data[Counter]);
  StringValue := Trim(StringValue);
  if StringValue = '' then
    StringValue := 'unbekanntes Modell';
  SPDData.Add('Modell=' + StringValue);

  {Größe}
  SizeTemp := GetMemSize_DDR3SDRAM(Data);
  SPDData.Add('Größe=' + GetCapacity(SizeTemp * 1024 * 1024));

  {Seriennummer}
  Move(Data[122], LWordValue, SizeOf(LWordValue));
  if LWordValue <> 0 then
    SPDData.Add('Seriennummer=' + IntToHex(Swap32(LWordValue), 8) + ' (' + IntToStr(LWordValue) + ')')
  else
    SPDData.Add('Seriennummer=nicht vorhanden');

  {Zusatzfunktionen}
  case Data[3] and 15 of
    1, 5 : StringValue := 'Registriert';
    else StringValue := '';
  end;
  if (Data[8] shr 3) and 3 = 1 then
  begin
    if StringValue = '' then
      StringValue := 'ECC' else
      StringValue := StringValue + ', ECC';
  end;
  if StringValue = '' then
    StringValue := 'keine';
  SPDData.Add('Zusatzfunktionen=' + StringValue);

  {Herstellungsdatum}
  if (Data[121] <> 0) and (Data[120] <> 0) then
    SPDData.Add('Herstellungsdatum=' +
                'Woche ' + IntToHex(Data[121], 2) + '/20' + IntToHex(Data[120], 2))
  else
    SPDData.Add('Herstellungsdatum=nicht vorhanden');

  {Physikalische Bänke}
  case ((Data[4] shr 4) and 7) of
    0 : StringValue := '8';
    1 : StringValue := '16';
    2 : StringValue := '32';
    3 : StringValue := '64';
  end;
  SPDData.Add('Physikalische Bänke=' + StringValue);

  {Zeilen x Spalten}
  case ((Data[5] shr 3) and 7) of
    0  : StringValue := '12';
    1  : StringValue := '13';
    2  : StringValue := '14';
    3  : StringValue := '15';
    4  : StringValue := '16';
    else StringValue := 'unbekannt';
  end;
  case Data[5] and 7 of
    0  : StringValue2 := '9';
    1  : StringValue2 := '10';
    2  : StringValue2 := '11';
    3  : StringValue2 := '12';
    else StringValue2 := 'unbekannt';
  end;
  SPDData.Add('Zeilen x Spalten=' + StringValue + ' x ' + StringValue2);

  {Unterstützte Latenzen}
  StringValue := '';
  if IsBitOn(Data[14], 0) then StringValue := StringValue+'CL4, ';
  if IsBitOn(Data[14], 1) then StringValue := StringValue+'CL5, ';
  if IsBitOn(Data[14], 2) then StringValue := StringValue+'CL6, ';
  if IsBitOn(Data[14], 3) then StringValue := StringValue+'CL7, ';
  if IsBitOn(Data[14], 4) then StringValue := StringValue+'CL8, ';
  if IsBitOn(Data[14], 5) then StringValue := StringValue+'CL9, ';
  if IsBitOn(Data[14], 6) then StringValue := StringValue+'CL10, ';
  if IsBitOn(Data[14], 7) then StringValue := StringValue+'CL11, ';
  if IsBitOn(Data[15], 0) then StringValue := StringValue+'CL12, ';
  if IsBitOn(Data[15], 1) then StringValue := StringValue+'CL13, ';
  if IsBitOn(Data[15], 2) then StringValue := StringValue+'CL14, ';
  if IsBitOn(Data[15], 3) then StringValue := StringValue+'CL15, ';
  if IsBitOn(Data[15], 4) then StringValue := StringValue+'CL16, ';
  if IsBitOn(Data[15], 5) then StringValue := StringValue+'CL17, ';
  if IsBitOn(Data[15], 6) then StringValue := StringValue+'CL18, ';
  Delete(StringValue, Length(StringValue) - 1, 255);
  if StringValue = '' then
    StringValue := 'unbekannt';
  SPDData.Add('Unterstützte Latenzen=' + StringValue);

  {SPD-Details}
  StringValue := IntToHex(Data[1], 2);
  case ((Data[0] shr 4) and 7) of
    1 : SizeValue := '256 Bytes';
    else SizeValue := 'unbekannt';
  end;
  case Data[0] and 15 of
    1 : UsedValue := ', davon 128 Bytes benutzt';
    2 : UsedValue := ', davon 176 Bytes benutzt';
    3 : UsedValue := ', davon 256 Bytes benutzt';
    else UsedValue := '';
  end;
  SPDData.Add('SPD-EEPROM-Details=' +
    'Revision ' + StringValue[1] + '.' + StringValue[2] +
    ', Größe ' + SizeValue + UsedValue);
end;

procedure TSMBus.GetSPD_DDR4SDRAM(Data : TArray<Byte>; var SPDData : TStrings); {Typ 12}
var
  StringValue,
  StringValue2,
  SizeValue,
  UsedValue : String;
  Counter : Word;
  SizeTemp : UInt64;
  LWordValue : Cardinal;
  StartLatency : Byte;
begin
  SPDData.Add('Speichertyp=DDR4 SDRAM');

  case Data[3] and 15 of
    1  : StringValue:='Registered DIMM, 133,35 mm';
    2  : StringValue:='Unbuffered DIMM, 133,35 mm';
    3  : StringValue:='Unbuffered 64 Bit Small Outline DIMM, 67,6 mm';
    4  : StringValue:='Load Reduction DIMM, unbekannte Größe';
    5  : StringValue:='Mini Registered DIMM, 82,0 mm';
    6  : StringValue:='Mini Unbuffered DIMM, 82,0 mm';
    8  : StringValue:='Registered 72 Bit Small Outline DIMM, 67,6 mm';
    9  : StringValue:='Unbuffered 72 Bit Small Outline DIMM, 67,6 mm';
    10 : StringValue:='Clocked 72 Bit Small Outline DIMM, 67,6 mm';
    12 : StringValue:='Unbuffered 16 Bit Small Outline DIMM, 67,6 mm';
    13 : StringValue:='Unbuffered 32 Bit Small Outline DIMM, 67,6 mm';
    else StringValue:='unbekannt';
  end;
  SPDData.Add('Modultyp/-länge=' + StringValue);

  {Hersteller}
  case Data[320] and $7F of
    00 : StringValue := GetJEDECBank1 (Data[321]);
    01 : StringValue := GetJEDECBank2 (Data[321]);
    02 : StringValue := GetJEDECBank3 (Data[321]);
    03 : StringValue := GetJEDECBank4 (Data[321]);
    04 : StringValue := GetJEDECBank5 (Data[321]);
    05 : StringValue := GetJEDECBank6 (Data[321]);
    06 : StringValue := GetJEDECBank7 (Data[321]);
    07 : StringValue := GetJEDECBank8 (Data[321]);
    08 : StringValue := GetJEDECBank9 (Data[321]);
    09 : StringValue := GetJEDECBank10(Data[321]);
    10 : StringValue := GetJEDECBank11(Data[321]);
    11 : StringValue := GetJEDECBank12(Data[321]);
    12 : StringValue := GetJEDECBank13(Data[321]);
    13 : StringValue := GetJEDECBank14(Data[321]);
    14 : StringValue := GetJEDECBank15(Data[321]);
    else StringValue := 'unbekannt';
  end;
  SPDData.Add('Hersteller=' + StringValue);

  {Modell}
  StringValue := '';
  for Counter := 329 to 348 do
    StringValue := StringValue + Char(Data[Counter]);
  StringValue := Trim(StringValue);
  if StringValue = '' then
    StringValue := 'unbekanntes Modell';
  SPDData.Add('Modell=' + StringValue);

  {Größe}
  SizeTemp := GetMemSize_DDR4SDRAM(Data);
  SPDData.Add('Größe=' + GetCapacity(SizeTemp * 1024 * 1024));

  {Seriennummer}
  Move(Data[325], LWordValue, SizeOf(LWordValue));
  if LWordValue <> 0 then
    SPDData.Add('Seriennummer=' + IntToHex(Swap32(LWordValue), 8) + ' (' + IntToStr(LWordValue) + ')')
  else
    SPDData.Add('Seriennummer=nicht vorhanden');

  {Zusatzfunktionen}
  StringValue := '';
  case Data[3] and 15 of
    1, 5, 8 : StringValue := 'Registriert';
  end;
  if (Data[13] shr 3) and 3 = 1 then
  begin
    if StringValue = '' then
      StringValue := 'ECC' else
      StringValue := StringValue + ', ECC';
  end;
  if StringValue = '' then
    StringValue := 'keine';
  SPDData.Add('Zusatzfunktionen=' + StringValue);

  {Herstellungsdatum}
  if (Data[324] <> 0) and (Data[323] <> 0) then
    SPDData.Add('Herstellungsdatum=' +
                'Woche ' + IntToHex(Data[324], 2) + '/20' + IntToHex(Data[323], 2))
  else
    SPDData.Add('Herstellungsdatum=nicht vorhanden');

  {Physikalische Bänke}
  case (Data[4] shr 4) and 3 of
    0 : StringValue := '4';
    1 : StringValue := '8';
  end;
  SPDData.Add('Physikalische Bänke=' + StringValue);

  {Zeilen x Spalten}
  case (Data[5] shr 3) and 7 of
    0  : StringValue := '12';
    1  : StringValue := '13';
    2  : StringValue := '14';
    3  : StringValue := '15';
    4  : StringValue := '16';
    5  : StringValue := '17';
    6  : StringValue := '18';
    else StringValue := 'unbekannt';
  end;
  case Data[5] and 7 of
    0  : StringValue2 := '9';
    1  : StringValue2 := '10';
    2  : StringValue2 := '11';
    3  : StringValue2 := '12';
    else StringValue2 := 'unbekannt';
  end;
  SPDData.Add('Zeilen x Spalten=' + StringValue + ' x ' + StringValue2);

  {Unterstützte Latenzen}
  StringValue := '';
  if IsBitOn(Data[23], 7) then
    StartLatency := 23
  else
    StartLatency := 7;

  for Counter := 0 to 7 do
    if IsBitOn(Data[20], Counter) then
      StringValue := StringValue + 'CL' + IntToStr(StartLatency + Counter) + ', ';

  Inc(StartLatency, 8);
  for Counter := 0 to 7 do
    if IsBitOn(Data[21], Counter) then
      StringValue := StringValue + 'CL' + IntToStr(StartLatency + Counter) + ', ';

  Inc(StartLatency, 8);
  for Counter := 0 to 7 do
    if IsBitOn(Data[22], Counter) then
      StringValue := StringValue + 'CL' + IntToStr(StartLatency + Counter) + ', ';

  Inc(StartLatency, 8);
  for Counter := 0 to 5 do
    if IsBitOn(Data[23], Counter) then
      StringValue := StringValue + 'CL' + IntToStr(StartLatency + Counter) + ', ';

  Delete(StringValue, Length(StringValue) - 1, 255);
  if StringValue = '' then
    StringValue := 'unbekannt';
  SPDData.Add('Unterstützte Latenzen=' + StringValue);

  {SPD-Details}
  StringValue := IntToHex(Data[1], 2);
  case ((Data[0] shr 4) and 7) of
    1 : SizeValue := '256 Bytes';
    2 : SizeValue := '512 Bytes';
    else SizeValue := 'unbekannt';
  end;
  case Data[0] and 15 of
    1  : UsedValue := ', davon 128 Bytes benutzt';
    2  : UsedValue := ', davon 256 Bytes benutzt';
    3  : UsedValue := ', davon 384 Bytes benutzt';
    4  : UsedValue := ', davon 512 Bytes benutzt';
    else UsedValue := '';
  end;
  SPDData.Add('SPD-EEPROM-Details=' +
    'Revision ' + StringValue[1] + '.' + StringValue[2] +
    ', Größe ' + SizeValue + UsedValue);
end;

procedure TSMBus.GetSPD_DDR5SDRAM(Data : TArray<Byte>; var SPDData : TStrings); {Typ 18}
var
  StringValue,
  SizeValue : String;
  Counter : Word;
  SizeTemp : UInt64;
  LWordValue : Cardinal;
begin
  SPDData.Add('Speichertyp=DDR5 SDRAM');

  case Data[3] and 15 of
    1  : StringValue := 'Registered DIMM (RDIMM)';
    2  : StringValue := 'Unregistered DIMM (UDIMM)';
    3  : StringValue := 'Unbuffered Small Outline DIMM (SODIMM)';
    4  : StringValue := 'Load Reduced DIMM (LRDIMM)';
    7  : StringValue := 'Multiplexed Rank DIMM (MRDIMM)';
    10 : StringValue := 'Differential DIMM (DDIMM)';
    11 : StringValue := 'Solder down (direkte Anbindung an Speicher-Kontroller)';
    else StringValue := 'unbekannt';
  end;
  SPDData.Add('Modultyp=' + StringValue);

  if IsBitOn(Data[3], 7) then
  begin
    SPDData.Add('Hybrid-Modul=ja');

    case (Data[3] shr 4) and 7 of
      0  : StringValue := 'kein Hybrid';
      1  : StringValue := 'NVDIMM-N Hybrid';
      2  : StringValue := 'NVDIMM-P Hybrid';
      else StringValue := 'unbekannt';
    end;
    SPDData.Add('Hybrid-Typ=' + StringValue);
  end
  else
    SPDData.Add('Hybrid-Modul=nein');

  {Modulhersteller}
  case Data[512] and $7F of
    00 : StringValue := GetJEDECBank1 (Data[513]);
    01 : StringValue := GetJEDECBank2 (Data[513]);
    02 : StringValue := GetJEDECBank3 (Data[513]);
    03 : StringValue := GetJEDECBank4 (Data[513]);
    04 : StringValue := GetJEDECBank5 (Data[513]);
    05 : StringValue := GetJEDECBank6 (Data[513]);
    06 : StringValue := GetJEDECBank7 (Data[513]);
    07 : StringValue := GetJEDECBank8 (Data[513]);
    08 : StringValue := GetJEDECBank9 (Data[513]);
    09 : StringValue := GetJEDECBank10(Data[513]);
    10 : StringValue := GetJEDECBank11(Data[513]);
    11 : StringValue := GetJEDECBank12(Data[513]);
    12 : StringValue := GetJEDECBank13(Data[513]);
    13 : StringValue := GetJEDECBank14(Data[513]);
    14 : StringValue := GetJEDECBank15(Data[513]);
    else StringValue := 'unbekannt';
  end;
  SPDData.Add('Modulhersteller=' + StringValue);

  {DRAM-Hersteller}
  case Data[552] and $7F of
    00 : StringValue := GetJEDECBank1 (Data[553]);
    01 : StringValue := GetJEDECBank2 (Data[553]);
    02 : StringValue := GetJEDECBank3 (Data[553]);
    03 : StringValue := GetJEDECBank4 (Data[553]);
    04 : StringValue := GetJEDECBank5 (Data[553]);
    05 : StringValue := GetJEDECBank6 (Data[553]);
    06 : StringValue := GetJEDECBank7 (Data[553]);
    07 : StringValue := GetJEDECBank8 (Data[553]);
    08 : StringValue := GetJEDECBank9 (Data[553]);
    09 : StringValue := GetJEDECBank10(Data[553]);
    10 : StringValue := GetJEDECBank11(Data[553]);
    11 : StringValue := GetJEDECBank12(Data[553]);
    12 : StringValue := GetJEDECBank13(Data[553]);
    13 : StringValue := GetJEDECBank14(Data[553]);
    14 : StringValue := GetJEDECBank15(Data[553]);
    else StringValue := 'unbekannt';
  end;
  SPDData.Add('DRAM-Hersteller=' + StringValue);

  {Modell}
  StringValue := '';
  for Counter := 521 to 550 do
    StringValue := StringValue + Char(Data[Counter]);
  StringValue := Trim(StringValue);
  if StringValue = '' then
    StringValue := 'unbekanntes Modell';
  SPDData.Add('Modell=' + StringValue);

  {Größe}
  SizeTemp := GetMemSize_DDR5SDRAM(Data);
  SPDData.Add('Größe=' + GetCapacity(SizeTemp * 1024 * 1024 * 1024));

  {Seriennummer}
  Move(Data[517], LWordValue, SizeOf(LWordValue));
  if LWordValue <> 0 then
    SPDData.Add('Seriennummer=' + IntToHex(Swap32(LWordValue), 8) + ' (' + IntToStr(LWordValue) + ')')
  else
    SPDData.Add('Seriennummer=nicht vorhanden');

  {Zusatzfunktionen}
  StringValue := '';
  if Data[3] and 15 = 1 then
     StringValue := 'Registriert';
  if (Data[235] shr 3) and 3 > 0 then
  begin
    if StringValue = '' then
      StringValue := 'ECC' else
      StringValue := StringValue + ', ECC';
  end;
  if StringValue = '' then
    StringValue := 'keine';
  SPDData.Add('Zusatzfunktionen=' + StringValue);

  {Herstellungsdatum}
  if (Data[516] <> 0) and (Data[515] <> 0) then
    SPDData.Add('Herstellungsdatum=' +
                'Woche ' + IntToHex(Data[516], 2) + '/20' + IntToHex(Data[515], 2))
  else
    SPDData.Add('Herstellungsdatum=nicht vorhanden');

  {Rang-Mischung}
  if IsBitOn(Data[234], 6) then
    SPDData.Add('Rang-Mischung=asymmetrisch')
  else
    SPDData.Add('Rang-Mischung=symmetrisch');

  {Anzahl der Ränge}
  SPDData.Add('Anzahl der Ränge=' + IntToStr(((Data[234] shr 3) and 7) + 1));

  {Kanäle pro DIMM}
  case (Data[235] shr 5) and 3 of
    0  : StringValue := '1 Kanal';
    1  : StringValue := '2 Kanäle';
    else StringValue := 'unbekannt';
  end;
  SPDData.Add('Kanäle pro DIMM=' + StringValue);

  {Breite des primären Busses}
  case Data[235] and 7 of
    0  : StringValue := '8 Bit';
    1  : StringValue := '16 Bit';
    2  : StringValue := '32 Bit';
    3  : StringValue := '64 Bit';
    else StringValue := 'unbekannt';
  end;
  SPDData.Add('Breite des primären Busses=' + StringValue);

  {SDRAM I/O-Breite}
  case (Data[6] shr 5) and 7 of
    0  : StringValue := '4 Bit';
    1  : StringValue := '8 Bit';
    2  : StringValue := '16 Bit';
    3  : StringValue := '32 Bit';
    else StringValue := 'unbekannt';
  end;
  SPDData.Add('SDRAM I/O-Breite=' + StringValue);

  {Dies pro Paket}
  case (Data[4] shr 5) and 7 of
    0  : StringValue := '1 Die';
    1  : StringValue := '2 Dies';
    2  : StringValue := '2 Dies';
    3  : StringValue := '4 Dies';
    4  : StringValue := '8 Dies';
    5  : StringValue := '16 Dies';
    else StringValue := 'unbekannt';
  end;
  SPDData.Add('Dies pro Paket=' + StringValue);

  {SDRAM-Dichte pro Die}
  case Data[4] and 31 of
    1  : StringValue := '4 GBit';
    2  : StringValue := '8 GBit';
    3  : StringValue := '12 GBit';
    4  : StringValue := '16 GBit';
    5  : StringValue := '24 GBit';
    6  : StringValue := '32 GBit';
    7  : StringValue := '48 GBit';
    8  : StringValue := '64 GBit';
    else StringValue := 'unbekannt';
  end;
  SPDData.Add('SDRAM-Dichte pro Die=' + StringValue);

  {SPD-Details}
  StringValue := IntToHex(Data[1], 2);
  case ((Data[0] shr 4) and 7) of
    1  : SizeValue := '256 Bytes';
    2  : SizeValue := '512 Bytes';
    3  : SizeValue := '1024 Bytes';
    4  : SizeValue := '2024 Bytes';
    else SizeValue := 'unbekannt';
  end;
  SPDData.Add('SPD-EEPROM-Details=' +
    'Revision ' + StringValue[1] + '.' + StringValue[2] +
    ', Größe ' + SizeValue);
end;

function TSMBus.HiDWord(AValue : UInt64) : Cardinal;
begin
  Result := AValue shr 32;
end;

function TSMBus.LoDWord(AValue : UInt64) : Cardinal;
begin
  Result := Cardinal(AValue);
end;

function TSMBus.IsBitOn(Value : UInt64; Bit : Byte) : Boolean;
begin
  if Bit > 31 then
    Result := (HiDWord(Value) and (1 shl (Bit - 32))) <> 0
  else
    Result := (LoDWord(Value) and (1 shl Bit)) <> 0;
end;

function TSMBus.Swap32(Value : LongWord) : LongWord;
begin
  Result := Swap(Value shr 16) or (Swap(Value) shl 16);
end;

function TSMBus.GetNameFromStr(ASource : String; ASep : String = '=') : String;
var
  Position : Integer;
begin
  Position := Pos(ASep, ASource);
  if Position > 0 then
    Result := Trim(Copy(ASource, 1, Position - 1))
  else
    Result := ASource;
end;

function TSMBus.GetValueFromStr(ASource : String; ASep : String = '=') : String;
var
  Position : Integer;
begin
  Position := Pos(ASep, ASource);
  if Position > 0 then
    Result := Copy(ASource, Position + Length(ASep), 1024)
  else
    Result := '';
end;

function TSMBus.GetCapacity(AValue : UInt64) : String;
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

end.
