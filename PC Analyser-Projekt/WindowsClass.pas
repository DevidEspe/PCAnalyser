unit WindowsClass;

interface

uses
  Winapi.Windows, Winapi.ShlObj, Winapi.ActiveX, Winapi.ShellAPI,
  System.SysUtils, System.StrUtils, System.Classes,
  System.Win.Registry, System.Math, System.IOUtils;

type
  TWindows = class(TObject)
  public
    constructor Create;
    destructor Destroy; override;
    type
      TVersionInfo = record
        FileName,
        FileVersion,
        ProductVersion : String;
        Major,
        Minor,
        Release,
        Build : Cardinal;
        ProductMajor,
        ProductMinor,
        ProductRelease,
        ProductBuild : Cardinal;
        PreReleaseBuild,
        DebugBuild,
        PrivateBuild : Boolean;
      end;
      TInstallRecord = record
        Name,
        Version,
        Company,
        Uninstall : String;
        HideFromControlPanel : Boolean;
      end;
      TInstallData = Array of TInstallRecord;
    var
      OSVIX : TOSVersionInfoEx;
      IsWow64 : LongBool;
      SWList : TInstallData;
    function GetFileVerInfo(const AFilename : String; out AData : TVersionInfo) : Boolean;

    function GetWinSysDir : String;
    function GetWindowsDir : String;
    function GetSystemDir : String;
    function GetWindowsInstallDate : TDateTime;
    function FormatOSName(const AName : String) : String;
    function GetTrueWindowsVersion(var AMajor, AMinor, ABuild : Cardinal) : String;
    function GetTrueWindowsName : String;
    function IsWinPE : Boolean;
    function GetWinPEVersion : String;
    function IsWindowsCompatibilityMode : Boolean;
    function GetWindowsCompatibilityMode : String;
    function GetServicePack : String;
    function GetWindowsCodename : String;
    function DetectInstalledSoftware : TInstallData;
    function GetWindowsDirectories : TStringList;
    procedure GetEnvironmentVariables(EnvList : TStrings);
    function GetNameFromStr(ASource : String; ASep : String = '=') : String;
    function GetValueFromStr(ASource : String; ASep : String = '=') : String;
    private
      type
        TRtlGetNtVersionNumbers = procedure(out MajorVersion, MinorVersion, BuildNumber : Cardinal); stdcall;
        TRtlGetVersion = function(var TOSVersionInfoExW): Longint; stdcall;
      var
        NTDLLHandle : THandle;
        RtlGetNtVersionNumbers : TRtlGetNtVersionNumbers;
        RtlGetVersion : TRtlGetVersion;
      procedure ResetMemory(out P; Size: Longint);
      function StripSpaces(ASource : String) : String;
      function OpenRegistryReadOnly(ARoot : HKEY = HKEY_LOCAL_MACHINE) : TRegistry;
  end;

implementation

