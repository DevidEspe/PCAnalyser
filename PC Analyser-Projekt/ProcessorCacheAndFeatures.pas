unit ProcessorCacheAndFeatures;

interface

uses
  WinAPI.Windows, System.Classes, System.SysUtils, System.Math;

type
  TCacheAssociativity = (caNone, caDirect, ca2Way, ca4Way, ca8Way, ca12Way, ca16Way, caFull, ca6Way, ca24way);

  TCacheDescriptors = Array [1..16] of Cardinal;

  TLogicalProcessorRelationship = (
    RelationProcessorCore = 0,
    RelationNumaNode = 1,
    RelationCache = 2,
    RelationProcessorPackage = 3,
    RelationGroup = 4,
    RelationAll = $FFFF
  );

  TProcessorCacheType = (
    CacheUnified,
    CacheInstruction,
    CacheData,
    CacheTrace
  );

  TCacheDescriptor = record
    Level,
    Associativity : Byte;
    LineSize : Word;
    Size : DWord;
    &Type : TProcessorCacheType;
  end;

  PSystemLogicalProcessorInformation = ^TSystemLogicalProcessorInformation;
  TSystemLogicalProcessorInformation = record
    ProcessorMask : ULong_PTR;
    Relationship : TLogicalProcessorRelationship;
    case Integer of
      0 : (Flags : Byte);
      1 : (NodeNumber : DWord);
      2 : (Cache : TCacheDescriptor);
      3 : (Reserved : array [0..1] of ULongLong);
  end;

  TGroupAffinity = record
    Mask : KAffinity;
    Group : word;
    Reserved : array [0..2] of Word;
  end;

  TProcessorRelationship = record
    Flags,
    EfficiencyClass : Byte;
    Reserved : array [0..19] of Byte;
    GroupCount : Word;
    GroupMask : array [0..0] of TGroupAffinity;
  end;

  TNUMANodeRelationship = record
    NodeNumber : Cardinal;
    Reserved : array [0..19] of Byte;
    GroupMask : TGroupAffinity;
  end;

  TCacheRelationship = record
    Level,
    Associativity : Byte;
    LineSize : Word;
    CacheSize : Cardinal;
    &Type : TProcessorCacheType;
    Reserved : array [0..19] of Byte;
    GroupMask : TGroupAffinity;
  end;

  TProcessorGroupInfo = record
    MaximumProcessorCount,
    ActiveProcessorCount : Byte;
    Reserved : array [0..37] of Byte;
    ActiveProcessorMask : KAffinity;
  end;

  TGroupRelationship = record
    MaximumGroupCount,
    ActiveGroupCount : Word;
    Reserved : Array [0..19] of Byte;
    GroupInfo : Array [0..0] of TProcessorGroupInfo;
  end;

  PSystemLogicalProcessorInformationEx = ^TSystemLogicalProcessorInformationEx;
  TSystemLogicalProcessorInformationEx = record
    Relationship : TLogicalProcessorRelationship;
    Size : DWord;
    case Integer of
      0 : (Processor : TProcessorRelationship);
      1 : (NumaNode : TNUMANodeRelationship);
      2 : (Cache : TCacheRelationship);
      3 : (Group : TGroupRelationship);
  end;

  TCacheDetails = record
    &Type : Byte;
    Desc : String;
    Associativity : TCacheAssociativity;
    Ways,
    Partitions,
    Size,
    Shared,
    LineSize,
    Level : Cardinal;
    Descriptors  : TCacheDescriptors;
  end;

  TCPUCacheDetails = class(TPersistent)
  private
    FLevel, FShared, FLineSize, FSize, FWays, FParts : Integer;
    FAssociativity : TCacheAssociativity;
    FDescriptors : TCacheDescriptors;
    FType : Byte;
    FDesc : string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetContent(AContent : TCacheDetails);
    procedure Clear;

    property Descriptors : TCacheDescriptors read FDescriptors;
  published
    property &Type : Byte read FType write FType;
    property Descriptor : String read FDesc write FDesc;
    property Associativity : TCacheAssociativity read FAssociativity write FAssociativity;
    property LineSize : Integer read FLineSize write FLineSize;
    property Size : Integer read FSize write FSize;
    property Ways : Integer read FWays write FWays;
    property Partitions : Integer read FParts write FParts;
    property Level : Integer read FLevel write FLevel;
    property SharedWays : Integer read FShared write FShared;
  end;

  TCPUSegmentedCache = class(TPersistent)
  private
    FData : TCPUCacheDetails;
    FUnified : TCPUCacheDetails;
    FCode : TCPUCacheDetails;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;

    procedure SetContent(ACode, AData, AUnified : TCacheDetails);
  published
    property Code : TCPUCacheDetails read FCode;
    property Data : TCPUCacheDetails read FData;
    property Unified : TCPUCacheDetails read FUnified;
  end;

  TCPUCache = class(TPersistent)
  private
    FLevel3 : TCPUCacheDetails;
    FLevel2 : TCPUCacheDetails;
    FLevel1 : TCPUSegmentedCache;
    FTrace : TCPUCacheDetails;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure AddData(AType : TProcessorCacheType; ALevel, AAssoc : Byte; ALineSize : Word; ASize : Cardinal);
    procedure SetContent(ALevel1Code, ALevel1data, ALevel1Unified, ALevel2, ALevel3, ATrace : TCacheDetails);
  published
    property Level1 : TCPUSegmentedCache read FLevel1;
    property Level2 : TCPUCacheDetails read FLevel2;
    property Level3 : TCPUCacheDetails read FLevel3;
    property Trace : TCPUCacheDetails read FTrace;
  end;

  TFeatureAvailability = (faCommon, faIntel, faAmd, faCyrix);

  TFeatureSet = (fsStandard, fsExtended, fsPowerManagement, fsSecureVirtualMachine);

  TExXRegister = (rEAX, rEBX, rECX, rEDX);

  TFeatureDefinition = record
    Func : Cardinal;
    ExX : TExXRegister;
    Index : Byte;
    FeatSet : TFeatureSet;
    Availability : TFeatureAvailability;
    Name : String;
    Desc : String;
  end;

  TCPUFeature = record
    Definition : TFeatureDefinition;
    Value : Boolean;
  end;

  TAvailableFeatures = array of TCPUFeature;

  TCPUFeatureSet = class(TPersistent)
  private
    FAF : TAvailableFeatures;
    function GetCount : Integer;
    function GetFeature(Index : Byte) : TCPUFeature;
    function GetFeatureByName(const AName : String) : TCPUFeature;
  public
    destructor Destroy; override;

    procedure SetContent(AAF : TAvailableFeatures);

    property Features[Index : Byte] : TCPUFeature read GetFeature;
    property FeaturesByName[const Name : String] : TCPUFeature read GetFeatureByName;
  published
    property Count : Integer read GetCount;
  end;

  TCPUFeatures = class(TPersistent)
  private
    FStd, FExt, FPM, FSVM : TCPUFeatureSet;
    function GetInstructions : String;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetContent(AStd, AExt, APM, ASVM : TAvailableFeatures);
  published
    property Standard : TCPUFeatureSet read FStd;
    property Extended : TCPUFeatureSet read FExt;
    property PowerManagement : TCPUFeatureSet read FPM;
    property SecureVirtualMachine : TCPUFeatureSet read FSVM;

    property Instructions : String read GetInstructions;
  end;

  function GetCPUClock(const ADelay: integer = 1000): double;
  procedure ResetMemory(out P; Size : Longint);

