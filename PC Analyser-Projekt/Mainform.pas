{$WARN SYMBOL_PLATFORM OFF}

unit Mainform;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.WinSvc,
  System.SysUtils, System.Variants, System.Classes,
  System.UITypes, System.Timespan,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls,
  SystemAccess, ProcessorCacheAndFeatures,
  ProcessorDB, ProcessorMSR,
  SMBIOSClass, SMBIOSStructures;

type
  TPCAnalyserForm = class(TForm)
    ProgramControlGroupBox: TGroupBox;
    ProgramContextGroupBox: TGroupBox;
    ProgramInfoGroupBox: TGroupBox;
    KernelModeDriverGroupBox: TGroupBox;
    SystemAccessGroupBox: TGroupBox;
    ProgramLogGroupBox: TGroupBox;
    LogMemo: TMemo;
    CategoryTreeView: TTreeView;
    Splitter: TSplitter;
    ResultsListView: TListView;
    NameStaticText: TStaticText;
    TargetCompilationStaticText: TStaticText;
    TargetOperatingSystemStaticText: TStaticText;
    NameStaticTextResult: TStaticText;
    TargetCompilationStaticTextResult: TStaticText;
    TargetOperatingSystemStaticTextResult: TStaticText;
    CurrentUserStaticText: TStaticText;
    CurrentUserStaticTextResult: TStaticText;
    UserRightsStaticText: TStaticText;
    UserRightsStaticTextResult: TStaticText;
    DriverNameStaticText: TStaticText;
    LoadDriverButton: TButton;
    UnloadDriverButton: TButton;
    DriverDetailsStaticText: TStaticText;
    DriverNameStaticTextResult: TStaticText;
    DriverDetailsStaticTextResult: TStaticText;
    ElevateAdminRightsButton: TButton;
    UserContextStaticText: TStaticText;
    UserContextStaticTextResult: TStaticText;
    DisableTestModeButton: TButton;
    EnableTestModeButton: TButton;
    KernelModeDriver: TTimer;
    KernelModeDriverOpenDialog: TOpenDialog;
    procedure CategoryTreeViewChange(Sender: TObject; Node: TTreeNode);
    procedure FormCreate(Sender: TObject);
    procedure ElevateAdminRightsButtonClick(Sender: TObject);
    procedure CheckKernelDriverButtonState;
    procedure EnableTestModeButtonClick(Sender: TObject);
    procedure DisableTestModeButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure KernelModeDriverTimer(Sender: TObject);
    procedure LoadDriverButtonClick(Sender: TObject);
    procedure UnloadDriverButtonClick(Sender: TObject);
    procedure CreateCategoryTree;
    procedure DisplayNodeInfo;
    procedure DisplayMachineInfo;
    procedure DisplayWindowsDetails;
    procedure DisplaySoftwareInstalled;
    procedure DisplayWindowsDirectories;
    procedure DisplayEnvVariables;

    procedure CreateWindowsTree(ARoot: TTreeNode);
    procedure CreateProcessorTree(ARoot: TTreeNode);
    procedure CreateSMBIOSTree(ARoot: TTreeNode);
    procedure CreatePCIBusTree(ARoot: TTreeNode);
    procedure CreateSMBusTree(ARoot: TTreeNode);

    procedure DisplaySMBIOSInfo;

    procedure DisplayCPUDetail(AIndex: Integer);
    procedure DisplayCPUCache(AIndex: Integer);
    procedure DisplayCPUFeatures(AIndex: Integer);
    procedure DisplayCPUMSR(AIndex: Integer);
    procedure DisplaySMBIOSStructureDetails(AStructNum : Byte);

    procedure DisplayPCIDevices;
    procedure DisplayPCIDevice(AIndex: Integer);

    procedure DisplaySMBus_MemoryDevices;
    procedure DisplaySMBus_MemoryDevice(AIndex: Integer);
  private
    SystemAccessClass : TSystemAccess;
    procedure WMSysCommand(var Message: TWMSysCommand); message WM_SYSCOMMAND;
    function Join(const LoWord, HiWord : Word) : Integer;
    function FormatSeconds(AValue : Int64; AShort : Boolean = True) : String;
  public
    procedure AddLog(AStr : String; CreateNewLine : Boolean);
  end;

  TCategory = (CatMachine,

               CatWindows, CatWindowsDetails, CatWindowsSoftware, CatWindowsDirectories, CatWindowsEnvVariables,

               CatSMBIOS, CatSMBIOS_BIOS, CatSMBIOS_SystemInfo, CatSMBIOS_Mainboard, CatSMBIOS_Chassis,
               CatSMBIOS_Processors, CatSMBIOS_Caches, CatSMBIOS_Ports, CatSMBIOS_Slots,
               CatSMBIOS_MemoryController, CatSMBIOS_MemoryModules, CatSMBIOS_VoltageSensor,
               CatSMBIOS_CoolingSensor, CatSMBIOS_TemperatureSensor, CatSMBIOS_CurrentSensor,
               CatSMBIOS_TPMDevice,

               CatProcessor, CatProcessorDetails, CatCPUCache, CatProcessorFeatures, CatProcessorMSR,

               CatPCIBus, CatPCIDevice,

               CatSMBus, CatSMBus_MemoryDevice);

var
  PCAnalyserForm: TPCAnalyserForm;

implementation

{$R *.dfm}

uses
  SystemDefinitions;

const
  {$IFDEF WIN64}
  ProgramName = 'PC Analyser x64';
  {$ELSE}
  ProgramName = 'PC Analyser x86';
  {$ENDIF}
  ProgramVersion = '1.0';
  ProgramCopyright = 'Copyright © 2023 Devid Espenschied';

procedure TPCAnalyserForm.ElevateAdminRightsButtonClick(Sender: TObject);
begin
  if SystemAccessClass.RunAsAdmin(Handle, Application.ExeName, '') then
    Close;
end;

procedure TPCAnalyserForm.EnableTestModeButtonClick(Sender: TObject);
var CallStrMain,
    CallStrParameters,
    SystemRootEnv : String;
    CallRes : Integer;