const
  PRODUCT_BUSINESS                           = $00000006;
  PRODUCT_BUSINESS_N                         = $00000010;
  PRODUCT_CLUSTER_SERVER                     = $00000012;
  PRODUCT_DATACENTER_SERVER                  = $00000008;
  PRODUCT_DATACENTER_SERVER_CORE             = $0000000C;
  PRODUCT_DATACENTER_SERVER_CORE_V           = $00000027;
  PRODUCT_DATACENTER_SERVER_V                = $00000025;
  PRODUCT_CLUSTER_SERVER_V                   = $00000040;
  PRODUCT_ENTERPRISE                         = $00000004;
  PRODUCT_ENTERPRISE_E                       = $00000046;
  PRODUCT_ENTERPRISE_N                       = $0000001B;
  PRODUCT_ENTERPRISE_SERVER                  = $0000000A;
  PRODUCT_ENTERPRISE_SERVER_CORE             = $0000000E;
  PRODUCT_ENTERPRISE_SERVER_CORE_V           = $00000029;
  PRODUCT_ENTERPRISE_SERVER_IA64             = $0000000F;
  PRODUCT_ENTERPRISE_SERVER_V                = $00000026;
  PRODUCT_ESSENTIALBUSINESS_SERVER_ADDL      = $0000003C; // Windows Essential Server Solution Additional
  PRODUCT_ESSENTIALBUSINESS_SERVER_ADDLSVC   = $0000003E; // Windows Essential Server Solution Additional SVC
  PRODUCT_ESSENTIALBUSINESS_SERVER_MGMT      = $0000003B; // Windows Essential Server Solution Management
  PRODUCT_ESSENTIALBUSINESS_SERVER_MGMTSVC   = $0000003D; // Windows Essential Server Solution Management SVC
  PRODUCT_HOME_BASIC                         = $00000002;
  PRODUCT_HOME_BASIC_E                       = $00000043;
  PRODUCT_HOME_BASIC_N                       = $00000005;
  PRODUCT_HOME_PREMIUM                       = $00000003;
  PRODUCT_HOME_PREMIUM_E                     = $00000044;
  PRODUCT_HOME_PREMIUM_N                     = $0000001A;
  PRODUCT_HYPERV                             = $0000002A;
  PRODUCT_MEDIUMBUSINESS_SERVER_MANAGEMENT   = $0000001E;
  PRODUCT_MEDIUMBUSINESS_SERVER_MESSAGING    = $00000020;
  PRODUCT_MEDIUMBUSINESS_SERVER_SECURITY     = $0000001F;
  PRODUCT_PROFESSIONAL                       = $00000030;
  PRODUCT_PROFESSIONAL_E                     = $00000045;
  PRODUCT_PROFESSIONAL_N                     = $00000031;
  PRODUCT_PROFESSIONAL_WMC                   = $00000067; // Professional with Media Center
  PRODUCT_SB_SOLUTION_SERVER                 = $00000032; // Windows Small Business Server 2011 Essentials
  PRODUCT_SB_SOLUTION_SERVER_EM              = $00000036; // Server For SB Solutions EM
  PRODUCT_SERVER_FOR_SB_SOLUTIONS            = $00000033; // Server For SB Solutions
  PRODUCT_SERVER_FOR_SB_SOLUTIONS_EM         = $00000037; // Server For SB Solutions EM
  PRODUCT_SERVER_FOR_SMALLBUSINESS           = $00000018;
  PRODUCT_SERVER_FOR_SMALLBUSINESS_V         = $00000023;
  PRODUCT_SERVER_FOUNDATION                  = $00000021;
  PRODUCT_SMALLBUSINESS_SERVER               = $00000009;
  PRODUCT_SMALLBUSINESS_SERVER_PREMIUM       = $00000019; // Small Business Server Premium
  PRODUCT_SMALLBUSINESS_SERVER_PREMIUM_CORE  = $0000003F; // Small Business Server Premium (core installation)
  PRODUCT_SOLUTION_EMBEDDEDSERVER            = $00000038; // Windows MultiPoint Server
  PRODUCT_STANDARD_EVALUATION_SERVER         = $0000004F; // Server Standard (evaluation installation)
  PRODUCT_STANDARD_SERVER                    = $00000007;
  PRODUCT_STANDARD_SERVER_CORE               = $0000000D;
  PRODUCT_STANDARD_SERVER_CORE_V             = $00000028;
  PRODUCT_STANDARD_SERVER_V                  = $00000024;
  PRODUCT_STANDARD_SERVER_SOLUTIONS          = $00000034; // Server Solutions Premium
  PRODUCT_STANDARD_SERVER_SOLUTIONS_CORE     = $00000035; // Server Solutions Premium (core installation)
  PRODUCT_STARTER                            = $0000000B;
  PRODUCT_STARTER_E                          = $00000042;
  PRODUCT_STARTER_N                          = $0000002F;
  PRODUCT_STORAGE_ENTERPRISE_SERVER          = $00000017;
  PRODUCT_STORAGE_EXPRESS_SERVER             = $00000014;
  PRODUCT_STORAGE_STANDARD_SERVER            = $00000015;
  PRODUCT_STORAGE_WORKGROUP_SERVER           = $00000016;
  PRODUCT_UNDEFINED                          = $00000000;
  PRODUCT_ULTIMATE                           = $00000001;
  PRODUCT_ULTIMATE_E                         = $00000047;
  PRODUCT_ULTIMATE_N                         = $0000001C;
  PRODUCT_WEB_SERVER                         = $00000011;
  PRODUCT_WEB_SERVER_CORE                    = $0000001D;
  PRODUCT_CORE                               = $00000065; // Windows 10 Home
  PRODUCT_CORE_N                             = $00000062; // Windows 10 Home N
  PRODUCT_CORE_COUNTRYSPECIFIC               = $00000063; // Windows 10 Home China
  PRODUCT_CORE_SINGLELANGUAGE                = $00000064; // Windows 10 Home Single Language
  PRODUCT_MOBILE_CORE                        = $00000068; // Windows 10 Mobile
  PRODUCT_MOBILE_ENTERPRISE                  = $00000085; // Windows 10 Mobile Enterprise
  PRODUCT_EDUCATION                          = $00000079; // Windows 10 Education
  PRODUCT_EDUCATION_N                        = $0000007A; // Windows 10 Education N
  PRODUCT_DATACENTER_EVALUATION_SERVER       = $00000050; // Server Datacenter (evaluation installation)
  PRODUCT_DATACENTER_A_SERVER_CORE           = $00000091; // Server Datacenter, Semi-Annual Channel (core installation)
  PRODUCT_STANDARD_A_SERVER_CORE             = $00000092; // Server Standard, Semi-Annual Channel (core installation)
  PRODUCT_ENTERPRISE_EVALUATION              = $00000048; // Windows 10 Enterprise Evaluation
  PRODUCT_ENTERPRISE_N_EVALUATION            = $00000054; // Windows 10 Enterprise N Evaluation
  PRODUCT_ENTERPRISE_S                       = $0000007D; // Windows 10 Enterprise 2015 LTSB
  PRODUCT_ENTERPRISE_S_EVALUATION            = $00000081; // Windows 10 Enterprise 2015 LTSB Evaluation
  PRODUCT_ENTERPRISE_S_N                     = $0000007E; // Windows 10 Enterprise 2015 LTSB N
  PRODUCT_ENTERPRISE_S_N_EVALUATION          = $00000082; // Windows 10 Enterprise 2015 LTSB N Evaluation
  PRODUCT_HOME_PREMIUM_SERVER                = $00000022; // Windows Home Server 2011
  PRODUCT_HOME_SERVER                        = $00000013; // Windows Storage Server 2008 R2 Essentials
  PRODUCT_IOTENTERPRISE                      = $000000BC; // Windows IoT Enterprise
  PRODUCT_IOTENTERPRISE_S                    = $000000BF; // Windows IoT Enterprise LTSC
  PRODUCT_IOTUAP                             = $0000007B; // Windows 10 IoT Core
  PRODUCT_IOTUAPCOMMERCIAL                   = $00000083; // Windows 10 IoT Core Commercial
  PRODUCT_MULTIPOINT_PREMIUM_SERVER          = $0000004D; // Windows MultiPoint Server Premium (full installation)
  PRODUCT_MULTIPOINT_STANDARD_SERVER         = $0000004C; // Windows MultiPoint Server Standard (full installation)
  PRODUCT_PRO_WORKSTATION                    = $000000A1; // Windows 10 Pro for Workstations
  PRODUCT_PRO_WORKSTATION_N                  = $000000A2; // Windows 10 Pro for Workstations N
  PRODUCT_STORAGE_ENTERPRISE_SERVER_CORE     = $0000002E; // Storage Server Enterprise (core installation)
  PRODUCT_STORAGE_STANDARD_EVALUATION_SERVER = $00000060; // Storage Server Standard (evaluation installation)
  PRODUCT_STORAGE_STANDARD_SERVER_CORE       = $0000002C; // Storage Server Standard (core installation)
  PRODUCT_STORAGE_WORKGROUP_EVALUATION_SERVER= $0000005F; // Storage Server Workgroup (evaluation installation)
  PRODUCT_STORAGE_WORKGROUP_SERVER_CORE      = $0000002D; // Storage Server Workgroup (core installation)

constructor TWindows.Create;
begin
  inherited;

  ResetMemory(OSVIX, SizeOf(OSVIX));
  OSVIX.dwOSVersionInfoSize := SizeOf(OSVIX);
  GetVersionEx(OSVIX);

  if not IsWow64Process(GetCurrentProcess, IsWow64) then
    IsWow64 := False;

  NTDLLHandle := GetModuleHandle(PChar('NTDLL.DLL'));
  @RtlGetNtVersionNumbers := GetProcAddress(NTDLLHandle, 'RtlGetNtVersionNumbers');
  @RtlGetVersion := GetProcAddress(NTDLLHandle, 'RtlGetVersion');
end;

destructor TWindows.Destroy;
begin
  inherited;
end;

function TWindows.GetFileVerInfo(const AFilename : String; out AData : TVersionInfo) : Boolean;
var
  Handle : Cardinal;
  Len, Size : Cardinal;
  buf : PChar;
  FixedFileInfo : PVSFixedFileInfo;