const
  cAssociativityInfo : Array[caNone..ca24way] of Byte = (0, 1, 2, 4, 6, 7, 8, 15, 6, 24);
  cAssociativityDescription : Array[caNone..ca24way] of String = ('Keine',   'Direkt',
                                                                  '2-fach',  '4-fach',
                                                                  '8-fach',  '12-fach',
                                                                  '16-fach', 'Voll',
                                                                  '6-fach',  '24-fach');

implementation

{ TCPUCacheDetails }

procedure TCPUCacheDetails.Clear;
begin
  FType := 0;
  FDesc := '';
  FAssociativity := caNone;
  FLinesize := 0;
  FSize := 0;
  ResetMemory(FDescriptors, SizeOf(FDescriptors));
  FWays := 0;
  FParts := 0;
  FLevel := 0;
  FShared := 0;
end;

constructor TCPUCacheDetails.Create;
begin
  inherited Create;
  FAssociativity := caNone;
  FLinesize := 0;
  FSize := 0;
  ResetMemory(FDescriptors, SizeOf(FDescriptors));
end;

destructor TCPUCacheDetails.Destroy;
begin
  inherited;
end;

procedure TCPUCacheDetails.SetContent(AContent : TCacheDetails);
begin
  FType := AContent.&Type;
  FDesc := AContent.Desc;
  FAssociativity := AContent.Associativity;
  FLinesize := AContent.Linesize;
  FSize := AContent.Size;
  FDescriptors := AContent.Descriptors;
  FWays := AContent.Ways;
  FParts := AContent.Partitions;
  FLevel := AContent.Level;
  FShared := AContent.Shared;