begin
  SystemRootEnv := IncludeTrailingPathDelimiter(GetEnvironmentVariable('SYSTEMROOT'));
  if (SystemRootEnv <> '') and
     (SystemAccessClass.FileExistsExt(SystemRootEnv + 'system32\bcdedit.exe')) then
  begin
    CallStrMain := SystemRootEnv + 'system32\bcdedit.exe';
    if (TOSVersion.Architecture in [arIntelX64, arARM64]) and
       (SystemAccessClass.IsProcess32OnWin64(GetCurrentProcess)) then
      CallStrMain := StringReplace(CallStrMain, '\system32\', '\Sysnative\', [rfIgnoreCase]);

    CallStrParameters := '/set testsigning on';
    CallRes := SystemAccessClass.ShellExecuteAndWaitW(Application.Handle, 'open', PWideChar(CallStrMain),
                                 PWideChar(CallStrParameters), nil, SW_SHOWMAXIMIZED{SW_HIDE}, True);
    if CallRes <= 32 then
      ShowMessage('Es ist ein Fehler aufgetreten (Code ' + IntToStr(CallRes) + ' - ' + SysErrorMessage(CallRes) + ').')
    else
    begin
      if MessageDlg('Die Operation scheint erfolgreich durchgeführt worden zu sein. '+
                    'Ein Neustart ist notwendig, um die Änderungen wirksam werden zu lassen. '+
                    'Soll jetzt neu gestartet werden?', mtConfirmation, [mbYes, mbNo],0) = mrYes then
        if not SystemAccessClass.WindowsExit(EWX_REBOOT) then
          ShowMessage('Der Neustart konnte nicht durchgeführt werden. '+
                      'Bitte starten Sie manuell neu.');
    end;

    CheckKernelDriverButtonState;
  end
  else
    ShowMessage('Der Testmodus kann nicht aktiviert werden, da BCDEDIT nicht gefunden wurde.');
end;

procedure TPCAnalyserForm.DisableTestModeButtonClick(Sender: TObject);
var CallStrMain,
    CallStrParameters,
    SystemRootEnv : String;
    CallRes : Integer;
begin
  SystemRootEnv := IncludeTrailingPathDelimiter(GetEnvironmentVariable('SYSTEMROOT'));
  if (SystemRootEnv <> '') and
     (SystemAccessClass.FileExistsExt(SystemRootEnv + 'system32\bcdedit.exe')) then
  begin
    CallStrMain := SystemRootEnv + 'system32\bcdedit.exe';
    if (TOSVersion.Architecture in [arIntelX64, arARM64]) and
       (SystemAccessClass.IsProcess32OnWin64(GetCurrentProcess)) then
      CallStrMain := StringReplace(CallStrMain, '\system32\', '\Sysnative\', [rfIgnoreCase]);

    CallStrParameters := '/set testsigning off';
    CallRes := SystemAccessClass.ShellExecuteAndWaitW(Application.Handle, 'open', PWideChar(CallStrMain),
                                 PWideChar(CallStrParameters), nil, SW_SHOWMAXIMIZED{SW_HIDE}, True);
    if CallRes <= 32 then
      ShowMessage('Es ist ein Fehler aufgetreten (Code ' + IntToStr(CallRes) + ' - ' + SysErrorMessage(CallRes) + ').')
    else
    begin
      if MessageDlg('Die Operation scheint erfolgreich durchgeführt worden zu sein. '+
                    'Ein Neustart ist notwendig, um die Änderungen wirksam werden zu lassen. '+
                    'Soll jetzt neu gestartet werden?', mtConfirmation, [mbYes, mbNo],0) = mrYes then
        if not SystemAccessClass.WindowsExit(EWX_REBOOT) then
          ShowMessage('Der Neustart konnte nicht durchgeführt werden. '+
                      'Bitte starten Sie manuell neu.');
    end;

    CheckKernelDriverButtonState;
  end
  else
    ShowMessage('Der Testmodus kann nicht deaktiviert werden, da BCDEDIT nicht gefunden wurde.');
end;

procedure TPCAnalyserForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  //Klasseninstanz für Systemzugriffsklasse auflösen
  SystemAccessClass.Free;
end;

procedure TPCAnalyserForm.FormCreate(Sender: TObject);
var
  WindowsCompatibilityMode : String;
begin
  //Systemmenü erweitern um Copyright-Meldung
  AppendMenu(GetSystemMenu(Handle, False), MF_STRING, $1234, '&Copyright...');

  //Formular-Bezeichnung setzen
  Caption := ProgramName + ' V' + ProgramVersion;

  //LogMemo leeren
  LogMemo.Clear;

  //Systemzugriffsklasse erstellen
  SystemAccessClass := TSystemAccess.Create;

  //Privileg "SeSystemEnvironmentPrivilege" hinzufügen, um später mit der
  //Klassenfunktion "IsUEFISecureBoot" den UEFI SecureBoot-Status abzufragen
  SystemAccessClass.EnablePrivilege(SE_SYSTEM_ENVIRONMENT_NAME);

  //Programminfos ermitteln
  NameStaticTextResult.Caption := ProgramName + ' V' + ProgramVersion;;
  {$IFDEF WIN64}
  TargetCompilationStaticTextResult.Caption := 'Windows 64 Bit';
  {$ELSE}
  TargetCompilationStaticTextResult.Caption := 'Windows 32 Bit';
  {$ENDIF}
  if TOSVersion.Architecture in [arIntelX64, arARM64] then
    TargetOperatingSystemStaticTextResult.Caption := 'Windows 64 Bit'
  else
    TargetOperatingSystemStaticTextResult.Caption := 'Windows 32 Bit';

  //Programmkontext ermitteln
  CurrentUserStaticTextResult.Caption := SystemAccessClass.GetCurrentUserName;
  if SystemAccessClass.IsAdmin then
    UserRightsStaticTextResult.Caption := 'Administrator'
  else
    UserRightsStaticTextResult.Caption := 'Standardbenutzer';
  if SystemAccessClass.IsElevated then
    UserContextStaticTextResult.Caption := 'Erweiterter Kontext'
  else
    UserContextStaticTextResult.Caption := 'Eingeschränkter Kontext';
  ElevateAdminRightsButton.Enabled :=
    (not SystemAccessClass.IsElevated) or (not SystemAccessClass.IsAdmin);

  //Kernelmodus-Treiber Details und Schalterstatus ermitteln
  //Diese Aufgabe wird per Timer in regelmäßigen Abständen geprüft
  //und daher hier einmalig manuell aufgerufen
  KernelModeDriverTimer(Sender);

  AddLog('Ausgabelog für ' + ProgramName + ' V' + ProgramVersion, True);
  AddLog(ProgramCopyright, True);
  AddLog('', True);

  //Zusätzliche Systemdetails ins Log schreiben
  if TOSVersion.Architecture in [arIntelX64, arARM64] then
  begin
    if SystemAccessClass.IsSystemCodeIntegrityEnabled then
      AddLog('- Erzwingen der Treibersignatur: aktiv', True)
    else
      AddLog('- Erzwingen der Treibersignatur: inaktiv', True);
    if SystemAccessClass.IsTestSigningModeEnabled then
      AddLog('- Windows-Testmodus: aktiv', True)
    else
      AddLog('- Windows-Testmodus: inaktiv', True);
    if SystemAccessClass.IsUEFISecureBoot then
    begin
      AddLog('- UEFI SecureBoot: aktiv (dadurch Windows-Testmodus nicht aktivierbar)', True);
      AddLog('- WARNUNG: durch UEFI SecureBoot ist der Windows-Testmodus oben rechts nicht aktivierbar', True);
    end
    else
      AddLog('- UEFI SecureBoot: inaktiv', True);
    AddLog('', True);
  end;

  WindowsCompatibilityMode := SystemAccessClass.WindowsClass.GetWindowsCompatibilityMode;
  if WindowsCompatibilityMode = '-' then
    AddLog('- Windows-Kompatibilitätsmodus: inaktiv', True)
  else
    AddLog('- Windows-Kompatibilitätsmodus: aktiv mit ' + WindowsCompatibilityMode, True);

  CreateCategoryTree;
end;

procedure TPCAnalyserForm.CreateCategoryTree;
var
  Root : TTreeNode;
  PInt : PInteger;
begin
  Root := nil;
  with CategoryTreeView, Items do
  begin
    BeginUpdate;
    try
      Clear;

      New(PInt);
      PInt^ := Join(0, Word(CatMachine));
      if SystemAccessClass.GetCurrentComputerName = '' then
        Root := AddObject(nil, 'Computer', PInt)
      else
        Root := AddObject(nil, SystemAccessClass.GetCurrentComputerName, PInt);

      Screen.Cursor := crHourGlass;
      CreateWindowsTree(Root);
      CreateSMBIOSTree(Root);
      CreateProcessorTree(Root);
      CreatePCIBusTree(Root);
      CreateSMBusTree(Root);
      Screen.Cursor := crDefault;
    finally
      EndUpdate;
      Root.Expand(False);
      CategoryTreeView.Selected := CategoryTreeView.Items.GetFirstNode;
      CategoryTreeView.OnChange(CategoryTreeView, CategoryTreeView.Selected);
    end;
  end;
end;

procedure TPCAnalyserForm.CreateWindowsTree(ARoot: TTreeNode);
var
  Node : TTreeNode;
  PInt : PInteger;
begin
  with CategoryTreeView, Items do
  begin
    New(PInt);
    PInt^ := Join(0, Word(CatWindows));
    Node := AddChildObject(ARoot, 'Windows', PInt);

    New(PInt);
    PInt^ := Join(1, Word(CatWindowsDetails));
    AddChildObject(Node, 'Windows-Details', PInt);

    New(PInt);
    PInt^ := Join(2, Word(CatWindowsSoftware));
    AddChildObject(Node, 'Installierte Software', PInt);

    New(PInt);
    PInt^ := Join(2, Word(CatWindowsDirectories));
    AddChildObject(Node, 'Verzeichnisse', PInt);

    New(PInt);
    PInt^ := Join(2, Word(CatWindowsEnvVariables));
    AddChildObject(Node, 'Umgebungsvariablen', PInt);
  end;
end;

procedure TPCAnalyserForm.CreateProcessorTree(ARoot: TTreeNode);
var
  Node,
  ProcessorNode : TTreeNode;
  PInt : PInteger;
  Counter,
  CPUCount : Integer;
begin
  with CategoryTreeView, Items do
  begin
    New(PInt);
    PInt^ := Join(0, Word(CatProcessor));
    Node := AddChildObject(ARoot,'Prozessor(en)', PInt);

    CPUCount := SystemAccessClass.ProcessorClass.GetCPUPhysicalCount;
    for Counter := 0 to CPUCount  - 1 do
    begin
      New(PInt);
      PInt^ := Join(Counter + 1, Word(CatProcessorDetails));
      ProcessorNode := AddChildObject(Node, 'Prozessor ' + IntToStr(Counter + 1), PInt);

      New(PInt);
      PInt^ := Join(Counter + 1, Word(CatCPUCache));
      AddChildObject(ProcessorNode, 'Cache', PInt);

      New(PInt);
      PInt^ := Join(Counter + 1, Word(CatProcessorFeatures));
      AddChildObject(ProcessorNode, 'Fähigkeiten', PInt);

      New(PInt);
      PInt^ := Join(Counter + 1, Word(CatProcessorMSR));
      AddChildObject(ProcessorNode, 'MSR', PInt);
    end;
  end;
end;

procedure TPCAnalyserForm.CreateSMBIOSTree(ARoot: TTreeNode);
var
  Node : TTreeNode;
  PInt: PInteger;
begin
  if SystemAccessClass.SMBIOSClass.LoadFromSystem then
  with CategoryTreeView, Items do
  begin
    New(PInt);
    PInt^ := Join(0, Word(CatSMBIOS));
    Node := AddChildObject(ARoot,'Hauptplatine SMBIOS', PInt);

    if SystemAccessClass.SMBIOSClass.IsTableAvailable(SMB_BIOSINFO) then
    begin
      New(PInt);
      PInt^ := Join(0, Word(CatSMBIOS_BIOS));
      AddChildObject(Node, 'BIOS-Details', PInt);
    end;

    if SystemAccessClass.SMBIOSClass.IsTableAvailable(SMB_SYSINFO) then
    begin
      New(PInt);
      PInt^ := Join(0, Word(CatSMBIOS_SystemInfo));
      AddChildObject(Node, 'System-Identifikation', PInt);
    end;

    if SystemAccessClass.SMBIOSClass.IsTableAvailable(SMB_BASEINFO) then
    begin
      New(PInt);
      PInt^ := Join(0, Word(CatSMBIOS_Mainboard));
      AddChildObject(Node, 'Hauptplatine', PInt);
    end;

    if SystemAccessClass.SMBIOSClass.IsTableAvailable(SMB_SYSENC) then
    begin
      New(PInt);
      PInt^ := Join(0, Word(CatSMBIOS_Chassis));
      AddChildObject(Node, 'Gehäuse/Chassis', PInt);
    end;

    if SystemAccessClass.SMBIOSClass.IsTableAvailable(SMB_CPU) then
    begin
      New(PInt);
      PInt^ := Join(0, Word(CatSMBIOS_Processors));
      AddChildObject(Node, 'Prozessor(en)', PInt);
    end;

    if SystemAccessClass.SMBIOSClass.IsTableAvailable(SMB_CACHE) then
    begin
      New(PInt);
      PInt^ := Join(0, Word(CatSMBIOS_Caches));
      AddChildObject(Node, 'Prozessor-Caches', PInt);
    end;

    if SystemAccessClass.SMBIOSClass.IsTableAvailable(SMB_PORTCON) then
    begin
      New(PInt);
      PInt^ := Join(0, Word(CatSMBIOS_Ports));
      AddChildObject(Node, 'Anschlüsse', PInt);
    end;

    if SystemAccessClass.SMBIOSClass.IsTableAvailable(SMB_SLOTS) then
    begin
      New(PInt);
      PInt^ := Join(0, Word(CatSMBIOS_Slots));
      AddChildObject(Node, 'Steckplätze', PInt);
    end;

    if SystemAccessClass.SMBIOSClass.IsTableAvailable(SMB_PHYSMEM) then
    begin
      New(PInt);
      PInt^ := Join(0, Word(CatSMBIOS_MemoryController));
      AddChildObject(Node, 'Speicher-Überblick', PInt);
    end;

    if SystemAccessClass.SMBIOSClass.IsTableAvailable(SMB_MEMDEV) then
    begin
      New(PInt);
      PInt^ := Join(0, Word(CatSMBIOS_MemoryModules));
      AddChildObject(Node, 'Speichermodul(e)', PInt);
    end;

    if SystemAccessClass.SMBIOSClass.IsTableAvailable(SMB_VOLTAGE) then
    begin
      New(PInt);
      PInt^ := Join(0, Word(CatSMBIOS_VoltageSensor));
      AddChildObject(Node, 'Spannungssensoren', PInt);
    end;

    if SystemAccessClass.SMBIOSClass.IsTableAvailable(SMB_COOL) then
    begin
      New(PInt);
      PInt^ := Join(0, Word(CatSMBIOS_CoolingSensor));
      AddChildObject(Node, 'Kühlungssensoren', PInt);
    end;

    if SystemAccessClass.SMBIOSClass.IsTableAvailable(SMB_TEMP) then
    begin
      New(PInt);
      PInt^ := Join(0, Word(CatSMBIOS_TemperatureSensor));
      AddChildObject(Node, 'Temperatursensoren', PInt);
    end;

    if SystemAccessClass.SMBIOSClass.IsTableAvailable(SMB_CURRENT) then
    begin
      New(PInt);
      PInt^ := Join(0, Word(CatSMBIOS_CurrentSensor));
      AddChildObject(Node, 'Stromstärkesensoren', PInt);
    end;

    if SystemAccessClass.SMBIOSClass.IsTableAvailable(SMB_TPMDEV) then
    begin
      New(PInt);
      PInt^ := Join(0, Word(CatSMBIOS_TPMDevice));
      AddChildObject(Node, 'TPM-Geräte', PInt);
    end;
  end;
end;

procedure TPCAnalyserForm.CreatePCIBusTree(ARoot: TTreeNode);
var
  Node  : TTreeNode;
  PInt : PInteger;
  Counter : Integer;
begin
  with CategoryTreeView, Items do
  begin
    New(PInt);
    PInt^ := Join(0, Word(CatPCIBus));
    Node := AddChildObject(ARoot, 'PCI-Bus', PInt);

    if SystemAccessClass.PCIBusClass.DetectPCIDevices and
       (SystemAccessClass.PCIBusClass.PCIDeviceCount > 0) then
    for Counter := 0 to SystemAccessClass.PCIBusClass.PCIDeviceCount - 1 do
    begin
      New(PInt);
      PInt^ := Join(Counter + 1, Word(CatPCIDevice));
      AddChildObject(Node, 'PCI-Gerät ' +
                           IntToStr(Counter + 1) +
                           ' (' +
                           IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[Counter].VendorID, 4) +
                           ':' +
                           IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[Counter].DeviceID, 4) +
                           ')',
                           PInt);
    end;
  end;
end;

procedure TPCAnalyserForm.CreateSMBusTree(ARoot: TTreeNode);
var
  Node  : TTreeNode;
  PInt : PInteger;
  AddrCnt,
  ModuleCounter : Byte;
begin
  with CategoryTreeView, Items do
  begin
    New(PInt);
    PInt^ := Join(0, Word(CatSMBus));
    Node := AddChildObject(ARoot, 'Speichermodul(e) SMBus', PInt);

    if SystemAccessClass.PCIBusClass.SMBusBaseAddress <> 0 then
    begin
      SystemAccessClass.SMBusClass.SMBusBaseAddress :=
      SystemAccessClass.PCIBusClass.SMBusBaseAddress;

      SystemAccessClass.SMBusClass.SMBusControllerName :=
      SystemAccessClass.PCIBusClass.SMBusControllerName;

      Screen.Cursor := crHourGlass;
      SystemAccessClass.SMBusClass.MemoryDevices :=
        SystemAccessClass.SMBusClass.GetSMBusMemoryModules;
      Screen.Cursor := crDefault;
      ModuleCounter := 0;
      for AddrCnt := 0 to 7 do
        if SystemAccessClass.SMBusClass.MemoryDevices[AddrCnt] <> 0 then
        begin
          New(PInt);
          Inc(ModuleCounter);
          PInt^ := Join(SystemAccessClass.SMBusClass.MemoryDevices[AddrCnt] + 1,
                        Word(CatSMBus_MemoryDevice));

          AddChildObject(Node, 'Speichermodul ' +
                               IntToStr(ModuleCounter),
                               PInt);
        end;
    end;
  end;
end;

procedure TPCAnalyserForm.CheckKernelDriverButtonState;
var
  DrvStatus : Integer;
  IsTestSigningModeEnabled : Boolean;
