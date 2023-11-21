program PCAnalyser;

uses
  Vcl.Forms,
  Mainform in 'Mainform.pas' {PCAnalyserForm},
  SystemAccess in 'SystemAccess.pas',
  SystemDefinitions in 'SystemDefinitions.pas',
  WindowsClass in 'WindowsClass.pas',
  SMBIOSClass in 'SMBIOSClass.pas',
  SMBIOSStructures in 'SMBIOSStructures.pas',
  ProcessorDB in 'ProcessorDB.pas',
  ProcessorCacheAndFeatures in 'ProcessorCacheAndFeatures.pas',
  ProcessorMSR in 'ProcessorMSR.pas',
  JEDECVendors in 'JEDECVendors.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TPCAnalyserForm, PCAnalyserForm);
  Application.Run;
end.