end;

{ TCPUSegmentedCache }

procedure TCPUSegmentedCache.Clear;
begin
  FCode.Clear;
  FData.Clear;
  FUnified.Clear;
end;

constructor TCPUSegmentedCache.Create;
begin
  inherited Create;
  FCode := TCPUCacheDetails.Create;
  FData := TCPUCacheDetails.Create;
  FUnified := TCPUCacheDetails.Create;
end;

destructor TCPUSegmentedCache.Destroy;
begin
  FCode.Free;
  FData.Free;
  FUnified.Free;
  inherited;
end;

procedure TCPUSegmentedCache.SetContent(ACode, AData, AUnified : TCacheDetails);
begin
  FCode.SetContent(ACode);
  FData.SetContent(AData);
  FUnified.SetContent(AUnified);
end;

{ TCPUCache }

procedure TCPUCache.AddData(AType : TProcessorCacheType; ALevel, AAssoc : Byte;
                            ALineSize : Word; ASize : Cardinal);
var
  a : TCacheAssociativity;
begin
  case AAssoc of
    2   : a := ca2Way;
    4   : a := ca4Way;
    6   : a := ca6Way;
    8   : a := ca8Way;
    12  : a := ca12Way;
    16  : a := ca16Way;
    24  : a := ca24way;
    $FF : a := caFull;
    else  a := caNone;
  end;
  if AType = CacheTrace then
  begin
    FTrace.FType := 1;
    Inc(FTrace.FShared);
    FTrace.FLevel := 1;
    FTrace.FSize := ASize;
    FTrace.FLineSize := ALineSize;
    FTrace.FAssociativity := a;
    FTrace.FDesc := Format('Trace %d KB, %s', [ASize, cAssociativityDescription[a]]);
  end else
  case ALevel of
    1 : case AType of
         CacheUnified : begin
           FLevel1.FUnified.FType := 1;
           Inc(FLevel1.FUnified.FShared);
           FLevel1.FUnified.FLevel := 1;
           FLevel1.FUnified.FSize := ASize;
           FLevel1.FUnified.FLineSize := ALineSize;
           FLevel1.FUnified.FAssociativity := a;
           FLevel1.FUnified.FDesc :=
           Format('L1 Instruktionen+Daten %d KB, %s', [ASize, cAssociativityDescription[a]]);
         end;
        CacheInstruction : begin
          FLevel1.FCode.FType := 1;
          FLevel1.FCode.FLevel := 1;
          Inc(FLevel1.FCode.FShared);
          FLevel1.FCode.FSize := ASize;
          FLevel1.FCode.FLineSize := ALineSize;
          FLevel1.FCode.FAssociativity := a;
          FLevel1.FCode.FDesc := Format('L1 Instruktionen %d KB, %s', [ASize, cAssociativityDescription[a]]);
        end;
        CacheData : begin
          FLevel1.FData.FType := 1;
          FLevel1.FData.FLevel := 1;
          Inc(FLevel1.FData.FShared);
          FLevel1.FData.FSize := ASize;
          FLevel1.FData.FLineSize := ALineSize;
          FLevel1.FData.FAssociativity := a;
          FLevel1.FData.FDesc := Format('L1 Daten %d KB, %s', [ASize, cAssociativityDescription[a]]);
        end;
    end;
    2 : begin
      FLevel2.FType := 1;
      Inc(FLevel2.FShared);
      FLevel2.FLevel := 2;
      FLevel2.FSize := ASize;
      FLevel2.FLineSize := ALineSize;
      FLevel2.FAssociativity := a;
      FLevel2.FDesc := Format('L2 %d KB, %s', [ASize, cAssociativityDescription[a]]);
    end;
    3 : begin
      FLevel3.FType := 1;
      Inc(FLevel3.FShared);
      FLevel3.FLevel := 3;
      FLevel3.FSize := ASize;
      FLevel3.FLineSize := ALineSize;
      FLevel3.FAssociativity := a;
      FLevel3.FDesc := Format('L3 %d KB, %s', [ASize, cAssociativityDescription[a]]);
    end;
  end;