begin
  if SystemAccessClass.IsAdmin and (SystemAccessClass.IsElevated)then
  begin
    IsTestSigningModeEnabled := SystemAccessClass.IsTestSigningModeEnabled;
    DrvStatus := SystemAccessClass.GetKernelModeDriverStatus(SystemAccessClass.DriverName);
    case DrvStatus of
      SERVICE_STOPPED          : begin
                                   LoadDriverButton.Enabled := False;
                                   UnloadDriverButton.Enabled := True;
                                 end;
      SERVICE_START_PENDING    : begin
                                   LoadDriverButton.Enabled := False;
                                   UnloadDriverButton.Enabled := False;
                                 end;
      SERVICE_STOP_PENDING     : begin
                                   LoadDriverButton.Enabled := False;
                                   UnloadDriverButton.Enabled := False;
                                 end;
      SERVICE_RUNNING          : begin
                                   LoadDriverButton.Enabled := False;
                                   UnloadDriverButton.Enabled := True;
                                 end;
      SERVICE_CONTINUE_PENDING : begin
                                   LoadDriverButton.Enabled := False;
                                   UnloadDriverButton.Enabled := False;
                                 end;
      SERVICE_PAUSE_PENDING    : begin
                                   LoadDriverButton.Enabled := False;
                                   UnloadDriverButton.Enabled := False;
                                 end;
      SERVICE_PAUSED           : begin
                                   LoadDriverButton.Enabled := False;
                                   UnloadDriverButton.Enabled := True;
                                 end;
      else
        if TOSVersion.Architecture in [arIntelX86, arARM32] then
          LoadDriverButton.Enabled := True
        else
        if (TOSVersion.Architecture in [arIntelX64, arARM64]) and (IsTestSigningModeEnabled) then
          LoadDriverButton.Enabled := True
        else
          LoadDriverButton.Enabled := False;

        UnloadDriverButton.Enabled := False;
    end;

    if TOSVersion.Architecture in [arIntelX64, arARM64] then
    begin
      if IsTestSigningModeEnabled then
      begin
        EnableTestModeButton.Enabled := False;
        DisableTestModeButton.Enabled := True;
      end
      else
      begin
        if SystemAccessClass.IsUEFISecureBoot then
          EnableTestModeButton.Enabled := False
        else
          EnableTestModeButton.Enabled := True;

        DisableTestModeButton.Enabled := False;
      end;
    end
    else
    begin
      EnableTestModeButton.Enabled := False;
      DisableTestModeButton.Enabled := False;
    end;
  end
  else
  begin
    LoadDriverButton.Enabled := False;
    UnloadDriverButton.Enabled := False;
    EnableTestModeButton.Enabled := False;
    DisableTestModeButton.Enabled := False;
  end;
end;

procedure TPCAnalyserForm.WMSysCommand(var Message: TWMSysCommand);
begin
  inherited;
  If Message.CmdType = $1234 then
    ShowMessage(ProgramName +
                ' Version ' + ProgramVersion + #13#13 +
                ProgramCopyright);
end;

function TPCAnalyserForm.Join(const LoWord, HiWord : Word) : Integer;
begin
  Result := LoWord + 65536 * HiWord;
end;

function TPCAnalyserForm.FormatSeconds(AValue : Int64; AShort : Boolean = True) : String;
var
  ts : TTimeSpan;
begin
  ts := TTimeSpan.Create(0, 0, 0, AValue);
  if AShort and (ts.Days = 0) then
    Result := Format('%2.2d:%2.2d:%2.2d', [ts.Hours, ts.Minutes, ts.Seconds])
  else
    Result := Format('%3.3d %2.2d:%2.2d:%2.2d', [ts.Days, ts.Hours, ts.Minutes, ts.Seconds]);
end;

procedure TPCAnalyserForm.AddLog(AStr : String; CreateNewLine : Boolean);
begin
  if CreateNewLine then
    LogMemo.Lines.Add(AStr)
  else
    if LogMemo.Lines.Count > 0 then
    begin
      LogMemo.Lines[LogMemo.Lines.Count - 1] :=
      LogMemo.Lines[LogMemo.Lines.Count - 1] +
      AStr;
    end;
end;

procedure TPCAnalyserForm.CategoryTreeViewChange(Sender: TObject; Node: TTreeNode);
begin
  if Assigned(Node) then
  begin
    if Assigned(Node.Data) then
    begin
      case HiWord(PInteger(Node.Data)^) of
        //Machine Section
        Integer(CatMachine)                  : DisplayMachineInfo;

        //Windows Section
        Integer(CatWindowsDetails)           : DisplayWindowsDetails;
        Integer(CatWindowsSoftware)          : DisplaySoftwareInstalled;
        Integer(CatWindowsDirectories)       : DisplayWindowsDirectories;
        Integer(CatWindowsEnvVariables)      : DisplayEnvVariables;

        //SMBIOS Section
        Integer(CatSMBIOS)                   : DisplaySMBIOSInfo;
        Integer(CatSMBIOS_BIOS)              : DisplaySMBIOSStructureDetails(SMB_BIOSINFO);
        Integer(CatSMBIOS_SystemInfo)        : DisplaySMBIOSStructureDetails(SMB_SYSINFO);
        Integer(CatSMBIOS_Mainboard)         : DisplaySMBIOSStructureDetails(SMB_BASEINFO);
        Integer(CatSMBIOS_Chassis)           : DisplaySMBIOSStructureDetails(SMB_SYSENC);
        Integer(CatSMBIOS_Processors)        : DisplaySMBIOSStructureDetails(SMB_CPU);
        Integer(CatSMBIOS_Caches)            : DisplaySMBIOSStructureDetails(SMB_CACHE);
        Integer(CatSMBIOS_Ports)             : DisplaySMBIOSStructureDetails(SMB_PORTCON);
        Integer(CatSMBIOS_Slots)             : DisplaySMBIOSStructureDetails(SMB_SLOTS);
        Integer(CatSMBIOS_MemoryController)  : DisplaySMBIOSStructureDetails(SMB_PHYSMEM);
        Integer(CatSMBIOS_MemoryModules)     : DisplaySMBIOSStructureDetails(SMB_MEMDEV);
        Integer(CatSMBIOS_VoltageSensor)     : DisplaySMBIOSStructureDetails(SMB_VOLTAGE);
        Integer(CatSMBIOS_CoolingSensor)     : DisplaySMBIOSStructureDetails(SMB_COOL);
        Integer(CatSMBIOS_TemperatureSensor) : DisplaySMBIOSStructureDetails(SMB_TEMP);
        Integer(CatSMBIOS_CurrentSensor)     : DisplaySMBIOSStructureDetails(SMB_CURRENT);
        Integer(CatSMBIOS_TPMDevice)         : DisplaySMBIOSStructureDetails(SMB_TPMDEV);

        //Processor Section
        Integer(CatProcessorDetails)         : DisplayCPUDetail(LoWord(PInteger(Node.Data)^) - 1);
        Integer(CatCPUCache)                 : DisplayCPUCache(LoWord(PInteger(Node.Data)^) - 1);
        Integer(CatProcessorFeatures)        : DisplayCPUFeatures(LoWord(PInteger(Node.Data)^) - 1);
        Integer(CatProcessorMSR)             : DisplayCPUMSR(LoWord(PInteger(Node.Data)^) - 1);

        //PCI Bus Section
        Integer(CatPCIBus)                   : DisplayPCIDevices;
        Integer(CatPCIDevice)                : DisplayPCIDevice(LoWord(PInteger(Node.Data)^) - 1);

        //SMBus Section
        Integer(CatSMBus)                    : DisplaySMBus_MemoryDevices;
        Integer(CatSMBus_MemoryDevice)       : DisplaySMBus_MemoryDevice(LoWord(PInteger(Node.Data)^) - 1);
        else
          DisplayNodeInfo;
      end;
    end;
  end;
end;

procedure TPCAnalyserForm.DisplaySMBIOSInfo;
var
  TblCount : Integer;
begin
  with ResultsListView, Items do
  begin
    BeginUpdate;
    try
      Clear;

      with Add do
      begin
        Caption := 'SMBIOS-Datenbasis';
        SubItems.Add(SystemAccessClass.SMBIOSClass.DataSource);
      end;

      with Add do
      begin
        Caption := 'SMBIOS-Version';
        SubItems.Add(IntToStr(SystemAccessClass.SMBIOSClass.MajorVersion) +
                     '.' +
                     IntToStr(SystemAccessClass.SMBIOSClass.MinorVersion));
      end;

      with Add do
      begin
        Caption := 'Revision';
        SubItems.Add(IntToStr(SystemAccessClass.SMBIOSClass.DMIRevision));
      end;

      with Add do
      begin
        Caption := 'Anzahl der Strukturen';
        SubItems.Add(IntToStr(SystemAccessClass.SMBIOSClass.TableCount));
      end;

      with Add do
      begin
        Caption := 'Gesamtgröße der Strukturen';
        SubItems.Add(IntToStr(SystemAccessClass.SMBIOSClass.Size) + ' Bytes');
      end;

      if SystemAccessClass.SMBIOSClass.TableCount > 0 then
      begin
        with Add do
        begin
          Caption := '';
          SubItems.Add('');
        end;
        with Add do
        begin
          Caption := 'SMBIOS-Strukturen';
        end;

        for TblCount := 0 to SystemAccessClass.SMBIOSClass.TableCount - 1 do
        with Add do
        begin
          Caption := 'Strukturtyp ' +
                     IntToStr(SystemAccessClass.SMBIOSClass.Tables[TblCount].Header.&Type);
          SubItems.Add(SystemAccessClass.SMBIOSClass.Tables[TblCount].Name);
        end;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TPCAnalyserForm.DisplaySMBIOSStructureDetails(AStructNum : Byte);
var
  SMBIOSDetail : TStrings;
  SMBIOSCnt : Integer;
begin
  SMBIOSDetail := TStringList.Create;
  try
    SystemAccessClass.SMBIOSClass.GetSMBIOSStructureDetails(
      AStructNum, SMBIOSDetail);

    with ResultsListView, Items do
    begin
      BeginUpdate;
      try
        Clear;

        if SMBIOSDetail.Count > 0 then
        begin
          for SMBIOSCnt := 0 to SMBIOSDetail.Count - 1 do
            with Add do
            begin
              Caption :=
                SystemAccessClass.SMBIOSClass.
                GetNameFromStr(SMBIOSDetail.Strings[SMBIOSCnt], '=');
              SubItems.Add(
                SystemAccessClass.SMBIOSClass.
                GetValueFromStr(SMBIOSDetail.Strings[SMBIOSCnt], '='));
            end;
        end else
        begin
          with Add do
            Caption := 'Keine SMBIOS-Details ermittelbar';
        end;

      finally
        EndUpdate;
      end;
    end;
  finally
    SMBIOSDetail.Free;
  end;
end;

procedure TPCAnalyserForm.DisplayCPUDetail(AIndex: Integer);
var
  StringValue : String;