begin
  Result := False;
  AData.FileName := AFilename;
  Size := GetFileVersionInfoSize(PChar(AFilename), Handle);
  if Size > 0 then
  begin
    buf := Allocmem(Size);
    try
      if GetFileVersionInfo(PChar(AFilename), Handle, Size, buf) then
      begin
        if VerQueryValue(buf, '\', Pointer(FixedFileInfo), Len) then
        begin
          AData.Major := HiWord(FixedFileInfo^.dwfileversionms);
          AData.Minor := LoWord(FixedFileInfo^.dwfileversionms);
          AData.Release := HiWord(FixedFileInfo^.dwfileversionls);
          AData.Build := LoWord(FixedFileInfo^.dwfileversionls);

          AData.ProductMajor := HiWord(FixedFileInfo^.dwProductVersionMS);
          AData.ProductMinor := LoWord(FixedFileInfo^.dwProductVersionMS);
          AData.ProductRelease := HiWord(FixedFileInfo^.dwProductVersionLS);
          AData.ProductBuild := LoWord(FixedFileInfo^.dwProductVersionLS);
          AData.PreReleaseBuild := FixedFileInfo^.dwFileFlags and VS_FF_PRERELEASE = VS_FF_PRERELEASE;
          AData.DebugBuild := FixedFileInfo^.dwFileFlags and VS_FF_DEBUG = VS_FF_DEBUG;
          AData.PrivateBuild := FixedFileInfo^.dwFileFlags and VS_FF_PRIVATEBUILD = VS_FF_PRIVATEBUILD;

          AData.ProductVersion := Format('%u.%u.%u', [AData.ProductMajor, AData.ProductMinor, AData.ProductRelease]);
          AData.FileVersion := Format('%u.%u.%u.%u', [AData.Major, AData.Minor, AData.Release, AData.Build]);

          Result := True;
        end;
      end;
    finally
      FreeMem(buf);
    end;
  end;
end;

function TWindows.GetWinSysDir : String;
var
  PathSize : Integer;
  PathName : PChar;
begin
  PathSize := MAX_PATH;
  PathName := StrAlloc(PathSize);
  GetWindowsDirectory(PathName, PathSize);
  Result := String(PathName) + ';';
  GetSystemDirectory(PathName, PathSize);
  Result := Result + String(PathName) + ';';
  StrDispose(PathName);
end;

function TWindows.GetWindowsDir : String;
var
  PathSize : Integer;
  PathName : PChar;
begin
  PathSize := MAX_PATH;
  PathName := StrAlloc(PathSize);
  GetWindowsDirectory(PathName, PathSize);
  Result := String(PathName);
  StrDispose(PathName);
end;

function TWindows.GetSystemDir : String;
var
  PathSize : Integer;
  PathName : PChar;
begin
  PathSize := MAX_PATH;
  PathName := StrAlloc(PathSize);
  GetSystemDirectory(PathName, PathSize);
  Result := String(PathName);
  StrDispose(PathName);
end;

function TWindows.GetWindowsInstallDate : TDateTime;
var
  Reg : TRegistry;
  IntValue : Cardinal;
begin
  Result := 0;
  try
    Reg := OpenRegistryReadOnly;
    if Reg.OpenKey('SOFTWARE\Microsoft\Windows NT\CurrentVersion', False) then
    begin
      IntValue := Reg.ReadInteger('InstallDate');
      if IntValue > 0 then
      begin
        Result := Int(EncodeDate(1970, 1, 1));
        Result := ((Result * SecsPerDay) + IntValue) / SecsPerDay;
      end;
      Reg.CloseKey;
    end;
  finally
    FreeAndNil(Reg);
  end;
end;

function TWindows.FormatOSName(const AName : String) : String;
begin
  Result := AName;
  Result := StringReplace(Result, 'Service Pack ', 'SP', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'Standard', 'Std', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'Professional', 'Pro', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'Enterprise', 'Ent', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'Edition', '', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '(R)', '', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'NULL', '', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '®', '', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '(TM)', ' ', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'Microsoft', '', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'Seven', '7', [rfReplaceAll, rfIgnoreCase]);
  Result := Trim(StripSpaces(Result));
end;

function TWindows.GetTrueWindowsVersion(var AMajor, AMinor, ABuild : Cardinal) : String;
var
  vi : TVersionInfo;
begin
  AMajor := 0; AMinor := 0; ABuild := 0;

  GetFileVerInfo(FileSearch(Winapi.Windows.kernel32, GetWinSysDir), vi);
  if Assigned(RtlGetNtVersionNumbers) then
  begin
    RtlGetNtVersionNumbers(AMajor, AMinor, ABuild);
    if ABuild > 0 then
      ABuild := LoWord(ABuild);
  end else
  begin
    AMajor := vi.ProductMajor;
    AMinor := vi.ProductMinor;
    ABuild := Max(OSVIX.dwBuildNumber, vi.ProductRelease);
  end;

  if ABuild = 0 then
    with TRegistry.Create do
      try
        RootKey := HKEY_CURRENT_USER;
        if OpenKeyReadOnly('\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon') then
        begin
          if ValueExists('BuildNumber') then
            ABuild := ReadInteger('BuildNumber');
          CloseKey;
        end;
      finally
        Free;
      end;

  if ABuild = 0 then
    ABuild := Max(OSVIX.dwBuildNumber, vi.ProductRelease);

  Result := Format('%d.%d.%d', [AMajor, AMinor, ABuild]);
end;

function TWindows.GetTrueWindowsName : String;
var
  Edition : String;
  ProductType,
  Major, Minor,
  Build : Cardinal;
begin
  Edition := '';

  if IsWinPE then
  begin
    Result := 'Windows PE ' + GetWinPEVersion;
    Exit;
  end;

  GetTrueWindowsVersion(Major, Minor, Build);
  if not GetProductInfo(Major,
                        Minor,
                        OSVIX.wServicePackMajor,
                        OSVIX.wServicePackMinor,
                        ProductType) then
  ProductType := 0;

  case ProductType of
    PRODUCT_BUSINESS                            : Edition:='Business';
    PRODUCT_BUSINESS_N                          : Edition:='Business N';
    PRODUCT_CLUSTER_SERVER                      : Edition:='HPC Edition';
    PRODUCT_DATACENTER_SERVER                   : Edition:='Datacenter Full';
    PRODUCT_DATACENTER_SERVER_CORE              : Edition:='Datacenter Core';
    PRODUCT_DATACENTER_SERVER_CORE_V            : Edition:='Datacenter without Hyper-V Core';
    PRODUCT_DATACENTER_SERVER_V                 : Edition:='Datacenter without Hyper-V Full';
    PRODUCT_ENTERPRISE                          : Edition:='Enterprise';
    PRODUCT_ENTERPRISE_E                        : Edition:='Enterprise E';
    PRODUCT_ENTERPRISE_N                        : Edition:='Enterprise N';
    PRODUCT_ENTERPRISE_SERVER                   : Edition:='Enterprise Full';
    PRODUCT_ENTERPRISE_SERVER_CORE              : Edition:='Enterprise Core';
    PRODUCT_ENTERPRISE_SERVER_CORE_V            : Edition:='Enterprise without Hyper-V Core';
    PRODUCT_ENTERPRISE_SERVER_IA64              : Edition:='Enterprise for Itanium-based Systems';
    PRODUCT_ENTERPRISE_SERVER_V                 : Edition:='Enterprise without Hyper-V Full';
    PRODUCT_HOME_BASIC                          : Edition:='Home Basic';
    PRODUCT_HOME_BASIC_E                        : Edition:='Home Basic E';
    PRODUCT_HOME_BASIC_N                        : Edition:='Home Basic N';
    PRODUCT_HOME_PREMIUM                        : Edition:='Home Premium';
    PRODUCT_HOME_PREMIUM_E                      : Edition:='Home Premium E';
    PRODUCT_HOME_PREMIUM_N                      : Edition:='Home Premium N';
    PRODUCT_HYPERV                              : Edition:='Microsoft Hyper-V Server';
    PRODUCT_MEDIUMBUSINESS_SERVER_MANAGEMENT    : Edition:='Windows Essential Business Server Management Server';
    PRODUCT_MEDIUMBUSINESS_SERVER_MESSAGING     : Edition:='Windows Essential Business Server Messaging Server';
    PRODUCT_MEDIUMBUSINESS_SERVER_SECURITY      : Edition:='Windows Essential Business Server Security Server';
    PRODUCT_PROFESSIONAL                        : Edition:='Professional';
    PRODUCT_PROFESSIONAL_E                      : Edition:='Professional E';
    PRODUCT_PROFESSIONAL_N                      : Edition:='Professional N';
    PRODUCT_PROFESSIONAL_WMC                    : Edition:='Professional with Media Center';
    PRODUCT_SB_SOLUTION_SERVER                  : Edition:='Small Business Essentials';
    PRODUCT_SB_SOLUTION_SERVER_EM               : Edition:='SB Solutions EM';
    PRODUCT_SERVER_FOR_SB_SOLUTIONS             : Edition:='SB Solutions';
    PRODUCT_SERVER_FOR_SB_SOLUTIONS_EM          : Edition:='SB Solutions EM';
    PRODUCT_SERVER_FOR_SMALLBUSINESS            : Edition:='Essential Solutions';
    PRODUCT_SERVER_FOR_SMALLBUSINESS_V          : Edition:='without Hyper-V for Windows Essential Server Solutions';
    PRODUCT_SERVER_FOUNDATION                   : Edition:='Foundation';
    PRODUCT_SMALLBUSINESS_SERVER                : Edition:='Small Business';
    PRODUCT_SMALLBUSINESS_SERVER_PREMIUM        : Edition:='Small Business Server Premium';
    PRODUCT_SMALLBUSINESS_SERVER_PREMIUM_CORE   : Edition:='Small Business Server Premium (core installation)';
    PRODUCT_SOLUTION_EMBEDDEDSERVER             : Edition:='MultiPoint';
    PRODUCT_STANDARD_EVALUATION_SERVER          : Edition:='Standard (evaluation installation)';
    PRODUCT_STANDARD_SERVER                     : Edition:='Standard Full';
    PRODUCT_STANDARD_SERVER_CORE                : Edition:='Standard Core';
    PRODUCT_STANDARD_SERVER_CORE_V              : Edition:='Standard without Hyper-V Core';
    PRODUCT_STANDARD_SERVER_V                   : Edition:='Standard without Hyper-V Full';
    PRODUCT_STANDARD_SERVER_SOLUTIONS           : Edition:='Solutions Premium';
    PRODUCT_STANDARD_SERVER_SOLUTIONS_CORE      : Edition:='Solutions Premium (core installation)';
    PRODUCT_STARTER                             : Edition:='Starter';
    PRODUCT_STARTER_E                           : Edition:='Starter E';
    PRODUCT_STARTER_N                           : Edition:='Starter N';
    PRODUCT_STORAGE_ENTERPRISE_SERVER           : Edition:='Storage Server Enterprise';
    PRODUCT_STORAGE_EXPRESS_SERVER              : Edition:='Storage Server Express';
    PRODUCT_STORAGE_STANDARD_SERVER             : Edition:='Storage Server Standard';
    PRODUCT_STORAGE_WORKGROUP_SERVER            : Edition:='Storage Server Workgroup';
    PRODUCT_UNDEFINED                           : Edition:='';
    PRODUCT_ULTIMATE                            : Edition:='Ultimate';
    PRODUCT_ULTIMATE_E                          : Edition:='Ultimate E';
    PRODUCT_ULTIMATE_N                          : Edition:='Ultimate N';
    PRODUCT_WEB_SERVER                          : Edition:='Web Server Full';
    PRODUCT_WEB_SERVER_CORE                     : Edition:='Web Server Core';
    PRODUCT_CORE                                : Edition:='Home';
    PRODUCT_CORE_N                              : Edition:='Home N';
    PRODUCT_CORE_COUNTRYSPECIFIC                : Edition:='Home China';
    PRODUCT_CORE_SINGLELANGUAGE                 : Edition:='Home Single Language';
    PRODUCT_MOBILE_CORE                         : Edition:='Mobile';
    PRODUCT_MOBILE_ENTERPRISE                   : Edition:='Mobile Enterprise';
    PRODUCT_EDUCATION                           : Edition:='Education';
    PRODUCT_EDUCATION_N                         : Edition:='Education N';
    PRODUCT_ESSENTIALBUSINESS_SERVER_ADDL       : Edition:='Essential Solution Additional';
    PRODUCT_ESSENTIALBUSINESS_SERVER_ADDLSVC    : Edition:='Essential Solution Additional SVC';
    PRODUCT_ESSENTIALBUSINESS_SERVER_MGMT       : Edition:='Essential Solution Management';
    PRODUCT_ESSENTIALBUSINESS_SERVER_MGMTSVC    : Edition:='Essential Solution Management SVC';
    PRODUCT_CLUSTER_SERVER_V                    : Edition:='Server Hyper Core V';
    PRODUCT_DATACENTER_EVALUATION_SERVER        : Edition:='Server Datacenter (evaluation installation)';
    PRODUCT_DATACENTER_A_SERVER_CORE            : Edition:='Server Datacenter, Semi-Annual Channel (core installation)';
    PRODUCT_STANDARD_A_SERVER_CORE              : Edition:='Server Standard, Semi-Annual Channel (core installation)';
    PRODUCT_ENTERPRISE_EVALUATION               : Edition:='Windows 10 Enterprise Evaluation';
    PRODUCT_ENTERPRISE_N_EVALUATION             : Edition:='Windows 10 Enterprise N Evaluation';
    PRODUCT_ENTERPRISE_S                        : Edition:='Windows 10 Enterprise 2015 LTSB';
    PRODUCT_ENTERPRISE_S_EVALUATION             : Edition:='Windows 10 Enterprise 2015 LTSB Evaluation';
    PRODUCT_ENTERPRISE_S_N                      : Edition:='Windows 10 Enterprise 2015 LTSB N';
    PRODUCT_ENTERPRISE_S_N_EVALUATION           : Edition:='Windows 10 Enterprise 2015 LTSB N Evaluation';
    PRODUCT_HOME_PREMIUM_SERVER                 : Edition:='Windows Home Server 2011';
    PRODUCT_HOME_SERVER                         : Edition:='Windows Storage Server 2008 R2 Essentials';
    PRODUCT_IOTENTERPRISE                       : Edition:='Windows IoT Enterprise';
    PRODUCT_IOTENTERPRISE_S                     : Edition:='Windows IoT Enterprise LTSC';
    PRODUCT_IOTUAP                              : Edition:='Windows 10 IoT Core';
    PRODUCT_IOTUAPCOMMERCIAL                    : Edition:='Windows 10 IoT Core Commercial';
    PRODUCT_MULTIPOINT_PREMIUM_SERVER           : Edition:='Windows MultiPoint Server Premium (full installation)';
    PRODUCT_MULTIPOINT_STANDARD_SERVER          : Edition:='Windows MultiPoint Server Standard (full installation)';
    PRODUCT_PRO_WORKSTATION                     : Edition:='Windows 10 Pro for Workstations';
    PRODUCT_PRO_WORKSTATION_N                   : Edition:='Windows 10 Pro for Workstations N';
    PRODUCT_STORAGE_ENTERPRISE_SERVER_CORE      : Edition:='Storage Server Enterprise (core installation)';
    PRODUCT_STORAGE_STANDARD_EVALUATION_SERVER  : Edition:='Storage Server Standard (evaluation installation)';
    PRODUCT_STORAGE_STANDARD_SERVER_CORE        : Edition:='Storage Server Standard (core installation)';
    PRODUCT_STORAGE_WORKGROUP_EVALUATION_SERVER : Edition:='Storage Server Workgroup (evaluation installation)';
    PRODUCT_STORAGE_WORKGROUP_SERVER_CORE       : Edition:='Storage Server Workgroup (core installation)';
    else                                          Edition:='';
  end;

  if Edition = '' then
  begin
    if OSVIX.wSuiteMask and VER_SUITE_EMBEDDEDNT <> 0 then
      Edition := 'Embedded';
    if OSVIX.wSuiteMask and VER_SUITE_BLADE <> 0 then
      Edition := Edition + ' Web Edition';
    if OSVIX.wSuiteMask and VER_SUITE_COMPUTE_SERVER <> 0 then
      Edition := Edition + ' Compute Cluster';
    if OSVIX.wSuiteMask and VER_SUITE_DATACENTER <> 0 then
      Edition := Edition + ' Datacenter';
    if (OSVIX.wSuiteMask and VER_SUITE_SMALLBUSINESS <> 0) or
       (OSVIX.wSuiteMask and VER_SUITE_SMALLBUSINESS_RESTRICTED <> 0) then
      Edition := Edition + ' Small Business';
    if OSVIX.wSuiteMask and VER_SUITE_STORAGE_SERVER <> 0 then
      Edition := Edition + ' Storage Server';
    if OSVIX.wSuiteMask and VER_SUITE_ENTERPRISE <> 0 then
      Edition := Edition + ' Enterprise';
    Edition := Trim(Edition);
  end;

  case Major of
    10 : if OSVIX.wProductType = VER_NT_WORKSTATION then
         begin
           if Build >= 22000 then
             Result := 'Windows 11'
           else
             Result := 'Windows 10';
         end else
         begin
           Result := 'Windows Server 2016';
           if Build >= 20000 then
             Result := 'Windows Server 2022'
           else
           if Build >= 17763 then
             Result := 'Windows Server 2019';
         end;
    6  : case Minor of
           0 : if (OSVIX.wProductType = VER_NT_WORKSTATION) or
                  (ProductType in [PRODUCT_BUSINESS, PRODUCT_BUSINESS_N]) then
                 Result := 'Windows Vista'
               else
                Result := 'Windows Server 2008';
           1 : if OSVIX.wProductType = VER_NT_WORKSTATION then
                 Result := 'Windows 7'
               else
                 Result := 'Windows Server 2008 R2';
           2 : if OSVIX.wProductType = VER_NT_WORKSTATION then
                 Result := 'Windows 8'
               else
                 Result := 'Windows Server 2012';
           3 : if OSVIX.wProductType = VER_NT_WORKSTATION then
                 Result := 'Windows 8.1'
               else
                 Result := 'Windows Server 2012 R2';
         end;
    5 : case Minor of
          0 : begin
                Result := 'Windows 2000';
                if OSVIX.wProductType = VER_NT_WORKSTATION then
                  Result := Result + ' Professional'
                else if (OSVIX.wSuiteMask and VER_SUITE_DATACENTER) = VER_SUITE_DATACENTER then
                  Result := Result + ' Datacenter Server'
                else if (OSVIX.wSuiteMask and VER_SUITE_ENTERPRISE) = VER_SUITE_ENTERPRISE then
                  Result := Result + ' Advanced Server'
                else
                  Result := Result + ' Server';
              end;
          1 : begin
                Result := 'Windows XP';
                if (OSVIX.wSuiteMask and VER_SUITE_PERSONAL) = VER_SUITE_PERSONAL then
                  Result := Result + ' Home'
                else
                  Result := Result + ' Professional';
                if (GetSystemMetrics(SM_STARTER) > 0) then
                  Result := Result + ' Starter'
                else if (GetSystemMetrics(SM_TABLETPC) > 0) then
                  Result := Result + ' Tablet PC'
                else if (GetSystemMetrics(SM_MEDIACENTER) > 0) then
                  Result := Result + ' Media Center';
              end;
          2 : begin
                if (OSVIX.wProductType = VER_NT_WORKSTATION) and
                   (TOSVersion.Architecture in [arIntelX64, arARM64]) then
                  Result := 'Windows XP Professional'
                else if (GetSystemMetrics(SM_SERVERR2) > 0) then
                  Result := 'Windows Server 2003 R2'
                else if (OSVIX.wSuiteMask and VER_SUITE_STORAGE_SERVER) = VER_SUITE_STORAGE_SERVER then
                  Result := 'Windows Storage Server 2003'
                else if (OSVIX.wSuiteMask and VER_SUITE_WH_SERVER) = VER_SUITE_WH_SERVER then
                  Result := 'Windows Home Server'
                else
                  Result := 'Windows Server 2003';
              end;
        end;
  end;

  if (Edition <> '') and (Pos(Edition, Result) = 0) then
    Result := Result + ' ' + Edition;

  if TOSVersion.Architecture in [arIntelX64, arARM64] then
    Result := Result + ' x64';

  Result := FormatOSName(Result);
end;

function TWindows.OpenRegistryReadOnly(ARoot : HKEY = HKEY_LOCAL_MACHINE) : TRegistry;
var
  KeyAccess : Cardinal;
begin
  KeyAccess := KEY_READ;
  if IsWow64 then
    KeyAccess := KeyAccess or KEY_WOW64_64KEY;
  Result := TRegistry.Create(KeyAccess);
  Result.RootKey := ARoot;
end;

function TWindows.IsWinPE : Boolean;
const
  rkWinPE = {HKEY_LOCAL_MACHINE\}'SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinPE';
begin
  Result := False;
  with OpenRegistryReadOnly do
    try
      Rootkey := HKEY_LOCAL_MACHINE;
      if OpenKey(rkWinPE, False) then
      begin
        Result := ValueExists('Version');
        CloseKey;
      end;
    finally
      Free;
    end;
end;

function TWindows.GetWinPEVersion : String;
const
  rkWinPE = {HKEY_LOCAL_MACHINE\}'SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinPE';
begin
  Result := '';
  with OpenRegistryReadOnly do
    try
      Rootkey := HKEY_LOCAL_MACHINE;
      if OpenKey(rkWinPE, False) then
      begin
        Result := ReadString('Version');
        CloseKey;
      end;
    finally
      Free;
    end;
end;

function TWindows.IsWindowsCompatibilityMode : Boolean;
var
  Major,
  Minor,
  Build : Cardinal;
begin
  Result := not SameText(GetTrueWindowsVersion(Major, Minor, Build),
                         Format('%d.%d.%d', [OSVIX.dwMajorVersion,
                                             OSVIX.dwMinorVersion,
                                             OSVIX.dwBuildNumber]));
end;

function TWindows.GetWindowsCompatibilityMode : String;
var
  CompatLayerEnv : String;
begin
  Result := '-';
  CompatLayerEnv := GetEnvironmentVariable('__COMPAT_LAYER');

  if SameText('WIN95', CompatLayerEnv) then
    Result := 'Windows 95' else
  if SameText('WIN98', CompatLayerEnv) then
    Result := 'Windows 98/ME' else
  if SameText('NT4SP5', CompatLayerEnv) then
    Result := 'Windows NT 4.0 SP5' else
  if SameText('WIN2000', CompatLayerEnv) then
    Result := 'Windows 2000' else
  if SameText('WINXPSP2', CompatLayerEnv) then
    Result := 'Windows XP SP2' else
  if SameText('WINXPSP3', CompatLayerEnv) then
    Result := 'Windows XP SP3' else
  if SameText('WINSRV03SP1', CompatLayerEnv) then
    Result := 'Windows Server 2003 SP1' else
  if SameText('WINSRV08SP1', CompatLayerEnv) then
    Result := 'Windows Server 2008 SP1' else
  if SameText('VISTARTM', CompatLayerEnv) then
    Result := 'Windows Vista' else
  if SameText('VISTASP1', CompatLayerEnv) then
    Result := 'Windows Vista SP1' else
  if SameText('VISTASP2', CompatLayerEnv) then
    Result := 'Windows Vista SP2' else
  if SameText('WIN7RTM', CompatLayerEnv) then
    Result := 'Windows 7' else
  if SameText('WIN8RTM', CompatLayerEnv) then
    Result := 'Windows 8';
end;

function TWindows.GetServicePack : String;
begin
  if OSVIX.wServicePackMajor > 0 then
    Result := IntToStr(OSVIX.wServicePackMajor) + '.' +
              IntToStr(OSVIX.wServicePackMinor)
  else
    Result := '-'
end;

function TWindows.GetWindowsCodename : String;
var
  Major, Minor,
  Build : Cardinal;
begin
  Result := '-';

  GetTrueWindowsVersion(Major, Minor, Build);
  if Build <> 0 then
    case Build of
      10240 : Result := 'RTM (Threshold 1, Version 1507)';
      10586 : Result := 'November Update (Threshold 2, Version 1511)';
      14393 : Result := 'Anniversary Update (Redstone 1, Version 1607)';
      15063 : Result := 'Creators Update (Redstone 2, Version 1703)';
      16299 : Result := 'Fall Creators Update (Redstone 3, Version 1709)';
      17134 : Result := 'April 2018 Update (Redstone 4, Version 1803)';
      17763 : Result := 'October 2018 Update (Redstone 5, Version 1809)';
      18362 : Result := 'May 2019 Update (Version 1903)';
      18363 : Result := 'November 2019 Update (Version 1909)';
      19041 : Result := 'May 2020 Update (Version 2004)';
      19042 : Result := 'October 2020 Update (Version 20H2)';
      19043 : Result := 'May 2021 Update (Version 21H1)';
      19044,
      22000 : Result := 'November 2021 Update (Version 21H2)';
      19045,
      22621 : Result := 'August 2022 Update (Version 22H2)';
    end;
end;

function TWindows.DetectInstalledSoftware : TInstallData;
const
  RKeyRoot : Array [0..1] of String = ('SOFTWARE','SOFTWARE\Wow6432Node');
  RKey0 = '\%s\Microsoft\Windows\CurrentVersion\Uninstall';
  RKey1 = '\%s\Microsoft\Windows\CurrentVersion\Installer\UserData';
  RKey2 = '\%s\Microsoft\Active Setup\Installed Components';
  rvDN = 'DisplayName';
  rvDV = 'DisplayVersion';
  rvUS = 'UninstallString';
  rvCompany = 'Publisher';
  rvKFN = 'KeyFileName';
  rvVer = 'Version';
  rkAP = '\%s\Microsoft\Windows\CurrentVersion\App Paths\';
var
  KeyCount,
  KeyCount2,
  RKCount
  {$IFDEF WIN32}, x64{$ENDIF} : Integer;
  RKey, Str : String;
  StringList,
  KeyList : TStringList;
  Reg : TRegistry;
  IR : TInstallRecord;

  procedure AddEntry(AEntry : TInstallRecord);
  var
    EntryCnt, Idx : Integer;
  begin
    Idx := -1;
    for EntryCnt := 0 to High(Result) do
      if SameText(Result[EntryCnt].Name, AEntry.Name) then
      begin
        Idx := EntryCnt;
        Break;
      end;
    if Idx = -1 then
    begin
      SetLength(Result, Length(Result) + 1);
      Idx := High(Result);
    end;
    if Result[Idx].Name = '' then
      Result[Idx] := AEntry;
  end;

  function ReadEntry(var AEntry : TInstallRecord) : Boolean;
  begin
    if Reg.ValueExists('SystemComponent') and
       (Reg.GetDataType('SystemComponent') = rdInteger) then
      AEntry.HideFromControlPanel := Reg.ReadInteger('SystemComponent') = 1;

    if Reg.ValueExists(rvDN) then
    begin
      AEntry.Name := Reg.ReadString(rvDN);

      if Reg.ValueExists(rvDV) and
         (Reg.GetDataType(rvDV) = rdString) then
        AEntry.Version := Reg.ReadString(rvDV);

      if Reg.ValueExists(rvCompany) and
         (Reg.GetDataType(rvCompany) = rdString) then
        AEntry.Company := Reg.ReadString(rvCompany);

      if Reg.ValueExists(rvUS) and
         (Reg.GetDataType(rvUS) = rdString) then
        AEntry.Uninstall := Reg.ReadString(rvUS);
    end;
    Result := (AEntry.Name <> '');
  end;

begin
  StringList := TStringList.Create;
  KeyList := TStringList.Create;
  try
    {$IFDEF WIN64}
    for RKCount := 0 to 1 do
    begin
      Reg := TRegistry.Create(KEY_READ);
      RKey := Format(RKey0, [RKeyRoot[RKCount]]);
    {$ELSE}
    if not IsWow64 then
      x64 := 0
    else
      x64 := 1;
    for RKCount := 0 to x64 do
    begin
      RKey := Format(RKey0, [RKeyRoot[0]]);
      if RKCount = 0 then
        Reg := TRegistry.Create(KEY_READ)
      else
        Reg := TRegistry.Create(KEY_READ or KEY_WOW64_64KEY);
    {$ENDIF}

      try
        Reg.RootKey := HKEY_LOCAL_MACHINE;
        if Reg.OpenKey(RKey, False) then
        begin
          Reg.GetKeyNames(StringList);
          Reg.CloseKey;
          for KeyCount := 0 to StringList.Count - 1 do
            if Reg.OpenKey(RKey + '\' + StringList[KeyCount], False) then
            begin
              ResetMemory(IR, SizeOf(IR));
              if ReadEntry(IR) then
                AddEntry(IR);
              Reg.CloseKey;
            end;
        end;

        {$IFDEF WIN64}
        RKey := Format(RKey1, [RKeyRoot[RKCount]]);
        {$ELSE}
        RKey := Format(RKey1, [RKeyRoot[0]]);
        {$ENDIF}
        if Reg.OpenKey(RKey, False) then
        begin
          StringList.Clear;
          Reg.GetKeyNames(StringList);
          Reg.CloseKey;
          for KeyCount := 0 to StringList.Count - 1 do
            if Reg.OpenKey(Format('%s\%s\Products', [RKey, StringList[KeyCount]]), False) then
            begin
              KeyList.Clear;
              Reg.GetKeyNames(KeyList);
              Reg.CloseKey;
              for KeyCount2 := 0 to KeyList.Count - 1 do
                if Reg.OpenKey(Format('%s\%s\Products\%s\InstallProperties',
                  [RKey, StringList[KeyCount], KeyList[KeyCount2]]), False) then
                begin
                  ResetMemory(IR, SizeOf(IR));
                  if ReadEntry(IR) then
                    AddEntry(IR);
                  Reg.CloseKey;
                end;
            end;
        end;

        {$IFDEF WIN64}
        RKey := Format(RKey2, [RKeyRoot[RKCount]]);
        {$ELSE}
        RKey := Format(RKey2, [RKeyRoot[0]]);
        {$ENDIF}
        if Reg.OpenKey(RKey, False) then
        begin
          StringList.Clear;
          Reg.GetKeyNames(StringList);
          Reg.CloseKey;
          for KeyCount := 0 to StringList.Count - 1 do
            if Reg.OpenKey(Format('%s\%s', [RKey, StringList[KeyCount]]), False) then
            begin
              if Reg.ValueExists('') then
              begin
                ResetMemory(IR, SizeOf(IR));
                IR.HideFromControlPanel := True;
                IR.Name := Reg.ReadString('');
                if Reg.ValueExists(rvVer) and
                   (Reg.GetDataType(rvVer) = rdString) then
                  IR.Version := Reg.ReadString(rvVer);
                if Reg.ValueExists(rvKFN) and
                   (Reg.GetDataType(rvKFN) = rdString) then
                  IR.Uninstall := Reg.ReadString(rvKFN);
                if IR.Name = '' then
                  Continue;
                AddEntry(IR);
              end;
              Reg.CloseKey;
            end;
        end;

        {$IFDEF WIN64}
        RKey := Format(RKey0, [RKeyRoot[RKCount]]);
        {$ELSE}
        RKey := Format(RKey0, [RKeyRoot[0]]);
        {$ENDIF}
        Reg.RootKey := HKEY_CURRENT_USER;
        Str := RKey;
        if Reg.OpenKey(Str, False) then
        begin
          StringList.Clear;
          Reg.GetKeyNames(StringList);
          Reg.CloseKey;
          for KeyCount := 0 to StringList.Count - 1 do
            if Reg.OpenKey(Str + '\' + StringList[KeyCount], False) then
            begin
              ResetMemory(IR, SizeOf(IR));
              if ReadEntry(IR) then
                AddEntry(IR);
              Reg.CloseKey;
            end;
        end;
      finally
        Reg.Free;
      end;
    end;
  finally
    StringList.Free;
    KeyList.Free;
  end;
end;

function TWindows.GetWindowsDirectories : TStringList;

  function GetSpecialFolder(Handle : Hwnd; nFolder : Integer) : String;
  var
    PIDL : PItemIDList;
    Path : PWideChar;
    Malloc : IMalloc;
  begin
    Result := '';
    Path := StrAlloc(MAX_PATH);
    if SHGetSpecialFolderLocation(Handle, nFolder, PIDL) = S_OK then
    begin
      if SHGetPathFromIDList(PIDL, Path) then
        Result := Path;
    end;
    StrDispose(Path);

    if Succeeded(SHGetMalloc(Malloc)) then
      Malloc.Free(PIDL);
  end;

var
  DWHandle : HWND;

begin
  Result := TStringList.Create;
  DWHandle := GetDesktopWindow;

  Result.Add('AdminTools=' + GetSpecialFolder(DWHandle, CSIDL_ADMINTOOLS));
  Result.Add('AltStartup=' + GetSpecialFolder(DWHandle, CSIDL_ALTSTARTUP));
  Result.Add('AppData=' + GetSpecialFolder(DWHandle, CSIDL_APPDATA));
  Result.Add('CDBurnArea=' + GetSpecialFolder(DWHandle, CSIDL_CDBURN_AREA));
  Result.Add('CommonAdminTools=' + GetSpecialFolder(DWHandle, CSIDL_COMMON_ADMINTOOLS));
  Result.Add('CommonDesktopDir=' + GetSpecialFolder(DWHandle, CSIDL_COMMON_DESKTOPDIRECTORY));
  Result.Add('CommonAltStartUp=' + GetSpecialFolder(DWHandle, CSIDL_COMMON_ALTSTARTUP));
  Result.Add('CommonAppData=' + GetSpecialFolder(DWHandle, CSIDL_COMMON_APPDATA));
  Result.Add('CommonDocuments=' + GetSpecialFolder(DWHandle, CSIDL_COMMON_DOCUMENTS));
  Result.Add('CommonFavorites=' + GetSpecialFolder(DWHandle, CSIDL_COMMON_FAVORITES));
  Result.Add('CommonMusic=' + GetSpecialFolder(DWHandle, CSIDL_COMMON_MUSIC));
  Result.Add('CommonPictures=' + GetSpecialFolder(DWHandle, CSIDL_COMMON_PICTURES));
  Result.Add('CommonStartMenu=' + GetSpecialFolder(DWHandle, CSIDL_COMMON_STARTMENU));
  Result.Add('CommonStartup=' + GetSpecialFolder(DWHandle, CSIDL_COMMON_STARTUP));
  Result.Add('CommonTemplates=' + GetSpecialFolder(DWHandle, CSIDL_COMMON_TEMPLATES));
  Result.Add('CommonVideo=' + GetSpecialFolder(DWHandle, CSIDL_COMMON_VIDEO));
  Result.Add('Cookies=' + GetSpecialFolder(DWHandle, CSIDL_COOKIES));
  Result.Add('Controls=' + GetSpecialFolder(DWHandle, CSIDL_CONTROLS));
  Result.Add('Desktop=' + GetSpecialFolder(DWHandle, CSIDL_DESKTOP));
  Result.Add('DesktopDir=' + GetSpecialFolder(DWHandle, CSIDL_DESKTOPDIRECTORY));
  Result.Add('Favorites=' + GetSpecialFolder(DWHandle, CSIDL_FAVORITES));
  Result.Add('Drives=' + GetSpecialFolder(DWHandle, CSIDL_DRIVES));
  Result.Add('Fonts=' + GetSpecialFolder(DWHandle, CSIDL_FONTS));
  Result.Add('History=' + GetSpecialFolder(DWHandle, CSIDL_HISTORY));
  Result.Add('Internet=' + GetSpecialFolder(DWHandle, CSIDL_INTERNET));
  Result.Add('InternetCache=' + GetSpecialFolder(DWHandle, CSIDL_INTERNET_CACHE));
  Result.Add('LocalAppData=' + GetSpecialFolder(DWHandle, CSIDL_LOCAL_APPDATA));
  Result.Add('NetWork=' + GetSpecialFolder(DWHandle, CSIDL_NETWORK));
  Result.Add('NetHood=' + GetSpecialFolder(DWHandle, CSIDL_NETHOOD));
  Result.Add('MyDocuments=' + GetSpecialFolder(DWHandle, CSIDL_PERSONAL));
  Result.Add('MyMusic=' + GetSpecialFolder(DWHandle, CSIDL_MYMUSIC));
  Result.Add('MyPictures=' + GetSpecialFolder(DWHandle, CSIDL_MYPICTURES));
  Result.Add('MyVideo=' + GetSpecialFolder(DWHandle, CSIDL_MYVIDEO));
  Result.Add('Personal=' + GetSpecialFolder(DWHandle, CSIDL_PERSONAL));
  Result.Add('PrintHood=' + GetSpecialFolder(DWHandle, CSIDL_PRINTHOOD));
  Result.Add('Printers=' + GetSpecialFolder(DWHandle, CSIDL_PRINTERS));
  Result.Add('Programs=' + GetSpecialFolder(DWHandle, CSIDL_PROGRAMS));
  Result.Add('Profile=' + GetSpecialFolder(DWHandle, CSIDL_PROFILE));
  Result.Add('ProgramFiles=' + GetSpecialFolder(DWHandle, CSIDL_PROGRAM_FILES));
  Result.Add('ProgramFilesCommon=' + GetSpecialFolder(DWHandle, CSIDL_PROGRAM_FILES_COMMON));
  Result.Add('RecycleBin=' + GetSpecialFolder(DWHandle, CSIDL_BITBUCKET));
  Result.Add('Recent=' + GetSpecialFolder(DWHandle, CSIDL_RECENT));
  Result.Add('SendTo=' + GetSpecialFolder(DWHandle, CSIDL_SENDTO));
  Result.Add('StartMenu=' + GetSpecialFolder(DWHandle, CSIDL_STARTMENU));
  Result.Add('StartUp=' + GetSpecialFolder(DWHandle, CSIDL_STARTUP));
  Result.Add('System=' + GetSpecialFolder(DWHandle, CSIDL_SYSTEM));
  Result.Add('Windows=' + GetSpecialFolder(DWHandle, CSIDL_WINDOWS));
  Result.Add('Templates=' + GetSpecialFolder(DWHandle, CSIDL_TEMPLATES));
end;

procedure TWindows.GetEnvironmentVariables(EnvList : TStrings);
var
  EnvCount : Cardinal;
  EnvBlock : PChar;
  EnvString : String;
begin
  EnvList.Clear;
  EnvBlock := GetEnvironmentStrings;
  EnvCount := 0;
  EnvString := '';
  while (EnvBlock[EnvCount] <> #0) or (EnvBlock[EnvCount - 1] <> #0) do
  begin
    if EnvBlock[EnvCount] <> #0 then
      EnvString := EnvString + EnvBlock[EnvCount]
    else
    begin
      if EnvString = '' then
        Break;
      if Pos('=', EnvString) <> 1 then
        EnvList.Add(Trim(EnvString));
      EnvString := '';
    end;
    Inc(EnvCount);
  end;
  FreeEnvironmentStrings(EnvBlock);
end;

function TWindows.GetNameFromStr(ASource : String; ASep : String = '=') : String;
var
  Position : Integer;
begin
  Position := Pos(ASep, ASource);
  if Position > 0 then
    Result := Trim(Copy(ASource, 1, Position - 1))
  else
    Result := ASource;
end;

function TWindows.GetValueFromStr(ASource : String; ASep : String = '=') : String;
var
  Position : Integer;
begin
  Position := Pos(ASep, ASource);
  if Position > 0 then
    Result := Copy(ASource, Position + Length(ASep), 1024)
  else
    Result := '';
end;

procedure TWindows.ResetMemory(out P; Size : Longint);
begin
  if Size > 0 then
  begin
    Byte(P) := 0;
    FillChar(P, Size, 0);
  end;
end;

function TWindows.StripSpaces(ASource: string): string;
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

end.