end;

procedure TCPUCache.Clear;
begin
  FLevel1.Clear;
  FLevel2.Clear;
  FLevel3.Clear;
  FTrace.Clear;
end;

constructor TCPUCache.Create;
begin
  inherited Create;
  FLevel1 := TCPUSegmentedCache.Create;
  FLevel2 := TCPUCacheDetails.Create;
  FLevel3 := TCPUCacheDetails.Create;
  FTrace := TCPUCacheDetails.Create;
end;

destructor TCPUCache.Destroy;
begin
  FLevel1.Free;
  FLevel2.Free;
  FLevel3.Free;
  FTrace.Free;
  inherited;
end;

procedure TCPUCache.SetContent(ALevel1Code, ALevel1data, ALevel1Unified,
                               ALevel2, ALevel3, ATrace : TCacheDetails);
begin
  FLevel1.SetContent(ALevel1Code, ALevel1Data, ALevel1Unified);
  FLevel2.SetContent(Alevel2);
  FLevel3.SetContent(ALevel3);
  FTrace.SetContent(ATrace);
end;

{ TCPUFeatureSet }

destructor TCPUFeatureSet.Destroy;
begin
  Finalize(FAF);
  inherited;
end;

function TCPUFeatureSet.GetCount : Integer;
begin
  Result := Length(FAF);
end;

function TCPUFeatureSet.GetFeature;
begin
  Finalize(Result);
  try
    Result := FAF[Index]
  except
    ResetMemory(Result, SizeOf(Result));
  end;
end;

function TCPUFeatureSet.GetFeatureByName(const AName : String) : TCPUFeature;
var
  i : Integer;
begin
  ResetMemory(Result, SizeOf(Result));
  for i := 0 to High(FAF) do
    if SameText(FAF[i].Definition.Name, AName) then
    begin
      Result := FAF[i];
      Break;
    end;
end;

procedure TCPUFeatureSet.SetContent(AAF : TAvailableFeatures);
begin
  FAF := AAF;
end;

{ TCPUFeatures }

constructor TCPUFeatures.Create;
begin
  inherited Create;
  FStd := TCPUFeatureSet.Create;
  FExt := TCPUFeatureSet.Create;
  FPM := TCPUFeatureSet.Create;
  FSVM := TCPUFeatureSet.Create;
end;

destructor TCPUFeatures.Destroy;
begin
  FStd.Free;
  FExt.Free;
  FPM.Free;
  FSVM.Free;
  inherited;
end;