begin
  if SystemAccessClass.ProcessorClass.FVendor = cvNone then
    SystemAccessClass.ProcessorClass.GetProcessorDetails(AIndex);

  with ResultsListView, Items do
  begin
    BeginUpdate;
    try
      Clear;

      with Add do
      begin
        Caption := 'Hersteller';
        SubItems.Add(SystemAccessClass.ProcessorClass.cVendorNames[
                     SystemAccessClass.ProcessorClass.FVendor].
                     Name);
      end;

      if SystemAccessClass.ProcessorClass.FCPUName <> '' then
        with Add do
        begin
          Caption := 'Prozessorname';
          SubItems.Add(SystemAccessClass.ProcessorClass.cVendorNames[
                       SystemAccessClass.ProcessorClass.FVendor].Prefix +
                       ' ' +
                       SystemAccessClass.ProcessorClass.FCPUName);
        end;

      case SystemAccessClass.ProcessorClass.FArch of
        PROCESSOR_ARCHITECTURE_AMD64 :
          StringValue := 'x64 (AMD oder Intel)';
        PROCESSOR_ARCHITECTURE_IA32_ON_WIN64 :
          StringValue := 'WOW64';
        PROCESSOR_ARCHITECTURE_IA64 :
          StringValue := 'Intel Itanium Processor Family (IPF)';
        PROCESSOR_ARCHITECTURE_INTEL :
          StringValue := 'x86';
        else
          StringValue := 'unbekannt (' + IntToStr(SystemAccessClass.ProcessorClass.FArch) + ')';
      end;
      with Add do
      begin
        Caption := 'Architektur';
        SubItems.Add(StringValue);
      end;

      case SystemAccessClass.ProcessorClass.FCPUType of
        0  : StringValue := 'Hauptprozessor';
        1  : StringValue := 'Overdrive-Prozessor';
        2  : StringValue := 'Zweiter Prozessor (Multiprozessor)';
        else StringValue := 'unbekannt (' + IntToStr(SystemAccessClass.ProcessorClass.FCPUType) + ')';
      end;
      with Add do
      begin
        Caption := 'Typ';
        SubItems.Add(StringValue);
      end;

      if SystemAccessClass.ProcessorClass.FMarketingName <> '' then
      with Add do
      begin
        Caption := 'Marketing-Name';
        SubItems.Add(SystemAccessClass.ProcessorClass.FMarketingName);
      end;

      if SystemAccessClass.ProcessorClass.FGenericName <> '' then
      with Add do
      begin
        Caption := 'Generischer Name';
        SubItems.Add(SystemAccessClass.ProcessorClass.FGenericName);
      end;

      if SystemAccessClass.ProcessorClass.FCodeName <> '' then
      with Add do
      begin
        Caption := 'Code-Name';
        SubItems.Add(SystemAccessClass.ProcessorClass.FCodeName);
      end;

      if SystemAccessClass.ProcessorClass.FRevision <> '' then
      with Add do
      begin
        Caption := 'Revision';
        SubItems.Add(SystemAccessClass.ProcessorClass.FRevision);
      end;

      if SystemAccessClass.ProcessorClass.FTech <> '' then
      with Add do
      begin
        Caption := 'Technologie';
        SubItems.Add(SystemAccessClass.ProcessorClass.FTech);
      end;

      if SystemAccessClass.ProcessorClass.FFreq > 0 then
      with Add do
      begin
        Caption := 'Taktfrequenz';
        SubItems.Add(FloatToStrF(SystemAccessClass.ProcessorClass.FFreq, ffFixed, 15, 0) + ' MHz');
      end;

      if SystemAccessClass.ProcessorClass.FCPUFeatures.Instructions <> '' then
      with Add do
      begin
        Caption := 'Instruktionen';
        SubItems.Add(SystemAccessClass.ProcessorClass.FCPUFeatures.Instructions);
      end;

      with Add do
        Caption := '';

      with Add do
        Caption := 'Kernstatistik';

      with Add do
      begin
        Caption := 'Physikalische Prozessoren';
        SubItems.Add(IntToStr(SystemAccessClass.ProcessorClass.CPUPhysicalCount));
      end;

      with Add do
      begin
        Caption := 'Anzahl Kerne / Threads';
        SubItems.Add(IntToStr(SystemAccessClass.ProcessorClass.CoreCount) +
                     ' / ' +
                     IntToStr(SystemAccessClass.ProcessorClass.ThreadCount));
      end;

      with Add do
      begin
        Caption := 'Kerne / Logische Kerne pro Paket';
        SubItems.Add(IntToStr(SystemAccessClass.ProcessorClass.CorePerPackage) +
                     ' / ' +
                     IntToStr(SystemAccessClass.ProcessorClass.LogicalPerCore));
      end;

      with Add do
        Caption := '';

      with Add do
        Caption := 'CPUID-Details';

      with Add do
      begin
        Caption := 'Familie / Familie-Erweitert';
        SubItems.Add(IntToStr(SystemAccessClass.ProcessorClass.FFamily) +
                     ' / ' +
                     IntToStr(SystemAccessClass.ProcessorClass.FFamilyEx));
      end;

      with Add do
      begin
        Caption := 'Modell / Modell-Erweitert';
        SubItems.Add(IntToStr(SystemAccessClass.ProcessorClass.FModel) +
                     ' / ' +
                     IntToStr(SystemAccessClass.ProcessorClass.FModelEx));
      end;

      with Add do
      begin
        Caption := 'Stepping / Stepping-Erweitert';
        SubItems.Add(IntToStr(SystemAccessClass.ProcessorClass.FStepping) +
                     ' / ' +
                     IntToStr(SystemAccessClass.ProcessorClass.FSteppingEx));
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TPCAnalyserForm.DisplayCPUCache(AIndex: Integer);
begin
  if SystemAccessClass.ProcessorClass.FVendor = cvNone then
    SystemAccessClass.ProcessorClass.GetProcessorDetails(AIndex);

  with ResultsListView, Items do
  begin
    BeginUpdate;
    try
      Clear;

      with SystemAccessClass.ProcessorClass.FCPUCache.Level1.Code do
      if Size > 0 then
      begin
        with Add do
          Caption := 'Level 1 Instruktionen';

        with Add do
        begin
          Caption := '- Größe';
          SubItems.Add(IntToStr(Size * SharedWays) + ' KByte');
        end;

        with Add do
        begin
          Caption := '- Assoziativität';
          if Associativity <> caNone then
            SubItems.Add(Format('%s', [cAssociativityDescription[Associativity]]))
          else
            SubItems.Add(Format('%d-fach', [Ways]));
        end;

        with Add do
        begin
          Caption := '- Zeilengröße';
          SubItems.Add(IntToStr(LineSize) + ' Einträge');
        end;
      end;

      with SystemAccessClass.ProcessorClass.FCPUCache.Level1.Data do
      if Size > 0 then
      begin
        with Add do
          Caption := '';
        with Add do
          Caption := 'Level 1 Daten';

        with Add do
        begin
          Caption := '- Größe';
          SubItems.Add(IntToStr(Size * SharedWays) + ' KByte');
        end;

        with Add do
        begin
          Caption := '- Assoziativität';
          if Associativity <> caNone then
            SubItems.Add(Format('%s', [cAssociativityDescription[Associativity]]))
          else
            SubItems.Add(Format('%d-fach', [Ways]));
        end;

        with Add do
        begin
          Caption := '- Zeilengröße';
          SubItems.Add(IntToStr(LineSize) + ' Einträge');
        end;
      end;

      with SystemAccessClass.ProcessorClass.FCPUCache.Level1.Unified do
      if Size > 0 then
      begin
        with Add do
          Caption := '';
        with Add do
          Caption := 'Level 1 Daten+Instruktionen';

        with Add do
        begin
          Caption := '- Größe';
          SubItems.Add(IntToStr(Size * SharedWays) + ' KByte');
        end;

        with Add do
        begin
          Caption := '- Assoziativität';
          if Associativity <> caNone then
            SubItems.Add(Format('%s', [cAssociativityDescription[Associativity]]))
          else
            SubItems.Add(Format('%d-fach', [Ways]));
        end;

        with Add do
        begin
          Caption := '- Zeilengröße';
          SubItems.Add(IntToStr(LineSize) + ' Einträge');
        end;
      end;

      with SystemAccessClass.ProcessorClass.FCPUCache.Level2 do
      if Size > 0 then
      begin
        with Add do
          Caption := '';
        with Add do
          Caption := 'Level 2';

        with Add do
        begin
          Caption := '- Größe';
          SubItems.Add(IntToStr(Size * SharedWays) + ' KByte');
        end;

        with Add do
        begin
          Caption := '- Assoziativität';
          if Associativity <> caNone then
            SubItems.Add(Format('%s', [cAssociativityDescription[Associativity]]))
          else
            SubItems.Add(Format('%d-fach', [Ways]));
        end;

        with Add do
        begin
          Caption := '- Zeilengröße';
          SubItems.Add(IntToStr(LineSize) + ' Einträge');
        end;
      end;

      with SystemAccessClass.ProcessorClass.FCPUCache.Level3 do
      if Size > 0 then
      begin
        with Add do
          Caption := '';
        with Add do
          Caption := 'Level 3';

        with Add do
        begin
          Caption := '- Größe';
          SubItems.Add(IntToStr(Size * SharedWays) + ' KByte');
        end;

        with Add do
        begin
          Caption := '- Assoziativität';
          if Associativity <> caNone then
            SubItems.Add(Format('%s', [cAssociativityDescription[Associativity]]))
          else
            SubItems.Add(Format('%d-fach', [Ways]));
        end;

        with Add do
        begin
          Caption := '- Zeilengröße';
          SubItems.Add(IntToStr(LineSize) + ' Einträge');
        end;
      end;

      with SystemAccessClass.ProcessorClass.FCPUCache.Trace do
      if Size > 0 then
      begin
        with Add do
          Caption := '';
        with Add do
          Caption := 'Trace';

        with Add do
        begin
          Caption := '- Größe';
          SubItems.Add(IntToStr(Size) + ' KByte');
        end;

        with Add do
        begin
          Caption := '- Assoziativität';
          SubItems.Add(cAssociativityDescription[Associativity]);
        end;

        with Add do
        begin
          Caption := '- Zeilengröße';
          SubItems.Add(IntToStr(LineSize) + ' Einträge');
        end;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TPCAnalyserForm.DisplayCPUFeatures(AIndex: Integer);
var
  FeatCount : Integer;
begin
  if SystemAccessClass.ProcessorClass.FVendor = cvNone then
    SystemAccessClass.ProcessorClass.GetProcessorDetails(AIndex);

  with ResultsListView, Items do
  begin
    BeginUpdate;
    try
      Clear;

      if SystemAccessClass.ProcessorClass.FCPUFeatures.Standard.Count > 0 then
      begin
        with Add do
          Caption := 'Standard Fähigkeiten';

        for FeatCount := 0 to SystemAccessClass.ProcessorClass.FCPUFeatures.Standard.Count - 1 do
          with SystemAccessClass.ProcessorClass.FCPUFeatures.Standard.Features[FeatCount], Definition do
          begin
            with Add do
            begin
              Caption := Name + ' (' + Desc + ')';
              SubItems.Add(SystemAccessClass.ProcessorClass.YesNo(Value));
            end;
          end;
      end;

      if SystemAccessClass.ProcessorClass.FCPUFeatures.Extended.Count > 0 then
      begin
        with Add do
          Caption := '';
        with Add do
          Caption := 'Erweiterte Fähigkeiten';

        for FeatCount := 0 to SystemAccessClass.ProcessorClass.FCPUFeatures.Extended.Count - 1 do
          with SystemAccessClass.ProcessorClass.FCPUFeatures.Extended.Features[FeatCount], Definition do
          begin
            with Add do
            begin
              Caption := Name + ' (' + Desc + ')';
              SubItems.Add(SystemAccessClass.ProcessorClass.YesNo(Value));
            end;
          end;
      end;

      if SystemAccessClass.ProcessorClass.FCPUFeatures.PowerManagement.Count > 0 then
      begin
        with Add do
          Caption := '';
        with Add do
          Caption := 'Stromspar-Fähigkeiten';

        for FeatCount := 0 to SystemAccessClass.ProcessorClass.FCPUFeatures.PowerManagement.Count - 1 do
          with SystemAccessClass.ProcessorClass.FCPUFeatures.PowerManagement.Features[FeatCount], Definition do
          begin
            with Add do
            begin
              Caption := Name + ' (' + Desc + ')';
              SubItems.Add(SystemAccessClass.ProcessorClass.YesNo(Value));
            end;
          end;
      end;

      if SystemAccessClass.ProcessorClass.FCPUFeatures.SecureVirtualMachine.Count > 0 then
      begin
        with Add do
          Caption := '';
        with Add do
          Caption := 'Fähigkeiten für sichere virtuelle Maschine';

        for FeatCount := 0 to SystemAccessClass.ProcessorClass.FCPUFeatures.SecureVirtualMachine.Count - 1 do
          with SystemAccessClass.ProcessorClass.FCPUFeatures.SecureVirtualMachine.Features[FeatCOunt], Definition do
          begin
            with Add do
            begin
              Caption := Name + ' (' + Desc + ')';
              SubItems.Add(SystemAccessClass.ProcessorClass.YesNo(Value));
            end;
          end;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TPCAnalyserForm.DisplayCPUMSR(AIndex: Integer);
var
  InputBuf : ReadMSRInputStruct;
  OutputBuf : ReadMSROutputStruct;
  MSRCount,
  CPUCount : Integer;
  CPUID_ThermalMonitor,
  CPUID_DTSSupported : TCPUIDRec;
begin
  if SystemAccessClass.ProcessorClass.FVendor = cvNone then
    SystemAccessClass.ProcessorClass.GetProcessorDetails(AIndex);

  with ResultsListView, Items do
  begin
    BeginUpdate;
    try
      Clear;

      //wenn Kernelmodus-Treiber geladen, dann mit MSR-Sektion beginnen
      if SystemAccessClass.GetKernelModeDriverStatus(SystemAccessClass.DriverName) = SERVICE_RUNNING then
      begin
        //Intel & AMD Microcode Update
        if SystemAccessClass.ProcessorClass.FVendor in [cvIntel, cvAMD] then
        begin
          with Add do
          begin
            Caption := 'Microcode Update';
            SubItems.Add(IntToHex(SystemAccessClass.ProcessorClass.GetIntelAMD_MicrocodeUpdate) + 'h');
          end;
        end;

        //Intel Platform ID
        if SystemAccessClass.ProcessorClass.FVendor = cvIntel then
        begin
          InputBuf.ECXReg := $17; {IA32_PLATFORM_ID}
          if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
          with Add do
          begin
            Caption := 'Platform ID';
            SubItems.Add(IntToStr((OutputBuf.EDXReg shr 18) and 7));
          end;
        end;

        //Intel Overclocking Status
        if SystemAccessClass.ProcessorClass.FVendor = cvIntel then
        begin
          with Add do
            Caption := '';

          with Add do
            Caption := 'Übertaktungsstatus';

          InputBuf.ECXReg := $195; {IA32_OVERCLOCKING_STATUS}
          if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
          begin
            with Add do
            begin
              Caption := '- Übertaktung wird verwendet';
              SubItems.Add(SystemAccessClass.ProcessorClass.YesNo(
                           SystemAccessClass.ProcessorClass.IsBitOn(OutputBuf.EAXReg, 0)));
            end;

            with Add do
            begin
              Caption := '- Unterspannungsschutz';
              SubItems.Add(SystemAccessClass.ProcessorClass.YesNo(
                           SystemAccessClass.ProcessorClass.IsBitOn(OutputBuf.EAXReg, 1)));
            end;

            with Add do
            begin
              Caption := '- Sicherheitsstatus für Übertaktung';
              if SystemAccessClass.ProcessorClass.IsBitOn(OutputBuf.EAXReg, 2) then
                SubItems.Add('gesichert')
              else
                SubItems.Add('nicht gesichert');
            end;
          end;
        end;

        //Intel Temperatures
        CPUID_ThermalMonitor := SystemAccessClass.ProcessorClass.ExecuteCPUID(-1, CPUID_STD_FeatureSet);
        CPUID_DTSSupported := SystemAccessClass.ProcessorClass.ExecuteCPUID(-1, CPUID_STD_ThermalPower);
        if (SystemAccessClass.ProcessorClass.FVendor = cvIntel) and
           (SystemAccessClass.ProcessorClass.IsBitOn(CPUID_ThermalMonitor.EDX, 22)) and
           (SystemAccessClass.ProcessorClass.IsBitOn(CPUID_DTSSupported.EAX, 31)) then
        begin
          with Add do
            Caption := '';

          with Add do
            Caption := 'Temperaturen';

          if SystemAccessClass.ProcessorClass.GetIntelTjMax > 0 then
          begin
            for CPUCount := 0 to SystemAccessClass.ProcessorClass.CoreCount - 1 do
            begin
              SystemAccessClass.ProcessorClass.SetProcAffinity(CPUCount);

              InputBuf.ECXReg := $19C; {IA32_THERM_STATUS}
              if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
              begin
                if SystemAccessClass.ProcessorClass.IsBitOn(OutputBuf.EAXReg, 31) then
                with Add do
                begin
                  Caption := 'Temperatur für Kern ' + IntToStr(CPUCount + 1);
                  SubItems.Add(IntToStr(
                    SystemAccessClass.ProcessorClass.GetIntelTjMax -
                    ((OutputBuf.EAXReg shr 16) and $7F)) + {Digital Readout}
                    ' Grad');
                end;
              end;
            end;
            SystemAccessClass.ProcessorClass.RestoreProcAffinity;
          end
          else
            with Add do
              Caption := 'Keine Temperaturen auslesbar';
        end;

        //AMD System Configuration
        if SystemAccessClass.ProcessorClass.FVendor = cvAMD then
        begin
          with Add do
            Caption := '';

          with Add do
            Caption := 'System-Konfiguration';

          InputBuf.ECXReg := $C0010010; {System Configuration / SYS_CFG}
          if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
          with Add do
          begin
            Caption := 'Sichere Speicherverschlüsselung aktiv';
            SubItems.Add(SystemAccessClass.ProcessorClass.YesNo(
                         SystemAccessClass.ProcessorClass.IsBitOn(OutputBuf.EAXReg, 23)));
          end;
        end;

        //AMD Hardware Configuration
        if SystemAccessClass.ProcessorClass.FVendor = cvAMD then
        begin
          with Add do
            Caption := '';

          with Add do
            Caption := 'Hardware-Konfiguration';

          InputBuf.ECXReg := $C0010015; {Hardware Configuration / HWCR}
          if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
          begin
            with Add do
            begin
              Caption := 'Cachefähiger Speicher aktiv';
              SubItems.Add(SystemAccessClass.ProcessorClass.YesNo(
                           not SystemAccessClass.ProcessorClass.IsBitOn(OutputBuf.EAXReg, 3)));
            end;

            with Add do
            begin
              Caption := 'Kernleistungssteigerung aktiv';
              SubItems.Add(SystemAccessClass.ProcessorClass.YesNo(
                           not SystemAccessClass.ProcessorClass.IsBitOn(OutputBuf.EAXReg, 25)));
            end;
          end;
        end;

        //Intel & AMD MSR List
        if SystemAccessClass.ProcessorClass.FVendor in [cvIntel, cvAMD] then
        begin
          with Add do
            Caption := '';

          with Add do
            Caption := 'MSR-Liste';

          if SystemAccessClass.ProcessorClass.FVendor = cvIntel then
          begin
            for MSRCount := 0 to INTEL_ARCHITECTURAL_MSRS_CONST - 1 do
            begin
              try
                InputBuf.ECXReg := INTEL_ARCHITECTURAL_MSRS[MSRCount].MSR_ID;
                if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
                with Add do
                begin
                  Caption := IntToHex(INTEL_ARCHITECTURAL_MSRS[MSRCount].MSR_ID, 8) +
                             'h - ' +
                             INTEL_ARCHITECTURAL_MSRS[MSRCount].Name;
                  SubItems.Add(IntToHex(OutputBuf.EDXReg, 8) +
                               ':' +
                               IntToHex(OutputBuf.EAXReg, 8));
                end;
              except
                with Add do
                begin
                  Caption := IntToHex(INTEL_ARCHITECTURAL_MSRS[MSRCount].MSR_ID, 8) +
                             'h - ' +
                             INTEL_ARCHITECTURAL_MSRS[MSRCount].Name;
                  SubItems.Add('nicht auslesbar');
                end;
              end;
            end;
          end
          else
          if SystemAccessClass.ProcessorClass.FVendor = cvAMD then
          begin
            case SystemAccessClass.ProcessorClass.FFamily of
              $10 : begin {AMD Family 10h}
                      for MSRCount := 0 to AMD_FAMILY10_MSRS_CONST - 1 do
                      begin
                        try
                          InputBuf.ECXReg := AMD_FAMILY10_MSRS[MSRCount].MSR_ID;
                          if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
                          with Add do
                          begin
                            Caption := IntToHex(AMD_FAMILY10_MSRS[MSRCount].MSR_ID, 8) +
                                       'h - ' +
                                       AMD_FAMILY10_MSRS[MSRCount].Name;
                            SubItems.Add(IntToHex(OutputBuf.EDXReg, 8) +
                                         ':' +
                                         IntToHex(OutputBuf.EAXReg, 8));
                          end;
                        except
                          with Add do
                          begin
                            Caption := IntToHex(AMD_FAMILY10_MSRS[MSRCount].MSR_ID, 8) +
                                       'h - ' +
                                       AMD_FAMILY10_MSRS[MSRCount].Name;
                            SubItems.Add('nicht auslesbar');
                          end;
                        end;
                      end;
                    end;
              $11 : for MSRCount := 0 to AMD_FAMILY11_MSRS_CONST - 1 do {AMD Family 11h}
                    begin
                      try
                        InputBuf.ECXReg := AMD_FAMILY11_MSRS[MSRCount].MSR_ID;
                        if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
                        with Add do
                        begin
                          Caption := IntToHex(AMD_FAMILY11_MSRS[MSRCount].MSR_ID, 8) +
                                     'h - ' +
                                     AMD_FAMILY11_MSRS[MSRCount].Name;
                          SubItems.Add(IntToHex(OutputBuf.EDXReg, 8) +
                                       ':' +
                                       IntToHex(OutputBuf.EAXReg, 8));
                        end;
                      except
                        with Add do
                        begin
                          Caption := IntToHex(AMD_FAMILY11_MSRS[MSRCount].MSR_ID, 8) +
                                     'h - ' +
                                     AMD_FAMILY11_MSRS[MSRCount].Name;
                          SubItems.Add('nicht auslesbar');
                        end;
                      end;
                    end;
              $12 : for MSRCount := 0 to AMD_FAMILY12_MSRS_CONST - 1 do {AMD Family 12h}
                    begin
                      try
                        InputBuf.ECXReg := AMD_FAMILY12_MSRS[MSRCount].MSR_ID;
                        if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
                        with Add do
                        begin
                          Caption := IntToHex(AMD_FAMILY12_MSRS[MSRCount].MSR_ID, 8) +
                                     'h - ' +
                                     AMD_FAMILY12_MSRS[MSRCount].Name;
                          SubItems.Add(IntToHex(OutputBuf.EDXReg, 8) +
                                       ':' +
                                       IntToHex(OutputBuf.EAXReg, 8));
                        end;
                      except
                        with Add do
                        begin
                          Caption := IntToHex(AMD_FAMILY12_MSRS[MSRCount].MSR_ID, 8) +
                                     'h - ' +
                                     AMD_FAMILY12_MSRS[MSRCount].Name;
                          SubItems.Add('nicht auslesbar');
                        end;
                      end;
                    end;
              $14 : for MSRCount := 0 to AMD_FAMILY14_MSRS_CONST - 1 do {AMD Family 14h}
                    begin
                      try
                        InputBuf.ECXReg := AMD_FAMILY14_MSRS[MSRCount].MSR_ID;
                        if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
                        with Add do
                        begin
                          Caption := IntToHex(AMD_FAMILY14_MSRS[MSRCount].MSR_ID, 8) +
                                     'h - ' +
                                     AMD_FAMILY14_MSRS[MSRCount].Name;
                          SubItems.Add(IntToHex(OutputBuf.EDXReg, 8) +
                                       ':' +
                                       IntToHex(OutputBuf.EAXReg, 8));
                        end;
                      except
                        with Add do
                        begin
                          Caption := IntToHex(AMD_FAMILY14_MSRS[MSRCount].MSR_ID, 8) +
                                     'h - ' +
                                     AMD_FAMILY14_MSRS[MSRCount].Name;
                          SubItems.Add('nicht auslesbar');
                        end;
                      end;
                    end;
              $15 : case SystemAccessClass.ProcessorClass.FModel of {AMD Family 15h}
                      $00..$0F : for MSRCount := 0 to AMD_FAMILY15_M000F_MSRS_CONST - 1 do
                                 begin
                                   try
                                     InputBuf.ECXReg := AMD_FAMILY15_M000F_MSRS[MSRCount].MSR_ID;
                                     if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
                                     with Add do
                                     begin
                                       Caption := IntToHex(AMD_FAMILY15_M000F_MSRS[MSRCount].MSR_ID, 8) +
                                                  'h - ' +
                                                  AMD_FAMILY15_M000F_MSRS[MSRCount].Name;
                                       SubItems.Add(IntToHex(OutputBuf.EDXReg, 8) +
                                                    ':' +
                                                    IntToHex(OutputBuf.EAXReg, 8));
                                     end;
                                   except
                                     with Add do
                                     begin
                                       Caption := IntToHex(AMD_FAMILY15_M000F_MSRS[MSRCount].MSR_ID, 8) +
                                                  'h - ' +
                                                  AMD_FAMILY15_M000F_MSRS[MSRCount].Name;
                                       SubItems.Add('nicht auslesbar');
                                     end;
                                   end;
                                 end;
                      $10..$1F : for MSRCount := 0 to AMD_FAMILY15_M101F_MSRS_CONST - 1 do
                                 begin
                                   try
                                     InputBuf.ECXReg := AMD_FAMILY15_M101F_MSRS[MSRCount].MSR_ID;
                                     if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
                                     with Add do
                                     begin
                                       Caption := IntToHex(AMD_FAMILY15_M101F_MSRS[MSRCount].MSR_ID, 8) +
                                                  'h - ' +
                                                  AMD_FAMILY15_M101F_MSRS[MSRCount].Name;
                                       SubItems.Add(IntToHex(OutputBuf.EDXReg, 8) +
                                                    ':' +
                                                    IntToHex(OutputBuf.EAXReg, 8));
                                     end;
                                   except
                                     with Add do
                                     begin
                                       Caption := IntToHex(AMD_FAMILY15_M101F_MSRS[MSRCount].MSR_ID, 8) +
                                                  'h - ' +
                                                  AMD_FAMILY15_M101F_MSRS[MSRCount].Name;
                                       SubItems.Add('nicht auslesbar');
                                     end;
                                   end;
                                 end;
                      $30..$3F : for MSRCount := 0 to AMD_FAMILY15_M303F_MSRS_CONST - 1 do
                                 begin
                                   try
                                     InputBuf.ECXReg := AMD_FAMILY15_M303F_MSRS[MSRCount].MSR_ID;
                                     if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
                                     with Add do
                                     begin
                                       Caption := IntToHex(AMD_FAMILY15_M303F_MSRS[MSRCount].MSR_ID, 8) +
                                                  'h - ' +
                                                  AMD_FAMILY15_M303F_MSRS[MSRCount].Name;
                                       SubItems.Add(IntToHex(OutputBuf.EDXReg, 8) +
                                                    ':' +
                                                    IntToHex(OutputBuf.EAXReg, 8));
                                     end;
                                   except
                                     with Add do
                                     begin
                                       Caption := IntToHex(AMD_FAMILY15_M303F_MSRS[MSRCount].MSR_ID, 8) +
                                                  'h - ' +
                                                  AMD_FAMILY15_M303F_MSRS[MSRCount].Name;
                                       SubItems.Add('nicht auslesbar');
                                     end;
                                   end;
                                 end;
                      $60..$6F : for MSRCount := 0 to AMD_FAMILY15_M606F_MSRS_CONST - 1 do
                                 begin
                                   try
                                     InputBuf.ECXReg := AMD_FAMILY15_M606F_MSRS[MSRCount].MSR_ID;
                                     if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
                                     with Add do
                                     begin
                                       Caption := IntToHex(AMD_FAMILY15_M606F_MSRS[MSRCount].MSR_ID, 8) +
                                                  'h - ' +
                                                  AMD_FAMILY15_M606F_MSRS[MSRCount].Name;
                                       SubItems.Add(IntToHex(OutputBuf.EDXReg, 8) +
                                                    ':' +
                                                    IntToHex(OutputBuf.EAXReg, 8));
                                     end;
                                   except
                                     with Add do
                                     begin
                                       Caption := IntToHex(AMD_FAMILY15_M606F_MSRS[MSRCount].MSR_ID, 8) +
                                                  'h - ' +
                                                  AMD_FAMILY15_M606F_MSRS[MSRCount].Name;
                                       SubItems.Add('nicht auslesbar');
                                     end;
                                   end;
                                 end;
                      $70..$7F : for MSRCount := 0 to AMD_FAMILY15_M707F_MSRS_CONST - 1 do
                                 begin
                                   try
                                     InputBuf.ECXReg := AMD_FAMILY15_M707F_MSRS[MSRCount].MSR_ID;
                                     if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
                                     with Add do
                                     begin
                                       Caption := IntToHex(AMD_FAMILY15_M707F_MSRS[MSRCount].MSR_ID, 8) +
                                                  'h - ' +
                                                  AMD_FAMILY15_M707F_MSRS[MSRCount].Name;
                                       SubItems.Add(IntToHex(OutputBuf.EDXReg, 8) +
                                                    ':' +
                                                    IntToHex(OutputBuf.EAXReg, 8));
                                     end;
                                   except
                                     with Add do
                                     begin
                                       Caption := IntToHex(AMD_FAMILY15_M707F_MSRS[MSRCount].MSR_ID, 8) +
                                                  'h - ' +
                                                  AMD_FAMILY15_M707F_MSRS[MSRCount].Name;
                                       SubItems.Add('nicht auslesbar');
                                     end;
                                   end;
                                 end;
                    END;
              $16 : case SystemAccessClass.ProcessorClass.FModel of {AMD Family 16h}
                      $00..$0F : for MSRCount := 0 to AMD_FAMILY16_M000F_MSRS_CONST - 1 do
                                 begin
                                   try
                                     InputBuf.ECXReg := AMD_FAMILY16_M000F_MSRS[MSRCount].MSR_ID;
                                     if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
                                     with Add do
                                     begin
                                       Caption := IntToHex(AMD_FAMILY16_M000F_MSRS[MSRCount].MSR_ID, 8) +
                                                  'h - ' +
                                                  AMD_FAMILY16_M000F_MSRS[MSRCount].Name;
                                       SubItems.Add(IntToHex(OutputBuf.EDXReg, 8) +
                                                    ':' +
                                                    IntToHex(OutputBuf.EAXReg, 8));
                                     end;
                                   except
                                     with Add do
                                     begin
                                       Caption := IntToHex(AMD_FAMILY16_M000F_MSRS[MSRCount].MSR_ID, 8) +
                                                  'h - ' +
                                                  AMD_FAMILY16_M000F_MSRS[MSRCount].Name;
                                       SubItems.Add('nicht auslesbar');
                                     end;
                                   end;
                                 end;
                      $30..$3F : for MSRCount := 0 to AMD_FAMILY16_M303F_MSRS_CONST - 1 do
                                 begin
                                   try
                                     InputBuf.ECXReg := AMD_FAMILY16_M303F_MSRS[MSRCount].MSR_ID;
                                     if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
                                     with Add do
                                     begin
                                       Caption := IntToHex(AMD_FAMILY16_M303F_MSRS[MSRCount].MSR_ID, 8) +
                                                  'h - ' +
                                                  AMD_FAMILY16_M303F_MSRS[MSRCount].Name;
                                       SubItems.Add(IntToHex(OutputBuf.EDXReg, 8) +
                                                    ':' +
                                                    IntToHex(OutputBuf.EAXReg, 8));
                                     end;
                                   except
                                     with Add do
                                     begin
                                       Caption := IntToHex(AMD_FAMILY16_M303F_MSRS[MSRCount].MSR_ID, 8) +
                                                  'h - ' +
                                                  AMD_FAMILY16_M303F_MSRS[MSRCount].Name;
                                       SubItems.Add('nicht auslesbar');
                                     end;
                                   end;
                                 end;
                    END;
              $17 : for MSRCount := 0 to AMD_FAMILY17_MSRS_CONST - 1 do {AMD Family 17h}
                    begin
                      try
                        InputBuf.ECXReg := AMD_FAMILY17_MSRS[MSRCount].MSR_ID;
                        if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
                        with Add do
                        begin
                          Caption := IntToHex(AMD_FAMILY17_MSRS[MSRCount].MSR_ID, 8) +
                                     'h - ' +
                                     AMD_FAMILY17_MSRS[MSRCount].Name;
                          SubItems.Add(IntToHex(OutputBuf.EDXReg, 8) +
                                       ':' +
                                       IntToHex(OutputBuf.EAXReg, 8));
                        end;
                      except
                        with Add do
                        begin
                          Caption := IntToHex(AMD_FAMILY17_MSRS[MSRCount].MSR_ID, 8) +
                                     'h - ' +
                                     AMD_FAMILY17_MSRS[MSRCount].Name;
                          SubItems.Add('nicht auslesbar');
                        end;
                      end;
                    end;
              $19 : for MSRCount := 0 to AMD_FAMILY19_MSRS_CONST - 1 do {AMD Family 19h}
                    begin
                      try
                        InputBuf.ECXReg := AMD_FAMILY19_MSRS[MSRCount].MSR_ID;
                        if SystemAccessClass.Driver_ReadMSR(InputBuf, OutputBuf) then
                        with Add do
                        begin
                          Caption := IntToHex(AMD_FAMILY19_MSRS[MSRCount].MSR_ID, 8) +
                                     'h - ' +
                                     AMD_FAMILY19_MSRS[MSRCount].Name;
                          SubItems.Add(IntToHex(OutputBuf.EDXReg, 8) +
                                       ':' +
                                       IntToHex(OutputBuf.EAXReg, 8));
                        end;
                      except
                        with Add do
                        begin
                          Caption := IntToHex(AMD_FAMILY19_MSRS[MSRCount].MSR_ID, 8) +
                                     'h - ' +
                                     AMD_FAMILY19_MSRS[MSRCount].Name;
                          SubItems.Add('nicht auslesbar');
                        end;
                      end;
                    end;
            end;
          end;
        end;
      end
      else
      begin
        with Add do
        begin
          Caption := 'Keine MSR-Details auslesbar';
          SubItems.Add('Bitte Kernelmodus-Treiber laden');
        end;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TPCAnalyserForm.DisplayPCIDevices;