function TCPUFeatures.GetInstructions: string;
begin
  Result := '';
  if FStd.FeaturesByName['MMX+'].Value then
    Result := Result + 'MMX+, '
  else if FStd.FeaturesByName['MMX'].Value then
    Result := Result + 'MMX, ';
  if FStd.FeaturesByName['SSE'].Value then
    Result := Result + 'SSE, ';
  if FStd.FeaturesByName['SSE2'].Value then
    Result := Result + 'SSE2, ';
  if FStd.FeaturesByName['SSE3'].Value then
    Result := Result + 'SSE3, ';
  if FStd.FeaturesByName['SSSE3'].Value then
    Result := Result + 'SSSE3, ';
  if FStd.FeaturesByName['SSE4.1'].Value then
    Result := Result + 'SSE4.1, ';
  if FStd.FeaturesByName['SSE4.2'].Value then
    Result := Result + 'SSE4.2, ';
  if FExt.FeaturesByName['SSE4A'].Value then
    Result := Result + 'SSE4A, ';
  if FExt.FeaturesByName['x64'].Value then
    Result := Result + 'x86-64, ';
  if FExt.FeaturesByName['3DNOW+'].Value then
    Result := Result + '3DNOW+, '
  else if FExt.FeaturesByName['3DNOW'].Value then
    Result := Result + '3DNOW, ';
  if FExt.FeaturesByName['SVM'].Value then
    Result := Result + 'AMD-V, '
  else if FStd.FeaturesByName['VME'].Value then
    Result := Result + 'VT-x, ';
  if FStd.FeaturesByName['AES'].Value then
    Result := Result + 'AES, ';
  if FStd.FeaturesByName['AVX'].Value then
    Result := Result + 'AVX, ';
  if FExt.FeaturesByName['AVX2'].Value then
    Result := Result + 'AVX2, ';
  if FExt.FeaturesByName['AVX512F'].Value then
    Result := Result + 'AVX512F, ';
  if FStd.FeaturesByName['FMA3'].Value then
    Result := Result + 'FMA3, ';
  if FExt.FeaturesByName['FMA4'].Value then
    Result := Result + 'FMA4, ';
  if FExt.FeaturesByName['RTM'].Value and FExt.FeaturesByName['HLE'].Value then
    Result := Result + 'TSX, ';
  if FExt.FeaturesByName['SHA'].Value then
    Result := Result + 'SHA, ';
  Result := Trim(Result);
  SetLength(Result, Length(Result) - 1);
end;

procedure TCPUFeatures.SetContent(AStd, AExt, APM, ASVM : TAvailableFeatures);
begin
  FStd.SetContent(AStd);
  FExt.SetContent(AExt);
  FPM.SetContent(APM);
  FSVM.SetContent(ASVM);
end;

{ CPU Speed and ResetMemory }

function GetCPUClock(const ADelay : Integer = 1000) : Double;

  function ReadTimeStampCounter : Int64; assembler;
  asm
    DW      $310F
  {$IFDEF WIN64}
    SHL     RDX, 32
    OR      RAX, RDX
  {$ENDIF}
  end;

var
  Timer : Int64;
  PriorityClass,
  Priority : Integer;
begin
  // Saves thread priority for the process
  PriorityClass := GetPriorityClass(GetCurrentProcess);
  Priority := GetThreadPriority(GetCurrentThread);

  // Sets priority to Realtime
  SetPriorityClass(GetCurrentProcess, REALTIME_PRIORITY_CLASS);
  SetThreadPriority(GetCurrentThread, THREAD_PRIORITY_TIME_CRITICAL);

  // "delay" for priority effect
  Sleep(10);

  // Read the Time Stamp Counter
  Timer := ReadTimeStampCounter;

  // Wait for calculations
  Sleep(ADelay);

  // Read the Time Stamp Counter and get the difference for the first read
  Timer := ReadTimeStampCounter - Timer;

  // Restores process priority
  SetThreadPriority(GetCurrentThread, Priority);
  SetPriorityClass(GetCurrentProcess, PriorityClass);

  // Sets the result with CPU clock frequency
  Result := Timer / (1000.0 * ADelay);
end;

procedure ResetMemory(out P; Size : Longint);
begin
  if Size > 0 then
  begin
    Byte(P) := 0;
    FillChar(P, Size, 0);
  end;
end;

end.