var
  PCICount : Integer;
  PCIBusSystem : String;
  ByteValue,
  CapPos, CapID : Byte;
  PCIStat : Array [1..3] of Byte;

  procedure AddPCIBusSystem(BusSystem : String);
  begin
    if PCIBusSystem = '' then
      PCIBusSystem := BusSystem else
    if Pos(BusSystem, PCIBusSystem) = 0 then
      PCIBusSystem := PCIBusSystem + ', ' + BusSystem;
  end;

begin
  if SystemAccessClass.PCIBusClass.PCIDeviceCount = 0 then
    SystemAccessClass.PCIBusClass.DetectPCIDevices;

  SystemAccessClass.PCIBusClass.GetSMBusBaseAddress;

  with ResultsListView, Items do
  begin
    BeginUpdate;
    try
      Clear;

      if SystemAccessClass.PCIBusClass.PCIDeviceCount > 0 then
      begin
        PCIBusSystem := 'PCI';

        for PCICount := 0 to SystemAccessClass.PCIBusClass.PCIDeviceCount - 1 do
        begin
          if SystemAccessClass.PCIBusClass.IsBitOn(
               SystemAccessClass.PCIBusClass.FPCIDevices[PCICount].PCIContent[$04],
               4) then
          begin
            case SystemAccessClass.PCIBusClass.FPCIDevices[PCICount].PCIContent[$0E] and $7F of
              0  : ByteValue := SystemAccessClass.PCIBusClass.FPCIDevices[PCICount].PCIContent[$34];
              1  : ByteValue := SystemAccessClass.PCIBusClass.FPCIDevices[PCICount].PCIContent[$34];
              2  : ByteValue := SystemAccessClass.PCIBusClass.FPCIDevices[PCICount].PCIContent[$14];
              else ByteValue := 0;
            end;
          end else
            ByteValue := 0;

          if ByteValue > 0 then
          repeat
            CapPos := ByteValue;
            CapID := SystemAccessClass.PCIBusClass.FPCIDevices[PCICount].PCIContent[CapPos + 0];
            ByteValue := SystemAccessClass.PCIBusClass.FPCIDevices[PCICount].PCIContent[CapPos + 1];

            case CapID of
              $00 : ; {Reserved}
              $01 : ; {PCI Power Management Interface}
              $02 : begin {AGP - Accelerated Graphics Port}
                      AddPCIBusSystem('AGP ' +
                      IntToStr(
                        (SystemAccessClass.PCIBusClass.FPCIDevices[PCICount].PCIContent[CapPos + 2] shr 4) and 15) +
                        '.' +
                        IntToStr(SystemAccessClass.PCIBusClass.FPCIDevices[PCICount].PCIContent[CapPos + 2] and 15));
                    end;
              $03 : ; {VPD - Virtual Product Data}
              $04 : ; {Slot Identification}
              $05 : ; {Message Signaled Interrupts}
              $06 : begin {CompactPCI - Hot Swap}
                      AddPCIBusSystem('CompactPCI');
                    end;
              $07 : begin {PCI-X}
                      AddPCIBusSystem('PCI-X');
                    end;
              $08 : ; {HyperTransport}
              $09 : ; {Vendor Specific}
              $0A : ; {Debug Port}
              $0B : begin {CompactPCI - Central Resource Control}
                      AddPCIBusSystem('CompactPCI');
                    end;
              $0C : ; {PCI Hot-Plug}
              $0D : ; {Subsystem ID & Subsystem Vendor ID}
              $0E : begin {AGP 8x - Accelerated Graphics Port}
                      AddPCIBusSystem('AGP');
                    end;
              $0F : ; {Secure Device}
              $10 : begin {PCI Express}
                      AddPCIBusSystem('PCI Express');
                    end;
              $11 : ; {MSI-X - Message Signaled Interrupts Extension}
              $12 : ; {SATA HBA Optional Features}
              $13 : ; {Function Level Reset (FLR) will utilize the standard capability structure with unique capability ID assigned by PCISIG.}
            end;
          until ByteValue = 0;
        end;

        for PCICount := 1 to 3 do PCIStat[PCICount] := 0;
        for PCICount := 0 to SystemAccessClass.PCIBusClass.PCIDeviceCount - 1 do
        begin
          if SystemAccessClass.PCIBusClass.IsBitOn(
            SystemAccessClass.PCIBusClass.FPCIDevices[PCICount].PCIContent[$0E], 7) then
            Inc(PCIStat[1], 1);

          case (SystemAccessClass.PCIBusClass.FPCIDevices[PCICount].PCIContent[$0E] shr 1) and $7F of
            1 : Inc(PCIStat[2], 1);
            2 : Inc(PCIStat[3], 1);
          end;
        end;

        with Add do
        begin
          Caption := 'Bus-System(e)';
          SubItems.Add(PCIBusSystem);
        end;

        with Add do
        begin
          Caption := 'Gesamtgerät(e)';
          SubItems.Add(IntToStr(SystemAccessClass.PCIBusClass.PCIDeviceCount));
        end;

        with Add do
        begin
          Caption := 'Multifunktionsgerät(e)';
          SubItems.Add(IntToStr(PCIStat[1]));
        end;

        with Add do
        begin
          Caption := 'PCI-zu-PCI-Gerät(e)';
          SubItems.Add(IntToStr(PCIStat[2]));
        end;

        with Add do
        begin
          Caption := 'PCI-zu-CardBus-Gerät(e)';
          SubItems.Add(IntToStr(PCIStat[3]));
        end;
      end else
      begin
        with Add do
        begin
          Caption := 'Keine PCI-Bus-Details auslesbar';
          SubItems.Add('Bitte Kernelmodus-Treiber laden');
        end;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TPCAnalyserForm.DisplayPCIDevice(AIndex: Integer);
var
  StringValue : String;
  DumpCnt : Byte;
  WordValue : Word;
begin
  if SystemAccessClass.PCIBusClass.PCIDeviceCount = 0 then
    SystemAccessClass.PCIBusClass.DetectPCIDevices;

  with ResultsListView, Items do
  begin
    BeginUpdate;
    try
      Clear;

      if (SystemAccessClass.PCIBusClass.PCIDeviceCount > 0) and
         (AIndex <= SystemAccessClass.PCIBusClass.PCIDeviceCount) then
      begin
        with Add do
          Caption := 'Geräte-Identifikation';

        with Add do
        begin
          Caption := 'Hersteller-Kennung';
          SubItems.Add(
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].VendorID, 4) +
            'h');
        end;

        with Add do
        begin
          Caption := 'Hersteller-Name';
          StringValue := SystemAccessClass.PCIBusClass.GetVendorString(
                           SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].VendorID);
          if StringValue = '' then
            StringValue := 'unbekannt';
          SubItems.Add(StringValue);
        end;

        with Add do
        begin
          Caption := 'Geräte-Kennung';
          SubItems.Add(
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].DeviceID, 4) +
            'h');
        end;

        with Add do
        begin
          Caption := 'Geräte-Name';
          StringValue := SystemAccessClass.PCIBusClass.GetDeviceString(
                           SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].VendorID,
                           SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].DeviceID,
                           SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].Rev);
          if StringValue = '' then
            StringValue := 'unbekannt';
          SubItems.Add(StringValue);
        end;

        with Add do
        begin
          Caption := 'Unterhersteller-Kennung';
          SubItems.Add(
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].SubVendorID, 4) +
            'h');
        end;

        with Add do
        begin
          Caption := 'Unterhersteller-Name';
          StringValue := SystemAccessClass.PCIBusClass.GetVendorString(
                           SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].SubVendorID);
          if StringValue = '' then
            StringValue := 'unbekannt';
          SubItems.Add(StringValue);
        end;

        with Add do
        begin
          Caption := 'Untergeräte-Kennung';
          SubItems.Add(
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].SubDeviceID, 4) +
            'h');
        end;

        with Add do
        begin
          Caption := 'Untergeräte-Name';
          StringValue := SystemAccessClass.PCIBusClass.GetSubDeviceString(
                           SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].VendorID,
                           SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].DeviceID,
                           SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].Rev,
                           SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].SubVendorID,
                           SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].SubDeviceID);
          if StringValue = '' then
            StringValue := 'unbekannt';
          SubItems.Add(StringValue);
        end;

        with Add do
          Caption := '';

        with Add do
        begin
          Caption := 'Revision';
          SubItems.Add(
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].Rev) + 'h');
        end;

        with Add do
        begin
          Caption := 'Bus / Geräte-Nummer / Funktion';
          SubItems.Add(
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].Bus) + 'h /' +
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].Dev) + 'h /' +
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].Func) + 'h');
        end;

        with Add do
        begin
          Caption := 'Kopfbereich-Typ';

          case (SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[$0E] shr 1) and $7F of
            0  : StringValue := 'Standard';
            1  : StringValue := 'PCI-zu-PCI';
            2  : StringValue := 'PCI-zu-CardBus';
            else StringValue := 'unbekannt';
          end;;
          SubItems.Add(StringValue);
        end;

        with Add do
        begin
          Caption := 'Multifunktionsgerät';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.YesNo(
            SystemAccessClass.PCIBusClass.IsBitOn(
            SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[$0E], 7)));
        end;

        with Add do
          Caption := '';

        with Add do
          Caption := 'Geräte-Typ';

        with Add do
        begin
          Caption := 'Basis-Klasse';
          SubItems.Add(
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].ClassID) +
            'h (' + SystemAccessClass.PCIBusClass.GetBaseClassName(AIndex) +
            ')');
        end;

        with Add do
        begin
          Caption := 'Unterklasse';
          SubItems.Add(
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].SubClassID) +
            'h (' + SystemAccessClass.PCIBusClass.GetSubClassName(AIndex) +
            ')');
        end;

        with Add do
        begin
          Caption := 'Schnittstelle';
          SubItems.Add(
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PrgInt) +
            'h');
        end;

        with Add do
          Caption := '';

        with Add do
          Caption := 'Geräte-Kontrolle';

        WordValue := MakeWord(
                     SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[$04],
                     SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[$05]);

        with Add do
        begin
          Caption := 'Interrupt inaktiv';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.ActiveInactive(
            not SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 10)));
        end;

        with Add do
        begin
          Caption := 'Schneller Back-to-Back aktiv';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.ActiveInactive(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 9)));
        end;

        with Add do
        begin
          Caption := 'SERR# aktiv';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.ActiveInactive(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 8)));
        end;

        with Add do
        begin
          Caption := 'Kontrolle für Wartezyklus';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.ActiveInactive(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 7)));
        end;

        with Add do
        begin
          Caption := 'Paritätsfehler aufgetreten';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.YesNo(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 6)));
        end;

        with Add do
        begin
          Caption := 'VGA-Funktion Paletten-Snoop aktiv';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.ActiveInactive(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 5)));
        end;

        with Add do
        begin
          Caption := 'Schreibzugriff mit Invalidierung aktiv';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.YesNo(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 4)));
        end;

        with Add do
        begin
          Caption := 'Spezialzyklen';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.YesNo(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 3)));
        end;

        with Add do
        begin
          Caption := 'Bus Master aktiv';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.YesNo(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 2)));
        end;

        with Add do
        begin
          Caption := 'Zugriff auf Speicherbereich aktiv';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.YesNo(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 1)));
        end;

        with Add do
        begin
          Caption := 'Zugriff auf EA-Bereich aktiv';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.YesNo(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 0)));
        end;

        with Add do
          Caption := '';

        with Add do
          Caption := 'Geräte-Status';

        WordValue := MakeWord(
                     SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[$06],
                     SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[$07]);

        with Add do
        begin
          Caption := 'Interrupt-Status';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.YesNo(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 3)));
        end;

        with Add do
        begin
          Caption := 'Fähigkeiten-Liste';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.YesNo(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 4)));
        end;

        with Add do
        begin
          Caption := 'Unterstützung für 66 MHz';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.YesNo(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 5)));
        end;

        with Add do
        begin
          Caption := 'Unterstützung für schnelles Back-to-Back';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.YesNo(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 7)));
        end;

        with Add do
        begin
          Caption := 'Paritätsfehler bei Bus-Master-Gerät';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.YesNo(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 8)));
        end;

        with Add do
        begin
          Caption := 'Geschwindigkeit für aktuelles Gerät';

          case ((WordValue shr 9) and 3) of
            0 :  StringValue := 'schnell';
            1 :  StringValue := 'mittel';
            2 :  StringValue := 'langsam';
            else StringValue := 'unbekannt';
          end;
          SubItems.Add(StringValue);
        end;

        with Add do
        begin
          Caption := 'Signalisierter Ziel-Abbruch';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.YesNo(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 11)));
        end;

        with Add do
        begin
          Caption := 'Empfangener Ziel-Abbruch';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.YesNo(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 12)));
        end;

        with Add do
        begin
          Caption := 'Empfangener Master-Abbruch';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.YesNo(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 13)));
        end;

        with Add do
        begin
          Caption := 'Signalisierter Systemfehler';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.YesNo(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 14)));
        end;

        with Add do
        begin
          Caption := 'Erkannter Paritätsfehler';
          SubItems.Add(
            SystemAccessClass.PCIBusClass.YesNo(
            SystemAccessClass.PCIBusClass.IsBitOn(
            WordValue, 15)));
        end;

        with Add do
          Caption := '';

        with Add do
          Caption := 'Gerätedump';

        for DumpCnt := 1 to 16 do
        begin
          with Add do
          begin
            Caption := 'Offset ' +
                       IntToHex((DumpCnt * 16) - 16, 2) +
                       ' - ' +
                       IntToHex((DumpCnt * 16) - 1, 2);

            StringValue :=
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[(DumpCnt * 16) - 16], 2) + ' ' +
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[(DumpCnt * 16) - 15], 2) + ' ' +
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[(DumpCnt * 16) - 14], 2) + ' ' +
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[(DumpCnt * 16) - 13], 2) + ' ' +
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[(DumpCnt * 16) - 12], 2) + ' ' +
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[(DumpCnt * 16) - 11], 2) + ' ' +
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[(DumpCnt * 16) - 10], 2) + ' ' +
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[(DumpCnt * 16) - 9], 2) + ' ' +
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[(DumpCnt * 16) - 8], 2) + ' ' +
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[(DumpCnt * 16) - 7], 2) + ' ' +
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[(DumpCnt * 16) - 6], 2) + ' ' +
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[(DumpCnt * 16) - 5], 2) + ' ' +
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[(DumpCnt * 16) - 4], 2) + ' ' +
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[(DumpCnt * 16) - 3], 2) + ' ' +
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[(DumpCnt * 16) - 2], 2) + ' ' +
            IntToHex(SystemAccessClass.PCIBusClass.FPCIDevices[AIndex].PCIContent[(DumpCnt * 16) - 1], 2);

            SubItems.Add(StringValue);
          end;
        end;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TPCAnalyserForm.DisplaySMBus_MemoryDevices;
var
  ModuleCounter,
  ModuleNumber,
  ModulesTotal : Byte;
begin
  with ResultsListView, Items do
  begin
    BeginUpdate;
    try
      Clear;

      with Add do
      begin
        Caption := 'SMBUS-Basisadresse';
        SubItems.Add(IntToHex(SystemAccessClass.SMBusClass.SMBusBaseAddress) + 'h');
      end;

      with Add do
      begin
        Caption := 'SMBUS-Kontroller';
        SubItems.Add(SystemAccessClass.SMBusClass.SMBusControllerName);
      end;

      if SystemAccessClass.SMBusClass.IsIntel_SPDWD then
        with Add do
        begin
          Caption := 'SPD Write Disable (SPDWD)';
          SubItems.Add('aktiv');
        end;

      with Add do
        Caption := '';

      ModulesTotal := 0;
      for ModuleCounter := 0 to 7 do
        if SystemAccessClass.SMBusClass.MemoryDevices[ModuleCounter] <> 0 then
          Inc(ModulesTotal);
      with Add do
      begin
        Caption := 'Anzahl Speichermodule';
        SubItems.Add(IntToStr(ModulesTotal));
      end;

      ModuleNumber := 0;
      for ModuleCounter := 0 to 7 do
        if SystemAccessClass.SMBusClass.MemoryDevices[ModuleCounter] <> 0 then
        begin
          Inc(ModuleNumber);
          with Add do
          begin
            Caption := 'Modul ' + IntToStr(ModuleNumber) + ' bei Adresse';
            SubItems.Add(IntToHex(
              SystemAccessClass.SMBusClass.MemoryDevices[ModuleCounter]) + 'h');
          end;
        end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TPCAnalyserForm.DisplaySMBus_MemoryDevice(AIndex: Integer);
var
  SPDDetail : TStrings;
  SPDCnt : Integer;
begin
  SPDDetail := TStringList.Create;
  try
    Screen.Cursor := crHourGlass;
    SystemAccessClass.SMBusClass.GetSPDDetails(AIndex, SPDDetail);
    Screen.Cursor := crDefault;

    with ResultsListView, Items do
    begin
      BeginUpdate;
      try
        Clear;

        if SPDDetail.Count > 0 then
        begin
          for SPDCnt := 0 to SPDDetail.Count - 1 do
            with Add do
            begin
              Caption :=
                SystemAccessClass.SMBusClass.
                GetNameFromStr(SPDDetail.Strings[SPDCnt], '=');
              SubItems.Add(
                SystemAccessClass.SMBusClass.
                GetValueFromStr(SPDDetail.Strings[SPDCnt], '='));
            end;
        end else
        begin
          with Add do
            Caption := 'Keine Speichermodul-Details ermittelbar';
        end;

      finally
        EndUpdate;
      end;
    end;
  finally
    SPDDetail.Free;
  end;
end;

procedure TPCAnalyserForm.DisplayNodeInfo;
var
  Node : TTreeNode;
begin
  with ResultsListView, Items do
  begin
    BeginUpdate;
    try
      Clear;

      with Add do
      begin
        Caption := 'Anzahl der Knoten';
        SubItems.Add(Format('%d',[CategoryTreeView.Selected.Count]));
      end;

      Node := CategoryTreeView.Selected.GetFirstChild;
      while Assigned(Node) do
      begin
        with Add do
          Caption := Node.Text;

        if Node = CategoryTreeView.Selected.GetLastChild then
          Break;
        Node := Node.GetNextSibling;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TPCAnalyserForm.DisplayMachineInfo;
var
  LastBoot : TDateTime;
  SystemUpTime : Int64;
  KeyState : TKeyboardState;
begin
  with ResultsListView, Items do
  begin
    BeginUpdate;
    try
      Clear;

      with Add do
      begin
        Caption := 'Maschinenname';
        SubItems.Add(SystemAccessClass.GetCurrentComputerName);
      end;

      with Add do
      begin
        Caption := 'Benutzername';
        SubItems.Add(SystemAccessClass.GetCurrentUserName);
      end;

      with Add do
      begin
        Caption := 'Administrator';
        if SystemAccessClass.IsAdmin then
          SubItems.Add('ja')
        else
          SubItems.Add('nein')
      end;

      with Add do
      begin
        Caption := 'Benutzerkontext';
        if SystemAccessClass.IsElevated then
          SubItems.Add('erweitert')
        else
          SubItems.Add('eingeschränkt')
      end;

      with Add do
      begin
        Caption := 'Letzter Startvorgang';
        try
          LastBoot := Now - (GetTickCount64 / 1000) / (24 * 3600);
        except
          LastBoot := 0;
        end;

        if LastBoot <> 0 then
          SubItems.Add(DateTimeToStr(LastBoot))
        else
          SubItems.Add('unbekannt')
      end;

      with Add do
      begin
        Caption := 'Systembetriebszeit';
        try
          SystemUpTime := Round(GetTickCount64 / 1000);
        except
          SystemUpTime := 0;
        end;
        if LastBoot <> 0 then
          SubItems.Add(FormatSeconds(SystemUpTime))
        else
          SubItems.Add('unbekannt')
      end;

      GetKeyboardState(KeyState);
      with Add do
      begin
        Caption := 'Caps Lock';
        if KeyState[VK_CAPITAL] = 1 then
          SubItems.Add('ja')
        else
          SubItems.Add('nein');
      end;

      with Add do
      begin
        Caption := 'Num Lock';
        if KeyState[VK_NUMLOCK] = 1 then
          SubItems.Add('ja')
        else
          SubItems.Add('nein');
      end;

      with Add do
      begin
        Caption := 'Scroll Lock';
        if KeyState[VK_SCROLL] = 1 then
          SubItems.Add('ja')
        else
          SubItems.Add('nein');
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TPCAnalyserForm.DisplayWindowsDetails;
var
  Major,
  Minor,
  Build : Cardinal;
begin
  with ResultsListView, Items do
  begin
    BeginUpdate;
    try
      Clear;

      with Add do
      begin
        Caption := 'Windows-Name';
        SubItems.Add(SystemAccessClass.WindowsClass.GetTrueWindowsName);
      end;

      with Add do
      begin
        Caption := 'Windows-Version';
        SubItems.Add(SystemAccessClass.WindowsClass.GetTrueWindowsVersion(Major, Minor, Build));
      end;

      with Add do
      begin
        Caption := 'Service Pack';
        SubItems.Add(SystemAccessClass.WindowsClass.GetServicePack);
      end;

      with Add do
      begin
        Caption := 'Codename';
        SubItems.Add(SystemAccessClass.WindowsClass.GetWindowsCodename);
      end;

      with Add do
      begin
        Caption := 'Kompatibilitätsmodus';
        if not SystemAccessClass.WindowsClass.IsWindowsCompatibilityMode then
          SubItems.Add('deaktiviert')
        else
          SubItems.Add(SystemAccessClass.WindowsClass.GetWindowsCompatibilityMode);
      end;

      with Add do
      begin
        Caption := 'Installationszeitpunkt';
        if SystemAccessClass.WindowsClass.GetWindowsInstallDate <> 0 then
          SubItems.Add(DateTimeToStr(SystemAccessClass.WindowsClass.GetWindowsInstallDate))
        else
          SubItems.Add('unbekannt');
      end;

      with Add do
      begin
        Caption := 'Windows-Verzeichnis';
        SubItems.Add(SystemAccessClass.WindowsClass.GetWindowsDir);
      end;

      with Add do
      begin
        Caption := 'System-Verzeichnis';
        SubItems.Add(SystemAccessClass.WindowsClass.GetSystemDir);
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TPCAnalyserForm.DisplaySoftwareInstalled;
var
  SoftwareCounter : Integer;
begin
  with ResultsListView, Items do
  begin
    BeginUpdate;
    try
      Clear;

      SystemAccessClass.WindowsClass.SWList :=
        SystemAccessClass.WindowsClass.DetectInstalledSoftware;

      if High(SystemAccessClass.WindowsClass.SWList) > 0 then
      begin
        ResultsListView.SortType := stText;
        for SoftwareCounter := 0 to High(SystemAccessClass.WindowsClass.SWList) do
          with Add do
          begin
            Caption :=
              SystemAccessClass.
              WindowsClass.
              SWList[SoftwareCounter].Name;
            if SystemAccessClass.
               WindowsClass.
               SWList[SoftwareCounter].Version <> '' then
              SubItems.Add(SystemAccessClass.
                           WindowsClass.
                           SWList[SoftwareCounter].Version)
            else
              SubItems.Add('-');
          end;
      end
      else
        Caption := 'Keine Software gefunden';
    finally
      ResultsListView.SortType := stNone;
      EndUpdate;
    end;
  end;
end;

procedure TPCAnalyserForm.DisplayWindowsDirectories;
var
  DirectoryList : TStrings;
  DirectoryCount : Integer;
begin
  DirectoryList := TStringList.Create;

  try
    DirectoryList := SystemAccessClass.WindowsClass.GetWindowsDirectories;

    with ResultsListView, Items do
    begin
      BeginUpdate;
      try
        Clear;

        if DirectoryList.Count > 0 then
          for DirectoryCount := 0 to DirectoryList.Count - 1 do
          begin
            with Add do
            begin
              Caption :=
                  SystemAccessClass.WindowsClass.
                  GetNameFromStr(DirectoryList.Strings[DirectoryCount], '=');
              if SystemAccessClass.WindowsClass.
                 GetValueFromStr(DirectoryList.Strings[DirectoryCount]) <> '' then
                SubItems.Add(
                    SystemAccessClass.WindowsClass.
                    GetValueFromStr(DirectoryList.Strings[DirectoryCount], '='))
              else
                SubItems.Add('-');
            end;
          end else
          begin
            with Add do
              Caption := 'Keine Verzeichnisse ermittelbar';
          end;
      finally
        EndUpdate;
      end;
    end;
  finally
    DirectoryList.Free;
  end;
end;

procedure TPCAnalyserForm.DisplayEnvVariables;
var
  EnvVars : TStrings;
  EnvCnt : Integer;
begin
  EnvVars := TStringList.Create;
  try
    SystemAccessClass.WindowsClass.GetEnvironmentVariables(EnvVars);

    with ResultsListView, Items do
    begin
      BeginUpdate;
      try
        Clear;

          if EnvVars.Count > 0 then
          begin
            for EnvCnt := 0 to EnvVars.Count - 1 do
              with Add do
              begin
                Caption :=
                  SystemAccessClass.WindowsClass.
                  GetNameFromStr(EnvVars.Strings[EnvCnt], '=');
                SubItems.Add(
                  SystemAccessClass.WindowsClass.
                  GetValueFromStr(EnvVars.Strings[EnvCnt], '='));
              end;
          end else
          begin
            with Add do
              Caption := 'Keine Umgebungsvariablen ermittelbar';
          end;

      finally
        EndUpdate;
      end;
    end;
  finally
    EnvVars.Free;
  end;
end;

procedure TPCAnalyserForm.KernelModeDriverTimer(Sender: TObject);
var
  DrvStatus : Integer;
  VerData : VersionOutputStruct;
  VerText : String;
begin
  //Kernelmodus-Treiber Details ermitteln
  DrvStatus := SystemAccessClass.GetKernelModeDriverStatus(SystemAccessClass.DriverName);
  case DrvStatus of
    SERVICE_STOPPED          : DriverNameStaticTextResult.Caption := 'gestoppt';
    SERVICE_START_PENDING    : DriverNameStaticTextResult.Caption := 'wird gestartet';
    SERVICE_STOP_PENDING     : DriverNameStaticTextResult.Caption := 'wird gestoppt';
    SERVICE_RUNNING          : DriverNameStaticTextResult.Caption := 'installiert && gestartet';
    SERVICE_CONTINUE_PENDING : DriverNameStaticTextResult.Caption := 'wird fortgesetzt';
    SERVICE_PAUSE_PENDING    : DriverNameStaticTextResult.Caption := 'wird pausiert';
    SERVICE_PAUSED           : DriverNameStaticTextResult.Caption := 'pausiert';
    else                       DriverNameStaticTextResult.Caption := 'nicht installiert';
  end;

  if DrvStatus in [SERVICE_STOPPED,
                   SERVICE_START_PENDING,
                   SERVICE_STOP_PENDING,
                   SERVICE_RUNNING,
                   SERVICE_CONTINUE_PENDING,
                   SERVICE_PAUSE_PENDING,
                   SERVICE_PAUSED] then
  begin
    if SystemAccessClass.Driver_GetVersion(VerData) then
    begin
      //Version Hi.Lo
      VerText := 'V' + IntToHex((VerData.Version shr 16) and $FF, 1) +
                 '.' +
                 IntToHex((VerData.Version shr 08) and $FF, 2);

      //Datum
      VerText := VerText + ' vom ' +
                 IntToHex((VerData.Date shr 24) and $FF, 2) +
                 '.' +
                 IntToHex((VerData.Date shr 16) and $FF, 2) +
                 '.' +
                 IntToHex((VerData.Date shr 00) and $FFFF, 4);

      DriverDetailsStaticTextResult.Caption := VerText;
    end
    else
      DriverDetailsStaticTextResult.Caption := 'keine Details verfügbar';
  end
  else
    DriverDetailsStaticTextResult.Caption := 'nicht verfügbar';

  //Schalterstatus für Kernelmodus-Treiber ermitteln
  CheckKernelDriverButtonState;
end;

procedure TPCAnalyserForm.LoadDriverButtonClick(Sender: TObject);
var
  LastErrorCode : Integer;
begin
  if SystemAccessClass.DriverFileName <> '' then
  begin
    KernelModeDriverOpenDialog.Title:='Kernelmodus-Treiber auswählen...';
    KernelModeDriverOpenDialog.Filter:='Kernelmodus-Treiberdatei|'+SystemAccessClass.DriverFileName;
    KernelModeDriverOpenDialog.DefaultExt := 'sys';
    KernelModeDriverOpenDialog.FilterIndex := 1;
    KernelModeDriverOpenDialog.FileName := '';
    KernelModeDriverOpenDialog.InitialDir := GetCurrentDir;
    KernelModeDriverOpenDialog.Options := [ofPathMustExist, ofFileMustExist];
    if KernelModeDriverOpenDialog.Execute then
    begin
      SystemAccessClass.DriverFullPath := KernelModeDriverOpenDialog.FileName;
      if FileExists(KernelModeDriverOpenDialog.FileName) then
      begin
        if SystemAccessClass.InstallKernelModeDriver(SystemAccessClass.DriverName,
                                                     SystemAccessClass.DriverFullPath,
                                                     LastErrorCode) then
        begin
          AddLog('Code ' + IntToStr(LastErrorCode) + ': ' +
                 SysErrorMessage(LastErrorCode),
                 True);

          if not SystemAccessClass.StartKernelModeDriver(SystemAccessClass.DriverName, LastErrorCode) then
          begin
            ShowMessage('Die Treiberdatei ' +
                        SystemAccessClass.DriverFullPath +
                        ' kann nicht gestartet werden.');
            AddLog('Die Treiberdatei ' +
                   SystemAccessClass.DriverFullPath +
                   ' kann nicht gestartet werden',
                   True);
            AddLog('Code ' + IntToStr(LastErrorCode) + ': ' +
                   SysErrorMessage(LastErrorCode),
                   True);
          end;
        end else
        begin
          ShowMessage('Die Treiberdatei ' +
                      SystemAccessClass.DriverFullPath +
                      ' kann nicht installiert werden.');
          AddLog('Die Treiberdatei ' +
                 SystemAccessClass.DriverFullPath +
                 ' kann nicht installiert werden',
                 True);
          AddLog('Code ' + IntToStr(LastErrorCode) + ': ' +
                 SysErrorMessage(LastErrorCode),
                 True);
        end;
      end
      else
      begin
        ShowMessage('Die Treiberdatei ' +
                    SystemAccessClass.DriverFullPath +
                    ' existiert nicht.');
        AddLog('Die Treiberdatei ' +
               SystemAccessClass.DriverFullPath +
               ' existiert nicht',
               True);
      end;
    end;
  end
  else
  begin
    ShowMessage('Es wurde kein Treibername spezifiziert.');
    AddLog('Es wurde kein Treibername spezifiziert.', True);
  end;
  KernelModeDriverTimer(Sender);

  CategoryTreeView.Items.Clear;
  CreateCategoryTree;
end;

procedure TPCAnalyserForm.UnloadDriverButtonClick(Sender: TObject);
var
  LastErrorCode : Integer;
begin
  if SystemAccessClass.DriverFileName <> '' then
  begin
    if SystemAccessClass.GetKernelModeDriverStatus(SystemAccessClass.DriverName) = SERVICE_RUNNING then
    begin
      if not SystemAccessClass.StopKernelModeDriver(SystemAccessClass.DriverName, LastErrorCode) then
      begin
        ShowMessage('Die Treiberdatei ' +
                    SystemAccessClass.DriverFullPath +
                    ' kann nicht gestoppt werden.');
        AddLog('Die Treiberdatei ' +
               SystemAccessClass.DriverFullPath +
               ' kann nicht gestoppt werden',
               True);
        AddLog('Code ' + IntToStr(LastErrorCode) + ': ' +
               SysErrorMessage(LastErrorCode),
               True);
      end
      else
        AddLog('Code ' + IntToStr(LastErrorCode) + ': ' +
                 SysErrorMessage(LastErrorCode),
                 True);
    end;
    if SystemAccessClass.GetKernelModeDriverStatus(SystemAccessClass.DriverName) = SERVICE_STOPPED then
    begin
      if not SystemAccessClass.RemoveKernelModeDriver(SystemAccessClass.DriverName, LastErrorCode) then
      begin
        ShowMessage('Die Treiberdatei ' +
                    SystemAccessClass.DriverFullPath +
                    ' kann nicht entfernt werden.');
        AddLog('Die Treiberdatei ' +
               SystemAccessClass.DriverFullPath +
               ' kann nicht entfernt werden',
               True);
        AddLog('Code ' + IntToStr(LastErrorCode) + ': ' +
               SysErrorMessage(LastErrorCode),
               True);
      end
      else
        AddLog('Code ' + IntToStr(LastErrorCode) + ': ' +
               SysErrorMessage(LastErrorCode),
               True);
    end;
  end;
  KernelModeDriverTimer(Sender);
end;

end.
